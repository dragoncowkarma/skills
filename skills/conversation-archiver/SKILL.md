---
name: conversation-archiver
description: Archive the current conversation state, including Markdown-converted logs, implementation plans, tasks, and walkthroughs.
license: MIT
metadata:
  author: dragoncowkarma
  version: "0.0.4"
  short-description: Automated conversation state archiver.
---

# Conversation Archiver Skill

This skill automates the preservation of session data for long-term tracking and auditing.

## Workflow & Core Rules

1. **[Data Gathering]**:
   - Gemini: locate the conversation log at `.system_generated/logs/overview.txt` below the matching `~/.gemini/*/brain/<conversation_id>` directory.
   - Codex: locate the matching JSONL session under `$CODEX_HOME/sessions` or `$CODEX_HOME/archived_sessions` (`$CODEX_HOME` defaults to `~/.codex`).
   - Claude Code: locate the matching JSONL session under `$CLAUDE_CONFIG_DIR/projects/<project-dir>/<session-id>.jsonl` (`$CLAUDE_CONFIG_DIR` defaults to `~/.claude`; `<project-dir>` is the working directory path with non-alphanumeric characters replaced by `-`).
   - Collect the core planning artifacts when present: `implementation_plan.md`, `task.md`, and `walkthrough.md`.

2. **[Markdown Conversion]**:
   - Use `scripts/markdown_converter.py` to transform Gemini `overview.txt`, Codex session JSONL, or Claude Code session JSONL into a human-readable `conversation_history.md`.
   - The converter auto-detects the log format, or it can be forced with `--format gemini`, `--format codex`, or `--format claude`.
   - Ensure the output clearly distinguishes between User and AI roles.

3. **[Archival]**:
   - Create a timestamped directory under `history/`.
   - Copy all processed and collected files into this directory.
   - For Codex and Claude sessions, also copy the raw session JSONL as `session.jsonl` and write `archive_manifest.md`.

4. **[Execution]**:
   - Run the skill using the `scripts/archive.sh` script with the current `conversation_id`.
   - Command: `scripts/archive.sh <conversation_id>`
   - Codex/Claude convenience commands:
     - `scripts/archive.sh current`
     - `scripts/archive.sh latest`
   - When both Codex and Claude sessions exist, `current`/`latest` resolves Claude-only if running inside Claude Code (detected via `$CLAUDECODE` or `$CLAUDE_CODE_ENTRYPOINT`); otherwise the most recently modified session across both tools wins.
   - For Claude sessions, `current` only matches the project for the working directory (walking up parent directories), while `latest` may fall back to the newest session across all projects.
