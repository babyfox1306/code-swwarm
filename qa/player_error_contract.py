#!/usr/bin/env python3
"""Regression contract for the exact beginner typo/error-location path."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / "python" / "worker.py"


def run(source: str) -> dict:
    with tempfile.TemporaryDirectory(prefix="codeswarm_error_") as td:
        ipc = Path(td)
        proc = subprocess.Popen(
            [sys.executable, str(WORKER), str(ipc)],
            cwd=str(ROOT),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            pid = ipc / "worker.pid"
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and not pid.exists():
                time.sleep(0.02)
            assert pid.exists(), "worker did not become ready"

            (ipc / "command.json").write_text(
                json.dumps({"fn": "run", "args": [source]}),
                encoding="utf-8",
            )
            response = ipc / "response.json"
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and not response.exists():
                time.sleep(0.02)
            assert response.exists(), "worker did not produce a response"
            return json.loads(response.read_text(encoding="utf-8"))
        finally:
            try:
                (ipc / "command.json").write_text(
                    json.dumps({"fn": "stop", "args": []}), encoding="utf-8"
                )
                proc.wait(timeout=2)
            except Exception:
                proc.kill()


def main() -> int:
    source = "# Welcome to CODE SWARM!\n\n\nmpve_to(nearest_ore())\n"
    response = run(source)
    assert response.get("type") == "error", response
    assert response.get("kind") == "NameError", response
    assert response.get("line") == 4, response
    assert "mpve_to" in response.get("message", ""), response
    print("Exact typo contract PASS:", response)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
