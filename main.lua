io.stdout:setvbuf("no")
math.random = love.math.random

local json = require 'lib.json'
log = require 'lib.log'
lume = require 'lib.lume'
log.serialize = lume.serialize
vec2 = require 'lib.vector'
game = require 'game'

local input = require 'input'

---@type State?
local state

function love.load()

    state = require 'states.play'
    if state.load then
        state.load()
    end
end

function love.update(dt)
    input:update()
    if state and state.update then
        state.update(dt)
    end
end

function love.draw()
    if state and state.draw then
        state.draw()
    end
end

local function error_printer(msg, layer)
	msg =  (debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", ""))
    msg = msg .. '\n---\n' .. lume.serialize(game) .. '\n---\n'
    return msg
end

function love.errorhandler(msg)
    if tostring(msg):find("stack overflow") then
        print(msg)
    else
        log.error(error_printer(msg, 2))
    end
end