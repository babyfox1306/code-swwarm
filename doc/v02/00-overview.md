# V0.2 — 00 Overview

## Một câu

Biến CODE SWARM từ **prototype kỹ thuật** thành **game dạy Python cho người mới bắt đầu** — viết, chạy, hiểu lỗi, sửa, **trong game**.

## V0.1 vs V0.2

| V0.1 (Gate 1) | V0.2 (Issue #2) |
|---------------|-----------------|
| Sửa `player/program.lua` ngoài game | Editor Python **trong game** |
| Ngôn ngữ player: Lua | Ngôn ngữ player: **Python** |
| Không hướng dẫn | **Coach** + hint 4 tầng |
| Script hoàn chỉnh sẵn | Starter **không** chứa đáp án |
| QA/dev mindset | **Zero prior programming** mindset |

## Core loop mới

```text
LEARN → WRITE PYTHON → RUN → WATCH → UNDERSTAND ERROR → FIX → RUN AGAIN → WIN
```

## Ranh giới ngôn ngữ

```text
PLAYER PYTHON (editor buffer)
        ↓
Python runtime adapter (bundled CPython)
        ↓
Game API bridge (6 functions)
        ↓
Existing Lua simulation (game/world.lua, …)
        ↓
Visible drone behavior
```

- **Lua** = engine + simulation (giữ V0.1).
- **Python** = duy nhất ngôn ngữ player trong UI V0.2.
- User **không** thấy Lua syntax trong tutorial/examples/starter.

## Nguyên tắc sản phẩm — không thương lượng

| # | Quy tắc |
|---|---------|
| 1 | **Teaching > testing** |
| 2 | **Guidance > guessing** |
| 3 | **Visible cause/effect > lectures** |
| 4 | Python **thật** — transferable syntax |
| 5 | Không **regex dịch Python → Lua** |
| 6 | RUN chạy **đúng buffer editor** |
| 7 | RESET **world only** — code giữ |
| 8 | Bundled Python — **no manual pip/venv** |
| 9 | Hint solution **cuối cùng**, không default |

## Mission 01 (duy nhất)

**Goal:** Deposit **20 ore** at base.

**Dạy tuần tự:** move → mine → loop → cargo/capacity → base → deposit → automate.

Chi tiết từng step: [07-coach-mission01.md](./07-coach-mission01.md)

## Bốn vùng UI bắt buộc

1. Mission / objective  
2. Python editor  
3. World simulation (V0.1 assets)  
4. Coach / errors / hints  

Layout: [09-layout-hud.md](./09-layout-hud.md)

## Out of scope — Issue #2

**Cấm** trước khi V0.2 DONE:

- Level 2, multiple drones, enemies, combat  
- Factory, shop, economy, tech tree, campaign map  
- Story/dialogue, multiplayer, cloud, Steam, mobile  
- Full IDE, LSP, debugger breakpoints, autocomplete engine  
- LLM/online AI tutor  
- **Lua player mode** trong beginner UI  
- **Multiple player languages**

## Definition of Done — tóm tắt

Xem checklist đầy đủ: [11-testing.md](./11-testing.md)

Ba trụ:

1. **Python runtime** — 6 API, blocking, errors, anti-freeze, bundled  
2. **In-game editor** — multiline, indent, RUN=buffer, persist  
3. **Beginner teaching** — Coach, hints, Mission 01, API reference  

## Product acceptance question

> Could a person who has never written code understand what to do, write their first Python inside CODE SWARM, see the drone react, understand a mistake, fix it, and make visible progress **without leaving the game**?

## Thứ tự implement

Issue #2 priority:

```text
P0 spike → P1 bridge → P2 editor → P3 errors → P4 coach → P5 mission → P6 save → P7 QA
```

Không viết “documentation forest” trước khi P0 chạy trên màn hình.
