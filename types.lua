---@class State
---@field load? fun()
---@field update? fun(dt:number)
---@field draw? fun()

---@alias LevelTheme 'forest'|'castle'

---@class Level
---@field alt number
---@field theme LevelTheme
---@field width number

---@class LevelCell
---@field level number which level this belongs to
---@field type TILE
---@field index number

---@class Item
---@field name string
---@field cooldown? number
---@field equipped? boolean

---@alias ShapeTag 'wall'|'body'|'hit'|'area'|'ground'

---@class Shape
---@field tag ShapeTag
---@field pos Vector.lua
---@field size Vector.lua
---@field disabled? boolean
---@field knockback? number [tag=hit] collision knockback strength
---@field cd? number cooldown
---@field debug? boolean

---@class Ai
---@field vision_radius number
---@field breadcrumb_radius? number
---@field last_seen? string actor id
---@field path? Vector.lua[]

---@alias Group 'level_cell'|'player'

---@alias Faction 'human'|'wild_aggro'

---@class Actor
---@field id? string
---@field group? Group must be set before calling add_actor
---@field owner? string id
---@field player? number
---@field z? number draw order
---@field pos? Vector.lua
---@field off? Vector.lua render offset
---@field scale? Vector.lua render scale
---@field vel? Vector.lua
---@field aim_dir? Vector.lua
---@field move_dir? Vector.lua
---@field stunned? boolean
---@field alt? number altitude/elevation
---@field alt_v? number alt velocity
---@field alt_0_walkable? boolean remove? (unused)
---@field max_move_speed? number
---@field mass? number
---@field hp? number
---@field dmg? number deal damage on collision
---@field enemy? string
---@field map_path? {x:number, y:number}[]
---@field tile_path? {x:number, y:number}[]
---@field start_level? number
---@field start_tile? number tile index this actor spawned at, if they used an entrance
---@field inventory? {items:Item[], capacity:number}
---@field item? Item this is an item
---@field shape? Shape
---@field range? number aim / attacks / projectiles
---@field level_cell? LevelCell this is a level tile
---@field size? Vector.lua
---@field level_exit? boolean this is a level exit
---@field current_level? number
---@field light? {color:string, radius:number}
---@field ai? Ai targets must have breadcrumbs
---@field faction? Faction
---@field hates? Faction[]
---@field breadcrumbs? {capacity:number, cd:number, points:Vector.lua} throttled position history
---@field status_effects? table<string, number> {name:time_left}