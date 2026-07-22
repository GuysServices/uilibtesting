--[[
    ═══════════════════════════════════════════════════════════════
     GuysModz Hub — Baddies Edition v2.1
     Throwable Hitbox Expander (no freeze)
     
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

local LocalPlayer = Players.LocalPlayer

--═══════════════════════════════════════════════════════════════
-- LOADING + WINDOW
--═══════════════════════════════════════════════════════════════
Library:CreateLoadingScreen("Loading GuysModz Baddies Hub...", 1.0)
task.wait(1.0)

local Watermark = Library:CreateWatermark("GuysModz Baddies v2.1")
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
    ExpandHitbox = false,
    HitboxSize = 15,
    TeamCheck = false,
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

-- Original sizes only (we never touch Massless/physics props that freeze people)
local OriginalSizes = {} -- [BasePart] = Vector3
local OriginalTransparency = {} -- [BasePart] = number

-- Parts safe to expand for throwables.
-- NOTE: We intentionally do NOT set Massless / mess with HRP physics.
-- Freezing was caused by Massless=true + constant physics prop writes on root.
local EXPAND_NAMES = {
    "HumanoidRootPart",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "Torso",
}

local function ShouldTarget(player)
    if player == LocalPlayer or not IsAlive(player) then
        return false
    end
    if State.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function RestorePart(part)
    if not part or not part.Parent then return end
    local size = OriginalSizes[part]
    if size then
        pcall(function()
            part.Size = size
            part.CanCollide = (part.Name == "HumanoidRootPart") and false or part.CanCollide
        end)
    end
    local tr = OriginalTransparency[part]
    if tr ~= nil then
        pcall(function()
            part.Transparency = tr
        end)
    end
end

local function RestoreAll()
    for part, _ in pairs(OriginalSizes) do
        RestorePart(part)
    end
    -- Always clear CanCollide override carefully — only restore size/transparency
    OriginalSizes = {}
    OriginalTransparency = {}
end

local function ExpandPart(part, size)
    if not part or not part:IsA("BasePart") then return end

    -- Cache original once
    if not OriginalSizes[part] then
        OriginalSizes[part] = part.Size
        OriginalTransparency[part] = part.Transparency
    end

    local target = Vector3.new(size, size, size)

    -- Only write Size when it actually changed (stops physics thrash / freeze)
    if (part.Size - target).Magnitude > 0.05 then
        part.Size = target
    end

    -- CanCollide false stops giant boxes from pushing/locking characters
    if part.CanCollide then
        part.CanCollide = false
    end

    -- CanTouch/CanQuery help client-side throwable contact (safe, no freeze)
    if part.CanTouch == false then
        part.CanTouch = true
    end
    if part.CanQuery == false then
        part.CanQuery = true
    end

    -- DO NOT set Massless — that freezes / breaks character physics
    -- DO NOT set Anchored
    -- DO NOT parent extra parts into the character

    if State.ShowHitbox then
        if part.Transparency ~= 0.6 then
            part.Transparency = 0.6
        end
    else
        local original = OriginalTransparency[part]
        if original ~= nil and part.Transparency ~= original then
            part.Transparency = original
        end
    end
end

local function ApplyHitbox(player)
    local character = player.Character
    if not character then return end

    local size = State.HitboxSize
    for _, name in ipairs(EXPAND_NAMES) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            ExpandPart(part, size)
        end
    end
end

local function StartHitbox()
    -- Heartbeat is fine; we only write when values differ
    Bind("Hitbox", RunService.Heartbeat:Connect(function()
        if not State.ExpandHitbox then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if ShouldTarget(player) then
                pcall(ApplyHitbox, player)
            end
        end
    end))
end

local function StopHitbox()
    Unbind("Hitbox")
    RestoreAll()
end

Players.PlayerRemoving:Connect(function(player)
    local char = player.Character
    if not char then return end
    for _, name in ipairs(EXPAND_NAMES) do
        local part = char:FindFirstChild(name)
        if part and OriginalSizes[part] then
            RestorePart(part)
            OriginalSizes[part] = nil
            OriginalTransparency[part] = nil
        end
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 1: HITBOX
--═══════════════════════════════════════════════════════════════
local HitboxTab = Window:CreateTab("Hitbox")

HitboxTab:CreateLabel("Throwable Hitbox Expander")
HitboxTab:CreateBadge("Throwables", Color3.fromRGB(255, 140, 30))
HitboxTab:CreateRichLabel(
    "<font color=\"rgb(180,180,200)\">Expands HRP / Head / Torso for throwables.\nNo Massless, no fake parts — players keep moving.</font>"
)

HitboxTab:CreateSeparator()

HitboxTab:CreateToggle("Expand Hitbox", false, function(state)
    State.ExpandHitbox = state
    if state then
        StartHitbox()
        Library:Notify("Hitbox", "ON — size " .. tostring(State.HitboxSize))
    else
        StopHitbox()
        Library:Notify("Hitbox", "OFF — restored")
    end
end, "Expand enemy hitboxes for throwables")

HitboxTab:CreateSlider("Hitbox Size", 5, 40, 15, function(value)
    State.HitboxSize = value
end, "Bigger = easier hits")

HitboxTab:CreateToggle("Show Hitbox", false, function(state)
    State.ShowHitbox = state
    if not state then
        for part, tr in pairs(OriginalTransparency) do
            if part and part.Parent then
                pcall(function()
                    part.Transparency = tr
                end)
            end
        end
    end
end, "Fade parts slightly so you can see the size")

HitboxTab:CreateToggle("Team Check", false, function(state)
    State.TeamCheck = state
end, "Don't expand teammates")

HitboxTab:CreateButton("Reset Hitboxes", function()
    RestoreAll()
    Library:Notify("Hitbox", State.ExpandHitbox and "Reset — re-applying next frame" or "Restored")
end)

HitboxTab:CreateSeparator()
HitboxTab:CreateRichLabel(
    "<b>Tips</b>\n• Size <font color=\"rgb(100,200,255)\">12–20</font> is a good start\n• Leave Show Hitbox off for normal look\n• If throwables still miss, the game may validate hits on the server"
)

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
SettingsTab:CreateRichLabel("<b>GuysModz Baddies Hub v2.1</b>\nThrowable Hitbox (no freeze)\nPress RightShift to toggle UI.")

SettingsTab:CreateButton("Destroy UI", function()
    Library:CreateConfirmationDialog("Destroy UI", "Close the hub?", function()
        for name, _ in pairs(Connections) do Unbind(name) end
        RestoreAll()
        Watermark.Destroy()
        StatsDisplay.Destroy()
        Window:Destroy()
    end)
end)

--═══════════════════════════════════════════════════════════════
-- INIT
--═══════════════════════════════════════════════════════════════
Window:BindToggleKey(Enum.KeyCode.RightShift)

Library:Notify("GuysModz Baddies", "v2.1 loaded — hitbox won't freeze players. RightShift toggles UI.")
