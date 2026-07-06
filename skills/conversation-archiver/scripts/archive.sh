#!/bin/bash

set -euo pipefail

CONV_ID=${1:-}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=""
ARCHIVE_SOURCE=""
LOG_FILE=""
BRAIN_PATH=""
SESSION_FILE=""

usage() {
    echo "Usage: ./archive.sh <conversation_id|current|latest>"
}

find_gemini_brain() {
    if [ "$CONV_ID" = "current" ] || [ "$CONV_ID" = "latest" ]; then
        return 1
    fi

    find "$HOME/.gemini" -path "*/brain/$CONV_ID" -type d 2>/dev/null | head -n 1
}

find_codex_session() {
    local codex_home="${CODEX_HOME:-$HOME/.codex}"

    if [ "$CONV_ID" = "current" ] || [ "$CONV_ID" = "latest" ]; then
        find "$codex_home/sessions" -type f -name "*.jsonl" -print0 2>/dev/null \
            | xargs -0 ls -t 2>/dev/null \
            | head -n 1
        return 0
    fi

    {
        find "$codex_home/sessions" -type f -name "*$CONV_ID*.jsonl" 2>/dev/null
        find "$codex_home/archived_sessions" -type f -name "*$CONV_ID*.jsonl" 2>/dev/null
    } | head -n 1
}

codex_session_cwd() {
    python3 -c '
import json
import sys

for line in open(sys.argv[1], encoding="utf-8"):
    try:
        entry = json.loads(line)
    except json.JSONDecodeError:
        continue
    if entry.get("type") == "session_meta":
        cwd = entry.get("payload", {}).get("cwd")
        if cwd:
            print(cwd)
            break
' "$1"
}

in_claude_env() {
    [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]
}

claude_munge_path() {
    # Claude Code stores sessions under projects/<path with non-alphanumerics replaced by "-">
    printf '%s' "$1" | sed 's|[^a-zA-Z0-9]|-|g'
}

find_claude_project_dir() {
    # The Bash cwd may be a subdirectory of the session's start cwd, so walk up
    # until a matching project dir is found.
    local projects_dir="$1"
    local dir
    dir=$(pwd)
    while [ -n "$dir" ]; do
        if [ -d "$projects_dir/$(claude_munge_path "$dir")" ]; then
            echo "$projects_dir/$(claude_munge_path "$dir")"
            return 0
        fi
        [ "$dir" = "/" ] && break
        dir=$(dirname "$dir")
    done
    return 0
}

find_claude_session() {
    local config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    local projects_dir="$config_dir/projects"

    [ -d "$projects_dir" ] || return 0

    # Session logs live at projects/<project-dir>/<session-id>.jsonl; subagent
    # transcripts live deeper (<session-id>/subagents/**/agent-*.jsonl) and must
    # not be picked up.
    if [ "$CONV_ID" = "current" ] || [ "$CONV_ID" = "latest" ]; then
        local project_dir
        project_dir=$(find_claude_project_dir "$projects_dir")
        if [ -n "$project_dir" ]; then
            find "$project_dir" -maxdepth 1 -type f -name "*.jsonl" -print0 2>/dev/null \
                | xargs -0 ls -t 2>/dev/null \
                | head -n 1
        elif [ "$CONV_ID" = "latest" ]; then
            # "latest" may cross projects; "current" must stay within this project.
            find "$projects_dir" -mindepth 2 -maxdepth 2 -type f -name "*.jsonl" -print0 2>/dev/null \
                | xargs -0 ls -t 2>/dev/null \
                | head -n 1
        fi
        return 0
    fi

    find "$projects_dir" -mindepth 2 -maxdepth 2 -type f -name "*$CONV_ID*.jsonl" 2>/dev/null | head -n 1
}

claude_session_cwd() {
    python3 -c '
import json
import sys

for line in open(sys.argv[1], encoding="utf-8"):
    try:
        entry = json.loads(line)
    except json.JSONDecodeError:
        continue
    if entry.get("type") in ("user", "assistant"):
        cwd = entry.get("cwd")
        if cwd:
            print(cwd)
            break
' "$1"
}

gemini_project_root() {
    local brain_path="$1"
    local current_pwd
    local app_data_dir
    local gemini_dir
    local project_id

    current_pwd=$(pwd)
    app_data_dir=$(echo "$brain_path" | sed 's|/brain/.*||')
    gemini_dir=$(dirname "$(dirname "$app_data_dir")")
    project_id=$(find "$gemini_dir/history" -maxdepth 2 -name ".project_root" -exec grep -l "$current_pwd" {} + 2>/dev/null | head -n 1 | xargs dirname 2>/dev/null | xargs basename 2>/dev/null || true)

    if [ -z "$project_id" ]; then
        echo "$current_pwd"
    else
        cat "$gemini_dir/history/$project_id/.project_root" 2>/dev/null || echo "$current_pwd"
    fi
}

copy_artifacts() {
    local search_root="$1"
    for name in implementation_plan.md task.md walkthrough.md; do
        if [ -f "$search_root/$name" ]; then
            cp "$search_root/$name" "$ARCHIVE_DIR/"
            echo "Archived $name."
        fi
    done
}

if [ -z "$CONV_ID" ]; then
    usage
    exit 1
fi

resolve_codex_source() {
    SESSION_FILE="${1:-}"
    if [ -z "$SESSION_FILE" ]; then
        SESSION_FILE=$(find_codex_session || true)
    fi
    if [ -n "$SESSION_FILE" ]; then
        ARCHIVE_SOURCE="codex"
        PROJECT_ROOT=$(codex_session_cwd "$SESSION_FILE")
        if [ -z "$PROJECT_ROOT" ]; then
            PROJECT_ROOT=$(pwd)
        fi
        LOG_FILE="$SESSION_FILE"
    fi
}

resolve_claude_source() {
    SESSION_FILE="${1:-}"
    if [ -z "$SESSION_FILE" ]; then
        SESSION_FILE=$(find_claude_session || true)
    fi
    if [ -n "$SESSION_FILE" ]; then
        ARCHIVE_SOURCE="claude"
        PROJECT_ROOT=$(claude_session_cwd "$SESSION_FILE")
        if [ -z "$PROJECT_ROOT" ]; then
            PROJECT_ROOT=$(pwd)
        fi
        LOG_FILE="$SESSION_FILE"
    fi
}

BRAIN_PATH=$(find_gemini_brain || true)
if [ -n "$BRAIN_PATH" ]; then
    ARCHIVE_SOURCE="gemini"
    PROJECT_ROOT=$(gemini_project_root "$BRAIN_PATH")
    if [ -f "$BRAIN_PATH/.system_generated/logs/transcript.jsonl" ]; then
        LOG_FILE="$BRAIN_PATH/.system_generated/logs/transcript.jsonl"
    else
        LOG_FILE="$BRAIN_PATH/.system_generated/logs/overview.txt"
    fi
elif in_claude_env; then
    resolve_claude_source
    # Inside Claude Code, current/latest means this tool's sessions; do not
    # silently archive another tool's session. Explicit IDs may still match Codex.
    if [ -z "$ARCHIVE_SOURCE" ] && [ "$CONV_ID" != "current" ] && [ "$CONV_ID" != "latest" ]; then
        resolve_codex_source
    fi
elif [ "$CONV_ID" = "current" ] || [ "$CONV_ID" = "latest" ]; then
    # No environment signal: prefer the most recently modified session across tools.
    CODEX_CANDIDATE=$(find_codex_session || true)
    CLAUDE_CANDIDATE=$(find_claude_session || true)
    if [ -n "$CODEX_CANDIDATE" ] && [ -n "$CLAUDE_CANDIDATE" ]; then
        if [ "$(ls -t "$CODEX_CANDIDATE" "$CLAUDE_CANDIDATE" 2>/dev/null | head -n 1)" = "$CLAUDE_CANDIDATE" ]; then
            CODEX_CANDIDATE=""
        else
            CLAUDE_CANDIDATE=""
        fi
    fi
    if [ -n "$CLAUDE_CANDIDATE" ]; then
        resolve_claude_source "$CLAUDE_CANDIDATE"
    elif [ -n "$CODEX_CANDIDATE" ]; then
        resolve_codex_source "$CODEX_CANDIDATE"
    fi
else
    resolve_codex_source
    if [ -z "$ARCHIVE_SOURCE" ]; then
        resolve_claude_source
    fi
fi

if [ -z "$ARCHIVE_SOURCE" ]; then
    echo "Error: Could not find Gemini brain, Codex session, or Claude session for '$CONV_ID'."
    exit 1
fi

ARCHIVE_DIR="$PROJECT_ROOT/history/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"

if [ -f "$LOG_FILE" ]; then
    if [ "$ARCHIVE_SOURCE" = "codex" ] || [ "$ARCHIVE_SOURCE" = "claude" ]; then
        python3 "$SCRIPT_DIR/markdown_converter.py" "$LOG_FILE" "$ARCHIVE_DIR/conversation_history.md" --format "$ARCHIVE_SOURCE" --root "$PROJECT_ROOT" --session "$SESSION_FILE" --home "$HOME"
        cp "$SESSION_FILE" "$ARCHIVE_DIR/session.jsonl"
        echo "Archived raw $ARCHIVE_SOURCE session to $ARCHIVE_DIR/session.jsonl"
        copy_artifacts "$PROJECT_ROOT"
    else
        python3 "$SCRIPT_DIR/markdown_converter.py" "$LOG_FILE" "$ARCHIVE_DIR/conversation_history.md" --format gemini --root "$PROJECT_ROOT" --brain "$BRAIN_PATH" --home "$HOME"
        copy_artifacts "$BRAIN_PATH"
    fi
    echo "Archived conversation history to $ARCHIVE_DIR/conversation_history.md"
else
    echo "Log file not found at $LOG_FILE"
fi

{
    echo "# Archive Manifest"
    echo
    echo "- source: $ARCHIVE_SOURCE"
    echo "- requested_id: $CONV_ID"
    echo "- project_root: $PROJECT_ROOT"
    echo "- log_file: $LOG_FILE"
} > "$ARCHIVE_DIR/archive_manifest.md"

echo "Archive completed at: $ARCHIVE_DIR"
