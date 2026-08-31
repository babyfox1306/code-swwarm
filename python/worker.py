"""
CODE SWARM — Python Worker
Subprocess entry point. Reads commands from file IPC, executes player code.
"""

import os
import sys
import json
import time

# Ensure python/ dir is importable
_script_dir = os.path.dirname(os.path.abspath(__file__))
if _script_dir not in sys.path:
    sys.path.insert(0, _script_dir)

from bootstrap import make_globals, trace_hook, reset_trace, MAX_INSTRUCTIONS


def _get_ipc_dir():
    """Get IPC directory — from env or hardcoded temp path."""
    ipc_dir = os.environ.get("CODESWARM_IPC_DIR", "")
    if not ipc_dir:
        ipc_dir = os.path.join(os.environ.get("TEMP", os.environ.get("TMP", "/tmp")), "codeswarm_ipc")
    os.makedirs(ipc_dir, exist_ok=True)
    return ipc_dir


def _read_cmd(ipc_dir):
    """Read and consume a command file. Returns dict or None."""
    cmd_path = os.path.join(ipc_dir, "command.json")
    try:
        with open(cmd_path, "r") as f:
            data = json.load(f)
        os.remove(cmd_path)
        return data
    except (FileNotFoundError, json.JSONDecodeError, PermissionError):
        return None


def _write_resp(ipc_dir, resp):
    """Write a response file."""
    resp_path = os.path.join(ipc_dir, "response.json")
    with open(resp_path, "w") as f:
        json.dump(resp, f)


def _run_source(source, ipc_dir):
    """Compile and execute player source code in restricted sandbox."""
    globals_dict = make_globals()

    try:
        code = compile(source, "<player>", "exec")
    except SyntaxError as e:
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": "SyntaxError",
            "message": str(e),
            "line": e.lineno,
        })
        return

    # Arm trace hook for anti-freeze — ONLY around exec
    reset_trace()
    sys.settrace(trace_hook)
    had_error = False
    try:
        exec(code, globals_dict)
    except SyntaxError as e:
        had_error = True
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": "SyntaxError",
            "message": str(e),
            "line": e.lineno,
        })
    except IndentationError as e:
        had_error = True
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": "IndentationError",
            "message": str(e),
            "line": e.lineno,
        })
    except NameError as e:
        had_error = True
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": "NameError",
            "message": str(e),
            "line": _extract_line(e),
        })
    except TypeError as e:
        had_error = True
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": "TypeError",
            "message": str(e),
            "line": _extract_line(e),
        })
    except RuntimeError as e:
        had_error = True
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": "RuntimeError",
            "message": str(e),
            "line": _extract_line(e),
        })
    except Exception as e:
        had_error = True
        _write_resp(ipc_dir, {
            "type": "error",
            "kind": type(e).__name__,
            "message": str(e),
            "line": _extract_line(e),
        })
    finally:
        sys.settrace(None)

    if not had_error:
        _write_resp(ipc_dir, {"type": "done"})


def _extract_line(exc):
    """Extract line number from exception."""
    tb = exc.__traceback__
    if tb:
        return tb.tb_lineno
    return None


def _write_pid(ipc_dir):
    pid_path = os.path.join(ipc_dir, "worker.pid")
    with open(pid_path, "w") as f:
        f.write(str(os.getpid()))


def main():
    ipc_dir = _get_ipc_dir()
    _write_pid(ipc_dir)
    stop = False

    while not stop:
        cmd = _read_cmd(ipc_dir)
        if cmd is None:
            time.sleep(0.02)
            continue

        cmd_type = cmd.get("fn", "")
        args = cmd.get("args", [])

        if cmd_type == "run":
            source = args[0] if args else ""
            _run_source(source, ipc_dir)

        elif cmd_type == "stop":
            stop = True

        elif cmd_type == "kill":
            stop = True

        else:
            _write_resp(ipc_dir, {
                "type": "error",
                "kind": "InternalError",
                "message": "Unknown command: " + str(cmd_type),
            })

    sys.exit(0)


if __name__ == "__main__":
    main()
