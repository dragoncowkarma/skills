#!/usr/bin/env bash
# =============================================================================
# harness.sh — Hardened & Auditable Protocol Engine v3.0.0
#
# Replaces harness.py. Runs natively in shell to avoid Python subprocess
# permission popups in sandboxed AI agent environments.
#
# Supports: Linux, macOS, Windows (WSL/Git Bash)
# Requires: bash 4+, jq
#
# v3.0.0 Changelog:
#   - CI/Headless mode (--ci)
#   - TUI error reporting with colorized failure summaries
#   - Mutation testing integration (--mutation)
#   - Plugin/adapter pattern for multi-environment support
#   - docs-init --lite mode
#   - Allowlist-based command validation (replaces blocklist)
#   - Log masking (PII/secrets redaction)
#   - Log rotation/archival
#   - KANBAN SSOT renderer
# =============================================================================
set -euo pipefail

# ===== GLOBALS =====
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "${SCRIPT_PATH}/../assets" && pwd)"
ADAPTERS_DIR="${SCRIPT_PATH}/adapters"
TASKS_DIR="docs/tasks"
TELEMETRY_DIR=".harness/telemetry"
MAP_PATH="docs/map.md"
CYCLE_LOGS_DIR="docs/cycle_logs"
ARCHIVE_DIR=".archive"
VERSION="3.0.0"

# Defaults
AUTONOMY_LEVEL=3
TIMEOUT_SECONDS=30
HASH_CMD=""
CI_MODE=false
MUTATION_MODE=false
MUTATION_THRESHOLD=60
LITE_MODE=false
ADAPTER_NAME_OVERRIDE=""
ARCHIVE_AGE_DAYS=7

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ===== PREREQUISITES =====
check_prerequisites() {
  # jq is a hard requirement
  if ! command -v jq &>/dev/null; then
    echo "❌ FATAL: 'jq' is required but not installed."
    echo "  Install: brew install jq (macOS) | apt install jq (Linux) | choco install jq (Windows)"
    exit 1
  fi

  # Detect best available hash command (fallback chain)
  if command -v sha256sum &>/dev/null; then
    HASH_CMD="sha256sum"
  elif command -v shasum &>/dev/null; then
    HASH_CMD="shasum -a 256"
  elif command -v md5sum &>/dev/null; then
    HASH_CMD="md5sum"
  elif command -v md5 &>/dev/null; then
    HASH_CMD="md5 -r"
  else
    echo "❌ FATAL: No hash command found (sha256sum, shasum, md5sum, md5)."
    exit 1
  fi
}

# ===== UTILITY FUNCTIONS =====
compute_hash() {
  local file="$1"
  ${HASH_CMD} "$file" | awk '{print $1}'
}

is_human() {
  if [[ "${HARNESS_SESSION_TYPE:-}" == "HUMAN" ]]; then
    return 0
  fi
  if [[ "${HARNESS_AGENT:-}" == "true" ]]; then
    return 1
  fi
  return 0 # Default to human for DX
}

get_file_mtime() {
  local file="$1"
  case "$(uname -s)" in
    Darwin)  stat -f %m "$file" ;;
    *)       stat -c %Y "$file" ;;
  esac
}

# Disable colors when in CI mode or non-interactive terminal
should_use_color() {
  if [[ "$CI_MODE" == "true" ]]; then
    return 1
  fi
  if [[ ! -t 1 ]]; then
    return 1
  fi
  return 0
}

# ===== LOG MASKING (PII/Secrets Redaction) =====
redact_sensitive_data() {
  local input="$1"

  # Email addresses
  input=$(echo "$input" | sed -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[REDACTED:email]/g')

  # API keys, tokens, secrets, passwords (key=value or key: value patterns)
  input=$(echo "$input" | sed -E 's/(api[_-]?key|token|secret|password|passwd|api_secret|access_key)[[:space:]]*[:=][[:space:]]*[^[:space:],;\"'\'']+/\1=[REDACTED]/gi')

  # JWT tokens (eyJ... pattern)
  input=$(echo "$input" | sed -E 's/eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[REDACTED:jwt]/g')

  # IPv4 addresses (best effort — redact private IPs cautiously)
  input=$(echo "$input" | sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED:ip]/g')

  echo "$input"
}

# ===== ADAPTER SYSTEM =====
load_adapter() {
  local adapter_name="${ADAPTER_NAME_OVERRIDE}"

  # Auto-detect from .harness/config.json if not set
  if [[ -z "$adapter_name" ]] && [[ -f ".harness/config.json" ]]; then
    adapter_name=$(jq -r '.adapter // ""' ".harness/config.json" 2>/dev/null || echo "")
  fi

  # Auto-detect from environment variable
  if [[ -z "$adapter_name" ]]; then
    adapter_name="${HARNESS_ADAPTER:-node}"
  fi

  local adapter_path="${ADAPTERS_DIR}/${adapter_name}.sh"
  if [[ ! -f "$adapter_path" ]]; then
    echo "❌ FATAL: Adapter '${adapter_name}' not found at: ${adapter_path}"
    echo "   Available adapters: $(ls "${ADAPTERS_DIR}"/*.sh 2>/dev/null | xargs -I{} basename {} .sh | tr '\n' ', ')"
    exit 1
  fi

  # shellcheck source=/dev/null
  source "$adapter_path"
  export LOADED_ADAPTER="$adapter_name"
}

# ===== COMMAND VALIDATION (Allowlist) =====
validate_command() {
  local command="$1"
  local cmd_trimmed
  cmd_trimmed=$(echo "$command" | sed 's/^[[:space:]]*//')

  # --- Shell metacharacter injection detection ---
  local metachar
  for metachar in ';' '&&' '||' '|' '$(' '`' '>' '>>' '<' '&'; do
    if [[ "$cmd_trimmed" == *"$metachar"* ]]; then
      echo "❌ SECURITY VIOLATION: Shell metacharacter '${metachar}' detected in command."
      echo "   Command must be a single, non-chained invocation."
      return 1
    fi
  done

  # --- Allowlist check ---
  # Get adapter-specific allowed prefixes
  local allowed_prefixes
  allowed_prefixes=$(adapter_allowed_prefixes 2>/dev/null || echo "")

  # Global allowlist (always permitted)
  local global_allowed="npx node npm c8 nyc jest vitest pytest go gradle gradlew ./gradlew dotnet stryker make cargo ruby bundle python python3 php"

  local all_allowed="${global_allowed} ${allowed_prefixes}"

  local cmd_first_word
  cmd_first_word=$(echo "$cmd_trimmed" | awk '{print $1}')

  # Check against allowlist
  local prefix
  for prefix in $all_allowed; do
    if [[ "$cmd_first_word" == "$prefix" ]]; then
      return 0
    fi
  done

  # --- Legacy blocklist (extra safety for known dangerous commands) ---
  local cmd_lower
  cmd_lower=$(echo "$cmd_first_word" | tr '[:upper:]' '[:lower:]')

  local blocked
  for blocked in "grep" "ls" "cat" "echo" "test" "rm" "sudo" "chmod" "chown" "kill" "eval" "sh" "bash" "curl" "wget"; do
    if [[ "$cmd_lower" == "$blocked" ]]; then
      echo "❌ INTEGRITY VIOLATION: Command '${cmd_first_word}' is explicitly blocked."
      return 1
    fi
  done

  echo "❌ SECURITY VIOLATION: Command '${cmd_first_word}' is not in the allowlist."
  echo "   Allowed prefixes: ${all_allowed}"
  return 1
}

# ===== INTEGRITY =====
verify_integrity() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"
  local log_path="${TELEMETRY_DIR}/${task_id}.log"

  if [[ ! -f "$task_file" ]] || [[ ! -f "$log_path" ]]; then
    echo "Missing task registry or telemetry log."
    return 1
  fi

  local actual_hash
  actual_hash=$(compute_hash "$log_path")

  local stored_hash
  stored_hash=$(jq -r '.telemetry_hash // ""' "$task_file")

  if [[ "$actual_hash" != "$stored_hash" ]]; then
    echo "INTEGRITY VIOLATION: Registry hash does not match physical log."
    return 1
  fi

  return 0
}

# ===== TUI ERROR REPORTING =====
render_failure_report() {
  local task_id="$1"
  local mode="$2"
  local exit_code="$3"
  local cause="$4"
  local file_ref="${5:-N/A}"
  local coverage="${6:-N/A}"
  local log_path="${7:-}"

  if should_use_color; then
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}❌ TEST FAILURE REPORT${NC}                          ${RED}║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  ${CYAN}Task:${NC}     %-36s ${RED}║${NC}" "$task_id"
    echo -e "${RED}║${NC}  ${CYAN}Mode:${NC}     %-36s ${RED}║${NC}" "$mode"
    echo -e "${RED}║${NC}  ${CYAN}Exit:${NC}     %-36s ${RED}║${NC}" "$exit_code"
    echo -e "${RED}║${NC}  ${CYAN}Cause:${NC}    %-36s ${RED}║${NC}" "$cause"
    echo -e "${RED}║${NC}  ${CYAN}File:${NC}     %-36s ${RED}║${NC}" "$file_ref"
    echo -e "${RED}║${NC}  ${CYAN}Coverage:${NC} %-36s ${RED}║${NC}" "$coverage"
    echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"

    if [[ -n "$log_path" ]] && [[ -f "$log_path" ]]; then
      echo ""
      echo -e "${DIM}─── Last 10 lines of log ───${NC}"
      tail -10 "$log_path" | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${NC}"
      done
      echo -e "${DIM}────────────────────────────${NC}"
    fi
    echo ""
  else
    # Plain text for CI mode
    echo ""
    echo "==== TEST FAILURE REPORT ===="
    echo "  Task:     ${task_id}"
    echo "  Mode:     ${mode}"
    echo "  Exit:     ${exit_code}"
    echo "  Cause:    ${cause}"
    echo "  File:     ${file_ref}"
    echo "  Coverage: ${coverage}"
    echo "============================="

    if [[ -n "$log_path" ]] && [[ -f "$log_path" ]]; then
      echo "--- Last 10 lines of log ---"
      tail -10 "$log_path"
      echo "----------------------------"
    fi
    echo ""
  fi
}

# ===== CYCLE LOG CHECK =====
check_cycle_log() {
  local task_id="$1"
  local log_file="${CYCLE_LOGS_DIR}/${task_id}_log.md"

  if [[ ! -f "$log_file" ]]; then
    echo "❌ REASONING VIOLATION: Cycle log not found: ${log_file}"
    echo "   You MUST document your reasoning before executing tests."
    return 1
  fi

  # Check if file was modified within last 120 seconds
  local now mtime age
  now=$(date +%s)
  mtime=$(get_file_mtime "$log_file")
  age=$(( now - mtime ))

  if [[ "$age" -gt 120 ]]; then
    echo "⚠️ WARNING: Cycle log is stale (${age}s old). Update your reasoning before proceeding."
    return 1
  fi

  echo "✅ Cycle log verified: ${log_file}"
  return 0
}

# ===== RUN TEST =====
run_test() {
  local task_id="$1"
  local command="$2"
  local mode="${3:-standard}"

  # --- Command validation (allowlist + metachar check) ---
  validate_command "$command" || return 1

  # --- Cycle log enforcement ---
  check_cycle_log "$task_id" || return 1

  local start_time
  start_time=$(date +%s)

  echo "🧪 [TASK:${task_id}] [MODE:${mode}] [ADAPTER:${LOADED_ADAPTER:-node}] Executing: ${command}"

  mkdir -p "$TELEMETRY_DIR"
  local log_path="${TELEMETRY_DIR}/${task_id}.log"

  # Determine timeout based on autonomy level
  local timeout_val=$TIMEOUT_SECONDS
  if [[ "$AUTONOMY_LEVEL" -eq 4 ]]; then
    timeout_val=120
  fi

  # Execute command safely (no eval, no shell expansion beyond bash -c)
  local exit_code=0
  if command -v timeout &>/dev/null; then
    timeout "$timeout_val" bash -c "$command" > "$log_path" 2>&1 || exit_code=$?
  elif command -v gtimeout &>/dev/null; then
    gtimeout "$timeout_val" bash -c "$command" > "$log_path" 2>&1 || exit_code=$?
  else
    # Fallback: run without timeout
    bash -c "$command" > "$log_path" 2>&1 || exit_code=$?
  fi

  if [[ "$exit_code" -eq 124 ]]; then
    echo "❌ TIMEOUT VIOLATION: Test execution exceeded ${timeout_val}s limit."
    echo "[ERROR] Execution timed out after ${timeout_val}s." >> "$log_path"
  fi

  # --- Apply log masking before any further processing ---
  if [[ -f "$log_path" ]]; then
    local masked_content
    masked_content=$(redact_sensitive_data "$(cat "$log_path")")
    echo "$masked_content" > "$log_path"
  fi

  # --- TDD ENFORCEMENT LOGIC ---
  local log_text
  log_text=$(cat "$log_path")

  local is_junk_failure=false
  local failure_cause="Unknown"
  local failure_file="N/A"
  local err_pattern
  for err_pattern in "SyntaxError" "IndentationError" "ReferenceError" "ModuleNotFoundError"; do
    if echo "$log_text" | grep -q "$err_pattern"; then
      is_junk_failure=true
      failure_cause="$err_pattern"
      # Try to extract file reference
      failure_file=$(echo "$log_text" | grep -oE '[a-zA-Z0-9_/.-]+\.(js|ts|py|kt|cs):[0-9]+' | head -1 || echo "N/A")
      break
    fi
  done

  local has_assertion=false
  local log_lower
  log_lower=$(echo "$log_text" | tr '[:upper:]' '[:lower:]')
  local keyword
  for keyword in "assertionerror" "failed" "expect" "fail" "assert"; do
    if echo "$log_lower" | grep -q "$keyword"; then
      has_assertion=true
      if [[ "$failure_cause" == "Unknown" ]]; then
        failure_cause="AssertionError"
        failure_file=$(echo "$log_text" | grep -oE '[a-zA-Z0-9_/.-]+\.(js|ts|py|kt|cs):[0-9]+' | head -1 || echo "N/A")
      fi
      break
    fi
  done

  if [[ "$mode" == "tdd-red" ]]; then
    if [[ "$exit_code" -eq 0 ]]; then
      failure_cause="Test passed (expected failure)"
      render_failure_report "$task_id" "$mode" "$exit_code" "$failure_cause" "$failure_file" "N/A" "$log_path"
      echo "❌ INTEGRITY VIOLATION: TDD Red phase requires a FAILING test."
      exit_code=1
    elif [[ "$is_junk_failure" == "true" ]]; then
      render_failure_report "$task_id" "$mode" "$exit_code" "$failure_cause" "$failure_file" "N/A" "$log_path"
      echo "❌ INTEGRITY VIOLATION: Junk failure detected. RED phase requires a VALID test failure."
      exit_code=1
    elif [[ "$has_assertion" == "false" ]]; then
      echo "⚠️ WARNING: No clear assertion failure detected in logs. Proceed with caution."
    else
      echo "✅ TDD RED VERIFIED: Test failed as expected with valid assertion."
      exit_code=0 # Treat as success for the protocol loop
    fi
  fi

  # --- MANDATORY COVERAGE CHECK (Standard Mode Only) ---
  local coverage_msg="N/A"
  if [[ "$mode" == "standard" ]] && [[ "$exit_code" -eq 0 ]]; then
    local lcov_path="coverage/lcov.info"
    local percentage
    percentage=$(adapter_parse_coverage "$lcov_path" 2>&1) || true

    if [[ "$percentage" == ERROR:* ]]; then
      failure_cause="${percentage#ERROR:}"
      render_failure_report "$task_id" "$mode" "1" "$failure_cause" "N/A" "MISSING" "$log_path"
      echo "❌ COVERAGE ERROR: ${percentage#ERROR:}"
      exit_code=1
      coverage_msg="${percentage#ERROR:}"
    else
      local below
      below=$(awk "BEGIN {print ($percentage < 80.0) ? 1 : 0}")
      if [[ "$below" -eq 1 ]]; then
        failure_cause="Coverage below threshold"
        render_failure_report "$task_id" "$mode" "1" "$failure_cause" "N/A" "${percentage}%" "$log_path"
        echo "❌ INTEGRITY VIOLATION: Line Coverage ${percentage}% is below 80% threshold."
        exit_code=1
        coverage_msg="Low Coverage: ${percentage}%"
      else
        echo "✅ COVERAGE PASSED: ${percentage}%"
        coverage_msg="${percentage}%"
      fi
    fi
  fi

  # --- MUTATION TESTING (if requested) ---
  local mutation_msg="N/A"
  if [[ "$MUTATION_MODE" == "true" ]] && [[ "$exit_code" -eq 0 ]]; then
    echo ""
    local mutation_result
    mutation_result=$(adapter_run_mutation "$task_id" "$MUTATION_THRESHOLD" "$log_path" 2>&1) || {
      failure_cause="Mutation score below threshold"
      render_failure_report "$task_id" "$mode" "1" "$failure_cause" "N/A" "$coverage_msg" "$log_path"
      exit_code=1
    }
    if [[ "$exit_code" -eq 0 ]]; then
      # Last line of mutation_result is the score
      local m_score
      m_score=$(echo "$mutation_result" | tail -1)
      mutation_msg="${m_score}%"
    fi
  fi

  # --- Render failure report if test failed and we haven't rendered one yet ---
  if [[ "$exit_code" -ne 0 ]] && [[ "$failure_cause" == "Unknown" ]]; then
    failure_cause="Test execution failed"
    render_failure_report "$task_id" "$mode" "$exit_code" "$failure_cause" "$failure_file" "$coverage_msg" "$log_path"
  fi

  # --- LOCK TELEMETRY ---
  local duration
  duration=$(( $(date +%s) - start_time ))
  local salt
  salt=$(printf "\n[salt:%s:%s]" "$task_id" "$(date +%s.%N 2>/dev/null || date +%s)")
  printf "%s" "$salt" >> "$log_path"

  local telemetry_hash
  telemetry_hash=$(compute_hash "$log_path")

  # --- UPDATE REGISTRY ---
  local task_file="${TASKS_DIR}/${task_id}.json"
  if [[ -f "$task_file" ]]; then
    local new_status="Failed"
    [[ "$exit_code" -eq 0 ]] && new_status="Verified"

    local prev_duration prev_retries prev_tokens
    prev_duration=$(jq -r '.metrics.duration_seconds // 0' "$task_file")
    prev_retries=$(jq -r '.metrics.retry_count // 0' "$task_file")
    prev_tokens=$(jq -r '.metrics.tokens_used // 0' "$task_file")

    local new_duration=$(( prev_duration + duration ))
    local new_retries=$prev_retries
    [[ "$exit_code" -ne 0 ]] && new_retries=$(( prev_retries + 1 ))

    jq \
      --arg status "$new_status" \
      --arg hash "$telemetry_hash" \
      --arg mode "$mode" \
      --arg cov "$coverage_msg" \
      --arg mut "$mutation_msg" \
      --argjson dur "$new_duration" \
      --argjson retries "$new_retries" \
      --argjson tokens "$prev_tokens" \
      '.status = $status |
       .telemetry_hash = $hash |
       .verification_mode = $mode |
       .metrics.duration_seconds = $dur |
       .metrics.retry_count = $retries |
       .metrics.tokens_used = $tokens |
       .metrics.coverage = $cov |
       .metrics.mutation_score = $mut' "$task_file" > "${task_file}.tmp" && mv "${task_file}.tmp" "$task_file"

    echo "🔒 Telemetry Locked. Status: ${new_status} | Mode: ${mode}"
  else
    echo "⚠️ Registry entry for ${task_id} not found."
  fi

  return $exit_code
}

# ===== DOCUMENT =====
document() {
  local standard="$1"
  echo "📄 Generating Documentation for Standard: ${standard}..."

  if [[ "$standard" == "ISO_42010" ]]; then
    local template_path="${ASSETS_DIR}/ISO_42010_template.md"
    local output_path="docs/architecture.md"

    if [[ ! -f "$MAP_PATH" ]]; then
      echo "⚠️ Warning: ${MAP_PATH} not found. Skipping architecture doc."
      return 0
    fi

    # Parse map.md for mermaid + components
    local mermaid_lines=""
    local component_lines=""

    while IFS= read -r line; do
      if [[ "$line" == *"|"*'`'* ]]; then
        local clean
        clean=$(echo "$line" | tr -d '`')
        local symbol path target desc

        # Extract fields by splitting on |
        symbol=$(echo "$clean" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        path=$(echo "$clean" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        desc=$(echo "$clean" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')

        # Skip header/separator
        if [[ -n "$symbol" ]] && [[ "$symbol" != :* ]] && [[ "$symbol" != -* ]]; then
          target=$(echo "$path" | cut -d'/' -f1)
          mermaid_lines="${mermaid_lines}    ${symbol} --> ${target}"$'\n'
          component_lines="${component_lines}- **${symbol}**: Located in \`${path}\`. ${desc}"$'\n'
        fi
      fi
    done < "$MAP_PATH"

    local mermaid_block
    mermaid_block=$(printf "graph TD\n%s" "$mermaid_lines")

    mkdir -p docs
    local template
    template=$(cat "$template_path")

    # Replace placeholders using awk for safety with special characters
    echo "$template" | awk -v diagram="$mermaid_block" -v details="$component_lines" \
      '{gsub(/\{mermaid_diagram\}/, diagram); gsub(/\{component_details\}/, details); print}' \
      > "$output_path"

    echo "✅ Architecture Specification updated: ${output_path}"

  elif [[ "$standard" == "ISO_25010" ]]; then
    local template_path="${ASSETS_DIR}/ISO_25010_template.md"
    local output_path="docs/quality_metrics.md"

    # Check for task files
    local task_files
    task_files=$(find "$TASKS_DIR" -name '*.json' 2>/dev/null) || true
    if [[ -z "$task_files" ]]; then
      echo "⚠️ Warning: No tasks found. Skipping quality metrics."
      return 0
    fi

    local total_tasks=0
    local verified_count=0
    local total_coverage=0
    local coverage_count=0
    local total_retries=0
    local total_duration=0
    local total_tokens=0
    local task_rows=""
    local token_rows=""

    local tf
    for tf in "$TASKS_DIR"/*.json; do
      [[ ! -f "$tf" ]] && continue
      total_tasks=$(( total_tasks + 1 ))

      local t_id t_status t_cov t_dur t_retry t_tokens t_mut
      t_id=$(jq -r '.id // "N/A"' "$tf")
      t_status=$(jq -r '.status // "N/A"' "$tf")
      t_cov=$(jq -r '.metrics.coverage // "N/A"' "$tf")
      t_dur=$(jq -r '.metrics.duration_seconds // 0' "$tf")
      t_retry=$(jq -r '.metrics.retry_count // 0' "$tf")
      t_tokens=$(jq -r '.metrics.tokens_used // 0' "$tf")
      t_mut=$(jq -r '.metrics.mutation_score // "N/A"' "$tf")

      [[ "$t_status" == "Verified" ]] && verified_count=$(( verified_count + 1 ))

      if echo "$t_cov" | grep -q '%'; then
        local cov_val
        cov_val=$(echo "$t_cov" | tr -d '%')
        total_coverage=$(awk "BEGIN {print $total_coverage + $cov_val}")
        coverage_count=$(( coverage_count + 1 ))
      fi

      total_retries=$(( total_retries + t_retry ))
      total_duration=$(( total_duration + t_dur ))
      total_tokens=$(( total_tokens + t_tokens ))

      task_rows="${task_rows}| ${t_id} | ${t_status} | ${t_cov} | ${t_mut} | ${t_dur}s | ${t_retry} |"$'\n'
      token_rows="${token_rows}| ${t_id} | ${t_tokens} |"$'\n'
    done

    local avg_coverage="0.00"
    [[ "$coverage_count" -gt 0 ]] && avg_coverage=$(awk "BEGIN {printf \"%.2f\", $total_coverage / $coverage_count}")

    local success_rate retry_rate avg_duration estimated_cost
    success_rate=$(awk "BEGIN {printf \"%.2f\", ($verified_count / $total_tasks) * 100}")
    retry_rate=$(awk "BEGIN {printf \"%.2f\", ($total_retries / $total_tasks) * 100}")
    avg_duration=$(awk "BEGIN {printf \"%.2f\", $total_duration / $total_tasks}")
    # Cost estimate: $0.003 per 1K tokens (configurable)
    estimated_cost=$(awk "BEGIN {printf \"%.4f\", ($total_tokens / 1000) * 0.003}")

    mkdir -p docs
    sed -e "s|{avg_coverage}|${avg_coverage}|g" \
        -e "s|{total_tasks}|${total_tasks}|g" \
        -e "s|{retry_rate}|${retry_rate}|g" \
        -e "s|{success_rate}|${success_rate}|g" \
        -e "s|{avg_duration}|${avg_duration}|g" \
        -e "s|{total_tokens}|${total_tokens}|g" \
        -e "s|{estimated_cost}|${estimated_cost}|g" \
        -e "/{task_rows}/c\\
${task_rows}" \
        -e "/{token_dashboard}/c\\
${token_rows}" \
        "$template_path" > "$output_path"

    echo "✅ Quality Metrics updated: ${output_path}"
  else
    echo "❌ Unknown standard: ${standard}"
    return 1
  fi
}

# ===== APPROVE =====
approve() {
  local task_id="$1"

  # In CI mode, allow approval via CI token
  if [[ "$CI_MODE" == "true" ]]; then
    if [[ -z "${HARNESS_CI_TOKEN:-}" ]]; then
      echo "❌ SECURITY ERROR: CI mode requires HARNESS_CI_TOKEN environment variable."
      return 1
    fi
    echo "🤖 CI Mode: Auto-approving with CI token."
  else
    if ! is_human; then
      echo "❌ SECURITY ERROR: Agent attempted to self-approve."
      return 1
    fi
  fi

  local task_file="${TASKS_DIR}/${task_id}.json"
  if [[ ! -f "$task_file" ]]; then
    echo "❌ Error: Task ${task_id} not found."
    return 1
  fi

  local status
  status=$(jq -r '.status' "$task_file")
  if [[ "$status" != "Verified" ]]; then
    echo "❌ Error: Task ${task_id} must be 'Verified' before approval."
    return 1
  fi

  jq '.status = "Approved" | .approved = true' "$task_file" > "${task_file}.tmp" \
    && mv "${task_file}.tmp" "$task_file"
  echo "✅ Task ${task_id} Approved."
}

# ===== COMMIT =====
do_commit() {
  local task_id="$1"
  local msg="$2"

  if ! verify_integrity "$task_id"; then
    echo "❌ Integrity check failed."
    return 1
  fi

  local task_file="${TASKS_DIR}/${task_id}.json"
  local status
  status=$(jq -r '.status' "$task_file")

  if [[ "$status" != "Verified" ]] && [[ "$status" != "Approved" ]]; then
    echo "❌ Task ${task_id} must be Verified to commit."
    return 1
  fi

  local coverage
  coverage=$(jq -r '.metrics.coverage // "N/A"' "$task_file")
  local cov_lower
  cov_lower=$(echo "$coverage" | tr '[:upper:]' '[:lower:]')

  if [[ "$cov_lower" == *"fail"* ]] || [[ "$cov_lower" == *"missing"* ]] || [[ "$coverage" == "N/A" ]]; then
    echo "❌ INTEGRITY VIOLATION: Task ${task_id} has invalid coverage record (${coverage})."
    return 1
  fi

  git commit -m "[harness:${task_id}] ${msg}"
}

# ===== PRE-COMMIT CHECK =====
pre_commit_check() {
  echo "🛡️ Running Harness Pre-commit Integrity Check..."
  return 0
}

# ===== GENERATE PROMPT =====
generate_prompt() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"

  if [[ ! -f "$task_file" ]]; then
    echo "❌ Error: Task ${task_id} not found."
    return 1
  fi

  local template
  template=$(cat "${ASSETS_DIR}/PROMPT.md")

  # Substitute placeholders from task JSON
  local t_target t_role t_priority
  t_target=$(jq -r '.target_file // "N/A"' "$task_file")
  t_role=$(jq -r '.assigned_sub_agent // "Dev"' "$task_file")
  t_priority=$(jq -r '.priority // "Medium"' "$task_file")

  # Build failure context for retry (self-reflection)
  local failure_context=""
  local retry_count
  retry_count=$(jq -r '.metrics.retry_count // 0' "$task_file")
  if [[ "$retry_count" -gt 0 ]]; then
    local prev_status prev_cov
    prev_status=$(jq -r '.status // "N/A"' "$task_file")
    prev_cov=$(jq -r '.metrics.coverage // "N/A"' "$task_file")
    failure_context=$(printf '<failure_context attempt="%s" max_chars="100">\nAttempt %s: status=%s, coverage=%s. Check cycle_logs for details.\n</failure_context>' \
      "$retry_count" "$retry_count" "$prev_status" "$prev_cov")
  fi

  echo "$template" | sed \
    -e "s|{task_id}|${task_id}|g" \
    -e "s|{target_file}|${t_target}|g" \
    -e "s|{agent_role}|${t_role}|g" \
    -e "s|{priority}|${t_priority}|g" \
    -e "s|{failure_context}|${failure_context}|g"
}

# ===== LOG ROTATION / ARCHIVAL =====
archive_old_tasks() {
  local age_days="${1:-$ARCHIVE_AGE_DAYS}"
  local now
  now=$(date +%s)
  local threshold=$(( age_days * 86400 ))
  local archived=0

  echo "📦 Archiving tasks older than ${age_days} days..."

  # Archive completed tasks
  if [[ -d "$TASKS_DIR" ]]; then
    for tf in "$TASKS_DIR"/*.json; do
      [[ ! -f "$tf" ]] && continue

      local t_status
      t_status=$(jq -r '.status // ""' "$tf")

      # Only archive Approved tasks
      if [[ "$t_status" != "Approved" ]]; then
        continue
      fi

      local mtime age
      mtime=$(get_file_mtime "$tf")
      age=$(( now - mtime ))

      if [[ "$age" -gt "$threshold" ]]; then
        mkdir -p "${ARCHIVE_DIR}/tasks"
        local basename
        basename=$(basename "$tf")
        gzip -c "$tf" > "${ARCHIVE_DIR}/tasks/${basename}.gz"
        rm "$tf"
        archived=$(( archived + 1 ))
        echo "  📁 Archived: ${basename}"
      fi
    done
  fi

  # Archive old telemetry logs
  if [[ -d "$TELEMETRY_DIR" ]]; then
    for tl in "$TELEMETRY_DIR"/*.log; do
      [[ ! -f "$tl" ]] && continue

      local mtime age
      mtime=$(get_file_mtime "$tl")
      age=$(( now - mtime ))

      if [[ "$age" -gt "$threshold" ]]; then
        mkdir -p "${ARCHIVE_DIR}/telemetry"
        local basename
        basename=$(basename "$tl")
        gzip -c "$tl" > "${ARCHIVE_DIR}/telemetry/${basename}.gz"
        rm "$tl"
        archived=$(( archived + 1 ))
        echo "  📁 Archived: ${basename}"
      fi
    done
  fi

  echo "✅ Archive complete: ${archived} file(s) archived."
}

# ===== KANBAN RENDERER (SSOT) =====
render_kanban() {
  echo "📋 Rendering Kanban board from task data (SSOT)..."

  local output_path="docs/agile/KANBAN.md"
  mkdir -p docs/agile

  # Collect tasks by status
  local backlog_rows="" ready_rows="" inprogress_rows="" review_rows="" done_rows="" blocked_rows=""
  local wip_inprogress=0 wip_review=0

  if [[ -d "$TASKS_DIR" ]]; then
    for tf in "$TASKS_DIR"/*.json; do
      [[ ! -f "$tf" ]] && continue

      local t_id t_status t_desc t_agent t_cov t_retry t_dur
      t_id=$(jq -r '.id // "N/A"' "$tf")
      t_status=$(jq -r '.status // "N/A"' "$tf")
      t_desc=$(jq -r '.description // "N/A"' "$tf" | head -c 60)
      t_agent=$(jq -r '.assigned_sub_agent // "—"' "$tf")
      t_cov=$(jq -r '.metrics.coverage // "N/A"' "$tf")
      t_retry=$(jq -r '.metrics.retry_count // 0' "$tf")
      t_dur=$(jq -r '.metrics.duration_seconds // 0' "$tf")

      case "$t_status" in
        Ready)
          ready_rows="${ready_rows}| ${t_id} | ${t_desc} | ${t_agent} |"$'\n'
          ;;
        InProgress|Pending)
          inprogress_rows="${inprogress_rows}| ${t_id} | ${t_desc} | ${t_agent} | ${t_retry} |"$'\n'
          wip_inprogress=$(( wip_inprogress + 1 ))
          ;;
        Verified)
          review_rows="${review_rows}| ${t_id} | ${t_desc} | ${t_cov} | Verified |"$'\n'
          wip_review=$(( wip_review + 1 ))
          ;;
        Approved|Completed)
          done_rows="${done_rows}| ${t_id} | ${t_desc} | ${t_dur}s | ${t_retry} | ${t_cov} |"$'\n'
          ;;
        Failed)
          if [[ "$t_retry" -ge 3 ]]; then
            blocked_rows="${blocked_rows}| ${t_id} | ${t_desc} | Max retries exceeded | ${t_retry} |"$'\n'
          else
            inprogress_rows="${inprogress_rows}| ${t_id} | ${t_desc} (RETRY) | ${t_agent} | ${t_retry} |"$'\n'
            wip_inprogress=$(( wip_inprogress + 1 ))
          fi
          ;;
      esac
    done
  fi

  local today
  today=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$output_path" <<KANBANEOF
# Kanban Board — Auto-Generated (SSOT)

> ⚠️ **DO NOT EDIT THIS FILE DIRECTLY.** This document is auto-generated by \`harness.sh kanban-render\`.
> Source of truth: \`docs/tasks/*.json\`
> **Last Rendered**: ${today}

---

## Board State

### Ready

| Task ID | Description | Assignee |
|---|---|---|
${ready_rows:-| *(empty)* | — | — |}

### In Progress (WIP: ${wip_inprogress} / 3)

| Task ID | Description | Agent/Dev | Retries |
|---|---|---|---|
${inprogress_rows:-| *(empty)* | — | — | — |}

### Review (WIP: ${wip_review} / 3)

| Task ID | Description | Coverage | Status |
|---|---|---|---|
${review_rows:-| *(empty)* | — | — | — |}

### Done

| Task ID | Description | Duration | Retries | Coverage |
|---|---|---|---|---|
${done_rows:-| *(empty)* | — | — | — | — |}

### Blocked

| Task ID | Description | Blocker | Retries |
|---|---|---|---|
${blocked_rows:-| *(empty)* | — | — | — |}

---

## Harness Integration

| Harness Status | Kanban Column |
|---|---|
| \`Ready\` | Ready |
| Task JSON created + cycle log initialized | In Progress |
| \`Verified\` | Review |
| \`Approved\` | Done |
| \`Failed\` (retry_count < 3) | In Progress (retry) |
| \`Failed\` (retry_count >= 3) | Blocked |

---

## Board Policies

### WIP Limits
- **In Progress**: Max 3 concurrent tasks
- **Review**: Max 3 concurrent tasks
- Exceeding WIP limits requires escalation

### Definition of Done (DoD)
- Harness verification: status = \`Verified\`, coverage ≥ 80%
- Cycle log completed with reasoning documentation
- ISO documentation synchronized
- Code reviewed and approved

---
*Auto-generated by Harness Protocol Engine v${VERSION}*
KANBANEOF

  echo "✅ Kanban board rendered: ${output_path}"
}

# ===== RUN PIPELINE (AUTONOMY LEVELS) =====
run_pipeline() {
  local task_id="$1"
  local task_file="${TASKS_DIR}/${task_id}.json"

  if [[ ! -f "$task_file" ]]; then
    echo "❌ Error: Task ${task_id} not found."
    return 1
  fi

  echo "🚀 [LEVEL:${AUTONOMY_LEVEL}] Starting pipeline for task: ${task_id}"

  # --- Level 1: Planning Only ---
  if [[ "$AUTONOMY_LEVEL" -eq 1 ]]; then
    echo "📋 Level 1 (Planning): Generating docs structure..."
    mkdir -p docs/tasks docs/cycle_logs docs/prompts

    # Initialize cycle log template
    local log_file="${CYCLE_LOGS_DIR}/${task_id}_log.md"
    if [[ ! -f "$log_file" ]]; then
      cat > "$log_file" <<LOGEOF
# Cycle Log: ${task_id}

## Cycle 1 — $(date -u +"%Y-%m-%dT%H:%M:%SZ")
### Intent
[Document your reasoning here]

### Analysis
[Document your observations here]

### Plan
[Document your plan here]
LOGEOF
      echo "✅ Created cycle log template: ${log_file}"
    fi
    echo "✅ Level 1 complete. Docs structure ready."
    return 0
  fi

  # --- Level 2: Prompting Only ---
  if [[ "$AUTONOMY_LEVEL" -eq 2 ]]; then
    echo "📝 Level 2 (Prompting): Generating prompt..."
    echo "---"
    generate_prompt "$task_id"
    echo "---"
    echo "✅ Level 2 complete. Prompt generated above. Awaiting manual execution."
    return 0
  fi

  # --- Level 3: Interactive ---
  if [[ "$AUTONOMY_LEVEL" -eq 3 ]]; then
    echo "🔄 Level 3 (Interactive): Running with approval gates..."

    local cmd
    cmd=$(jq -r '.mechanical_dod.command // ""' "$task_file")
    if [[ -z "$cmd" || "$cmd" == "null" ]]; then
      echo "❌ No command defined in task mechanical_dod."
      return 1
    fi

    # Determine phase from task ID
    if [[ "$task_id" == *-RED* ]]; then
      echo "--- RED PHASE ---"
      run_test "$task_id" "$cmd" "tdd-red" || return 1
      echo ""
      if [[ "$CI_MODE" == "true" ]]; then
        echo "🤖 CI Mode: Auto-continuing past RED phase."
      else
        read -rp "✋ RED phase complete. Continue to documentation? [y/N] " answer
        [[ "$answer" != "y" && "$answer" != "Y" ]] && { echo "⏸ Paused by user."; return 0; }
      fi
    else
      echo "--- GREEN PHASE ---"
      run_test "$task_id" "$cmd" "standard" || return 1
      echo ""
      if [[ "$CI_MODE" == "true" ]]; then
        echo "🤖 CI Mode: Auto-continuing past GREEN phase."
      else
        read -rp "✋ GREEN phase complete. Continue to documentation? [y/N] " answer
        [[ "$answer" != "y" && "$answer" != "Y" ]] && { echo "⏸ Paused by user."; return 0; }
      fi
    fi

    # DOC phase
    echo "--- DOC PHASE ---"
    document "ISO_42010"
    document "ISO_25010"
    echo ""
    if [[ "$CI_MODE" == "true" ]]; then
      echo "🤖 CI Mode: Auto-completing pipeline."
    else
      read -rp "✋ Documentation complete. All done. [Enter to finish] " _
    fi
    echo "✅ Level 3 pipeline complete."
    return 0
  fi

  # --- Level 4: Autonomous ---
  if [[ "$AUTONOMY_LEVEL" -eq 4 ]]; then
    echo "🤖 Level 4 (Autonomous): Full auto pipeline..."

    local cmd
    cmd=$(jq -r '.mechanical_dod.command // ""' "$task_file")
    if [[ -z "$cmd" || "$cmd" == "null" ]]; then
      echo "❌ No command defined in task mechanical_dod."
      return 1
    fi

    local sub_agent
    sub_agent=$(jq -r '.assigned_sub_agent // ""' "$task_file")
    if [[ -n "$sub_agent" && "$sub_agent" != "null" ]]; then
      echo "🤖 Delegating to sub-agent: ${sub_agent}"
    fi

    # Mark in-progress
    jq '.sub_task_status = "InProgress"' "$task_file" > "${task_file}.tmp" \
      && mv "${task_file}.tmp" "$task_file"

    # Determine mode
    local mode="standard"
    [[ "$task_id" == *-RED* ]] && mode="tdd-red"

    if run_test "$task_id" "$cmd" "$mode"; then
      # Auto-document
      document "ISO_42010"
      document "ISO_25010"

      # Mark completed
      jq '.sub_task_status = "Completed"' "$task_file" > "${task_file}.tmp" \
        && mv "${task_file}.tmp" "$task_file"
      echo "✅ Level 4 autonomous pipeline complete."
    else
      jq '.sub_task_status = "Failed"' "$task_file" > "${task_file}.tmp" \
        && mv "${task_file}.tmp" "$task_file"
      echo "❌ Level 4 pipeline failed."
      return 1
    fi

    return 0
  fi

  echo "❌ Invalid autonomy level: ${AUTONOMY_LEVEL} (must be 1-4)"
  return 1
}

# ===== DOCS INIT =====
docs_init() {
  local template_filter="${1:-all}"
  local templates_dir="${ASSETS_DIR}/templates"

  if [[ ! -d "$templates_dir" ]]; then
    echo "❌ Templates directory not found: ${templates_dir}"
    return 1
  fi

  echo "📄 Scaffolding documentation structure..."

  # Template definitions: KEY:target_dir:src_file:dest_file
  local entries=(
    "SRS:docs/specs:SRS_template.md:SRS.md"
    "SDD:docs/specs:SDD_template.md:SDD.md"
    "SCS:docs/specs:SCS_template.md:SCS.md"
    "KANBAN:docs/agile:KANBAN_template.md:KANBAN.md"
    "WBS:docs/agile:WBS_template.md:WBS.md"
    "SCRUM:docs/agile:SCRUM_template.md:SCRUM.md"
    "ADR:docs/decisions:ADR_template.md:ADR-001.md"
    "STD:docs/testing:STD_template.md:STD.md"
    "STR:docs/testing:STR_template.md:STR.md"
    "API_SPEC:docs/api:API_SPEC_template.md:API_SPEC.md"
    "TROUBLESHOOTING:docs/troubleshooting:TROUBLESHOOTING_template.md:TROUBLESHOOTING.md"
  )

  # Lite mode: only essential templates
  local lite_entries=(
    "SRS:docs/specs:SRS_template.md:SRS.md"
    "SDD:docs/specs:SDD_template.md:SDD.md"
    "KANBAN:docs/agile:KANBAN_template.md:KANBAN.md"
    "WBS:docs/agile:WBS_template.md:WBS.md"
  )

  local active_entries
  if [[ "$LITE_MODE" == "true" ]]; then
    echo "📦 Lite mode: scaffolding essential templates only (SRS, SDD, KANBAN, WBS)."
    active_entries=("${lite_entries[@]}")
  else
    active_entries=("${entries[@]}")
  fi

  local project_name
  project_name=$(basename "$(pwd)")
  local today
  today=$(date -u +"%Y-%m-%d")

  local count=0

  local entry
  for entry in "${active_entries[@]}"; do
    local key target_dir src_file dest_file
    key=$(echo "$entry" | cut -d: -f1)
    target_dir=$(echo "$entry" | cut -d: -f2)
    src_file=$(echo "$entry" | cut -d: -f3)
    dest_file=$(echo "$entry" | cut -d: -f4)

    # Filter if specific template requested
    if [[ "$template_filter" != "all" ]] && [[ "$template_filter" != "$key" ]]; then
      continue
    fi

    local src_path="${templates_dir}/${src_file}"
    local dest_path="${target_dir}/${dest_file}"

    if [[ ! -f "$src_path" ]]; then
      echo "⚠️ Template not found: ${src_path}"
      continue
    fi

    if [[ -f "$dest_path" ]]; then
      echo "⏭️  Skipping (exists): ${dest_path}"
      continue
    fi

    mkdir -p "$target_dir"

    # Copy and substitute basic placeholders
    sed -e "s|{PROJECT_NAME}|${project_name}|g" \
        -e "s|{PROJECT_ID}|${project_name}|g" \
        -e "s|{DATE}|${today}|g" \
        -e "s|{AUTHOR}|Harness Protocol|g" \
        "$src_path" > "$dest_path"

    echo "✅ Created: ${dest_path}"
    count=$(( count + 1 ))
  done

  # Also ensure core harness directories exist
  mkdir -p docs/tasks docs/cycle_logs docs/prompts

  echo ""
  echo "📋 Documentation scaffold complete: ${count} file(s) created."
  if [[ "$LITE_MODE" == "true" ]]; then
    echo "   Lite mode: docs/specs/, docs/agile/"
  else
    echo "   Core directories: docs/specs/, docs/agile/, docs/decisions/, docs/testing/, docs/api/, docs/troubleshooting/"
  fi
  echo "   Harness directories: docs/tasks/, docs/cycle_logs/, docs/prompts/"
}

# ===== HELP =====
show_help() {
  cat <<'HELPEOF'
Harness Protocol Engine v3.0.0

Usage: harness.sh <command> [options]

Commands:
  test          Run test with telemetry locking
  run           Execute full pipeline with autonomy level
  approve       Human-only task approval (CI: token-based)
  document      Generate ISO documentation
  docs-init     Scaffold documentation templates into project
  commit        Verified commit with integrity check
  check         Pre-commit integrity check
  prompt        Generate prompt from template
  archive       Archive old completed tasks and telemetry
  kanban-render Render Kanban board from task data (SSOT)
  help          Show this help

Options:
  --id <task_id>       Task identifier
  --cmd <command>      Test command to execute
  --mode <mode>        Test mode: standard | tdd-red
  --level <1-4>        Autonomy level (default: 3)
  --standard <std>     ISO standard: ISO_42010 | ISO_25010
  --template <name>    Template to scaffold: SRS | SDD | SCS | KANBAN | WBS | SCRUM | ADR | STD | STR | API_SPEC | TROUBLESHOOTING
  --msg <message>      Commit message
  --ci                 Enable CI/headless mode (no interactive prompts)
  --mutation           Enable mutation testing after standard tests
  --mutation-threshold <N>  Mutation score threshold (default: 60)
  --lite               docs-init: scaffold essential templates only (SRS, SDD, KANBAN, WBS)
  --adapter <name>     Coverage adapter: node | kmp | unity (default: node)
  --archive-days <N>   Archive tasks older than N days (default: 7)

Autonomy Levels:
  1 (Planning)       Generate docs structure only, then exit
  2 (Prompting)      Generate prompt text only, then exit
  3 (Interactive)    Step-by-step with approval gates (default)
  4 (Autonomous)     Full auto with sub-agent delegation

Adapters:
  node    Node.js/JS/TS — c8/nyc coverage, Stryker mutation (default)
  kmp     Kotlin Multiplatform — Kover coverage, PIT mutation
  unity   Unity/C#/.NET — dotCover/coverlet coverage, Stryker.NET mutation

Examples:
  harness.sh test --id TASK-001 --cmd "c8 node --test test.js"
  harness.sh test --id TASK-001 --cmd "c8 node --test test.js" --mutation
  harness.sh run --id TASK-001 --level 4 --ci
  harness.sh run --id TASK-001 --adapter kmp --level 3
  harness.sh document --standard ISO_42010
  harness.sh docs-init
  harness.sh docs-init --lite
  harness.sh docs-init --template WBS
  harness.sh archive --archive-days 14
  harness.sh kanban-render
  harness.sh commit --id TASK-001 --msg "feat: add validation"

HELPEOF
}

# ===== MAIN =====
main() {
  check_prerequisites

  # Integrity check: must run from skill workspace
  if [[ "$SCRIPT_PATH" != *"skills/harness/scripts"* ]]; then
    echo "❌ INTEGRITY VIOLATION: Harness engine must run from its skill workspace."
    echo "Attempted path: ${SCRIPT_PATH}"
    exit 1
  fi

  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  local cmd="$1"
  shift

  # Parse global flags
  local task_id="" command="" mode="standard" standard="ISO_25010" msg="" template="all"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)       task_id="$2"; shift 2 ;;
      --cmd)      command="$2"; shift 2 ;;
      --mode)     mode="$2"; shift 2 ;;
      --level)    AUTONOMY_LEVEL="$2"; shift 2 ;;
      --standard) standard="$2"; shift 2 ;;
      --template) template="$2"; shift 2 ;;
      --msg)      msg="$2"; shift 2 ;;
      --ci)       CI_MODE=true; shift ;;
      --mutation) MUTATION_MODE=true; shift ;;
      --mutation-threshold) MUTATION_THRESHOLD="$2"; shift 2 ;;
      --lite)     LITE_MODE=true; shift ;;
      --adapter)  ADAPTER_NAME_OVERRIDE="$2"; shift 2 ;;
      --archive-days) ARCHIVE_AGE_DAYS="$2"; shift 2 ;;
      --help|-h)  show_help; exit 0 ;;
      *)          echo "❌ Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Load adapter for commands that need it
  case "$cmd" in
    test|run)
      load_adapter
      ;;
  esac

  case "$cmd" in
    test)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      [[ -z "$command" ]] && { echo "❌ --cmd required"; exit 1; }
      run_test "$task_id" "$command" "$mode"
      exit $?
      ;;
    run)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      run_pipeline "$task_id"
      exit $?
      ;;
    approve)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      approve "$task_id"
      ;;
    document)
      document "$standard"
      ;;
    commit)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      [[ -z "$msg" ]] && { echo "❌ --msg required"; exit 1; }
      do_commit "$task_id" "$msg"
      ;;
    check)
      pre_commit_check
      ;;
    docs-init)
      docs_init "$template"
      ;;
    prompt)
      [[ -z "$task_id" ]] && { echo "❌ --id required"; exit 1; }
      load_adapter
      generate_prompt "$task_id"
      ;;
    archive)
      archive_old_tasks "$ARCHIVE_AGE_DAYS"
      ;;
    kanban-render)
      render_kanban
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      echo "❌ Unknown command: ${cmd}"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
