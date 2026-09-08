#!/usr/bin/env bash
# board-cards.sh - read the Discovery TSV (stdin, 9 fields) and join tracker + git + recorded
# state into the Card TSV (stdout): one row per card, 13 tab-separated fields, no header. Per
# conforming repo: open issues from "$TRACKER_CMD" list, closed issues inside the lookback from
# list-closed, session cards and live handoffs from "$TAKE_STOCK_CMD" --cards; every other repo
# still gets a git working-tree card, so each discovered repo yields at least one card.
# No jq: the JSON is read with the repo's brace-depth scan (cf. tracker.sh, gen-mirrors.sh).
set -uo pipefail
TAB=$'\t'
US=$'\037'                    # unit separator: non-whitespace, so consecutive fields never collapse in `read`

DONE_LOOKBACK_DAYS=60         # the done-lane closed-issue window, in days

TRACKER_CMD="${TRACKER_CMD:-scripts/tracker.sh}"
case "$TRACKER_CMD" in
  /*) ;;
  */*) TRACKER_CMD="$PWD/${TRACKER_CMD#./}" ;;   # resolve before the per-repo cd breaks it
esac
TAKE_STOCK_CMD="${TAKE_STOCK_CMD:-scripts/take-stock.sh}"
case "$TAKE_STOCK_CMD" in
  /*) ;;
  */*) TAKE_STOCK_CMD="$PWD/${TAKE_STOCK_CMD#./}" ;;   # same resolution, same reason
esac
RENDER_EPOCH="$(date +%s)"                        # captured once, stamped on every row
LOOKBACK_CUTOFF="$(date -u -v-${DONE_LOOKBACK_DAYS}d +%Y-%m-%d 2>/dev/null)" \
  || LOOKBACK_CUTOFF="$(date -u -d "${DONE_LOOKBACK_DAYS} days ago" +%Y-%m-%d)"

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

age_of_date() {            # YYYY-MM-DD -> days old; the Hinnant civil arithmetic tracker cards use
  awk -v now="$RENDER_EPOCH" -v d="$1" 'BEGIN {
    if (d !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) { print 99999; exit }
    y = substr(d, 1, 4) + 0; m = substr(d, 6, 2) + 0; dd = substr(d, 9, 2) + 0
    y -= (m <= 2)
    era = int((y >= 0 ? y : y - 399) / 400)
    yoe = y - era * 400
    doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + dd - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    print int(now / 86400) - (era * 146097 + doe - 719468)
  }'
}

session_column() {         # session-card status -> lane (plan's mapping); unknown stays visible
  case "$1" in
    open)         echo in-session ;;
    blocked)      echo blocked-on-fact ;;
    handed-off)   echo handed-off ;;
    done|aborted) echo done ;;
    parked)       echo backlog ;;
    *)            echo next-up ;;   # a hand-edited card can never drop off the board
  esac
}

card() {                   # the 13-field row; free text (title, position, note) sanitized here;
                           # field 13 (marker) is a fixed vocabulary, so it skips the clean() guard
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$1" "$2" "$3" "$4" "$(clean "$5")" "$6" "$7" "$8" "$(clean "$9")" "$(clean "${10}")" \
    "${11}" "${12}" "${13}"
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
  tc=0; failed=0; stale=""; open_ids=","; json=""
  if [ "$conf" = yes ]; then
    if json="$( cd "$path" && "$TRACKER_CMD" list )"; then
      while IFS="$US" read -r num title labels lwd age; do
        [ -n "$num" ] || continue
        open_ids="$open_ids$num,"
        case ",$labels," in
          *,wayfinder:*) continue ;;                # wayfinder items render elsewhere, no card
        esac
        case ",$labels," in
          *,idea,*)              col=backlog ;;     # idea wins, as in gen-mirrors BACKLOG lane
          *,agent:done,*|*,done,*) col=done ;;
          *,blocked-on-fact,*)   col=blocked-on-fact ;;
          *,handed-off,*)        col=handed-off ;;
          *,agent:working,*)     col=in-session ;;
          *,agent:needs-input,*) col=blocked-on-you ;;
          *,agent:review,*)      col=awaiting-review ;;
          *,agent:todo,*)        col=next-up ;;
          *)                     col=next-up ;;     # no agent: label yet
        esac
        token="I$num"
        case ",$labels," in *,idea,*) token="B$num" ;; esac
        card "$key#$token" "$key" tracker "$col" "$title" "$token" "$(band_of_age "$age")" \
          "$lwd" "" "" ok "$RENDER_EPOCH" ""
        tc=$((tc + 1))
      done < <(printf '%s\n' "$json" | parse_issues)
    else
      # a failed source is exactly one card (never zero, never many) and stands in for the repo
      failed=1
      card "$key#tracker" "$key" tracker next-up "$key tracker unavailable" "" 4 "" "" "" \
        failed "$RENDER_EPOCH" ""
    fi
  fi
  [ "$failed" -eq 0 ] || continue
  # a conforming repo whose tracker answered with zero open issues emits no tracker card, so the
  # health note's per-conforming-repo list would silently drop it; carry the status on a comment row
  [ "$conf" = yes ] && [ "$tc" -eq 0 ] && printf '#tracker\t%s\tok (no open issues)\n' "$key"
  if [ "$conf" = yes ]; then
    # recorded state, via take-stock's 7-field TSV; the rows are re-joined on US because a tab
    # IFS collapses the empty token/marker fields (cf. board-render-obsidian.sh), and the call
    # takes </dev/null because a child reading stdin would eat Discovery rows from this loop
    if tsv="$( ( cd "$path" && "$TAKE_STOCK_CMD" . --cards ) </dev/null )"; then
      while IFS="$US" read -r knd ref st tok tit last marker; do
        [ -n "$knd" ] || continue
        case "$knd" in
          repo)
            stale="$marker" ;;
          session)
            # done/aborted render only inside the closed-issue window; without the bound the
            # done lane would grow by one card per session forever
            case "$st" in
              done|aborted) [ "$last" \< "$LOOKBACK_CUTOFF" ] && continue ;;
            esac
            stem="${ref##*/}"; stem="${stem%.md}"
            card "$key#s-$stem" "$key" session "$(session_column "$st")" "$tit" "$tok" \
              "$(band_of_age "$(age_of_date "$last")")" "$last" "" "" ok "$RENDER_EPOCH" "$marker"
            ;;
          handoff)
            stem="${ref##*/}"; stem="${stem%.md}"
            card "$key#h-$stem" "$key" handoff handed-off "$tit" "$tok" \
              "$(band_of_age "$(age_of_date "$last")")" "$last" "" "" ok "$RENDER_EPOCH" ""
            ;;
        esac
      done < <(printf '%s\n' "$tsv" | awk -F'\t' -v us="$US" '{ for (i = 1; i <= NF; i++) printf "%s%s", $i, us; printf "\n" }')
    else
      echo "board-cards: take-stock failed for $key" >&2
    fi
    # closed tracker issues inside the lookback; a failed call is not a source failure
    if cjson="$( ( cd "$path" && "$TRACKER_CMD" list-closed "$LOOKBACK_CUTOFF" ) </dev/null )"; then
      while IFS="$US" read -r num title labels lwd age; do
        [ -n "$num" ] || continue
        case ",$labels," in
          *,wayfinder:*) continue ;;                # as on the open path: wayfinder gets no card
        esac
        case "$open_ids" in
          *",$num,"*) continue ;;   # open wins; list returns open issues only, so this fires only
        esac                        # when a backend answers both calls with the same set
        token="I$num"
        case ",$labels," in *,idea,*) token="B$num" ;; esac
        card "$key#$token" "$key" closed done "$title" "$token" "$(band_of_age "$age")" \
          "$lwd" "" "" ok "$RENDER_EPOCH" ""
      done < <(printf '%s\n' "$cjson" | parse_issues)
    else
      echo "board-cards: list-closed failed for $key" >&2
    fi
  fi
  is_clean=0
  if [ "$unc" -eq 0 ] && { [ "$ahead" -eq 0 ] || [ "$ahead" -eq -1 ]; }; then is_clean=1; fi
  # suppression: a clean, conforming repo already carrying tracker cards needs no git card -
  # unless it went stale: the git card is then the marker's only carrier (D9 exception)
  if [ "$is_clean" -eq 1 ] && [ "$conf" = yes ] && [ "$tc" -gt 0 ] && [ "$stale" != went-stale ]; then continue; fi
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
  card "$key#git" "$key" git next-up "${key##*/} working tree" "" \
    "$(band_of_age "$(( (RENDER_EPOCH - epoch) / 86400 ))")" \
    "$(fmt_epoch "$epoch" '+%Y-%m-%d')" "$pos" "$note" "$health" "$RENDER_EPOCH" "$stale"
done
