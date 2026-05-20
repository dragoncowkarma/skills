#!/usr/bin/env bash
# =============================================================================
# Harness Adapter: Kotlin Multiplatform (KMP)
# Coverage: Kover (LCOV format)
# Mutation: PIT (pitest)
# =============================================================================

ADAPTER_NAME="kmp"
ADAPTER_COVERAGE_TOOLS="kover"
ADAPTER_MUTATION_TOOL="pitest"

# --- Coverage ---
adapter_parse_coverage() {
  local lcov_path="${1:-build/reports/kover/report.xml}"

  # Kover can export LCOV — check standard locations
  local kover_lcov="build/reports/kover/lcov.info"
  if [[ -f "$kover_lcov" ]]; then
    lcov_path="$kover_lcov"
  fi

  if [[ ! -f "$lcov_path" ]]; then
    echo "ERROR:Coverage report not found. Run: ./gradlew koverXmlReport or koverReport with LCOV output."
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

  echo "🧬 [MUTATION] Running PIT Mutation Testing for task: ${task_id}..."

  local mutation_exit=0
  ./gradlew pitest 2>&1 | tee -a "$log_path" || mutation_exit=$?

  if [[ "$mutation_exit" -ne 0 ]]; then
    echo "❌ PIT execution failed (exit: ${mutation_exit})."
    return 1
  fi

  # Parse mutation score from PIT output
  local score
  score=$(grep -oP 'mutation score:\s*\K[0-9.]+' "$log_path" 2>/dev/null || echo "0")

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
  echo "gradle gradlew ./gradlew java kotlin kotlinc"
}
