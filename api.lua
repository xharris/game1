local math2 = require 'lib.math2'
local mui = require 'lib.mui'
local camera = require 'camera'
local input = require 'input'
local assets = require 'assets'
local bump = require 'lib.bump'
local luastar = require 'lib.lua-star'
local tick = require 'lib.tick'
local actors = require 'actors'
local light = require 'light'
local hitbox = require 'hitbox'
local status_effects = require 'status_effects'
local filters = require 'actor_filters'
local audio = require 'audio'
local scenarios = require 'scenarios'

local render_level_cell = require 'render.level_cell'
local render_sprite = require 'render.sprite'
local render_hands = require 'render.hands'

local steer = math2.steer
local setColor = love.graphics.setColor
local color = lume.color
local rectangle = love.graphics.rectangle
local remove = lume.remove
local randomchoice = lume.randomchoice
local eq = math2.eq
local floor = math.floor
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop
local clamp = lume.clamp
local abs = math.abs
local sign = lume.sign
local rad = math.rad
local max = math.max
local transform = math2.transform
local circle = love.graphics.circle
local blend = math2.blend
local line = love.graphics.line

local world = bump.newWorld()

---@param idx number
local cell_pos = function (idx)
    return vec2(math2.array1d_to_array2d(idx, game.LEVEL_CELL_SIZE.x)) * game.LEVEL_TILE_SIZE
end


local id = 0
---@type table<Group, Actor[]>
local actor_groups = {}

---@type table<Faction, Actor[]>
local actor_factions = {}

---@param group Group
local get_group = function (group)
    return actor_groups[group] or {}
end

---@param faction Faction
local get_faction = function (faction)
    return actor_factions[faction] or {}
end

---@param level_idx number
---@param cell_idx number
local get_level_cell = function(level_idx, cell_idx)
    for _, tile in ipairs(get_group('level_cell')) do
        if tile.level_cell and tile.level_cell.level == level_idx and tile.level_cell.index == cell_idx then
            return tile
        end
    end
end

---@param ... any
local key = lume.memoize(function (...)
    local id = {}
    for _, prop in ipairs{...} do
        lume.push(id, tostring(prop))
    end
    return table.concat(id, '_')
end)

---@param a Actor
---@param c? string color
local draw_hitbox = function (a, c)
    if world:hasItem(a) then
        c = c or mui.GREEN_50
        local x, y, w, h = world:getRect(a)
        setColor(color(c))
        rectangle('line', x, y, w, h)
    end
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

---@param a Actor
local remove_actor = function (a)
    world:remove(a)
    remove(game.actors, a)
    -- remove from group
    if a.group and actor_groups[a.group] then
        remove(actor_groups[a.group], a)
    end
    -- remove from faction
    if a.faction and actor_factions[a.faction] then
        remove(actor_factions[a.faction], a)
    end
end

---@param a Actor
local add_actor = function (a)
    if not a.id then
        id = id + 1
        a.id = tostring(id)
    end
    if not a.name then
        a.name = 'ENT#'..tostring(a.id)
    end
    a.z = a.z or 0
    if not lume.find(game.actors, a) then
        lume.push(game.actors, a)
    end
    if not a.group then
        a.group = 'entity'
    end
    -- add to group
    if a.group and not actor_groups[a.group] then
        actor_groups[a.group] = {}
    end
    if a.group then
        lume.push(actor_groups[a.group], a)
    end
    -- add hitbox
    local shape = a.shape
    if shape and not world:hasItem(a) then
        world:add(a, a.pos.x + shape.pos.x, a.pos.y + shape.pos.y, shape.size.x, shape.size.y)
    end
    -- add lighting
    if a.light then
        light.add_light(a, {radius=a.light.radius})
    end
    -- add to faction
    if a.faction then
        if not actor_factions[a.faction] then
            actor_factions[a.faction] = {}
        end
        lume.push(actor_factions[a.faction], a)
    end
    -- set alt
    if not a.alt then
        if #game.levels > 0 then
            a.alt = game.levels[#game.levels].alt
        else
            a.alt = 0
        end
    end
    if a.remove_after then
        tick.delay(function ()
            remove_actor(a)
        end, a.remove_after)
    end
    return a
end

---@param a Actor
---@param immediate? boolean
local camera_follow = function (a, immediate)
    local cam_follow = a.cam_follow
    if not cam_follow or not a.pos then
        return
    end
    if immediate then
        camera.position_smoothing = nil
    end
    local pos = a.pos:clone()
    if a.alt then
        pos.y = pos.y - a.alt
    end
    if cam_follow.move_dir_offset and a.move_dir and a.max_move_speed then
        pos = pos + (a.move_dir * (a.max_move_speed / 2))
    end
    if cam_follow.aim_dir_offset and a.aim_dir then
        pos = pos + (a.aim_dir * 30)
    end
    camera.set_pos(pos.x, pos.y)
    if immediate then
        camera.position_smoothing = game.CAMERA_SMOOTH
    end
end

local cell_size = lume.memoize(function ()
    return vec2(
        game.LEVEL_TILE_SIZE.x * game.LEVEL_CELL_SIZE.x,
        game.LEVEL_TILE_SIZE.y * game.LEVEL_CELL_SIZE.y
    )
end)

---@param cells Actor[]
---@param a Actor
---@param idx number
local place_at_level_cell = function (cells, a, idx)
    local cell = cells[idx] or nil
    if cell then
        local offset = cell_size() / 2
        if a.item then
            offset = vec2(
                love.math.random(30, cell_size().x - 60),
                love.math.random(30, cell_size().y - 60)
            )
        end
        a.pos = cell.pos + offset
        a.alt = cell.alt
        a.alt_v = 0
        camera_follow(a, true)
        world:update(a, a.pos.x + a.shape.pos.x, a.pos.y + a.shape.pos.y)
    else
        log.warn("no start tile found", a)
    end
end

---@class ItemModule
---@field item fun():Item
---@field hold_in_hand? boolean
---@field sprite? fun():Sprite
---@field equip? fun(a:Actor, item:Item)
---@field activate? fun(a:Actor, item:Item, hand?:Hand)
---@field drop? fun(a:Actor, item:Item) TODO fly in an arc away from player

local load_item = function (name)
    ---@type ItemModule
    return require('items.'..name)
end

---@param a Actor
---@param idx number
local drop_item = function (a, idx)
    local dropped = a.inventory.items[idx]
    if dropped then
        log.debug("drop item:", dropped)
        table.remove(a.inventory.items, idx)
        local item_module = load_item(dropped.name)
        local item = actors.item(dropped, item_module.sprite())
        item.pos = a.pos:clone()
        item.alt = a.alt
        add_actor(item)
    end
end

---@param a Actor
---@param item Item
local equip_item = function (a, item)
    if item.equipped then
        return
    end
    log.info('equip', item.name)
    local item_module = load_item(item.name)
    item.equipped = true
    -- equip event
    if item_module.equip then
        item_module.equip(a, item)
    end
    -- show in hand?
    if item_module.hold_in_hand and a.hands.right then
        a.hands.right.item = item_module.sprite()
    end
    events.item.equipped.emit(a, item)
end

---@param a Actor
---@param item Item
local add_to_inventory = function (a, item)
    -- drop last item in inventory if above capacity
    while #a.inventory.items >= a.inventory.capacity do
        drop_item(a, #a.inventory.items)
    end
    if #a.inventory.items < a.inventory.capacity then
        -- add item to inventory
        lume.push(a.inventory.items, item)
        log.debug("add", item.name..', inventory:' , #a.inventory.items, 'items')
        -- call 'equip'
        if #a.inventory.items == 1 then
            equip_item(a, item)
        end
        return true
    end
end

---@param a Actor
---@param item Actor
local pick_up_item = function(a, item)
    log.debug('pick up item')
    if use_cd(key('pick_up_item', a.id), 2) and add_to_inventory(a, item.item) then
        remove_actor(item)
        return true
    end
    return false
end

---@param pos Vector.lua
---@param alt number
---@return Actor? cell, number? cell_index, number? level_idx
local get_map_pos = function (pos, alt)
    for l, level in ipairs(game.levels) do
        if level.alt == alt then
            -- check tiles in this level
            for t, cell in ipairs(get_group('level_cell')) do
                local size = vec2(
                    game.LEVEL_TILE_SIZE.x * game.LEVEL_CELL_SIZE.x,
                    game.LEVEL_TILE_SIZE.y * game.LEVEL_CELL_SIZE.y
                )
                if cell.level_cell and
                    pos.x >= cell.pos.x and
                    pos.y >= cell.pos.y and
                    pos.x <= cell.pos.x + size.x and
                    pos.y <= cell.pos.y + size.y
                then
                    return cell, t, l
                end
            end
        end
    end
    log.warn("could not find map pos at pos", pos, "alt", alt)
end
-- {x:684.06803259956,y:-1200} alt 600

---@param a Actor
---@param b Actor
---@param threshold? number if provided, allows a.alt to be within `threshold` above b.alt
local is_same_alt = function (a, b, threshold)
    if not a.alt and not b.alt then return true end
    if (a.alt == nil) ~= (b.alt == nil) then return false end
    if threshold then
        return a.alt >= b.alt and a.alt - b.alt <= threshold
    end
    return a.alt == b.alt
end

---@alias WorldResponse 'slide'|'touch'|'cross'|'bounce'

local responses = {
    body = {body='slide', wall='slide', fall='cross', area='cross', ground='cross'},
    hit = {body='cross', hit='cross'},
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

    if item_tag == 'hit' and other_tag == 'hit' and item.owner == other.owner then
        -- cant hit related hitboxes
        return false
    end

    if not is_same_alt(item, other) then
        -- different elevation
        return false
    end

    return resp
end

---@param item Actor
local line_of_sight_filter = function (item)
    return item.shape.tag == 'wall'
end

---@param a Actor
---@param pos Vector.lua
local has_line_of_sight = function (a, pos)
    local _, len = world:querySegment(a.pos.x, a.pos.y, pos.x, pos.y, line_of_sight_filter)
    return len == 0
end

---@param _ Actor
local get_level_tile_canvas = lume.memoize(function (_)
    return love.graphics.newCanvas()
end)

---@param level number
local get_level_cells = function (level)
    local cells = get_group('level_cell')
    return lume.filter(cells, function (t)
        return t.level_cell.level == level
    end)
end

---@param level number
local get_level_alt = function (level)
    return level * game.LEVEL_ALT
end

---@param level_idx number
---@param a Actor
---@param cell_filters? ActorFilter[] for cell placement
local enter_level = function (level_idx, a, cell_filters)
    local level = game.levels[level_idx]
    local cells = get_level_cells(level_idx)
    if not level or #cells == 0 then
        log.warn("invalid level", level_idx, "level", level, "cells", #cells)
        return
    end
    if not a.start_level then
        a.start_level = level_idx
    end
    local place = false
    if not a.start_cell then
        a.start_cell = {}
    end
    if not a.start_cell[level_idx] then
        if a.enemy then
            -- place enemy in random cell
            a.start_cell[level_idx] = filters.randomchoice(cells, 
                cell_filters or {filters.cell_of_type(game.CELL.ground)}
            ).level_cell.index
            
            place = true
        end
        if a.player then
            -- place at random entrance
            a.start_cell[level_idx] = filters.randomchoice(cells, 
                cell_filters or { filters.cell_of_type(game.CELL.entrance) }).level_cell.index
            place = true
            -- set audio effects for level theme
            audio.set_global_effects{'theme_'..level.theme}
        end
        if a.item then
            a.start_cell[level_idx] = filters.randomchoice(cells, 
                cell_filters or {filters.cell_of_type(game.CELL.ground)}
            ).level_cell.index
            place = true
        end
    else
        place = true
    end
    if place and a.start_cell[level_idx] then
        log.debug('place', a.name, 'at', a.start_cell[level_idx])
        place_at_level_cell(cells, a, a.start_cell[level_idx])
    end
    
    a.alt = level.alt
end

---Get Actor's current level based on `alt`
---@param a Actor
---@return Level? level, number level_index
local get_current_level = function(a)
    ---@type Level?
    local nearest_level
    local level_idx = 0
    if not a.alt then
        return nil, 0
    end
    for i, level in ipairs(game.levels) do
        if a.alt <= level.alt and (not nearest_level or level.alt < nearest_level.alt) then
            nearest_level = level
            level_idx = i
        end
    end
    return nearest_level, level_idx
end

---@param a Actor
---@param cell cell_type
---@param dist number
local near_cell_type = function (a, cell, dist)
    local a_cell = get_map_pos(a.pos, a.alt)
    if not a_cell then
        return filters.noop()
    end
    local level = game.levels[a.current_level]
    local a_pos = vec2(math2.array1d_to_array2d(a_cell.level_cell.index, level.width))

    ---@type ActorFilter
    return function (a2)
        if not a2.level_cell or a2.level_cell.type ~= cell or a2.level_cell.level ~= a.current_level then
            return false
        end
        local cell_pos = vec2(math2.array1d_to_array2d(a2.level_cell.index, level.width))
        return cell_pos:dist(a_pos) <= dist
    end
end

---@param next_level NextLevel
---@return number idx, Level level
local add_level = function (next_level)
    local theme, cells, width = next_level.theme, next_level.cells, next_level.width

    local level_idx = #game.levels + 1
    local alt = get_level_alt(level_idx)
    log.debug("add level", level_idx, "alt", alt)
    local ox, oy = -floor(width/2), -floor(width/2)
    ---@type Level
    local level = {
        alt = alt,
        theme = theme,
        width = width,
    }
    lume.push(game.levels, level)
    -- create level cells
    ---@type Actor[]
    local level_cells = {}
    for i, cell in ipairs(cells) do
        local ix, iy = math2.array1d_to_array2d(i, width)
        -- add level tile
        local level_cell = add_actor{
            name = 'LEVEL_CELL',
            group = 'level_cell',
            pos = vec2(ix+ox, iy+oy) * cell_size(),
            level_cell = {
                level = level_idx,
                type = cell,
                index = i,
            },
            size = cell_size(),
            shape = cell ~= game.CELL.none and {
                tag = 'ground',
                pos = vec2(0, 0),
                size = cell_size(),
            } or nil,
            alt = alt,
            z = -100,
            y_sort = true,
            current_level = level_idx,
        }
        lume.push(level_cells, level_cell)
    end

    for _, name in ipairs(next_level.scenarios) do
        ---@type Scenario?
        local s = scenarios[name]
        if s then
            s(level_idx, next_level)
        else
            log.warn('missing scenario', name)
        end
    end

    events.level.added.emit(level_idx, level)
    return level_idx, level
end

-- convert between world space and luastar grid space (0-based, always positive)
---@param world Vector.lua
---@param level_idx number
local to_grid = function (world, level_idx)
    local level = game.levels[level_idx]
    local ox = -floor(level.width / 2)
    local min_world = vec2(ox * cell_size().x, ox * cell_size().y)
    local step = game.LEVEL_TILE_SIZE:clone()
    return vec2(
        floor((world.x - min_world.x) / step.x),
        floor((world.y - min_world.y) / step.y)
    )
end

---@param grid Vector.lua
---@param level_idx number
local to_world = function (grid, level_idx)
    local level = game.levels[level_idx]
    local tile_size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE
    local ox = -floor(level.width / 2)
    local min_world = vec2(ox * tile_size.x, ox * tile_size.y)
    local step = game.LEVEL_TILE_SIZE:clone()
    return vec2(grid.x * step.x + min_world.x, grid.y * step.y + min_world.y)
end

local all_walkable = {}

---@param level_idx number
local update_walkable = function (level_idx)
    local step = game.LEVEL_TILE_SIZE:clone()
    local tiles_x = cell_size().x / step.x  -- tiles per cell
    local tiles_y = cell_size().y / step.y
    local walkable = {}
    for _, a in ipairs(get_group('level_cell')) do
        if a.level_cell.level == level_idx and a.level_cell.type ~= game.CELL.none then
            local g = to_grid(a.pos, level_idx)
            for dy = 0, tiles_y - 1 do
                local row = g.y + dy
                if not walkable[row] then walkable[row] = {} end
                for dx = 0, tiles_x - 1 do
                    walkable[row][g.x + dx] = true
                end
            end
        end
    end
    all_walkable[level_idx] = walkable
end

---@param a Actor
---@param b Vector.lua
---@return Vector.lua[]?
local get_pathing = function (a, b)
    if not a.current_level then
        log.warn('a missing current_level', a)
        return nil
    end

    local level = game.levels[a.current_level]
    local map_size = level.width * cell_size()
    -- break up map into grid of size `step`
    local step = game.LEVEL_TILE_SIZE:clone()

    local walkable = all_walkable[a.current_level]
    if not walkable then
        return nil
    end

    local pos_is_walkable = function (x, y)
        return walkable[y] ~= nil and walkable[y][x] == true
    end

    local start = to_grid(a.pos, a.current_level)
    local goal = to_grid(b, a.current_level)

    local path = luastar:find(
        map_size.x / step.x, map_size.y / step.y,
        start, goal,
        pos_is_walkable,
        true, true
    )
    if path then
        for i, p in ipairs(path) do
            -- convert back to world space (center of cell)
            path[i] = to_world(p, a.current_level) + step / 2
        end
        return path
    end
end

local xform = love.math.newTransform()

---@param a Actor
local get_z = function (a)
    if a.y_sort then
        return a.pos.y + (a.z or 0) - (a.alt or 0)
    end
    return (a.z or 0)
end

---@type table<string, number>
local last_z = {}

---@param a Actor
---@param b Actor
---@return boolean
local sort_by_z = function (a, b)
    return get_z(a) < get_z(b)
end

---@type table<string, table<number, love.Canvas>>
local level_canvas = {}

local renderers = {
    render_level_cell.draw,
    lume.fn(render_hands.draw, render_hands.LAYER.back_1),
    lume.fn(render_hands.draw, render_hands.LAYER.back_2),
    render_sprite.draw,
    lume.fn(render_hands.draw, render_hands.LAYER.front_1),
    lume.fn(render_hands.draw, render_hands.LAYER.front_2),
    hitbox.draw,
}

---@param a Actor
---@param alt? number
local draw_actor = function (a, alt)
    alt = alt or a.alt or 0
    local pop = transform(
        a.pos.x, a.pos.y - alt,
        0, a.scale and a.scale.x or 1, a.scale and a.scale.y or 1,
        0, 0
    )
    setColor(1,1,1,a.alpha or 1)
    for _, renderer in ipairs(renderers) do
        push()
        renderer(a)
        pop()
    end
    pop()
    if game.DRAW_Z_ORDER then
        -- draw z order
        pop = transform(
            a.pos.x, get_z(a),
            0, a.scale and a.scale.x or 1, a.scale and a.scale.y or 1,
            0, 0
        )
        setColor(0,0,1,1)
        rectangle("fill", -2, -2, 4, 4)
        pop()
    end
    if game.DRAW_AIM_POSITION and a.aim_position then
        -- aim position
        pop = transform(a.aim_position.x, a.aim_position.y, 0, 1, 1, 0, 0)
        setColor(0,0,1,1)
        circle('fill', 0, 0, 12)
        pop()
    end
    -- aim dir
    if game.DRAW_AIM_POSITION and a.aim_dir then
        pop = transform(a.pos.x + a.aim_dir.x * 30, a.pos.y - alt + a.aim_dir.y * 30,
            0, a.scale and a.scale.x or 1, a.scale and a.scale.y or 1,
            0, 0)
        setColor(0,0,0.8,1)
        circle('fill', 0, 0, 8)
        pop()
    end
end

local update = function (dt)
    love.audio.setVolume(game.VOLUME.global)

    local need_sort = false
    for _, a in ipairs(game.actors) do
        local delta_mod = a._delta_mod or 1
        a._delta_mod = blend(delta_mod, a.delta_mod or 1, 0.5)

        dt = dt * delta_mod
        if a.player and a.pos then
            -- set camera position
            local pos = a.pos
            if a.move_dir then
                pos = pos + (a.move_dir * 60)
            end
            if a.aim_dir then
                pos = pos + (a.aim_dir * 30)
            end
        end
        camera_follow(a)
        if a.move_dir then
            -- movement input
            local movex, movey = a.move_dir.x, a.move_dir.y
            if a.player then
                movex, movey = input:get 'move'
            end
            a.move_dir:set(movex, movey)
            -- apply move_dir
            a.vel = steer(a.vel, a.move_dir, a.max_move_speed, a.mass or 100, dt)
        end
        -- face direction
        if a.aim_dir and a.aim_dir:getmag() > 0 and a.scale then
            a.scale.x = sign(a.aim_dir.x) * abs(a.scale.x)
        end
        -- move arm in aim direction if holding an item
        if a.aim_dir and a.hands and a.hands.right.item then
            if a.aim_dir.x < 0 then
                a.hands.right.arm_r = a.aim_dir:heading() + rad(180)
            else
                a.hands.right.arm_r = -a.aim_dir:heading()
            end
        end
        if a.player then
            -- mouse aim direction
            local inside, mx, my = shove.mouseToViewport()
            local wx, wy = camera.to_world(mx, my)
            local aim_pos = vec2(wx, wy)

            if not a.disable_aim and inside then
                if not a.aim_position then
                    a.aim_position = aim_pos
                else
                    a.aim_position.x = blend(a.aim_position.x, aim_pos.x, dt * 4)
                    a.aim_position.y = blend(a.aim_position.y, aim_pos.y, dt * 4)
                end

                local alt_pos = vec2(a.pos.x, a.pos.y - (a.alt or 0))
                a.aim_dir = (a.aim_position - alt_pos):norm()
            end

            -- use item
            if a.inventory and #a.inventory.items > 0 then
                local item = a.inventory.items[1]
                local item_module = load_item(item.name)
                if item_module and input:down 'primary' and use_cd(key('use_item', a.id, item.name), item.cooldown or 1) then
                    item_module.activate(a, item, a.hands and a.hands.right or nil)
                end
            end
        end

        if not a.disable_aim and not a.aim_dir and a.move_dir and a.move_dir:getmag() > 0 then
            a.aim_dir = a.move_dir:norm()
        end

        local target = a.pos
        if a.alt and a.move_dir then
            -- floor/gravity
            local gravity_step = 9.8
            ---@type Actor[], number
            local floors, floor_len = world:queryPoint(a.pos.x, a.pos.y, 
            ---@param item Actor
            function (item)
                return item.shape.tag == 'ground' and is_same_alt(a, item, gravity_step + 1)
            end)
            local on_floor = floor_len > 0
            if on_floor then
                -- snap to floor
                a.alt = floors[1].alt
                a.alt_v = 0
            elseif a.alt then
                -- apply gravity
                a.alt_v = (a.alt_v or 0) - gravity_step
                a.alt = a.alt + a.alt_v * dt
            end
            -- there is a ground 0 floor
            a.alt = max(0, a.alt)
            if a.alt_0_walkable and a.alt <= 0 then
                a.alt_v = 0
            end
        end
        if a.alt and a.alt < get_level_alt(0) then
            -- out of bounds
            if a.start_level then
                log.debug("out of bounds, respawn at start")
                enter_level(a.start_level, a)
            else
                log.debug("out of bounds, remove actor", a)
                remove_actor(a)
            end
        end

        -- update other components
        status_effects.update(dt, a)
        local players = get_group('player')
        render_level_cell.update(dt, a, players)

        if a.vel then
            -- apply velocity
            target = a.pos + (a.vel * dt)
        end
        if a.shape then
            -- move hitbox
            target = target + a.shape.pos
            local x, y, cols, len = world:move(a, target.x, target.y, world_filter)
            a.pos:set(x, y)
            a.pos = a.pos - a.shape.pos
            -- resolve collisions
            for i = 1, len do
                local col = cols[i]
                ---@type Actor
                local other = col.other
                -- a deals dmg to other
                if other.hp and a.dmg and use_cd(key('take damage', a.id, other.id), 3) then
                    other.hp = other.hp - a.dmg
                    if other.hp <= 0 then
                        if other.player then
                            log.info("player died")
                            other.pos = cell_pos(other.start_cell) + (game.LEVEL_TILE_SIZE/2)
                            world:update(other,
                                other.pos.x + other.shape.pos.x,
                                other.pos.y + other.shape.pos.y
                            )
                            other.hp = game.HP
                        end
                        if other.enemy then
                            log.info("enemy died")
                            remove_actor(other)
                        end
                    end
                end
                -- other deals dmg to a
                if a.hp and other.dmg and use_cd(key('take damage', other.id, a.id), 3) then
                    a.hp = a.hp - other.dmg
                    if a.hp <= 0 then
                        if a.enemy then
                            log.info("enemy died")
                            remove_actor(a)
                        end
                    end
                end
                -- touch item
                if a.inventory and other.item then
                    pick_up_item(a, other)
                end
                -- `a` knocks back `other`
                if a.shape.knockback and other.vel and use_cd(key(a.id, 'knockback'), 0.5) then
                    log.debug("knock back", other)
                    local norm = (other.pos - a.pos):norm()
                    other.vel = other.vel + norm * a.shape.knockback
                end
                -- level exit
                local level_exit = other.level_exit
                if a.player and level_exit then
                    local _, current_level_idx = get_current_level(a)
                    local next_level = current_level_idx + 1
                    log.debug("player at alt", a.alt,"move from level", current_level_idx, "to", next_level)
                    if next_level > #game.levels then
                        add_level(level_exit)
                    end
                    enter_level(next_level, a)
                end
            end
        elseif target then
            a.pos:set(target)
        end

        local z = get_z(a)
        if z ~= last_z[a.id] then
            -- need z sorting
            last_z[a.id] = z
            need_sort = true
        end

        -- lighting
        if a.light then
            light.move_light(a, a.pos.x, a.pos.y - (a.alt or 0))
        end
        local ai = a.ai
        if ai then
            if a.hates and use_cd(key(a.id, 'chase enemy'), 0.25) then
                -- find a new target
                ai.path = nil
                a.move_dir:set(0, 0)
                for _, hate in ipairs(a.hates) do
                    local targets = get_faction(hate)
                    for _, a2 in ipairs(targets) do
                        -- same level and has breadcrumbs
                        if
                            a.alt and a2.alt and a.alt == a2.alt
                        then
                            if a.pos:dist(a2.pos) <= ai.vision_radius and has_line_of_sight(a, a2.pos) then
                                -- path to actor
                                ai.path = get_pathing(a, a2.pos)
                                ai.last_seen = a2.id
                                
                            elseif
                                ai.breadcrumb_radius and
                                ai.last_seen == a2.id
                            then
                                if
                                    a.pos:dist(a2.pos) > ai.breadcrumb_radius or
                                    not a2.breadcrumbs or #a2.breadcrumbs.points == 0
                                then
                                    ai.last_seen = nil
                                else
                                    -- path to a breadcrumb
                                    for _, pt in ipairs(a2.breadcrumbs.points) do
                                        if has_line_of_sight(a, pt) then
                                            ai.path = get_pathing(a, pt)
                                        end
                                    end
                                end
                            end
                        end
                        if ai.path then break end
                    end
                    if ai.path then break end
                end
            end

            if ai.path and #ai.path == 0 then
                -- done pathing
                ai.path = nil
                a.move_dir:set(0, 0)
            end

            -- get waypoint
            ---@type Vector.lua?
            local waypoint
            if ai.path and #ai.path > 0 then
                waypoint = ai.path[1]
            end

            if waypoint then
                -- move to waypoint
                a.move_dir = (waypoint - a.pos):norm()
            end

            -- get next waypoint
            if waypoint and a.pos:dist(waypoint) < 20 and ai.path and #ai.path > 0 then
                table.remove(ai.path, 1)
            end

        end
        local bc = a.breadcrumbs
        if bc and use_cd(key(a.id, 'leave breadcrumb'), bc.cd) then
            lume.push(bc.points, a.pos:clone())
            if #bc.points > bc.capacity then
                table.remove(bc.points, 1)
            end
        end
    end

    if need_sort then
        table.sort(game.actors, sort_by_z)
    end

    if use_cd(key('update walkable'), 3) then
        for i in ipairs(game.levels) do
            update_walkable(i)
        end
    end
end

local draw = function ()
    local players = get_group('player')
    for _, player in ipairs(players) do
        local canvases = level_canvas[player.id]
        if not canvases then
            canvases = {}
            level_canvas[player.id] = canvases
        end

        -- clear level canvases
        for _, canvas in ipairs(canvases) do
            canvas:renderTo(function ()
                love.graphics.clear()
            end)
        end

        camera.push()
        -- draw actors
        for _, a in ipairs(game.actors) do
            local level, level_idx = get_current_level(a)
            ---@type love.Canvas
            local canvas
            if not level or level_idx > 0 then
                canvas = canvases[level_idx]
                if not canvas then
                    canvas = love.graphics.newCanvas()
                    canvases[level_idx] = canvas
                end
                -- love.graphics.setCanvas(canvas)
                if not a.player and a.current_level then
                    -- draw relative to player elevation
                    local level = game.levels[a.current_level]
                    local alt_diff = clamp(level.alt - player.alt, -game.LEVEL_ALT, game.LEVEL_ALT) / game.LEVEL_ALT
                    setColor(1,1,1,1-abs(alt_diff))
                    -- NOTE wont work until I start using spritesheets (non-primitive drawing)
                end
                draw_actor(a, a.alt)
                -- love.graphics.setCanvas()
            end
        end
        light.draw()
        camera.pop()
    end
end

return {
    math2 = math2,
    camera = camera,
    update = update,
    draw = draw,
    key = key,
    filters = {
        near_cell_type = near_cell_type
    },
    mouse = {
        world_pos = shove.mouseToViewport,
    },
    viewport = {
        size = shove.getViewportDimensions,
    },
    level = {
        add = add_level,
        enter = enter_level,
        to_grid = to_grid,
        get_cell = get_level_cell,
        get_cells = get_level_cells,
        cell_size = cell_size,
        get_pos = get_map_pos,
        get_alt = get_level_alt,
    },
    actor = {
        add = add_actor,
        ---@param actors Actor[]
        add_many = function (actors)
            for _, a in ipairs(actors) do
                add_actor(a)
            end
        end,
        remove = remove_actor,
        ---@param actors Actor[]
        remove_many = function (actors)
            for _, a in ipairs(actors) do
                remove_actor(a)
            end
        end,
        get_group = get_group,
        draw = draw_actor,
        add_to_inventory = add_to_inventory,
        pick_up_item = pick_up_item,
        status_effects = {
            apply = status_effects.apply,
            remove = status_effects.remove,
        },
    },
    audio = {
        ---@param a Actor
        ---@param path string
        play_from_actor = function (a, path)
            local effects = {}
            local filter

            -- check if anyone can hear it
            local in_hearing_range = a.current_level == nil
            if a.current_level then
                for _, p in ipairs(get_group('player')) do
                    if p.current_level == a.current_level then
                        in_hearing_range = true
                    end
                end
            end
            if not in_hearing_range then
                log.debug('not in hearing range', path, 'from', a.name)
                return
            end

            -- get actor level theme effect
            local level = a.current_level and game.levels[a.current_level] or nil
            if level then
                lume.push(effects, 'theme_'..level.theme)
            end

            local src = audio.get_source(path, effects, filter)

            -- adjust volume
            src:setVolume(game.VOLUME.SFX)

            -- set position relative to camera
            if src:getChannelCount() == 1 then
                src:setPosition(a.pos.x, a.pos.y, 0)
            end

            log.debug('play', path, 'at', a.name, 'pos', {src:getPosition()}, 'effects', effects, 'filter', filter)

            local listen_pos
            
            if a.cam_follow and a.pos then
                listen_pos = a.pos
            else
                listen_pos = camera.get_pos()
            end

            if listen_pos then
                love.audio.setPosition(listen_pos.x, listen_pos.y, 0)
            end
            log.debug('listener at', love.audio.getPosition())

            src:play()
        end
    }
}