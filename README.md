# CODE SWARM

A programming game: write Lua scripts to automate drones — mine ore, return to base, deposit, repeat until WIN.

## Quick Start

```bash
# Install LÖVE 11.x from https://love2d.org/
# Then from this directory:
love .
```

## Controls

| Action | Button | Keyboard |
|--------|--------|----------|
| RUN | Click "RUN" | `F5` or `R` |
| STOP | Click "STOP" | `Escape` |
| RESET | Click "RESET" | `F8` |

## How to Play

1. Edit `player/program.lua` in your favorite text editor
2. Press **RUN** (or `F5`) to execute your script
3. Watch your drone mine ore and return to base
4. Deposit 20 ore to **WIN**
5. Press **RESET** to start over

## Player API

```lua
move_to(target)    -- move drone to "base" or an ore node
nearest_ore()      -- returns nearest ore with remaining resources
mine()             -- mine ore at current location
cargo()            -- returns current cargo count
capacity()         -- returns max cargo capacity
deposit()          -- deposit cargo at base
```

## Default Script

```lua
while true do
    while cargo() < capacity() do
        move_to(nearest_ore())
        mine()
    end
    move_to("base")
    deposit()
end
```

## License

- Game code: MIT
- Art: Robot Lab Asset Pack by Murphy's Dad — CC0 1.0
- Audio: Kenney UI Audio Pack — CC0 1.0
