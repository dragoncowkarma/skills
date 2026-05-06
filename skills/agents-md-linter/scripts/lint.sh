#!/bin/bash

# agents-md-linter wrapper script
# Usage: ./lint.sh <path_to_markdown_file>

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PYTHON_SCRIPT="$SCRIPT_DIR/agents_md_linter.py"

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_markdown_file>"
    exit 1
fi

# Only execute if the file is AGENTS.md or project rules
# Ignore other file updates to avoid redundant runs
FILENAME=$(basename "$1")
if [[ "$FILENAME" != "AGENTS.md" && "$FILENAME" != "SKILL.md" && "$FILENAME" != "RULES.md" ]]; then
    # echo "Skipping linter: $FILENAME is not a core rule document."
    exit 0
fi

python3 "$PYTHON_SCRIPT" "$1"
