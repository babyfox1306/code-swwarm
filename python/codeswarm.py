"""
CODE SWARM — Player API Module
Exactly 6 functions. Blocking RPC to Lua simulation via file IPC.

Architecture:
  - Player code calls e.g. move_to(target)
  - codeswarm.py atomically publishes api_call.json
  - Lua reads -> executes -> atomically publishes api_response.json
  - codeswarm.py blocks until the matching response appears
"""

import json
import os
import time

_call_counter = 0

API_CALL_FILE = "api_call.json"
API_RESPONSE_FILE = "api_response.json"


def _ipc_dir():
    d = os.environ.get("CODESWARM_IPC_DIR", "")
    if not d:
        d = os.path.join(
            os.environ.get("TEMP", os.environ.get("TMP", "/tmp")),
            "codeswarm_ipc",
        )
    os.makedirs(d, exist_ok=True)
    return d


def _atomic_json_write(path, payload):
    """Publish one complete JSON document; readers never see a partial file."""
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
        f.flush()
        try:
            os.fsync(f.fileno())
        except OSError:
            pass
    os.replace(tmp, path)


def _rpc(fn_name, args=None):
    global _call_counter
    _call_counter += 1
    call_id = _call_counter

    ipc_dir = _ipc_dir()
    call_path = os.path.join(ipc_dir, API_CALL_FILE)
    resp_path = os.path.join(ipc_dir, API_RESPONSE_FILE)

    _atomic_json_write(
        call_path,
        {"fn": fn_name, "args": args or [], "call_id": call_id},
    )

    timeout = 60
    start = time.monotonic()
    while time.monotonic() - start < timeout:
        try:
            with open(resp_path, "r", encoding="utf-8") as f:
                resp = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError, PermissionError):
            time.sleep(0.02)
            continue

        if resp.get("call_id") != call_id:
            # A response from an obsolete call must not block the current one.
            try:
                os.remove(resp_path)
            except FileNotFoundError:
                pass
            time.sleep(0.01)
            continue

        try:
            os.remove(resp_path)
        except FileNotFoundError:
            pass

        if "error" in resp:
            raise RuntimeError(resp["error"])
        return resp.get("result")

    raise RuntimeError("Simulation timeout — no response from game engine")


# ─── 6 Player API Functions ───

def move_to(target):
    """Send drone to a location. Blocks until arrival."""
    _rpc("move_to", [target])


def nearest_ore():
    """Return the nearest available ore target."""
    return _rpc("nearest_ore", [])


def mine():
    """Mine one unit at the current ore location."""
    _rpc("mine", [])


def cargo():
    """Return current cargo count."""
    return _rpc("cargo", [])


def capacity():
    """Return drone cargo capacity."""
    return _rpc("capacity", [])


def deposit():
    """Deposit all cargo while at base."""
    _rpc("deposit", [])
