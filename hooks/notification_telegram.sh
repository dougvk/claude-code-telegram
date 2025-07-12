#!/usr/bin/env bash
# Send the .message field from a Notification hook to Telegram
set -euo pipefail

BOT_TOKEN=""
CHAT_ID=""

payload="$(cat)"
msg="$(jq -r '.message' <<<"$payload")"

# Telegram messages max out at 4096 chars; split if needed
while IFS= read -r -d '' chunk; do
  curl -s --max-time 10 \
    --data-urlencode "chat_id=$CHAT_ID" \
    --data-urlencode "text=$chunk" \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" >/dev/null
done < <(printf '%s' "$msg" | fold -w4000 -s | awk '{printf "%s\0",$0}')
