local M = {}

local E = {}

E.theme_forest = {
    effect = {
        type="reverb",volume=1,density=1,diffusion=.3,gain=.3162,highgain=.0224,
        decaytime=1.49,decayhighratio=.54,earlygain=.0525,earlydelay=.162,
        lategain=.7682,latedelay=.088,airabsorption=.9943,roomrolloff=0,highlimit=true,
    },
}

---@type string[]
local global_effects = {}

local sources = {}

---@param path string
---@return love.SoundData
local to_mono = function (path)
    local data = love.sound.newSoundData(path)
    local ch = data:getChannelCount()
    if ch <= 1 then return data end
    local frames = data:getSampleCount() / ch
    local mono = love.sound.newSoundData(frames, data:getSampleRate(), data:getBitDepth(), 1)
    for i = 0, frames - 1 do
        local sum = 0
        for c = 0, ch - 1 do
            sum = sum + data:getSample(i * ch + c)
        end
        mono:setSample(i, sum / ch)
    end
    return mono
end

---@param path string
---@param effects? string[]
---@param filter? string
M.get_source = function (path, effects, filter)
    effects = effects or {}
    local key = path..'|'..table.concat(global_effects, '+')..'|'..table.concat(effects, '+')..'|'..(filter or '')
    local src = sources[key]
    if not src then
        log.debug('create audio source', key)
        src = love.audio.newSource(path, 'static')
        if src:getChannelCount() > 1 then
            log.warn("mono audio is preferred", path)
        end
        -- add effects
        if love.audio.isEffectsSupported() then
            for _, name in ipairs(global_effects) do
                src:setEffect(name, true)
            end
            for _, name in ipairs(effects) do
                src:setEffect(name, true)
            end
        end
        -- set filter
        if filter and E[filter] and E[filter].filter then
            src:setFilter(E[filter].filter)
        end
    end
    return src
end

M.load = function ()
    if love.audio.isEffectsSupported() then
        -- load effects
        for name, settings in pairs(E) do
            if settings.effect then
                log.debug('add audio effect', name)
                love.audio.setEffect(name, settings.effect)
            end
        end
    end
end

---@param name string
---@return table? effect
M.get_effect = function (name)
    if not E[name] or not E[name].effect or not love.audio.isEffectsSupported() then
        return
    end
    return E[name].effect
end

---@param names string[]
M.set_global_effects = function (names)
    global_effects = names
end

return M