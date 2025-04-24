-- Local lua debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start(); end

local g3d = require "g3d"
local shader = love.graphics.newShader(g3d.shaderpath, "assets/shader.frag")

local dir = love.filesystem.getSourceBaseDirectory()
local success = love.filesystem.mount(dir, "root")
print("trying to mount base directory:", success)

local skinIsSlim = false
local skinRefresh = false
local skinLighting = true
local skinLook = false
local skinPath = nil
local skinImage = nil

local alex = nil
local alexData = nil
local steve = nil
local steveData = nil

local fps = {}
fps.mx = 0
fps.my = 0
fps.dx = 0
fps.dy = 0
fps.sensitivity = 1 / 150
fps.speed = 4.5
fps.yaw = 0
fps.pitch = 0

local player = {}
player.rotZ = 0
player.headRotY = 0
player.headRotZ = 0
player.speed = 0

local head = nil
local torso = nil
local right_leg = nil
local left_leg = nil
local right_arm_wide = nil
local left_arm_wide = nil
local right_arm_slim = nil
local left_arm_slim = nil

function updateSkinTexture(imageData, imagePath)
    local r,g,b,a = imageData:getPixel(math.min(51, imageData:getWidth() - 1), math.min(16, imageData:getHeight() - 1))
    skinIsSlim = a <= 0.5

    skinPath = imagePath
    skinImage = love.graphics.newImage(imageData)
    skinImage:setFilter("nearest", "nearest")

    head.texture = skinImage
    torso.texture = skinImage
    right_leg.texture = skinImage
    left_leg.texture = skinImage
    right_arm_wide.texture = skinImage
    left_arm_wide.texture = skinImage
    right_arm_slim.texture = skinImage
    left_arm_slim.texture = skinImage
    
    head.mesh:setTexture(head.texture)
    torso.mesh:setTexture(torso.texture)
    right_leg.mesh:setTexture(right_leg.texture)
    left_leg.mesh:setTexture(left_leg.texture)
    right_arm_wide.mesh:setTexture(right_arm_wide.texture)
    left_arm_wide.mesh:setTexture(left_arm_wide.texture)
    right_arm_slim.mesh:setTexture(right_arm_slim.texture)
    left_arm_slim.mesh:setTexture(left_arm_slim.texture)
end

function love.load()
    steveData = love.image.newImageData("assets/steve.png")
    steve = love.graphics.newImage(steveData)
    alexData = love.image.newImageData("assets/alex.png")
    alex = love.graphics.newImage(alexData)

    head = g3d.newModel("assets/head.obj", steve)
    torso = g3d.newModel("assets/torso.obj", steve)
    right_leg = g3d.newModel("assets/right_leg.obj", steve)
    left_leg = g3d.newModel("assets/left_leg.obj", steve)
    right_arm_wide = g3d.newModel("assets/right_arm_wide.obj", steve)
    left_arm_wide = g3d.newModel("assets/left_arm_wide.obj", steve)
    right_arm_slim = g3d.newModel("assets/right_arm_slim.obj", steve)
    left_arm_slim = g3d.newModel("assets/left_arm_slim.obj", steve)

    updateSkinTexture(steveData, "assets/steve.png")

    g3d.camera.lookInDirection(-4, 0, 1.62, 0, 0)
    g3d.camera.fov = math.rad(70)
    g3d.camera.updateProjectionMatrix()
    
    head:setTranslation(0, 0, 1.5)
    torso:setTranslation(0, 0, 0.75)
    right_leg:setTranslation(0.005, -0.125, 0.75)
    left_leg:setTranslation(0.005, 0.125, 0.75)
    right_arm_wide:setTranslation(0, -0.375, 1.375)
    left_arm_wide:setTranslation(0, 0.375, 1.375)
    right_arm_slim:setTranslation(0, -0.375, 1.375)
    left_arm_slim:setTranslation(0, 0.375, 1.375)

    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
end

function love.update(dt)
    -- arms idle
    local armRot = 0.05
    local rightArmRotX = (math.cos(love.timer.getTime() + 3) * 0.5 - 0.5) * armRot
    local rightArmRotY = math.sin(love.timer.getTime() + 3) * armRot
    local leftArmRotX = (math.sin(love.timer.getTime()) * 0.5 + 0.5) * armRot
    local leftArmRotY = math.cos(love.timer.getTime()) * armRot

    right_arm_wide:setRotation(rightArmRotX, rightArmRotY, 0)
    right_arm_slim:setRotation(rightArmRotX, rightArmRotY, 0)
    left_arm_wide:setRotation(leftArmRotX, leftArmRotY, 0)
    left_arm_slim:setRotation(leftArmRotX, leftArmRotY, 0)

    -- walk animation
    local swingRot = 1
    local rightSwing = math.sin(love.timer.getTime() * player.speed) * swingRot
    local leftSwing = math.sin(love.timer.getTime() * player.speed + math.pi) * swingRot
    right_leg:setRotation(0, leftSwing, 0)
    left_leg:setRotation(0, rightSwing, 0)
    right_arm_wide:setRotation(right_arm_wide.rotation[1], right_arm_wide.rotation[2] + rightSwing, right_arm_wide.rotation[3])
    right_arm_slim:setRotation(right_arm_slim.rotation[1], right_arm_slim.rotation[2] + rightSwing, right_arm_slim.rotation[3])
    left_arm_wide:setRotation(left_arm_wide.rotation[1], left_arm_wide.rotation[2] + leftSwing, left_arm_wide.rotation[3])
    left_arm_slim:setRotation(left_arm_slim.rotation[1], left_arm_slim.rotation[2] + leftSwing, left_arm_slim.rotation[3])

    -- head look
    if (skinLook) then
        player.headRotY = -fps.pitch
        player.headRotZ = fps.yaw
    end

    head:setRotation(0, player.headRotY, math.sin(player.headRotZ))

    -- camera
    if (love.mouse.isDown(2)) then
        if (not love.mouse.getRelativeMode()) then
            fps.mx = love.mouse.getX()
            fps.my = love.mouse.getY()
        end

        love.mouse.setRelativeMode(true)

        if (fps.dmove) then
            fps.dmove = false

            fps.yaw = fps.yaw - fps.dx * fps.sensitivity
            fps.pitch = math.max(math.min(fps.pitch - fps.dy * fps.sensitivity, math.pi * 0.5), math.pi * -0.5)
    
            g3d.camera.lookInDirection(g3d.camera.position[1], g3d.camera.position[2], g3d.camera.position[3], fps.yaw, fps.pitch)
        end

        local moveX, moveY = 0, 0
        local cameraMoved = false
        local cameraspeed = fps.speed
        if love.keyboard.isDown "lshift" then
            cameraspeed = cameraspeed * 0.25
        end
        if love.keyboard.isDown "space" then
            cameraspeed = cameraspeed * 2
        end

        if love.keyboard.isDown "w" then moveX = moveX + 1 end
        if love.keyboard.isDown "a" then moveY = moveY + 1 end
        if love.keyboard.isDown "s" then moveX = moveX - 1 end
        if love.keyboard.isDown "d" then moveY = moveY - 1 end
        if love.keyboard.isDown "e" then
            g3d.camera.position[3] = g3d.camera.position[3] + cameraspeed * dt
            cameraMoved = true
        end
        if love.keyboard.isDown "q" then
            g3d.camera.position[3] = g3d.camera.position[3] - cameraspeed * dt
            cameraMoved = true
        end

        if moveX ~= 0 or moveY ~= 0 then
            local angle = math.atan2(moveY, moveX)
            g3d.camera.position[1] = g3d.camera.position[1] + math.cos(fps.yaw + angle) * cameraspeed * dt
            g3d.camera.position[2] = g3d.camera.position[2] + math.sin(fps.yaw + angle) * cameraspeed * dt
            cameraMoved = true
        end

        if cameraMoved then
            g3d.camera.lookInDirection()
        end
    else
        if (love.mouse.getRelativeMode()) then
            love.mouse.setX(fps.mx)
            love.mouse.setY(fps.my)
        end

        love.mouse.setRelativeMode(false)
    end
end

function love.mousemoved(x, y, dx, dy)
    fps.dx = dx
    fps.dy = dy
    fps.dmove = true
end

function love.keypressed(key)
    if (key == "r") then
        skinRefresh = not skinRefresh
    elseif (key == "t") then
        skinIsSlim = not skinIsSlim
    elseif (key == "y") then
        skinLighting = not skinLighting
    elseif (key == "f") then
        skinLook = not skinLook
    elseif (key == "g") then
        if (player.speed <= 0) then
            player.speed = 5
        else
            player.speed = 0
        end
    end
end

function love.focus(f)
    if f then
        if (skinRefresh) then
            local path = "root/skin.png"
            local skin = love.filesystem.getInfo(path)

            print("refreshing:", path, skin)
            
            if (skin) then
                updateSkinTexture(love.image.newImageData(path), path)
            end
        end
    end
end

function love.filedropped(file)	
	local filename = file:getFilename()
	local ext = filename:match("%.%w+$")

	if ext == ".png" then
		file:open("r")
		fileData = file:read("data")
		local img = love.image.newImageData(fileData)

        updateSkinTexture(img, filename)
	end
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    shader:send("lighting", skinLighting)
    head:draw(shader)
    torso:draw(shader)
    right_leg:draw(shader)
    left_leg:draw(shader)
    if (not skinIsSlim) then
        right_arm_wide:draw(shader)
        left_arm_wide:draw(shader)
    else
        right_arm_slim:draw(shader)
        left_arm_slim:draw(shader)
    end

    if (skinImage and skinPath) then
        local mx, my = love.mouse.getPosition()
        if (mx <= 128 + 8 and my <= 128 + 32 + 8 and not love.mouse.getRelativeMode()) then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.1)
        end

        love.graphics.print(skinPath)
        love.graphics.draw(skinImage, 0, 32, 0, 2, 2)
    end

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("v1", love.graphics.getWidth() - 24, love.graphics.getHeight() - 24)
    love.graphics.print("drag and drop a PNG file to this window, or edit 'skin.png' while having refresh on", 300, 0)
    love.graphics.print("walk (g): " .. tostring(player.speed), 0, love.graphics.getHeight() - 80)
    love.graphics.print("head look (f): " .. tostring(skinLook), 0, love.graphics.getHeight() - 64)
    love.graphics.print("lighting (y): " .. tostring(skinLighting), 0, love.graphics.getHeight() - 48)
    love.graphics.print("refresh (r): " .. tostring(skinRefresh), 0, love.graphics.getHeight() - 32)
    love.graphics.print("slim (t): " .. tostring(skinIsSlim), 0, love.graphics.getHeight() - 16)
end
