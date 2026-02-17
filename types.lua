---@class State
---@field load? fun()
---@field update? fun(dt:number)
---@field draw? fun()

---@class Item
---@field name string
---@field cooldown? number

---@alias ShapeTag 'fall'|'wall'|'body'|'hit'

---@class Shape
---@field tag ShapeTag
---@field pos Vector.lua
---@field size Vector.lua
---@field disabled? boolean
---@field knockback? number [tag=hit] collision knockback strength

---@class Actor
---@field id? string
---@field owner? string id
---@field player? number
---@field pos Vector.lua
---@field vel? Vector.lua
---@field aim_dir? Vector.lua
---@field move_dir? Vector.lua
---@field max_move_speed? number
---@field mass? number
---@field hp? number
---@field dmg? number deal damage on collision
---@field enemy? string
---@field map_path? {x:number, y:number}[]
---@field tile_path? {x:number, y:number}[]
---@field start_tile? number tile index this actor spawned at, if they used an entrance
---@field inventory? {items:Item[], capacity:number}
---@field item? Item this actor is an item
---@field shape? Shape
---@field range? number aim / attacks / projectiles