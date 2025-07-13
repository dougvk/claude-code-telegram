#!/bin/bash

MONITOR_DIR="$HOME/.claude"
BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"

declare -A sent_messages # track sent messages per file

log() {
  # Simple logging to stdout with timestamp, customize if needed
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

send_telegram() {
  local txt="${1-}"
  if [[ -z ${txt+x} || -z $txt ]]; then
    log "send_telegram called with empty text – abort"
    return 1
  fi

  local max=4000 len=${#txt} pos=0 n=1 resp rc http body
  while ((pos < len)); do
    local chunk=${txt:pos:max}
    log "--- chunk $n (len=${#chunk}) ---"
    set +e
    resp=$(curl -sS -X POST -w "HTTP_STATUS:%{http_code}" \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      --data-urlencode "chat_id=${CHAT_ID}" \
      --data-urlencode "text=${chunk}" \
      --data-urlencode "disable_web_page_preview=true" \
      --max-time 10 2>&1)
    rc=$?
    set -e
    http=$(grep -o 'HTTP_STATUS:[0-9]*' <<<"$resp" | cut -d: -f2 || echo 0)
    body=${resp/HTTP_STATUS:*/}
    log "curl_exit=$rc  http=$http  body=$body"
    if ((rc != 0 || http >= 400)); then
      log "❌  Telegram rejected chunk $n"
      return 1
    fi
    pos=$((pos + max))
    n=$((n + 1))
  done
  log "✅  all chunks sent"
  return 0
}

extract_latest_message() {
  local file="$1"
  jq -s -r '
    map(
      select(.type == "assistant")
      | select(.message and .message.type == "message")
      | .message.content[]
      | select(.type == "text")
      | .text
    )
    | last
  ' "$file"
}

inotifywait -m -r -e create,modify --format '%w%f' --include '.*\.jsonl$' "$MONITOR_DIR" | while read -r NEWFILE; do
  log "New or modified file detected: $NEWFILE"

  MESSAGE_TEXT=$(extract_latest_message "$NEWFILE")

  if [ -z "$MESSAGE_TEXT" ]; then
    log "No assistant message text found in $NEWFILE, skipping."
    continue
  fi

  MSG_HASH=$(printf '%s' "$MESSAGE_TEXT" | sha256sum | awk '{print $1}')
  UNIQUE_KEY="${NEWFILE}::${MSG_HASH}"

  if [[ -n "${sent_messages[$UNIQUE_KEY]}" ]]; then
    log "Message already sent for this file, skipping."
    continue
  fi

  sent_messages[$UNIQUE_KEY]=1

  log "Extracted new message:"
  log "$MESSAGE_TEXT"

  if send_telegram "$MESSAGE_TEXT"; then
    log "Message posted to Telegram successfully"
  else
    log "Failed to post message to Telegram"
  fi
done
