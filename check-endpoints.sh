#!/bin/bash
# Liveness check for Paul's production endpoints.
# Exit 0 = all up, 1 = at least one down. Writes a markdown report to report.md.
set -uo pipefail
REPORT="${REPORT_FILE:-report.md}"
FAIL=0; DOWN_LIST=""
: > "$REPORT"
printf '| Service | Status | Detail |\n|---|---|---|\n' >> "$REPORT"

while IFS='|' read -r name url expect; do
  case "$name" in \#*|'') continue;; esac
  [ -z "${url:-}" ] && continue

  # Up to 3 attempts, 10s apart, to avoid alerting on a transient blip.
  ok=0; code=""; detail=""
  for attempt in 1 2 3; do
    code=$(curl -sS -m 20 -o body.tmp -w '%{http_code}' -A 'uptime-monitor/1.0' "$url" 2>err.tmp)
    body=$(head -c 200 body.tmp 2>/dev/null | tr -d '\n\r|')
    if [ "$code" != "200" ]; then
      detail="HTTP ${code:-000} $(head -c 80 err.tmp | tr -d '\n|')"
    elif grep -qi 'Application not found' body.tmp; then
      # Railway edge 404 — service removed/unbound. Returns 200-ish but is DOWN.
      detail="Railway edge: Application not found (service removed/unbound)"
    elif [ -n "${expect:-}" ] && ! grep -qF "$expect" body.tmp; then
      detail="200 but body missing expected \`$expect\`"
    else
      ok=1; detail="$(echo "$body" | head -c 60)"; break
    fi
    [ "$attempt" -lt 3 ] && sleep 10
  done

  if [ "$ok" = "1" ]; then
    printf '| %s | ✅ up | `%s` |\n' "$name" "$detail" >> "$REPORT"
  else
    printf '| %s | ❌ DOWN | %s |\n' "$name" "$detail" >> "$REPORT"
    DOWN_LIST="${DOWN_LIST}- **${name}** — ${detail}\n  ${url}\n"
    FAIL=1
  fi
done < endpoints.txt

rm -f body.tmp err.tmp
{ echo; if [ "$FAIL" -eq 0 ]; then echo "All endpoints healthy."; else echo "### Down"; printf "%b" "$DOWN_LIST"; fi; } >> "$REPORT"
cat "$REPORT"
exit $FAIL
