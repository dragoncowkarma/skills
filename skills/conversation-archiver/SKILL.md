---
name: conversation-archiver
description: Automate the archival of project context (logs, implementation plans, tasks) and recover truncated or missing conversation history.
license: MIT
compatibility: python3
metadata:
  author: dragoncowkarma
  version: "0.0.3"
allowed-tools: bash(./scripts/archive.sh)
---

# Conversation Archiver

Automate the archival of project context (logs, implementation plans, tasks) and recover truncated or missing conversation history.

## When to use

- Before starting a new major task to preserve current state.
- When handing over project context to another agent.
- **NEW**: When a conversation appears truncated or missing from the Antigravity UI.

## Prerequisites & Setup

- Python 3.x
- `pip install antigravity-history` (for recovery features)

## Workflow

### Standard Archival

Run the archiver to save the current conversation state:

```bash
/skills/conversation-archiver/scripts/archive.sh <conversation_id>
```

### Recovery Methods

If your conversation is truncated or missing, use the following methods:

#### Method 1: API Recovery (Recommended)

Fetches the full conversation trajectory via the internal API (bypassing UI truncation).

```bash
/skills/conversation-archiver/scripts/archive.sh <conversation_id> --recover
```

> [!NOTE]
> This requires identifying the `ANTIGRAVITY_PORT` (usually `61749`) and `ANTIGRAVITY_TOKEN` (CSRF token). The script attempts auto-detection, but you can provide them manually via `scripts/recover.py`.

#### Method 2: Forced Re-indexing

If conversations are missing from the sidebar, run:

```bash
/skills/conversation-archiver/scripts/archive.sh <conversation_id> --reindex
```

Follow the printed instructions to paste a specific prompt into a new chat.

#### Method 3: .pb Injection

If the UI index is corrupted, you can inject an old `.pb` file into a new dummy chat:

```bash
python3 scripts/recover.py inject <path_to_old_pb> <new_dummy_id>
```

## Guardrails & Execution Notes

- Always backup `~/.gemini/antigravity/conversations/` before using the `inject` method.
- Archival automatically excludes its own execution logs to prevent circular history.
- Truncated steps in the history will be marked with a `[!WARNING]` block.
