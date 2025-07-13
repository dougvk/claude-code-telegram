# Claude Code Project Configuration

## Project Overview
This is a Telegram integration for Claude Code, allowing users to interact with Claude through Telegram messages.

## Key Technologies
- Node.js/TypeScript
- Telegram Bot API (node-telegram-bot-api)
- SQLite (better-sqlite3)
- Winston for logging

## Project Structure
- `src/` - Source code directory
  - `bot.ts` - Main bot entry point
  - `handlers/` - Message and command handlers
  - `services/` - Core services (API, database, etc.)
  - `config/` - Configuration files
  - `types/` - TypeScript type definitions
  - `utils/` - Utility functions
- `scripts/` - Utility scripts
- `logs/` - Application logs

## Important Commands
```bash
# Install dependencies
npm install

# Run the bot
npm start

# Development mode with auto-reload
npm run dev

# Type checking
npm run typecheck

# Linting
npm run lint

# Build the project
npm run build
```

## Environment Variables
The following environment variables are required:
- `TELEGRAM_BOT_TOKEN` - Telegram bot token from BotFather
- `ANTHROPIC_API_KEY` - Anthropic API key for Claude
- `ADMIN_USER_IDS` - Comma-separated list of admin Telegram user IDs

## Database
The application uses SQLite with the following main tables:
- `users` - Stores user information and settings
- `conversations` - Tracks conversation threads
- `messages` - Stores message history

## Key Features
- Multi-user support with user management
- Conversation history and context management
- Admin commands for user and system management
- Real-time monitoring capabilities
- Comprehensive logging system

## Testing
Currently, the project doesn't have a test suite configured. Consider adding tests using Jest or another testing framework.

## Deployment Notes
- Ensure all environment variables are properly set
- The bot requires persistent storage for the SQLite database
- Logs are stored in the `logs/` directory
- Consider using a process manager like PM2 for production

## Common Tasks

### Adding a New Command
1. Create a new handler in `src/handlers/commands/`
2. Register the command in the bot's command list
3. Add appropriate permission checks if needed

### Modifying API Integration
- API service is located in `src/services/api.ts`
- Rate limiting and error handling are implemented

### Database Schema Changes
- Database initialization is in `src/services/database.ts`
- Use migrations for schema updates in production