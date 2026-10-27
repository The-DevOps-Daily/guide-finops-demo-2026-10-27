# Helpers for the guide runs, sourced by scripts/run.sh.
#
# cap NAME 'command'
#   Runs the command in the current shell (so cd and variables carry over),
#   saves its combined output to captures/NAME.txt and the command, exit code
#   and time to captures/NAME.json.
# must 'command'
#   A setup step that the guide does not show. The job fails if it fails.

CAP_DIR="${CAP_DIR:-$PWD/captures}"
mkdir -p "$CAP_DIR"

cap() {
  local name=$1 shown=$2 rc started
  started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  eval "$shown" >"$CAP_DIR/$name.txt" 2>&1 </dev/null
  rc=$?
  jq -n --arg cmd "$shown" --argjson rc "$rc" --arg at "$started" \
    --arg run_id "${GITHUB_RUN_ID:-local}" \
    '{cmd: $cmd, rc: $rc, at: $at, run_id: $run_id}' >"$CAP_DIR/$name.json"
  printf '::group::%s (exit %s)\n$ %s\n' "$name" "$rc" "$shown"
  cat "$CAP_DIR/$name.txt"
  echo '::endgroup::'
}

must() {
  echo "+ $*"
  if ! eval "$*"; then
    echo "::error::setup step failed: $*"
    exit 1
  fi
}

FOCUS_URL=https://raw.githubusercontent.com/FinOps-Open-Cost-and-Usage-Spec/FOCUS-Sample-Data/adbdd17a132984d6e8583c149c236d2199c3f5bc/FOCUS-1.0/focus_sample_100000.csv.gz
FOCUS_SHA256=76e9158659d40cdef0fecfe6fbc8b874a438ef9fb440205b9190ed1600bf6f8a

# The state at the end of Part 1: the sample in focus.duckdb.
state_focus() {
  must "curl -fsSLO $FOCUS_URL"
  must "echo '$FOCUS_SHA256  focus_sample_100000.csv.gz' | sha256sum -c"
  must 'duckdb focus.duckdb -f focus/load.sql > /dev/null'
}

# The state at the end of Part 2: plus the usage view.
state_focus_view() {
  state_focus
  must 'duckdb focus.duckdb -f focus/usage-view.sql > /dev/null'
}

# Mock AWS credentials, so `terraform plan` runs without an account.
tf_mock() {
  must 'cp ci/mock_provider_override.tf infra/mock_provider_override.tf'
}
