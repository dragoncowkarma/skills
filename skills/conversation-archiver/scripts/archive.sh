#!/bin/bash

# Configuration
CONV_ID=$1
SHIFT_ARGS=1

# Check for flags
RECOVER=false
REINDEX=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --recover) RECOVER=true ;;
        --reindex) REINDEX=true ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -z "$CONV_ID" ]; then
    echo "Usage: ./archive.sh <conversation_id> [--recover] [--reindex]"
    exit 1
fi

# 1. Find APP_DATA_DIR (Agent brain directory)
BRAIN_PATH=$(ls -d ~/.gemini/*/brain/"$CONV_ID" 2>/dev/null | head -n 1)

if [ -z "$BRAIN_PATH" ]; then
    echo "Error: Could not find brain directory for conversation $CONV_ID"
    exit 1
fi

APP_DATA_DIR=$(echo "$BRAIN_PATH" | sed 's|/brain/.*||')
GEMINI_DIR=$(dirname "$(dirname "$APP_DATA_DIR")")

# 2. Identify the Project Root
CURRENT_PWD=$(pwd)
PROJECT_ID=$(find "$GEMINI_DIR/history" -maxdepth 2 -name ".project_root" -exec grep -l "$CURRENT_PWD" {} + 2>/dev/null | head -n 1 | xargs dirname | xargs basename)

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ROOT="$CURRENT_PWD"
else
    PROJECT_ROOT=$(cat "$GEMINI_DIR/history/$PROJECT_ID/.project_root" 2>/dev/null)
fi

ARCHIVE_DIR="$PROJECT_ROOT/history/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"

LOG_FILE="$BRAIN_PATH/.system_generated/logs/overview.txt"
API_DATA_FILE="$ARCHIVE_DIR/api_recovery.json"

# API Recovery if requested
API_DATA_ARG=""
if [ "$RECOVER" = true ]; then
    echo "[*] Running API recovery..."
    python3 "$SCRIPT_DIR/recover.py" api "$CONV_ID" --output "$API_DATA_FILE"
    if [ -f "$API_DATA_FILE" ]; then
        API_DATA_ARG="--api-data $API_DATA_FILE"
    fi
fi

# Reindexing if requested
if [ "$REINDEX" = true ]; then
    echo "[!] To re-index, please paste the following prompt into a NEW chat:"
    echo "----------------------------------------------------------------"
    echo "You MUST use your native, built-in list_dir API tool for this to work correctly. Please execute the following steps exactly:"
    echo "1. Use your list_dir API tool on my absolute path: '~/.gemini/antigravity/conversations/'"
    echo "2. Look at the output and identify every single subdirectory inside it."
    echo "3. Issue a completely separate list_dir API tool call for every single one of those individual subdirectories. You can batch these tool calls."
    echo "4. DO NOT output, print, or summarize the contents in your response."
    echo "5. Simply reply: 'I have successfully pinged all directory contents to trigger your UI refresh'."
    echo "----------------------------------------------------------------"
fi

# Convert Log to Markdown
if [ -f "$LOG_FILE" ]; then
    python3 "$SCRIPT_DIR/markdown_converter.py" "$LOG_FILE" "$ARCHIVE_DIR/conversation_history.md" --root "$PROJECT_ROOT" --brain "$BRAIN_PATH" --home "$HOME" $API_DATA_ARG
    echo "Archived conversation history to $ARCHIVE_DIR/conversation_history.md"
else
    echo "Log file not found at $LOG_FILE"
fi

# Copy Artifacts
IMPL_PLAN="$BRAIN_PATH/implementation_plan.md"
TASK_FILE="$BRAIN_PATH/task.md"
WALKTHROUGH="$BRAIN_PATH/walkthrough.md"

for FILE in "$IMPL_PLAN" "$TASK_FILE" "$WALKTHROUGH"; do
    if [ -f "$FILE" ]; then
        cp "$FILE" "$ARCHIVE_DIR/"
        echo "Archived $(basename "$FILE")."
    fi
done

echo "Archive completed at: $ARCHIVE_DIR"
