"""
CODE SWARM — Player API Module
Exactly 6 functions. Blocking RPC to Lua simulation via file IPC.

Architecture:
  - Player code calls e.g. move_to(target)
  - codeswarm.py writes API_CALL.json → Lua reads → executes → writes API_RESPONSE.json
  - codeswarm.py blocks until API_RESPONSE.json appears
  - Worker loop uses command.json/response.json (separate channel)

Usage (player code, auto-injected):
    move_to(nearest_ore())
    mine()
    move_to("base")
    deposit()
"""

import os
import json
import time

_call_counter = 0

# Separate file names for API calls (worker uses command.json/response.json)
API_CALL_FILE = "api_call.json"
API_RESPONSE_FILE = "api_response.json"


def _ipc_dir():
    d = os.environ.get("CODESWARM_IPC_DIR", "")
    if not d:
        d = os.path.join(os.environ.get("TEMP", os.environ.get("TMP", "/tmp")), "codeswarm_ipc")
    return d


def _rpc(fn_name, args=None):
    """Send API call to Lua simulation, block until response."""
    global _call_counter
    _call_counter += 1
    call_id = _call_counter

    ipc_dir = _ipc_dir()
    call_path = os.path.join(ipc_dir, API_CALL_FILE)
    resp_path = os.path.join(ipc_dir, API_RESPONSE_FILE)

    # Write API call
    cmd = {"fn": fn_name, "args": args or [], "call_id": call_id}
    with open(call_path, "w") as f:
        json.dump(cmd, f)

    # Block-read response
    timeout = 60  # seconds
    start = time.time()
    while time.time() - start < timeout:
        try:
            with open(resp_path, "r") as f:
                resp = json.load(f)
            if resp.get("call_id") == call_id:
                os.remove(resp_path)
                if "error" in resp:
                    raise RuntimeError(resp["error"])
                return resp.get("result")
        except (FileNotFoundError, json.JSONDecodeError):
            pass
        time.sleep(0.02)  # 20ms poll

    raise RuntimeError("Simulation timeout — no response from game engine")


# ─── 6 Player API Functions ───

def move_to(target):
    """Send drone to a location. Blocks until arrival.

    Args:
        target: Use nearest_ore() or "base"
    """
    _rpc("move_to", [target])


def nearest_ore():
    """Find closest ore patch.

    Returns:
        str — target id for move_to()
    """
    return _rpc("nearest_ore", [])


def mine():
    """Mine ore at current location. Blocks until one mine action completes.

    Raises:
        RuntimeError: if not on ore or cargo full
    """
    _rpc("mine", [])


def cargo():
    """Current ore count in drone.

    Returns:
        int — 0 .. capacity()
    """
    return _rpc("cargo", [])


def capacity():
    """Maximum ore drone can hold.

    Returns:
        int — 5 for Mission 01
    """
    return _rpc("capacity", [])


def deposit():
    """Deposit all cargo at base. Blocks until complete.

    Raises:
        RuntimeError: if not at base or cargo empty
    """
    _rpc("deposit", [])
