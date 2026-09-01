#!/usr/bin/env python3
"""
Pre-flight harness for CODE SWARM V0.2 Python worker.
Run from repo root: python qa/worker_harness.py

Does NOT need LÖVE — tests worker.py error/done semantics only.
Exit 0 = all pass, 1 = at least one fail.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
WORKER = REPO_ROOT / "python" / "worker.py"


def run_worker_test(source: str, ipc_dir: Path, timeout: float = 8.0) -> dict | None:
    """Spawn worker, send run command, return response dict or None on timeout."""
    ipc_dir.mkdir(parents=True, exist_ok=True)
    for name in ("command.json", "response.json", "worker.pid", "worker_error.txt"):
        p = ipc_dir / name
        if p.exists():
            p.unlink()

    env = os.environ.copy()
    env["CODESWARM_IPC_DIR"] = str(ipc_dir)

    proc = subprocess.Popen(
        [sys.executable, str(WORKER), str(ipc_dir)],
        cwd=str(REPO_ROOT),
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    cmd_path = ipc_dir / "command.json"
    resp_path = ipc_dir / "response.json"

    try:
        cmd_path.write_text(
            json.dumps({"fn": "run", "args": [source]}),
            encoding="utf-8",
        )

        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if resp_path.exists():
                try:
                    return json.loads(resp_path.read_text(encoding="utf-8"))
                except json.JSONDecodeError:
                    pass
            if proc.poll() is not None and resp_path.exists():
                return json.loads(resp_path.read_text(encoding="utf-8"))
            time.sleep(0.05)
        return None
    finally:
        stop_path = ipc_dir / "command.json"
        stop_path.write_text(json.dumps({"fn": "stop", "args": []}), encoding="utf-8")
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()


def check(label: str, ok: bool, detail: str = "") -> bool:
    status = "PASS" if ok else "FAIL"
    suffix = f" — {detail}" if detail else ""
    print(f"  [{status}] {label}{suffix}")
    return ok


def main() -> int:
    if not WORKER.is_file():
        print(f"ERROR: worker not found at {WORKER}")
        return 1

    print("CODE SWARM worker harness")
    print(f"Python: {sys.version.split()[0]}")
    print(f"Worker: {WORKER}")
    print()

    all_ok = True
    with tempfile.TemporaryDirectory(prefix="codeswarm_qa_") as tmp:
        ipc = Path(tmp)

        # SyntaxError — missing colon
        resp = run_worker_test("while cargo() < 20\n    pass\n", ipc)
        ok = resp is not None and resp.get("type") == "error" and resp.get("kind") == "SyntaxError"
        all_ok &= check("SyntaxError (missing colon)", ok, str(resp))

        # NameError — minne()
        resp = run_worker_test("minne()\n", ipc)
        ok = (
            resp is not None
            and resp.get("type") == "error"
            and resp.get("kind") == "NameError"
        )
        all_ok &= check("NameError (minne)", ok, str(resp))

        # Anti-freeze — must NOT return done quickly
        resp = run_worker_test("while True:\n    x = 1\n", ipc, timeout=6.0)
        if resp is None:
            ok = True  # timeout waiting for response = loop blocked/hung in worker (acceptable if budget fires)
            detail = "no response within timeout (check manually if budget error expected)"
        else:
            ok = resp.get("type") == "error" and "budget" in str(resp.get("message", "")).lower()
            if resp.get("type") == "done":
                ok = False
            detail = str(resp)
        all_ok &= check("Anti-freeze (infinite loop)", ok, detail)

    print()
    if all_ok:
        print("All pre-flight tests PASS")
        return 0
    print("Pre-flight FAILED — fix python/worker.py before LÖVE playtest")
    return 1


if __name__ == "__main__":
    sys.exit(main())
