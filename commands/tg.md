---
allowed-tools: Bash(~/.claude/scripts/fetch_tg_updates.sh:*)
description: Import the latest N Telegram messages (text + screenshots)
---

## Context

!> **How to use**  
!> `/tg`           – pull just the most recent Telegram message  
!> `/tg 3`         – pull the last three (text + images) in order  

---

### Incoming from Telegram

!`~/.claude/scripts/fetch_tg_updates.sh $1`

---

## Your task

1. Treat the *lines above* exactly as if I had typed them in this order.  
2. Where a line is a **relative image path** (`tmp/telegram/*.jpg`), load that image and reference it when needed.  
3. Proceed with the normal conversation.
