--[[
    ═══════════════════════════════════════════════════════════════
     GuysModz Hub — Baddies Edition v2.0
     Throwable Hitbox Expander
     
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

--═══════════════════════════════════════════════════════════════
-- LOADING + WINDOW
--═══════════════════════════════════════════════════════════════
Library:CreateLoadingScreen("Loading GuysModz Baddies Hub...", 1.2)
task.wait(1.2)

local Watermark = Library:CreateWatermark("GuysModz Baddies v2.0")
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

-- Anti-AFK
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
    ShowHitbox = false, -- if true, slightly fade expanded parts so you can see size
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

-- Cache: [BasePart] = { Size, Transparency, CanCollide, Massless, CanTouch, CanQuery }
local Original = {}

-- Parts we expand for throwables (real character parts — not fake overlays)
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

local function CachePart(part)
    if Original[part] then return end
    Original[part] = {
        Size = part.Size,
        Transparency = part.Transparency,
        CanCollide = part.CanCollide,
        Massless = part.Massless,
        CanTouch = part.CanTouch,
        CanQuery = part.CanQuery,
    }
end

local function RestorePart(part)
    local data = Original[part]
    if not data or not part or not part.Parent then return end
    pcall(function()
        part.Size = data.Size
        part.Transparency = data.Transparency
        part.CanCollide = data.CanCollide
        part.Massless = data.Massless
        part.CanTouch = data.CanTouch
        part.CanQuery = data.CanQuery
    end)
end

local function RestoreAll()
    for part, _ in pairs(Original) do
        RestorePart(part)
    end
    Original = {}
end

local function ExpandPart(part, size)
    if not part or not part:IsA("BasePart") then return end
    CachePart(part)

    -- Real size expand — this is what throwable Touched / client hit checks use
    part.Size = Vector3.new(size, size, size)
    part.CanCollide = false
    part.Massless = true
    part.CanTouch = true
    part.CanQuery = true

    -- NEVER force high transparency (that made people disappear)
    if State.ShowHitbox then
        part.Transparency = 0.55
    else
        -- keep original look so avatars stay normal
        local data = Original[part]
        if data then
            part.Transparency = data.Transparency
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

-- Clean up when players leave / die
Players.PlayerRemoving:Connect(function(player)
    local char = player.Character
    if not char then return end
    for _, name in ipairs(EXPAND_NAMES) do
        local part = char:FindFirstChild(name)
        if part and Original[part] then
            RestorePart(part)
            Original[part] = nil
        end
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 1: HITBOX (throwable only)
--═══════════════════════════════════════════════════════════════
local HitboxTab = Window:CreateTab("Hitbox")

HitboxTab:CreateLabel("Throwable Hitbox Expander")
HitboxTab:CreateBadge("Throwables", Color3.fromRGB(255, 140, 30))
HitboxTab:CreateRichLabel(
    "<font color=\"rgb(180,180,200)\">Expands real body parts (HRP/Head/Torso) so snowballs and throwables can land easier.\nPlayers stay visible — no orange blobs, no grouping.</font>"
)

HitboxTab:CreateSeparator()

HitboxTab:CreateToggle("Expand Hitbox", false, function(state)
    State.ExpandHitbox = state
    if state then
        StartHitbox()
        Library:Notify("Hitbox", "Throwable hitbox ON — size " .. tostring(State.HitboxSize))
    else
        StopHitbox()
        Library:Notify("Hitbox", "Hitbox OFF — players restored")
    end
end, "Expand enemy hitboxes for throwables")

HitboxTab:CreateSlider("Hitbox Size", 5, 40, 15, function(value)
    State.HitboxSize = value
end, "Bigger = easier throwable hits")

HitboxTab:CreateToggle("Show Hitbox", false, function(state)
    State.ShowHitbox = state
    if not state then
        -- restore visual transparency immediately while keeping size if still expanded
        for part, data in pairs(Original) do
            if part and part.Parent then
                pcall(function()
                    part.Transparency = data.Transparency
                end)
            end
        end
    end
end, "Slightly fade parts so you can see the expanded size")

HitboxTab:CreateToggle("Team Check", false, function(state)
    State.TeamCheck = state
end, "Don't expand teammates")

HitboxTab:CreateButton("Reset Hitboxes", function()
    RestoreAll()
    if State.ExpandHitbox then
        -- will re-apply next frame
        Library:Notify("Hitbox", "Reset — re-applying...")
    else
        Library:Notify("Hitbox", "All hitboxes restored")
    end
end)

HitboxTab:CreateSeparator()
HitboxTab:CreateRichLabel(
    "<b>Tips</b>\n• Start around size <font color=\"rgb(100,200,255)\">12–20</font>\n• Keep <b>Show Hitbox</b> off for normal-looking players\n• If hits still miss, Baddies may check throwables on the server (client expand can't fix that)"
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
SettingsTab:CreateRichLabel("<b>GuysModz Baddies Hub v2.0</b>\nThrowable Hitbox Expander only\nPress RightShift to toggle UI.")

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

Library:Notify("GuysModz Baddies", "v2.0 loaded — Throwable Hitbox ready. RightShift toggles UI.")
