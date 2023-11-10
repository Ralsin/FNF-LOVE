local dimensions = require "dimensions"

function love.conf(t)
    t.identity = "funkin"
    -- t.console = true

    t.window.title = "Friday Night Funkin' LÖVE"
    t.window.icon = "art/icon.png"
    t.window.width = dimensions.width
    t.window.height = dimensions.height
    t.window.resizable = true
    t.window.vsync = false

    t.modules.physics = false
    t.modules.touch = false
    t.modules.video = false
end
