#!/usr/bin/env bash
set -euo pipefail

########################
#  configuration
########################
BOT_TOKEN=""
CHAT_ID=""

########################
#  helpers
########################
log() { printf '%s\n' "$*" >&2; }
die() {
  log "ERROR: $*"
  exit 1
}

# --- NEW: send_telegram -----------------------------------------------
# Sends ONE message if ≤4 096 chars, otherwise substring-splits every 4 000
send_telegram() {
  local txt=$1
  local max=4000 # safety margin < 4 096
  local len=${#txt}
  local pos=0

  while ((pos < len)); do
    local chunk=${txt:pos:max}
    curl -sS -X POST \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      --data-urlencode "chat_id=${CHAT_ID}" \
      --data-urlencode "text=${chunk}" \
      --max-time 10 >/dev/null
    pos=$((pos + max))
  done
}

# --- unchanged ---------------------------------------------------------
last_assistant() {
  local file=$1 line
  line="$(grep -F '"type":"assistant"' "$file" | tail -n1 || true)" || return 1

  jq -r '
    def join_text:
      if type=="string" then .
      elif type=="array" then [ .[] | select(.type=="text") | .text ] | join("")
      else "" end;
    (.message?.content?|join_text) // (.content?|join_text) // .text? // empty
  ' <<<"$line"
}

########################
#  main
########################
payload="$(cat)"
transcript="$(jq -r '.transcript_path' <<<"$payload")"
transcript="${transcript/#\~/$HOME}"

[[ -f $transcript ]] || die "Transcript not found at $transcript"

msg="$(last_assistant "$transcript")" || die "No assistant message parsed."
[[ -z $msg ]] && die "Assistant message empty."

send_telegram "$msg"
