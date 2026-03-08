local M = {}

-- images

M.maze_test = 'assets/maze_test.png'
M.grass = 'assets/grass.png'
M.hand = 'assets/hand.png'
M.sword = 'assets/sword.png'
M.large_tree = 'assets/large_tree.png'
M.stairs = 'assets/stairs.png'

M.player = 'assets/player.png'
M.player_frames = vec2(7, 1)
M.player_frame = {
    idle = {1},
    hurt = {2},
    sit = {3},
    sit_sleep = {4},
    fall = {5},
    walk = {6,7},
}

M.slime = 'assets/slime.png'
M.slime_frames = vec2(2, 1)
M.slime_frame = {
    neutral = {1},
    angry = {2},
}

M.dummy = 'assets/dummy2.png'
M.dummy_frames = vec2(1, 1)
M.dummy_frame = {
    idle = {1},
}

-- audio

M.sword_slice = 'assets/dragon-studio-sword-slice.ogg'

-- TODO add _frames/_frame for other sprites

return M