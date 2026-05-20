#!/usr/bin/env bash
# =============================================================================
# Harness Adapter: Node.js / JavaScript / TypeScript
# Coverage: c8, nyc (LCOV format)
# Mutation: Stryker Mutator
# =============================================================================

ADAPTER_NAME="node"
ADAPTER_COVERAGE_TOOLS="c8, nyc, jest --coverage"
ADAPTER_MUTATION_TOOL="stryker"

# --- Coverage ---
adapter_parse_coverage() {
  local lcov_path="${1:-coverage/lcov.info}"

  if [[ ! -f "$lcov_path" ]]; then
    echo "ERROR:Coverage report (lcov.info) not found. Run tests with coverage tool (e.g., c8, nyc)."
    return 1
  fi

  local total_lf=0
  local total_lh=0

  while IFS= read -r line; do
    case "$line" in
      LF:*) total_lf=$(( total_lf + ${line#LF:} )) ;;
      LH:*) total_lh=$(( total_lh + ${line#LH:} )) ;;
    esac
  done < "$lcov_path"

  if [[ "$total_lf" -eq 0 ]]; then
    echo "0.00"
    return 0
  fi

  awk "BEGIN {printf \"%.2f\", ($total_lh / $total_lf) * 100}"
}

# --- Mutation Testing ---
adapter_run_mutation() {
  local task_id="$1"
  local threshold="${2:-60}"
  local log_path="${3}"

  if ! command -v npx &>/dev/null; then
    echo "❌ npx not found. Install Node.js to use mutation testing."
    return 1
  fi

  echo "🧬 [MUTATION] Running Stryker Mutator for task: ${task_id}..."

  local mutation_exit=0
  npx stryker run --reporters clear-text 2>&1 | tee -a "$log_path" || mutation_exit=$?

  if [[ "$mutation_exit" -ne 0 ]]; then
    echo "❌ Stryker execution failed (exit: ${mutation_exit})."
    return 1
  fi

  # Parse mutation score from stryker output
  local score
  score=$(grep -oP 'Mutation score:\s*\K[0-9.]+' "$log_path" 2>/dev/null || echo "0")

  local below
  below=$(awk "BEGIN {print ($score < $threshold) ? 1 : 0}")
  if [[ "$below" -eq 1 ]]; then
    echo "❌ MUTATION SCORE TOO LOW: ${score}% (threshold: ${threshold}%)"
    return 1
  fi

  echo "✅ MUTATION SCORE PASSED: ${score}% (threshold: ${threshold}%)"
  echo "$score"
  return 0
}

# --- Allowed Commands ---
adapter_allowed_prefixes() {
  echo "npx node npm c8 nyc jest vitest stryker tsx ts-node"
}
