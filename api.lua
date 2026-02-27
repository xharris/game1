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

local render_level_tile = require 'render.level_cell'
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
local TILE = game.TILE 
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop
local clamp = lume.clamp
local abs = math.abs
local sign = lume.sign
local rad = math.rad
local max = math.max
local transform = math2.transform

local world = bump.newWorld()

---@param path string
---@param colors string[]
---@return TILE[] tiles, number width
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

---@param tiles Actor[]
---@param tile TILE
---@return number[] indexes
local get_tiles_of_type = function (tiles, tile)
    local idxs = {}
    for i, a in ipairs(tiles) do
        if a.level_cell and a.level_cell.type == tile then
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

local actor_light = {}

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
    if not a.alt and #game.levels > 0 then
        _, a.alt = game.levels[#game.levels].alt
    end
    return a
end

---@param tiles Actor[]
---@param a Actor
---@param idx number
local place_at_level_tile = function (tiles, a, idx)
    local tile = tiles[idx] or nil
    if tile then
        local center = (game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE) / 2
        a.pos = tile.pos + center
        a.alt = tile.alt
        a.alt_v = 0
        world:update(a, a.pos.x + a.shape.pos.x, a.pos.y + a.shape.pos.y)
    else
        log.warn("no start tile found", a)
    end
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


---@class ItemModule
---@field item fun():Item
---@field hold_in_hand? boolean
---@field sprite? fun():Sprite
---@field equip? fun(a:Actor, item:Item)
---@field activate? fun(a:Actor, item:Item, hand?:Hand)

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
    if use_cd(key('pick_up_item', a.id), 2) and add_to_inventory(a, item.item) then
        remove_actor(item)
        return true
    end
    return false
end

---@param pos Vector.lua
---@param alt number
---@return Actor? tile, number? tile_idx, number? level_idx
local get_map_pos = function (pos, alt)
    for l, level in ipairs(game.levels) do
        if level.alt == alt then
            -- check tiles in this level
            for t, tile in ipairs(get_group('level_cell')) do
                local size = vec2(
                    game.LEVEL_TILE_SIZE.x * game.LEVEL_CELL_SIZE.x,
                    game.LEVEL_TILE_SIZE.y * game.LEVEL_CELL_SIZE.y
                )
                if tile.level_cell and
                    pos.x >= tile.pos.x and
                    pos.y >= tile.pos.y and
                    pos.x <= tile.pos.x + size.x and
                    pos.y <= tile.pos.y + size.y
                then
                    return tile, t, l
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
    if not (a.alt and b.alt) then return false end
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
local get_level_tiles = function (level)
    local tiles = get_group('level_cell')
    return lume.filter(tiles, function (t)
        return t.level_cell.level == level
    end)
end

---@param level number
local get_level_alt = function (level)
    return level * game.LEVEL_ALT
end

---@param level_idx number
---@param a Actor
local enter_level = function (level_idx, a)
    local level = game.levels[level_idx]
    local tiles = get_level_tiles(level_idx)
    if not level or #tiles == 0 then
        log.warn("invalid level", level_idx, "level", level, "tiles", #tiles)
        return
    end
    if not a.start_level then
        a.start_level = level_idx
    end
    local place = false
    if not a.start_tile then
        a.start_tile = {}
    end
    if not a.start_tile[level_idx] then
        if a.enemy then
            -- place enemy in random tile
            a.start_tile[level_idx] = randomchoice(get_tiles_of_type(tiles, TILE.ground))
            place = true
        end
        if a.player then
            -- place at random entrance
            a.start_tile[level_idx] = randomchoice(get_tiles_of_type(tiles, TILE.entrance))
            place = true
        end
        if a.item then
            a.start_tile[level_idx] = randomchoice(get_tiles_of_type(tiles, TILE.ground))
            place = true
        end
    else
        place = true
    end
    if place and a.start_tile[level_idx] then
        log.debug('place', a.group, 'at', a.start_tile[level_idx])
        place_at_level_tile(tiles, a, a.start_tile[level_idx])
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

local cell_size = lume.memoize(function ()
    return vec2(
        game.LEVEL_TILE_SIZE.x * game.LEVEL_CELL_SIZE.x,
        game.LEVEL_TILE_SIZE.y * game.LEVEL_CELL_SIZE.y
    )
end)

--- local tiles, width = load_maze_from_img(assets.maze_test, game.TILE_COLORS)
---@param next_level NextLevel
---@return number idx, Level level
local add_level = function (next_level)
    local theme, tiles, width = next_level.theme, next_level.tiles, next_level.width

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
    -- create LevelTiles
    ---@type Actor[]
    local level_tiles = {}
    for i, tile in ipairs(tiles) do
        local ix, iy = math2.array1d_to_array2d(i, width)
        -- add level tile
        local level_tile = add_actor{
            name = 'LEVEL_CELL',
            group = 'level_cell',
            pos = vec2(ix+ox, iy+oy) * (game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE),
            level_cell = {
                level = level_idx,
                type = tile,
                index = i,
            },
            size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE,
            shape = tile ~= TILE.none and {
                tag = 'ground',
                pos = vec2(0, 0),
                size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE,
            } or nil,
            alt = alt,
            z = -100,
            y_sort = true,
        }
        lume.push(level_tiles, level_tile)
    end
    -- set exit
    local tiles = get_level_tiles(level_idx)
    local exits = get_tiles_of_type(tiles, TILE.exit)
    local exit
    if #exits > 0 then
        exit = randomchoice(exits)
    else
        exit = randomchoice(get_tiles_of_type(tiles, TILE.entrance))
    end
    local exit_tile = tiles[exit]
    exit_tile.level_cell.type = 3
    local level_exit = add_actor{
        name = 'LEVEL_EXIT',
        pos = exit_tile.pos + (cell_size() / 2),
        level_exit = randomchoice(game.LEVELS),
        shape = {
            tag = 'area',
            pos = vec2(),
            size = vec2(32, 32),
        },
        sprite = {
            frame = 1,
            frames = vec2(1, 1),
            off = vec2(32, 32),
            path = assets.stairs,
        },
        alt = alt,
        z = exit_tile.z + 10,
        y_sort = true,
    }
    log.debug('add level exit', level_exit.pos)
    events.level.added.emit(level_idx, level)
    return level_idx, level
end

-- convert between world space and luastar grid space (0-based, always positive)
---@param world Vector.lua
---@param level_idx number
local to_grid = function (world, level_idx)
    local level = game.levels[level_idx]
    local tile_size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE
    local ox = -floor(level.width / 2)
    local min_world = vec2(ox * tile_size.x, ox * tile_size.y)
    local map_size = level.width * tile_size
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
    local map_size = level.width * tile_size
    local step = game.LEVEL_TILE_SIZE:clone()
    return vec2(grid.x * step.x + min_world.x, grid.y * step.y + min_world.y)
end

local all_walkable = {}

---@param level_idx number
local update_walkable = function (level_idx)
    local step = game.LEVEL_TILE_SIZE:clone()
    local tile_size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE
    local cells_x = tile_size.x / step.x  -- grid cells per tile
    local cells_y = tile_size.y / step.y
    local walkable = {}
    for _, tile in ipairs(get_group('level_cell')) do
        if tile.level_cell.level == level_idx and tile.level_cell.type ~= TILE.none then
            local g = to_grid(tile.pos, level_idx)
            for dy = 0, cells_y - 1 do
                local row = g.y + dy
                if not walkable[row] then walkable[row] = {} end
                for dx = 0, cells_x - 1 do
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
    local tile_size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE
    local map_size = level.width * tile_size
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
    render_level_tile.draw,
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
        a.off and a.off.x or 0, a.off and a.off.y or 0
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
end


local update = function (dt)
    local need_sort = false
    for _, a in ipairs(game.actors) do
        if a.player and a.pos then
            -- set camera position
            local pos = a.pos
            if a.move_dir then
                pos = pos + (a.move_dir * 60)
            end
            if a.aim_dir then
                pos = pos + (a.aim_dir * 30)
            end
            camera.set_pos(pos.x, pos.y - (a.alt or 0))
            camera.position_smoothing = 0.1
        end
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
            if a.move_dir and a.move_dir:getmag() > 0 then
                a.aim_dir = a.move_dir:norm()
            elseif not a.aim_dir then
                a.aim_dir = vec2(1,0)
            end

            -- mouse aim direction
            local _, mx, my = shove.mouseToViewport()
            local wx, wy = camera.to_world(mx, my)
            a.aim_dir = vec2(wx - a.pos.x, wy - (a.pos.y - (a.alt or 0))):norm()

            -- use item
            if a.inventory and #a.inventory.items > 0 then
                local item = a.inventory.items[1]
                local item_module = load_item(item.name)
                if item_module and input:down 'primary' and use_cd(key('use_item', a.id, item.name), item.cooldown or 1) then
                    item_module.activate(a, item, a.hands and a.hands.right or nil)
                end
            end
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
        render_level_tile.update(dt, a, players)

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
                            other.pos = tile_pos(other.start_tile) + (game.LEVEL_TILE_SIZE/2)
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
        
        _, a.current_level = get_current_level(a)
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
            local _, level_idx = get_current_level(a)
            ---@type love.Canvas
            local canvas
            if level_idx > 0 then
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
        cell_size = cell_size,
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
}