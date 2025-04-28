-- Local lua debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start(); end

local g3d = require "g3d"
local shader = love.graphics.newShader(g3d.shaderpath, "assets/shader.frag")

local dir = love.filesystem.getSourceBaseDirectory()
local success = love.filesystem.mount(dir, "root")
print("trying to mount base directory:", success)

local skinIsSlim = false
local skinRefresh = true
local skinLighting = true
local skinLook = false
local skinShowArmor1 = false
local skinShowArmor2 = false

local skinImage = nil
local skinArmor1Image = nil
local skinArmor2Image = nil

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
player.targetSpeed = 0

local head = {}
local torso = {}
local right_leg = {}
local left_leg = {}
local right_arm = {}
local left_arm = {}

function updateSkinTexture(imageData, imagePath)
    local r,g,b,a = imageData:getPixel(math.min(51, imageData:getWidth() - 1), math.min(16, imageData:getHeight() - 1))
    skinIsSlim = a <= 0.5
    refreshSlimWide()

    skinImage = love.graphics.newImage(imageData)
    skinImage:setFilter("nearest", "nearest")

    setTexture(head, skinImage)
    setTexture(torso, skinImage)
    setTexture(right_arm, skinImage)
    setTexture(left_arm, skinImage)
    setTexture(left_leg, skinImage)
    setTexture(right_leg, skinImage)
end

function setTranslation(models, x, y, z)
    for k,model in pairs(models) do
        if (model) then
            model:setTranslation(x, y, z)
        end
    end
end
function setRotation(models, rx, ry, rz)
    for k,model in pairs(models) do
        if (model) then
            model:setRotation(rx, ry, rz)
        end
    end
end
function setTexture(models, texture, key)
    for k,model in pairs(models) do
        if (not key or (key and k == key)) then
            if (model) then
                texture:setFilter("nearest", "nearest")
                model.texture = texture
                model.mesh:setTexture(texture)
            end
        end
    end
end
function draw(models, shader, key)
    for k,model in pairs(models) do
        if (not key or (key and k == key)) then
            if (model) then
                model:draw(shader)
            end
        end
    end
end
function refreshSlimWide()
    if (skinIsSlim) then
        right_arm.normal_wide = nil
        left_arm.normal_wide = nil
        right_arm.normal_slim = g3d.newModel("assets/right_arm_slim.obj", skinImage)
        left_arm.normal_slim = g3d.newModel("assets/left_arm_slim.obj", skinImage)
    else
        right_arm.normal_wide = g3d.newModel("assets/right_arm_wide.obj", skinImage)
        left_arm.normal_wide = g3d.newModel("assets/left_arm_wide.obj", skinImage)
        right_arm.normal_slim = nil
        left_arm.normal_slim = nil
    end

    setTranslation(right_arm, 0, -0.375, 1.375)
    setTranslation(left_arm, 0, 0.375, 1.375)
end

function love.load()
    local errorData = love.image.newImageData(2, 2)
    errorData:mapPixel(function(x,y,r,g,b,a)
        if (x == 0 and y == 0 or x == 1 and y == 1) then
            return 1,0,1,1
        else
            return 0,0,0,1
        end
    end)

    local errorImage = love.graphics.newImage(errorData)

    head.normal = g3d.newModel("assets/head.obj", nil)
    torso.normal = g3d.newModel("assets/torso.obj", nil)
    
    head.armor2 = g3d.newModel("assets/head_armor2.obj", nil)
    torso.armor1 = g3d.newModel("assets/torso_armor1.obj", nil)
    torso.armor2 = g3d.newModel("assets/torso_armor2.obj", nil)

    right_leg.normal = g3d.newModel("assets/right_leg.obj", nil)
    left_leg.normal = g3d.newModel("assets/left_leg.obj", nil)

    right_leg.armor1 = g3d.newModel("assets/right_leg_armor1.obj", nil)
    right_leg.armor2 = g3d.newModel("assets/right_leg_armor2.obj", nil)
    left_leg.armor1 = g3d.newModel("assets/left_leg_armor1.obj", nil)
    left_leg.armor2 = g3d.newModel("assets/left_leg_armor2.obj", nil)
    right_arm.armor1 = g3d.newModel("assets/right_arm_armor1.obj", nil)
    right_arm.armor2 = g3d.newModel("assets/right_arm_armor2.obj", nil)
    left_arm.armor1 = g3d.newModel("assets/left_arm_armor1.obj", nil)
    left_arm.armor2 = g3d.newModel("assets/left_arm_armor2.obj", nil)
    setTexture(head, errorImage)
    setTexture(torso, errorImage)
    setTexture(right_leg, errorImage)
    setTexture(left_leg, errorImage)
    setTexture(right_arm, errorImage)
    setTexture(left_arm, errorImage)
    refreshSlimWide()

    g3d.camera.lookInDirection(-4, 0, 1.62, 0, 0)
    g3d.camera.fov = math.rad(70)
    g3d.camera.updateProjectionMatrix()
    
    local legXOffset, legYOffset = 0.001, 0.005

    setTranslation(head, 0, 0, 1.5)
    setTranslation(torso, 0, 0, 0.75)
    setTranslation(right_leg, 0 + legXOffset, -0.125 + legYOffset, 0.75)
    setTranslation(left_leg, 0 + legXOffset, 0.125 - legYOffset, 0.75)
    setTranslation(right_arm, 0, -0.375, 1.375)
    setTranslation(left_arm, 0, 0.375, 1.375)

    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
end

function love.update(dt)
    player.speed = player.targetSpeed

    -- walk animation
    local swingRot = math.rad(60)
    local rightSwing = math.sin(love.timer.getTime() * player.speed) * swingRot
    local leftSwing = math.sin(love.timer.getTime() * player.speed + math.pi) * swingRot
    setRotation(right_leg, 0, leftSwing, 0)
    setRotation(left_leg, 0, rightSwing, 0)

    -- arms idle
    local armRot = 0.05
    local rightArmRotX = (math.cos(love.timer.getTime() + 3) * 0.5 - 0.5) * armRot
    local rightArmRotY = math.sin(love.timer.getTime() + 3) * armRot + rightSwing
    local leftArmRotX = (math.sin(love.timer.getTime()) * 0.5 + 0.5) * armRot
    local leftArmRotY = math.cos(love.timer.getTime()) * armRot + leftSwing

    setRotation(right_arm, rightArmRotX, rightArmRotY, 0)
    setRotation(left_arm, leftArmRotX, leftArmRotY, 0)


    -- head look
    if (skinLook) then
        player.headRotY = -fps.pitch
        player.headRotZ = fps.yaw
    end

    setRotation(head, 0, player.headRotY, math.sin(player.headRotZ))

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
        refreshSlimWide()
    elseif (key == "y") then
        skinLighting = not skinLighting
    elseif (key == "f") then
        skinLook = not skinLook
    elseif (key == "g") then
        player.targetSpeed = player.targetSpeed <= 0 and 10 or 0
    elseif (key == "c") then
        skinShowArmor1 = not skinShowArmor1
    elseif (key == "v") then
        skinShowArmor2 = not skinShowArmor2
    end
end

function love.focus(f)
    if f then
        if (skinRefresh) then
            print("refreshing:", path, skin)

            local path = "root/"

            local skinPath = path .. "skin.png"
            local skin = love.filesystem.getInfo(skinPath)
            if (skin) then
                updateSkinTexture(love.image.newImageData(skinPath))
            end

            local armor1Path = path .. "armor_leggings.png"
            local armor1 = love.filesystem.getInfo(armor1Path)
            local armor2Path = path .. "armor.png"
            local armor2 = love.filesystem.getInfo(armor2Path)
            
            if (armor1) then
                skinArmor1Image = love.graphics.newImage(armor1Path)
                setTexture(right_arm, skinArmor1Image, "armor1")
                setTexture(left_arm, skinArmor1Image, "armor1")
                setTexture(right_leg, skinArmor1Image, "armor1")
                setTexture(left_leg, skinArmor1Image, "armor1")
                setTexture(torso, skinArmor1Image, "armor1")
                setTexture(head, skinArmor1Image, "armor1")
            end
            if (armor2) then
                skinArmor2Image = love.graphics.newImage(armor2Path)
                setTexture(right_arm, skinArmor2Image, "armor2")
                setTexture(left_arm, skinArmor2Image, "armor2")
                setTexture(right_leg, skinArmor2Image, "armor2")
                setTexture(left_leg, skinArmor2Image, "armor2")
                setTexture(torso, skinArmor2Image, "armor2")
                setTexture(head, skinArmor2Image, "armor2")
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
        skinRefresh = false
	end
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    shader:send("lighting", skinLighting)
    draw(head, shader, "normal")
    draw(torso, shader, "normal")
    draw(right_leg, shader, "normal")
    draw(left_leg, shader, "normal")
    draw(right_arm, shader, "normal_wide")
    draw(right_arm, shader, "normal_slim")
    draw(left_arm, shader, "normal_wide")
    draw(left_arm, shader, "normal_slim")

    if (skinShowArmor1) then
        draw(head, shader, "armor1")
        draw(torso, shader, "armor1")
        draw(right_leg, shader, "armor1")
        draw(left_leg, shader, "armor1")
        draw(right_arm, shader, "armor1")
        draw(left_arm, shader, "armor1")
    end
    if (skinShowArmor2) then
        draw(head, shader, "armor2")
        draw(torso, shader, "armor2")
        draw(right_leg, shader, "armor2")
        draw(left_leg, shader, "armor2")
        draw(right_arm, shader, "armor2")
        draw(left_arm, shader, "armor2")
    end

    if (skinImage) then
        local mx, my = love.mouse.getPosition()
        if (mx <= 128 + 8 and my <= 128 + 32 + 8 and not love.mouse.getRelativeMode()) then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.1)
        end

        love.graphics.draw(skinImage, 0, 32, 0, 2, 2)
    end

    local textHeight = love.graphics.getFont():getHeight()
    local text = ""
    text = text .. "refresh (r): " .. tostring(skinRefresh) .. "\n"
    text = text .. "slim (t): " .. tostring(skinIsSlim) .. "\n"
    text = text .. "lighting (y): " .. tostring(skinLighting) .. "\n"
    text = text .. "head look (f): " .. tostring(skinLook) .. "\n"
    text = text .. "walk (g): " .. tostring(player.speed) .. "/" .. tostring(player.targetSpeed) .. "\n"
    text = text .. "armor layer 1 (c): " .. tostring(skinShowArmor1) .. "\n"
    text = text .. "armor layer 2 (v): " .. tostring(skinShowArmor2) .. "\n"

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("v1", love.graphics.getWidth() - 24, love.graphics.getHeight() - 24)
    love.graphics.print("you can drag and drop a PNG file to this window, or edit 'skin.png'", 300, 0)

    love.graphics.print(text, 10, love.graphics.getHeight() - textHeight * 7 - 10)
end
