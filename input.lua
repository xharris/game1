local baton = require 'lib.baton'
return baton.new{
    controls = {
        join = {'mouse:1', 'button:a', 'axis:triggerright+', 'axis:triggerleft+'},
        -- move
        move_left = {'key:a', 'axis:leftx-'},
        move_right = {'key:d', 'axis:leftx+'},
        move_up = {'key:w', 'axis:lefty-'},
        move_down = {'key:s', 'axis:lefty+'},
        -- aim
        aim_left = {'key:left', 'axis:rightx-'},
        aim_right = {'key:right', 'axis:rightx+'},
        aim_up = {'key:up', 'axis:righty-'},
        aim_down = {'key:down', 'axis:righty+'},
        -- actions
        primary = {'mouse:1', 'button:rightshoulder', 'axis:triggerright+'},
        secondary = {'mouse:2'},
        -- TODO dash/roll?
        -- secondary = {'mouse:2', 'button:b'},
        next = {'mouse:2', 'button:leftshoulder', 'axis:triggerleft+'},
        start = {'button:start', 'key:return'},

        dev_kill_players = {'key:0'},
    },
    pairs = {
        move = {'move_left', 'move_right', 'move_up', 'move_down'},
        aim = {'aim_left', 'aim_right', 'aim_up', 'aim_down'},
    },
}