function love.conf(t)
    t.identity = "LOVE SkinViewer"
    t.version = "11.4"

    t.window.title = "Skin Viewer"
    t.window.depth = 16
    t.window.minwidth = 100
    t.window.minheight = 100
    t.window.resizable = true

    t.modules.joystick = false
    t.modules.physics = false
end