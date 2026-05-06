#!/bin/bash

# Configuration
CONV_ID=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -z "$CONV_ID" ]; then
    echo "Usage: ./archive.sh <conversation_id>"
    exit 1
fi

# 1. Find APP_DATA_DIR (Agent brain directory)
# We look for a directory under ~/.gemini/*/brain/$CONV_ID
BRAIN_PATH=$(ls -d ~/.gemini/*/brain/"$CONV_ID" 2>/dev/null | head -n 1)

if [ -z "$BRAIN_PATH" ]; then
    echo "Error: Could not find brain directory for conversation $CONV_ID"
    exit 1
fi

# The APP_DATA_DIR is usually the parent of the 'brain' directory
APP_DATA_DIR=$(echo "$BRAIN_PATH" | sed 's|/brain/.*||')
# The base .gemini directory
GEMINI_DIR=$(dirname "$(dirname "$APP_DATA_DIR")")

# 2. Identify the Project Root and History Directory
# We can find the project name/ID by looking for .project_root files in ~/.gemini/history/
# that contain the current working directory.
CURRENT_PWD=$(pwd)
PROJECT_ID=$(find "$GEMINI_DIR/history" -maxdepth 2 -name ".project_root" -exec grep -l "$CURRENT_PWD" {} + 2>/dev/null | head -n 1 | xargs dirname | xargs basename)

if [ -z "$PROJECT_ID" ]; then
    # Fallback to current directory if not found in history
    PROJECT_ROOT="$CURRENT_PWD"
else
    PROJECT_ROOT=$(cat "$GEMINI_DIR/history/$PROJECT_ID/.project_root" 2>/dev/null)
fi

ARCHIVE_DIR="$PROJECT_ROOT/history/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"

LOG_FILE="$BRAIN_PATH/.system_generated/logs/overview.txt"
IMPL_PLAN="$BRAIN_PATH/implementation_plan.md"
TASK_FILE="$BRAIN_PATH/task.md"
WALKTHROUGH="$BRAIN_PATH/walkthrough.md"

# Convert Log to Markdown
if [ -f "$LOG_FILE" ]; then
    python3 "$SCRIPT_DIR/markdown_converter.py" "$LOG_FILE" "$ARCHIVE_DIR/conversation_history.md" --root "$PROJECT_ROOT" --brain "$BRAIN_PATH" --home "$HOME"
    echo "Archived conversation history to $ARCHIVE_DIR/conversation_history.md"
else
    echo "Log file not found at $LOG_FILE"
fi

# Copy Artifacts
for FILE in "$IMPL_PLAN" "$TASK_FILE" "$WALKTHROUGH"; do
    if [ -f "$FILE" ]; then
        cp "$FILE" "$ARCHIVE_DIR/"
        echo "Archived $(basename "$FILE")."
    fi
done

echo "Archive completed at: $ARCHIVE_DIR"
