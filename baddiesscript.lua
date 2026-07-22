--[[
    ═══════════════════════════════════════════════════════════════
     GuysModz Hub — Baddies Edition v3.0
     Throwable Magnet (homing throwables)
     
     Usage:
       loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/baddiesscript.lua"))()
    ═══════════════════════════════════════════════════════════════
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/robloxui.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--═══════════════════════════════════════════════════════════════
-- LOADING + WINDOW
--═══════════════════════════════════════════════════════════════
Library:CreateLoadingScreen("Loading GuysModz Baddies Hub...", 1.0)
task.wait(1.0)

local Watermark = Library:CreateWatermark("GuysModz Baddies v3.0")
local StatsDisplay = Library:CreateStatsDisplay()
local Window = Library:CreateWindow("GuysModz | Baddies")

--═══════════════════════════════════════════════════════════════
-- HELPERS
--═══════════════════════════════════════════════════════════════
local function GetCharacter()
    return LocalPlayer.Character
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

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--═══════════════════════════════════════════════════════════════
-- STATE
--═══════════════════════════════════════════════════════════════
local State = {
    -- Throwable magnet
    MagnetEnabled = false,
    MagnetRange = 80,       -- how far a throwable can snap to a target
    MagnetStrength = 1,     -- 1 = full redirect toward target
    TargetPart = "HumanoidRootPart", -- Head / HumanoidRootPart / UpperTorso
    TeamCheck = false,
    OnlyMyThrowables = true,
    MaxTrackTime = 4,       -- seconds to keep steering a projectile

    -- Optional body expand (melee only — does NOT help server throwables)
    ExpandHitbox = false,
    HitboxSize = 12,
    ShowHitbox = false,

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

local function ShouldTarget(player)
    if player == LocalPlayer or not IsAlive(player) then
        return false
    end
    if State.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function GetTargetPart(player)
    local char = player.Character
    if not char then return nil end
    local name = State.TargetPart
    return char:FindFirstChild(name)
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
end

local function GetClosestTarget(fromPos, maxRange)
    local bestPlayer, bestPart, bestDist = nil, nil, maxRange or State.MagnetRange
    for _, player in ipairs(Players:GetPlayers()) do
        if ShouldTarget(player) then
            local part = GetTargetPart(player)
            if part then
                local d = (part.Position - fromPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestPlayer = player
                    bestPart = part
                end
            end
        end
    end
    return bestPlayer, bestPart, bestDist
end

--═══════════════════════════════════════════════════════════════
-- THROWABLE MAGNET
-- Client body-size expand does NOT work when Baddies validates throws
-- on the server. Instead we steer YOUR projectiles toward enemies.
--═══════════════════════════════════════════════════════════════
local Tracked = {} -- [BasePart] = { start = tick(), targetPart = BasePart? }
local StatusLabel

local THROWABLE_NAME_HINTS = {
    "snow", "ball", "throw", "projectile", "rock", "brick", "bottle",
    "can", "knife", "shuriken", "grenade", "bomb", "egg", "tomato",
    "bullet", "missile", "rocket", "dart", "arrow", "orb", "sphere",
    "obj", "item", "weapon", "tool", "ammo", "proj",
}

local function NameLooksThrowable(name)
    if not name then return false end
    local lower = string.lower(name)
    for _, hint in ipairs(THROWABLE_NAME_HINTS) do
        if string.find(lower, hint, 1, true) then
            return true
        end
    end
    return false
end

local function IsDescendantOfLocalCharacter(inst)
    local char = LocalPlayer.Character
    return char and inst:IsDescendantOf(char)
end

local function OwnedByLocalPlayer(inst)
    -- Common ownership patterns across tool/projectile systems
    local ok, val

    ok, val = pcall(function() return inst:GetAttribute("Owner") end)
    if ok and val ~= nil then
        if val == LocalPlayer.UserId or val == LocalPlayer.Name or val == tostring(LocalPlayer.UserId) then
            return true
        end
        if typeof(val) == "Instance" and val == LocalPlayer then
            return true
        end
    end

    ok, val = pcall(function() return inst:GetAttribute("OwnerId") end)
    if ok and (val == LocalPlayer.UserId or val == tostring(LocalPlayer.UserId)) then
        return true
    end

    ok, val = pcall(function() return inst:GetAttribute("UserId") end)
    if ok and (val == LocalPlayer.UserId or val == tostring(LocalPlayer.UserId)) then
        return true
    end

    -- ObjectValues / StringValues
    for _, childName in ipairs({ "Owner", "Creator", "Player", "Thrower" }) do
        local v = inst:FindFirstChild(childName)
        if v then
            if v:IsA("ObjectValue") and v.Value == LocalPlayer then
                return true
            end
            if v:IsA("StringValue") and (v.Value == LocalPlayer.Name or v.Value == tostring(LocalPlayer.UserId)) then
                return true
            end
            if v:IsA("IntValue") and v.Value == LocalPlayer.UserId then
                return true
            end
        end
    end

    -- Creator tag (classic Roblox)
    local creator = inst:FindFirstChild("creator") or inst:FindFirstChild("Creator")
    if creator and creator:IsA("ObjectValue") and creator.Value == LocalPlayer then
        return true
    end

    return false
end

local function IsLikelyThrowable(part)
    if not part or not part:IsA("BasePart") then return false end
    if part.Anchored then return false end
    if IsDescendantOfLocalCharacter(part) then return false end

    -- Ignore huge map parts
    local size = part.Size
    if size.X > 12 or size.Y > 12 or size.Z > 12 then return false end
    if size.Magnitude < 0.05 then return false end

    -- Must be moving (or just spawned near us)
    local speed = 0
    pcall(function()
        speed = part.AssemblyLinearVelocity.Magnitude
    end)

    local myHRP = GetHRP()
    local nearMe = false
    if myHRP then
        nearMe = (part.Position - myHRP.Position).Magnitude < 25
    end

    local owned = OwnedByLocalPlayer(part) or OwnedByLocalPlayer(part.Parent)
    local nameHit = NameLooksThrowable(part.Name) or NameLooksThrowable(part.Parent and part.Parent.Name)

    -- Heuristic:
    -- 1) explicitly owned by us
    -- 2) name looks like a projectile AND near us / moving
    -- 3) small unanchored part newly near us moving fast
    if owned then
        return true
    end

    if State.OnlyMyThrowables then
        -- Still allow name+near+moving for games that don't set owner attrs
        if nameHit and nearMe and speed > 5 then
            return true
        end
        if nearMe and speed > 35 and size.Magnitude < 6 then
            return true
        end
        return false
    end

    -- Track any small fast projectile near anyone (riskier)
    return (nameHit or speed > 20) and size.Magnitude < 8
end

local function SteerProjectile(part, targetPart)
    if not part or not part.Parent or not targetPart or not targetPart.Parent then return end

    local targetPos = targetPart.Position
    -- slight lead
    pcall(function()
        local vel = targetPart.AssemblyLinearVelocity
        targetPos = targetPos + vel * 0.08
    end)

    local pos = part.Position
    local toTarget = targetPos - pos
    local dist = toTarget.Magnitude
    if dist < 0.1 then return end

    local dir = toTarget.Unit
    local speed = 80
    pcall(function()
        local v = part.AssemblyLinearVelocity.Magnitude
        if v > 10 then speed = v end
    end)

    -- Blend current velocity toward target (strength 1 = full lock)
    local strength = math.clamp(State.MagnetStrength, 0.1, 1)
    local desired = dir * speed
    local current = Vector3.zero
    pcall(function() current = part.AssemblyLinearVelocity end)

    local newVel = current:Lerp(desired, strength)
    pcall(function()
        part.AssemblyLinearVelocity = newVel
        -- Keep orientation sensible
        if part.AssemblyAngularVelocity then
            part.AssemblyAngularVelocity = Vector3.zero
        end
        -- Soft CFrame assist when very close so contact registers client-side
        if dist < 8 then
            part.CFrame = CFrame.new(pos, targetPos)
        end
        if dist < 3.5 then
            -- Snap almost onto target for touch/ray games
            part.CFrame = CFrame.new(targetPos - dir * 1.2, targetPos)
            part.AssemblyLinearVelocity = dir * math.max(speed, 60)
        end
    end)
end

local function TryTrack(part)
    if not State.MagnetEnabled then return end
    if Tracked[part] then return end
    if not IsLikelyThrowable(part) then return end

    local fromPos = part.Position
    local _, targetPart = GetClosestTarget(fromPos, State.MagnetRange)
    Tracked[part] = {
        start = tick(),
        targetPart = targetPart,
    }
end

local function ScanWorkspaceForThrowables()
    -- Lightweight periodic scan + DescendantAdded handles most cases
    local myHRP = GetHRP()
    if not myHRP then return end
    local origin = myHRP.Position

    -- Check direct children of Workspace and a few common folders
    local roots = { Workspace }
    for _, name in ipairs({ "Projectiles", "Thrown", "Throwables", "Effects", "Debris", "Ignore", "Bullets", "Missiles" }) do
        local f = Workspace:FindFirstChild(name)
        if f then table.insert(roots, f) end
    end

    for _, root in ipairs(roots) do
        for _, inst in ipairs(root:GetChildren()) do
            if inst:IsA("BasePart") then
                if (inst.Position - origin).Magnitude < 40 then
                    TryTrack(inst)
                end
            elseif inst:IsA("Model") or inst:IsA("Folder") then
                for _, d in ipairs(inst:GetDescendants()) do
                    if d:IsA("BasePart") and (d.Position - origin).Magnitude < 40 then
                        TryTrack(d)
                        break -- one primary part per model is enough
                    end
                end
            end
        end
    end
end

local function StartMagnet()
    -- Catch new instances
    Bind("MagnetAdded", Workspace.DescendantAdded:Connect(function(inst)
        if not State.MagnetEnabled then return end
        if inst:IsA("BasePart") then
            task.defer(function()
                -- wait a frame so velocity/owner attrs exist
                task.wait()
                TryTrack(inst)
            end)
        end
    end))

    -- Steer loop
    Bind("Magnet", RunService.Heartbeat:Connect(function()
        if not State.MagnetEnabled then return end

        local trackedCount = 0
        local now = tick()

        for part, data in pairs(Tracked) do
            if not part or not part.Parent then
                Tracked[part] = nil
            elseif (now - data.start) > State.MaxTrackTime then
                Tracked[part] = nil
            else
                trackedCount += 1
                -- refresh target if lost
                local t = data.targetPart
                if not t or not t.Parent then
                    local _, newT = GetClosestTarget(part.Position, State.MagnetRange)
                    data.targetPart = newT
                    t = newT
                end
                if t then
                    -- retarget if much closer enemy exists
                    local _, closer, dist = GetClosestTarget(part.Position, State.MagnetRange)
                    if closer and dist + 2 < (t.Position - part.Position).Magnitude then
                        data.targetPart = closer
                        t = closer
                    end
                    SteerProjectile(part, t)
                end
            end
        end

        if StatusLabel then
            StatusLabel.Set(string.format(
                "<b>Magnet:</b> <font color=\"rgb(80,200,120)\">ON</font>  |  Tracking: <font color=\"rgb(100,180,255)\">%d</font>  |  Range: %d",
                trackedCount, State.MagnetRange
            ))
        end
    end))

    -- Backup scan for projectiles DescendantAdded may miss
    local lastScan = 0
    Bind("MagnetScan", RunService.Heartbeat:Connect(function()
        if not State.MagnetEnabled then return end
        local t = tick()
        if t - lastScan < 0.15 then return end
        lastScan = t
        pcall(ScanWorkspaceForThrowables)
    end))
end

local function StopMagnet()
    Unbind("Magnet")
    Unbind("MagnetAdded")
    Unbind("MagnetScan")
    Tracked = {}
    if StatusLabel then
        StatusLabel.Set("<b>Magnet:</b> <font color=\"rgb(255,80,80)\">OFF</font>  |  Tracking: 0")
    end
end

--═══════════════════════════════════════════════════════════════
-- OPTIONAL BODY HITBOX (melee only — kept simple, no freeze)
--═══════════════════════════════════════════════════════════════
local OriginalSizes = {}
local OriginalTransparency = {}
local EXPAND_NAMES = { "Head", "UpperTorso", "LowerTorso", "Torso" } -- NO HRP (avoids freeze)

local function RestorePart(part)
    if not part or not part.Parent then return end
    if OriginalSizes[part] then
        pcall(function() part.Size = OriginalSizes[part] end)
    end
    if OriginalTransparency[part] ~= nil then
        pcall(function() part.Transparency = OriginalTransparency[part] end)
    end
end

local function RestoreAllHitboxes()
    for part, _ in pairs(OriginalSizes) do
        RestorePart(part)
    end
    OriginalSizes = {}
    OriginalTransparency = {}
end

local function ExpandPart(part, size)
    if not part or not part:IsA("BasePart") then return end
    if not OriginalSizes[part] then
        OriginalSizes[part] = part.Size
        OriginalTransparency[part] = part.Transparency
    end
    local target = Vector3.new(size, size, size)
    if (part.Size - target).Magnitude > 0.05 then
        part.Size = target
    end
    if part.CanCollide then
        part.CanCollide = false
    end
    if State.ShowHitbox then
        part.Transparency = 0.55
    else
        local tr = OriginalTransparency[part]
        if tr ~= nil then part.Transparency = tr end
    end
end

local function StartHitbox()
    Bind("Hitbox", RunService.Heartbeat:Connect(function()
        if not State.ExpandHitbox then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if ShouldTarget(player) then
                local char = player.Character
                if char then
                    for _, name in ipairs(EXPAND_NAMES) do
                        local part = char:FindFirstChild(name)
                        if part then
                            pcall(ExpandPart, part, State.HitboxSize)
                        end
                    end
                end
            end
        end
    end))
end

local function StopHitbox()
    Unbind("Hitbox")
    RestoreAllHitboxes()
end

--═══════════════════════════════════════════════════════════════
-- TAB 1: THROWABLES
--═══════════════════════════════════════════════════════════════
local ThrowTab = Window:CreateTab("Throwables")

ThrowTab:CreateLabel("Throwable Magnet")
ThrowTab:CreateBadge("Homing", Color3.fromRGB(100, 180, 255))
ThrowTab:CreateRichLabel(
    "<font color=\"rgb(180,180,200)\">Body hitbox expand usually <b>cannot</b> fix throwables if Baddies checks hits on the server.\nThis magnet steers <b>your</b> throwables toward the nearest player instead.</font>"
)

ThrowTab:CreateSeparator()

StatusLabel = ThrowTab:CreateRichLabel("<b>Magnet:</b> <font color=\"rgb(255,80,80)\">OFF</font>  |  Tracking: 0")

ThrowTab:CreateToggle("Throwable Magnet", false, function(state)
    State.MagnetEnabled = state
    if state then
        StartMagnet()
        Library:Notify("Throwables", "Magnet ON — throw something at a player")
    else
        StopMagnet()
        Library:Notify("Throwables", "Magnet OFF")
    end
end, "Home your throwables onto nearby players")

ThrowTab:CreateSlider("Magnet Range", 20, 200, 80, function(value)
    State.MagnetRange = value
end, "How far throwables will lock onto someone")

ThrowTab:CreateSlider("Magnet Strength", 0.2, 1, 1, function(value)
    State.MagnetStrength = value
end, "1 = full lock onto target", 2)

ThrowTab:CreateDropdown("Target Part", {"HumanoidRootPart", "Head", "UpperTorso", "Torso"}, "HumanoidRootPart", function(selected)
    State.TargetPart = selected
end, "Where throwables home to")

ThrowTab:CreateToggle("Only My Throwables", true, function(state)
    State.OnlyMyThrowables = state
end, "Only steer projectiles that look like yours")

ThrowTab:CreateToggle("Team Check", false, function(state)
    State.TeamCheck = state
end, "Don't lock onto teammates")

ThrowTab:CreateSeparator()
ThrowTab:CreateLabel("Optional: Body Expand (melee)")
ThrowTab:CreateRichLabel(
    "<font color=\"rgb(200,160,100)\">This is for punches/melee only. It will <b>not</b> make server throwables hit.</font>"
)

ThrowTab:CreateToggle("Expand Body Hitbox", false, function(state)
    State.ExpandHitbox = state
    if state then
        StartHitbox()
        Library:Notify("Hitbox", "Body expand ON (melee only)")
    else
        StopHitbox()
        Library:Notify("Hitbox", "Body expand OFF")
    end
end, "Expand head/torso for melee — not throwables")

ThrowTab:CreateSlider("Body Hitbox Size", 5, 30, 12, function(value)
    State.HitboxSize = value
end, "Melee hitbox size")

ThrowTab:CreateToggle("Show Body Hitbox", false, function(state)
    State.ShowHitbox = state
end, "Fade expanded body parts")

ThrowTab:CreateButton("Reset Body Hitboxes", function()
    RestoreAllHitboxes()
    Library:Notify("Hitbox", "Body hitboxes restored")
end)

--═══════════════════════════════════════════════════════════════
-- TAB 2: TELEPORT
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
        if ShouldTarget(p) then
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
    if best then
        myHRP.CFrame = best.CFrame + Vector3.new(0, 3, 0)
        Library:Notify("Teleport", "Teleported to nearest player.")
    else
        Library:Notify("Teleport", "No player found.")
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 3: VISUALS
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
-- TAB 4: SETTINGS
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
SettingsTab:CreateRichLabel("<b>GuysModz Baddies Hub v3.0</b>\nThrowable Magnet + optional melee hitbox\nPress RightShift to toggle UI.")

SettingsTab:CreateButton("Destroy UI", function()
    Library:CreateConfirmationDialog("Destroy UI", "Close the hub?", function()
        for name, _ in pairs(Connections) do Unbind(name) end
        StopMagnet()
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

Library:Notify("GuysModz Baddies", "v3.0 — use Throwable Magnet for snowballs. RightShift toggles UI.")
