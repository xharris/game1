local M = {}

local json = require 'lib.json'
local events = require 'events'

M.save_id = 'DEFAULT'
M.is_loading = false

local vec2_mt = getmetatable(vec2(0,0))

---@generic V
---@param v V
---@return V
local function serialize(v, seen)
    if type(v) ~= 'table' then return v end
    seen = seen or {}
    if seen[v] then return nil end  -- skip circular refs
    seen[v] = true

    local mt = getmetatable(v)
    if mt == vec2_mt then
        return { __type = 'vec2', x = v.x, y = v.y }
    end

    local out = {}
    for k, val in pairs(v) do
        out[k] = serialize(val, seen)
    end
    return out
end

---@generic V
---@param v V
---@return V
local function deserialize(v)
    if type(v) ~= 'table' then return v end

    if v.__type == 'vec2' then
        return vec2(v.x, v.y)
    end

    for k, val in pairs(v) do
        v[k] = deserialize(val)
    end
    return v
end

M.get_name = function ()
    return M.save_id..'.save'
end

M.get_path = function ()
    return love.filesystem.getSaveDirectory()..'/'..M.get_name()
end

---@alias SaveWriteFn fun(data:any) save json serializable data associated with the file that calls this

M.write = function ()
    if game.SAVE_WRITE_DISABLED or M.is_loading then
        return true
    end
    -- collect save data
    local save_data = {}
    ---@type SaveWriteFn
    local write = function (data)
        local info = debug.getinfo(2, "Sl")
        save_data[info.short_src] = data
    end
    events.game.saving.emit(write)
    -- clean data
    save_data = serialize(save_data)
    -- write to save dir
    local content = json.encode(save_data)
    local save_path = M.get_name()
    log.info('write to', M.get_path())
    local ok, err = love.filesystem.write(save_path, content)
    if not ok then
        log.error('could not write', M.save_id, err)
        return false
    end
    return true
end

---@alias SaveLoadFn fun():any 

M.load = function ()
    -- read from save dir
    local save_path = M.get_name()
    if not love.filesystem.getInfo(save_path) then
        return
    end
    log.info('read', M.get_path())
    local content, err = love.filesystem.read(save_path)
    if not content then
        log.error('could not read', M.save_id, err)
        return
    end
    -- parse json
    local data = json.decode(content)
    if not data or type(data) ~= "table" then
        log.error('could not load', type(data))
        return
    end
    M.is_loading = true
    data = deserialize(data)
    -- 'disperse' save data
    ---@type SaveLoadFn
    local load = function ()
        local info = debug.getinfo(2, "Sl")
        return data[info.short_src]
    end
    events.game.loading.emit(load)
    M.is_loading = false
    return data
end

return M