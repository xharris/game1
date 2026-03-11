local M = {}

-- images

M.maze_test = 'assets/maze_test.png'
M.grass = 'assets/grass.png'
M.large_tree = 'assets/large_tree.png'
M.stairs = 'assets/stairs.png'

M.hand = 'assets/hand.png'
M.hand_rows_cols = vec2(3, 1)
M.hand_frames = {
    idle = {1},
    -- TODO other frames
}

M.sword = 'assets/sword.png'
M.sword_rows_cols = vec2(8, 1)
M.sword_frames = {
    idle = {8},
    swing = {1,2,3,4,5,6,7,8},
}

M.player = 'assets/player.png'
M.player_rows_cols = vec2(7, 1)
M.player_frames = {
    idle = {1},
    hurt = {2},
    sit = {3},
    sit_sleep = {4},
    fall = {5},
    walk = {6,7},
}

M.slime = 'assets/slime.png'
M.slime_rows_cols = vec2(2, 1)
M.slime_frames = {
    neutral = {1},
    angry = {2},
}

M.dummy = 'assets/dummy2.png'
M.dummy_rows_cols = vec2(1, 1)
M.dummy_frames = {
    idle = {1},
}

-- audio

M.sword_slice = 'assets/dragon-studio-sword-slice.ogg'

-- TODO add _frames/_frame for other sprites

return M