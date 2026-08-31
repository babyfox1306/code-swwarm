local C = {}

-- Win condition
C.WIN_ORE_TARGET = 20

-- Drone
C.DRONE_SPEED = 120
C.CARGO_CAPACITY = 5
C.DRONE_START_X = 80
C.DRONE_START_Y = 200

-- Ranges (pixels)
C.ARRIVAL_DISTANCE = 8
C.MINING_RANGE = 24
C.BASE_RANGE = 48

-- Action durations (seconds)
C.MINE_DURATION = 1.5
C.DEPOSIT_DURATION = 0.6

-- Ore
C.ORE_PER_MINE = 1
C.ORE_INITIAL_AMOUNT = 10

C.ORE_POSITIONS = {
    { id = 1, x = 400, y = 80  },
    { id = 2, x = 650, y = 200 },
    { id = 3, x = 400, y = 320 },
}

-- Base
C.BASE_X = 80
C.BASE_Y = 200

-- World viewport
C.WORLD_X = 80
C.WORLD_Y = 80
C.WORLD_W = 800
C.WORLD_H = 400

-- Script runner
C.INSTRUCTION_BUDGET = 50000
C.HOOK_INSTRUCTION_INTERVAL = 1000

-- Visual
C.SPRITE_SCALE = 2

-- Animation
C.DRONE_BOB_SPEED = 4
C.DRONE_BOB_AMPLITUDE = 2
C.DRONE_ANIM_FRAME_TIME = 0.15

-- Audio volumes
C.VOL_MUSIC = 0.3
C.VOL_SFX = 0.8
C.VOL_DRONE_LOOP = 0.2

-- Debug
C.DEBUG = false

return C
