#!/usr/bin/env bash
# =============================================================================
# Harness Adapter: Unity / .NET / C#
# Coverage: dotCover, coverlet (LCOV format)
# Mutation: Stryker.NET (stub)
# =============================================================================

ADAPTER_NAME="unity"
ADAPTER_COVERAGE_TOOLS="dotCover, coverlet"
ADAPTER_MUTATION_TOOL="stryker-net"

# --- Coverage ---
adapter_parse_coverage() {
  local lcov_path="${1:-TestResults/lcov.info}"

  # Check common dotCover/coverlet LCOV output locations
  local coverlet_lcov="TestResults/coverage.info"
  if [[ ! -f "$lcov_path" ]] && [[ -f "$coverlet_lcov" ]]; then
    lcov_path="$coverlet_lcov"
  fi

  if [[ ! -f "$lcov_path" ]]; then
    echo "ERROR:Coverage report not found. Run: dotnet test --collect:'XPlat Code Coverage' with LCOV output."
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

  echo "🧬 [MUTATION] Running Stryker.NET for task: ${task_id}..."

  local mutation_exit=0
  dotnet stryker 2>&1 | tee -a "$log_path" || mutation_exit=$?

  if [[ "$mutation_exit" -ne 0 ]]; then
    echo "❌ Stryker.NET execution failed (exit: ${mutation_exit})."
    return 1
  fi

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
  echo "dotnet unity-editor msbuild nunit"
}
