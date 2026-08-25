# app-uptime-monitor

External uptime monitoring for Paul's production apps. Runs on GitHub's
servers every 5 minutes, so it keeps watch whether or not any local machine
is on — that was the gap this fixes.

Verified running 2026-08-25: workflow `uptime` is active and a dispatched run
completed successfully.

## What it checks

All 8 production endpoints (see `endpoints.txt`). An endpoint is healthy only
if it returns **200**, is not Railway's `Application not found` edge error, and
its body contains the expected marker. Each is retried 3× / 10s apart so a
transient blip doesn't page anyone.

## Alerts

If any endpoint fails its check, `check-endpoints.sh` exits non-zero and the
workflow run **fails**. GitHub emails the repository owner on a failed run —
that is the alert. Open the run to see the report table showing which endpoint
was down and why.

The workflow lives in `.github/workflows/monitor.yml` and is written in YAML
**flow style** (every line at column zero) on purpose: it was authored through
GitHub's web editor, which auto-indents typed lines and silently corrupts
normal block-style YAML. Keep that format if you edit it there.

## Adding or changing an endpoint

Edit `endpoints.txt` — one per line:

    Display name|https://url/health|expected substring

Leave the third field empty to accept any 200 response.

## What this does NOT cover

Liveness only. It proves the servers answer; it does not prove features work.
The deeper functional check — a synthetic AI request plus a Claude model-ID
audit — lives in the local daily task
(`~/.claude/scheduled-tasks/daily-app-health-check/`) because it needs secrets.
That distinction matters: in Aug 2026 AI Companion served a healthy `/health`
for two months while its photo and memory features were dead.
