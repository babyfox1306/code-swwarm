# CODE SWARM

CODE SWARM is a beginner-friendly programming game where the player writes **Python inside the game** to control a mining drone.

Current product status: **V0.2 / Mission 01 product pass — Gate 2 not complete yet.**

## Player loop

1. Read the in-game Coach.
2. Write Python in the built-in editor.
3. Press **RUN / F5**.
4. Watch the drone execute the program in the facility.
5. Understand errors and game-state feedback.
6. Fix the code and automate the mission.

Mission 01 goal: deposit **20 ore**.

## Player API

```python
move_to(target)     # target: nearest_ore() or "base"
nearest_ore()       # returns the nearest available ore target
mine()              # mine one unit while at ore
cargo()             # current cargo amount
capacity()          # drone cargo capacity
deposit()           # deposit cargo while at base
```

The player language is **Python**. Lua/LÖVE2D is the internal game engine and is not part of the learning surface.

## Development quick start

This repository is still a development build, not the final player distribution package.

```bat
run.bat
```

Development currently requires LÖVE 11.5 and either bundled Python under `vendor/python/` or a local Python 3.10+ runtime. The release target is a standalone Windows package where the player installs neither Python nor LÖVE manually.

## Controls

| Action | Keyboard |
|---|---|
| Run program | `F5` |
| Stop | `Esc` |
| Reset facility | `F8` |
| Reset code to starter | `F9` |
| API reference | `F1` |
| Fullscreen | `F11` |

## QA

GitHub Actions validates the Python worker and the production Lua JSON serializer -> Python worker IPC contract. Product Gate 2 still requires real in-game playtesting and beginner cold-start evidence.

## Design rule

UI is not considered locked until there is a **real Figma Make reference** for the required states. ASCII wireframes are planning notes only and must not be treated as Figma approval.

## License

- Game code: MIT
- Art: Robot Lab Asset Pack by Murphy's Dad — CC0 1.0
- Audio: Kenney UI Audio Pack — CC0 1.0
