local math2 = require 'lib.math2'
local mui = require 'lib.mui'
local camera = require 'camera'
local input = require 'input'
local assets = require 'assets'
local bump = require 'lib.bump'
local luastar = require 'lib.lua-star'
local tick = require 'lib.tick'
local actors = require 'actors'

local steer = math2.steer
local setColor = love.graphics.setColor
local color = lume.color
local rectangle = love.graphics.rectangle
local remove = lume.remove
local randomchoice = lume.randomchoice
local eq = math2.eq
local floor = math.floor
local find = lume.find
local TILE = game.maze.TILE
local ripairs = lume.ripairs

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
local tile_pos = function (idx)
    return vec2(math2.array1d_to_array2d(idx, game.maze.width)) * game.maze.tile_size
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

---@param ... any
local key = lume.memoize(function (...)
    local id = ''
    for _, prop in ipairs{...} do
        id = id .. '_' .. tostring(prop)
    end
    return id
end)

---@param key any
---@param c? string color
local draw_hitbox = function (key, c)
    if world:hasItem(key) then
        c = c or mui.GREEN_50
        local x, y, w, h = world:getRect(key)
        setColor(color(c))
        rectangle('line', x, y, w, h)
    end
end

local get_tile_idx = function (x, y)
    x = floor(x / game.maze.width)
    y = floor(y / game.maze.width)
    return math2.array2d_to_array1d(x, y, game.maze.width)
end

local pos_is_walkable = function (x, y)
    if x < 1 or y < 1 or x > game.maze.width or y > game.maze.width then
        return false
    end
    local idx = math2.array2d_to_array1d(x, y, game.maze.width)
    local tile = game.maze.tiles[idx]
    return tile ~= 0
end

local get_players = function ()
    return lume.filter(game.actors, function (a)
        return a.player ~= nil
    end)
end

---@param tile TILE
local get_tiles_of_type = function (tile)
    local idxs = {}
    for i, t in ipairs(game.maze.tiles) do
        if t == tile then
            lume.push(idxs, i)
        end
    end
    return idxs
end

local ticks = {}

---@param name string
---@param cd number seconds
local use_cd = function (name, cd)
    local timer = ticks[name]
    if not timer then
        -- log.debug(name, "on cooldown")
        ticks[name] = tick.delay(function ()
            -- log.debug(name, "off cooldown")
            ticks[name] = nil
        end, cd)
        return true
    end
    return false
end

---@param name string
local is_off_cd = function (name)
    return ticks[name] == nil
end

local id = 0

---@param a Actor
local add_actor = function (a)
    if not a.id then
        id = id + 1
        a.id = tostring(id)
    end
    if not lume.find(game.actors, a) then
        lume.push(game.actors, a)
    end
    -- add hitbox
    local shape = a.shape
    if shape and not world:hasItem(a) then
        world:add(a, a.pos.x + shape.pos.x, a.pos.y + shape.pos.y, shape.size.x, shape.size.y)
    end
    -- add starting tile
    a.start_tile = get_tile_idx(a.pos:unpack())
    return a
end

---@param actor Actor
local remove_actor = function (actor)
    world:remove(actor)
    remove(game.actors, actor)
end

---@param a Actor
---@param item Actor
local can_use_pick_up_item = function (a, item)
    return is_off_cd(key('pick_up_item', a.id, item.id))
end

---@param a Actor
---@param idx number
local drop_item = function (a, idx)
    local dropped = a.inventory.items[idx]
    if dropped then
        log.debug("drop item:", dropped)
        table.remove(a.inventory.items, idx)
        local item = actors.item(dropped)
        item.pos = a.pos:clone()
        add_actor(item)
    end
end

---@param a Actor
---@param item Actor
local pick_up_item = function(a, item)
    if use_cd(key('pick_up_item', a.id, item.id), 1) then
        -- drop last item in inventory if above capacity
        while #a.inventory.items >= a.inventory.capacity do
            drop_item(a, #a.inventory.items)
        end
        if #a.inventory.items < a.inventory.capacity then
            -- add item to inventory
            lume.push(a.inventory.items, item.item)
            log.debug("picked up", item.item.name..',' , #a.inventory.items, 'items')
            remove_actor(item)
            return true
        end
    end
    return false
end

---@alias WorldResponse 'slide'|'touch'|'cross'|'bounce'

local responses = {
    body = {body='slide', wall='slide', fall='cross'},
    hit = {body='cross'},
}

---@param item Actor
---@param other Actor
---@return 'slide'|'touch'|'cross'|'slide'|'bounce'|false type response type
local world_filter = function (item, other)
    local item_tag = item.shape.tag
    local other_tag = other.shape.tag

    local resp = responses[item_tag] and responses[item_tag][other_tag] or false

    if item_tag == 'hit' and other_tag == 'body' and item.owner == other.id then
        -- cant hit self
        return false
    end

    if resp then
        log.debug('response', resp)
    end

    return resp
end

---@type State
return {
    load = function ()
        camera.set_scale(2, 2)
        game.maze.tiles, game.maze.width = load_maze_from_img(
            assets.maze_test, game.maze.tile_colors
        )

        game.actors = {
            actors.player(1),
            actors.slime(),
            actors.slime(),
            actors.slime(),
            actors.slime(),
            actors.sword(),
            actors.sword(),
            actors.sword(),
            actors.sword(),
        }

        if #get_tiles_of_type(TILE.entrance) == 0 then
            log.error("no maze entrances")
        end
        -- set exits
        local exit = randomchoice(get_tiles_of_type(TILE.entrance))
        game.maze.tiles[exit] = 3
        -- setup actors
        for _, a in ipairs(game.actors) do
            if a.enemy then
                -- place enemy in random tile
                local idx = randomchoice(get_tiles_of_type(TILE.ground))
                a.pos = tile_pos(idx) + (vec2(game.maze.tile_size, game.maze.tile_size)/2)
                -- path to random player (test code)
                local player = randomchoice(get_players())
                local player_idx = get_tile_idx(player.pos.x, player.pos.y)
                local goal_x, goal_y = math2.array1d_to_array2d(player_idx, game.maze.width)
                local start_x, start_y = math2.array1d_to_array2d(idx, game.maze.width)
                local path = luastar:find(
                    game.maze.width, game.maze.width, 
                    {x=start_x, y=start_y}, {x=goal_x, y=goal_y},
                    pos_is_walkable,
                    true, true
                )
                if path then
                    a.map_path = path
                end
            end
            if a.player then
                -- place at random entrance
                local idx = randomchoice(get_tiles_of_type(TILE.entrance))
                a.pos = tile_pos(idx) + (vec2(game.maze.tile_size, game.maze.tile_size)/2)
            end
            if a.item then
                local idx = randomchoice(get_tiles_of_type(TILE.ground))
                a.pos = tile_pos(idx) + (vec2(game.maze.tile_size, game.maze.tile_size)/2)
            end
        end
        for _, a in ipairs(game.actors) do
            add_actor(a)
        end
        for _ = 1, game.maze.trap_count do
            local idx = randomchoice(get_tiles_of_type(TILE.ground))
            -- TODO place trap here
        end
        -- add tile walls
        -- TODO no walls. remove or have only some rooms with walls?
        for i, tile in ipairs(game.maze.tiles) do
            if tile ~= 0 then
                local x, y, w, h = get_tile_bbox(i, game.maze.width, game.maze.tile_size)
                if get_tile_neighbor(i, -1, 0) == 0 then
                    -- wall left
                    add_actor{
                        pos = vec2(x-5, y),
                        shape = {
                            tag = 'wall',
                            pos = vec2(),
                            size = vec2(5, h),
                        }
                    }
                end
                if get_tile_neighbor(i, 1, 0) == 0 then
                    -- wall right
                    add_actor{
                        pos = vec2(x+w, y),
                        shape = {
                            tag = 'wall',
                            pos = vec2(),
                            size = vec2(5, h),
                        }
                    }
                end
                if get_tile_neighbor(i, 0, -1) == 0 then
                    -- wall top
                    add_actor{
                        pos = vec2(x, y-5),
                        shape = {
                            tag = 'wall',
                            pos = vec2(),
                            size = vec2(w, 5),
                        }
                    }
                end
                if get_tile_neighbor(i, 0, 1) == 0 then
                    -- wall bottom
                    add_actor{
                        pos = vec2(x, y+h),
                        shape = {
                            tag = 'wall',
                            pos = vec2(),
                            size = vec2(w, 5),
                        }
                    }
                end
            end
        end
    end,

    update = function (dt)
        tick.update(dt)
        for i, a in ipairs(game.actors) do
            if a.move_dir then
                -- movement input
                local movex, movey = 0, 0
                if a.player then
                    movex, movey = input:get 'move'
                end
                a.move_dir:set(movex, movey)
                -- apply move_dir
                a.vel = steer(a.vel, a.move_dir, a.max_move_speed, a.mass or 100, dt)
            end
            if a.player then

                if a.move_dir:getmag() > 0 then
                    a.aim_dir = a.move_dir:norm()
                elseif not a.aim_dir then
                    a.aim_dir = vec2(1,0)
                end

                -- mouse aim direction
                local mx, my = love.mouse.getPosition()
                mx, my = camera.to_world(mx, my)
                a.aim_dir = (vec2(mx, my) - a.pos):norm()

                -- set camera position
                camera.set_pos(a.pos.x, a.pos.y)
                -- use item
                if a.inventory and #a.inventory.items > 0 then
                    local item = a.inventory.items[1]
                    if  input:down 'primary' and
                        item.name == 'sword' and
                        a.aim_dir and
                        use_cd(key('use_item', a.id, item.name), item.cooldown or 1)
                    then
                        -- swing sword
                        local sword_hitbox
                        tick.delay(function ()
                            -- create sword dmg+hitbox
                            -- log.debug("aim dir", a.aim_dir)
                            sword_hitbox = add_actor{
                                owner = a.id,
                                pos = a.pos + (a.aim_dir * a.range),
                                vel = a.vel,
                                dmg = 5,
                                shape = {
                                    tag = 'hit',
                                    pos=vec2(-16, -16), 
                                    size=vec2(32, 32),
                                    knockback = 300
                                },
                            }
                        end, 0.1)
                        :after(function ()
                            -- remove hitbox at 0.6 sec
                            remove_actor(sword_hitbox)
                        end, 0.1)
                    end
                end
            end
            -- move hitbox
            local target = a.pos
            if a.vel then
                target = a.pos + (a.vel * dt)
            end
            if a.shape then
                target = target + a.shape.pos
                local x, y, cols, len = world:move(a, target.x, target.y, world_filter)
                a.pos:set(x, y)
                a.pos = a.pos - a.shape.pos
                -- resolve collisions
                for i = 1, len do
                    local col = cols[i]
                    ---@type Actor
                    local other = col.other
                    if a.hp and other.dmg and other.owner ~= a.id and use_cd(key('take damage', i), 3) then
                        -- take
                        a.hp = a.hp - other.dmg
                        if a.hp <= 0 and a.player then
                            log.info("player died")
                            -- respawn at entrance
                            a.pos = tile_pos(a.start_tile) + (vec2(game.maze.tile_size, game.maze.tile_size)/2)
                            world:update(a, a.pos.x + a.shape.pos.x, a.pos.y + a.shape.pos.y)
                            a.hp = actors.HP
                        end
                        if a.hp <= 0 and a.enemy then
                            -- enemy died
                            log.info("enemy died")
                            remove_actor(a)
                        end
                    end
                    -- touch item
                    if a.inventory and other.item and can_use_pick_up_item(a, other) then
                        pick_up_item(a, other)
                    end
                    if a.shape.knockback then
                        -- apply knockback impulse along collision normal
                        local norm = (other.pos - a.pos):norm()
                        log.debug('knockback', norm * a.shape.knockback)
                        other.vel = other.vel + norm * a.shape.knockback
                    end
                end
            else
                a.pos:set(target)
            end
        end
    end,

    draw = function ()
        camera.push()
        -- draw maze
        local tile_size = game.maze.tile_size
        for i, tile in ipairs(game.maze.tiles) do
            if tile ~= TILE.none then
                local ix, iy = math2.array1d_to_array2d(i, game.maze.width)
                local x, y = ix * tile_size, iy * tile_size
                setColor(color(game.maze.tile_colors[tile]))
                rectangle("fill", x, y, tile_size, tile_size)
            end
        end
        -- draw actors
        for i, a in ipairs(game.actors) do
            local skip = false
            if a.item then
                setColor(color(mui.AMBER_500))
            elseif a.dmg then
                setColor(color(mui.RED_500))
            elseif a.player or a.enemy then
                setColor(color(mui.GREEN_500))
            else
                skip = true
            end
            if not skip then
                rectangle("fill", a.pos.x-16, a.pos.y-16, 32, 32)
                draw_hitbox(a)
                -- draw aim direction
                if a.aim_dir and a.range then
                    local aim_pos = a.pos + (a.aim_dir * a.range)
                    setColor(color(mui.RED_500))
                    rectangle("fill", aim_pos.x-6, aim_pos.y-6, 12, 12)
                end
            end
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
                draw_hitbox(key, mui.BLUE_GREY_900)
            end
        end
        camera.pop()
    end
}