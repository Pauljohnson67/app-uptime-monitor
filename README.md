# app-uptime-monitor

External uptime monitoring for Paul's production apps. Runs on GitHub's
servers every 5 minutes, so it keeps watch whether or not any local machine
is on — that was the gap this fixes.

## What it checks

All 8 production endpoints (see `endpoints.txt`). An endpoint is healthy only
if it returns **200**, is not Railway's `Application not found` edge error, and
its body contains the expected marker. Each is retried 3× / 10s apart so a
transient blip doesn't page anyone.

## Alerts

A failed run opens a GitHub issue labelled `uptime-alert` (GitHub emails you),
and keeps commenting on that same issue rather than opening a new one every
5 minutes. When everything recovers, the issue is auto-closed.

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
