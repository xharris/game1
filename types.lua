---@class State
---@field load? fun()
---@field update? fun(dt:number)
---@field draw? fun()

---@class Level
---@field alt number
---@field theme level_theme
---@field width number
---@field name string NextLevel.name

---@class NextLevel
---@field name string
---@field theme level_theme
---@field cells cell_type[]
---@field width number `tiles` width
---@field items string[]
---@field scenarios string[]

---@class LevelCell
---@field level number which level this belongs to
---@field type cell_type
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
---@field cd? number cooldown (unused??)
---@field debug? boolean

---@class Ai
---@field vision_radius number
---@field breadcrumb_radius? number
---@field last_seen? string actor id
---@field path? Vector.lua[]

---@class CameraFollow
---@field move_dir_offset? boolean
---@field aim_dir_offset? boolean

---@class Inventory
---@field items Item[]
---@field capacity number

---@class Vibration
---@field amt number [0,1]
---@field dir? Vector.lua alternative to `amt`

---@alias Group 'entity'|'level_cell'|'player'|'item'|'enemy'

---@alias Faction 'human'|'wild_aggro'

---@class Actor
---@field name? string
---@field id? string
---@field delta_mod? number [1, 0]
---@field _delta_mod? number
---@field group? Group must be set before calling add_actor
---@field owner? string id
---@field player? number
---@field z? number draw order
---@field y_sort? boolean `z` is treated as offset
---@field pos? Vector.lua
---@field scale? Vector.lua render scale
---@field alpha? number [0,1] opacity
---@field vel? Vector.lua
---@field aim_position? Vector.lua
---@field aim_dir? Vector.lua
---@field disable_aim? boolean
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
---@field start_cell? number[] tile index this actor spawned at for each level
---@field inventory? Inventory
---@field item? Item this is an item
---@field shape? Shape
---@field range? number aim / attacks / projectiles
---@field level_cell? LevelCell this is a level tile
---@field size? Vector.lua
---@field level_exit? NextLevel this is a level exit
---@field current_level? number
---@field light? {color:string, radius:number}
---@field ai? Ai targets must have breadcrumbs
---@field faction? Faction
---@field hates? Faction[]
---@field breadcrumbs? {capacity:number, cd:number, points:Vector.lua} throttled position history
---@field status_effects? table<string, number> {name:time_left}
---@field cam_follow? CameraFollow
---@field remove_after? number remove this actor from game after x seconds
---@field vibration? Vibration