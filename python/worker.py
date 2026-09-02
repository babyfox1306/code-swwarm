"""
CODE SWARM — Python Worker
Subprocess entry point. Reads commands from file IPC and executes player code.
"""

import json
import os
import sys
import time

_script_dir = os.path.dirname(os.path.abspath(__file__))
if _script_dir not in sys.path:
    sys.path.insert(0, _script_dir)

from bootstrap import make_globals, trace_hook, reset_trace


def _get_ipc_dir():
    if len(sys.argv) > 1 and sys.argv[1].strip():
        ipc_dir = sys.argv[1].strip()
    else:
        ipc_dir = os.environ.get("CODESWARM_IPC_DIR", "")
        if not ipc_dir:
            ipc_dir = os.path.join(
                os.environ.get("TEMP", os.environ.get("TMP", "/tmp")),
                "codeswarm_ipc",
            )
    os.makedirs(ipc_dir, exist_ok=True)
    os.environ["CODESWARM_IPC_DIR"] = ipc_dir
    return ipc_dir


def _atomic_json_write(path, payload):
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
        f.flush()
        try:
            os.fsync(f.fileno())
        except OSError:
            pass
    os.replace(tmp, path)


def _read_cmd(ipc_dir):
    """Read and consume one complete command document."""
    cmd_path = os.path.join(ipc_dir, "command.json")
    try:
        with open(cmd_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, PermissionError):
        return None

    try:
        os.remove(cmd_path)
    except FileNotFoundError:
        pass
    return data


def _write_resp(ipc_dir, resp):
    _atomic_json_write(os.path.join(ipc_dir, "response.json"), resp)


def _error(ipc_dir, kind, message, line=None):
    payload = {"type": "error", "kind": kind, "message": str(message)}
    if line is not None:
        payload["line"] = line
    _write_resp(ipc_dir, payload)


def _run_source(source, ipc_dir):
    if not isinstance(source, str):
        _error(
            ipc_dir,
            "InternalError",
            "RUN protocol expected Python source text but received "
            + type(source).__name__,
        )
        return

    source = _clean_source(source)
    globals_dict = make_globals()

    try:
        code = compile(source, "<player>", "exec")
    except IndentationError as e:
        _error(ipc_dir, "IndentationError", e, e.lineno)
        return
    except SyntaxError as e:
        _error(ipc_dir, "SyntaxError", e, e.lineno)
        return

    reset_trace()
    sys.settrace(trace_hook)
    had_error = False
    try:
        exec(code, globals_dict)
    except NameError as e:
        had_error = True
        _error(ipc_dir, "NameError", e, _extract_line(e))
    except TypeError as e:
        had_error = True
        _error(ipc_dir, "TypeError", e, _extract_line(e))
    except RuntimeError as e:
        had_error = True
        _error(ipc_dir, "RuntimeError", e, _extract_line(e))
    except Exception as e:
        had_error = True
        _error(ipc_dir, type(e).__name__, e, _extract_line(e))
    finally:
        sys.settrace(None)

    if not had_error:
        _write_resp(ipc_dir, {"type": "done"})


def _extract_line(exc):
    tb = exc.__traceback__
    player_line = None
    fallback = None
    while tb is not None:
        if tb.tb_lineno:
            fallback = tb.tb_lineno
            if tb.tb_frame.f_code.co_filename == "<player>":
                player_line = tb.tb_lineno
                break
        tb = tb.tb_next
    return player_line if player_line is not None else fallback


def _clean_source(source):
    if not source:
        return source
    source = source.replace("\ufeff", "")
    for ch in ("\u200b", "\u200c", "\u200d", "\u2060"):
        source = source.replace(ch, "")
    return source


def _write_pid(ipc_dir):
    path = os.path.join(ipc_dir, "worker.pid")
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="ascii") as f:
        f.write(str(os.getpid()))
        f.flush()
    os.replace(tmp, path)


def main():
    ipc_dir = None
    try:
        ipc_dir = _get_ipc_dir()
        _write_pid(ipc_dir)
        stop = False

        while not stop:
            cmd = _read_cmd(ipc_dir)
            if cmd is None:
                time.sleep(0.02)
                continue

            if not isinstance(cmd, dict):
                _error(ipc_dir, "InternalError", "IPC command must be a JSON object")
                continue

            cmd_type = cmd.get("fn", "")
            args = cmd.get("args", [])
            if not isinstance(args, list):
                _error(
                    ipc_dir,
                    "InternalError",
                    "IPC field 'args' must be a JSON array",
                )
                continue

            if cmd_type == "run":
                source = args[0] if args else ""
                _run_source(source, ipc_dir)
            elif cmd_type in ("stop", "kill"):
                stop = True
            else:
                _error(ipc_dir, "InternalError", "Unknown command: " + str(cmd_type))

        return 0
    except Exception as e:
        if ipc_dir is None:
            ipc_dir = _get_ipc_dir()
        err_path = os.path.join(ipc_dir, "worker_error.txt")
        try:
            with open(err_path, "w", encoding="utf-8") as f:
                f.write(str(e))
        except OSError:
            pass
        raise


if __name__ == "__main__":
    raise SystemExit(main())
