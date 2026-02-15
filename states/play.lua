local math2 = require 'lib.math2'
local mui = require 'lib.mui'
local camera = require 'camera'
local input = require 'input'

local steer = math2.steer
local setColor = love.graphics.setColor
local color = lume.color
local rectangle = love.graphics.rectangle
local remove = lume.remove
local randomchoice = lume.randomchoice

---@type State
return {
    load = function ()
        game.maze.entrances = {}
        game.maze.exits = {}
        ---@type number[]
        local idxs = {}
        for i, tile in ipairs(game.maze.tiles) do
            if tile ~= 0 then
                lume.push(idxs, i)
            end
        end
        -- set entrances
        local idx_entrance_exit = lume.filter(idxs, function(idx)
            return game.maze.tiles[idx] == 2
        end)
        for _ = 1, #game.players do
            local idx = randomchoice(idx_entrance_exit)
            remove(idxs, idx)
            remove(idx_entrance_exit, idx)
            lume.push(game.maze.entrances, idx)
        end
        -- set exits
        game.maze.exits = idx_entrance_exit
        for _, idx in ipairs(game.maze.exits) do
            remove(idxs, idx)
        end
        -- set players at random entrance positions
        for _, p in ipairs(game.players) do
            local idx = randomchoice(game.maze.entrances)
            p.pos = vec2(math2.array1d_to_array2d(idx, game.maze.width)) * game.maze.tile_size
        end
        -- set enemy/trap tiles randomly
        for _, e in ipairs(game.enemies) do
            local idx = randomchoice(idxs)
            remove(idxs, idx)
            e.pos = vec2(math2.array1d_to_array2d(idx, game.maze.width)) * game.maze.tile_size
        end
        for _ = 1, game.maze.trap_count do
            local idx = randomchoice(idxs)
            remove(idxs, idx)
            game.maze.tiles[idx] = 3
        end
    end,
    update = function (dt)
        for _, p in ipairs(game.players) do
            -- movement input
            local movex, movey = input:get 'move'
            p.move_dir:set(movex, movey)
            -- apply move_dir
            p.vel = steer(p.vel, p.move_dir, p.max_move_speed, p.mass)
            p.pos = p.pos + (p.vel * dt)
            -- set camera position
            camera.set(p.pos.x, p.pos.y)
        end
    end,
    draw = function ()
        camera.push()
        -- draw maze
        local tile_size = game.maze.tile_size
        for i, tile in ipairs(game.maze.tiles) do
            if tile > 0 then
                local ix, iy = math2.array1d_to_array2d(i, game.maze.width)
                local x, y = ix * tile_size, iy * tile_size
                local colors = {
                    mui.GREEN_100,
                    mui.BLUE_100,
                    mui.PURPLE_100,
                }
                setColor(color(colors[tile]))
                rectangle("fill", x, y, tile_size, tile_size)
            end
        end
        -- draw players
        for _, p in ipairs(game.players) do
            setColor(color(mui.GREEN_500))
            rectangle("fill", p.pos.x, p.pos.y, 32, 32)
        end
        -- draw enemies
        for _, e in ipairs(game.enemies) do
            setColor(color(mui.RED_500))
            rectangle("fill", e.pos.x, e.pos.y, 32, 32)
        end
        camera.pop()
    end
}