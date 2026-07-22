--[[
    ═══════════════════════════════════════════════════════════════
     GuysModz Hub — Baddies Edition
     Hitbox Expand + Silent Aim + Prediction
     
     Usage:
       loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/baddiesscript.lua"))()
    ═══════════════════════════════════════════════════════════════
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/robloxui.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--═══════════════════════════════════════════════════════════════
-- LOADING + WINDOW
--═══════════════════════════════════════════════════════════════
Library:CreateLoadingScreen("Loading GuysModz Baddies Hub...", 1.5)
task.wait(1.5)

local Watermark = Library:CreateWatermark("GuysModz Baddies v1.1")
local StatsDisplay = Library:CreateStatsDisplay()
local Window = Library:CreateWindow("GuysModz | Baddies")

--═══════════════════════════════════════════════════════════════
-- HELPERS
--═══════════════════════════════════════════════════════════════
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetPart(player, partName)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--═══════════════════════════════════════════════════════════════
-- STATE
--═══════════════════════════════════════════════════════════════
local State = {
    -- Hitbox
    ExpandHitbox = false,
    HitboxSize = 10,
    HitboxTransparency = 1, -- 1 = fully invisible (won't hide players)
    HitboxMode = "Throwable", -- Throwable / HRP / Full Body
    ExpandLimbs = false,
    ThrowableHitbox = true, -- separate part only — never touches real body in Throwable mode
    ShowHitbox = false, -- if true, show orange outline instead of fully invisible
    TeamCheck = false,

    -- Silent Aim
    SilentAim = false,
    SilentAimPart = "Head",
    SilentAimFOV = 150,
    SilentAimSmooth = 1, -- 1 = instant (true silent), lower = smoother
    Prediction = 0.13,
    PredictionEnabled = true,
    WallCheck = false,
    VisibleOnly = false,
    TargetType = "Closest", -- Closest / FOV
    ShowFOV = true,
    FOVColor = Color3.fromRGB(100, 120, 255),
    MaxDistance = 2000,
    AimKey = Enum.KeyCode.E,
    AimKeyHeld = false,
    RequireKey = false, -- if true, only aim while key held

    -- Player
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,

    -- Misc
    Fullbright = false,
}

local Connections = {}
local function Bind(name, conn)
    if Connections[name] then
        pcall(function() Connections[name]:Disconnect() end)
    end
    Connections[name] = conn
end

local function Unbind(name)
    if Connections[name] then
        pcall(function() Connections[name]:Disconnect() end)
        Connections[name] = nil
    end
end

local CurrentTarget = nil
local OriginalSizes = {} -- [BasePart] = original Size
local OriginalProps = {} -- [BasePart] = {Transparency, CanCollide, Massless, CanTouch, CanQuery}
local ThrowableParts = {} -- [Character] = Part  (stored OUTSIDE the character)
local HitboxFolder = nil
local FOVCircle = nil
local DrawingSupported = pcall(function()
    local d = Drawing.new("Circle")
    d:Remove()
end)

local BODY_PARTS = {
    "HumanoidRootPart",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "Torso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}

local function GetHitboxFolder()
    if HitboxFolder and HitboxFolder.Parent then
        return HitboxFolder
    end
    local existing = Workspace:FindFirstChild("GuysModzHitboxes")
    if existing then
        HitboxFolder = existing
        return HitboxFolder
    end
    HitboxFolder = Instance.new("Folder")
    HitboxFolder.Name = "GuysModzHitboxes"
    HitboxFolder.Parent = Workspace
    return HitboxFolder
end

local function ShouldExpandPlayer(player)
    if player == LocalPlayer or not IsAlive(player) then
        return false
    end
    if State.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function CachePart(part)
    if not OriginalSizes[part] then
        OriginalSizes[part] = part.Size
        OriginalProps[part] = {
            Transparency = part.Transparency,
            CanCollide = part.CanCollide,
            Massless = part.Massless,
            CanTouch = part.CanTouch,
            CanQuery = part.CanQuery,
        }
    end
end

-- Only used by HRP / Full Body modes. Never used by Throwable mode.
local function ExpandPart(part, size)
    if not part or not part:IsA("BasePart") then return end
    CachePart(part)
    part.Size = Vector3.new(size, size, size)
    -- Keep real body parts visible — only fade a little if user wants outline
    if State.ShowHitbox then
        part.Transparency = math.clamp(State.HitboxTransparency, 0.4, 0.85)
    end
    -- Do NOT force high transparency (that makes people disappear)
    part.CanCollide = false
    part.Massless = true
    part.CanTouch = true
    part.CanQuery = true
end

local function RestorePart(part)
    if not part or not part.Parent then return end
    local size = OriginalSizes[part]
    local props = OriginalProps[part]
    if size then
        part.Size = size
    end
    if props then
        part.Transparency = props.Transparency
        part.CanCollide = props.CanCollide
        part.Massless = props.Massless
        part.CanTouch = props.CanTouch
        part.CanQuery = props.CanQuery
    end
end

local function ClearThrowablePart(character)
    local p = ThrowableParts[character]
    if p then
        pcall(function()
            if p.Parent then p:Destroy() end
        end)
        ThrowableParts[character] = nil
    end
end

local function GetThrowableTransparency()
    -- Default fully invisible so players never "disappear" behind orange blobs
    if State.ShowHitbox then
        return math.clamp(State.HitboxTransparency, 0.5, 0.9)
    end
    return 1
end

local function EnsureThrowablePart(character, hrp, size)
    local folder = GetHitboxFolder()
    local part = ThrowableParts[character]
    local transparency = GetThrowableTransparency()

    if part and part.Parent then
        part.Size = Vector3.new(size, size, size)
        part.Transparency = transparency
        part.CFrame = hrp.CFrame
        part.CanTouch = true
        part.CanQuery = true
        part.CanCollide = false
        part.Massless = true
        part.Anchored = true -- follow via CFrame each frame (no weld physics issues)
        return part
    end

    part = Instance.new("Part")
    part.Name = "GuysModzThrowableHitbox_" .. (character.Name or "unknown")
    part.Size = Vector3.new(size, size, size)
    part.Transparency = transparency
    part.Color = Color3.fromRGB(255, 140, 30)
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = true
    part.CanQuery = true
    part.Massless = true
    part.CastShadow = false
    part.CFrame = hrp.CFrame
    -- CRITICAL: parent outside character so avatar/mesh never gets covered or grouped
    part.Parent = folder

    ThrowableParts[character] = part
    return part
end

local function RestoreAllHitboxes()
    for part, _ in pairs(OriginalSizes) do
        pcall(function()
            RestorePart(part)
        end)
    end
    OriginalSizes = {}
    OriginalProps = {}

    for character, _ in pairs(ThrowableParts) do
        ClearThrowablePart(character)
    end
    ThrowableParts = {}

    if HitboxFolder and HitboxFolder.Parent then
        pcall(function() HitboxFolder:ClearAllChildren() end)
    end
end

local function ApplyHitboxToPlayer(player)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local size = State.HitboxSize
    local mode = State.HitboxMode

    -- ── Throwable mode: NEVER resize real body parts ──
    -- Only a separate invisible part in Workspace (prevents players vanishing / grouping)
    if mode == "Throwable" then
        -- If we previously expanded body parts, restore them first
        for _, name in ipairs(BODY_PARTS) do
            local part = character:FindFirstChild(name)
            if part and OriginalSizes[part] then
                pcall(RestorePart, part)
                OriginalSizes[part] = nil
                OriginalProps[part] = nil
            end
        end
        if State.ThrowableHitbox then
            EnsureThrowablePart(character, hrp, size)
        else
            ClearThrowablePart(character)
        end
        return
    end

    -- Non-throwable modes don't need the extra part unless toggle is on
    if State.ThrowableHitbox then
        EnsureThrowablePart(character, hrp, size)
    else
        ClearThrowablePart(character)
    end

    if mode == "HRP" then
        ExpandPart(hrp, size)
        -- restore limbs if previously expanded
        for _, name in ipairs(BODY_PARTS) do
            if name ~= "HumanoidRootPart" then
                local part = character:FindFirstChild(name)
                if part and OriginalSizes[part] then
                    pcall(RestorePart, part)
                    OriginalSizes[part] = nil
                    OriginalProps[part] = nil
                end
            end
        end
    elseif mode == "Full Body" then
        ExpandPart(hrp, size)
        for _, name in ipairs(BODY_PARTS) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") and part ~= hrp then
                local limbSize = math.max(2, size * 0.65)
                ExpandPart(part, limbSize)
            end
        end
    end
end

if DrawingSupported then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Radius = State.SilentAimFOV
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.Color = State.FOVColor
    FOVCircle.Transparency = 1
end

--═══════════════════════════════════════════════════════════════
-- SILENT AIM LOGIC
--═══════════════════════════════════════════════════════════════
local function IsVisible(origin, targetPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.IgnoreWater = true

    local direction = targetPos - origin
    local result = Workspace:Raycast(origin, direction, params)
    if not result then return true end

    -- If we hit something belonging to a player character that's not wall, allow
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

local function GetPredictedPosition(part)
    if not part then return nil end
    local pos = part.Position
    if State.PredictionEnabled then
        local vel = part.AssemblyLinearVelocity
        pos = pos + (vel * State.Prediction)
    end
    return pos
end

local function GetClosestTarget()
    local bestPlayer = nil
    local bestScore = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local origin = cam.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            if State.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                -- skip teammate
            else
                local part = GetPart(player, State.SilentAimPart)
                if part then
                    local worldPos = GetPredictedPosition(part)
                    if worldPos then
                        local dist = (origin - worldPos).Magnitude
                        if dist <= State.MaxDistance then
                            if not State.WallCheck or IsVisible(origin, worldPos) then
                                local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
                                if onScreen or not State.VisibleOnly then
                                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                                    if screenDist <= State.SilentAimFOV then
                                        local score
                                        if State.TargetType == "Closest" then
                                            score = dist
                                        else
                                            score = screenDist
                                        end
                                        if score < bestScore then
                                            bestScore = score
                                            bestPlayer = player
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPlayer
end

local function GetSilentAimCFrame()
    if not State.SilentAim then return nil end
    if State.RequireKey and not State.AimKeyHeld then return nil end

    local target = GetClosestTarget()
    CurrentTarget = target
    if not target then return nil end

    local part = GetPart(target, State.SilentAimPart)
    if not part then return nil end

    local aimPos = GetPredictedPosition(part)
    if not aimPos then return nil end

    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    -- True silent aim returns CFrame looking at target from camera
    local origin = cam.CFrame.Position
    return CFrame.new(origin, aimPos)
end

-- Hook Camera CFrame / Mouse.Hit for silent aim
local function StartSilentAim()
    Unbind("SilentAim")

    -- Method 1: __index hook on Mouse.Hit / Mouse.Target
    local mt
    local success = pcall(function()
        mt = getrawmetatable(game)
    end)

    if success and mt and setreadonly then
        setreadonly(mt, false)
        local oldIndex = mt.__index

        mt.__index = newcclosure(function(self, key)
            if State.SilentAim and not checkcaller() then
                if self == Mouse and (key == "Hit" or key == "Target") then
                    local target = GetClosestTarget()
                    CurrentTarget = target
                    if target then
                        local part = GetPart(target, State.SilentAimPart)
                        if part then
                            local aimPos = GetPredictedPosition(part)
                            if aimPos then
                                if key == "Hit" then
                                    return CFrame.new(aimPos)
                                elseif key == "Target" then
                                    return part
                                end
                            end
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end)

        setreadonly(mt, true)

        Bind("SilentAim", {
            Disconnect = function()
                pcall(function()
                    setreadonly(mt, false)
                    mt.__index = oldIndex
                    setreadonly(mt, true)
                end)
            end
        })
    else
        -- Fallback: camera look (semi-silent / soft aim)
        Bind("SilentAim", RunService.RenderStepped:Connect(function()
            if not State.SilentAim then return end
            if State.RequireKey and not State.AimKeyHeld then
                CurrentTarget = nil
                return
            end

            local cf = GetSilentAimCFrame()
            if cf then
                local cam = Workspace.CurrentCamera
                if cam then
                    if State.SilentAimSmooth >= 0.99 then
                        cam.CFrame = cf
                    else
                        cam.CFrame = cam.CFrame:Lerp(cf, State.SilentAimSmooth)
                    end
                end
            else
                CurrentTarget = nil
            end
        end))
    end
end

local function StopSilentAim()
    Unbind("SilentAim")
    CurrentTarget = nil
end

-- Aim key tracking
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == State.AimKey then
        State.AimKeyHeld = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == State.AimKey then
        State.AimKeyHeld = false
    end
end)

-- FOV circle update
Bind("FOV", RunService.RenderStepped:Connect(function()
    if FOVCircle then
        if State.SilentAim and State.ShowFOV then
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = mousePos
            FOVCircle.Radius = State.SilentAimFOV
            FOVCircle.Color = State.FOVColor
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end
end))

--═══════════════════════════════════════════════════════════════
-- TAB 1: COMBAT (Silent Aim + Hitbox)
--═══════════════════════════════════════════════════════════════
local CombatTab = Window:CreateTab("Combat")

CombatTab:CreateLabel("Silent Aim")
CombatTab:CreateBadge("Aimbot", Color3.fromRGB(255, 80, 80))

CombatTab:CreateToggle("Enable Silent Aim", false, function(state)
    State.SilentAim = state
    if state then
        StartSilentAim()
        Library:Notify("Silent Aim", "Enabled")
    else
        StopSilentAim()
        Library:Notify("Silent Aim", "Disabled")
    end
end, "Redirect shots toward target")

CombatTab:CreateToggle("Require Aim Key", false, function(state)
    State.RequireKey = state
end, "Only silent aim while aim key is held")

local AimKeybind = CombatTab:CreateKeybind("Aim Key", Enum.KeyCode.E, function()
end, "Hold this key if Require Aim Key is on")

-- Keep State.AimKey synced with the UI keybind widget
task.spawn(function()
    while true do
        pcall(function()
            if AimKeybind and AimKeybind.Get then
                local k = AimKeybind.Get()
                if k and k ~= State.AimKey then
                    State.AimKey = k
                end
            end
        end)
        task.wait(0.25)
    end
end)

CombatTab:CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}, "Head", function(selected)
    State.SilentAimPart = selected
end, "Body part to aim at")

CombatTab:CreateDropdown("Target Priority", {"Closest", "FOV"}, "Closest", function(selected)
    State.TargetType = selected
end, "Closest = nearest world distance, FOV = closest to crosshair")

CombatTab:CreateSeparator()
CombatTab:CreateLabel("Prediction")

CombatTab:CreateToggle("Enable Prediction", true, function(state)
    State.PredictionEnabled = state
end, "Lead moving targets")

CombatTab:CreateSlider("Prediction Amount", 0, 0.5, 0.13, function(value)
    State.Prediction = value
end, "Velocity multiplier (higher = more lead)", 2)

CombatTab:CreateSeparator()
CombatTab:CreateLabel("Silent Aim Settings")

CombatTab:CreateSlider("FOV Radius", 20, 500, 150, function(value)
    State.SilentAimFOV = value
    if FOVCircle then FOVCircle.Radius = value end
end, "Only target players inside this FOV")

CombatTab:CreateSlider("Max Distance", 50, 5000, 2000, function(value)
    State.MaxDistance = value
end, "Max targeting distance")

CombatTab:CreateSlider("Smoothness", 0.05, 1, 1, function(value)
    State.SilentAimSmooth = value
end, "1 = instant silent, lower = softer camera aim (fallback mode)", 2)

CombatTab:CreateToggle("Team Check", false, function(state)
    State.TeamCheck = state
end, "Ignore teammates")

CombatTab:CreateToggle("Wall Check", false, function(state)
    State.WallCheck = state
end, "Don't target through walls")

CombatTab:CreateToggle("Visible Only", false, function(state)
    State.VisibleOnly = state
end, "Only target on-screen players")

CombatTab:CreateToggle("Show FOV Circle", true, function(state)
    State.ShowFOV = state
    if not state and FOVCircle then FOVCircle.Visible = false end
end)

CombatTab:CreateColorPicker("FOV Color", Color3.fromRGB(100, 120, 255), function(color)
    State.FOVColor = color
    if FOVCircle then FOVCircle.Color = color end
end)

CombatTab:CreateSeparator()
CombatTab:CreateLabel("Status")
local StatusLabel = CombatTab:CreateRichLabel("<b>Silent Aim:</b> <font color=\"rgb(255,80,80)\">Off</font>")
local TargetLabel = CombatTab:CreateRichLabel("<b>Target:</b> <font color=\"rgb(150,150,170)\">None</font>")
local PredLabel = CombatTab:CreateRichLabel("<b>Prediction:</b> 0.13")

task.spawn(function()
    while true do
        pcall(function()
            if State.SilentAim then
                StatusLabel.Set("<b>Silent Aim:</b> <font color=\"rgb(80,200,120)\">On</font>")
            else
                StatusLabel.Set("<b>Silent Aim:</b> <font color=\"rgb(255,80,80)\">Off</font>")
            end
            if CurrentTarget then
                TargetLabel.Set("<b>Target:</b> <font color=\"rgb(100,120,255)\">" .. CurrentTarget.Name .. "</font>")
            else
                TargetLabel.Set("<b>Target:</b> <font color=\"rgb(150,150,170)\">None</font>")
            end
            PredLabel.Set(string.format("<b>Prediction:</b> %.2f %s", State.Prediction, State.PredictionEnabled and "(on)" or "(off)"))
        end)
        task.wait(0.1)
    end
end)

CombatTab:CreateSeparator()
CombatTab:CreateLabel("Hitbox Expander")
CombatTab:CreateBadge("Hitbox", Color3.fromRGB(255, 140, 30))

CombatTab:CreateDropdown("Hitbox Mode", {"Throwable", "HRP", "Full Body"}, "Throwable", function(selected)
    State.HitboxMode = selected
    -- Throwable = separate invisible part only (safe, no player vanishing)
    State.ThrowableHitbox = true
    State.ExpandLimbs = (selected == "Full Body")
    if selected == "Throwable" then
        -- restore any previously resized body parts immediately
        for part, _ in pairs(OriginalSizes) do
            pcall(RestorePart, part)
        end
        OriginalSizes = {}
        OriginalProps = {}
    end
    Library:Notify("Hitbox", "Mode: " .. selected .. (selected == "Throwable" and " (invisible, safe)" or ""))
end, "Throwable = invisible extra hitbox (won't hide players)")

CombatTab:CreateToggle("Expand Hitbox", false, function(state)
    State.ExpandHitbox = state
    if state then
        Bind("Hitbox", RunService.Heartbeat:Connect(function()
            if not State.ExpandHitbox then return end
            local alive = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if ShouldExpandPlayer(player) then
                    local char = player.Character
                    if char then alive[char] = true end
                    pcall(ApplyHitboxToPlayer, player)
                end
            end
            -- cleanup orphaned / dead player hitboxes
            for character, part in pairs(ThrowableParts) do
                if not character or not character.Parent or not alive[character] or not part or not part.Parent then
                    ClearThrowablePart(character)
                end
            end
        end))
        Library:Notify("Hitbox", "Enabled (" .. State.HitboxMode .. "). Throwable mode keeps players visible.")
    else
        Unbind("Hitbox")
        RestoreAllHitboxes()
        Library:Notify("Hitbox", "Hitbox expand disabled.")
    end
end, "Expand hitboxes. Use Throwable mode for snowballs.")

CombatTab:CreateToggle("Show Hitbox Outline", false, function(state)
    State.ShowHitbox = state
    if state then
        State.HitboxTransparency = 0.7
    else
        State.HitboxTransparency = 1
    end
end, "Show orange hitboxes. Off = fully invisible (recommended)")

CombatTab:CreateSlider("Hitbox Size", 2, 50, 10, function(value)
    State.HitboxSize = value
end, "Expanded hitbox size")

CombatTab:CreateSlider("Hitbox Transparency", 0, 1, 1, function(value)
    State.HitboxTransparency = value
end, "Only used when Show Hitbox Outline is on", 2)

CombatTab:CreateToggle("Team Check (Hitbox)", false, function(state)
    State.TeamCheck = state
end, "Don't expand teammates")

CombatTab:CreateButton("Reset Hitboxes", function()
    RestoreAllHitboxes()
    Library:Notify("Hitbox", "Hitboxes reset — players restored.")
end)

--═══════════════════════════════════════════════════════════════
-- TAB 2: PLAYER
--═══════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Player")

MainTab:CreateLabel("Movement")

MainTab:CreateSlider("Walk Speed", 16, 200, 16, function(value)
    State.WalkSpeed = value
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = value end
end)

MainTab:CreateSlider("Jump Power", 50, 300, 50, function(value)
    State.JumpPower = value
    local hum = GetHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = value
    end
end)

MainTab:CreateToggle("Infinite Jump", false, function(state)
    State.InfJump = state
    if state then
        Bind("InfJump", UserInputService.JumpRequest:Connect(function()
            if State.InfJump then
                local hum = GetHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end))
    else
        Unbind("InfJump")
    end
end)

MainTab:CreateToggle("Noclip", false, function(state)
    State.Noclip = state
    if state then
        Bind("Noclip", RunService.Stepped:Connect(function()
            if not State.Noclip then return end
            local char = GetCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end))
    else
        Unbind("Noclip")
    end
end)

MainTab:CreateToggle("Fly", false, function(state)
    State.Fly = state
    if state then
        Bind("Fly", RunService.RenderStepped:Connect(function()
            if not State.Fly then return end
            local hrp = GetHRP()
            local hum = GetHumanoid()
            if not hrp or not hum then return end
            hum.PlatformStand = true
            local move = Vector3.zero
            local cam = Workspace.CurrentCamera
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= look end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= right end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
            if move.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = move.Unit * State.FlySpeed
            else
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end))
    else
        Unbind("Fly")
        local hum = GetHumanoid()
        if hum then hum.PlatformStand = false end
    end
end)

MainTab:CreateSlider("Fly Speed", 10, 200, 50, function(value)
    State.FlySpeed = value
end)

MainTab:CreateSeparator()
MainTab:CreateButton("Reset Character", function()
    local char = GetCharacter()
    if char then char:BreakJoints() end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = State.JumpPower
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 3: TELEPORT
--═══════════════════════════════════════════════════════════════
local TPTab = Window:CreateTab("Teleport")

TPTab:CreateLabel("Players")

local function RefreshPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    table.sort(names)
    if #names == 0 then names = { "No players" } end
    return names
end

local PlayerDropdown = TPTab:CreateDropdown("Select Player", RefreshPlayerList(), nil, function(selected)
    if selected == "No players" then return end
    local target = Players:FindFirstChild(selected)
    local myHRP = GetHRP()
    if target and target.Character and myHRP then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
            Library:Notify("Teleport", "Teleported to " .. selected)
        end
    end
end)

TPTab:CreateButton("Refresh Player List", function()
    PlayerDropdown.Refresh(RefreshPlayerList())
end)

TPTab:CreateButton("TP to Nearest Enemy", function()
    local myHRP = GetHRP()
    if not myHRP then return end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            if State.TeamCheck and p.Team and LocalPlayer.Team and p.Team == LocalPlayer.Team then
                -- skip
            else
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = hrp
                    end
                end
            end
        end
    end
    if best then
        myHRP.CFrame = best.CFrame + Vector3.new(0, 3, 0)
        Library:Notify("Teleport", "Teleported to nearest player.")
    else
        Library:Notify("Teleport", "No player found.")
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 4: VISUALS
--═══════════════════════════════════════════════════════════════
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateToggle("Fullbright", false, function(state)
    State.Fullbright = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 10000
    end
end)

VisualsTab:CreateDropdown("Time of Day", {"Morning", "Noon", "Evening", "Night"}, "Noon", function(selected)
    local times = { Morning = 6, Noon = 12, Evening = 18, Night = 0 }
    Lighting.ClockTime = times[selected] or 12
end)

--═══════════════════════════════════════════════════════════════
-- TAB 5: SETTINGS
--═══════════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateLabel("UI")
SettingsTab:CreateKeybind("Toggle UI", Enum.KeyCode.RightShift, function() end)

SettingsTab:CreateDropdown("Theme", {"Dark", "Midnight", "BloodRed", "Green", "Purple", "Orange"}, "Dark", function(selected)
    local preset = Library.Presets[selected]
    if preset then
        Library:SetTheme(preset)
        Library:Notify("Theme", "Switched to " .. selected)
    end
end)

SettingsTab:CreateSeparator()
SettingsTab:CreateRichLabel("<b>GuysModz Baddies Hub v1.3</b>\nSilent Aim + Prediction + Safe Throwable Hitbox\nPress RightShift to toggle UI.")

SettingsTab:CreateButton("Destroy UI", function()
    Library:CreateConfirmationDialog("Destroy UI", "Close the hub?", function()
        StopSilentAim()
        for name, _ in pairs(Connections) do Unbind(name) end
        if FOVCircle then pcall(function() FOVCircle:Remove() end) end
        RestoreAllHitboxes()
        Watermark.Destroy()
        StatsDisplay.Destroy()
        Window:Destroy()
    end)
end)

--═══════════════════════════════════════════════════════════════
-- INIT
--═══════════════════════════════════════════════════════════════
Window:BindToggleKey(Enum.KeyCode.RightShift)

Library:Notify("GuysModz Baddies", "Loaded! Silent Aim + Hitbox ready. RightShift toggles UI.")
