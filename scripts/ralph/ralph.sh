#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$SCRIPT_DIR/config.env"
FLOWCTL="$SCRIPT_DIR/flowctl"

fail() { echo "ralph: $*" >&2; exit 1; }
log() {
  # Machine-readable logs: only show when UI disabled
  [[ "${UI_ENABLED:-1}" != "1" ]] && echo "ralph: $*"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Presentation layer (human-readable output)
# ─────────────────────────────────────────────────────────────────────────────
UI_ENABLED="${RALPH_UI:-1}"  # set RALPH_UI=0 to disable

# Colors (disabled if not tty or NO_COLOR set)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_DIM='\033[2m'
  C_BLUE='\033[34m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
  C_CYAN='\033[36m'
  C_MAGENTA='\033[35m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_BLUE='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_MAGENTA=''
fi

ui() {
  [[ "$UI_ENABLED" == "1" ]] || return 0
  echo -e "$*"
}

ui_header() {
  ui ""
  ui "${C_BOLD}${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  ui "${C_BOLD}${C_BLUE}  🤖 Ralph Autonomous Loop${C_RESET}"
  ui "${C_BOLD}${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
}

ui_config() {
  local epic_count task_count
  epic_count="$(ls "$ROOT_DIR/.flow/epics/"*.json 2>/dev/null | wc -l | tr -d ' ')"
  task_count="$(ls "$ROOT_DIR/.flow/tasks/"*.json 2>/dev/null | wc -l | tr -d ' ')"
  ui ""
  ui "${C_DIM}   Run:${C_RESET} $RUN_ID"
  ui "${C_DIM}   Epics:${C_RESET} $epic_count  ${C_DIM}Tasks:${C_RESET} $task_count  ${C_DIM}Max iters:${C_RESET} $MAX_ITERATIONS"
  local plan_review_display="$PLAN_REVIEW" work_review_display="$WORK_REVIEW"
  [[ "$PLAN_REVIEW" == "rp" ]] && plan_review_display="RepoPrompt" || true
  [[ "$WORK_REVIEW" == "rp" ]] && work_review_display="RepoPrompt" || true
  ui "${C_DIM}   Plan review:${C_RESET} $plan_review_display  ${C_DIM}Work review:${C_RESET} $work_review_display  ${C_DIM}Branch:${C_RESET} $BRANCH_MODE"
  [[ -n "${EPICS:-}" ]] && ui "${C_DIM}   Scope:${C_RESET} $EPICS" || true
  ui ""
}

ui_iteration() {
  local iter="$1" status="$2" epic="${3:-}" task="${4:-}"
  ui ""
  ui "${C_BOLD}${C_CYAN}🔄 Iteration $iter${C_RESET}"
  if [[ "$status" == "plan" ]]; then
    ui "   ${C_DIM}Epic:${C_RESET} ${C_BOLD}$epic${C_RESET}"
    ui "   ${C_DIM}Phase:${C_RESET} ${C_YELLOW}Planning${C_RESET}"
  elif [[ "$status" == "work" ]]; then
    ui "   ${C_DIM}Task:${C_RESET} ${C_BOLD}$task${C_RESET}"
    ui "   ${C_DIM}Phase:${C_RESET} ${C_MAGENTA}Implementation${C_RESET}"
  fi
}

ui_plan_review() {
  local mode="$1" epic="$2"
  if [[ "$mode" == "rp" ]]; then
    ui ""
    ui "   ${C_YELLOW}📝 Plan Review${C_RESET}"
    ui "      ${C_DIM}Sending to reviewer via RepoPrompt...${C_RESET}"
  fi
}

ui_impl_review() {
  local mode="$1" task="$2"
  if [[ "$mode" == "rp" ]]; then
    ui ""
    ui "   ${C_MAGENTA}🔍 Implementation Review${C_RESET}"
    ui "      ${C_DIM}Sending to reviewer via RepoPrompt...${C_RESET}"
  fi
}

ui_verdict() {
  local verdict="$1"
  case "$verdict" in
    SHIP)
      ui "   ${C_GREEN}✅ Verdict: SHIP${C_RESET}" ;;
    NEEDS_WORK)
      ui "   ${C_YELLOW}🔧 Verdict: NEEDS_WORK${C_RESET} ${C_DIM}(fixing...)${C_RESET}" ;;
    MAJOR_RETHINK)
      ui "   ${C_RED}⚠️  Verdict: MAJOR_RETHINK${C_RESET}" ;;
    *)
      [[ -n "$verdict" ]] && ui "   ${C_DIM}Verdict: $verdict${C_RESET}" || true ;;
  esac
}


ui_task_done() {
  local task="$1"
  ui "   ${C_GREEN}✓ Task complete:${C_RESET} ${C_BOLD}$task${C_RESET}"
}

ui_retry() {
  local task="$1" attempts="$2" max="$3"
  ui "   ${C_YELLOW}↻ Retry${C_RESET} ${C_DIM}(attempt $attempts/$max)${C_RESET}"
}

ui_blocked() {
  local task="$1"
  ui "   ${C_RED}🚫 Task blocked:${C_RESET} $task ${C_DIM}(max attempts reached)${C_RESET}"
}

ui_complete() {
  ui ""
  ui "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  ui "${C_BOLD}${C_GREEN}  ✅ Ralph Complete${C_RESET}"
  ui "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  ui ""
}

ui_fail() {
  local reason="${1:-}"
  ui ""
  ui "${C_BOLD}${C_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  ui "${C_BOLD}${C_RED}  ❌ Ralph Failed${C_RESET}"
  [[ -n "$reason" ]] && ui "     ${C_DIM}$reason${C_RESET}" || true
  ui "${C_BOLD}${C_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  ui ""
}

ui_waiting() {
  ui "   ${C_DIM}⏳ Claude working...${C_RESET}"
}

[[ -f "$CONFIG" ]] || fail "missing config.env"
[[ -x "$FLOWCTL" ]] || fail "missing flowctl"

# shellcheck disable=SC1090
set -a
source "$CONFIG"
set +a

MAX_ITERATIONS="${MAX_ITERATIONS:-25}"
MAX_TURNS="${MAX_TURNS:-}"  # empty = no limit; Claude stops via promise tags
MAX_ATTEMPTS_PER_TASK="${MAX_ATTEMPTS_PER_TASK:-5}"
BRANCH_MODE="${BRANCH_MODE:-new}"
PLAN_REVIEW="${PLAN_REVIEW:-none}"
WORK_REVIEW="${WORK_REVIEW:-none}"
REQUIRE_PLAN_REVIEW="${REQUIRE_PLAN_REVIEW:-0}"
YOLO="${YOLO:-0}"
EPICS="${EPICS:-}"

CLAUDE_BIN="${CLAUDE_BIN:-claude}"

sanitize_id() {
  local v="$1"
  v="${v// /_}"
  v="${v//\//_}"
  v="${v//\\/__}"
  echo "$v"
}

get_actor() {
  if [[ -n "${FLOW_ACTOR:-}" ]]; then echo "$FLOW_ACTOR"; return; fi
  if actor="$(git -C "$ROOT_DIR" config user.email 2>/dev/null)"; then
    [[ -n "$actor" ]] && { echo "$actor"; return; }
  fi
  if actor="$(git -C "$ROOT_DIR" config user.name 2>/dev/null)"; then
    [[ -n "$actor" ]] && { echo "$actor"; return; }
  fi
  echo "${USER:-unknown}"
}

rand4() {
  python3 - <<'PY'
import secrets
print(secrets.token_hex(2))
PY
}

render_template() {
  local path="$1"
  python3 - "$path" <<'PY'
import os, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
keys = ["EPIC_ID","TASK_ID","PLAN_REVIEW","WORK_REVIEW","BRANCH_MODE","BRANCH_MODE_EFFECTIVE","REQUIRE_PLAN_REVIEW","REVIEW_RECEIPT_PATH"]
for k in keys:
    text = text.replace("{{%s}}" % k, os.environ.get(k, ""))
print(text)
PY
}

json_get() {
  local key="$1"
  local json="$2"
  python3 - "$key" "$json" <<'PY'
import json, sys
key = sys.argv[1]
data = json.loads(sys.argv[2])
val = data.get(key)
if val is None:
    print("")
elif isinstance(val, bool):
    print("1" if val else "0")
else:
    print(val)
PY
}

ensure_attempts_file() {
  [[ -f "$1" ]] || echo "{}" > "$1"
}

bump_attempts() {
  python3 - "$1" "$2" <<'PY'
import json, sys, os
path, task = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
count = int(data.get(task, 0)) + 1
data[task] = count
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=True)
print(count)
PY
}

write_epics_file() {
  python3 - "$1" <<'PY'
import json, sys
raw = sys.argv[1]
parts = [p.strip() for p in raw.replace(",", " ").split() if p.strip()]
print(json.dumps({"epics": parts}, indent=2, sort_keys=True))
PY
}

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$(hostname -s 2>/dev/null || hostname)-$(sanitize_id "$(get_actor)")-$$-$(rand4)"
RUN_DIR="$SCRIPT_DIR/runs/$RUN_ID"
mkdir -p "$RUN_DIR"
ATTEMPTS_FILE="$RUN_DIR/attempts.json"
ensure_attempts_file "$ATTEMPTS_FILE"
BRANCHES_FILE="$RUN_DIR/branches.json"
RECEIPTS_DIR="$RUN_DIR/receipts"
mkdir -p "$RECEIPTS_DIR"
PROGRESS_FILE="$RUN_DIR/progress.txt"
{
  echo "# Ralph Progress Log"
  echo "Run: $RUN_ID"
  echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "---"
} > "$PROGRESS_FILE"

extract_tag() {
  local tag="$1"
  python3 - "$tag" <<'PY'
import re, sys
tag = sys.argv[1]
text = sys.stdin.read()
matches = re.findall(rf"<{tag}>(.*?)</{tag}>", text, flags=re.S)
print(matches[-1] if matches else "")
PY
}

append_progress() {
  local verdict="$1"
  local promise="$2"
  local plan_review_status="${3:-}"
  local task_status="${4:-}"
  local receipt_exists="0"
  if [[ -n "${REVIEW_RECEIPT_PATH:-}" && -f "$REVIEW_RECEIPT_PATH" ]]; then
    receipt_exists="1"
  fi
  {
    echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) - iter $iter"
    echo "status=$status epic=${epic_id:-} task=${task_id:-} reason=${reason:-}"
    echo "claude_rc=$claude_rc"
    echo "verdict=${verdict:-}"
    echo "promise=${promise:-}"
    echo "receipt=${REVIEW_RECEIPT_PATH:-} exists=$receipt_exists"
    echo "plan_review_status=${plan_review_status:-}"
    echo "task_status=${task_status:-}"
    echo "iter_log=$iter_log"
    echo "last_output:"
    tail -n 10 "$iter_log" || true
    echo "---"
  } >> "$PROGRESS_FILE"
}

init_branches_file() {
  if [[ -f "$BRANCHES_FILE" ]]; then return; fi
  local base_branch
  base_branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  python3 - "$BRANCHES_FILE" "$base_branch" <<'PY'
import json, sys
path, base = sys.argv[1], sys.argv[2]
data = {"base_branch": base, "epics": {}}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=True)
PY
}

get_branch_for_epic() {
  python3 - "$BRANCHES_FILE" "$1" <<'PY'
import json, sys
path, epic = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    print(data.get("epics", {}).get(epic, ""))
except FileNotFoundError:
    print("")
PY
}

set_branch_for_epic() {
  python3 - "$BRANCHES_FILE" "$1" "$2" <<'PY'
import json, sys
path, epic, branch = sys.argv[1], sys.argv[2], sys.argv[3]
data = {"base_branch": "", "epics": {}}
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    pass
data.setdefault("epics", {})[epic] = branch
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=True)
PY
}

get_base_branch() {
  python3 - "$BRANCHES_FILE" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
    print(data.get("base_branch", ""))
except FileNotFoundError:
    print("")
PY
}

list_epics_from_file() {
  python3 - "$EPICS_FILE" <<'PY'
import json, sys
path = sys.argv[1]
if not path:
    sys.exit(0)
try:
    data = json.load(open(path, encoding="utf-8"))
except FileNotFoundError:
    sys.exit(0)
epics = data.get("epics", []) or []
print(" ".join(epics))
PY
}

epic_all_tasks_done() {
  python3 - "$1" <<'PY'
import json, sys
try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    print("0")
    sys.exit(0)
tasks = data.get("tasks", []) or []
if not tasks:
    print("0")
    sys.exit(0)
for t in tasks:
    if t.get("status") != "done":
        print("0")
        sys.exit(0)
print("1")
PY
}

maybe_close_epics() {
  [[ -z "$EPICS_FILE" ]] && return 0
  local epics json status all_done
  epics="$(list_epics_from_file)"
  [[ -z "$epics" ]] && return 0
  for epic in $epics; do
    json="$("$FLOWCTL" show "$epic" --json 2>/dev/null || true)"
    [[ -z "$json" ]] && continue
    status="$(json_get status "$json")"
    [[ "$status" == "done" ]] && continue
    all_done="$(epic_all_tasks_done "$json")"
    if [[ "$all_done" == "1" ]]; then
      "$FLOWCTL" epic close "$epic" --json >/dev/null 2>&1 || true
    fi
  done
}

verify_receipt() {
  local path="$1"
  local kind="$2"
  local id="$3"
  [[ -f "$path" ]] || return 1
  python3 - "$path" "$kind" "$id" <<'PY'
import json, sys
path, kind, rid = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    sys.exit(1)
if data.get("type") != kind:
    sys.exit(1)
if data.get("id") != rid:
    sys.exit(1)
sys.exit(0)
PY
}

ensure_epic_branch() {
  local epic_id="$1"
  if [[ "$BRANCH_MODE" != "new" ]]; then
    return
  fi
  init_branches_file
  local branch
  branch="$(get_branch_for_epic "$epic_id")"
  if [[ -z "$branch" ]]; then
    branch="${epic_id}-epic"
    set_branch_for_epic "$epic_id" "$branch"
  fi
  local base
  base="$(get_base_branch)"
  if [[ -n "$base" ]]; then
    git -C "$ROOT_DIR" checkout "$base" >/dev/null 2>&1 || true
  fi
  if git -C "$ROOT_DIR" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$ROOT_DIR" checkout "$branch" >/dev/null 2>&1
  else
    git -C "$ROOT_DIR" checkout -b "$branch" >/dev/null 2>&1
  fi
}

EPICS_FILE=""
if [[ -n "${EPICS// }" ]]; then
  EPICS_FILE="$RUN_DIR/run.json"
  write_epics_file "$EPICS" > "$EPICS_FILE"
fi

ui_header
ui_config

iter=1
while (( iter <= MAX_ITERATIONS )); do
  iter_log="$RUN_DIR/iter-$(printf '%03d' "$iter").log"

  selector_args=("$FLOWCTL" next --json)
  [[ -n "$EPICS_FILE" ]] && selector_args+=(--epics-file "$EPICS_FILE")
  [[ "$REQUIRE_PLAN_REVIEW" == "1" ]] && selector_args+=(--require-plan-review)

  selector_json="$("${selector_args[@]}")"
  status="$(json_get status "$selector_json")"
  epic_id="$(json_get epic "$selector_json")"
  task_id="$(json_get task "$selector_json")"
  reason="$(json_get reason "$selector_json")"

  log "iter $iter status=$status epic=${epic_id:-} task=${task_id:-} reason=${reason:-}"
  ui_iteration "$iter" "$status" "${epic_id:-}" "${task_id:-}"

  if [[ "$status" == "none" ]]; then
    if [[ "$reason" == "blocked_by_epic_deps" ]]; then
      log "blocked by epic deps"
    fi
    maybe_close_epics
    ui_complete
    echo "<promise>COMPLETE</promise>"
    exit 0
  fi

  if [[ "$status" == "plan" ]]; then
    export EPIC_ID="$epic_id"
    export PLAN_REVIEW
    export REQUIRE_PLAN_REVIEW
    export REVIEW_RECEIPT_PATH="$RECEIPTS_DIR/plan-${epic_id}.json"
    log "plan epic=$epic_id review=$PLAN_REVIEW receipt=$REVIEW_RECEIPT_PATH require=$REQUIRE_PLAN_REVIEW"
    ui_plan_review "$PLAN_REVIEW" "$epic_id"
    prompt="$(render_template "$SCRIPT_DIR/prompt_plan.md")"
  elif [[ "$status" == "work" ]]; then
    epic_id="${task_id%%.*}"
    ensure_epic_branch "$epic_id"
    export TASK_ID="$task_id"
    BRANCH_MODE_EFFECTIVE="$BRANCH_MODE"
    if [[ "$BRANCH_MODE" == "new" ]]; then
      BRANCH_MODE_EFFECTIVE="current"
    fi
    export BRANCH_MODE_EFFECTIVE
    export WORK_REVIEW
    export REVIEW_RECEIPT_PATH="$RECEIPTS_DIR/impl-${task_id}.json"
    log "work task=$task_id review=$WORK_REVIEW receipt=$REVIEW_RECEIPT_PATH branch=$BRANCH_MODE_EFFECTIVE"
    ui_impl_review "$WORK_REVIEW" "$task_id"
    prompt="$(render_template "$SCRIPT_DIR/prompt_work.md")"
  else
    fail "invalid selector status: $status"
  fi

  export FLOW_RALPH="1"
  claude_args=(-p --output-format text)

  # Autonomous mode system prompt - critical for preventing drift
  claude_args+=(--append-system-prompt "AUTONOMOUS MODE ACTIVE (FLOW_RALPH=1). You are running unattended. CRITICAL RULES:
1. EXECUTE COMMANDS EXACTLY as shown in prompts. Do not paraphrase or improvise.
2. VERIFY OUTCOMES by running the verification commands (flowctl show, git status).
3. NEVER CLAIM SUCCESS without proof. If flowctl done was not run, the task is NOT done.
4. COPY TEMPLATES VERBATIM - receipt JSON must match exactly including all fields.
5. USE SKILLS AS SPECIFIED - invoke /flow-next:impl-review, do not improvise review prompts.
Violations break automation and leave the user with incomplete work. Be precise, not creative.")

  [[ -n "${MAX_TURNS:-}" ]] && claude_args+=(--max-turns "$MAX_TURNS")
  [[ "$YOLO" == "1" ]] && claude_args+=(--dangerously-skip-permissions)
  [[ -n "${FLOW_RALPH_CLAUDE_MODEL:-}" ]] && claude_args+=(--model "$FLOW_RALPH_CLAUDE_MODEL")
  [[ -n "${FLOW_RALPH_CLAUDE_SESSION_ID:-}" ]] && claude_args+=(--session-id "$FLOW_RALPH_CLAUDE_SESSION_ID")
  [[ -n "${FLOW_RALPH_CLAUDE_PERMISSION_MODE:-}" ]] && claude_args+=(--permission-mode "$FLOW_RALPH_CLAUDE_PERMISSION_MODE")
  [[ "${FLOW_RALPH_CLAUDE_NO_SESSION_PERSISTENCE:-}" == "1" ]] && claude_args+=(--no-session-persistence)
  if [[ -n "${FLOW_RALPH_CLAUDE_DEBUG:-}" ]]; then
    if [[ "${FLOW_RALPH_CLAUDE_DEBUG}" == "1" ]]; then
      claude_args+=(--debug)
    else
      claude_args+=(--debug "$FLOW_RALPH_CLAUDE_DEBUG")
    fi
  fi
  [[ "${FLOW_RALPH_CLAUDE_VERBOSE:-}" == "1" ]] && claude_args+=(--verbose)

  ui_waiting

  set +e
  claude_out="$("$CLAUDE_BIN" "${claude_args[@]}" "$prompt" 2>&1)"
  claude_rc=$?
  set -e

  printf '%s\n' "$claude_out" > "$iter_log"
  log "claude rc=$claude_rc log=$iter_log"

  force_retry=0
  plan_review_status=""
  task_status=""
  if [[ "$status" == "plan" && "$PLAN_REVIEW" == "rp" ]]; then
    if ! verify_receipt "$REVIEW_RECEIPT_PATH" "plan_review" "$epic_id"; then
      echo "ralph: missing plan review receipt; forcing retry" >> "$iter_log"
      log "missing plan receipt; forcing retry"
      "$FLOWCTL" epic set-plan-review-status "$epic_id" --status needs_work --json >/dev/null 2>&1 || true
      force_retry=1
    fi
    epic_json="$("$FLOWCTL" show "$epic_id" --json 2>/dev/null || true)"
    plan_review_status="$(json_get plan_review_status "$epic_json")"
  fi
  if [[ "$status" == "work" && "$WORK_REVIEW" == "rp" ]]; then
    if ! verify_receipt "$REVIEW_RECEIPT_PATH" "impl_review" "$task_id"; then
      echo "ralph: missing impl review receipt; forcing retry" >> "$iter_log"
      log "missing impl receipt; forcing retry"
      force_retry=1
    fi
  fi
  if [[ "$status" == "work" ]]; then
    task_json="$("$FLOWCTL" show "$task_id" --json 2>/dev/null || true)"
    task_status="$(json_get status "$task_json")"
    if [[ "$task_status" != "done" ]]; then
      echo "ralph: task not done; forcing retry" >> "$iter_log"
      log "task $task_id status=$task_status; forcing retry"
      force_retry=1
    else
      ui_task_done "$task_id"
    fi
  fi


  verdict="$(printf '%s' "$claude_out" | extract_tag verdict)"
  promise="$(printf '%s' "$claude_out" | extract_tag promise)"
  ui_verdict "$verdict"
  append_progress "$verdict" "$promise" "$plan_review_status" "$task_status"

  if echo "$claude_out" | grep -q "<promise>COMPLETE</promise>"; then
    ui_complete
    echo "<promise>COMPLETE</promise>"
    exit 0
  fi

  exit_code=0
  if echo "$claude_out" | grep -q "<promise>FAIL</promise>"; then
    exit_code=1
  elif echo "$claude_out" | grep -q "<promise>RETRY</promise>"; then
    exit_code=2
  elif [[ "$force_retry" == "1" ]]; then
    exit_code=2
  elif [[ "$claude_rc" -ne 0 ]]; then
    exit_code=1
  fi

  if [[ "$exit_code" -eq 1 ]]; then
    log "exit=fail"
    ui_fail "Claude returned FAIL promise"
    exit 1
  fi

  if [[ "$exit_code" -eq 2 && "$status" == "work" ]]; then
    attempts="$(bump_attempts "$ATTEMPTS_FILE" "$task_id")"
    log "retry task=$task_id attempts=$attempts"
    ui_retry "$task_id" "$attempts" "$MAX_ATTEMPTS_PER_TASK"
    if (( attempts >= MAX_ATTEMPTS_PER_TASK )); then
      reason_file="$RUN_DIR/block-${task_id}.md"
      {
        echo "Auto-blocked after ${attempts} attempts."
        echo "Run: $RUN_ID"
        echo "Task: $task_id"
        echo ""
        echo "Last output:"
        tail -n 40 "$iter_log" || true
      } > "$reason_file"
      "$FLOWCTL" block "$task_id" --reason-file "$reason_file" --json || true
      ui_blocked "$task_id"
    fi
  fi

  sleep 2
  iter=$((iter + 1))
done

ui_fail "Max iterations ($MAX_ITERATIONS) reached"
echo "ralph: max iterations reached" >&2
exit 1
