#!/usr/bin/env bash
# Usage: fetch_tg_updates.sh [N]   (default N=1)
# Prints a merged, ordered stream of text lines and local image paths:
#   - Text lines exactly as sent
#   - Image paths like tmp/telegram/123456.jpg
#
# Claude Code can read those files immediately.

set -euo pipefail

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
if [[ -z "$BOT_TOKEN" ]]; then
  echo "Error: TELEGRAM_BOT_TOKEN environment variable not set" >&2
  exit 1
fi
TMP_DIR="./tmp/telegram" # project-relative, keep under .gitignore
mkdir -p "$TMP_DIR"

N="${1:-1}"          # how many most-recent updates to grab
((N > 100)) && N=100 # Bot-API max limit

# 1️⃣ Pull last N updates only
resp=$(curl -s \
  "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?limit=${N}&offset=-${N}")

len=$(jq '.result | length' <<<"$resp")
[[ $len -eq 0 ]] && {
  echo ""
  exit 0
}

last_update_id=$(jq -r '.result[-1].update_id' <<<"$resp")

# 2️⃣ Confirm them so they’re removed from the queue
curl -s \
  "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=$((last_update_id + 1))" \
  >/dev/null

# 3️⃣ Walk through the batch (oldest→newest) and emit text / image paths
for i in $(seq 0 $((len - 1))); do
  upd=$(jq ".result[$i]" <<<"$resp")

  # ---- text ------------------------------------------------------------
  txt=$(jq -r '.message.text // .channel_post.text // empty' <<<"$upd")
  [[ -n $txt ]] && printf '%s\n' "$txt"

  # ---- photo (screenshot) ---------------------------------------------
  # choose the highest-resolution size (last array element)
  if jq -e '.message.photo? or .channel_post.photo?' >/dev/null <<<"$upd"; then
    file_id=$(jq -r '.message.photo? // .channel_post.photo? | .[-1].file_id' <<<"$upd")
    # getFile
    f_resp=$(curl -s \
      "https://api.telegram.org/bot${BOT_TOKEN}/getFile?file_id=${file_id}")
    f_path=$(jq -r '.result.file_path' <<<"$f_resp")
    ext="${f_path##*.}"
    local_name="$TMP_DIR/tg_${file_id}.${ext}"
    curl -s "https://api.telegram.org/file/bot${BOT_TOKEN}/${f_path}" \
      -o "$local_name"
    printf '%s\n' "$local_name"
  fi
done
