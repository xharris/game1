local M = {}

M.maze_test = 'assets/maze_test.png'
M.grass = 'assets/grass.png'
M.hand = 'assets/hand.png'
M.sword = 'assets/sword.png'
M.large_tree = 'assets/large_tree.png'

M.player = 'assets/player.png'
M.player_frames = vec2(6, 1)
M.player_frame = {
    idle = {1},
    hurt = {2},
    sit = {3},
    fall = {4},
    walk = {5,6},
}

return M