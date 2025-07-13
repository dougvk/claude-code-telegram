#!/usr/bin/env bash
###############################################################################
# Claude Code – STOP hook → Telegram  (robust logging, v2)
###############################################################################

########################  USER CONFIG  ########################################
BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"
PREF_LOG_DIR="$HOME/claude_stop_logs" # any writable dir
###############################################################################

# ---------- open log BEFORE strict mode --------------------------------------
ts=$(date +%s)
if mkdir -p "$PREF_LOG_DIR" 2>/dev/null; then
  LOG="${PREF_LOG_DIR}/stop_hook_${ts}.log"
else
  LOG="/tmp/claude_stop_${ts}.log"
fi
exec 3>>"$LOG" || {
  echo "FATAL: cannot open $LOG" >&2
  exit 2
}
log() { printf '%s\n' "$*" >&3; }

log "=== stop-hook start $(date) (log=$LOG) ==="

# enable strict mode only after logging works
set -euo pipefail

########################  HELPERS  ###########################################
send_telegram() {
  local txt="${1-}" # safe even if unset
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

last_assistant() {
  local file=$1
  # newest assistant line (role field, not type)
  local line
  line=$(grep -F '"role":"assistant"' "$file" | tail -n1 || true)
  [[ -z $line ]] && {
    log "no assistant line found"
    return 1
  }
  log "raw last assistant JSON captured"

  jq -r '
    def join_text:
      if type=="string" then .
      elif type=="array" then [ .[] | select(.type=="text") | .text ] | join("")
      else "" end;

    (.message?.content?|join_text)   # new format
    // (.content?|join_text)         # legacy streaming
    // .text?                        # very old field
    // empty
  ' <<<"$line" 2>/dev/null || true
}

########################  MAIN  ###############################################
payload=$(cat)
log "payload=$payload"

tpath=$(jq -r '.transcript_path' <<<"$payload" 2>/dev/null || echo "")
tpath=${tpath/#\~/$HOME}
log "transcript=$tpath"

[[ -f $tpath ]] || {
  log "Transcript missing"
  exit 0
}

msg=$(last_assistant "$tpath" || true)
log "extracted_len=${#msg}"

if [[ -z $msg ]]; then
  log "nothing to send – exit 0"
  exit 0
fi

# real newline handling in case you splice other strings later
clean_msg="${msg//$'\\n'/$'\n'}"

if send_telegram "${clean_msg}"; then
  log "overall result: SUCCESS"
  exit 0
else
  log "overall result: FAILURE"
  exit 1
fi
