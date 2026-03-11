
table.unpack = table.unpack or unpack
io.stdout:setvbuf("no")
math.random = love.math.random
vec2 = require 'lib.vector'
game = require 'game'()
love.math.setRandomSeed(game.SEED)

log = require 'lib.log'
log.level = game.LOG_LEVEL
lume = require 'lib.lume'
events = require 'events'
log.serialize = lume.serialize

shove = require 'lib.shove'
local input = require 'input'
local animation = require 'animation'
local tick = require 'lib.tick'
local api = require 'api'
local status_effects = require 'status_effects'
local audio = require 'audio'
local scenarios = require 'scenarios'
local timeline = require 'timeline'
local camera = require 'camera'

-- love.window.setMode(1280, 720, {resizable=false, display=2})
-- push.setupScreen(800, 600, {upscale="normal"})

---@type State?
local state

function love.load()
    log.info("running on", love.system.getOS())
    game.DISPLAY = math.min(game.DISPLAY, love.window.getDisplayCount())
    local dw, dh = love.window.getDesktopDimensions(game.DISPLAY)
    log.info('resolution', dw * game.GAME_SCALE, 'x', dh * game.GAME_SCALE)
    shove.setResolution(dw * game.GAME_SCALE, dh * game.GAME_SCALE, {fitMethod="pixel", scalingFilter="nearest"})
    shove.setWindowMode(dw * game.WINDOW_SCALE, dh * game.WINDOW_SCALE, {
        display=game.DISPLAY,
        fullscreen=game.FULLSCREEN,
    })
    audio.load()
    scenarios.load()
    state = require(game.STATE)
    if state.load then
        state.load()
    end
end

function love.update(dt)
    local orig_dt = dt
    dt = dt * game.delta_mod
    input.update()
    for _, a in ipairs(api.actor.get_group('player')) do
        local inp = input.get(a.player)
        -- toggle fullscreen with [alt/cmd]+enter
        local is_mac = love.system.getOS() == 'OS X'
        if a.player == 1 and inp:pressed 'start' and love.keyboard.isDown(is_mac and 'lgui' or 'lalt') then
            local dw, dh = love.window.getDesktopDimensions(game.DISPLAY)
            shove.setWindowMode(dw * game.WINDOW_SCALE, dh * game.WINDOW_SCALE, {
                display=game.DISPLAY,
                fullscreen=not love.window.getFullscreen(),
            })
        end
    end
    if state and state.update then
        state.update(dt)
    end
    api.update(dt)
    tick.update(orig_dt)
    animation.update(dt)
    timeline.update(dt)
end

function love.draw()
    shove.beginDraw()
    if state and state.draw then
        state.draw()
    end
    shove.endDraw()
end

local function error_printer(msg, layer)
	msg =  (debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", ""))
    if game.LOG_GAME_STATE_ON_ERR then
        lume.serialize_with_quotes = true
        msg = msg .. ('\n--- `game` state ---\n' .. lume.serialize(game) .. '\n---\n')
    end
    return msg
end

function love.errorhandler(msg)
    if tostring(msg):find("stack overflow") then
        print(msg)
    else
        log.error(error_printer(msg, 2))
    end
end

function love.quit()
    if game.LOG_GAME_STATE_ON_QUIT then
        lume.serialize_with_quotes = true
        print('\n--- `game` state ---\n' .. lume.serialize(game) .. '\n---\n')
    end
    return false
end