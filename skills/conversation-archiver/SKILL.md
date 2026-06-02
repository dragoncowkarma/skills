---
name: conversation-archiver
description: Archive the current conversation state, including Markdown-converted logs, implementation plans, tasks, and walkthroughs.
license: MIT
metadata:
  author: dragoncowkarma
  version: "0.0.3"
  short-description: Automated conversation state archiver.
---

# Conversation Archiver Skill

This skill automates the preservation of session data for long-term tracking and auditing.

## Workflow & Core Rules

1. **[Data Gathering]**:
   - Gemini: locate the conversation log at `.system_generated/logs/overview.txt` below the matching `~/.gemini/*/brain/<conversation_id>` directory.
   - Codex: locate the matching JSONL session under `$CODEX_HOME/sessions` or `$CODEX_HOME/archived_sessions` (`$CODEX_HOME` defaults to `~/.codex`).
   - Collect the core planning artifacts when present: `implementation_plan.md`, `task.md`, and `walkthrough.md`.

2. **[Markdown Conversion]**:
   - Use `scripts/markdown_converter.py` to transform Gemini `overview.txt` or Codex session JSONL into a human-readable `conversation_history.md`.
   - The converter auto-detects the log format, or it can be forced with `--format gemini` or `--format codex`.
   - Ensure the output clearly distinguishes between User and AI roles.

3. **[Archival]**:
   - Create a timestamped directory under `history/`.
   - Copy all processed and collected files into this directory.
   - For Codex sessions, also copy the raw session JSONL as `session.jsonl` and write `archive_manifest.md`.

4. **[Execution]**:
   - Run the skill using the `scripts/archive.sh` script with the current `conversation_id`.
   - Command: `scripts/archive.sh <conversation_id>`
   - Codex convenience commands:
     - `scripts/archive.sh current`
     - `scripts/archive.sh latest`
