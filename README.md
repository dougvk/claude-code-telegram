# Claude Code Telegram Integration

**Connect your Telegram to Claude Code** - Send messages and screenshots from Telegram directly into Claude conversations, and get Claude's responses back in your chat.

## 🚀 Quick Start

### 1. Create a Telegram Bot
Message [@BotFather](https://t.me/botfather) → `/newbot` → Save your token

### 2. Install
```bash
git clone https://github.com/yourusername/claude-code-telegram.git
cd claude-code-telegram

# Copy files to Claude Code
cp -r hooks commands scripts ~/.claude/
chmod +x ~/.claude/hooks/*.sh ~/.claude/scripts/*.sh
```

### 3. Configure
Add your bot token and chat ID to:
- `~/.claude/hooks/notification_telegram.sh`
- `~/.claude/hooks/stop_telegram.sh`
- `~/.claude/scripts/monitor_and_post.sh`

```bash
BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"
```

(Get your chat ID: Message your bot, then `curl https://api.telegram.org/bot<TOKEN>/getUpdates`)

### 4. Enable Hooks
Add to `~/.config/claude/code/settings.json`:
```json
{
  "hooks": {
    "stop": "~/.claude/hooks/stop_telegram.sh",
    "notification": "~/.claude/hooks/notification_telegram.sh"
  }
}
```

## 📱 Basic Usage

### Send Telegram → Claude
In Claude Code:
```
/tg      # Get latest message/image from Telegram
/tg 3    # Get last 3 messages
```

### Get Claude → Telegram
Claude's responses are automatically sent to your Telegram when:
- A conversation ends (stop hook)
- Claude needs your input (notification hook)
- Real-time monitoring is enabled (optional)

## 🔄 Example Workflow

1. 📸 Take a screenshot on your phone
2. 📤 Send to your Telegram bot: "Here's the error I'm seeing"
3. 💻 In Claude Code: `/tg`
4. 🤖 Claude sees your message + screenshot
5. 📨 Claude's solution appears in your Telegram

---

## 📚 Advanced Configuration

### Real-time Monitoring
Watch Claude conversations and send all responses to Telegram instantly:
```bash
# Run in background
nohup ~/.claude/scripts/monitor_and_post.sh > ~/claude_monitor.log 2>&1 &
```

### Environment Variables
Instead of hardcoding credentials, you can use:
```bash
export TELEGRAM_BOT_TOKEN="your-token"
export TELEGRAM_CHAT_ID="your-chat-id"
```

### Features in Detail

**`/tg` Command**
- Fetches messages and images from Telegram
- Downloads images to `tmp/telegram/`
- Supports multiple message retrieval

**Notification Hook**
- Captures when Claude needs permission (exit plan mode)
- Shows context when Claude is waiting for input
- Automatic message chunking for long responses

**Stop Hook**
- Sends Claude's final response when session ends
- Extracts from conversation transcript
- Handles various message formats

**Real-time Monitor**
- Watches JSONL files for new assistant messages
- Deduplicates to prevent spam
- Maintains per-session message history

### Technical Requirements
- Claude Code installed
- `jq` command-line tool
- `inotify-tools` (for monitoring)
- Write permissions for `tmp/` directory

### File Structure
```
~/.claude/
├── hooks/
│   ├── notification_telegram.sh
│   └── stop_telegram.sh
├── commands/
│   └── tg.md
└── scripts/
    ├── fetch_tg_updates.sh
    └── monitor_and_post.sh
```

### Logs and Debugging
Logs are created for troubleshooting:
- Notification: `~/claude_notif_logs/` or `/tmp/claude_notif_*.log`
- Stop hook: `~/claude_stop_logs/` or `/tmp/claude_stop_*.log`
- Monitor: Check output of `monitor_and_post.sh`

### Security Notes
- Never commit bot tokens to git
- Add `tmp/telegram/` to `.gitignore`
- Consider using a credential manager
- Bot tokens grant full bot access - keep secure

## 🐛 Troubleshooting

**Messages not appearing?**
- Verify bot token and chat ID
- Check script permissions: `ls -la ~/.claude/hooks/`
- Ensure you've messaged your bot first

**Images not loading?**
- Check `tmp/telegram/` exists and is writable
- Verify `jq` is installed: `which jq`

**Monitor not working?**
- Install inotify-tools: `sudo apt install inotify-tools`
- Check if running: `ps aux | grep monitor_and_post`
- Review monitor logs

**Hooks not triggering?**
- Verify paths in Claude Code settings
- Check logs in configured directories
- Look for errors in Claude Code output

## Contributing

Contributions welcome! Please submit a Pull Request.

## License

MIT License - see LICENSE file for details