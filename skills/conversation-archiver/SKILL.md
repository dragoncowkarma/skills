---
name: conversation-archiver
description: Archive the current conversation state, including Markdown-converted logs, implementation plans, tasks, and walkthroughs.
license: MIT
metadata:
  author: dragoncowkarma
  version: "0.0.2"
  short-description: Automated conversation state archiver.
---

# Conversation Archiver Skill

This skill automates the preservation of session data for long-term tracking and auditing.

## Workflow & Core Rules

1. **[Data Gathering]**:
   - Locate the conversation logs in the `.system_generated/logs` directory.
   - Collect the core planning artifacts: `implementation_plan.md`, `task.md`, and `walkthrough.md`.

2. **[Markdown Conversion]**:
   - Use `scripts/markdown_converter.py` to transform the JSON-formatted `overview.txt` into a human-readable `conversation_history.md`.
   - Ensure the output clearly distinguishes between User and AI roles.

3. **[Archival]**:
   - Create a timestamped directory under `history/`.
   - Move all processed and collected files into this directory.

4. **[Execution]**:
   - Run the skill using the `scripts/archive.sh` script with the current `conversation_id`.
   - Command: `scripts/archive.sh <conversation_id>`
