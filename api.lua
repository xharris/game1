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
local cd = require 'cooldown'
local weakkeytable = require 'lib.weakkeytable'

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
local transform = math2.transform
local circle = love.graphics.circle
local blend = math2.blend
local line = love.graphics.line
local min = math.min
local max = math.max
local curve = math2.curve

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

local actor_by_id = weakkeytable()

---@param a Actor
local add_actor = function (a)
    if not a.id then
        id = id + 1
        a.id = tostring(id)
    end
    actor_by_id[a.id] = a
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
local get_move_speed = function (a)
    return status_effects.modify_stat(a, 'move_speed', a.move_speed or 0)
end

---@param a Actor
---@param immediate? boolean
local camera_follow = function (a, immediate)
    local cam_follow = a.cam_follow
    if not cam_follow or not a.pos then
        return
    end
    local cam = camera.get()
    if immediate then
        cam.pos_smooth = nil
    end
    local pos = a.pos:clone()
    if a.alt then
        pos.y = pos.y - a.alt
    end
    if cam_follow.move_dir_offset and a.move_dir and a.move_speed then
        pos = pos + (a.move_dir * (a.move_speed / 2))
    end
    if cam_follow.aim_dir_offset and a.aim_dir then
        pos = pos + (a.aim_dir * 30)
    end
    cam.target = pos:clone()
    if immediate then
        cam.pos_smooth = game.CAMERA_SMOOTH
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
---@param cell_idx number
local place_at_level_cell = function (cells, a, cell_idx)
    local cell = cells[cell_idx] or nil
    if cell then
        log.info('place', a.name, 'at', cell_idx, 'cell_pos', cell.pos.x, cell.pos.y)
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
        if not a.start_cell then
            a.start_cell = {}
        end
        if not a.start_cell[cell.level_cell.level] then
            a.start_cell[cell.level_cell.level] = cell_idx
        end
        camera_follow(a, true)
        world:update(a, a.pos.x + a.shape.pos.x, a.pos.y + a.shape.pos.y)
    else
        log.warn("no start tile found", a)
    end
end

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
    if item_module.primary_hand and a.hands.right then
        a.hands.right.item = item_module.sprite()
    end
    events.actor.item_equipped.emit(a, item)
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
    if cd.use(game.CD.pick_up_item, cd.names.pick_up_item, a.id) and add_to_inventory(a, item.item) then
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

---@param name string
---@return NextLevel?
local get_next_level_config = function (name)
    for _, l in ipairs(game.LEVELS) do
        if l.name == name then
            return l
        end
    end
end

---@param level_idx number
---@param a Actor
---@param cell_filters? ActorFilter[] for cell placement
local enter_level = function (level_idx, a, cell_filters)
    local level = game.levels[level_idx]
    local cells = get_level_cells(level_idx)
    if not level or #cells == 0 then
        log.warn(a.name, "could not enter level", level_idx, level, "cells", #cells)
        return
    end
    if not a.start_level then
        a.start_level = level_idx
    end
    
    local start_cell = a.start_cell and a.start_cell[level_idx] or nil

    if not start_cell then
        -- actor has never been to this level before

        if a.group == 'enemy' then
            cell_filters = cell_filters or {filters.cell_of_type(game.CELL.ground)}
        end
        
        if a.group == 'player' then
            cell_filters = cell_filters or {filters.cell_of_type(game.CELL.entrance)}
        end

        if a.group == 'item' then
            cell_filters = cell_filters or {filters.cell_of_type(game.CELL.ground)}
        end

        if cell_filters and #cell_filters > 0 then
            -- place at random cell with given filters
            start_cell = filters.randomchoice(cells, cell_filters).level_cell.index
        end
    end

    if start_cell then
        place_at_level_cell(cells, a, start_cell)
    end
    
    a.alt = level.alt
    if a.current_level ~= level_idx then
        a.current_level = level_idx
        events.actor.current_level_changed.emit(a)
    end

    events.level.entered.emit(level_idx, a)
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
    log.debug("add level", level_idx, next_level.name, "alt", alt)
    local ox, oy = -floor(width/2), -floor(width/2)
    ---@type Level
    local level = {
        alt = alt,
        theme = theme,
        width = width,
        name = next_level.name,
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

    events.level.added.emit(level_idx, level, next_level)
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

    log.debug('map_size', map_size, 'step', step, 'start', start, 'goal', goal)
    local path = luastar:find(
        map_size.x / step.x, map_size.y / step.y,
        start, goal,
        pos_is_walkable,
        true, true
    )
    if path then
        local result = {}
        for i, p in ipairs(path) do
            -- convert back to world space (center of cell)
            result[i] = to_world(p, a.current_level) + step / 2
        end
        log.debug("path", result)
        return result
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
    if game.DRAW_AIM and a.aim_dir then
        -- aim position
        pop = transform(a.aim_dir.x * 64, a.aim_dir.y * 64, 0, 1, 1, 0, 0)
        setColor(0,0,1,1)
        circle('fill', 0, 0, 12)
        pop()
    end
    -- aim dir
    if game.DRAW_AIM and a.aim_dir then
        pop = transform(a.pos.x + a.aim_dir.x * 30, a.pos.y - alt + a.aim_dir.y * 30,
            0, a.scale and a.scale.x or 1, a.scale and a.scale.y or 1,
            0, 0)
        setColor(0,0,0.8,1)
        circle('fill', 0, 0, 8)
        pop()
    end
end

---@param target Actor
---@param amt number
---@param src? Actor
local deal_damage = function (target, amt, src)
    -- apply status effects
    if target.status_effects then
        for name in pairs(target.status_effects) do
            amt = status_effects.effects[name].take_damage(target, amt, src) or amt
        end
    end

    target.hp = target.hp - amt
    if target.hp <= 0 then
        log.info(target.name, "died")
        if target.group == 'player' then
            target.pos = cell_pos(target.start_cell[target.current_level]) + (game.LEVEL_TILE_SIZE/2)
            world:update(target,
                target.pos.x + target.shape.pos.x,
                target.pos.y + target.shape.pos.y
            )
            target.hp = math2.curve(game.CURVE.hp, 1)
        end
        remove_actor(target)
    end
end

---@param apply_to Actor
---@param dir Vector.lua
---@param amt number [0,1]
local knock_back = function (apply_to, dir, amt)
    if not apply_to.vel then
        return
    end
    dir = dir:norm()
    -- apply knockback
    local vec = dir:norm() * math2.curve(game.CURVE.knockback, amt)
    apply_to.vel = apply_to.vel + vec
end

local update = function (dt)
    love.audio.setVolume(game.VOLUME.global)

    local need_sort = false
    for _, a in ipairs(game.actors) do
        local delta_mod = a._delta_mod or 1
        a._delta_mod = blend(delta_mod, a.delta_mod or 1, 0.5)

        dt = dt * delta_mod
        if a.player and a.pos then
            local inp = input.get(a.player)

            -- set camera position
            local pos = a.pos
            if a.move_dir then
                pos = pos + (a.move_dir * 60)
            end
            if a.aim_dir then
                pos = pos + (a.aim_dir * 30)
            end

            if a.move_dir then
                -- movement input
                local input_movex, input_movey = inp:get 'move'
                a.move_dir:set(input_movex or 0, input_movey or 0)
            end

            local alt_pos = vec2(a.pos.x, a.pos.y - (a.alt or 0))

            if a.aim_dir and not a.disable_aim then
                if inp:getActiveDevice() == 'joy' then
                    -- joystick aim direction
                    local aim_dir = vec2(inp:get 'aim')
                    if aim_dir:getmag() > 0 then
                        a.aim_dir:set(aim_dir)
                    end

                else
                    -- mouse aim direction
                    local inside, mx, my = shove.mouseToViewport()
                    local wx, wy = camera.to_world(mx, my)
                    if inside then
                        local aim_pos = vec2(wx, wy)
                        a.aim_dir:set((aim_pos - alt_pos):norm())
                    end
                end
            end

            -- use item
            if a.inventory and #a.inventory.items > 0 then
                local item = a.inventory.items[1]
                local item_module = load_item(item.name)
                if item_module and inp:down 'primary' and cd.use(item.cooldown or 1, cd.names.use_item, a.id, item.name) then
                    item_module.activate(a, item, a.hands and a.hands.right or nil)
                end
                if item_module and item_module.update then
                    item_module.update(a, item, dt)
                end
            end

            -- vibrate
            local vibe = a.vibration
            ---@type love.Joystick
            local joy = love.joystick.getJoysticks()[a.player]
            if inp:getActiveDevice() == 'joy' and joy then
                local amt = vibe and vibe.amt or 0
                
                local l, r = 1, 1
                if vibe and vibe.dir then
                    vibe.dir = vibe.dir:norm()
                    l, r = abs(min(vibe.dir.x, 0)), abs(max(vibe.dir.x, 0))
                end

                joy:setVibration(l * amt, r * amt)
            end
        end
        camera_follow(a)

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

        -- apply move_dir to velocity
        if a.move_dir then

            a.vel = steer(a.vel, a.move_dir, get_move_speed(a), a.mass or 100, dt)
        end

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

                -- collision on cooldown?
                local shape_cd = a.shape.cd
                if not shape_cd or cd.use(shape_cd.duration, cd.names.collision, other.id, shape_cd.id) then
                    -- a deals dmg to other
                    if other.hp and a.dmg and cd.use(game.CD.take_damage, cd.names.take_damage, a.id, other.id) then
                        deal_damage(other, a.dmg or 0, a)
                    end
                    -- other deals dmg to a
                    -- TODO remove?
                    -- if a.hp and other.dmg and cd.use(game.CD.take_damage, cd.names.take_damage, other.id, a.id) then
                    --     deal_damage(a, other.dmg or 0, other)
                    -- end
                    -- touch item
                    if a.inventory and other.item then
                        pick_up_item(a, other)
                    end
                    -- `a` knocks back `other`
                    local knockback_key = a.shape.cd and a.shape.cd.id or a.id
                    if a.shape.knockback ~= nil and other.vel and cd.use(game.INF_TIME, cd.names.knockback, other.id, knockback_key) then
                        log.debug(a.name, "knock back", other.name, a.shape.knockback)
                        local dir = a.aim_dir and a.aim_dir or other.pos - a.pos
                        knock_back(other, dir, a.shape.knockback)
                        camera.shake() -- 0.2, a.shape.knockback)
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
                    if a.shape.action then
                        log.debug("shape action", a.shape.action)
                        events.actor.shape_hit.emit(a.shape.action, a, other)
                    end
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
            if a.hates and cd.use(game.CD.chase_enemy, cd.names.chase_enemy, a.id) then
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
                                -- path directly to actor
                                ai.path = {a2.pos:clone()}
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

            -- close enought to waypoint, get next waypoint
            if waypoint and a.pos:dist(waypoint) < game.MIN_WAYPOINT_DIST and ai.path and #ai.path > 0 then
                table.remove(ai.path, 1)
            end

        end
        local bc = a.breadcrumbs
        if bc and cd.use(bc.cd, cd.names.leave_breadcrumb, a.id) then
            lume.push(bc.points, a.pos:clone())
            if #bc.points > bc.capacity then
                table.remove(bc.points, 1)
            end
        end
        local _, current_level = get_current_level(a)
        if current_level ~= a.current_level then
            if a.group ~= 'entity' then
                log.debug(a.name, 'now in level', current_level)
            end
            a.current_level = current_level
            events.actor.current_level_changed.emit(a)
        end
    end

    if need_sort then
        table.sort(game.actors, sort_by_z)
    end

    if cd.use(game.CD.update_walkable, cd.names.update_walkable) then
        for i in ipairs(game.levels) do
            update_walkable(i)
        end
    end

    camera.update(dt)
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
    cd = cd,
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
        ---@param id? string
        by_id = function (id)
            ---@type Actor?
            return id and actor_by_id[id] or nil
        end,
        draw = draw_actor,
        add_to_inventory = add_to_inventory,
        equip_item = equip_item,
        pick_up_item = pick_up_item,
        ---@param a Actor
        ---@param name string
        get_item = function (a, name)
            for _, item in ipairs(a.inventory.items) do
                if item.name == name then
                    return item
                end
            end
        end,
        status_effects = {
            apply = status_effects.apply,
            remove = status_effects.remove,
        },
        deal_damage = deal_damage,
        knock_back = knock_back,
        get_move_speed = get_move_speed,
    },
    audio = {
        get_source = audio.get_source,

        ---Get audio source and configure it to play from the actor's position
        ---@param a Actor
        ---@param path string
        ---@param config AudioConfig
        play_from_actor = function (a, path, config)
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

            -- use level audio effects if none given
            if not config.effect or #config.effect == 0 then
                local level = get_current_level(a)
                if level then
                    local level_config = get_next_level_config(level.name)
                    local level_audio = level_config and level_config.audio_config or nil
                    if level_audio then
                        config = level_audio
                    end
                end
            end

            local src = audio.get_source(path, config)

            -- set position relative to camera
            if game.POSITION_AUDIO and src:getChannelCount() == 1 then
                src:setPosition(a.pos.x, a.pos.y, 0)
            else
                src:setPosition(0, 0, 0)
            end

            log.info('play', path, 'at', a.name, 'pos', {src:getPosition()})

            local listen_pos
            
            if a.cam_follow and a.pos then
                listen_pos = a.pos
            else
                listen_pos = camera.get().pos
            end

            if game.POSITION_AUDIO and listen_pos then
                love.audio.setPosition(listen_pos.x, listen_pos.y, 0)
            else
                love.audio.setPosition(0, 0, 0)
            end
            log.debug('listener at', love.audio.getPosition())

            src:play()
            return src
        end
    },
    effect = {
        ---@param delta_mod any
        ---@param duration any
        set_delta_mod = function (delta_mod, duration)
            local old_delta_mod = game.delta_mod or 1
            game.delta_mod = delta_mod
            tick.delay(function ()
                -- reset
                game.delta_mod = old_delta_mod
            end, duration)
        end
    }
}