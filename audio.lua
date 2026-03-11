local M = {}

---@class AudioConfig
---@field volume 'sfx'|'sfx_epic'|'music'
---@field pitch? number
---@field effect? string

local assets = require 'assets'

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

---@type table<string, string[]>
local effect_types_by_name = {}

---@param name string
---@param settings table[]
M.install_effect = function (name, settings)
    effect_types_by_name[name] = {}
    for _, s in ipairs(settings) do
        local fullname = name..'_'..s.type
        lume.push(effect_types_by_name[name], fullname)
        log.info("install", fullname)
        love.audio.setEffect(fullname, s)
    end
end

---@param path string
---@param config AudioConfig
M.get_source = function (path, config)
    local key = path..'|'..(config.effect or 'none')..'|'..config.volume
    local src = sources[key]
    if not src then
        log.info('create audio source', key)
        src = love.audio.newSource(path, 'static')
        if src:getChannelCount() > 1 then
            log.warn("mono audio is preferred", path)
        end
        -- add effects
        if love.audio.isEffectsSupported() then
            local names = effect_types_by_name[config.effect] or {}
            for _, name in ipairs(names) do
                src:setEffect(name, true)
            end
        end
        -- other config options
        src:setPitch(config.pitch or 1)
        src:setVolume(game.VOLUME[config.volume] or 1)
        sources[key] = src
    end
    return src
end

M.load = function ()
    if not love.audio.isEffectsSupported() then
        log.warn("audio effects not supported")
    else
        for name, settings in pairs(assets.audio_effects) do
            M.install_effect(name, settings)
        end
    end
end

return M