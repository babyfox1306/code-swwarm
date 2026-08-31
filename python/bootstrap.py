"""
CODE SWARM — Bootstrap Module
Creates restricted globals for player code sandbox.
Only the 6 API functions + safe builtins are available.
"""

import sys

# Allowed builtins — minimal safe set for beginners
SAFE_BUILTINS = {
    "True": True,
    "False": False,
    "None": None,
    "int": int,
    "float": float,
    "str": str,
    "bool": bool,
    "range": range,
    "len": len,
    "print": print,
    "Exception": Exception,
}

# Instruction budget for anti-freeze
MAX_INSTRUCTIONS = 50000


def make_globals():
    """Build restricted global namespace for player code."""
    import codeswarm

    g = {"__builtins__": SAFE_BUILTINS}
    g["move_to"] = codeswarm.move_to
    g["nearest_ore"] = codeswarm.nearest_ore
    g["mine"] = codeswarm.mine
    g["cargo"] = codeswarm.cargo
    g["capacity"] = codeswarm.capacity
    g["deposit"] = codeswarm.deposit
    return g


def trace_hook(frame, event, arg):
    """sys.settrace callback — counts instructions, raises on budget exceeded."""
    if event == "line":
        trace_hook.ops += 1
        if trace_hook.ops > MAX_INSTRUCTIONS:
            raise RuntimeError(
                "Instruction budget exceeded — your loop may be infinite. "
                "Check: does your while condition ever become False?"
            )
    return trace_hook


trace_hook.ops = 0


def reset_trace():
    trace_hook.ops = 0
