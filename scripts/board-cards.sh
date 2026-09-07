#!/usr/bin/env bash
# board-cards.sh - read the Discovery TSV (stdin, 9 fields) and join tracker + git signals into
# the Card TSV (stdout): one row per card, 12 tab-separated fields, no header. Tracker issues
# come from "$TRACKER_CMD" list (gh-shaped JSON) run inside each conforming repo; every other
# repo still gets a git working-tree card, so each discovered repo yields at least one card.
# No jq: the JSON is read with the repo's brace-depth scan (cf. tracker.sh, gen-mirrors.sh).
set -uo pipefail
TAB=$'\t'
US=$'\037'                    # unit separator: non-whitespace, so consecutive fields never collapse in `read`

TRACKER_CMD="${TRACKER_CMD:-scripts/tracker.sh}"
case "$TRACKER_CMD" in
  /*) ;;
  */*) TRACKER_CMD="$PWD/${TRACKER_CMD#./}" ;;   # resolve before the per-repo cd breaks it
esac
RENDER_EPOCH="$(date +%s)"                        # captured once, stamped on every row

clean() { printf '%s' "$1" | tr '\t\n' '  '; }    # free-text guard: a tab/newline can never split a row

band_of_age() {            # days since last work -> 1 (<5), 2 (<15), 3 (<30), else 4
  if   [ "$1" -lt 5  ]; then echo 1
  elif [ "$1" -lt 15 ]; then echo 2
  elif [ "$1" -lt 30 ]; then echo 3
  else echo 4; fi
}

fmt_epoch() {              # epoch -> strftime output; BSD date first, GNU date fallback
  date -u -r "$1" "$2" 2>/dev/null || date -u -d "@$1" "$2" 2>/dev/null || :
}

card() {                   # the 12-field row; free text (title, position, note) sanitized here
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$1" "$2" "$3" "$4" "$(clean "$5")" "$6" "$7" "$8" "$(clean "$9")" "$(clean "${10}")" \
    "${11}" "${12}"
}

parse_issues() {           # gh-shaped issue JSON on stdin -> num US title US labels US date US age-days
  awk -v now="$RENDER_EPOCH" -v us="$US" '
    { all = all $0 "\n" }
    END {
      n = length(all); depth = 0; obj = ""
      for (i = 1; i <= n; i++) {
        c = substr(all, i, 1)
        if (c == "{") { if (depth == 0) obj = "{"; else obj = obj c; depth++ }
        else if (c == "}") { depth--; if (depth == 0) { emit(obj); obj = "" } else obj = obj c }
        else if (depth > 0) obj = obj c
      }
    }
    # ponytail: "[^"]*" strings and a comma-joined label list - an escaped quote or embedded
    # brace in a title degrades to truncation, not a crash (same ceiling as gen-mirrors.sh).
    # days_civil (Hinnant civil-date algorithm) keeps staleness off per-issue date subprocesses.
    function emit(s,    m, num, title, upd, labels, seg) {
      if (!match(s, /"number"[ \t]*:[ \t]*[0-9]+/)) return
      m = substr(s, RSTART, RLENGTH); gsub(/[^0-9]/, "", m); num = m
      title = ""
      if (match(s, /"title"[ \t]*:[ \t]*"[^"]*"/)) {
        m = substr(s, RSTART, RLENGTH); gsub(/^"[^"]*"[ \t]*:[ \t]*"|"$/, "", m); title = m
      }
      gsub(/[\t\n\r]/, " ", title)                # free-text: never split the intermediate TSV
      upd = ""
      if (match(s, /"updatedAt"[ \t]*:[ \t]*"[^"]*"/)) {
        m = substr(s, RSTART, RLENGTH); gsub(/^"[^"]*"[ \t]*:[ \t]*"|"$/, "", m); upd = m
      }
      labels = ""
      if (match(s, /"labels"[ \t]*:[ \t]*\[/)) {
        seg = substr(s, RSTART)
        while (match(seg, /"name"[ \t]*:[ \t]*"[^"]*"/)) {
          m = substr(seg, RSTART, RLENGTH); gsub(/^"[^"]*"[ \t]*:[ \t]*"|"$/, "", m)
          labels = (labels == "" ? m : labels "," m)
          seg = substr(seg, RSTART + RLENGTH)
        }
      }
      print num us title us labels us substr(upd, 1, 10) us age_days(upd)
    }
    function age_days(upd,    y, mo, d) {
      if (upd !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) return 99999
      y = substr(upd, 1, 4) + 0; mo = substr(upd, 6, 2) + 0; d = substr(upd, 9, 2) + 0
      return int(now / 86400) - days_civil(y, mo, d)
    }
    function days_civil(y, m, d) {
      # Hinnant civil-date algorithm; era/yoe/doy/doe are function-local by awk scoping
      y -= (m <= 2)
      era = int((y >= 0 ? y : y - 399) / 400)
      yoe = y - era * 400
      doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
      doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
      return era * 146097 + doe - 719468
    }
  '
}

while IFS= read -r line; do
  [ -n "$line" ] || continue
  IFS="$TAB" read -r path key root conf incl epoch unc ahead behind <<< "$line"
  [ -n "$path" ] || continue
  [ "$incl" = yes ] || continue
  tc=0; failed=0; json=""
  if [ "$conf" = yes ]; then
    if json="$( cd "$path" && "$TRACKER_CMD" list )"; then
      while IFS="$US" read -r num title labels lwd age; do
        [ -n "$num" ] || continue
        case ",$labels," in
          *,wayfinder:*) continue ;;                # wayfinder items render elsewhere, no card
          *,agent:done,*|*,done,*|*,blocked-on-fact,*|*,handed-off,*) continue ;;  # no card in MVP
        esac
        case ",$labels," in
          *,idea,*)              col=backlog ;;     # idea wins, as in gen-mirrors BACKLOG lane
          *,agent:working,*)     col=in-session ;;
          *,agent:needs-input,*) col=blocked-on-you ;;
          *,agent:review,*)      col=awaiting-review ;;
          *,agent:todo,*)        col=next-up ;;
          *)                     col=next-up ;;     # no agent: label yet
        esac
        token="I$num"
        case ",$labels," in *,idea,*) token="B$num" ;; esac
        card "$key#$token" "$key" tracker "$col" "$title" "$token" "$(band_of_age "$age")" \
          "$lwd" "" "" ok "$RENDER_EPOCH"
        tc=$((tc + 1))
      done < <(printf '%s\n' "$json" | parse_issues)
    else
      # a failed source is exactly one card (never zero, never many) and stands in for the repo
      failed=1
      card "$key#tracker" "$key" tracker next-up "$key tracker unavailable" "" 4 "" "" "" \
        failed "$RENDER_EPOCH"
    fi
  fi
  [ "$failed" -eq 0 ] || continue
  is_clean=0
  if [ "$unc" -eq 0 ] && { [ "$ahead" -eq 0 ] || [ "$ahead" -eq -1 ]; }; then is_clean=1; fi
  # suppression: a clean, conforming repo already carrying tracker cards needs no git card
  if [ "$is_clean" -eq 1 ] && [ "$conf" = yes ] && [ "$tc" -gt 0 ]; then continue; fi
  pos=""; note=""; health=ok
  [ "$conf" = yes ] || health=degraded
  if [ "$is_clean" -eq 1 ]; then
    pos=clean
  else
    [ "$unc" -gt 0 ] && pos="$unc uncommitted"
    [ "$ahead" -gt 0 ] && pos="${pos:+$pos, }+$ahead ahead"
  fi
  if [ -n "$behind" ]; then
    bn="${behind%%:*}"; fe="${behind##*:}"
    if [ "$bn" -gt 0 ] 2>/dev/null && [ "$fe" -gt 0 ] 2>/dev/null; then
      note="$bn behind as of $(fmt_epoch "$fe" '+%Y-%m-%d %H:%M')"
    fi
  fi
  card "$key#git" "$key" git next-up "$key working tree" "" \
    "$(band_of_age "$(( (RENDER_EPOCH - epoch) / 86400 ))")" \
    "$(fmt_epoch "$epoch" '+%Y-%m-%d')" "$pos" "$note" "$health" "$RENDER_EPOCH"
done
