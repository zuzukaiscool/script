-- ModernMenu_UI_with_ESP_KillAll_Enhanced.lua
-- Combined LocalScript: Enhanced UI + ESP & Kill All (teleport + knife backstab)
-- Integrates Montserrat font, rich text, UIStroke, hover effects, responsive text, fade-out
-- Fixes Kill All with robust knife detection, fallback teleport, and multiple stab methods
-- Optimized for Velocity Executor, retains ESP, FOV, Speed Hack, Infinite Jump
-- Extensive debug logging for Arsenal compatibility

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Debug function
local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- FPS monitoring
local lastFrameTime = tick()
local function checkFPS()
    local currentTime = tick()
    local fps = math.floor(1 / (currentTime - lastFrameTime))
    lastFrameTime = currentTime
    return fps
end

-- ========== STATE ==========
local STATE = {
    uiOpen = true,
    espEnabled = false,
    espRGB = false,
    espColor = Color3.fromRGB(255, 0, 0),
    aimbotEnabled = false,
    aimPart = "Head",
    showFOV = false,
    fovPercent = 25,
    killAllEnabled = false,
    speedHackEnabled = false,
    infJumpEnabled = false,
    speedValue = 100,
}

getgenv().CHEAT_UI_STATE = STATE

-- ========== UI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernCheatStyleMenu"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 1000000
screenGui.Enabled = STATE.uiOpen
screenGui.ScreenInsets = Enum.ScreenInsets.None
screenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
debugPrint("ScreenGui created and parented to CoreGui")

-- Notifications
local notifFrame = Instance.new("Frame")
notifFrame.AnchorPoint = Vector2.new(0, 1)
notifFrame.Position = UDim2.new(0, 12, 1, -12)
notifFrame.Size = UDim2.new(0, 280, 0, 30)
notifFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notifFrame.BackgroundTransparency = 0.3
notifFrame.BorderSizePixel = 0
notifFrame.Visible = true
notifFrame.Parent = screenGui
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 10)

local notifLabel = Instance.new("TextLabel")
notifLabel.BackgroundTransparency = 1
notifLabel.Size = UDim2.new(1, -14, 1, 0)
notifLabel.Position = UDim2.new(0, 7, 0, 0)
notifLabel.Text = ""
notifLabel.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
notifLabel.TextSize = 15 * screenGui.AbsoluteSize.X / 1600
notifLabel.TextXAlignment = Enum.TextXAlignment.Left
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextStrokeTransparency = 0
notifLabel.Parent = notifFrame

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    notifLabel.TextSize = 15 * screenGui.AbsoluteSize.X / 1600
end)

local function notify(text)
    debugPrint("Notification: " .. text)
    notifLabel.TextTransparency = 0
    notifFrame.BackgroundTransparency = 0.3
    notifLabel.Text = text
    TweenService:Create(notifFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
    task.delay(2, function()
        TweenService:Create(notifLabel, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
        TweenService:Create(notifFrame, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
    end)
end

-- Main window
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(360, 260)
main.Position = UDim2.new(0.5, -180, 0.5, -130)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BackgroundTransparency = 0.3
main.BorderSizePixel = 0
main.Active = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 1
mainStroke.Parent = main
debugPrint("Main frame created with UIStroke")

-- Glow
local glow = Instance.new("ImageLabel")
glow.Size = UDim2.new(1, 30, 1, 30)
glow.Position = UDim2.new(0, -15, 0, -15)
glow.BackgroundTransparency = 1
glow.Image = "rbxassetid://4994315734"
glow.ImageColor3 = Color3.fromRGB(120, 0, 255)
glow.ImageTransparency = 0.75
glow.ScaleType = Enum.ScaleType.Fit
glow.ZIndex = 0
glow.Parent = main

-- Header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -16, 0, 36)
header.Position = UDim2.new(0, 8, 0, 6)
header.BackgroundTransparency = 1
header.Text = '<u>Nebula <font color="rgb(120, 0, 255)">Overlay</font></u>'
header.RichText = true
header.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
header.TextSize = 20 * screenGui.AbsoluteSize.X / 1600
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.TextStrokeTransparency = 0
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = main
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    header.TextSize = 20 * screenGui.AbsoluteSize.X / 1600
end)

-- Dragging
do
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.Position = UDim2.new(0, 8, 0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
tabBar.BorderSizePixel = 0
tabBar.Parent = main
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local function mkTabButton(text, xScale)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.333, -4, 1, -8)
    b.Position = UDim2.new(xScale, 2, 0, 4)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    b.TextColor3 = Color3.fromRGB(230, 230, 245)
    b.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
    b.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    b.AutoButtonColor = true
    b.Parent = tabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(168, 168, 168)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(230, 230, 245)}):Play()
    end)
    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        b.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    end)
    return b
end

local aimbotTabBtn = mkTabButton("Aimbot", 0)
local visualsTabBtn = mkTabButton("Visuals", 0.333)
local cheatsTabBtn = mkTabButton("Cheats", 0.666)

-- Content area
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -96)
content.Position = UDim2.new(0, 8, 0, 86)
content.BackgroundTransparency = 1
content.Parent = main

-- UI helpers
local function setToggleVisual(btn, on)
    btn.BackgroundColor3 = on and Color3.fromRGB(230, 230, 255) or Color3.fromRGB(40, 40, 52)
    btn.TextColor3 = on and Color3.fromRGB(10, 10, 20) or Color3.fromRGB(230, 230, 245)
end

local function mkToggle(parent, text, y, stateKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    btn.Text = text
    btn.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
    btn.TextSize = 16 * screenGui.AbsoluteSize.X / 1600
    btn.TextColor3 = Color3.fromRGB(230, 230, 245)
    btn.TextStrokeTransparency = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    setToggleVisual(btn, STATE[stateKey])
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(168, 168, 168)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(230, 230, 245)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        STATE[stateKey] = not STATE[stateKey]
        setToggleVisual(btn, STATE[stateKey])
        notify(text .. " " .. (STATE[stateKey] and "Enabled" or "Disabled"))
        debugPrint("Toggled " .. stateKey .. " to " .. tostring(STATE[stateKey]))
    end)
    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        btn.TextSize = 16 * screenGui.AbsoluteSize.X / 1600
    end)
    return btn
end

local function mkDropdown(parent, label, y, cycleList, getIdx, setIdx)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.Position = UDim2.new(0, 0, 0, y)
    holder.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    holder.BorderSizePixel = 0
    holder.Parent = parent
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -36, 1, 0)
    txt.Position = UDim2.new(0, 12, 0, 0)
    txt.BackgroundTransparency = 1
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Text = label .. ": " .. tostring(cycleList[getIdx()])
    txt.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
    txt.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    txt.TextColor3 = Color3.fromRGB(230, 230, 245)
    txt.TextStrokeTransparency = 0
    txt.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.Position = UDim2.new(1, -32, 0.5, -13)
    btn.Text = "⟳"
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 66)
    btn.TextColor3 = Color3.fromRGB(230, 230, 245)
    btn.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
    btn.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    btn.Parent = holder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(168, 168, 168)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(230, 230, 245)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        local i = getIdx()
        i = i % #cycleList + 1
        setIdx(i)
        txt.Text = label .. ": " .. tostring(cycleList[i])
        debugPrint("Set " .. label .. " to " .. cycleList[i])
    end)
    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        txt.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
        btn.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    end)
    return btn
end

local function mkSlider(parent, label, y, defaultPercent, onChange)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 54)
    holder.Position = UDim2.new(0, 0, 0, y)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, 0, 0, 18)
    lab.Position = UDim2.new(0, 0, 0, 0)
    lab.BackgroundTransparency = 1
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Text = ("%s (%d%%)"):format(label, defaultPercent)
    lab.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
    lab.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    lab.TextColor3 = Color3.fromRGB(230, 230, 245)
    lab.TextStrokeTransparency = 0
    lab.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 10)
    bar.Position = UDim2.new(0, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(defaultPercent / 100, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(230, 230, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function updateFromX(x)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        local pct = math.clamp((x - abs) / w, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        local percentVal = math.floor(pct * 100 + 0.5)
        lab.Text = ("%s (%d%%)"):format(label, percentVal)
        onChange(percentVal)
        debugPrint("Set " .. label .. " to " .. percentVal .. "%")
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(i.Position.X)
        end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(i.Position.X)
        end
    end)
    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        lab.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    end)
end

-- HSV COLOR PICKER
local function hsvToColor3(h, s, v)
    return Color3.fromHSV(h, s, v)
end

local function mkHSVPicker(parent, yStart, initialColor, onColorChanged, onToggleRGB)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 140)
    container.Position = UDim2.new(0, 0, 0, yStart)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "ESP Color"
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)
    label.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.TextStrokeTransparency = 0
    label.Parent = container

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 36, 0, 36)
    preview.Position = UDim2.new(1, -40, 0, 0)
    preview.BackgroundColor3 = initialColor
    preview.BorderSizePixel = 0
    preview.Parent = container
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)

    local rgbBtn = Instance.new("TextButton")
    rgbBtn.Size = UDim2.new(0, 88, 0, 28)
    rgbBtn.Position = UDim2.new(1, -96, 0, 40)
    rgbBtn.Text = "RGB Mode"
    rgbBtn.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
    rgbBtn.TextSize = 13 * screenGui.AbsoluteSize.X / 1600
    rgbBtn.TextColor3 = Color3.fromRGB(10, 10, 20)
    rgbBtn.BackgroundColor3 = Color3.fromRGB(230, 230, 255)
    rgbBtn.Parent = container
    Instance.new("UICorner", rgbBtn).CornerRadius = UDim.new(0, 8)
    rgbBtn.MouseEnter:Connect(function()
        TweenService:Create(rgbBtn, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(168, 168, 168)}):Play()
    end)
    rgbBtn.MouseLeave:Connect(function()
        TweenService:Create(rgbBtn, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(10, 10, 20)}):Play()
    end)
    rgbBtn.MouseButton1Click:Connect(function()
        onToggleRGB()
        notify("ESP Color: " .. (STATE.espRGB and "RGB" or "Static"))
        debugPrint("Toggled RGB Mode to " .. tostring(STATE.espRGB))
    end)
    screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        label.TextSize = 14 * screenGui.AbsoluteSize.X / 1600
        rgbBtn.TextSize = 13 * screenGui.AbsoluteSize.X / 1600
    end)

    local hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(1, -110, 0, 14)
    hueBar.Position = UDim2.new(0, 0, 0, 40)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = container
    Instance.new("UICorner", hueBar).CornerRadius = UDim.new(1, 0)

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)),
        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(1/6, 1, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(2/6, 1, 1)),
        ColorSequenceKeypoint.new(0.50, Color3.fromHSV(3/6, 1, 1)),
        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(4/6, 1, 1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(5/6, 1, 1)),
        ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
    }
    hueGrad.Rotation = 0
    hueGrad.Parent = hueBar

    local svSquare = Instance.new("Frame")
    svSquare.Size = UDim2.new(1, -110, 0, 70)
    svSquare.Position = UDim2.new(0, 0, 0, 60)
    svSquare.BorderSizePixel = 0
    svSquare.Parent = container
    Instance.new("UICorner", svSquare).CornerRadius = UDim.new(0, 6)

    local satGrad = Instance.new("UIGradient")
    satGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
    }
    satGrad.Rotation = 0
    satGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }
    satGrad.Parent = svSquare

    local valGrad = Instance.new("UIGradient")
    valGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
    }
    valGrad.Rotation = 90
    valGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    }
    valGrad.Parent = svSquare

    local hueMarker = Instance.new("Frame")
    hueMarker.Size = UDim2.new(0, 2, 1, 0)
    hueMarker.BackgroundColor3 = Color3.new(1, 1, 1)
    hueMarker.BorderSizePixel = 0
    hueMarker.Parent = hueBar

    local svMarker = Instance.new("Frame")
    svMarker.Size = UDim2.new(0, 8, 0, 8)
    svMarker.BackgroundColor3 = Color3.new(1, 1, 1)
    svMarker.BorderSizePixel = 0
    svMarker.AnchorPoint = Vector2.new(0.5, 0.5)
    svMarker.Parent = svSquare
    Instance.new("UICorner", svMarker).CornerRadius = UDim.new(1, 0)

    local H, S, V = Color3.toHSV(initialColor)

    local function updateSVHue()
        svSquare.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
    end
    updateSVHue()

    local function applyColor()
        local col = hsvToColor3(H, S, V)
        preview.BackgroundColor3 = col
        onColorChanged(col)
    end
    applyColor()

    local hueDragging = false
    local svDragging = false

    local function hueFromX(x)
        local abs = hueBar.AbsolutePosition.X
        local w = hueBar.AbsoluteSize.X
        local u = math.clamp((x - abs) / w, 0, 1)
        H = u
        hueMarker.Position = UDim2.new(u, -1, 0, 0)
        updateSVHue()
        applyColor()
    end

    local function svFromXY(x, y)
        local abs = svSquare.AbsolutePosition
        local sz = svSquare.AbsoluteSize
        local u = math.clamp((x - abs.X) / sz.X, 0, 1)
        local v = math.clamp((y - abs.Y) / sz.Y, 0, 1)
        S = u
        V = 1 - v
        svMarker.Position = UDim2.new(u, 0, 1 - v, 0)
        applyColor()
    end

    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = true
            hueFromX(i.Position.X)
        end
    end)
    hueBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = false
        end
    end)

    svSquare.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = true
            svFromXY(i.Position.X, i.Position.Y)
        end
    end)
    svSquare.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if hueDragging then hueFromX(i.Position.X) end
            if svDragging then svFromXY(i.Position.X, i.Position.Y) end
        end
    end)
end

-- AIMBOT TAB
local function buildAimbotTab()
    content:ClearAllChildren()
    mkToggle(content, "Toggle Aimbot", 0, "aimbotEnabled")
    local parts = {"Head", "Chest", "Legs"}
    local idx = table.find(parts, STATE.aimPart) or 1
    mkDropdown(content, "Target", 44, parts,
        function() return idx end,
        function(i) idx = i; STATE.aimPart = parts[i] end
    )
    mkToggle(content, "Show FOV Circle", 88, "showFOV")
    mkSlider(content, "FOV Size", 132, STATE.fovPercent, function(pct)
        STATE.fovPercent = pct
    end)
end

-- VISUALS TAB
local function buildVisualsTab()
    content:ClearAllChildren()
    mkToggle(content, "Toggle ESP", 0, "espEnabled")
    mkHSVPicker(content, 44, STATE.espColor,
        function(col)
            STATE.espColor = col
            STATE.espRGB = false
            notify("ESP Color Set")
        end,
        function()
            STATE.espRGB = not STATE.espRGB
            notify("ESP Color: " .. (STATE.espRGB and "RGB" or "Static"))
        end
    )
end

-- CHEATS TAB
local function buildCheatsTab()
    content:ClearAllChildren()
    mkToggle(content, "Kill All", 0, "killAllEnabled")
    mkToggle(content, "Speed Hack", 36, "speedHackEnabled")
    mkSlider(content, "Speed", 72, (STATE.speedValue / 100) * 100, function(pct)
        STATE.speedValue = math.floor(pct / 100 * 400 + 16)
    end)
    mkToggle(content, "Infinite Jump", 126, "infJumpEnabled")
end

-- TAB SWITCHING
local function selectTab(which)
    if which == "Aimbot" then
        aimbotTabBtn.BackgroundColor3 = Color3.fromRGB(72, 72, 94)
        visualsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        cheatsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        buildAimbotTab()
    elseif which == "Visuals" then
        visualsTabBtn.BackgroundColor3 = Color3.fromRGB(72, 72, 94)
        aimbotTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        cheatsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        buildVisualsTab()
    elseif which == "Cheats" then
        cheatsTabBtn.BackgroundColor3 = Color3.fromRGB(72, 72, 94)
        aimbotTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        visualsTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        buildCheatsTab()
    end
end

aimbotTabBtn.MouseButton1Click:Connect(function() selectTab("Aimbot") end)
visualsTabBtn.MouseButton1Click:Connect(function() selectTab("Visuals") end)
cheatsTabBtn.MouseButton1Click:Connect(function() selectTab("Cheats") end)
selectTab("Aimbot")

-- K TOGGLE with Fade-Out
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.K then
        debugPrint("K key pressed, toggling UI")
        STATE.uiOpen = not STATE.uiOpen
        if STATE.uiOpen then
            main.Size = UDim2.fromOffset(360, 260)
            main.BackgroundTransparency = 0.3
            screenGui.Enabled = true
            notify("Menu Opened")
        else
            TweenService:Create(main, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(), BackgroundTransparency = 1}):Play()
            task.wait(1)
            screenGui.Enabled = false
            notify("Menu Closed")
        end
    end
end)

-- J Key for Manual Kill All Trigger
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.J then
        debugPrint("J key pressed, triggering Kill All")
        notify("Manual Kill All Triggered")
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or (player.Team and player.Team == LocalPlayer.Team) then continue end
            stabPlayer(player)
            task.wait(1)
        end
    end
end)

-- ========== ESP & Aimbot Logic ==========
local DrawingMap = {}

local function safeRemove(obj)
    if obj and type(obj.Remove) == "function" then
        pcall(function() obj:Remove() end)
    end
end

local function createDrawingForModel(model)
    if not model or DrawingMap[model] then return end
    local sq = Drawing.new("Square")
    sq.Visible = false
    sq.Filled = false
    sq.Thickness = 2
    sq.Transparency = 1
    sq.Color = STATE.espColor
    sq.Size = Vector2.new(20, 40)
    sq.Position = Vector2.new(0, 0)
    DrawingMap[model] = { box = sq, lastValid = tick() }
    debugPrint("Created Drawing for model: " .. model.Name)
end

local function removeDrawingForModel(model)
    local t = DrawingMap[model]
    if not t then return end
    for _, v in pairs(t) do safeRemove(v) end
    DrawingMap[model] = nil
    debugPrint("Removed Drawing for model: " .. model.Name)
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(char)
        createDrawingForModel(char)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
    debugPrint("Added player to ESP: " .. player.Name)
end

for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
end

Players.PlayerAdded:Connect(addPlayer)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        removeDrawingForModel(player.Character)
    end
end)

local function getTargetPartForModel(model, aimPartName)
    if not model then return nil end
    local partMap = {
        Head = "Head",
        Chest = "UpperTorso",
        Legs = "LowerTorso"
    }
    local partName = partMap[aimPartName] or "HumanoidRootPart"
    local part = model:FindFirstChild(partName) or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if part then
        debugPrint("Selected part for " .. model.Name .. ": " .. part.Name)
    else
        debugPrint("No valid part found for " .. model.Name)
    end
    return part
end

local function computeTopBottom(model)
    if not model then return nil, nil, false end
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if not hrp then
        debugPrint("No HumanoidRootPart or BasePart for " .. model.Name)
        return nil, nil, false
    end
    local headPos = hrp.Position + Vector3.new(0, 2.5, 0)
    local bottomPos = hrp.Position - Vector3.new(0, 2.5, 0)
    local topScreen, topOn = Camera:WorldToViewportPoint(headPos)
    local bottomScreen, bottomOn = Camera:WorldToViewportPoint(bottomPos)
    if not (topOn and bottomOn) then
        debugPrint("Model " .. model.Name .. " not on screen")
        return nil, nil, false
    end
    return Vector2.new(topScreen.X, topScreen.Y), Vector2.new(bottomScreen.X, bottomScreen.Y), true
end

local function getClosestTargetInFov()
    local vps = Camera.ViewportSize
    local center = Vector2.new(vps.X / 2, vps.Y / 2)
    local maxRadius = math.min(vps.X, vps.Y) * 0.5
    local radius = maxRadius * (STATE.fovPercent / 100)
    local best, bestDist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or (player.Team and player.Team == LocalPlayer.Team) then continue end
        local model = player.Character
        if model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
            local part = getTargetPartForModel(model, STATE.aimPart)
            if part and part:IsA("BasePart") then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local centerDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if centerDist <= radius and centerDist < bestDist then
                        bestDist = centerDist
                        best = model
                    end
                end
            end
        end
    end
    if best then
        debugPrint("Target selected: " .. best.Name .. " (" .. STATE.aimPart .. ")")
    else
        debugPrint("No valid target in FOV")
    end
    return best
end

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Filled = false
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Visible = false
debugPrint("FOV circle created")

local rightHeld = false
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = true
        debugPrint("Right mouse button pressed")
    end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = false
        debugPrint("Right mouse button released")
    end
end)

-- Kill All
local killAllConnection
local function findKnife()
    local knife
    -- Check Backpack
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name:lower():match("knife") or tool.Name:lower():match("melee") or tool:FindFirstChild("Handle") then
                knife = tool
                break
            end
        end
    end
    -- Check Character
    if not knife and LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():match("knife") or tool.Name:lower():match("melee") or tool:FindFirstChild("Handle")) then
            knife = tool
        end
    end
    -- Fallback: Any tool
    if not knife then
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                knife = tool
                break
            end
        end
    end
    if knife then
        debugPrint("Found knife: " .. knife.Name)
    else
        debugPrint("No knife or tool found")
    end
    return knife
end

local function stabPlayer(player)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        debugPrint("LocalPlayer has no valid character or HumanoidRootPart")
        return false
    end
    local myHrp = LocalPlayer.Character.HumanoidRootPart
    local targetModel = player.Character
    if not targetModel or not targetModel:FindFirstChild("Humanoid") or targetModel.Humanoid.Health <= 0 then
        debugPrint("Target " .. player.Name .. " has no valid character or is dead")
        return false
    end
    local targetHead = targetModel:FindFirstChild("Head") or targetModel:FindFirstChildWhichIsA("BasePart")
    if not targetHead then
        debugPrint("Target " .. player.Name .. " has no Head or BasePart")
        return false
    end
    local knife = findKnife()
    if not knife then
        debugPrint("Cannot stab: No knife available")
        return false
    end
    -- Equip knife
    pcall(function()
        LocalPlayer.Character.Humanoid:EquipTool(knife)
        debugPrint("Equipped knife: " .. knife.Name)
    end)
    -- Teleport behind head
    local targetCFrame = targetHead.CFrame
    local offset = targetCFrame.LookVector * -3 + Vector3.new(0, 1.5, 0) -- 3 studs behind, head height
    pcall(function()
        myHrp.CFrame = targetCFrame * CFrame.new(offset)
        debugPrint("Teleported to " .. player.Name .. "'s head (CFrame)")
    end)
    if myHrp.CFrame.Position ~= (targetCFrame * CFrame.new(offset)).Position then
        pcall(function()
            myHrp.Position = targetHead.Position + offset
            debugPrint("Teleported to " .. player.Name .. "'s head (Position fallback)")
        end)
    end
    -- Stab with multiple methods
    local stabbed = false
    pcall(function()
        local remoteNames = {"Fire", "Stab", "Attack", "Hit", "Melee"}
        for _, name in ipairs(remoteNames) do
            local remote = knife:FindFirstChild(name)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(targetHead.Position)
                debugPrint("Fired RemoteEvent: " .. name .. " at " .. player.Name)
                stabbed = true
                break
            end
        end
    end)
    if not stabbed then
        pcall(function()
            knife:Activate()
            debugPrint("Activated knife: " .. knife.Name .. " at " .. player.Name)
            stabbed = true
        end)
    end
    if not stabbed then
        pcall(function()
            VirtualUser:ClickButton1(Vector2.new())
            debugPrint("Simulated mouse click for " .. player.Name)
            stabbed = true
        end)
    end
    return stabbed
end

local function startKillAll()
    if killAllConnection then return end
    killAllConnection = RunService.Heartbeat:Connect(function()
        local fps = checkFPS()
        if fps < 20 then
            STATE.killAllEnabled = false
            stopKillAll()
            notify("Kill All disabled due to low FPS (" .. fps .. ")")
            debugPrint("Disabled Kill All due to FPS: " .. fps)
            return
        end
        if not STATE.killAllEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or (player.Team and player.Team == LocalPlayer.Team) then continue end
            if stabPlayer(player) then
                task.wait(1) -- Increased delay for anti-cheat
            end
        end
    end)
    debugPrint("Kill All enabled")
end

local function stopKillAll()
    if killAllConnection then
        killAllConnection:Disconnect()
        killAllConnection = nil
        debugPrint("Kill All disabled")
    end
end

local infJumpConnection = UserInputService.JumpRequest:Connect(function()
    if STATE.infJumpEnabled then
        pcall(function()
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end)
    end
end)

-- Render loop
RunService.RenderStepped:Connect(function()
    local fps = checkFPS()
    if fps < 20 then
        STATE.espEnabled = false
        notify("ESP disabled due to low FPS (" .. fps .. ")")
        debugPrint("Disabled ESP due to FPS: " .. fps)
    end

    local vps = Camera.ViewportSize
    local center = Vector2.new(vps.X / 2, vps.Y / 2)

    -- Update FOV circle
    if STATE.showFOV then
        fovCircle.Visible = true
        fovCircle.Position = center
        local maxRadius = math.min(vps.X, vps.Y) * 0.5
        fovCircle.Radius = maxRadius * (STATE.fovPercent / 100)
        debugPrint("FOV circle updated: radius=" .. fovCircle.Radius)
    else
        fovCircle.Visible = false
        debugPrint("FOV circle hidden")
    end

    -- Update ESP
    for model, tbl in pairs(DrawingMap) do
        local box = tbl.box
        if not box then continue end
        local player = Players:GetPlayerFromCharacter(model)
        if STATE.espEnabled and model and model.Parent and player and player ~= LocalPlayer and (not player.Team or player.Team ~= LocalPlayer.Team) and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
            local topV, bottomV, onScreen = computeTopBottom(model)
            if not onScreen then
                box.Visible = false
            else
                local height = math.max(16, math.abs(bottomV.Y - topV.Y))
                local width = math.max(18, height * 0.4)
                local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                local hrpScreen = hrp and Camera:WorldToViewportPoint(hrp.Position) or {X = topV.X}
                box.Position = Vector2.new(hrpScreen.X - width / 2, topV.Y)
                box.Size = Vector2.new(width, height)
                if STATE.espRGB then
                    local t = tick() * 2
                    local r = math.sin(t) * 127 + 128
                    local g = math.sin(t + 2) * 127 + 128
                    local b = math.sin(t + 4) * 127 + 128
                    box.Color = Color3.fromRGB(r, g, b)
                else
                    box.Color = STATE.espColor
                end
                box.Visible = true
                tbl.lastValid = tick()
            end
        else
            box.Visible = false
        end
    end

    -- Aimbot
    if STATE.aimbotEnabled and rightHeld then
        local targetModel = getClosestTargetInFov()
        if targetModel then
            local targetPart = getTargetPartForModel(targetModel, STATE.aimPart)
            if targetPart and targetPart:IsA("BasePart") then
                local camPos = Camera.CFrame.Position
                Camera.CFrame = CFrame.new(camPos, targetPart.Position)
                debugPrint("Aimbot: Aiming at " .. targetPart.Name)
            end
        end
    end

    -- Speed Hack
    if STATE.speedHackEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        pcall(function()
            LocalPlayer.Character.Humanoid.WalkSpeed = STATE.speedValue
        end)
    end

    -- Kill All
    if STATE.killAllEnabled then
        startKillAll()
    else
        stopKillAll()
    end
end)

Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        for m, _ in pairs(DrawingMap) do removeDrawingForModel(m) end
        pcall(function() fovCircle:Remove() end)
        stopKillAll()
        if infJumpConnection then infJumpConnection:Disconnect() end
    end
end)

notify("Enhanced Nebula Overlay loaded with fixed Kill All")
debugPrint("Script loaded successfully")