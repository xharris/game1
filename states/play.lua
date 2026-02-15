local math2 = require 'lib.math2'
local mui = require 'lib.mui'
local camera = require 'camera'
local input = require 'input'
local assets = require 'assets'
local bump = require 'lib.bump'

local steer = math2.steer
local setColor = love.graphics.setColor
local color = lume.color
local rectangle = love.graphics.rectangle
local remove = lume.remove
local randomchoice = lume.randomchoice
local eq = math2.eq

local world = bump.newWorld()

---@param path string
---@param colors string[]
---@return number[] tiles, number width
local load_maze_from_img = function (path, colors)
    local data = love.image.newImageData(path)
    local tiles = {}
    local width = data:getWidth()
    -- note y comes first in iteration
    for y = 0, data:getHeight()-1 do
        for x = 0, width-1 do
            local idx = math2.array2d_to_array1d(x, y, width)
            local r,g,b,_ = data:getPixel(x, y)
            for i, color in ipairs(colors) do
                local cr,cg,cb,_ = lume.color(color)
                if eq(cr, r) and eq(cb, b) and eq(cg, g) then
                    tiles[idx] = i
                    break
                end
            end
            if not tiles[idx] then
                tiles[idx] = 0
            end
        end
    end
    return tiles, width
end

---@param idx number
---@param w number
---@param tile_size number
local tile_pos = function (idx, w, tile_size)
    return vec2(math2.array1d_to_array2d(idx, w)) * tile_size
end

---@param idx number
---@param x number
---@param y number
local get_tile_neighbor = function (idx, x, y)
    local ix, iy = math2.array1d_to_array2d(idx, game.maze.width)
    ix = ix + x
    iy = iy + y
    if ix < 1 or iy < 1 or ix > game.maze.width or iy > game.maze.width then
        return 0
    end
    local idx = math2.array2d_to_array1d(ix, iy, game.maze.width)
    return game.maze.tiles[idx] or 0
end

---@param idx number
---@param w number
---@param tile_size number
local get_tile_bbox = function (idx, w, tile_size)
    local x, y = math2.array1d_to_array2d(idx, w)
    return x * tile_size, y * tile_size, tile_size, tile_size
end

---@param name string
---@param idx number
local key = function (name, idx)
    return name..'_'..tostring(idx)
end

---@param key string
local draw_hitbox = function (key)
    if world:hasItem(key) then
        local x, y, w, h = world:getRect(key)
        setColor(color(mui.GREY_200))
        rectangle('fill', x, y, w, h)
    end
end

---@type State
return {
    load = function ()
        game.maze.tiles, game.maze.width = load_maze_from_img(
            assets.maze_test, game.maze.tile_colors
        )
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
        game.maze.entrances = {}
        for _ = 1, #game.players do
            local idx = randomchoice(idx_entrance_exit)
            remove(idxs, idx)
            remove(idx_entrance_exit, idx)
            lume.push(game.maze.entrances, idx)
        end
        if #game.maze.entrances == 0 then
            log.error("no maze entrances")
        end
        -- set exits
        game.maze.exits = idx_entrance_exit
        for _, idx in ipairs(game.maze.exits) do
            remove(idxs, idx)
        end
        -- set players at random entrance positions
        for _, p in ipairs(game.players) do
            local idx = randomchoice(game.maze.entrances)
            p.pos = tile_pos(idx, game.maze.width, game.maze.tile_size)
        end
        -- set enemy/trap tiles randomly
        for _, e in ipairs(game.enemies) do
            local idx = randomchoice(idxs)
            remove(idxs, idx)
            e.pos = tile_pos(idx, game.maze.width, game.maze.tile_size)
        end
        for _ = 1, game.maze.trap_count do
            local idx = randomchoice(idxs)
            remove(idxs, idx)
            game.maze.tiles[idx] = 3
        end
        -- add tile walls
        for i, tile in ipairs(game.maze.tiles) do
            if tile ~= 0 then
                local x, y, w, h = get_tile_bbox(i, game.maze.width, game.maze.tile_size)
                if get_tile_neighbor(i, -1, 0) == 0 then
                    -- wall left
                    world:add(key('wall_left', i), x-5, y, 5, h)
                end
                if get_tile_neighbor(i, 1, 0) == 0 then
                    -- wall right
                    world:add(key('wall_right', i), x+w, y, 5, h)
                end
                if get_tile_neighbor(i, 0, -1) == 0 then
                    -- wall top
                    world:add(key('wall_top', i), x, y-5, w, 5)
                end
                if get_tile_neighbor(i, 0, 1) == 0 then
                    -- wall bottom
                    world:add(key('wall_bottom', i), x, y+h, w, 5)
                end
            end
        end
        -- add player hitbox
        for i, p in ipairs(game.players) do
            world:add(key('player_body', i), p.pos.x, p.pos.y, 32, 16)
        end
    end,

    update = function (dt)
        for i, p in ipairs(game.players) do
            -- movement input
            local movex, movey = input:get 'move'
            p.move_dir:set(movex, movey)
            -- apply move_dir
            p.vel = steer(p.vel, p.move_dir, p.max_move_speed, p.mass)
            -- set camera position
            camera.set(p.pos.x, p.pos.y)
            -- move hitbox
            local target = p.pos + (p.vel * dt)
            local x, y, cols, len = world:move(key('player_body', i), target.x, target.y+16)
            if len > 0 then
                p.pos:set(x, y-16)
            else
                p.pos:set(target)
            end
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
        for i, p in ipairs(game.players) do
            setColor(color(mui.GREEN_500))
            rectangle("fill", p.pos.x, p.pos.y, 32, 32)
            -- draw body hitbox
            draw_hitbox(key('player_body', i))
        end
        -- draw enemies
        for _, e in ipairs(game.enemies) do
            setColor(color(mui.RED_500))
            rectangle("fill", e.pos.x, e.pos.y, 32, 32)
        end
        -- draw walls
        for i in ipairs(game.maze.tiles) do
            local keys = {
                'wall_left_'..tostring(i),
                'wall_right_'..tostring(i),
                'wall_top_'..tostring(i),
                'wall_bottom_'..tostring(i),
            }
            for _, key in ipairs(keys) do
                draw_hitbox(key)
            end
        end
        camera.pop()
    end
}