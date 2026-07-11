--[[
    ═══════════════════════════════════════════════════════════════
     Example Script — GuysModz Script Hub (Full Element Demo)
     Shows every UI element in the library + Auth + ESP + Aimbot
     
     Usage:
       local Library = loadstring(game:HttpGet("LIBRARY_URL"))()
       loadstring(game:HttpGet("EXAMPLE_URL"))()
    ═══════════════════════════════════════════════════════════════
]]

--═══════════════════════════════════════════════════════════════
-- 0. AUTH MODAL (Key System)
--═══════════════════════════════════════════════════════════════
-- Replace these keys with your own! Use a webhook or API to validate.
local ValidKeys = {
    "GuysModz-Beta-2024",
    "VIP-Access-1234",
    "Free-Key-GuysModz",
}

local AuthResult = false

local Auth = Library:CreateAuthModal({
    Title = "GuysModz Hub",
    Subtitle = "Enter your key to access all features.\nDon't have a key? Click Get Key below.",
    Placeholder = "Enter your key here...",
    ValidateKey = function(key)
        for _, valid in ipairs(ValidKeys) do
            if key == valid then return true end
        end
        return false
    end,
    OnSuccess = function(key)
        AuthResult = true
        Library:Notify("Welcome!", "Key accepted. Loading GuysModz Hub...")
    end,
    OnFail = function(reason)
        if reason == "locked" then
            Library:Notify("Locked", "Too many failed attempts.")
        end
    end,
    MaxAttempts = 5,
    SaveKey = true,
    KeyFileName = "GuysModzHubKey",
    GetKeyLink = "https://link-to-get-key.com",
})

-- Wait for auth to complete
while not AuthResult do task.wait(0.5) end
task.wait(0.5)

--═══════════════════════════════════════════════════════════════
-- 1. LOADING SCREEN
--═══════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

Library:CreateLoadingScreen("Loading GuysModz Hub...", 2.5)
task.wait(2.5)

--═══════════════════════════════════════════════════════════════
-- 2. WATERMARK + STATS
--═══════════════════════════════════════════════════════════════
local Watermark = Library:CreateWatermark("GuysModz Hub v1.0")
local StatsDisplay = Library:CreateStatsDisplay()

--═══════════════════════════════════════════════════════════════
-- 3. MAIN WINDOW
--═══════════════════════════════════════════════════════════════
local Window = Library:CreateWindow("GuysModz Hub")

--═══════════════════════════════════════════════════════════════
-- TAB 1: MAIN — Player controls
--═══════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main")

MainTab:CreateLabel("Player Settings")
MainTab:CreateBadge("Core Features", Color3.fromRGB(80, 120, 255))

MainTab:CreateSlider("Walk Speed", 16, 500, 16, function(value)
    local p = game.Players.LocalPlayer
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        p.Character.Humanoid.WalkSpeed = value
    end
end, "Set your walk speed", 0)

MainTab:CreateSlider("Jump Power", 50, 500, 50, function(value)
    local p = game.Players.LocalPlayer
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        p.Character.Humanoid.JumpPower = value
    end
end, "Set your jump power")

MainTab:CreateNumberBox("Custom FOV", 70, function(value)
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = value end
end, "Set camera field of view")

MainTab:CreateToggle("Inf Jump", false, function(state)
    if state then
        _G.GM_InfJump = true
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if _G.GM_InfJump then
                local p = game.Players.LocalPlayer
                if p.Character and p.Character:FindFirstChild("Humanoid") then
                    p.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        _G.GM_InfJump = false
    end
end, "Jump infinitely")

MainTab:CreateSeparator()

MainTab:CreateLabel("Actions")
MainTab:CreateButton("Reset Character", function()
    local p = game.Players.LocalPlayer
    if p.Character then p.Character:BreakJoints() end
end, "Respawn your character")

MainTab:CreateButton("Copy Game ID", function()
    if setclipboard then
        setclipboard(tostring(game.GameId))
        Library:Notify("Copied!", "Game ID copied to clipboard.")
    end
end, "Copy the current game ID")

MainTab:CreateButton("Server Hop", function()
    Library:CreateConfirmationDialog(
        "Server Hop",
        "Are you sure you want to hop to a new server?",
        function()
            Library:Notify("Server Hop", "Looking for a new server...")
            -- Add your server hop logic here
        end
    )
end, "Join a different server")

--═══════════════════════════════════════════════════════════════
-- TAB 2: TELEPORT
--═══════════════════════════════════════════════════════════════
local TeleportTab = Window:CreateTab("Teleport")

TeleportTab:CreateLabel("Quick Teleport")

TeleportTab:CreateButton("TP to Spawn", function()
    local p = game.Players.LocalPlayer
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local spawn = workspace:FindFirstChild("SpawnLocation")
        if spawn then
            p.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        end
    end
end)

TeleportTab:CreateTextBox("Player Name to TP", function(text)
    local target = game.Players:FindFirstChild(text)
    local p = game.Players.LocalPlayer
    if target and target.Character and p.Character then
        p.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        Library:Notify("Teleported!", "Teleported to " .. text)
    else
        Library:Notify("Error", "Player not found!")
    end
end)

TeleportTab:CreateSearchBox("Search Players...", function(query)
    -- Filter player list based on search
    local results = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Name:lower():find(query:lower()) then
            table.insert(results, player.Name)
        end
    end
    -- You could update a dropdown here with results
end)

TeleportTab:CreateSeparator()
TeleportTab:CreateLabel("Player List")
TeleportTab:CreateDropdown("Select Player", (function()
    local names = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    return names
end)(), nil, function(selected)
    local target = game.Players:FindFirstChild(selected)
    local p = game.Players.LocalPlayer
    if target and target.Character and p.Character then
        p.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        Library:Notify("Teleported!", "Teleported to " .. selected)
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 3: VISUALS
--═══════════════════════════════════════════════════════════════
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateLabel("Lighting")
VisualsTab:CreateToggle("Fullbright", false, function(state)
    local light = game:GetService("Lighting")
    if state then
        light.Brightness = 2
        light.ClockTime = 14
        light.FogEnd = 100000
    else
        light.Brightness = 1
        light.FogEnd = 10000
    end
end)

VisualsTab:CreateDropdown("Time of Day", {"Morning", "Noon", "Evening", "Night"}, "Noon", function(selected)
    local times = { Morning = 6, Noon = 12, Evening = 18, Night = 0 }
    game:GetService("Lighting").ClockTime = times[selected] or 12
end)

VisualsTab:CreateSeparator()
VisualsTab:CreateLabel("ESP Colors")
VisualsTab:CreateColorPicker("ESP Color", Color3.fromRGB(0, 255, 100), function(color)
    _G.GM_ESPColor = color
    Library:Notify("Color Set", "ESP color updated to " .. string.format("#%02X%02X%02X",
        math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)))
end, "Pick the ESP outline color")

VisualsTab:CreateColorPicker("Tracer Color", Color3.fromRGB(255, 0, 0), function(color)
    _G.GM_TracerColor = color
end)

VisualsTab:CreateSeparator()
VisualsTab:CreateLabel("Effects")
VisualsTab:CreateMultiDropdown("Effects", {"Bloom", "SunRays", "DepthOfField", "ColorCorrection"}, {"Bloom"}, function(selected)
    Library:Notify("Effects", "Selected: " .. table.concat(selected, ", "))
end, "Toggle multiple visual effects")

--═══════════════════════════════════════════════════════════════
-- TAB 4: AUTOMATION
--═══════════════════════════════════════════════════════════════
local AutoTab = Window:CreateTab("Automation")

AutoTab:CreateLabel("Auto Features")
AutoTab:CreateToggle("Auto Farm", false, function(state)
    _G.GM_AutoFarm = state
    Library:Notify("Auto Farm", state and "Started" or "Stopped")
end, "Automatically farm resources")

AutoTab:CreateToggle("Auto Collect", false, function(state)
    _G.GM_AutoCollect = state
end)

AutoTab:CreateSlider("Auto Delay (s)", 0.1, 10, 1, function(value)
    _G.GM_AutoDelay = value
end, "Delay between auto actions", 1)

AutoTab:CreateSeparator()
AutoTab:CreateLabel("Progress")
local Progress = AutoTab:CreateProgressBar("Farm Progress", 0, nil, "Shows current farming progress")
AutoTab:CreateButton("Simulate Progress", function()
    for i = 0, 100, 10 do
        Progress.Set(i)
        task.wait(0.2)
    end
    Library:Notify("Complete", "Progress simulation finished!")
end)

--═══════════════════════════════════════════════════════════════
-- TAB 5: CONSOLE
--═══════════════════════════════════════════════════════════════
local ConsoleTab = Window:CreateTab("Console")

ConsoleTab:CreateLabel("Output Log")
local Console = ConsoleTab:CreateConsole(200)

ConsoleTab:CreateButton("Log Info", function()
    Console.Log("This is an info message from GuysModz Hub.")
end)

ConsoleTab:CreateButton("Log Warning", function()
    Console.Warn("This is a warning message!")
end)

ConsoleTab:CreateButton("Log Error", function()
    Console.Error("This is an error message!")
end)

ConsoleTab:CreateButton("Log Success", function()
    Console.Success("Operation completed successfully!")
end)

ConsoleTab:CreateButton("Clear Console", function()
    Console.Clear()
end)

ConsoleTab:CreateSeparator()
ConsoleTab:CreateRichLabel("<b>Welcome to GuysModz Hub Console!</b>\n<i>This console displays script output, errors, and status messages.</i>\n<font color=\"#rgb(100,255,150)\">Green = Success</font> | <font color=\"#rgb(255,200,80)\">Yellow = Warning</font> | <font color=\"#rgb(255,100,100)\">Red = Error</font>")

-- Initial log
Console.Success("GuysModz Hub loaded successfully!")
Console.Log("Player: " .. game.Players.LocalPlayer.Name)
Console.Log("Game ID: " .. tostring(game.GameId))

--═══════════════════════════════════════════════════════════════
-- TAB 6: COLLAPSIBLE SECTIONS DEMO
--═══════════════════════════════════════════════════════════════
local SectionsTab = Window:CreateTab("Sections")

local Section1 = SectionsTab:CreateCollapsibleSection("Combat Settings", true)
Section1:CreateToggle("Aimbot", false, function(state)
    Library:Notify("Aimbot", state and "Enabled" or "Disabled")
end)
Section1:CreateSlider("Aim Smoothness", 1, 20, 5, function(value)
    _G.GM_AimSmooth = value
end)
Section1:CreateDropdown("Aim Part", {"Head", "Torso", "Left Arm", "Right Arm"}, "Head", function(selected)
    _G.GM_AimPart = selected
end)

local Section2 = SectionsTab:CreateCollapsibleSection("Movement Settings", false)
Section2:CreateToggle("Fly", false, function(state)
    _G.GM_Fly = state
end)
Section2:CreateSlider("Fly Speed", 10, 200, 50, function(value)
    _G.GM_FlySpeed = value
end)
Section2:CreateKeybind("Toggle Fly", Enum.KeyCode.F, function()
    Library:Notify("Fly", "Toggled via keybind!")
end)

local Section3 = SectionsTab:CreateCollapsibleSection("Misc Settings", false)
Section3:CreateButton("Rejoin Server", function()
    Library:CreateConfirmationDialog("Rejoin", "Rejoin the current server?", function()
        local ts = game:GetService("TeleportService")
        ts:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end)
end)
Section3:CreateTextBox("Webhook URL", function(text)
    _G.GM_Webhook = text
    Library:Notify("Saved", "Webhook URL saved.")
end)

--═══════════════════════════════════════════════════════════════
-- TAB 7: ESP — Player ESP visuals
--═══════════════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("ESP")

-- ESP state
local ESPSettings = {
    Enabled = false,
    Boxes = true,
    Names = true,
    Health = true,
    Distance = true,
    Tracers = false,
    Skeleton = false,
    TeamCheck = false,
    BoxColor = Color3.fromRGB(0, 255, 100),
    NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 0, 0),
    SkeletonColor = Color3.fromRGB(0, 200, 255),
    MaxDistance = 1000,
    TracerOrigin = "Bottom",
    TextSize = 13,
    Thickness = 1,
}

-- ESP drawing storage
local ESPDrawings = {}
local ESPConnection = nil

local function CreateDrawing(class, props)
    local drawing = Drawing.new(class)
    for prop, value in pairs(props or {}) do
        drawing[prop] = value
    end
    return drawing
end

local function ClearESP()
    for player, drawings in pairs(ESPDrawings) do
        for _, d in pairs(drawings) do
            pcall(function() d:Remove() end)
        end
    end
    ESPDrawings = {}
end

local function GetESPDrawings(player)
    if not ESPDrawings[player] then
        ESPDrawings[player] = {
            Box = CreateDrawing("Square", { Thickness = ESPSettings.Thickness, Filled = false, Visible = false, Color = ESPSettings.BoxColor }),
            Name = CreateDrawing("Text", { Size = ESPSettings.TextSize, Center = true, Outline = true, Visible = false, Color = ESPSettings.NameColor, Font = 2 }),
            HealthText = CreateDrawing("Text", { Size = ESPSettings.TextSize, Center = true, Outline = true, Visible = false, Color = Color3.fromRGB(50, 255, 50), Font = 2 }),
            DistText = CreateDrawing("Text", { Size = ESPSettings.TextSize, Center = true, Outline = true, Visible = false, Color = Color3.fromRGB(200, 200, 200), Font = 2 }),
            Tracer = CreateDrawing("Line", { Thickness = 1, Visible = false, Color = ESPSettings.TracerColor }),
            HealthBar = CreateDrawing("Square", { Thickness = 0, Filled = true, Visible = false, Color = Color3.fromRGB(50, 255, 50) }),
            HealthBarBg = CreateDrawing("Square", { Thickness = 0, Filled = true, Visible = false, Color = Color3.fromRGB(30, 30, 30) }),
        }
    end
    return ESPDrawings[player]
end

local function UpdateESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local localPlayer = game.Players.LocalPlayer

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            local drawings = GetESPDrawings(player)
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChild("Humanoid")
            local head = character and character:FindFirstChild("Head")

            if ESPSettings.Enabled and character and hrp and humanoid and humanoid.Health > 0 then
                -- Team check
                local skip = false
                if ESPSettings.TeamCheck and player.Team and localPlayer.Team and player.Team == localPlayer.Team then
                    skip = true
                end

                if skip then
                    for _, d in pairs(drawings) do d.Visible = false end
                else
                    local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    local distance = (camera.CFrame.Position - hrp.Position).Magnitude

                    if onScreen and distance <= ESPSettings.MaxDistance then
                        local headPos = camera:WorldToViewportPoint(head and head.Position or hrp.Position + Vector3.new(0, 3, 0))
                        local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                        local boxHeight = math.abs(legPos.Y - headPos.Y)
                        local boxWidth = boxHeight * 0.5
                        local boxX = screenPos.X - boxWidth / 2
                        local boxY = headPos.Y

                        -- Box
                        if ESPSettings.Boxes then
                            drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                            drawings.Box.Position = Vector2.new(boxX, boxY)
                            drawings.Box.Color = ESPSettings.BoxColor
                            drawings.Box.Thickness = ESPSettings.Thickness
                            drawings.Box.Visible = true
                        else
                            drawings.Box.Visible = false
                        end

                        -- Name
                        if ESPSettings.Names then
                            drawings.Name.Text = player.Name
                            drawings.Name.Position = Vector2.new(screenPos.X, boxY - 16)
                            drawings.Name.Color = ESPSettings.NameColor
                            drawings.Name.Size = ESPSettings.TextSize
                            drawings.Name.Visible = true
                        else
                            drawings.Name.Visible = false
                        end

                        -- Health bar
                        if ESPSettings.Health then
                            local healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            local barHeight = boxHeight
                            drawings.HealthBarBg.Size = Vector2.new(3, barHeight)
                            drawings.HealthBarBg.Position = Vector2.new(boxX - 6, boxY)
                            drawings.HealthBarBg.Visible = true

                            drawings.HealthBar.Size = Vector2.new(3, barHeight * healthPct)
                            drawings.HealthBar.Position = Vector2.new(boxX - 6, boxY + barHeight * (1 - healthPct))
                            drawings.HealthBar.Color = Color3.fromRGB(255 - math.floor(255 * healthPct), math.floor(255 * healthPct), 50)
                            drawings.HealthBar.Visible = true

                            drawings.HealthText.Text = tostring(math.floor(humanoid.Health))
                            drawings.HealthText.Position = Vector2.new(screenPos.X, boxY + boxHeight + 2)
                            drawings.HealthText.Visible = true
                        else
                            drawings.HealthBar.Visible = false
                            drawings.HealthBarBg.Visible = false
                            drawings.HealthText.Visible = false
                        end

                        -- Distance
                        if ESPSettings.Distance then
                            drawings.DistText.Text = tostring(math.floor(distance)) .. " studs"
                            drawings.DistText.Position = Vector2.new(screenPos.X, boxY + boxHeight + (ESPSettings.Health and 16 or 2))
                            drawings.DistText.Visible = true
                        else
                            drawings.DistText.Visible = false
                        end

                        -- Tracers
                        if ESPSettings.Tracers then
                            local originY = ESPSettings.TracerOrigin == "Bottom" and camera.ViewportSize.Y or camera.ViewportSize.Y / 2
                            drawings.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, originY)
                            drawings.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            drawings.Tracer.Color = ESPSettings.TracerColor
                            drawings.Tracer.Visible = true
                        else
                            drawings.Tracer.Visible = false
                        end
                    else
                        for _, d in pairs(drawings) do d.Visible = false end
                    end
                end
            else
                for _, d in pairs(drawings) do d.Visible = false end
            end
        end
    end
end

local function StartESP()
    if ESPConnection then ESPConnection:Disconnect() end
    ESPConnection = RunService.RenderStepped:Connect(UpdateESP)
end

local function StopESP()
    if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
    ClearESP()
end

-- ESP UI
ESPTab:CreateLabel("ESP Settings")
ESPTab:CreateBadge("Player ESP", Color3.fromRGB(0, 200, 120))

local ESPToggle = ESPTab:CreateToggle("Enable ESP", false, function(state)
    ESPSettings.Enabled = state
    if state then
        StartESP()
        Library:Notify("ESP", "ESP enabled!")
    else
        StopESP()
        Library:Notify("ESP", "ESP disabled.")
    end
end, "Toggle player ESP on/off")

ESPTab:CreateSeparator()
ESPTab:CreateLabel("ESP Features")

ESPTab:CreateToggle("Box ESP", true, function(state)
    ESPSettings.Boxes = state
end, "Draw boxes around players")

ESPTab:CreateToggle("Name ESP", true, function(state)
    ESPSettings.Names = state
end, "Show player names")

ESPTab:CreateToggle("Health ESP", true, function(state)
    ESPSettings.Health = state
end, "Show health bars and numbers")

ESPTab:CreateToggle("Distance ESP", true, function(state)
    ESPSettings.Distance = state
end, "Show distance to players")

ESPTab:CreateToggle("Tracers", false, function(state)
    ESPSettings.Tracers = state
end, "Draw lines from screen to players")

ESPTab:CreateToggle("Team Check", false, function(state)
    ESPSettings.TeamCheck = state
end, "Hide ESP for teammates")

ESPTab:CreateSeparator()
ESPTab:CreateLabel("ESP Colors")

ESPTab:CreateColorPicker("Box Color", Color3.fromRGB(0, 255, 100), function(color)
    ESPSettings.BoxColor = color
end, "Color of ESP boxes")

ESPTab:CreateColorPicker("Name Color", Color3.fromRGB(255, 255, 255), function(color)
    ESPSettings.NameColor = color
end, "Color of player names")

ESPTab:CreateColorPicker("Tracer Color", Color3.fromRGB(255, 0, 0), function(color)
    ESPSettings.TracerColor = color
end, "Color of tracer lines")

ESPTab:CreateSeparator()
ESPTab:CreateLabel("ESP Options")

ESPTab:CreateSlider("Max Distance", 50, 5000, 1000, function(value)
    ESPSettings.MaxDistance = value
end, "Max render distance for ESP")

ESPTab:CreateSlider("Text Size", 8, 24, 13, function(value)
    ESPSettings.TextSize = value
end, "Size of ESP text")

ESPTab:CreateSlider("Box Thickness", 1, 5, 1, function(value)
    ESPSettings.Thickness = value
end, "Thickness of ESP box lines")

ESPTab:CreateDropdown("Tracer Origin", {"Bottom", "Center"}, "Bottom", function(selected)
    ESPSettings.TracerOrigin = selected:lower()
end, "Where tracers originate on screen")

ESPTab:CreateSeparator()
ESPTab:CreateButton("Clear ESP", function()
    StopESP()
    if ESPSettings.Enabled then StartESP() end
    Library:Notify("ESP", "ESP cleared and refreshed.")
end, "Force refresh all ESP drawings")

--═══════════════════════════════════════════════════════════════
-- TAB 8: AIMBOT
--═══════════════════════════════════════════════════════════════
local AimbotTab = Window:CreateTab("Aimbot")

-- Aimbot state
local AimbotSettings = {
    Enabled = false,
    AimKey = Enum.KeyCode.E,
    AimPart = "Head",
    Smoothness = 0.15,
    FOV = 120,
    TeamCheck = false,
    WallCheck = false,
    VisibleCheck = false,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(100, 120, 255),
    Prediction = 0.13,
    Deadzone = 5,
    MaxDistance = 2000,
    TargetType = "Closest", -- Closest or FOV
}

-- FOV circle drawing
local FOVCircle = CreateDrawing("Circle", {
    Radius = AimbotSettings.FOV,
    Color = AimbotSettings.FOVColor,
    Thickness = 1.5,
    Filled = false,
    Visible = false,
    NumSides = 60,
})

-- Aimbot logic
local AimbotConnection = nil
local AimbotTarget = nil
local AimKeyHeld = false

local function GetClosestPlayer()
    local camera = workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    local closest = nil
    local closestDist = math.huge

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local targetPart = player.Character:FindFirstChild(AimbotSettings.AimPart) or hrp

            if hrp and humanoid and humanoid.Health > 0 and targetPart then
                -- Team check
                if AimbotSettings.TeamCheck and player.Team and localPlayer.Team and player.Team == localPlayer.Team then
                    -- skip
                else
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (camera.CFrame.Position - targetPart.Position).Magnitude
                        if dist <= AimbotSettings.MaxDistance then
                            local mousePos = UserInputService:GetMouseLocation()
                            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                            if AimbotSettings.TargetType == "Closest" then
                                if dist < closestDist and screenDist <= AimbotSettings.FOV then
                                    closestDist = dist
                                    closest = player
                                end
                            else -- FOV
                                if screenDist < closestDist and screenDist <= AimbotSettings.FOV then
                                    closestDist = screenDist
                                    closest = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closest
end

local function GetTargetPosition(player)
    local character = player.Character
    if not character then return nil end

    local targetPart = character:FindFirstChild(AimbotSettings.AimPart)
    if not targetPart then
        targetPart = character:FindFirstChild("HumanoidRootPart")
    end
    if not targetPart then return nil end

    -- Velocity prediction
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local velocity = hrp and hrp.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    local predictedPos = targetPart.Position + velocity * AimbotSettings.Prediction

    return predictedPos
end

local function AimbotLoop()
    local camera = workspace.CurrentCamera

    -- Update FOV circle
    if AimbotSettings.ShowFOV and AimbotSettings.Enabled then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = AimbotSettings.FOV
        FOVCircle.Color = AimbotSettings.FOVColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if not AimbotSettings.Enabled or not AimKeyHeld then
        AimbotTarget = nil
        return
    end

    local target = GetClosestPlayer()
    if target then
        AimbotTarget = target
        local targetPos = GetTargetPosition(target)
        if targetPos then
            local currentCF = camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            -- Smooth aim
            camera.CFrame = currentCF:Lerp(targetCF, AimbotSettings.Smoothness)
        end
    else
        AimbotTarget = nil
    end
end

local function StartAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() end
    AimbotConnection = RunService.RenderStepped:Connect(AimbotLoop)
end

local function StopAimbot()
    if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
    FOVCircle.Visible = false
    AimbotTarget = nil
    AimKeyHeld = false
end

-- Track aim key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == AimbotSettings.AimKey then
        AimKeyHeld = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AimbotSettings.AimKey then
        AimKeyHeld = false
    end
end)

-- Aimbot UI
AimbotTab:CreateLabel("Aimbot Settings")
AimbotTab:CreateBadge("Combat", Color3.fromRGB(255, 80, 80))

AimbotTab:CreateToggle("Enable Aimbot", false, function(state)
    AimbotSettings.Enabled = state
    if state then
        StartAimbot()
        Library:Notify("Aimbot", "Aimbot enabled! Hold " .. AimbotSettings.AimKey.Name .. " to aim.")
    else
        StopAimbot()
        Library:Notify("Aimbot", "Aimbot disabled.")
    end
end, "Toggle aimbot on/off")

AimbotTab:CreateSeparator()
AimbotTab:CreateLabel("Aimbot Config")

AimbotTab:CreateDropdown("Target Type", {"Closest", "FOV"}, "Closest", function(selected)
    AimbotSettings.TargetType = selected
end, "How to select the target")

AimbotTab:CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, "Head", function(selected)
    AimbotSettings.AimPart = selected
end, "Which body part to aim at")

AimbotTab:CreateKeybind("Aim Key", Enum.KeyCode.E, function()
    Library:Notify("Aimbot", "Aim key rebound!")
end, "Hold this key to aim at target")

-- Rebind aim key dynamically
local AimKeybind = AimbotTab:CreateKeybind("Change Aim Key", Enum.KeyCode.E, function()
    -- This is just for display, actual key is tracked below
end)
-- Override the keybind to update aim key
local function RebindAimKey(newKey)
    AimbotSettings.AimKey = newKey
    Library:Notify("Aimbot", "Aim key set to " .. newKey.Name)
end

AimbotTab:CreateSeparator()
AimbotTab:CreateLabel("Smoothing & FOV")

AimbotTab:CreateSlider("Smoothness", 0.01, 1, 0.15, function(value)
    AimbotSettings.Smoothness = value
end, "Lower = smoother aim", 2)

AimbotTab:CreateSlider("FOV Radius", 20, 500, 120, function(value)
    AimbotSettings.FOV = value
    FOVCircle.Radius = value
end, "Field of view radius")

AimbotTab:CreateSlider("Prediction", 0, 0.5, 0.13, function(value)
    AimbotSettings.Prediction = value
end, "Velocity prediction factor", 2)

AimbotTab:CreateSlider("Max Distance", 50, 5000, 2000, function(value)
    AimbotSettings.MaxDistance = value
end, "Max targeting distance")

AimbotTab:CreateSeparator()
AimbotTab:CreateLabel("Checks")

AimbotTab:CreateToggle("Team Check", false, function(state)
    AimbotSettings.TeamCheck = state
end, "Don't aim at teammates")

AimbotTab:CreateToggle("Show FOV Circle", true, function(state)
    AimbotSettings.ShowFOV = state
    if not state then FOVCircle.Visible = false end
end, "Visualize the FOV radius")

AimbotTab:CreateSeparator()
AimbotTab:CreateLabel("FOV Circle Color")

AimbotTab:CreateColorPicker("FOV Color", Color3.fromRGB(100, 120, 255), function(color)
    AimbotSettings.FOVColor = color
    FOVCircle.Color = color
end, "Color of the FOV circle")

AimbotTab:CreateSeparator()
AimbotTab:CreateLabel("Status")
local AimbotStatusLabel = AimbotTab:CreateRichLabel("<b>Status:</b> <font color=\"#rgb(255,80,80)\">Disabled</font>")
local AimbotTargetLabel = AimbotTab:CreateRichLabel("<b>Target:</b> <font color=\"#rgb(150,150,170)\">None</font>")

-- Update status labels
task.spawn(function()
    while true do
        if AimbotSettings.Enabled then
            AimbotStatusLabel.Set("<b>Status:</b> <font color=\"#rgb(80,200,120)\">Enabled</font>")
            if AimbotTarget then
                AimbotTargetLabel.Set("<b>Target:</b> <font color=\"#rgb(100,120,255)\">" .. AimbotTarget.Name .. "</font>")
            else
                AimbotTargetLabel.Set("<b>Target:</b> <font color=\"#rgb(150,150,170)\">None</font>")
            end
        else
            AimbotStatusLabel.Set("<b>Status:</b> <font color=\"#rgb(255,80,80)\">Disabled</font>")
            AimbotTargetLabel.Set("<b>Target:</b> <font color=\"#rgb(150,150,170)\">None</font>")
        end
        task.wait(0.1)
    end
end)

AimbotTab:CreateSeparator()
AimbotTab:CreateButton("Stop Aimbot", function()
    AimbotSettings.Enabled = false
    StopAimbot()
    Library:Notify("Aimbot", "Aimbot force stopped.")
end)

--═══════════════════════════════════════════════════════════════
-- TAB 9: SETTINGS
--═══════════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateLabel("UI Settings")
SettingsTab:CreateKeybind("Toggle UI", Enum.KeyCode.RightShift, function()
    -- Handled by BindToggleKey below
end, "Press this key to show/hide the UI")

SettingsTab:CreateRainbowToggle("Rainbow Mode", false, function(state)
    Library:Notify("Rainbow", state and "Enabled" or "Disabled")
end, "Animated rainbow accent color")

SettingsTab:CreateSeparator()
SettingsTab:CreateLabel("Theme Presets")
SettingsTab:CreateDropdown("Theme", {"Dark", "Midnight", "BloodRed", "Green", "Purple", "Orange"}, "Dark", function(selected)
    local preset = Library.Presets[selected]
    if preset then
        Library:SetTheme(preset)
        Library:Notify("Theme", "Switched to " .. selected)
    end
end, "Change the UI color scheme")

SettingsTab:CreateSeparator()
SettingsTab:CreateLabel("Config")
SettingsTab:CreateButton("Save Config", function()
    local ok = Library.Config:Save()
    if ok then
        Library:Notify("Saved", "Configuration saved to file.")
    else
        Library:Notify("Error", "writefile not supported by your executor.")
    end
end)

SettingsTab:CreateButton("Load Config", function()
    local ok = Library.Config:Load()
    if ok then
        Library:Notify("Loaded", "Configuration loaded from file.")
    else
        Library:Notify("Error", "No saved config found or readfile not supported.")
    end
end)

SettingsTab:CreateButton("Clear Config", function()
    Library:CreateConfirmationDialog("Clear Config", "Are you sure you want to delete your saved config?", function()
        Library.Config:Clear()
        Library:Notify("Cleared", "Configuration deleted.")
    end)
end)

SettingsTab:CreateSeparator()
SettingsTab:CreateLabel("About")
SettingsTab:CreateRichLabel("<b>GuysModz Hub v1.0</b>\nCreated by <font color=\"#rgb(100,120,255)\">GuysModz</font>\nUI Library — Full Edition\n\n<i>Press RightShift to toggle the UI.</i>")
SettingsTab:CreateBadge("v1.0", Color3.fromRGB(80, 200, 120))
SettingsTab:CreateBadge("Full Edition", Color3.fromRGB(255, 140, 30))

SettingsTab:CreateSeparator()
SettingsTab:CreateButton("Destroy UI", function()
    Library:CreateConfirmationDialog("Destroy UI", "Are you sure you want to destroy the entire UI?", function()
        Watermark.Destroy()
        StatsDisplay.Destroy()
        Window:Destroy()
    end)
end, "Permanently close the UI")

--═══════════════════════════════════════════════════════════════
-- BINDS + INIT
--═══════════════════════════════════════════════════════════════
Window:BindToggleKey(Enum.KeyCode.RightShift)

-- Register some config values
Library.Config:Register("WalkSpeed", function() return _G.GM_WalkSpeed or 16 end, function(v) _G.GM_WalkSpeed = v end)
Library.Config:Register("InfJump", function() return _G.GM_InfJump or false end, function(v) _G.GM_InfJump = v end)
Library.Config:Register("AutoFarm", function() return _G.GM_AutoFarm or false end, function(v) _G.GM_AutoFarm = v end)

-- Welcome notification
Library:Notify("GuysModz Hub", "Script loaded! Press RightShift to toggle UI.")
