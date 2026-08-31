# 08 — Assets & Audio

## Nguyên tắc

1. **Một pack chính** — coherent style, không mix 5 nguồn
2. **Local files only** — không hotlink runtime
3. **Không asset framework** — `love.graphics.newImage(path)` trực tiếp
4. **Document license** — `assets/SOURCE.md`
5. **Gameplay trước, đẹp sau** — nhưng Gate 1 phải có art thật

---

## Asset pack chính

### Robot Lab Asset Pack — Murphy's Dad

- URL: https://murphysdad.itch.io/robot-lab-asset-pack
- License: **CC0 1.0**
- Size: ~13 KB

**Có sẵn trong pack:**
- Floor + wall tiles
- Flying drone spritesheet
- Computers, robot parts, barrels (props)

### Cài đặt

```text
1. Download ZIP từ itch.io
2. Extract vào assets/vendor/robot-lab/ (giữ file gốc)
3. Copy/slice file cần dùng → assets/sprites/, assets/tiles/
4. Ghi vào assets/SOURCE.md
```

---

## Backup packs (chỉ khi thiếu)

| Pack | URL | Dùng khi |
|------|-----|----------|
| Sci-Fi RTS — Kenney | https://kenney.nl/assets/sci-fi-rts | Thiếu base/building |
| Robot Pack — Kenney | https://kenney.nl/assets/robot-pack | Drone không phù hợp |
| SciFi Dungeon — Thetra00 | https://thetra00.itch.io/scifi-dungeontileset-thretra00 | Thiếu floor tiles |

**Chỉ bổ sung 1-2 asset** — không retheme toàn game.

---

## File mapping gợi ý

| Entity | Source | Destination |
|--------|--------|-------------|
| Drone spritesheet | `vendor/robot-lab/drone*.png` | `assets/sprites/drone.png` |
| Floor tile | `vendor/robot-lab/floor*.png` | `assets/tiles/floor.png` |
| Wall (optional decor) | same pack | `assets/tiles/wall.png` |
| Base / terminal | computer sprite hoặc Kenney building | `assets/sprites/base.png` |
| Ore node | radioactive barrel recolor HOẶC custom 16×16 crystal | `assets/sprites/ore.png` |
| Ore depleted | darker variant | `assets/sprites/ore_depleted.png` |

Tên file thực tế phụ thuộc pack — **điều chỉnh sau khi download**, ghi vào SOURCE.md.

---

## `assets/SOURCE.md` template

```markdown
# Asset & Audio Sources

## Sprites — Robot Lab Asset Pack
- **Author:** Murphy's Dad
- **Source:** https://murphysdad.itch.io/robot-lab-asset-pack
- **License:** CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)
- **Files used:**
  - `assets/sprites/drone.png` — from `vendor/robot-lab/...`
  - `assets/tiles/floor.png` — from `vendor/robot-lab/...`
  - ...

## Sprites — (supplementary if any)
- ...

## Audio — Kenney Interface Sounds (example)
- **Source:** https://kenney.nl/assets/interface-sounds
- **License:** CC0
- **Files used:** ui_click.ogg, ...

## Audio — (music pack)
- ...
```

---

## Loading code pattern

### `main.lua` hoặc `game/assets.lua` (thin)

```lua
local Assets = {}

function Assets.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    Assets.sprites = {
        drone = love.graphics.newImage("assets/sprites/drone.png"),
        base  = love.graphics.newImage("assets/sprites/base.png"),
        ore   = love.graphics.newImage("assets/sprites/ore.png"),
        ore_depleted = love.graphics.newImage("assets/sprites/ore_depleted.png"),
    }
    Assets.tiles = {
        floor = love.graphics.newImage("assets/tiles/floor.png"),
    }

    -- Drone animation quads (example 16x16 frames, adjust to actual sheet)
    local sw, sh = 16, 16
    Assets.droneQuads = {}
    for i = 0, 3 do
        Assets.droneQuads[i+1] = love.graphics.newQuad(
            i * sw, 0, sw, sh,
            Assets.sprites.drone:getDimensions()
        )
    end
end

return Assets
```

### Floor tiling

```lua
function World:drawFloor()
    local tile = Assets.tiles.floor
    local tw, th = tile:getWidth(), tile:getHeight()
    for ty = 0, math.ceil(WORLD_H / th) do
        for tx = 0, math.ceil(WORLD_W / tw) do
            love.graphics.draw(tile, WORLD_X + tx * tw, WORLD_Y + ty * th)
        end
    end
end
```

### Integer scale

```lua
local SCALE = 2
love.graphics.draw(img, x, y, 0, SCALE, SCALE)
```

---

## Animation requirements

| Entity | Minimum |
|--------|---------|
| Drone | 2+ frames hover OR bob offset + move interpolation |
| Mining | Beam/particles/progress bar on ore |
| Deposit | Base pulse + particles |
| Ore | Optional shimmer; depleted sprite swap |

### Simple animation helper

```lua
function updateAnim(anim, dt)
    anim.timer = anim.timer + dt
    if anim.timer >= anim.frameTime then
        anim.timer = 0
        anim.frame = anim.frame % anim.frameCount + 1
    end
end
```

Không cần thư viện ngoài.

---

## Audio — minimum scope

### SFX list

| ID | Trigger | Suggested source |
|----|---------|------------------|
| `ui_click` | button press | Kenney Interface Sounds |
| `run_start` | RUN | sci-fi beep |
| `run_stop` | STOP | cancel buzz |
| `drone_hum` | while drone moving | loop, low |
| `mine` | mining start/loop | mechanical |
| `deposit` | deposit complete | transfer chime |
| `error` | script error | negative beep |
| `win` | WIN state | success sting |

### Music / ambience

1 looping track — industrial ambient hoặc low-key electronic.

**Sources gợi ý (CC0 / royalty-free):**
- https://kenney.nl/assets (various)
- https://opengameart.org
- https://freesound.org (check license per file)

### Thin audio wrapper

```lua
-- game/audio.lua
local Audio = { sources = {}, music = nil }

function Audio.load()
    Audio.sources.click = love.audio.newSource("assets/audio/sfx/ui_click.ogg", "static")
    Audio.music = love.audio.newSource("assets/audio/music/ambience.ogg", "stream")
    Audio.music:setLooping(true)
    Audio.music:setVolume(0.3)
end

function Audio.play(name)
    local s = Audio.sources[name]
    if s then s:clone():play() end  -- clone for overlap
end

function Audio.startMusic()
    if Audio.music then Audio.music:play() end
end
```

### Mix guidelines

| Channel | Volume |
|---------|--------|
| Music/ambience | 0.25 – 0.35 |
| SFX | 0.7 – 0.9 |
| Drone loop | 0.15 – 0.25 |

Play drone hum when `drone.state == "moving"`, stop khi idle.

---

## Ore custom sprite (nếu pack không có)

Tạo `assets/sprites/ore.png` 16×16:

- Core màu cyan glow `#58a6ff`
- Viền tối `#1f6feb`
- Export PNG — ghi trong SOURCE.md: "Custom, project original"

---

## Debug overlays (allowed)

Primitive shapes **chỉ** cho dev:

```lua
if DEBUG then
    love.graphics.circle("line", drone.x, drone.y, MINING_RANGE)
end
```

`DEBUG = false` trong release Gate 1.

---

## Checklist assets

- [ ] `assets/vendor/robot-lab/` có file gốc
- [ ] `assets/SOURCE.md` đầy đủ
- [ ] Game chạy offline sau `git clone`
- [ ] Không circle/rectangle làm art chính
- [ ] Nearest filter cho pixel art
- [ ] Mọi SFX + 1 music track có mặt
- [ ] License ghi cho audio

---

## Thời gian box

| Task | Max time gợi ý |
|------|----------------|
| Download + organize | 30 min |
| Wire sprites | 2–3 h |
| Animation/VFX | 2–3 h |
| Audio | 1–2 h |

Quá 1 ngày tìm art → dùng pack mặc định, ship.
