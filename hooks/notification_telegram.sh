#!/usr/bin/env bash
###############################################################################
# Claude Code – Notification hook → Telegram  (robust logging v2)
###############################################################################

########################  USER CONFIG  #######################################
BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"
PREF_LOG_DIR="$HOME/claude_notif_logs" # any writable dir
###############################################################################

# --- open log BEFORE strict mode --------------------------------------------
ts=$(date +%s)
if mkdir -p "$PREF_LOG_DIR" 2>/dev/null; then
  LOG="${PREF_LOG_DIR}/notif_hook_${ts}.log"
else
  LOG="/tmp/claude_notif_${ts}.log"
fi
exec 3>>"$LOG" || {
  echo "FATAL: cannot open $LOG" >&2
  exit 2
}
log() { printf '%s\n' "$*" >&3; }

log "=== hook start $(date) (log=$LOG) ==="

# turn on strict mode *after* logging is ready
set -euo pipefail

########################  HELPERS  ###########################################
send_telegram() {
  local txt="${1-}" # safe even if no arg
  if [[ -z ${txt+x} ]]; then
    log "send_telegram called with NO argument – abort"
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

extract_exit_plan() {
  local tpath=$1
  local line
  line=$(grep -F '"role":"assistant"' "$tpath" | tail -n1 || true)
  [[ -z $line ]] && return 0
  jq -r '
    .message.content[]?
    | select(.type=="tool_use" and .name=="exit_plan_mode")
    | "Tool: " + .name + "\n" + (.input.plan? // .input // "")
  ' <<<"$line" 2>/dev/null || true
}

########################  MAIN  #############################################
payload=$(cat)
log "payload=$payload"

msg=$(jq -r '.message' <<<"$payload" 2>/dev/null || echo "")
tpath=$(jq -r '.transcript_path' <<<"$payload" 2>/dev/null || echo "")
tpath=${tpath/#\~/$HOME}

log "banner=$msg"
log "transcript=$tpath"

extra=""

if [[ $msg == *"needs your permission"* && -f $tpath ]]; then
  extra=$(extract_exit_plan "$tpath") # never aborts, may be empty
  [[ -n $extra ]] && log "exit-plan len=${#extra}"
fi

if [[ $msg == *"waiting for your input"* && -f $tpath ]]; then
  prompt=$(grep -F '"role":"assistant"' "$tpath" | tail -n1 |
    jq -r '[.message.content[]? | select(.type=="text") | .text] | join("")' |
    head -c 200 2>/dev/null || true)
  extra="\nContext: $prompt…"
  log "idle snippet captured"
fi

# new
if [[ -n $extra ]]; then
  full="${msg}"$'\n'"${extra}" # real newline via $'\n'
else
  full="$msg"
fi
log "final len=${#full}"

if [[ -z $full ]]; then
  log "nothing to send – exit 0"
  exit 0
fi

if send_telegram "${full}"; then # always passes an arg, even if empty
  log "overall result: SUCCESS"
  exit 0
else
  log "overall result: FAILURE"
  exit 1
fi
