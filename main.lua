-- Local lua debugger
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start(); end

local g3d = require "g3d"
local shader = love.graphics.newShader(g3d.shaderpath, "assets/shader.glsl")

local dir = love.filesystem.getSourceBaseDirectory()
local success = love.filesystem.mount(dir, "root")
print("trying to mount base directory:", success)

local font = nil

local skinIsSlim = false
local skinRefresh = true
local skinLighting = true
local skinLook = false
local skinShowArmor1 = false
local skinShowArmor2 = false

local uiHidden = false

local skinImage = nil
local skinArmor1Image = nil
local skinArmor2Image = nil
local capeImage = nil

local fps = {}
fps.mx = 0
fps.my = 0
fps.dx = 0
fps.dy = 0
fps.sensitivity = 0.0066
fps.speed = 4.5
fps.yaw = 0
fps.pitch = 0
fps.curTime = 0

local player = {}
player.headRotY = 0
player.headRotZ = 0
player.movementType = 0
player.sneaking = false
player.currentSpeed = 0
player.acceleration = 0.098
player.friction = 0.546
player.swing = 0
player.setAnimation = function(index)
    if (player.animations[index]) then
        player.animationIndex = index
        
        local animation = player.animations[index]
        for partKey,partValue in pairs(animation) do
            local part = player.parts[partKey]
            if (part) then
                local pos = partValue.pos
                local rot = partValue.rot
                
                if (partValue.parent) then
                    local parentPos = animation[partValue.parent].pos or {0, 0, 0}
                    local parentRot = animation[partValue.parent].rot or {0, 0, 0}

                    if (pos) then
                        -- figure out math to translate it properly with parent's rotation
                        -- later

                        pos = {pos[1] + parentPos[1],pos[2] + parentPos[2],pos[3] + parentPos[3]}
                    end
                    if (rot) then
                        rot = {rot[1] + parentRot[1],rot[2] + parentRot[2],rot[3] + parentRot[3]}
                    end
                end
                
                if (pos) then
                    setTranslation(part, pos[1], pos[2], pos[3], partValue.key)
                end
                if (rot) then
                    setRotation(part, rot[1], rot[2], rot[3], partValue.key)
                end
            end
        end
    end
end
player.animationIndex = 1
player.animations = {
    -- idle
    {
        head = {
            parent = "torso",
            pos = {0, 0, 0.75},
            rot = {0, 0, 0},
        },
        torso = {
            pos = {0, 0, 0.75},
            rot = {0, 0, 0},
        },
        right_leg = {
            pos = {0.001, -0.125 + 0.005, 0.75},
            rot = {0, 0, 0},
        },
        left_leg = {
            pos = {0.001, 0.125 - 0.005, 0.75},
            rot = {0, 0, 0},
        },
        right_arm = {
            parent = "torso",
            pos = {0, -0.375, 0.0625 * 10},
            rot = {0, 0, 0},
        },
        left_arm = {
            parent = "torso",
            pos = {0, 0.375, 0.0625 * 10},
            rot = {0, 0, 0},
        },
        cape = {
            parent = "torso",
            pos = {0.0625 * 2, 0, 0.0625 * 12},
            rot = {0, 0, 0},
        },
        elytra_right = {
            parent = "torso",
            pos = {0.0625 * 2, 0.0625 * 4.5, 0.0625 * (6 + 6)},
            rot = {math.rad(15), math.rad(-10), math.rad(-5)},
        },
        elytra_left = {
            parent = "torso",
            pos = {0.0625 * 2, 0.0625 * -4.5, 0.0625 * (6 + 6)},
            rot = {math.rad(-15), math.rad(-10), math.rad(5)},
        },
    },
}

player.showParts = {
    ["head"] = {
        ["all"] = true,
        ["normal"] = true,
        ["armor1"] = false,
        ["armor2"] = false,
    },
    ["torso"] = {
        ["all"] = true,
        ["normal"] = true,
        ["armor1"] = false,
        ["armor2"] = false,
    },
    ["right_leg"] = {
        ["all"] = true,
        ["normal"] = true,
        ["armor1"] = false,
        ["armor2"] = false,
    },
    ["left_leg"] = {
        ["all"] = true,
        ["normal"] = true,
        ["armor1"] = false,
        ["armor2"] = false,
    },
    ["right_arm"] = {
        ["all"] = true,
        ["normal"] = true,
        ["armor1"] = false,
        ["armor2"] = false,
    },
    ["left_arm"] = {
        ["all"] = true,
        ["normal"] = true,
        ["armor1"] = false,
        ["armor2"] = false,
    },
    ["elytra_right"] = {
        ["all"] = false,
        ["normal"] = true,
    },
    ["elytra_left"] = {
        ["all"] = false,
        ["normal"] = true,
    },
    ["cape"] = {
        ["all"] = false,
        ["normal"] = true,
    },
}

player.parts = {}
player.parts.head = {}
player.parts.torso = {}
player.parts.right_leg = {}
player.parts.left_leg = {}
player.parts.right_arm = {}
player.parts.left_arm = {}
player.parts.elytra_right = {}
player.parts.elytra_left = {}
player.parts.cape = {}

function updateSkinTexture(imageData, imagePath)
    local r,g,b,a = imageData:getPixel(math.min(51, imageData:getWidth() - 1), math.min(16, imageData:getHeight() - 1))
    skinIsSlim = a <= 0.5
    refreshSlimWide()

    skinImage = love.graphics.newImage(imageData)
    skinImage:setFilter("nearest", "nearest")

    setTexture(player.parts.head, skinImage, "normal")
    setTexture(player.parts.torso, skinImage, "normal")
    setTexture(player.parts.right_arm, skinImage, "normal")
    setTexture(player.parts.left_arm, skinImage, "normal")
    setTexture(player.parts.left_leg, skinImage, "normal")
    setTexture(player.parts.right_leg, skinImage, "normal")
end

function setTranslation(models, x, y, z, key)
    for k,model in pairs(models) do
        if (not key or (key and k == key)) then
            if (model) then
                model:setTranslation(x, y, z)
            end
        end
    end
end
function setRotation(models, rx, ry, rz, key)
    for k,model in pairs(models) do
        if (not key or (key and k == key)) then
            if (model) then
                model:setRotation(rx, ry, rz)
            end
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
function offsetRotation(key, rx, ry, rz)
    local anim = player.animations[player.animationIndex][key]
    if (anim) then
        setRotation(player.parts[key], anim.rot[1] + rx, anim.rot[2] + ry, anim.rot[3] + rz)
    end
end

function refreshSlimWide()
    if (skinIsSlim) then
        player.parts.right_arm.normal = g3d.newModel("assets/right_arm_slim.obj", skinImage)
        player.parts.left_arm.normal = g3d.newModel("assets/left_arm_slim.obj", skinImage)
    else
        player.parts.right_arm.normal = g3d.newModel("assets/right_arm_wide.obj", skinImage)
        player.parts.left_arm.normal = g3d.newModel("assets/left_arm_wide.obj", skinImage)
    end

    player.setAnimation(player.animationIndex)
end

function love.load()
    font = love.graphics.newFont(12 + 4)
    love.graphics.setFont(font)

    if (love.filesystem.getInfo("sensitivity.txt")) then
        print("sensitivity file found, reading...")
        
        local sensitivityFile = love.filesystem.read("sensitivity.txt")
        fps.sensitivity = tonumber(sensitivityFile)
    else
        print("sensitivity file not found")
    end

    local errorData = love.image.newImageData(2, 2)
    errorData:mapPixel(function(x,y,r,g,b,a)
        if (x == 0 and y == 0 or x == 1 and y == 1) then
            return 1,0,1,1
        else
            return 0,0,0,1
        end
    end)

    local errorImage = love.graphics.newImage(errorData)

    player.parts.head.normal = g3d.newModel("assets/head.obj", nil)
    player.parts.torso.normal = g3d.newModel("assets/torso.obj", nil)
    
    player.parts.head.armor2 = g3d.newModel("assets/head_armor2.obj", nil)
    player.parts.torso.armor1 = g3d.newModel("assets/torso_armor1.obj", nil)
    player.parts.torso.armor2 = g3d.newModel("assets/torso_armor2.obj", nil)

    player.parts.right_leg.normal = g3d.newModel("assets/right_leg.obj", nil)
    player.parts.left_leg.normal = g3d.newModel("assets/left_leg.obj", nil)

    player.parts.right_leg.armor1 = g3d.newModel("assets/right_leg_armor1.obj", nil)
    player.parts.right_leg.armor2 = g3d.newModel("assets/right_leg_armor2.obj", nil)
    player.parts.left_leg.armor1 = g3d.newModel("assets/left_leg_armor1.obj", nil)
    player.parts.left_leg.armor2 = g3d.newModel("assets/left_leg_armor2.obj", nil)
    player.parts.right_arm.armor1 = g3d.newModel("assets/right_arm_armor1.obj", nil)
    player.parts.right_arm.armor2 = g3d.newModel("assets/right_arm_armor2.obj", nil)
    player.parts.left_arm.armor1 = g3d.newModel("assets/left_arm_armor1.obj", nil)
    player.parts.left_arm.armor2 = g3d.newModel("assets/left_arm_armor2.obj", nil)

    player.parts.elytra_right.normal = g3d.newModel("assets/elytra_right_wing.obj", nil)
    player.parts.elytra_left.normal = g3d.newModel("assets/elytra_left_wing.obj", nil)

    player.parts.cape.normal = g3d.newModel("assets/cape.obj", nil)
    setTexture(player.parts.head, errorImage)
    setTexture(player.parts.torso, errorImage)
    setTexture(player.parts.right_leg, errorImage)
    setTexture(player.parts.left_leg, errorImage)
    setTexture(player.parts.right_arm, errorImage)
    setTexture(player.parts.left_arm, errorImage)
    setTexture(player.parts.elytra_left, errorImage)
    setTexture(player.parts.elytra_right, errorImage)
    setTexture(player.parts.cape, errorImage)
    refreshSlimWide()

    g3d.camera.lookInDirection(-4, 0, 1.62, 0, 0)
    g3d.camera.fov = math.rad(70)
    g3d.camera.updateProjectionMatrix()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    
    player.setAnimation(1)
end
function love.quit()
    print("saving sensitivity...")
    local success, message = love.filesystem.write("sensitivity.txt", tostring(fps.sensitivity))
    if (success) then
        print("saved sensitivity: " .. tostring(fps.sensitivity))
    else
        print("error saving sensitivity: " .. message)
    end
end

function love.update(dt)
    fps.curTime = fps.curTime + dt

    if (true) then
        player.currentSpeed = player.currentSpeed * player.friction
        if (player.currentSpeed <= 0.0001) then
            player.currentSpeed = 0.0
        end

        if (player.movementType == 1) then
            player.currentSpeed = player.currentSpeed + player.acceleration
        elseif (player.movementType == 2) then
            player.currentSpeed = player.currentSpeed + player.acceleration * 1.30
        end
    end

    player.swing = player.swing + player.currentSpeed

    -- walk animation
    local swingArmAngle = math.rad(45)
    local swingLegAngle = math.rad(60)
    local swingTargetPlayerSpeed = 0.2
    local swingStrength = player.currentSpeed / swingTargetPlayerSpeed
    local swingLeft = math.sin(player.swing) * swingStrength
    local swingRight = math.sin(player.swing + math.pi) * swingStrength
    
    -- arms idle
    local armIdleAngle = math.rad(5)
    local idleLeftSin = (math.sin(fps.curTime) * 0.5 + 0.5) * armIdleAngle
    local idleLeftCos = (math.cos(fps.curTime + 1)) * armIdleAngle
    local idleRightSin = (math.sin(fps.curTime + math.pi * 1.65) * 0.5 - 0.5) * armIdleAngle
    local idleRightCos = (math.cos(fps.curTime + 1 + math.pi * 1.65)) * armIdleAngle

    if (skinLook) then
        if (not love.mouse.getRelativeMode()) then
            fps.mx = love.mouse.getX()
            fps.my = love.mouse.getY()
        end

        love.mouse.setRelativeMode(true)

        if (fps.dmove) then
            fps.dmove = false

            player.headRotZ = player.headRotZ - fps.dx * fps.sensitivity
            player.headRotY = math.max(math.min(player.headRotY - fps.dy * fps.sensitivity, math.pi * 0.5), math.pi * -0.5)
        end

        player.headRotY = math.max(math.min(player.headRotY, math.pi * 0.5), -math.pi * 0.5)
        player.headRotZ = math.max(math.min(player.headRotZ, math.pi * 0.5), -math.pi * 0.5)
    end
    
    -- offset parts from base animation
    offsetRotation("right_arm", idleRightSin, idleRightCos + swingLeft * swingArmAngle, 0)
    offsetRotation("left_arm", idleLeftSin, idleLeftCos + swingRight * swingArmAngle, 0)
    offsetRotation("right_leg", 0, swingRight * swingLegAngle, 0)
    offsetRotation("left_leg", 0, swingLeft * swingLegAngle, 0)
    offsetRotation("head", 0, player.headRotY, player.headRotZ)
    offsetRotation("cape", 0, (-math.pi * 0.5) * (player.currentSpeed / 0.3), 0)

    -- camera
    if (skinLook) then
        return
    end

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
function love.wheelmoved(dx, dy)
    local amount = dy > 0 and 1 or -1
    fps.sensitivity = fps.sensitivity + amount * 0.001
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
        player.movementType = (player.movementType + 1) % 3
    elseif (key == "c") then
        player.showParts.head.armor1 = not player.showParts.head.armor1
        player.showParts.torso.armor1 = not player.showParts.torso.armor1
        player.showParts.right_leg.armor1 = not player.showParts.right_leg.armor1
        player.showParts.left_leg.armor1 = not player.showParts.left_leg.armor1
        player.showParts.right_arm.armor1 = not player.showParts.right_arm.armor1
        player.showParts.left_arm.armor1 = not player.showParts.left_arm.armor1
        skinShowArmor1 = player.showParts.head.armor1
    elseif (key == "v") then
        player.showParts.head.armor2 = not player.showParts.head.armor2
        player.showParts.torso.armor2 = not player.showParts.torso.armor2
        player.showParts.right_leg.armor2 = not player.showParts.right_leg.armor2
        player.showParts.left_leg.armor2 = not player.showParts.left_leg.armor2
        player.showParts.right_arm.armor2 = not player.showParts.right_arm.armor2
        player.showParts.left_arm.armor2 = not player.showParts.left_arm.armor2
        skinShowArmor2 = player.showParts.head.armor2
    elseif (key == "f1") then
        uiHidden = not uiHidden
    elseif (tonumber(key) or string.sub(key, 1, 2) == "kp") then
        local num = tonumber(key) or tonumber(string.sub(key, 3))
        local nums = {}
        nums[1] = "head"
        nums[2] = "torso"
        nums[3] = "right_arm"
        nums[4] = "left_arm"
        nums[5] = "right_leg"
        nums[6] = "left_leg"
        nums[7] = "cape"

        if (nums[num]) then
            player.showParts[nums[num]].all = not player.showParts[nums[num]].all
        end
        if (num == 8) then
            player.showParts["elytra_left"].all = not player.showParts["elytra_left"].all
            player.showParts["elytra_right"].all = not player.showParts["elytra_right"].all
        end
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

            local capePath = path .. "cape.png"
            local cape = love.filesystem.getInfo(capePath)
            local armor1Path = path .. "armor_leggings.png"
            local armor1 = love.filesystem.getInfo(armor1Path)
            local armor2Path = path .. "armor.png"
            local armor2 = love.filesystem.getInfo(armor2Path)
            
            if (cape) then
                capeImage = love.graphics.newImage(capePath)
                setTexture(player.parts.cape, capeImage)
                setTexture(player.parts.elytra_right, capeImage)
                setTexture(player.parts.elytra_left, capeImage)
            end
            if (armor1) then
                skinArmor1Image = love.graphics.newImage(armor1Path)
                setTexture(player.parts.right_arm, skinArmor1Image, "armor1")
                setTexture(player.parts.left_arm, skinArmor1Image, "armor1")
                setTexture(player.parts.right_leg, skinArmor1Image, "armor1")
                setTexture(player.parts.left_leg, skinArmor1Image, "armor1")
                setTexture(player.parts.torso, skinArmor1Image, "armor1")
                setTexture(player.parts.head, skinArmor1Image, "armor1")
            end
            if (armor2) then
                skinArmor2Image = love.graphics.newImage(armor2Path)
                setTexture(player.parts.right_arm, skinArmor2Image, "armor2")
                setTexture(player.parts.left_arm, skinArmor2Image, "armor2")
                setTexture(player.parts.right_leg, skinArmor2Image, "armor2")
                setTexture(player.parts.left_leg, skinArmor2Image, "armor2")
                setTexture(player.parts.torso, skinArmor2Image, "armor2")
                setTexture(player.parts.head, skinArmor2Image, "armor2")
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
    shader:send("lightColor", {1, 1, 1})
    shader:send("ambientColor", {0.5, 0.5, 0.5})
    
    for showKey, showValue in pairs(player.showParts) do
        if (type(showValue) == "table") then
            for showSubKey, showSubValue in pairs(showValue) do
                if (showSubValue == true and showValue.all ~= false) then
                    draw(player.parts[showKey], shader, showSubKey)
                end
            end
        elseif (showValue == true) then
            draw(player.parts[showKey], shader)
        end
    end

    if (uiHidden) then
        local uiHiddenText = "- ui hidden (f1) -"
        local uiHiddenTextWidth = font:getWidth(uiHiddenText)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.print(uiHiddenText, love.graphics.getWidth() * 0.5 - uiHiddenTextWidth * 0.5, love.graphics.getHeight() - 32)
        return
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

    local textHeight = font:getHeight() + 4
    local controlsX = 24
    local controlsY = love.graphics.getHeight() - 16
    local controls = {
        {text = "refresh", key = "r", value = skinRefresh},
        {text = "slim", key = "t", value = skinIsSlim},
        {text = "lighting", key = "y", value = skinLighting},
        {text = "head look", key = "f", toggled = skinLook, value = skinLook},
        {text = "walk", key = "g", value = player.movementType},
        {text = "armor layer 1", key = "c", value = skinShowArmor1},
        {text = "armor layer 2", key = "v", value = skinShowArmor2},
        {text = "sensitivity", key = "mouse wheel", value = fps.sensitivity},
    }
    
    for i=1, #controls do
        local control = controls[i]
        local textStart = control.text .. " (" .. control.key .. "): "
        local textValue = tostring(control.value)
        local textWidthStart = font:getWidth(textStart)
        local textWidthValue = font:getWidth(textValue)
        local textColorValue = {1, 1, 1, 1}
        
        if (control.value == false) then
            textColorValue = {1, 0.25, 0.25, 1}
        elseif (control.value == true) then
            textColorValue = {0.25, 1, 1, 1}
        else
            textColorValue = {1, 1, 1, 1}
        end

        if (control.toggled) then
            local textWidth = textWidthStart + textWidthValue
            local hPadding = 10
            local vPadding = 1

            love.graphics.setColor(0, 0.5, 0.5, 1)
            love.graphics.rectangle("fill", controlsX - hPadding, controlsY - textHeight * i - vPadding, textWidth + hPadding * 2, textHeight + vPadding * 2)
        end
        
        love.graphics.setColor(0, 0, 0, 0.5)
        for sx=0,2 do
            for sy=0,2 do
                love.graphics.print(textStart, sx + controlsX, sy + controlsY - textHeight * i)
                love.graphics.print(textValue, sx + controlsX + textWidthStart, sy + controlsY - textHeight * i)
            end
        end

        love.graphics.setColor(0.75, 0.75, 0.75, 1)
        love.graphics.print(textStart, controlsX, controlsY - textHeight * i)
        love.graphics.setColor(textColorValue)
        love.graphics.print(textValue, controlsX + textWidthStart, controlsY - textHeight * i)
    end

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("v4", love.graphics.getWidth() - 32, love.graphics.getHeight() - 32)

    local dragNDropText = "drag and drop a PNG file, or edit 'skin.png'"
    local dragNDropTextWidth = font:getWidth(dragNDropText)

    love.graphics.setColor(0, 0, 0, 0.5)
    for sx=0,2 do
        for sy=0,2 do
            love.graphics.print(dragNDropText, sx + love.graphics.getWidth() * 0.5 - dragNDropTextWidth * 0.5, sy)
        end
    end
    love.graphics.setColor(0.75, 0.75, 0.75, 1)
    love.graphics.print(dragNDropText, love.graphics.getWidth() * 0.5 - dragNDropTextWidth * 0.5, 0)
end