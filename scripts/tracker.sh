#!/usr/bin/env bash
# tracker.sh - the single backend seam. Reads config/repo-state.md's tracker: key and
# dispatches every issue operation to github (gh), gitlab (glab), or local (docs/issues/*.md)
# accordingly.
# Operates on the caller's cwd repo, never on this script's own location (cf. loop-auto.sh).
set -uo pipefail
fail() { echo "tracker: $1" >&2; exit 1; }
RS="config/repo-state.md"
ISSUE_DIR="docs/issues"

tracker_mode_get() {          # prints mode, or exits 3 when the key is absent
  [ -f "$RS" ] || return 3
  local v
  v="$(grep -E '^tracker:' "$RS" | head -1 | sed -E 's/^tracker:[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "$v" ] || return 3
  printf '%s\n' "$v"
}
tracker_mode_set() {
  local m="$1"
  case "$m" in github|gitlab|local) ;; *) fail "mode set: must be 'github', 'gitlab', or 'local' (got '$m')";; esac
  mkdir -p "$(dirname "$RS")"; touch "$RS"
  grep -v '^tracker:' "$RS" > "${RS}.tmp" || true
  printf 'tracker: %s\n' "$m" >> "${RS}.tmp"
  mv "${RS}.tmp" "$RS"
  printf '%s\n' "$m"
}

gh_guard() {                  # fail-fast: covers gh-absent AND unauthenticated (criterion 3)
  command -v gh >/dev/null 2>&1 || fail "github mode requires the gh CLI, which is not on PATH"
  gh auth status >/dev/null 2>&1 || fail "github mode requires an authenticated gh CLI (run: gh auth login)"
}

# --- gitlab backend helpers ---
gitlab_host() {               # prints the host of origin; nothing + non-zero when origin is absent
  local url
  url="$(git remote get-url origin 2>/dev/null)" || return 1
  [ -n "$url" ] || return 1
  printf '%s\n' "$url" | sed -E 's#^[a-z+]+://##; s#^[^@]*@##; s#[:/].*$##'
}
gitlab_group() {              # prints the first path segment after the host of origin
  local url p
  url="$(git remote get-url origin 2>/dev/null)" || return 1
  [ -n "$url" ] || return 1
  p="$(printf '%s\n' "$url" | sed -E 's#^[a-z+]+://##; s#^[^@]*@##; s#^[^:/]+##; s#^:[0-9]+/#/#; s#^:##; s#^/##')"
  printf '%s\n' "${p%%/*}"
}
glab_guard() {                # fail-fast: host-scoped auth check (never bare `glab auth status`)
  command -v glab >/dev/null 2>&1 || fail "gitlab mode requires the glab CLI, which is not on PATH"
  local host
  host="$(gitlab_host)" || fail "gitlab mode requires an origin remote to resolve the GitLab host (found none)"
  [ -n "$host" ] || fail "gitlab mode requires an origin remote to resolve the GitLab host (found none)"
  glab auth status --hostname "$host" >/dev/null 2>&1 \
    || fail "gitlab mode requires glab authenticated to $host (run: glab auth login --hostname $host)"
}
# ponytail: 50 pages x 100 = a 5000-open-issue ceiling. GitLab caps per_page at 100, so a
# page loop is the only correct form; raise the cap or switch to keyset pagination if a repo
# ever exceeds it. The loop stops on the first short page, so the cap costs nothing normally.
gitlab_list() {
  local page=1 rows n all=""
  while [ "$page" -le 50 ]; do
    # declare first, assign second: `local rows="$(...)" || fail` would test local's status.
    rows="$(glab issue list --per-page 100 --page "$page" -O json \
      --jq '.[] | {number:.iid, title:.title, labels:[.labels[]|{name:.}], updatedAt:.updated_at}')" \
      || fail "glab issue list failed on page $page"
    [ -n "$rows" ] || break
    all="${all:+$all,}$(printf '%s' "$rows" | paste -sd, -)"
    n="$(printf '%s\n' "$rows" | grep -c .)"
    [ "$n" -lt 100 ] && break
    page=$((page + 1))
  done
  printf '[%s]\n' "$all"
}

# --- local backend helpers ---
slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'; }
fm() { grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }  # frontmatter value
# ponytail: escapes only \ and " (zero-dependency, no jq). Tab/newline/other control chars in a title
# are NOT escaped - rare in issue titles, and frontmatter values are single-line so embedded newlines
# cannot occur. Upgrade path: pipe through jq -Rn if control-char titles ever matter.
json_escape() { printf '%s' "$1" | sed -E 's/\\/\\\\/g; s/"/\\"/g'; }

next_number() {
  local max=0 n f
  shopt -s nullglob
  for f in "$ISSUE_DIR"/*.md; do
    n="$(fm "$f" number)"
    [ -n "$n" ] && [ "$n" -gt "$max" ] 2>/dev/null && max="$n"
  done
  echo $((max + 1))
}
find_issue_file() {           # arg: number -> prints path, exit 1 if none
  local f n
  shopt -s nullglob
  for f in "$ISSUE_DIR"/*.md; do
    n="$(fm "$f" number)"
    [ "$n" = "$1" ] && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}
local_create() {              # args: label title body -> prints number
  local label="$1" title="$2" body="$3" num slug file
  mkdir -p "$ISSUE_DIR"
  num="$(next_number)"; slug="$(slugify "$title")"; slug="${slug:-issue}"  # all-punctuation title -> NNN-issue.md
  file="$(printf '%s/%03d-%s.md' "$ISSUE_DIR" "$num" "$slug")"
  {
    echo "---"
    echo "number: $num"
    echo "title: $title"
    echo "labels: $label"
    echo "state: open"
    echo "updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "---"
    printf '%s\n' "$body"
  } > "$file"
  echo "note: ISSUES.md/BACKLOG.md now stale - run scripts/gen-mirrors.sh ." >&2  # reminder only; no auto-regen
  printf '%s\n' "$num"
}
local_set_state() {           # args: number newstate ; rewrites state: and updated: only inside the first frontmatter block
  local f tmp now; f="$(find_issue_file "$1")" || fail "no local issue #$1"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  awk -v st="$2" -v up="$now" '
    /^---$/ { d++; print; next }
    d==1 && /^state:/   { print "state: " st; next }
    d==1 && /^updated:/ { print "updated: " up; next }
    { print }
  ' "$f" > "$tmp" && mv "$tmp" "$f"
  echo "note: ISSUES.md/BACKLOG.md now stale - run scripts/gen-mirrors.sh ." >&2  # reminder only; no auto-regen
}
local_label() {               # args: number name add|remove ; rewrites labels: (deduped comma list)
  local f num="$1" name="$2" op="$3" cur l out="" _arr lb now tmp   # + updated:, first block only
  f="$(find_issue_file "$num")" || fail "no local issue #$num"
  cur="$(fm "$f" labels)"
  if [ -n "$cur" ]; then      # guard: iterating an empty array under set -u aborts on bash 3.2 (macOS)
    IFS=',' read -ra _arr <<< "$cur"
    for l in "${_arr[@]}"; do
      l="$(printf '%s' "$l" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "$l" ] || continue
      [ "$op" = remove ] && [ "$l" = "$name" ] && continue
      case ",$out," in *",$l,"*) continue ;; esac   # de-dup: add is idempotent
      out="${out:+$out,}$l"
    done
  fi
  if [ "$op" = add ]; then
    case ",$out," in *",$name,"*) ;; *) out="${out:+$out,}$name" ;; esac
  fi
  lb="$out"; [ -n "$lb" ] && lb=" $lb"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  awk -v lb="$lb" -v up="$now" '
    /^---$/ { d++; print; next }
    d==1 && /^labels:/  { print "labels:" lb; next }
    d==1 && /^updated:/ { print "updated: " up; next }
    { print }
  ' "$f" > "$tmp" && mv "$tmp" "$f"
  echo "note: ISSUES.md/BACKLOG.md now stale - run scripts/gen-mirrors.sh ." >&2  # reminder only; no auto-regen
}
local_comment() {             # args: number text ; appends a receipt line after the body, refreshes updated:
  local f num="$1" text="$2" now tmp
  f="$(find_issue_file "$num")" || fail "no local issue #$num"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  awk -v up="$now" -v line="> comment $now: $text" '
    /^---$/ { d++; print; next }
    d==1 && /^updated:/ { print "updated: " up; next }
    { print }
    END { print line }
  ' "$f" > "$tmp" && mv "$tmp" "$f"
}
local_list() {                # emit gh-shaped JSON for open issues
  local first=1 out="[" f state num title upd labels_raw labels_json l
  shopt -s nullglob
  for f in "$ISSUE_DIR"/*.md; do
    state="$(fm "$f" state)"; [ "$state" = "open" ] || continue
    num="$(fm "$f" number)"; title="$(fm "$f" title)"; upd="$(fm "$f" updated)"
    labels_raw="$(fm "$f" labels)"
    labels_json=""
    if [ -n "$labels_raw" ]; then   # guard: iterating an empty array under set -u aborts on bash 3.2 (macOS)
      IFS=',' read -ra _larr <<< "$labels_raw"
      for l in "${_larr[@]}"; do
        l="$(printf '%s' "$l" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        [ -n "$l" ] || continue
        [ -n "$labels_json" ] && labels_json="$labels_json,"
        labels_json="$labels_json{\"name\":\"$(json_escape "$l")\"}"
      done
    fi
    [ "$first" -eq 1 ] || out="$out,"; first=0
    out="$out{\"number\":$num,\"title\":\"$(json_escape "$title")\",\"labels\":[$labels_json],\"updatedAt\":\"$(json_escape "$upd")\"}"
  done
  printf '%s]\n' "$out"
}

usage() {
  cat >&2 <<EOF
Usage: tracker.sh <command> [args]
  mode get                       print the declared tracker mode (github|gitlab|local); exit 3 if the key is absent
  mode set <github|gitlab|local> write the line-anchored tracker: key
  host                           print the GitLab host derived from origin
  group                          print the first path segment of origin (the backlog group)
  list                           print a gh-shaped issue-JSON array for open issues
  create --label L --title T --body B   create an issue, print its number
  close <num>                    close an issue by number
  reopen <num>                   reopen an issue by number
  label ensure <name>            idempotently make the label exist (no-op in local mode)
  label add <num> <name>         attach a label (agent:done is evidence-gated: use 'done')
  label remove <num> <name>      detach a label
  comment <num> <text>           append a durable comment/receipt
EOF
}

[ $# -ge 1 ] || { usage; exit 1; }
sub="$1"; shift
case "$sub" in
  mode)
    [ $# -ge 1 ] || { usage; exit 1; }
    msub="$1"; shift
    case "$msub" in
      get) tracker_mode_get ;;
      set) [ $# -ge 1 ] || fail "mode set: requires 'github', 'gitlab', or 'local'"; tracker_mode_set "$1" ;;
      *)   usage; exit 1 ;;
    esac
    ;;
  list)
    # ponytail: mode bound in the PARENT scope - NOT a require_mode subshell. tracker_mode_get
    # return-3s on a keyless repo; the parent-scope `|| fail` then aborts non-zero. A subshell
    # `fail` would exit only the subshell and the parent would fall into the local branch.
    mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
    case "$mode" in
      github) gh_guard; gh issue list --state open --limit 1000 --json number,title,labels,updatedAt ;;
      gitlab) glab_guard; gitlab_list ;;
      local)  local_list ;;
      *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
    esac
    ;;
  create)
    label=""; title=""; body=""
    while [ $# -ge 2 ]; do
      case "$1" in
        --label) label="$2"; shift 2 ;;
        --title) title="$2"; shift 2 ;;
        --body)  body="$2";  shift 2 ;;
        *) fail "create: unknown argument '$1'" ;;
      esac
    done
    [ $# -eq 0 ] || fail "create: unpaired arguments"
    mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
    case "$mode" in
      github)
        gh_guard
        args=(issue create --title "$title" --body "$body")
        [ -n "$label" ] && args+=(--label "$label")
        url="$(gh "${args[@]}")" || fail "gh issue create failed"
        printf '%s\n' "${url##*/}"
        ;;
      gitlab)
        glab_guard
        args=(issue create --yes --no-editor -t "$title" -d "$body")
        [ -n "$label" ] && args+=(-l "$label")
        out="$(glab "${args[@]}")" || fail "glab issue create failed"
        iid="$(printf '%s' "$out" | grep -oE '/issues/[0-9]+' | tail -1 | sed 's#.*/##')"
        [ -n "$iid" ] || fail "glab issue create returned no parseable issue URL"
        printf '%s\n' "$iid"
        ;;
      local)
        local_create "$label" "$title" "$body"
        ;;
      *)
        fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)"
        ;;
    esac
    ;;
  close|reopen)
    [ $# -ge 1 ] || fail "$sub: requires an issue number"
    num="$1"
    mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
    case "$mode" in
      github) gh_guard; gh issue "$sub" "$num" ;;
      gitlab) glab_guard; glab issue "$sub" "$num" ;;
      local)
        if [ "$sub" = close ]; then local_set_state "$num" closed
        else                           local_set_state "$num" open; fi
        ;;
      *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
    esac
    ;;
  label)
    [ $# -ge 1 ] || fail "label: requires a subcommand (ensure|add|remove)"
    lsub="$1"; shift
    case "$lsub" in
      ensure)
        [ $# -ge 1 ] || fail "label ensure: requires a label name"
        mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
        case "$mode" in
          github) gh_guard; gh label create "$1" 2>/dev/null || true ;;
          gitlab) glab_guard; glab label create --name "$1" 2>/dev/null || true ;;
          local)  echo "note: local labels are frontmatter, nothing to ensure" >&2 ;;
          *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
        esac
        ;;
      add)
        [ $# -ge 2 ] || fail "label add: requires an issue number and a label name"
        [ "$2" = "agent:done" ] && { echo "tracker: agent:done is reachable only through 'tracker.sh done' (evidence-gated)" >&2; exit 6; }
        mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
        case "$mode" in
          github) gh_guard; gh issue edit "$1" --add-label "$2" ;;
          gitlab) glab_guard; glab issue update "$1" --label "$2" ;;
          local)  local_label "$1" "$2" add ;;
          *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
        esac
        ;;
      remove)
        [ $# -ge 2 ] || fail "label remove: requires an issue number and a label name"
        mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
        case "$mode" in
          github) gh_guard; gh issue edit "$1" --remove-label "$2" ;;
          gitlab) glab_guard; glab issue update "$1" --unlabel "$2" ;;
          local)  local_label "$1" "$2" remove ;;
          *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
        esac
        ;;
      *) usage; exit 1 ;;
    esac
    ;;
  comment)
    [ $# -ge 2 ] || fail "comment: requires an issue number and a text"
    mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"
    case "$mode" in
      github) gh_guard; gh issue comment "$1" --body "$2" ;;
      gitlab) glab_guard; glab issue note "$1" --message "$2" ;;
      local)  local_comment "$1" "$2" ;;
      *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
    esac
    ;;
  host)   gitlab_host || fail "no origin remote" ;;
  group)  gitlab_group || fail "no origin remote" ;;
  *) usage; exit 1 ;;
esac
