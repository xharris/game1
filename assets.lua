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
M.sword_big_hit = 'assets/sword-big-hit.ogg'

M.audio_effects = {
    forest = {
        {
            type="reverb",volume=1,density=1,diffusion=.3,gain=.3162,highgain=.0224,
            decaytime=1.49,decayhighratio=.54,earlygain=.0525,earlydelay=.162,
            lategain=.7682,latedelay=.088,airabsorption=.9943,roomrolloff=0,highlimit=true,
        }
    },
    sword_ult_activate = {
        {type="reverb",volume=1,density=.021157024793388,diffusion=1,gain=.31768595041322,highgain=.61123966942149,decaytime=2.1015062065612,decayhighratio=1.2572727272727,earlygain=.9717652892562,earlydelay=.0055785123966942,lategain=1.1314049586777,latedelay=.076165289256198,airabsorption=.9943,roomrolloff=0,highlimit=true},
        {type="echo",volume=.2217,delay=.06997,tapdelay=.03414,damping=.1669,feedback=.2986,spread=-.01352},
        {type="distortion",volume=1,edge=.16708402152485,gain=.21281048537482,lowcut=4855.0824600151,center=17567.804423655,bandwidth=3610.6661878574},
    },
}

-- TODO add _frames/_frame for other sprites

return M