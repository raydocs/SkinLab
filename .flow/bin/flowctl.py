#!/usr/bin/env python3
"""
flowctl - CLI for managing .flow/ task tracking system.

All task/epic state lives in JSON files. Markdown specs hold narrative content.
Agents must use flowctl for all writes - never edit .flow/* directly.
"""

import argparse
import json
import os
import re
import subprocess
import shlex
import shutil
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any, Optional


# --- Constants ---

SCHEMA_VERSION = 2
SUPPORTED_SCHEMA_VERSIONS = [1, 2]
FLOW_DIR = ".flow"
META_FILE = "meta.json"
EPICS_DIR = "epics"
SPECS_DIR = "specs"
TASKS_DIR = "tasks"
MEMORY_DIR = "memory"

EPIC_STATUS = ["open", "done"]
TASK_STATUS = ["todo", "in_progress", "blocked", "done"]

TASK_SPEC_HEADINGS = ["## Description", "## Acceptance", "## Done summary", "## Evidence"]


# --- Helpers ---

def get_repo_root() -> Path:
    """Find git repo root."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        # Fallback to current directory
        return Path.cwd()


def get_flow_dir() -> Path:
    """Get .flow/ directory path."""
    return get_repo_root() / FLOW_DIR


def ensure_flow_exists() -> bool:
    """Check if .flow/ exists."""
    return get_flow_dir().exists()


def json_output(data: dict, success: bool = True) -> None:
    """Output JSON response."""
    result = {"success": success, **data}
    print(json.dumps(result, indent=2, default=str))


def error_exit(message: str, code: int = 1, use_json: bool = True) -> None:
    """Output error and exit."""
    if use_json:
        json_output({"error": message}, success=False)
    else:
        print(f"Error: {message}", file=sys.stderr)
    sys.exit(code)


def now_iso() -> str:
    """Current timestamp in ISO format."""
    return datetime.utcnow().isoformat() + "Z"


def require_rp_cli() -> str:
    """Ensure rp-cli is available."""
    rp = shutil.which("rp-cli")
    if not rp:
        error_exit("rp-cli not found in PATH", use_json=False, code=2)
    return rp


def run_rp_cli(args: list[str]) -> subprocess.CompletedProcess:
    """Run rp-cli with safe error handling."""
    rp = require_rp_cli()
    cmd = [rp] + args
    try:
        return subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as e:
        msg = (e.stderr or e.stdout or str(e)).strip()
        error_exit(f"rp-cli failed: {msg}", use_json=False, code=2)


def normalize_repo_root(path: str) -> list[str]:
    """Normalize repo root for window matching."""
    root = os.path.realpath(path)
    roots = [root]
    if root.startswith("/private/tmp/"):
        roots.append("/tmp/" + root[len("/private/tmp/"):])
    elif root.startswith("/tmp/"):
        roots.append("/private/tmp/" + root[len("/tmp/"):])
    return list(dict.fromkeys(roots))


def parse_windows(raw: str) -> list[dict[str, Any]]:
    """Parse rp-cli windows JSON."""
    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return data
        if isinstance(data, dict) and "windows" in data and isinstance(data["windows"], list):
            return data["windows"]
    except json.JSONDecodeError as e:
        if "single-window mode" in raw:
            return [{"windowID": 1, "rootFolderPaths": []}]
        error_exit(f"windows JSON parse failed: {e}", use_json=False, code=2)
    error_exit("windows JSON has unexpected shape", use_json=False, code=2)


def extract_window_id(win: dict[str, Any]) -> Optional[int]:
    for key in ("windowID", "windowId", "id"):
        if key in win:
            try:
                return int(win[key])
            except Exception:
                return None
    return None


def extract_root_paths(win: dict[str, Any]) -> list[str]:
    for key in ("rootFolderPaths", "rootFolders", "rootFolderPath"):
        if key in win:
            val = win[key]
            if isinstance(val, list):
                return [str(v) for v in val]
            if isinstance(val, str):
                return [val]
    return []


def parse_builder_tab(output: str) -> str:
    match = re.search(r"Tab:\s*([A-Za-z0-9-]+)", output)
    if not match:
        error_exit("builder output missing Tab id", use_json=False, code=2)
    return match.group(1)


def parse_chat_id(output: str) -> Optional[str]:
    match = re.search(r"Chat\s*:\s*`([^`]+)`", output)
    if match:
        return match.group(1)
    match = re.search(r"\"chat_id\"\s*:\s*\"([^\"]+)\"", output)
    if match:
        return match.group(1)
    return None


def build_chat_payload(
    message: str,
    mode: str,
    new_chat: bool = False,
    chat_name: Optional[str] = None,
    selected_paths: Optional[list[str]] = None,
) -> str:
    payload: dict[str, Any] = {
        "message": message,
        "mode": mode,
    }
    if new_chat:
        payload["new_chat"] = True
    if chat_name:
        payload["chat_name"] = chat_name
    if selected_paths:
        payload["selected_paths"] = selected_paths
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def is_supported_schema(version: Any) -> bool:
    """Check schema version compatibility."""
    try:
        return int(version) in SUPPORTED_SCHEMA_VERSIONS
    except Exception:
        return False


def atomic_write(path: Path, content: str) -> None:
    """Write file atomically via temp + rename."""
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_path, path)
    except Exception:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise


def atomic_write_json(path: Path, data: dict) -> None:
    """Write JSON file atomically with sorted keys."""
    content = json.dumps(data, indent=2, sort_keys=True) + "\n"
    atomic_write(path, content)


def load_json(path: Path) -> dict:
    """Load JSON file."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_json_or_exit(path: Path, what: str, use_json: bool = True) -> dict:
    """Load JSON file with safe error handling."""
    if not path.exists():
        error_exit(f"{what} missing: {path}", use_json=use_json)
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        error_exit(f"{what} invalid JSON: {path} ({e})", use_json=use_json)
    except Exception as e:
        error_exit(f"{what} unreadable: {path} ({e})", use_json=use_json)


def read_text_or_exit(path: Path, what: str, use_json: bool = True) -> str:
    """Read text file with safe error handling."""
    if not path.exists():
        error_exit(f"{what} missing: {path}", use_json=use_json)
    try:
        return path.read_text(encoding="utf-8")
    except Exception as e:
        error_exit(f"{what} unreadable: {path} ({e})", use_json=use_json)


def parse_id(id_str: str) -> tuple[Optional[int], Optional[int]]:
    """Parse ID into (epic_num, task_num). Returns (epic, None) for epic IDs."""
    match = re.match(r"^fn-(\d+)(?:\.(\d+))?$", id_str)
    if not match:
        return None, None
    epic = int(match.group(1))
    task = int(match.group(2)) if match.group(2) else None
    return epic, task


def normalize_epic(epic_data: dict) -> dict:
    """Apply defaults for optional epic fields."""
    if "plan_review_status" not in epic_data:
        epic_data["plan_review_status"] = "unknown"
    if "plan_reviewed_at" not in epic_data:
        epic_data["plan_reviewed_at"] = None
    if "branch_name" not in epic_data:
        epic_data["branch_name"] = None
    if "depends_on_epics" not in epic_data:
        epic_data["depends_on_epics"] = []
    return epic_data


def normalize_task(task_data: dict) -> dict:
    """Apply defaults for optional task fields."""
    if "priority" not in task_data:
        task_data["priority"] = None
    return task_data


def task_priority(task_data: dict) -> int:
    """Priority for sorting (None -> 999)."""
    try:
        if task_data.get("priority") is None:
            return 999
        return int(task_data.get("priority"))
    except Exception:
        return 999


def is_epic_id(id_str: str) -> bool:
    """Check if ID is an epic ID (fn-N)."""
    epic, task = parse_id(id_str)
    return epic is not None and task is None


def is_task_id(id_str: str) -> bool:
    """Check if ID is a task ID (fn-N.M)."""
    epic, task = parse_id(id_str)
    return epic is not None and task is not None


def epic_id_from_task(task_id: str) -> str:
    """Extract epic ID from task ID. Raises ValueError if invalid."""
    epic, task = parse_id(task_id)
    if epic is None or task is None:
        raise ValueError(f"Invalid task ID: {task_id}")
    return f"fn-{epic}"


def get_actor() -> str:
    """Determine current actor for soft-claim semantics.

    Priority:
    1. FLOW_ACTOR env var
    2. git config user.email
    3. git config user.name
    4. $USER env var
    5. "unknown"
    """
    # 1. FLOW_ACTOR env var
    if actor := os.environ.get("FLOW_ACTOR"):
        return actor.strip()

    # 2. git config user.email (preferred)
    try:
        result = subprocess.run(
            ["git", "config", "user.email"],
            capture_output=True, text=True, check=True
        )
        if email := result.stdout.strip():
            return email
    except subprocess.CalledProcessError:
        pass

    # 3. git config user.name
    try:
        result = subprocess.run(
            ["git", "config", "user.name"],
            capture_output=True, text=True, check=True
        )
        if name := result.stdout.strip():
            return name
    except subprocess.CalledProcessError:
        pass

    # 4. $USER env var
    if user := os.environ.get("USER"):
        return user

    # 5. fallback
    return "unknown"


def scan_max_epic_id(flow_dir: Path) -> int:
    """Scan .flow/epics/ to find max epic number. Returns 0 if none exist."""
    epics_dir = flow_dir / EPICS_DIR
    if not epics_dir.exists():
        return 0

    max_n = 0
    for epic_file in epics_dir.glob("fn-*.json"):
        match = re.match(r"^fn-(\d+)\.json$", epic_file.name)
        if match:
            n = int(match.group(1))
            max_n = max(max_n, n)
    return max_n


def scan_max_task_id(flow_dir: Path, epic_id: str) -> int:
    """Scan .flow/tasks/ to find max task number for an epic. Returns 0 if none exist."""
    tasks_dir = flow_dir / TASKS_DIR
    if not tasks_dir.exists():
        return 0

    max_m = 0
    for task_file in tasks_dir.glob(f"{epic_id}.*.json"):
        match = re.match(rf"^{re.escape(epic_id)}\.(\d+)\.json$", task_file.name)
        if match:
            m = int(match.group(1))
            max_m = max(max_m, m)
    return max_m


def require_keys(obj: dict, keys: list[str], what: str, use_json: bool = True) -> None:
    """Validate dict has required keys. Exits on missing keys."""
    missing = [k for k in keys if k not in obj]
    if missing:
        error_exit(f"{what} missing required keys: {', '.join(missing)}", use_json=use_json)


# --- Spec File Operations ---

def create_epic_spec(id_str: str, title: str) -> str:
    """Create epic spec markdown content."""
    return f"""# {id_str} {title}

## Overview
TBD

## Scope
TBD

## Approach
TBD

## Quick commands
<!-- Required: at least one smoke command for the repo -->
- `# e.g., npm test, bun test, make test`

## Acceptance
- [ ] TBD

## References
- TBD
"""


def create_task_spec(id_str: str, title: str, acceptance: Optional[str] = None) -> str:
    """Create task spec markdown content."""
    acceptance_content = acceptance if acceptance else "- [ ] TBD"
    return f"""# {id_str} {title}

## Description
TBD

## Acceptance
{acceptance_content}

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
"""


def patch_task_section(content: str, section: str, new_content: str) -> str:
    """Patch a specific section in task spec. Preserves other sections.

    Raises ValueError on invalid content (duplicate/missing headings).
    """
    # Check for duplicate headings first (defensive)
    pattern = rf'^{re.escape(section)}\s*$'
    matches = len(re.findall(pattern, content, flags=re.MULTILINE))
    if matches > 1:
        raise ValueError(f"Cannot patch: duplicate heading '{section}' found ({matches} times)")

    lines = content.split("\n")
    result = []
    in_target_section = False
    section_found = False

    for i, line in enumerate(lines):
        if line.startswith("## "):
            if line.strip() == section:
                in_target_section = True
                section_found = True
                result.append(line)
                # Add new content
                result.append(new_content.rstrip())
                continue
            else:
                in_target_section = False

        if not in_target_section:
            result.append(line)

    if not section_found:
        raise ValueError(f"Section '{section}' not found in task spec")

    return "\n".join(result)


def get_task_section(content: str, section: str) -> str:
    """Get content under a task section heading."""
    lines = content.split("\n")
    in_target = False
    collected = []
    for line in lines:
        if line.startswith("## "):
            if line.strip() == section:
                in_target = True
                continue
            if in_target:
                break
        if in_target:
            collected.append(line)
    return "\n".join(collected).strip()


def validate_task_spec_headings(content: str) -> list[str]:
    """Validate task spec has required headings exactly once. Returns errors."""
    errors = []
    for heading in TASK_SPEC_HEADINGS:
        # Use regex anchored to line start to avoid matching inside code blocks
        pattern = rf'^{re.escape(heading)}\s*$'
        count = len(re.findall(pattern, content, flags=re.MULTILINE))
        if count == 0:
            errors.append(f"Missing required heading: {heading}")
        elif count > 1:
            errors.append(f"Duplicate heading: {heading} (found {count} times)")
    return errors


# --- Commands ---

def cmd_init(args: argparse.Namespace) -> None:
    """Initialize .flow/ directory structure."""
    flow_dir = get_flow_dir()

    if flow_dir.exists():
        if args.json:
            json_output({"message": ".flow/ already exists", "path": str(flow_dir)})
        else:
            print(f".flow/ already exists at {flow_dir}")
        return

    # Create directory structure
    (flow_dir / EPICS_DIR).mkdir(parents=True)
    (flow_dir / SPECS_DIR).mkdir(parents=True)
    (flow_dir / TASKS_DIR).mkdir(parents=True)
    (flow_dir / MEMORY_DIR).mkdir(parents=True)

    # Create meta.json
    meta = {
        "schema_version": SCHEMA_VERSION,
        "next_epic": 1
    }
    atomic_write_json(flow_dir / META_FILE, meta)

    if args.json:
        json_output({"message": ".flow/ initialized", "path": str(flow_dir)})
    else:
        print(f".flow/ initialized at {flow_dir}")


def cmd_detect(args: argparse.Namespace) -> None:
    """Check if .flow/ exists and is valid."""
    flow_dir = get_flow_dir()
    exists = flow_dir.exists()
    valid = False
    issues = []

    if exists:
        meta_path = flow_dir / META_FILE
        if not meta_path.exists():
            issues.append("meta.json missing")
        else:
            try:
                meta = load_json(meta_path)
                if not is_supported_schema(meta.get("schema_version")):
                    issues.append(
                        f"schema_version unsupported (expected {', '.join(map(str, SUPPORTED_SCHEMA_VERSIONS))})"
                    )
            except Exception as e:
                issues.append(f"meta.json parse error: {e}")

        # Check required subdirectories
        for subdir in [EPICS_DIR, SPECS_DIR, TASKS_DIR, MEMORY_DIR]:
            if not (flow_dir / subdir).exists():
                issues.append(f"{subdir}/ missing")

        valid = len(issues) == 0

    if args.json:
        result = {
            "exists": exists,
            "valid": valid,
            "path": str(flow_dir) if exists else None
        }
        if issues:
            result["issues"] = issues
        json_output(result)
    else:
        if exists and valid:
            print(f".flow/ exists and is valid at {flow_dir}")
        elif exists:
            print(f".flow/ exists but has issues at {flow_dir}:")
            for issue in issues:
                print(f"  - {issue}")
        else:
            print(".flow/ does not exist")


def cmd_epic_create(args: argparse.Namespace) -> None:
    """Create a new epic."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    flow_dir = get_flow_dir()
    meta_path = flow_dir / META_FILE
    meta = load_json_or_exit(meta_path, "meta.json", use_json=args.json)

    # MU-1: Scan-based allocation for merge safety
    # Scan existing epics to determine next ID (don't rely on counter)
    max_epic = scan_max_epic_id(flow_dir)
    epic_num = max_epic + 1
    epic_id = f"fn-{epic_num}"

    # Double-check no collision (shouldn't happen with scan-based allocation)
    epic_json_path = flow_dir / EPICS_DIR / f"{epic_id}.json"
    epic_spec_path = flow_dir / SPECS_DIR / f"{epic_id}.md"
    if epic_json_path.exists() or epic_spec_path.exists():
        error_exit(
            f"Refusing to overwrite existing epic {epic_id}. "
            f"This shouldn't happen - check for orphaned files.",
            use_json=args.json
        )

    # Create epic JSON
    epic_data = {
        "id": epic_id,
        "title": args.title,
        "status": "open",
        "plan_review_status": "unknown",
        "plan_reviewed_at": None,
        "branch_name": args.branch if args.branch else None,
        "depends_on_epics": [],
        "spec_path": f"{FLOW_DIR}/{SPECS_DIR}/{epic_id}.md",
        "next_task": 1,
        "created_at": now_iso(),
        "updated_at": now_iso()
    }
    atomic_write_json(flow_dir / EPICS_DIR / f"{epic_id}.json", epic_data)

    # Create epic spec
    spec_content = create_epic_spec(epic_id, args.title)
    atomic_write(flow_dir / SPECS_DIR / f"{epic_id}.md", spec_content)

    # NOTE: We no longer update meta["next_epic"] since scan-based allocation
    # is the source of truth. This reduces merge conflicts.

    if args.json:
        json_output({
            "id": epic_id,
            "title": args.title,
            "spec_path": epic_data["spec_path"],
            "message": f"Epic {epic_id} created"
        })
    else:
        print(f"Epic {epic_id} created: {args.title}")


def cmd_task_create(args: argparse.Namespace) -> None:
    """Create a new task under an epic."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_epic_id(args.epic):
        error_exit(f"Invalid epic ID: {args.epic}. Expected format: fn-N", use_json=args.json)

    flow_dir = get_flow_dir()
    epic_path = flow_dir / EPICS_DIR / f"{args.epic}.json"

    epic_data = load_json_or_exit(epic_path, f"Epic {args.epic}", use_json=args.json)

    # MU-1: Scan-based allocation for merge safety
    # Scan existing tasks to determine next ID (don't rely on counter)
    max_task = scan_max_task_id(flow_dir, args.epic)
    task_num = max_task + 1
    task_id = f"{args.epic}.{task_num}"

    # Double-check no collision (shouldn't happen with scan-based allocation)
    task_json_path = flow_dir / TASKS_DIR / f"{task_id}.json"
    task_spec_path = flow_dir / TASKS_DIR / f"{task_id}.md"
    if task_json_path.exists() or task_spec_path.exists():
        error_exit(
            f"Refusing to overwrite existing task {task_id}. "
            f"This shouldn't happen - check for orphaned files.",
            use_json=args.json
        )

    # Parse dependencies
    deps = []
    if args.deps:
        deps = [d.strip() for d in args.deps.split(",")]
        # Validate deps are valid task IDs within same epic
        for dep in deps:
            if not is_task_id(dep):
                error_exit(f"Invalid dependency ID: {dep}. Expected format: fn-N.M", use_json=args.json)
            if epic_id_from_task(dep) != args.epic:
                error_exit(f"Dependency {dep} must be within the same epic ({args.epic})", use_json=args.json)

    # Read acceptance from file if provided
    acceptance = None
    if args.acceptance_file:
        acceptance = read_text_or_exit(Path(args.acceptance_file), "Acceptance file", use_json=args.json)

    # Create task JSON (MU-2: includes soft-claim fields)
    task_data = {
        "id": task_id,
        "epic": args.epic,
        "title": args.title,
        "status": "todo",
        "priority": args.priority,
        "depends_on": deps,
        "assignee": None,
        "claimed_at": None,
        "claim_note": "",
        "spec_path": f"{FLOW_DIR}/{TASKS_DIR}/{task_id}.md",
        "created_at": now_iso(),
        "updated_at": now_iso()
    }
    atomic_write_json(flow_dir / TASKS_DIR / f"{task_id}.json", task_data)

    # Create task spec
    spec_content = create_task_spec(task_id, args.title, acceptance)
    atomic_write(flow_dir / TASKS_DIR / f"{task_id}.md", spec_content)

    # NOTE: We no longer update epic["next_task"] since scan-based allocation
    # is the source of truth. This reduces merge conflicts.

    if args.json:
        json_output({
            "id": task_id,
            "epic": args.epic,
            "title": args.title,
            "depends_on": deps,
            "spec_path": task_data["spec_path"],
            "message": f"Task {task_id} created"
        })
    else:
        print(f"Task {task_id} created: {args.title}")


def cmd_dep_add(args: argparse.Namespace) -> None:
    """Add a dependency to a task."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_task_id(args.task):
        error_exit(f"Invalid task ID: {args.task}. Expected format: fn-N.M", use_json=args.json)

    if not is_task_id(args.depends_on):
        error_exit(f"Invalid dependency ID: {args.depends_on}. Expected format: fn-N.M", use_json=args.json)

    # Validate same epic
    task_epic = epic_id_from_task(args.task)
    dep_epic = epic_id_from_task(args.depends_on)
    if task_epic != dep_epic:
        error_exit(f"Dependencies must be within the same epic. Task {args.task} is in {task_epic}, dependency {args.depends_on} is in {dep_epic}", use_json=args.json)

    flow_dir = get_flow_dir()
    task_path = flow_dir / TASKS_DIR / f"{args.task}.json"

    task_data = load_json_or_exit(task_path, f"Task {args.task}", use_json=args.json)

    if args.depends_on not in task_data["depends_on"]:
        task_data["depends_on"].append(args.depends_on)
        task_data["updated_at"] = now_iso()
        atomic_write_json(task_path, task_data)

    if args.json:
        json_output({
            "task": args.task,
            "depends_on": task_data["depends_on"],
            "message": f"Dependency {args.depends_on} added to {args.task}"
        })
    else:
        print(f"Dependency {args.depends_on} added to {args.task}")


def cmd_show(args: argparse.Namespace) -> None:
    """Show epic or task details."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    flow_dir = get_flow_dir()

    if is_epic_id(args.id):
        epic_path = flow_dir / EPICS_DIR / f"{args.id}.json"
        epic_data = normalize_epic(
            load_json_or_exit(epic_path, f"Epic {args.id}", use_json=args.json)
        )

        # Get tasks for this epic
        tasks = []
        tasks_dir = flow_dir / TASKS_DIR
        if tasks_dir.exists():
            for task_file in sorted(tasks_dir.glob(f"{args.id}.*.json")):
                task_data = normalize_task(
                    load_json_or_exit(task_file, f"Task {task_file.stem}", use_json=args.json)
                )
                tasks.append({
                    "id": task_data["id"],
                    "title": task_data["title"],
                    "status": task_data["status"],
                    "priority": task_data.get("priority"),
                    "depends_on": task_data["depends_on"]
                })

        # Sort tasks by numeric suffix (safe via parse_id)
        def task_sort_key(t):
            _, task_num = parse_id(t["id"])
            return task_num if task_num is not None else 0
        tasks.sort(key=task_sort_key)

        result = {**epic_data, "tasks": tasks}

        if args.json:
            json_output(result)
        else:
            print(f"Epic: {epic_data['id']}")
            print(f"Title: {epic_data['title']}")
            print(f"Status: {epic_data['status']}")
            print(f"Spec: {epic_data['spec_path']}")
            print(f"\nTasks ({len(tasks)}):")
            for t in tasks:
                deps = f" (deps: {', '.join(t['depends_on'])})" if t['depends_on'] else ""
                print(f"  [{t['status']}] {t['id']}: {t['title']}{deps}")

    elif is_task_id(args.id):
        task_path = flow_dir / TASKS_DIR / f"{args.id}.json"
        task_data = normalize_task(
            load_json_or_exit(task_path, f"Task {args.id}", use_json=args.json)
        )

        if args.json:
            json_output(task_data)
        else:
            print(f"Task: {task_data['id']}")
            print(f"Epic: {task_data['epic']}")
            print(f"Title: {task_data['title']}")
            print(f"Status: {task_data['status']}")
            print(f"Depends on: {', '.join(task_data['depends_on']) or 'none'}")
            print(f"Spec: {task_data['spec_path']}")

    else:
        error_exit(f"Invalid ID: {args.id}. Expected format: fn-N (epic) or fn-N.M (task)", use_json=args.json)


def cmd_epics(args: argparse.Namespace) -> None:
    """List all epics."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    flow_dir = get_flow_dir()
    epics_dir = flow_dir / EPICS_DIR

    epics = []
    if epics_dir.exists():
        for epic_file in sorted(epics_dir.glob("fn-*.json")):
            epic_data = normalize_epic(
                load_json_or_exit(epic_file, f"Epic {epic_file.stem}", use_json=args.json)
            )
            # Count tasks
            tasks_dir = flow_dir / TASKS_DIR
            task_count = 0
            done_count = 0
            if tasks_dir.exists():
                for task_file in tasks_dir.glob(f"{epic_data['id']}.*.json"):
                    task_data = load_json_or_exit(task_file, f"Task {task_file.stem}", use_json=args.json)
                    task_count += 1
                    if task_data.get("status") == "done":
                        done_count += 1

            epics.append({
                "id": epic_data["id"],
                "title": epic_data["title"],
                "status": epic_data["status"],
                "tasks": task_count,
                "done": done_count
            })

    # Sort by epic number
    def epic_sort_key(e):
        epic_num, _ = parse_id(e["id"])
        return epic_num if epic_num is not None else 0
    epics.sort(key=epic_sort_key)

    if args.json:
        json_output({"success": True, "epics": epics, "count": len(epics)})
    else:
        if not epics:
            print("No epics found.")
        else:
            print(f"Epics ({len(epics)}):\n")
            for e in epics:
                progress = f"{e['done']}/{e['tasks']}" if e['tasks'] > 0 else "0/0"
                print(f"  [{e['status']}] {e['id']}: {e['title']} ({progress} tasks done)")


def cmd_tasks(args: argparse.Namespace) -> None:
    """List tasks."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    flow_dir = get_flow_dir()
    tasks_dir = flow_dir / TASKS_DIR

    tasks = []
    if tasks_dir.exists():
        pattern = f"{args.epic}.*.json" if args.epic else "fn-*.json"
        for task_file in sorted(tasks_dir.glob(pattern)):
            # Skip if it's not a task file (must have . in the name before .json)
            stem = task_file.stem
            if "." not in stem:
                continue
            task_data = normalize_task(
                load_json_or_exit(task_file, f"Task {stem}", use_json=args.json)
            )
            # Filter by status if requested
            if args.status and task_data["status"] != args.status:
                continue
            tasks.append({
                "id": task_data["id"],
                "epic": task_data["epic"],
                "title": task_data["title"],
                "status": task_data["status"],
                "priority": task_data.get("priority"),
                "depends_on": task_data["depends_on"]
            })

    # Sort tasks by epic number then task number
    def task_sort_key(t):
        epic_num, task_num = parse_id(t["id"])
        return (epic_num if epic_num is not None else 0, task_num if task_num is not None else 0)
    tasks.sort(key=task_sort_key)

    if args.json:
        json_output({"success": True, "tasks": tasks, "count": len(tasks)})
    else:
        if not tasks:
            scope = f" for epic {args.epic}" if args.epic else ""
            status_filter = f" with status '{args.status}'" if args.status else ""
            print(f"No tasks found{scope}{status_filter}.")
        else:
            scope = f" for {args.epic}" if args.epic else ""
            print(f"Tasks{scope} ({len(tasks)}):\n")
            for t in tasks:
                deps = f" (deps: {', '.join(t['depends_on'])})" if t['depends_on'] else ""
                print(f"  [{t['status']}] {t['id']}: {t['title']}{deps}")


def cmd_list(args: argparse.Namespace) -> None:
    """List all epics and their tasks."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    flow_dir = get_flow_dir()
    epics_dir = flow_dir / EPICS_DIR
    tasks_dir = flow_dir / TASKS_DIR

    # Load all epics
    epics = []
    if epics_dir.exists():
        for epic_file in sorted(epics_dir.glob("fn-*.json")):
            epic_data = normalize_epic(
                load_json_or_exit(epic_file, f"Epic {epic_file.stem}", use_json=args.json)
            )
            epics.append(epic_data)

    # Sort epics by number
    def epic_sort_key(e):
        epic_num, _ = parse_id(e["id"])
        return epic_num if epic_num is not None else 0
    epics.sort(key=epic_sort_key)

    # Load all tasks grouped by epic
    tasks_by_epic = {}
    all_tasks = []
    if tasks_dir.exists():
        for task_file in sorted(tasks_dir.glob("fn-*.json")):
            stem = task_file.stem
            if "." not in stem:
                continue
            task_data = normalize_task(
                load_json_or_exit(task_file, f"Task {stem}", use_json=args.json)
            )
            epic_id = task_data["epic"]
            if epic_id not in tasks_by_epic:
                tasks_by_epic[epic_id] = []
            tasks_by_epic[epic_id].append(task_data)
            all_tasks.append({
                "id": task_data["id"],
                "epic": task_data["epic"],
                "title": task_data["title"],
                "status": task_data["status"],
                "priority": task_data.get("priority"),
                "depends_on": task_data["depends_on"]
            })

    # Sort tasks within each epic
    for epic_id in tasks_by_epic:
        tasks_by_epic[epic_id].sort(key=lambda t: parse_id(t["id"])[1] or 0)

    if args.json:
        epics_out = []
        for e in epics:
            task_list = tasks_by_epic.get(e["id"], [])
            done_count = sum(1 for t in task_list if t["status"] == "done")
            epics_out.append({
                "id": e["id"],
                "title": e["title"],
                "status": e["status"],
                "tasks": len(task_list),
                "done": done_count
            })
        json_output({
            "success": True,
            "epics": epics_out,
            "tasks": all_tasks,
            "epic_count": len(epics),
            "task_count": len(all_tasks)
        })
    else:
        if not epics:
            print("No epics or tasks found.")
            return

        total_tasks = len(all_tasks)
        total_done = sum(1 for t in all_tasks if t["status"] == "done")
        print(f"Flow Status: {len(epics)} epics, {total_tasks} tasks ({total_done} done)\n")

        for e in epics:
            task_list = tasks_by_epic.get(e["id"], [])
            done_count = sum(1 for t in task_list if t["status"] == "done")
            progress = f"{done_count}/{len(task_list)}" if task_list else "0/0"
            print(f"[{e['status']}] {e['id']}: {e['title']} ({progress} done)")

            for t in task_list:
                deps = f" (deps: {', '.join(t['depends_on'])})" if t['depends_on'] else ""
                print(f"    [{t['status']}] {t['id']}: {t['title']}{deps}")
            print()


def cmd_cat(args: argparse.Namespace) -> None:
    """Print markdown spec for epic or task."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=False)

    flow_dir = get_flow_dir()

    if is_epic_id(args.id):
        spec_path = flow_dir / SPECS_DIR / f"{args.id}.md"
    elif is_task_id(args.id):
        spec_path = flow_dir / TASKS_DIR / f"{args.id}.md"
    else:
        error_exit(f"Invalid ID: {args.id}. Expected format: fn-N (epic) or fn-N.M (task)", use_json=False)
        return

    content = read_text_or_exit(spec_path, f"Spec {args.id}", use_json=False)
    print(content)


def cmd_epic_set_plan(args: argparse.Namespace) -> None:
    """Set/overwrite entire epic spec from file."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_epic_id(args.id):
        error_exit(f"Invalid epic ID: {args.id}. Expected format: fn-N", use_json=args.json)

    flow_dir = get_flow_dir()
    epic_path = flow_dir / EPICS_DIR / f"{args.id}.json"

    # Verify epic exists (will be loaded later for timestamp update)
    if not epic_path.exists():
        error_exit(f"Epic {args.id} not found", use_json=args.json)

    # Read content from file
    content = read_text_or_exit(Path(args.file), "Input file", use_json=args.json)

    # Write spec
    spec_path = flow_dir / SPECS_DIR / f"{args.id}.md"
    atomic_write(spec_path, content)

    # Update epic timestamp
    epic_data = load_json_or_exit(epic_path, f"Epic {args.id}", use_json=args.json)
    epic_data["updated_at"] = now_iso()
    atomic_write_json(epic_path, epic_data)

    if args.json:
        json_output({
            "id": args.id,
            "spec_path": str(spec_path),
            "message": f"Epic {args.id} spec updated"
        })
    else:
        print(f"Epic {args.id} spec updated")


def cmd_epic_set_plan_review_status(args: argparse.Namespace) -> None:
    """Set plan review status for an epic."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_epic_id(args.id):
        error_exit(f"Invalid epic ID: {args.id}. Expected format: fn-N", use_json=args.json)

    flow_dir = get_flow_dir()
    epic_path = flow_dir / EPICS_DIR / f"{args.id}.json"

    if not epic_path.exists():
        error_exit(f"Epic {args.id} not found", use_json=args.json)

    epic_data = normalize_epic(load_json_or_exit(epic_path, f"Epic {args.id}", use_json=args.json))
    epic_data["plan_review_status"] = args.status
    epic_data["plan_reviewed_at"] = now_iso()
    epic_data["updated_at"] = now_iso()
    atomic_write_json(epic_path, epic_data)

    if args.json:
        json_output({
            "id": args.id,
            "plan_review_status": epic_data["plan_review_status"],
            "plan_reviewed_at": epic_data["plan_reviewed_at"],
            "message": f"Epic {args.id} plan review status set to {args.status}"
        })
    else:
        print(f"Epic {args.id} plan review status set to {args.status}")


def cmd_epic_set_branch(args: argparse.Namespace) -> None:
    """Set epic branch name."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_epic_id(args.id):
        error_exit(f"Invalid epic ID: {args.id}. Expected format: fn-N", use_json=args.json)

    flow_dir = get_flow_dir()
    epic_path = flow_dir / EPICS_DIR / f"{args.id}.json"

    if not epic_path.exists():
        error_exit(f"Epic {args.id} not found", use_json=args.json)

    epic_data = normalize_epic(load_json_or_exit(epic_path, f"Epic {args.id}", use_json=args.json))
    epic_data["branch_name"] = args.branch
    epic_data["updated_at"] = now_iso()
    atomic_write_json(epic_path, epic_data)

    if args.json:
        json_output({
            "id": args.id,
            "branch_name": epic_data["branch_name"],
            "message": f"Epic {args.id} branch_name set to {args.branch}"
        })
    else:
        print(f"Epic {args.id} branch_name set to {args.branch}")


def cmd_task_set_description(args: argparse.Namespace) -> None:
    """Set task description section."""
    _task_set_section(args.id, "## Description", args.file, args.json)


def cmd_task_set_acceptance(args: argparse.Namespace) -> None:
    """Set task acceptance section."""
    _task_set_section(args.id, "## Acceptance", args.file, args.json)


def _task_set_section(task_id: str, section: str, file_path: str, use_json: bool) -> None:
    """Helper to set a task spec section."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=use_json)

    if not is_task_id(task_id):
        error_exit(f"Invalid task ID: {task_id}. Expected format: fn-N.M", use_json=use_json)

    flow_dir = get_flow_dir()
    task_json_path = flow_dir / TASKS_DIR / f"{task_id}.json"
    task_spec_path = flow_dir / TASKS_DIR / f"{task_id}.md"

    # Verify task exists
    if not task_json_path.exists():
        error_exit(f"Task {task_id} not found", use_json=use_json)

    # Read new content
    new_content = read_text_or_exit(Path(file_path), "Input file", use_json=use_json)

    # Load task JSON first (fail early before any writes)
    task_data = load_json_or_exit(task_json_path, f"Task {task_id}", use_json=use_json)

    # Read current spec
    current_spec = read_text_or_exit(task_spec_path, f"Task {task_id} spec", use_json=use_json)

    # Patch section
    try:
        updated_spec = patch_task_section(current_spec, section, new_content)
    except ValueError as e:
        error_exit(str(e), use_json=use_json)

    # Write spec then JSON (both validated above)
    atomic_write(task_spec_path, updated_spec)
    task_data["updated_at"] = now_iso()
    atomic_write_json(task_json_path, task_data)

    if use_json:
        json_output({
            "id": task_id,
            "section": section,
            "message": f"Task {task_id} {section} updated"
        })
    else:
        print(f"Task {task_id} {section} updated")


def cmd_ready(args: argparse.Namespace) -> None:
    """List ready tasks for an epic."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_epic_id(args.epic):
        error_exit(f"Invalid epic ID: {args.epic}. Expected format: fn-N", use_json=args.json)

    flow_dir = get_flow_dir()
    epic_path = flow_dir / EPICS_DIR / f"{args.epic}.json"

    if not epic_path.exists():
        error_exit(f"Epic {args.epic} not found", use_json=args.json)

    # MU-2: Get current actor for display (marks your tasks)
    current_actor = get_actor()

    # Get all tasks for epic
    tasks_dir = flow_dir / TASKS_DIR
    if not tasks_dir.exists():
        error_exit(f"{TASKS_DIR}/ missing. Run 'flowctl init' or fix repo state.", use_json=args.json)
    tasks = {}
    for task_file in tasks_dir.glob(f"{args.epic}.*.json"):
        task_data = normalize_task(
            load_json_or_exit(task_file, f"Task {task_file.stem}", use_json=args.json)
        )
        tasks[task_data["id"]] = task_data

    # Find ready tasks (status=todo, all deps done)
    ready = []
    in_progress = []
    blocked = []

    for task_id, task in tasks.items():
        # MU-2: Track in_progress tasks separately
        if task["status"] == "in_progress":
            in_progress.append(task)
            continue

        if task["status"] == "done":
            continue

        if task["status"] == "blocked":
            blocked.append({"task": task, "blocked_by": ["status=blocked"]})
            continue

        # Check all deps are done
        deps_done = True
        blocking_deps = []
        for dep in task["depends_on"]:
            if dep not in tasks:
                deps_done = False
                blocking_deps.append(dep)
            elif tasks[dep]["status"] != "done":
                deps_done = False
                blocking_deps.append(dep)

        if deps_done:
            ready.append(task)
        else:
            blocked.append({"task": task, "blocked_by": blocking_deps})

    # Sort by numeric suffix
    def sort_key(t):
        _, task_num = parse_id(t["id"])
        return (task_priority(t), task_num if task_num is not None else 0, t.get("title", ""))
    ready.sort(key=sort_key)
    in_progress.sort(key=sort_key)
    blocked.sort(key=lambda x: sort_key(x["task"]))

    if args.json:
        json_output({
            "epic": args.epic,
            "actor": current_actor,
            "ready": [
                {"id": t["id"], "title": t["title"], "depends_on": t["depends_on"]}
                for t in ready
            ],
            "in_progress": [
                {"id": t["id"], "title": t["title"], "assignee": t.get("assignee")}
                for t in in_progress
            ],
            "blocked": [
                {"id": b["task"]["id"], "title": b["task"]["title"], "blocked_by": b["blocked_by"]}
                for b in blocked
            ]
        })
    else:
        print(f"Ready tasks for {args.epic} (actor: {current_actor}):")
        if ready:
            for t in ready:
                print(f"  {t['id']}: {t['title']}")
        else:
            print("  (none)")
        if in_progress:
            print("\nIn progress:")
            for t in in_progress:
                assignee = t.get("assignee") or "unknown"
                marker = " (you)" if assignee == current_actor else ""
                print(f"  {t['id']}: {t['title']} [{assignee}]{marker}")
        if blocked:
            print("\nBlocked:")
            for b in blocked:
                print(f"  {b['task']['id']}: {b['task']['title']} (by: {', '.join(b['blocked_by'])})")


def cmd_next(args: argparse.Namespace) -> None:
    """Select the next plan/work unit."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    flow_dir = get_flow_dir()

    # Resolve epics list
    epic_ids: list[str] = []
    if args.epics_file:
        data = load_json_or_exit(Path(args.epics_file), "Epics file", use_json=args.json)
        epics_val = data.get("epics")
        if not isinstance(epics_val, list):
            error_exit("Epics file must be JSON with key 'epics' as a list", use_json=args.json)
        for e in epics_val:
            if not isinstance(e, str) or not is_epic_id(e):
                error_exit(f"Invalid epic ID in epics file: {e}", use_json=args.json)
            epic_ids.append(e)
    else:
        epics_dir = flow_dir / EPICS_DIR
        if epics_dir.exists():
            for epic_file in sorted(epics_dir.glob("fn-*.json")):
                match = re.match(r"^fn-(\d+)\.json$", epic_file.name)
                if match:
                    epic_ids.append(f"fn-{match.group(1)}")
        epic_ids.sort(key=lambda e: parse_id(e)[0] or 0)

    current_actor = get_actor()

    def sort_key(t: dict) -> tuple[int, int]:
        _, task_num = parse_id(t["id"])
        return (task_priority(t), task_num if task_num is not None else 0)

    blocked_epics: dict[str, list[str]] = {}

    for epic_id in epic_ids:
        epic_path = flow_dir / EPICS_DIR / f"{epic_id}.json"
        if not epic_path.exists():
            if args.epics_file:
                error_exit(f"Epic {epic_id} not found", use_json=args.json)
            continue

        epic_data = normalize_epic(load_json_or_exit(epic_path, f"Epic {epic_id}", use_json=args.json))
        if epic_data.get("status") == "done":
            continue

        # Skip epics blocked by epic-level dependencies
        blocked_by: list[str] = []
        for dep in epic_data.get("depends_on_epics", []) or []:
            if dep == epic_id:
                continue
            dep_path = flow_dir / EPICS_DIR / f"{dep}.json"
            if not dep_path.exists():
                blocked_by.append(dep)
                continue
            dep_data = normalize_epic(load_json_or_exit(dep_path, f"Epic {dep}", use_json=args.json))
            if dep_data.get("status") != "done":
                blocked_by.append(dep)
        if blocked_by:
            blocked_epics[epic_id] = blocked_by
            continue

        if args.require_plan_review and epic_data.get("plan_review_status") != "ship":
            if args.json:
                json_output({
                    "status": "plan",
                    "epic": epic_id,
                    "task": None,
                    "reason": "needs_plan_review"
                })
            else:
                print(f"plan {epic_id} needs_plan_review")
            return

        tasks_dir = flow_dir / TASKS_DIR
        if not tasks_dir.exists():
            error_exit(f"{TASKS_DIR}/ missing. Run 'flowctl init' or fix repo state.", use_json=args.json)

        tasks: dict[str, dict] = {}
        for task_file in tasks_dir.glob(f"{epic_id}.*.json"):
            task_data = normalize_task(
                load_json_or_exit(task_file, f"Task {task_file.stem}", use_json=args.json)
            )
            tasks[task_data["id"]] = task_data

        # Resume in_progress tasks owned by current actor
        in_progress = [
            t for t in tasks.values()
            if t.get("status") == "in_progress" and t.get("assignee") == current_actor
        ]
        in_progress.sort(key=sort_key)
        if in_progress:
            task_id = in_progress[0]["id"]
            if args.json:
                json_output({
                    "status": "work",
                    "epic": epic_id,
                    "task": task_id,
                    "reason": "resume_in_progress"
                })
            else:
                print(f"work {task_id} resume_in_progress")
            return

        # Ready tasks by deps + priority
        ready: list[dict] = []
        for task in tasks.values():
            if task.get("status") != "todo":
                continue
            if task.get("status") == "blocked":
                continue
            deps_done = True
            for dep in task.get("depends_on", []):
                dep_task = tasks.get(dep)
                if not dep_task or dep_task.get("status") != "done":
                    deps_done = False
                    break
            if deps_done:
                ready.append(task)

        ready.sort(key=sort_key)
        if ready:
            task_id = ready[0]["id"]
            if args.json:
                json_output({
                    "status": "work",
                    "epic": epic_id,
                    "task": task_id,
                    "reason": "ready_task"
                })
            else:
                print(f"work {task_id} ready_task")
            return

    if args.json:
        payload = {"status": "none", "epic": None, "task": None, "reason": "none"}
        if blocked_epics:
            payload["reason"] = "blocked_by_epic_deps"
            payload["blocked_epics"] = blocked_epics
        json_output(payload)
    else:
        if blocked_epics:
            print("none blocked_by_epic_deps")
            for epic_id, deps in blocked_epics.items():
                print(f"  {epic_id}: {', '.join(deps)}")
        else:
            print("none")


def cmd_start(args: argparse.Namespace) -> None:
    """Start a task (set status to in_progress)."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_task_id(args.id):
        error_exit(f"Invalid task ID: {args.id}. Expected format: fn-N.M", use_json=args.json)

    flow_dir = get_flow_dir()
    task_path = flow_dir / TASKS_DIR / f"{args.id}.json"

    task_data = load_json_or_exit(task_path, f"Task {args.id}", use_json=args.json)

    # MU-2: Soft-claim semantics
    current_actor = get_actor()
    existing_assignee = task_data.get("assignee")

    # Cannot start done task
    if task_data["status"] == "done":
        error_exit(
            f"Cannot start task {args.id}: status is 'done'.",
            use_json=args.json
        )

    # Blocked requires --force
    if task_data["status"] == "blocked" and not args.force:
        error_exit(
            f"Cannot start task {args.id}: status is 'blocked'. Use --force to override.",
            use_json=args.json
        )

    # Check if claimed by someone else (unless --force)
    if not args.force and existing_assignee and existing_assignee != current_actor:
        error_exit(
            f"Cannot start task {args.id}: claimed by '{existing_assignee}'. "
            f"Use --force to override.",
            use_json=args.json
        )

    # Validate task is in todo status (unless --force or resuming own task)
    if not args.force and task_data["status"] != "todo":
        # Allow resuming your own in_progress task
        if not (task_data["status"] == "in_progress" and existing_assignee == current_actor):
            error_exit(
                f"Cannot start task {args.id}: status is '{task_data['status']}', expected 'todo'. "
                f"Use --force to override.",
                use_json=args.json
            )

    # Validate all dependencies are done (unless --force)
    if not args.force:
        for dep in task_data.get("depends_on", []):
            dep_path = flow_dir / TASKS_DIR / f"{dep}.json"
            dep_data = load_json_or_exit(dep_path, f"Dependency {dep}", use_json=args.json)
            if dep_data["status"] != "done":
                error_exit(
                    f"Cannot start task {args.id}: dependency {dep} is '{dep_data['status']}', not 'done'. "
                    f"Complete dependencies first or use --force to override.",
                    use_json=args.json
                )

    # Set status and claim fields
    task_data["status"] = "in_progress"
    if not existing_assignee:
        task_data["assignee"] = current_actor
        task_data["claimed_at"] = now_iso()
    if args.note:
        task_data["claim_note"] = args.note
    elif args.force and existing_assignee and existing_assignee != current_actor:
        # Force override: note the takeover
        task_data["assignee"] = current_actor
        task_data["claimed_at"] = now_iso()
        if not args.note:
            task_data["claim_note"] = f"Taken over from {existing_assignee}"
    task_data["updated_at"] = now_iso()
    atomic_write_json(task_path, task_data)

    # NOTE: We no longer update epic timestamp on task start/done.
    # Epic timestamp only changes on epic-level operations (set-plan, close).
    # This reduces merge conflicts in multi-user scenarios.

    if args.json:
        json_output({
            "id": args.id,
            "status": "in_progress",
            "message": f"Task {args.id} started"
        })
    else:
        print(f"Task {args.id} started")


def cmd_done(args: argparse.Namespace) -> None:
    """Complete a task with summary and evidence."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_task_id(args.id):
        error_exit(f"Invalid task ID: {args.id}. Expected format: fn-N.M", use_json=args.json)

    flow_dir = get_flow_dir()
    task_json_path = flow_dir / TASKS_DIR / f"{args.id}.json"
    task_spec_path = flow_dir / TASKS_DIR / f"{args.id}.md"

    # Load task JSON (fail early before any writes)
    task_data = load_json_or_exit(task_json_path, f"Task {args.id}", use_json=args.json)

    # MU-2: Require in_progress status (unless --force)
    if not args.force and task_data["status"] != "in_progress":
        error_exit(
            f"Cannot complete task {args.id}: status is '{task_data['status']}', expected 'in_progress'. "
            f"Use --force to override.",
            use_json=args.json
        )

    # MU-2: Prevent cross-actor completion (unless --force)
    current_actor = get_actor()
    existing_assignee = task_data.get("assignee")
    if not args.force and existing_assignee and existing_assignee != current_actor:
        error_exit(
            f"Cannot complete task {args.id}: claimed by '{existing_assignee}'. "
            f"Use --force to override.",
            use_json=args.json
        )

    # Read summary from file
    summary = read_text_or_exit(Path(args.summary_file), "Summary file", use_json=args.json)

    # Read evidence from JSON file
    evidence_raw = read_text_or_exit(Path(args.evidence_json), "Evidence file", use_json=args.json)
    try:
        evidence = json.loads(evidence_raw)
    except json.JSONDecodeError as e:
        error_exit(f"Evidence file invalid JSON: {e}", use_json=args.json)
    if not isinstance(evidence, dict):
        error_exit("Evidence JSON must be an object with keys: commits/tests/prs", use_json=args.json)

    # Format evidence as markdown (coerce to strings, handle string-vs-array)
    def to_list(val: Any) -> list:
        if val is None:
            return []
        if isinstance(val, str):
            return [val] if val else []
        return list(val)

    evidence_md = []
    commits = [str(x) for x in to_list(evidence.get("commits"))]
    tests = [str(x) for x in to_list(evidence.get("tests"))]
    prs = [str(x) for x in to_list(evidence.get("prs"))]
    evidence_md.append(f"- Commits: {', '.join(commits)}" if commits else "- Commits:")
    evidence_md.append(f"- Tests: {', '.join(tests)}" if tests else "- Tests:")
    evidence_md.append(f"- PRs: {', '.join(prs)}" if prs else "- PRs:")
    evidence_content = "\n".join(evidence_md)

    # Read current spec
    current_spec = read_text_or_exit(task_spec_path, f"Task {args.id} spec", use_json=args.json)

    # Patch sections
    try:
        updated_spec = patch_task_section(current_spec, "## Done summary", summary)
        updated_spec = patch_task_section(updated_spec, "## Evidence", evidence_content)
    except ValueError as e:
        error_exit(str(e), use_json=args.json)

    # All validation passed - now write (spec, task)
    atomic_write(task_spec_path, updated_spec)

    task_data["status"] = "done"
    task_data["updated_at"] = now_iso()
    atomic_write_json(task_json_path, task_data)

    # NOTE: We no longer update epic timestamp on task done.
    # This reduces merge conflicts in multi-user scenarios.

    if args.json:
        json_output({
            "id": args.id,
            "status": "done",
            "message": f"Task {args.id} completed"
        })
    else:
        print(f"Task {args.id} completed")


def cmd_block(args: argparse.Namespace) -> None:
    """Block a task with a reason."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_task_id(args.id):
        error_exit(f"Invalid task ID: {args.id}. Expected format: fn-N.M", use_json=args.json)

    flow_dir = get_flow_dir()
    task_json_path = flow_dir / TASKS_DIR / f"{args.id}.json"
    task_spec_path = flow_dir / TASKS_DIR / f"{args.id}.md"

    task_data = normalize_task(
        load_json_or_exit(task_json_path, f"Task {args.id}", use_json=args.json)
    )

    if task_data["status"] == "done":
        error_exit(f"Cannot block task {args.id}: status is 'done'.", use_json=args.json)

    reason = read_text_or_exit(Path(args.reason_file), "Reason file", use_json=args.json).strip()
    if not reason:
        error_exit("Reason file is empty", use_json=args.json)

    current_spec = read_text_or_exit(task_spec_path, f"Task {args.id} spec", use_json=args.json)
    summary = get_task_section(current_spec, "## Done summary")
    if summary.strip().lower() in ["tbd", ""]:
        new_summary = f"Blocked:\n{reason}"
    else:
        new_summary = f"{summary}\n\nBlocked:\n{reason}"

    try:
        updated_spec = patch_task_section(current_spec, "## Done summary", new_summary)
    except ValueError as e:
        error_exit(str(e), use_json=args.json)

    atomic_write(task_spec_path, updated_spec)

    task_data["status"] = "blocked"
    task_data["updated_at"] = now_iso()
    atomic_write_json(task_json_path, task_data)

    if args.json:
        json_output({
            "id": args.id,
            "status": "blocked",
            "message": f"Task {args.id} blocked"
        })
    else:
        print(f"Task {args.id} blocked")


def cmd_epic_close(args: argparse.Namespace) -> None:
    """Close an epic (all tasks must be done)."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    if not is_epic_id(args.id):
        error_exit(f"Invalid epic ID: {args.id}. Expected format: fn-N", use_json=args.json)

    flow_dir = get_flow_dir()
    epic_path = flow_dir / EPICS_DIR / f"{args.id}.json"

    if not epic_path.exists():
        error_exit(f"Epic {args.id} not found", use_json=args.json)

    # Check all tasks are done
    tasks_dir = flow_dir / TASKS_DIR
    if not tasks_dir.exists():
        error_exit(f"{TASKS_DIR}/ missing. Run 'flowctl init' or fix repo state.", use_json=args.json)
    incomplete = []
    for task_file in tasks_dir.glob(f"{args.id}.*.json"):
        task_data = load_json_or_exit(task_file, f"Task {task_file.stem}", use_json=args.json)
        if task_data["status"] != "done":
            incomplete.append(f"{task_data['id']} ({task_data['status']})")

    if incomplete:
        error_exit(f"Cannot close epic: incomplete tasks - {', '.join(incomplete)}", use_json=args.json)

    epic_data = load_json_or_exit(epic_path, f"Epic {args.id}", use_json=args.json)
    epic_data["status"] = "done"
    epic_data["updated_at"] = now_iso()
    atomic_write_json(epic_path, epic_data)

    if args.json:
        json_output({
            "id": args.id,
            "status": "done",
            "message": f"Epic {args.id} closed"
        })
    else:
        print(f"Epic {args.id} closed")


def validate_flow_root(flow_dir: Path) -> list[str]:
    """Validate .flow/ root invariants. Returns list of errors."""
    errors = []

    # Check meta.json exists and is valid
    meta_path = flow_dir / META_FILE
    if not meta_path.exists():
        errors.append(f"meta.json missing: {meta_path}")
    else:
        try:
            meta = load_json(meta_path)
            if not is_supported_schema(meta.get("schema_version")):
                errors.append(
                    "schema_version unsupported in meta.json "
                    f"(expected {', '.join(map(str, SUPPORTED_SCHEMA_VERSIONS))}, got {meta.get('schema_version')})"
                )
        except json.JSONDecodeError as e:
            errors.append(f"meta.json invalid JSON: {e}")
        except Exception as e:
            errors.append(f"meta.json unreadable: {e}")

    # Check required subdirectories exist
    for subdir in [EPICS_DIR, SPECS_DIR, TASKS_DIR, MEMORY_DIR]:
        if not (flow_dir / subdir).exists():
            errors.append(f"Required directory missing: {subdir}/")

    return errors


def validate_epic(flow_dir: Path, epic_id: str, use_json: bool = True) -> tuple[list[str], list[str], int]:
    """Validate a single epic. Returns (errors, warnings, task_count)."""
    errors = []
    warnings = []

    epic_path = flow_dir / EPICS_DIR / f"{epic_id}.json"

    if not epic_path.exists():
        errors.append(f"Epic {epic_id} not found")
        return errors, warnings, 0

    epic_data = normalize_epic(
        load_json_or_exit(epic_path, f"Epic {epic_id}", use_json=use_json)
    )

    # Check epic spec exists
    epic_spec = flow_dir / SPECS_DIR / f"{epic_id}.md"
    if not epic_spec.exists():
        errors.append(f"Epic spec missing: {epic_spec}")

    # Validate epic dependencies
    deps = epic_data.get("depends_on_epics", [])
    if deps is None:
        deps = []
    if not isinstance(deps, list):
        errors.append(f"Epic {epic_id}: depends_on_epics must be a list")
    else:
        for dep in deps:
            if not isinstance(dep, str) or not is_epic_id(dep):
                errors.append(f"Epic {epic_id}: invalid depends_on_epics entry '{dep}'")
                continue
            if dep == epic_id:
                errors.append(f"Epic {epic_id}: depends_on_epics cannot include itself")
                continue
            dep_path = flow_dir / EPICS_DIR / f"{dep}.json"
            if not dep_path.exists():
                errors.append(f"Epic {epic_id}: depends_on_epics missing epic {dep}")

    # Get all tasks
    tasks_dir = flow_dir / TASKS_DIR
    tasks = {}
    if tasks_dir.exists():
        for task_file in tasks_dir.glob(f"{epic_id}.*.json"):
            task_data = normalize_task(
                load_json_or_exit(task_file, f"Task {task_file.stem}", use_json=use_json)
            )
            tasks[task_data["id"]] = task_data

    # Validate each task
    for task_id, task in tasks.items():
        # Validate status
        if task.get("status") not in TASK_STATUS:
            errors.append(f"Task {task_id}: invalid status '{task.get('status')}'")

        # Check task spec exists
        task_spec_path = flow_dir / TASKS_DIR / f"{task_id}.md"
        if not task_spec_path.exists():
            errors.append(f"Task spec missing: {task_spec_path}")
        else:
            # Validate task spec headings
            try:
                spec_content = task_spec_path.read_text(encoding="utf-8")
            except Exception as e:
                errors.append(f"Task {task_id}: spec unreadable ({e})")
                continue
            heading_errors = validate_task_spec_headings(spec_content)
            for he in heading_errors:
                errors.append(f"Task {task_id}: {he}")

        # Check dependencies exist and are within epic
        for dep in task["depends_on"]:
            if dep not in tasks:
                errors.append(f"Task {task_id}: dependency {dep} not found")
            if not dep.startswith(epic_id + "."):
                errors.append(f"Task {task_id}: dependency {dep} is outside epic {epic_id}")

    # Cycle detection using DFS
    def has_cycle(task_id: str, visited: set, rec_stack: set) -> list[str]:
        visited.add(task_id)
        rec_stack.add(task_id)

        for dep in tasks.get(task_id, {}).get("depends_on", []):
            if dep not in visited:
                cycle = has_cycle(dep, visited, rec_stack)
                if cycle:
                    return [task_id] + cycle
            elif dep in rec_stack:
                return [task_id, dep]

        rec_stack.remove(task_id)
        return []

    visited = set()
    for task_id in tasks:
        if task_id not in visited:
            cycle = has_cycle(task_id, visited, set())
            if cycle:
                errors.append(f"Dependency cycle detected: {' -> '.join(cycle)}")
                break

    # Check epic done status consistency
    if epic_data["status"] == "done":
        for task_id, task in tasks.items():
            if task["status"] != "done":
                errors.append(f"Epic marked done but task {task_id} is {task['status']}")

    return errors, warnings, len(tasks)


def cmd_prep_chat(args: argparse.Namespace) -> None:
    """Prepare JSON payload for rp-cli chat_send. Handles escaping safely."""
    # Read message from file
    message = read_text_or_exit(Path(args.message_file), "Message file", use_json=False)
    json_str = build_chat_payload(
        message=message,
        mode=args.mode,
        new_chat=args.new_chat,
        chat_name=args.chat_name,
        selected_paths=args.selected_paths,
    )

    if args.output:
        atomic_write(Path(args.output), json_str)
        print(f"Wrote {args.output}", file=sys.stderr)
    else:
        print(json_str)


def cmd_rp_windows(args: argparse.Namespace) -> None:
    result = run_rp_cli(["--raw-json", "-e", "windows"])
    raw = result.stdout or ""
    if args.json:
        windows = parse_windows(raw)
        print(json.dumps(windows))
    else:
        print(raw, end="")


def cmd_rp_pick_window(args: argparse.Namespace) -> None:
    repo_root = args.repo_root
    roots = normalize_repo_root(repo_root)
    result = run_rp_cli(["--raw-json", "-e", "windows"])
    windows = parse_windows(result.stdout or "")
    if len(windows) == 1 and not extract_root_paths(windows[0]):
        win_id = extract_window_id(windows[0])
        if win_id is None:
            error_exit("No window matches repo root", use_json=False, code=2)
        if args.json:
            print(json.dumps({"window": win_id}))
        else:
            print(win_id)
        return
    for win in windows:
        win_id = extract_window_id(win)
        if win_id is None:
            continue
        for path in extract_root_paths(win):
            if path in roots:
                if args.json:
                    print(json.dumps({"window": win_id}))
                else:
                    print(win_id)
                return
    error_exit("No window matches repo root", use_json=False, code=2)


def cmd_rp_ensure_workspace(args: argparse.Namespace) -> None:
    window = args.window
    repo_root = os.path.realpath(args.repo_root)
    ws_name = os.path.basename(repo_root)

    list_cmd = [
        "--raw-json",
        "-w",
        str(window),
        "-e",
        f"call manage_workspaces {json.dumps({'action': 'list'})}",
    ]
    list_res = run_rp_cli(list_cmd)
    try:
        data = json.loads(list_res.stdout)
    except json.JSONDecodeError as e:
        error_exit(f"workspace list JSON parse failed: {e}", use_json=False, code=2)

    def extract_names(obj: Any) -> set[str]:
        names: set[str] = set()
        if isinstance(obj, dict):
            if "workspaces" in obj:
                obj = obj["workspaces"]
            elif "result" in obj:
                obj = obj["result"]
        if isinstance(obj, list):
            for item in obj:
                if isinstance(item, str):
                    names.add(item)
                elif isinstance(item, dict):
                    for key in ("name", "workspace", "title"):
                        if key in item:
                            names.add(str(item[key]))
        return names

    names = extract_names(data)

    if ws_name not in names:
        create_cmd = [
            "-w",
            str(window),
            "-e",
            f"call manage_workspaces {json.dumps({'action': 'create', 'name': ws_name, 'folder_path': repo_root})}",
        ]
        run_rp_cli(create_cmd)

    switch_cmd = [
        "-w",
        str(window),
        "-e",
        f"call manage_workspaces {json.dumps({'action': 'switch', 'workspace': ws_name, 'window_id': window})}",
    ]
    run_rp_cli(switch_cmd)


def cmd_rp_builder(args: argparse.Namespace) -> None:
    window = args.window
    summary = args.summary
    cmd = [
        "-w",
        str(window),
        "-e",
        f"builder {json.dumps(summary)}",
    ]
    res = run_rp_cli(cmd)
    output = (res.stdout or "") + ("\n" + res.stderr if res.stderr else "")
    tab = parse_builder_tab(output)
    if args.json:
        print(json.dumps({"window": window, "tab": tab}))
    else:
        print(tab)


def cmd_rp_prompt_get(args: argparse.Namespace) -> None:
    cmd = ["-w", str(args.window), "-t", args.tab, "-e", "prompt get"]
    res = run_rp_cli(cmd)
    print(res.stdout, end="")


def cmd_rp_prompt_set(args: argparse.Namespace) -> None:
    message = read_text_or_exit(Path(args.message_file), "Message file", use_json=False)
    payload = json.dumps({"op": "set", "text": message})
    cmd = [
        "-w",
        str(args.window),
        "-t",
        args.tab,
        "-e",
        f"call prompt {payload}",
    ]
    res = run_rp_cli(cmd)
    print(res.stdout, end="")


def cmd_rp_select_get(args: argparse.Namespace) -> None:
    cmd = ["-w", str(args.window), "-t", args.tab, "-e", "select get"]
    res = run_rp_cli(cmd)
    print(res.stdout, end="")


def cmd_rp_select_add(args: argparse.Namespace) -> None:
    if not args.paths:
        error_exit("select-add requires at least one path", use_json=False, code=2)
    quoted = " ".join(shlex.quote(p) for p in args.paths)
    cmd = ["-w", str(args.window), "-t", args.tab, "-e", f"select add {quoted}"]
    res = run_rp_cli(cmd)
    print(res.stdout, end="")


def cmd_rp_chat_send(args: argparse.Namespace) -> None:
    message = read_text_or_exit(Path(args.message_file), "Message file", use_json=False)
    payload = build_chat_payload(
        message=message,
        mode="chat",
        new_chat=args.new_chat,
        chat_name=args.chat_name,
        selected_paths=args.selected_paths,
    )
    cmd = [
        "-w",
        str(args.window),
        "-t",
        args.tab,
        "-e",
        f"call chat_send {payload}",
    ]
    res = run_rp_cli(cmd)
    output = (res.stdout or "") + ("\n" + res.stderr if res.stderr else "")
    chat_id = parse_chat_id(output)
    if args.json:
        print(json.dumps({"chat": chat_id}))
    else:
        print(res.stdout, end="")


def cmd_rp_prompt_export(args: argparse.Namespace) -> None:
    cmd = [
        "-w",
        str(args.window),
        "-t",
        args.tab,
        "-e",
        f"prompt export {shlex.quote(args.out)}",
    ]
    res = run_rp_cli(cmd)
    print(res.stdout, end="")


def cmd_rp_setup_review(args: argparse.Namespace) -> None:
    """Atomic setup: pick-window + builder.

    Returns W=<window> T=<tab> on success, exits non-zero on failure.
    Writes state file for ralph-guard to verify pick-window ran.

    Note: ensure-workspace removed - if user opens RP on a folder, workspace
    already exists. pick-window matches by folder path.
    """
    import hashlib

    repo_root = os.path.realpath(args.repo_root)
    summary = args.summary

    # Step 1: pick-window
    roots = normalize_repo_root(repo_root)
    result = run_rp_cli(["--raw-json", "-e", "windows"])
    windows = parse_windows(result.stdout or "")

    win_id: Optional[int] = None

    # Single window with no root paths - use it
    if len(windows) == 1 and not extract_root_paths(windows[0]):
        win_id = extract_window_id(windows[0])

    # Otherwise match by root
    if win_id is None:
        for win in windows:
            wid = extract_window_id(win)
            if wid is None:
                continue
            for path in extract_root_paths(win):
                if path in roots:
                    win_id = wid
                    break
            if win_id is not None:
                break

    if win_id is None:
        error_exit("No RepoPrompt window matches repo root", use_json=False, code=2)

    # Write state file for ralph-guard verification
    repo_hash = hashlib.sha256(repo_root.encode()).hexdigest()[:16]
    state_file = Path(f"/tmp/.ralph-pick-window-{repo_hash}")
    state_file.write_text(f"{win_id}\n{repo_root}\n")

    # Step 2: builder
    builder_cmd = [
        "-w",
        str(win_id),
        "-e",
        f"builder {json.dumps(summary)}",
    ]
    builder_res = run_rp_cli(builder_cmd)
    output = (builder_res.stdout or "") + ("\n" + builder_res.stderr if builder_res.stderr else "")
    tab = parse_builder_tab(output)

    if not tab:
        error_exit("Builder did not return a tab id", use_json=False, code=2)

    # Output
    if args.json:
        print(json.dumps({"window": win_id, "tab": tab, "repo_root": repo_root}))
    else:
        print(f"W={win_id} T={tab}")


def cmd_validate(args: argparse.Namespace) -> None:
    """Validate epic structure or all epics."""
    if not ensure_flow_exists():
        error_exit(".flow/ does not exist. Run 'flowctl init' first.", use_json=args.json)

    # Require either --epic or --all
    if not args.epic and not getattr(args, 'all', False):
        error_exit("Must specify --epic or --all", use_json=args.json)

    flow_dir = get_flow_dir()

    # MU-3: Validate all mode
    if getattr(args, 'all', False):
        # First validate .flow/ root invariants
        root_errors = validate_flow_root(flow_dir)

        epics_dir = flow_dir / EPICS_DIR
        tasks_dir = flow_dir / TASKS_DIR

        # Find all epics (if epics dir exists)
        epic_ids = []
        if epics_dir.exists():
            for epic_file in sorted(epics_dir.glob("fn-*.json")):
                match = re.match(r"^fn-(\d+)\.json$", epic_file.name)
                if match:
                    epic_ids.append(f"fn-{match.group(1)}")

        # Start with root errors
        all_errors = list(root_errors)
        all_warnings = []
        total_tasks = 0
        epic_results = []

        for epic_id in epic_ids:
            errors, warnings, task_count = validate_epic(flow_dir, epic_id, use_json=args.json)
            all_errors.extend(errors)
            all_warnings.extend(warnings)
            total_tasks += task_count
            epic_results.append({
                "epic": epic_id,
                "valid": len(errors) == 0,
                "errors": errors,
                "warnings": warnings,
                "task_count": task_count
            })

        valid = len(all_errors) == 0

        if args.json:
            json_output({
                "valid": valid,
                "root_errors": root_errors,
                "epics": epic_results,
                "total_epics": len(epic_ids),
                "total_tasks": total_tasks,
                "total_errors": len(all_errors),
                "total_warnings": len(all_warnings)
            }, success=valid)
        else:
            print(f"Validation for all epics:")
            print(f"  Epics: {len(epic_ids)}")
            print(f"  Tasks: {total_tasks}")
            print(f"  Valid: {valid}")
            if all_errors:
                print("  Errors:")
                for e in all_errors:
                    print(f"    - {e}")
            if all_warnings:
                print("  Warnings:")
                for w in all_warnings:
                    print(f"    - {w}")

        # Exit with non-zero if validation failed
        if not valid:
            sys.exit(1)
        return

    # Single epic validation
    if not is_epic_id(args.epic):
        error_exit(f"Invalid epic ID: {args.epic}. Expected format: fn-N", use_json=args.json)

    errors, warnings, task_count = validate_epic(flow_dir, args.epic, use_json=args.json)
    valid = len(errors) == 0

    if args.json:
        json_output({
            "epic": args.epic,
            "valid": valid,
            "errors": errors,
            "warnings": warnings,
            "task_count": task_count
        }, success=valid)
    else:
        print(f"Validation for {args.epic}:")
        print(f"  Tasks: {task_count}")
        print(f"  Valid: {valid}")
        if errors:
            print("  Errors:")
            for e in errors:
                print(f"    - {e}")
        if warnings:
            print("  Warnings:")
            for w in warnings:
                print(f"    - {w}")

    # Exit with non-zero if validation failed
    if not valid:
        sys.exit(1)


# --- Main ---

def main() -> None:
    parser = argparse.ArgumentParser(
        description="flowctl - CLI for .flow/ task tracking",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # init
    p_init = subparsers.add_parser("init", help="Initialize .flow/ directory")
    p_init.add_argument("--json", action="store_true", help="JSON output")
    p_init.set_defaults(func=cmd_init)

    # detect
    p_detect = subparsers.add_parser("detect", help="Check if .flow/ exists")
    p_detect.add_argument("--json", action="store_true", help="JSON output")
    p_detect.set_defaults(func=cmd_detect)

    # epic create
    p_epic = subparsers.add_parser("epic", help="Epic commands")
    epic_sub = p_epic.add_subparsers(dest="epic_cmd", required=True)

    p_epic_create = epic_sub.add_parser("create", help="Create new epic")
    p_epic_create.add_argument("--title", required=True, help="Epic title")
    p_epic_create.add_argument("--branch", help="Branch name to store on epic")
    p_epic_create.add_argument("--json", action="store_true", help="JSON output")
    p_epic_create.set_defaults(func=cmd_epic_create)

    p_epic_set_plan = epic_sub.add_parser("set-plan", help="Set epic spec from file")
    p_epic_set_plan.add_argument("id", help="Epic ID (fn-N)")
    p_epic_set_plan.add_argument("--file", required=True, help="Markdown file")
    p_epic_set_plan.add_argument("--json", action="store_true", help="JSON output")
    p_epic_set_plan.set_defaults(func=cmd_epic_set_plan)

    p_epic_set_review = epic_sub.add_parser("set-plan-review-status", help="Set plan review status")
    p_epic_set_review.add_argument("id", help="Epic ID (fn-N)")
    p_epic_set_review.add_argument(
        "--status",
        required=True,
        choices=["ship", "needs_work", "unknown"],
        help="Plan review status"
    )
    p_epic_set_review.add_argument("--json", action="store_true", help="JSON output")
    p_epic_set_review.set_defaults(func=cmd_epic_set_plan_review_status)

    p_epic_set_branch = epic_sub.add_parser("set-branch", help="Set epic branch name")
    p_epic_set_branch.add_argument("id", help="Epic ID (fn-N)")
    p_epic_set_branch.add_argument("--branch", required=True, help="Branch name")
    p_epic_set_branch.add_argument("--json", action="store_true", help="JSON output")
    p_epic_set_branch.set_defaults(func=cmd_epic_set_branch)

    p_epic_close = epic_sub.add_parser("close", help="Close epic")
    p_epic_close.add_argument("id", help="Epic ID (fn-N)")
    p_epic_close.add_argument("--json", action="store_true", help="JSON output")
    p_epic_close.set_defaults(func=cmd_epic_close)

    # task create
    p_task = subparsers.add_parser("task", help="Task commands")
    task_sub = p_task.add_subparsers(dest="task_cmd", required=True)

    p_task_create = task_sub.add_parser("create", help="Create new task")
    p_task_create.add_argument("--epic", required=True, help="Epic ID (fn-N)")
    p_task_create.add_argument("--title", required=True, help="Task title")
    p_task_create.add_argument("--deps", help="Comma-separated dependency IDs")
    p_task_create.add_argument("--acceptance-file", help="Markdown file with acceptance criteria")
    p_task_create.add_argument("--priority", type=int, help="Priority (lower = earlier)")
    p_task_create.add_argument("--json", action="store_true", help="JSON output")
    p_task_create.set_defaults(func=cmd_task_create)

    p_task_desc = task_sub.add_parser("set-description", help="Set task description")
    p_task_desc.add_argument("id", help="Task ID (fn-N.M)")
    p_task_desc.add_argument("--file", required=True, help="Markdown file")
    p_task_desc.add_argument("--json", action="store_true", help="JSON output")
    p_task_desc.set_defaults(func=cmd_task_set_description)

    p_task_acc = task_sub.add_parser("set-acceptance", help="Set task acceptance")
    p_task_acc.add_argument("id", help="Task ID (fn-N.M)")
    p_task_acc.add_argument("--file", required=True, help="Markdown file")
    p_task_acc.add_argument("--json", action="store_true", help="JSON output")
    p_task_acc.set_defaults(func=cmd_task_set_acceptance)

    # dep add
    p_dep = subparsers.add_parser("dep", help="Dependency commands")
    dep_sub = p_dep.add_subparsers(dest="dep_cmd", required=True)

    p_dep_add = dep_sub.add_parser("add", help="Add dependency")
    p_dep_add.add_argument("task", help="Task ID (fn-N.M)")
    p_dep_add.add_argument("depends_on", help="Dependency task ID (fn-N.M)")
    p_dep_add.add_argument("--json", action="store_true", help="JSON output")
    p_dep_add.set_defaults(func=cmd_dep_add)

    # show
    p_show = subparsers.add_parser("show", help="Show epic or task")
    p_show.add_argument("id", help="Epic (fn-N) or task (fn-N.M) ID")
    p_show.add_argument("--json", action="store_true", help="JSON output")
    p_show.set_defaults(func=cmd_show)

    # epics
    p_epics = subparsers.add_parser("epics", help="List all epics")
    p_epics.add_argument("--json", action="store_true", help="JSON output")
    p_epics.set_defaults(func=cmd_epics)

    # tasks
    p_tasks = subparsers.add_parser("tasks", help="List tasks")
    p_tasks.add_argument("--epic", help="Filter by epic ID (fn-N)")
    p_tasks.add_argument("--status", choices=["todo", "in_progress", "blocked", "done"], help="Filter by status")
    p_tasks.add_argument("--json", action="store_true", help="JSON output")
    p_tasks.set_defaults(func=cmd_tasks)

    # list
    p_list = subparsers.add_parser("list", help="List all epics and tasks")
    p_list.add_argument("--json", action="store_true", help="JSON output")
    p_list.set_defaults(func=cmd_list)

    # cat
    p_cat = subparsers.add_parser("cat", help="Print spec markdown")
    p_cat.add_argument("id", help="Epic (fn-N) or task (fn-N.M) ID")
    p_cat.set_defaults(func=cmd_cat)

    # ready
    p_ready = subparsers.add_parser("ready", help="List ready tasks")
    p_ready.add_argument("--epic", required=True, help="Epic ID (fn-N)")
    p_ready.add_argument("--json", action="store_true", help="JSON output")
    p_ready.set_defaults(func=cmd_ready)

    # next
    p_next = subparsers.add_parser("next", help="Select next plan/work unit")
    p_next.add_argument("--epics-file", help="JSON file with ordered epic list")
    p_next.add_argument("--require-plan-review", action="store_true", help="Require plan review before work")
    p_next.add_argument("--json", action="store_true", help="JSON output")
    p_next.set_defaults(func=cmd_next)

    # start
    p_start = subparsers.add_parser("start", help="Start task")
    p_start.add_argument("id", help="Task ID (fn-N.M)")
    p_start.add_argument("--force", action="store_true", help="Skip status/dependency/claim checks")
    p_start.add_argument("--note", help="Claim note (e.g., reason for taking over)")
    p_start.add_argument("--json", action="store_true", help="JSON output")
    p_start.set_defaults(func=cmd_start)

    # done
    p_done = subparsers.add_parser("done", help="Complete task")
    p_done.add_argument("id", help="Task ID (fn-N.M)")
    p_done.add_argument("--summary-file", required=True, help="Done summary markdown file")
    p_done.add_argument("--evidence-json", required=True, help="Evidence JSON file")
    p_done.add_argument("--force", action="store_true", help="Skip status checks")
    p_done.add_argument("--json", action="store_true", help="JSON output")
    p_done.set_defaults(func=cmd_done)

    # block
    p_block = subparsers.add_parser("block", help="Block task with reason")
    p_block.add_argument("id", help="Task ID (fn-N.M)")
    p_block.add_argument("--reason-file", required=True, help="Markdown file with block reason")
    p_block.add_argument("--json", action="store_true", help="JSON output")
    p_block.set_defaults(func=cmd_block)

    # validate
    p_validate = subparsers.add_parser("validate", help="Validate epic or all")
    p_validate.add_argument("--epic", help="Epic ID (fn-N)")
    p_validate.add_argument("--all", action="store_true", help="Validate all epics and tasks")
    p_validate.add_argument("--json", action="store_true", help="JSON output")
    p_validate.set_defaults(func=cmd_validate)

    # prep-chat (for rp-cli chat_send JSON escaping)
    p_prep = subparsers.add_parser("prep-chat", help="Prepare JSON for rp-cli chat_send")
    p_prep.add_argument("id", nargs="?", help="(ignored) Epic/task ID for compatibility")
    p_prep.add_argument("--message-file", required=True, help="File containing message text")
    p_prep.add_argument("--mode", default="chat", choices=["chat", "ask"], help="Chat mode")
    p_prep.add_argument("--new-chat", action="store_true", help="Start new chat")
    p_prep.add_argument("--chat-name", help="Name for new chat")
    p_prep.add_argument("--selected-paths", nargs="*", help="Files to include in context")
    p_prep.add_argument("--output", "-o", help="Output file (default: stdout)")
    p_prep.set_defaults(func=cmd_prep_chat)

    # rp (RepoPrompt wrappers)
    p_rp = subparsers.add_parser("rp", help="RepoPrompt helpers")
    rp_sub = p_rp.add_subparsers(dest="rp_cmd", required=True)

    p_rp_windows = rp_sub.add_parser("windows", help="List RepoPrompt windows (raw JSON)")
    p_rp_windows.add_argument("--json", action="store_true", help="JSON output (raw)")
    p_rp_windows.set_defaults(func=cmd_rp_windows)

    p_rp_pick = rp_sub.add_parser("pick-window", help="Pick window by repo root")
    p_rp_pick.add_argument("--repo-root", required=True, help="Repo root path")
    p_rp_pick.add_argument("--json", action="store_true", help="JSON output")
    p_rp_pick.set_defaults(func=cmd_rp_pick_window)

    p_rp_ws = rp_sub.add_parser("ensure-workspace", help="Ensure workspace and switch window")
    p_rp_ws.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_ws.add_argument("--repo-root", required=True, help="Repo root path")
    p_rp_ws.set_defaults(func=cmd_rp_ensure_workspace)

    p_rp_builder = rp_sub.add_parser("builder", help="Run builder and return tab")
    p_rp_builder.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_builder.add_argument("--summary", required=True, help="Builder summary")
    p_rp_builder.add_argument("--json", action="store_true", help="JSON output")
    p_rp_builder.set_defaults(func=cmd_rp_builder)

    p_rp_prompt_get = rp_sub.add_parser("prompt-get", help="Get current prompt")
    p_rp_prompt_get.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_prompt_get.add_argument("--tab", required=True, help="Tab id or name")
    p_rp_prompt_get.set_defaults(func=cmd_rp_prompt_get)

    p_rp_prompt_set = rp_sub.add_parser("prompt-set", help="Set current prompt")
    p_rp_prompt_set.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_prompt_set.add_argument("--tab", required=True, help="Tab id or name")
    p_rp_prompt_set.add_argument("--message-file", required=True, help="Message file")
    p_rp_prompt_set.set_defaults(func=cmd_rp_prompt_set)

    p_rp_select_get = rp_sub.add_parser("select-get", help="Get selection")
    p_rp_select_get.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_select_get.add_argument("--tab", required=True, help="Tab id or name")
    p_rp_select_get.set_defaults(func=cmd_rp_select_get)

    p_rp_select_add = rp_sub.add_parser("select-add", help="Add files to selection")
    p_rp_select_add.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_select_add.add_argument("--tab", required=True, help="Tab id or name")
    p_rp_select_add.add_argument("paths", nargs="+", help="Paths to add")
    p_rp_select_add.set_defaults(func=cmd_rp_select_add)

    p_rp_chat = rp_sub.add_parser("chat-send", help="Send chat via rp-cli")
    p_rp_chat.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_chat.add_argument("--tab", required=True, help="Tab id or name")
    p_rp_chat.add_argument("--message-file", required=True, help="Message file")
    p_rp_chat.add_argument("--new-chat", action="store_true", help="Start new chat")
    p_rp_chat.add_argument("--chat-name", help="Chat name (with --new-chat)")
    p_rp_chat.add_argument("--selected-paths", nargs="*", help="Override selected paths")
    p_rp_chat.add_argument("--json", action="store_true", help="JSON output (no review text)")
    p_rp_chat.set_defaults(func=cmd_rp_chat_send)

    p_rp_export = rp_sub.add_parser("prompt-export", help="Export prompt to file")
    p_rp_export.add_argument("--window", type=int, required=True, help="Window id")
    p_rp_export.add_argument("--tab", required=True, help="Tab id or name")
    p_rp_export.add_argument("--out", required=True, help="Output file")
    p_rp_export.set_defaults(func=cmd_rp_prompt_export)

    p_rp_setup = rp_sub.add_parser("setup-review", help="Atomic: pick-window + workspace + builder")
    p_rp_setup.add_argument("--repo-root", required=True, help="Repo root path")
    p_rp_setup.add_argument("--summary", required=True, help="Builder summary")
    p_rp_setup.add_argument("--json", action="store_true", help="JSON output")
    p_rp_setup.set_defaults(func=cmd_rp_setup_review)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
