# Claude Code Telegram Integration

This repository provides Telegram integration for [Claude Code](https://claude.ai/code), allowing you to:
- Send messages and screenshots from Telegram directly into Claude Code conversations
- Receive notifications from Claude Code in Telegram
- Get Claude's responses sent to your Telegram chat

## Features

- **`/tg` Command**: Fetch messages and images from Telegram into Claude Code
- **Notification Hook**: Forward Claude Code notifications to Telegram
  - Captures exit plan mode content when permission is needed
  - Shows context when Claude is waiting for input
  - Robust error handling and logging
- **Stop Hook**: Send Claude's final response to Telegram when a session ends
  - Extracts last assistant message from transcript
  - Handles various message formats (new/legacy)
  - Automatic message chunking for long responses
- **Image Support**: Automatically downloads and processes images from Telegram
- **Message Splitting**: Handles Telegram's 4096 character limit automatically
- **Comprehensive Logging**: Both hooks maintain detailed logs for debugging

## Prerequisites

- Claude Code installed and configured
- A Telegram Bot (create one with [@BotFather](https://t.me/botfather))
- Your Telegram Chat ID (can be a personal chat or channel)
- `jq` command-line tool installed

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/claude-code-telegram.git
cd claude-code-telegram
```

2. Copy the files to your Claude Code configuration:
```bash
# Copy hooks
cp hooks/*.sh ~/.claude/hooks/

# Copy command
cp commands/tg.md ~/.claude/commands/

# Copy script
mkdir -p ~/.claude/scripts
cp scripts/fetch_tg_updates.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/fetch_tg_updates.sh
```

3. Make the scripts executable:
```bash
chmod +x ~/.claude/hooks/*.sh
```

## Configuration

### 1. Set up your Telegram Bot

1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Create a new bot with `/newbot`
3. Save the bot token you receive

### 2. Get your Chat ID

Send a message to your bot, then run:
```bash
curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
```
Look for the `"chat":{"id":` value in the response.

### 3. Configure Environment Variables

Add to your shell configuration (`.bashrc`, `.zshrc`, etc.):
```bash
export TELEGRAM_BOT_TOKEN="your-bot-token-here"
```

### 4. Configure the Hooks

Edit the hook files to add your credentials:

**For `~/.claude/hooks/notification_telegram.sh`:**
```bash
BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"
PREF_LOG_DIR="$HOME/claude_notif_logs"  # Optional: customize log location
```

**For `~/.claude/hooks/stop_telegram.sh`:**
```bash
BOT_TOKEN="your-bot-token-here"
CHAT_ID="your-chat-id-here"
PREF_LOG_DIR="$HOME/claude_stop_logs"   # Optional: customize log location
```

## Usage

### Fetching Messages from Telegram

In any Claude Code conversation, use the `/tg` command:

```bash
/tg      # Fetch the most recent Telegram message
/tg 3    # Fetch the last 3 messages (text + images)
```

Messages and images will be imported directly into your conversation as if you had typed/pasted them.

### Setting up Hooks

To enable automatic notifications:

1. Add to your Claude Code settings file (`~/.config/claude/code/settings.json`):
```json
{
  "hooks": {
    "stop": "~/.claude/hooks/stop_telegram.sh",
    "notification": "~/.claude/hooks/notification_telegram.sh"
  }
}
```

2. The hooks will now:
   - Send notifications to Telegram when Claude Code emits them
   - Send Claude's final response when you end a session

## How It Works

### `/tg` Command Flow
1. The command executes `fetch_tg_updates.sh`
2. Script fetches recent messages from Telegram Bot API
3. Text messages are printed directly
4. Images are downloaded to `tmp/telegram/` directory
5. Claude Code reads and processes the content

### Notification Hook
- Receives JSON payload from Claude Code
- Extracts the `.message` field
- When Claude needs permission (exit plan mode), includes the plan details
- When Claude is waiting for input, shows context snippet
- Sends messages to your Telegram chat with automatic chunking
- Logs all operations to `PREF_LOG_DIR` for debugging

### Stop Hook
- Triggered when Claude Code session ends
- Reads the transcript file
- Extracts Claude's last response (supports multiple formats)
- Handles escaped newlines and formatting
- Sends the final response to your Telegram chat
- Maintains detailed logs for troubleshooting

## Security Notes

- Never commit your bot token or chat ID to version control
- The `tmp/telegram/` directory should be added to `.gitignore`
- Consider using environment variables or a secure credential manager
- Bot tokens provide full access to your bot - keep them secure

## Troubleshooting

### Messages not appearing
- Check your bot token and chat ID are correct
- Ensure you've messaged your bot at least once
- Verify the scripts have execute permissions

### Images not loading
- Check that `tmp/telegram/` directory exists and is writable
- Ensure your bot has access to receive photos
- Verify `jq` is installed: `which jq`

### Hook not triggering
- Verify hook paths in your Claude Code settings
- Check script permissions: `ls -la ~/.claude/hooks/`
- Look for errors in Claude Code logs
- Check hook logs in your configured `PREF_LOG_DIR` or `/tmp/claude_*_*.log`

### Debugging with Logs
Both hooks create detailed logs for troubleshooting:
- Notification logs: `~/claude_notif_logs/notif_hook_*.log` (or `/tmp/claude_notif_*.log`)
- Stop logs: `~/claude_stop_logs/stop_hook_*.log` (or `/tmp/claude_stop_*.log`)

These logs include:
- Full payloads received
- Telegram API responses
- Message extraction details
- Any errors encountered

## Example Workflow

1. Take a screenshot on your phone
2. Send it to your Telegram bot with a message: "Here's the error I'm seeing"
3. In Claude Code, type `/tg`
4. Claude will see both your message and the screenshot
5. When Claude responds with a solution, it's automatically sent back to Telegram

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details