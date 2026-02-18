---@class State
---@field load? fun()
---@field update? fun(dt:number)
---@field draw? fun()

---@alias LevelTheme 'forest'|'castle'

---@class Level
---@field alt number
---@field theme LevelTheme

---@class LevelTile
---@field level number which level this belongs to
---@field type TILE

---@class Item
---@field name string
---@field cooldown? number

---@alias ShapeTag 'wall'|'body'|'hit'|'area'|'ground'

---@class Shape
---@field tag ShapeTag
---@field pos Vector.lua
---@field size Vector.lua
---@field disabled? boolean
---@field knockback? number [tag=hit] collision knockback strength
---@field cd? number cooldown

---@alias Group 'level_tile'

---@class Actor
---@field id? string
---@field group? Group must be set before calling add_actor
---@field owner? string id
---@field player? number
---@field pos Vector.lua
---@field off? Vector.lua render offset
---@field vel? Vector.lua
---@field aim_dir? Vector.lua
---@field move_dir? Vector.lua
---@field alt? number altitude/elevation
---@field alt_v? number alt velocity
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
---@field level_tile? LevelTile this is a level tile
---@field size? Vector.lua