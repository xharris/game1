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
local TILE = game.TILE 
local ripairs = lume.ripairs
local round = math2.round
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop

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

---@param idx number
---@param w number
---@param tile_size number
local get_tile_bbox = function (idx, w, tile_size)
    local x, y = math2.array1d_to_array2d(idx, w)
    return x * tile_size, y * tile_size, tile_size, tile_size
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
        if a.level_tile and a.level_tile.type == tile then
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

local id = 0
---@type table<Group, Actor[]>
local actor_groups = {}

---@param group Group
local get_group = function (group)
    return actor_groups[group] or {}
end

---@param a Actor
local add_actor = function (a)
    if not a.id then
        id = id + 1
        a.id = tostring(id)
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
    if use_cd(key('pick_up_item', a.id), 2) then
        -- drop last item in inventory if above capacity
        while #a.inventory.items >= a.inventory.capacity do
            drop_item(a, #a.inventory.items)
        end
        if #a.inventory.items < a.inventory.capacity then
            -- add item to inventory
            lume.push(a.inventory.items, item.item)
            log.debug("picked up", item.item.name..', inventory:' , #a.inventory.items, 'items')
            remove_actor(item)
            return true
        end
    end
    return false
end

---@param a Actor
---@param b Actor
local get_pathing = function (a, b)
    -- path to random player (test code)
    local player = randomchoice(get_players())
    local a_tile_idx = get_tile_idx(a.pos.x, a.pos.y)
    local b_tile_idx = get_tile_idx(b.pos.x, b.pos.y)
    local goal_x, goal_y = math2.array1d_to_array2d(b_tile_idx, game.maze.width)
    local start_x, start_y = math2.array1d_to_array2d(a_tile_idx, game.maze.width)
    local path = luastar:find(
        game.maze.width, game.maze.width, 
        {x=start_x, y=start_y}, {x=goal_x, y=goal_y},
        pos_is_walkable,
        true, true
    )
    return path
end

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

---@param _ Actor
local get_level_tile_canvas = lume.memoize(function (_)
    return love.graphics.newCanvas()
end)

---@param level number
local get_level_tiles = function (level)
    local tiles = get_group('level_tile')
    return lume.filter(tiles, function (t)
        return t.level_tile.level == level
    end)
end

---@param level number
local get_level_alt = function (level)
    return level * game.LEVEL_ALT
end

---@param level number
---@param a Actor
local enter_level = function (level, a)
    local tiles = get_level_tiles(level)
    if not a.start_level then
        a.start_level = level
    end
    -- at starting level
    if level == a.start_level then
        if not a.start_tile then
            if a.enemy then
                -- place enemy in random tile
                a.start_tile = randomchoice(get_tiles_of_type(tiles, TILE.ground))
            end
            if a.player then
                -- place at random entrance
                a.start_tile = randomchoice(get_tiles_of_type(tiles, TILE.entrance))
            end
            if a.item then
                a.start_tile = randomchoice(get_tiles_of_type(tiles, TILE.ground))
            end
        end
        place_at_level_tile(tiles, a, a.start_tile)
    else
        place_at_level_tile(tiles, a, randomchoice(get_tiles_of_type(tiles, TILE.entrance)))
    end
end

---Get Actor's current level based on `alt`
---@param a Actor
---@return Level? level, number level_index
local get_current_level = function(a)
    ---@type Level?
    local nearest_level
    local level_idx = 0
    for i, level in ipairs(game.levels) do
        if a.alt <= level.alt and (not nearest_level or level.alt < nearest_level.alt) then
            nearest_level = level
            level_idx = i
        end
    end
    return nearest_level, level_idx
end

---@param theme LevelTheme
local add_level = function (theme)
    local level_idx = #game.levels + 1
    local alt = get_level_alt(level_idx)
    log.debug("add level", level_idx, "alt", alt)
    ---@type Level
    local level = {
        alt = alt,
        theme = theme,
    }
    lume.push(game.levels, level)
    -- read map data from img
    local tiles, width = load_maze_from_img(assets.maze_test, game.TILE_COLORS)
    local ox, oy = -floor(width/2), -floor(width/2)
    -- create LevelTiles
    ---@type Actor[]
    local level_tiles = {}
    for i, tile in ipairs(tiles) do
        local ix, iy = math2.array1d_to_array2d(i, width)
        -- add level tile
        local level_tile = add_actor{
            group = 'level_tile',
            pos = vec2(ix+ox, iy+oy) * (game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE),
            level_tile = {
                level = level_idx,
                type = tile
            },
            size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE,
            shape = tile ~= TILE.none and {
                tag = 'ground',
                pos = vec2(0, 0),
                size = game.LEVEL_CELL_SIZE * game.LEVEL_TILE_SIZE,
            } or nil,
            alt = alt,
            z = -1,
        }
        lume.push(level_tiles, level_tile)
    end
    -- set exit
    local tiles = get_level_tiles(level_idx)
    local exit = randomchoice(get_tiles_of_type(tiles, TILE.entrance))
    local exit_tile = tiles[exit]
    exit_tile.level_tile.type = 3
    add_actor{
        pos = exit_tile.pos + (game.LEVEL_CELL_SIZE / 2),
        level_exit = true,
        shape = {
            tag = 'area',
            pos = vec2(),
            size = vec2(32, 32),
        },
        alt = alt
    }
    -- setup actors
    local level_actors = {
        actors.slime(),
        actors.slime(),
        actors.slime(),
        actors.slime(),
        actors.sword(),
        actors.sword(),
        actors.sword(),
        actors.sword(),
    }
    for _, a in ipairs(level_actors) do
        add_actor(a)
        enter_level(level_idx, a)
    end
    -- TODO place traps
    local canvas = get_level_tile_canvas
    return level_idx
end

local xform = love.math.newTransform()

local get_z = function (a)
    return (a.z or 0) + (a.alt or 0)
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

---@param a Actor
---@param alt number
local draw_actor = function (a, alt)
    local skip = false
    local size = a.size or vec2(32, 32)
    local off = a.off or vec2()
    if a.item then
        setColor(color(mui.AMBER_500))
    elseif a.dmg then
        setColor(color(mui.RED_500))
    elseif a.player or a.enemy then
        setColor(color(mui.GREEN_500))
    elseif a.level_tile and a.level_tile.type ~= TILE.none then
        local level = game.levels[a.level_tile.level]
        if a.level_tile.type == TILE.exit then
            setColor(color(mui.PURPLE_100))
        elseif level.theme == 'forest' then
            setColor(color(mui.GREEN_300))
        elseif level.theme == 'castle' then
            setColor(color(mui.GREY_300))
        end
    elseif a.level_exit then
        setColor(color(mui.PURPLE_400))
    else
        skip = true
    end
    if not skip then
        xform:reset()
        xform:translate(round(a.pos.x), round(a.pos.y - (alt or 0))) -- position
        xform:translate(round(off.x), round(off.y)) -- offset
        
        push()
        love.graphics.applyTransform(xform)
        rectangle("fill", 0, 0, size.x, size.y)
        -- outline
        setColor(color(mui.RED_400))
        rectangle("line", 0, 0, size.x, size.y)
        -- draw aim direction
        if a.aim_dir and a.range then
            local aim_pos = a.aim_dir * a.range
            setColor(color(mui.RED_500))
            rectangle("fill", -off.x+aim_pos.x-6, -off.y+aim_pos.y-6, 12, 12)
        end
        pop()
        -- draw_hitbox(a)
    end
end

---@type State
return {
    load = function ()
        camera.set_scale(game.CAMERA_ZOOM)

        -- load level 1
        local level_idx = add_level('forest')

        -- add player to level
        enter_level(level_idx, add_actor(actors.player(1)))
    end,

    update = function (dt)
        tick.update(dt)

        local need_sort = false
        for _, a in ipairs(game.actors) do
            local z = get_z(a)
            if z ~= last_z[a.id] then
                -- need z sorting
                last_z[a.id] = z
                need_sort = true
            end
            if a.player then
                -- set camera position
                camera.set_pos(a.pos.x, a.pos.y - (a.alt or 0))
            end
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
                local pos = a.pos - vec2(0, a.alt or 0)
                a.aim_dir = (vec2(mx, my) - pos):norm()

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
                                off = vec2(-16, -16),
                                vel = a.vel,
                                dmg = 5,
                                shape = {
                                    tag = 'hit',
                                    pos=vec2(-16, -16), 
                                    size=vec2(32, 32),
                                    knockback = 300,
                                    cd = 5,
                                },
                                alt = a.alt,
                            }
                        end, 0.1)
                        :after(function ()
                            -- remove hitbox at 0.6 sec
                            remove_actor(sword_hitbox)
                        end, 0.1)
                    end
                end
            end
            local target = a.pos
            if a.player and a.alt then
                -- floor/gravity
                local gravity_step = 9.8
                ---@param item Actor
                local floors, floor_len = world:queryPoint(a.pos.x, a.pos.y, function (item)
                    return item.shape.tag == 'ground' and is_same_alt(a, item, gravity_step + 1)
                end)
                local on_floor = floor_len > 0
                if on_floor then
                    -- snap to floor
                    a.alt = floors[1].alt
                    a.alt_v = 0
                else
                    -- apply gravity
                    a.alt_v = (a.alt_v or 0) - gravity_step
                    a.alt = a.alt + a.alt_v * dt
                end
            end
            if a.alt and a.alt < get_level_alt(-1) then
                -- out of bounds
                if a.start_level then
                    log.debug("out of bounds, respawn at start")
                    enter_level(a.start_level, a)
                else
                    log.debug("out of bounds, remove actor", a)
                    remove_actor(a)
                end
            end
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
                                other.hp = actors.HP
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
                    if a.player and other.level_exit then
                        local _, current_level_idx = get_current_level(a)
                        local next_level = current_level_idx + 1
                        log.debug("player at alt", a.alt,"move from level", current_level_idx, "to", next_level)
                        if next_level > #game.levels then
                            add_level('castle')
                        end
                        enter_level(next_level, a)
                    end
                end
            else
                a.pos:set(target)
            end
        end

        if need_sort then
            table.sort(game.actors, sort_by_z)
        end
    end,

    draw = function ()

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

            -- draw actors in their respective level canvas
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
                    love.graphics.setCanvas(canvas)
                    camera.push()
                    -- draw relative to player elevation
                    draw_actor(a, a.alt)
                    camera.pop()
                    love.graphics.setCanvas()
                end
            end

            -- draw all level canvases (for this player)
            for i, canvas in pairs(canvases) do
                -- TODO change opacity based on `alt` difference
                love.graphics.draw(canvas)
            end
        end
    end
}