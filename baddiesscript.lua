--[[
    ═══════════════════════════════════════════════════════════════
     GuysModz Hub — Baddies Edition
     Game-specific script for Roblox Baddies
     
     Usage (one line in your executor):
       loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/baddiesscript.lua"))()
    ═══════════════════════════════════════════════════════════════
]]

--═══════════════════════════════════════════════════════════════
-- LOAD LIBRARY
--═══════════════════════════════════════════════════════════════
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/robloxui.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--═══════════════════════════════════════════════════════════════
-- 0. AUTH MODAL
--═══════════════════════════════════════════════════════════════
local ValidKeys = {
    "GuysModz-Baddies-2024",
    "VIP-Baddies-1234",
    "Free-Key-GuysModz",
}

local AuthResult = false

Library:CreateAuthModal({
    Title = "GuysModz Baddies Hub",
    Subtitle = "Enter your key to access Baddies features.",
    Placeholder = "Enter your key here...",
    ValidateKey = function(key)
        for _, valid in ipairs(ValidKeys) do
            if key == valid then return true end
        end
        return false
    end,
    OnSuccess = function()
        AuthResult = true
        Library:Notify("Welcome!", "Key accepted. Loading Baddies Hub...")
    end,
    OnFail = function(reason)
        if reason == "locked" then
            Library:Notify("Locked", "Too many failed attempts.")
        end
    end,
    MaxAttempts = 5,
    SaveKey = true,
    KeyFileName = "GuysModzBaddiesKey",
    GetKeyLink = "https://link-to-get-key.com",
})

while not AuthResult do task.wait(0.5) end
task.wait(0.3)

--═══════════════════════════════════════════════════════════════
-- LOADING + WINDOW
--═══════════════════════════════════════════════════════════════
Library:CreateLoadingScreen("Loading GuysModz Baddies Hub...", 2)
task.wait(2)

local Watermark = Library:CreateWatermark("GuysModz Baddies v1.0")
local StatsDisplay = Library:CreateStatsDisplay()
local Window = Library:CreateWindow("GuysModz | Baddies")

--═══════════════════════════════════════════════════════════════
-- HELPERS
--═══════════════════════════════════════════════════════════════
local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetDistance(part)
    local hrp = GetHRP()
    if not hrp or not part then return math.huge end
    return (hrp.Position - part.Position).Magnitude
end

local function IsAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function FindNearestPlayer(maxDist, teamCheck)
    local nearest, nearestDist = nil, maxDist or math.huge
    local myHRP = GetHRP()
    if not myHRP then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            if teamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                -- skip teammate
            else
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = player
                    end
                end
            end
        end
    end
    return nearest, nearestDist
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
    -- Farm
    AutoCash = false,
    AutoATM = false,
    AutoPickup = false,
    FarmRange = 50,
    FarmDelay = 0.3,

    -- Combat
    AutoPunch = false,
    AutoStomp = false,
    KillAura = false,
    KillAuraRange = 15,
    ExpandHitbox = false,
    HitboxSize = 10,
    TeamCheck = false,

    -- Player
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,

    -- Misc
    AntiRagdoll = false,
    AutoHospital = false,
    HospitalHP = 25,
    Fullbright = false,
    NoFog = false,
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

--═══════════════════════════════════════════════════════════════
-- TAB 1: MAIN / PLAYER
--═══════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main")

MainTab:CreateLabel("Player Settings")
MainTab:CreateBadge("Baddies Hub", Color3.fromRGB(255, 80, 140))

MainTab:CreateSlider("Walk Speed", 16, 200, 16, function(value)
    State.WalkSpeed = value
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = value end
end, "Change your movement speed")

MainTab:CreateSlider("Jump Power", 50, 300, 50, function(value)
    State.JumpPower = value
    local hum = GetHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = value
    end
end, "Change your jump height")

MainTab:CreateToggle("Infinite Jump", false, function(state)
    State.InfJump = state
    if state then
        Bind("InfJump", UserInputService.JumpRequest:Connect(function()
            if State.InfJump then
                local hum = GetHumanoid()
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end))
    else
        Unbind("InfJump")
    end
end, "Jump as many times as you want")

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
end, "Walk through walls")

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

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - look end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end

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
end, "Fly around the map (WASD + Space/Ctrl)")

MainTab:CreateSlider("Fly Speed", 10, 200, 50, function(value)
    State.FlySpeed = value
end, "How fast you fly")

MainTab:CreateSeparator()
MainTab:CreateLabel("Quick Actions")

MainTab:CreateButton("Reset Character", function()
    local char = GetCharacter()
    if char then char:BreakJoints() end
end, "Respawn your character")

MainTab:CreateButton("TP to Spawn", function()
    local hrp = GetHRP()
    if not hrp then return end
    local spawn = Workspace:FindFirstChild("SpawnLocation")
        or Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then
        hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        Library:Notify("Teleport", "Teleported to spawn.")
    else
        Library:Notify("Teleport", "Spawn not found.")
    end
end)

-- Keep walkspeed/jump after respawn
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
-- TAB 2: FARM
--═══════════════════════════════════════════════════════════════
local FarmTab = Window:CreateTab("Farm")

FarmTab:CreateLabel("Money Farming")
FarmTab:CreateBadge("Auto Farm", Color3.fromRGB(80, 200, 120))

local function CollectNearbyCash()
    local hrp = GetHRP()
    if not hrp then return 0 end
    local collected = 0

    -- Common cash/item names in Baddies-style games
    local keywords = {
        "cash", "money", "bill", "dollar", "drop", "loot",
        "pickup", "coin", "bag", "wallet", "tip"
    }

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            local name = string.lower(obj.Name)
            local match = false
            for _, kw in ipairs(keywords) do
                if string.find(name, kw) then
                    match = true
                    break
                end
            end
            if match then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist <= State.FarmRange then
                    -- Try touch / fire touch interest
                    pcall(function()
                        firetouchinterest(hrp, obj, 0)
                        firetouchinterest(hrp, obj, 1)
                    end)
                    -- Also try CFrame pull (safe soft TP of item toward player if possible)
                    pcall(function()
                        if obj:IsA("BasePart") and not obj.Anchored then
                            obj.CFrame = hrp.CFrame
                        end
                    end)
                    collected += 1
                end
            end
        end
        -- ProximityPrompt pickup
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (hrp.Position - parent.Position).Magnitude
                if dist <= math.max(State.FarmRange, obj.MaxActivationDistance + 5) then
                    pcall(function()
                        fireproximityprompt(obj)
                    end)
                    collected += 1
                end
            end
        end
    end
    return collected
end

local function FindATMs()
    local atms = {}
    local keywords = { "atm", "register", "cashregister", "bank", "teller", "machine" }
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(obj.Name)
        for _, kw in ipairs(keywords) do
            if string.find(name, kw) then
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    table.insert(atms, obj)
                end
                break
            end
        end
    end
    return atms
end

FarmTab:CreateToggle("Auto Pickup Cash", false, function(state)
    State.AutoPickup = state
    if state then
        Bind("AutoPickup", task.spawn(function()
            while State.AutoPickup do
                pcall(CollectNearbyCash)
                task.wait(State.FarmDelay)
            end
        end))
        Library:Notify("Farm", "Auto Pickup enabled.")
    else
        Unbind("AutoPickup")
        Library:Notify("Farm", "Auto Pickup disabled.")
    end
end, "Automatically collect nearby cash/items")

FarmTab:CreateToggle("Auto ATM Farm", false, function(state)
    State.AutoATM = state
    if state then
        Bind("AutoATM", task.spawn(function()
            while State.AutoATM do
                pcall(function()
                    local hrp = GetHRP()
                    if not hrp then return end
                    local atms = FindATMs()
                    for _, atm in ipairs(atms) do
                        if not State.AutoATM then break end
                        local part = atm:IsA("BasePart") and atm or atm:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local dist = (hrp.Position - part.Position).Magnitude
                            if dist <= State.FarmRange * 2 then
                                -- Fire prompts on ATM
                                for _, desc in ipairs(atm:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt") then
                                        pcall(function() fireproximityprompt(desc) end)
                                    end
                                    if desc:IsA("ClickDetector") then
                                        pcall(function() fireclickdetector(desc) end)
                                    end
                                end
                                pcall(function()
                                    firetouchinterest(hrp, part, 0)
                                    firetouchinterest(hrp, part, 1)
                                end)
                            end
                        end
                    end
                end)
                task.wait(State.FarmDelay + 0.2)
            end
        end))
        Library:Notify("Farm", "Auto ATM Farm enabled.")
    else
        Unbind("AutoATM")
        Library:Notify("Farm", "Auto ATM Farm disabled.")
    end
end, "Interact with nearby ATMs/registers")

FarmTab:CreateToggle("Auto Cash Loop", false, function(state)
    State.AutoCash = state
    if state then
        Bind("AutoCash", task.spawn(function()
            while State.AutoCash do
                pcall(function()
                    CollectNearbyCash()
                    -- Also try common remote names (best-effort)
                    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                            local n = string.lower(remote.Name)
                            if string.find(n, "cash") or string.find(n, "money") or string.find(n, "collect") or string.find(n, "pickup") then
                                pcall(function()
                                    if remote:IsA("RemoteEvent") then
                                        remote:FireServer()
                                    end
                                end)
                            end
                        end
                    end
                end)
                task.wait(State.FarmDelay)
            end
        end))
        Library:Notify("Farm", "Auto Cash Loop enabled.")
    else
        Unbind("AutoCash")
        Library:Notify("Farm", "Auto Cash Loop disabled.")
    end
end, "Loop cash pickup + try collect remotes")

FarmTab:CreateSeparator()
FarmTab:CreateLabel("Farm Settings")

FarmTab:CreateSlider("Farm Range", 10, 200, 50, function(value)
    State.FarmRange = value
end, "How far to collect/farm")

FarmTab:CreateSlider("Farm Delay", 0.1, 2, 0.3, function(value)
    State.FarmDelay = value
end, "Delay between farm actions", 1)

FarmTab:CreateButton("Collect Once", function()
    local count = CollectNearbyCash()
    Library:Notify("Farm", "Collected near " .. tostring(count) .. " objects.")
end)

FarmTab:CreateButton("TP to Nearest ATM", function()
    local hrp = GetHRP()
    if not hrp then return end
    local atms = FindATMs()
    local nearest, nearestDist = nil, math.huge
    for _, atm in ipairs(atms) do
        local part = atm:IsA("BasePart") and atm or atm:FindFirstChildWhichIsA("BasePart", true)
        if part then
            local dist = (hrp.Position - part.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = part
            end
        end
    end
    if nearest then
        hrp.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
        Library:Notify("Farm", "Teleported to ATM (" .. math.floor(nearestDist) .. " studs).")
    else
        Library:Notify("Farm", "No ATM found.")
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 3: COMBAT
--═══════════════════════════════════════════════════════════════
local CombatTab = Window:CreateTab("Combat")

CombatTab:CreateLabel("Combat Tools")
CombatTab:CreateBadge("PvP", Color3.fromRGB(255, 80, 80))

local function TryCombatAction(actionName)
    -- Best-effort: fire remotes / tools related to combat
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local n = string.lower(remote.Name)
            if string.find(n, actionName) or string.find(n, "punch") or string.find(n, "hit")
                or string.find(n, "stomp") or string.find(n, "attack") or string.find(n, "combat") then
                pcall(function() remote:FireServer() end)
            end
        end
    end

    -- Activate tools
    local char = GetCharacter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local function activateTools(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                pcall(function()
                    if char and not tool.Parent == char then
                        -- leave equipped tools alone unless already equipped
                    end
                    tool:Activate()
                end)
            end
        end
    end
    if char then activateTools(char) end
end

CombatTab:CreateToggle("Auto Punch", false, function(state)
    State.AutoPunch = state
    if state then
        Bind("AutoPunch", task.spawn(function()
            while State.AutoPunch do
                pcall(function()
                    TryCombatAction("punch")
                    -- Also click
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new())
                end)
                task.wait(0.15)
            end
        end))
        Library:Notify("Combat", "Auto Punch enabled.")
    else
        Unbind("AutoPunch")
        Library:Notify("Combat", "Auto Punch disabled.")
    end
end, "Spam punch / attack")

CombatTab:CreateToggle("Auto Stomp", false, function(state)
    State.AutoStomp = state
    if state then
        Bind("AutoStomp", task.spawn(function()
            while State.AutoStomp do
                pcall(function()
                    local target = FindNearestPlayer(State.KillAuraRange + 10, State.TeamCheck)
                    if target and target.Character then
                        local hum = target.Character:FindFirstChildOfClass("Humanoid")
                        -- Prefer stomping ragdolled / low HP players
                        if hum and (hum.Health < hum.MaxHealth * 0.35 or hum:GetState() == Enum.HumanoidStateType.Physics) then
                            local myHRP = GetHRP()
                            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                            if myHRP and tHRP then
                                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 3, 0)
                            end
                            TryCombatAction("stomp")
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new())
                        end
                    end
                end)
                task.wait(0.25)
            end
        end))
        Library:Notify("Combat", "Auto Stomp enabled.")
    else
        Unbind("AutoStomp")
        Library:Notify("Combat", "Auto Stomp disabled.")
    end
end, "Auto stomp nearby downed players")

CombatTab:CreateToggle("Kill Aura", false, function(state)
    State.KillAura = state
    if state then
        Bind("KillAura", task.spawn(function()
            while State.KillAura do
                pcall(function()
                    local target, dist = FindNearestPlayer(State.KillAuraRange, State.TeamCheck)
                    if target and dist <= State.KillAuraRange then
                        TryCombatAction("attack")
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new())
                    end
                end)
                task.wait(0.12)
            end
        end))
        Library:Notify("Combat", "Kill Aura enabled.")
    else
        Unbind("KillAura")
        Library:Notify("Combat", "Kill Aura disabled.")
    end
end, "Auto attack players in range")

CombatTab:CreateSlider("Kill Aura Range", 5, 50, 15, function(value)
    State.KillAuraRange = value
end, "Attack range for kill aura / stomp")

CombatTab:CreateToggle("Team Check", false, function(state)
    State.TeamCheck = state
end, "Don't target teammates")

CombatTab:CreateSeparator()
CombatTab:CreateLabel("Hitbox")

local OriginalSizes = {}

CombatTab:CreateToggle("Expand Hitbox", false, function(state)
    State.ExpandHitbox = state
    if state then
        Bind("Hitbox", RunService.RenderStepped:Connect(function()
            if not State.ExpandHitbox then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and IsAlive(player) then
                    if State.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                        -- skip
                    else
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if not OriginalSizes[hrp] then
                                OriginalSizes[hrp] = hrp.Size
                            end
                            hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                            hrp.Transparency = 0.7
                            hrp.CanCollide = false
                        end
                    end
                end
            end
        end))
        Library:Notify("Combat", "Hitbox expand enabled.")
    else
        Unbind("Hitbox")
        -- Restore
        for hrp, size in pairs(OriginalSizes) do
            pcall(function()
                hrp.Size = size
                hrp.Transparency = 0
            end)
        end
        OriginalSizes = {}
        Library:Notify("Combat", "Hitbox expand disabled.")
    end
end, "Make enemy hitboxes bigger")

CombatTab:CreateSlider("Hitbox Size", 2, 30, 10, function(value)
    State.HitboxSize = value
end, "Size of expanded hitboxes")

CombatTab:CreateSeparator()
CombatTab:CreateLabel("Targeting")

CombatTab:CreateButton("TP to Nearest Player", function()
    local target = FindNearestPlayer(10000, State.TeamCheck)
    local myHRP = GetHRP()
    if target and myHRP and target.Character then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
            Library:Notify("Combat", "Teleported to " .. target.Name)
        end
    else
        Library:Notify("Combat", "No player found.")
    end
end)

CombatTab:CreateTextBox("TP to Player Name", function(text)
    local target = Players:FindFirstChild(text)
    local myHRP = GetHRP()
    if target and target.Character and myHRP then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
            Library:Notify("Combat", "Teleported to " .. target.Name)
        end
    else
        Library:Notify("Combat", "Player not found.")
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 4: MISC / SURVIVAL
--═══════════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("Misc")

MiscTab:CreateLabel("Survival")
MiscTab:CreateBadge("Utility", Color3.fromRGB(255, 180, 50))

MiscTab:CreateToggle("Anti Ragdoll", false, function(state)
    State.AntiRagdoll = state
    if state then
        Bind("AntiRagdoll", RunService.Heartbeat:Connect(function()
            if not State.AntiRagdoll then return end
            local hum = GetHumanoid()
            local char = GetCharacter()
            if hum then
                -- Break out of physics/ragdoll-like states
                if hum:GetState() == Enum.HumanoidStateType.Physics
                    or hum:GetState() == Enum.HumanoidStateType.Ragdoll
                    or hum:GetState() == Enum.HumanoidStateType.FallingDown then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hum.PlatformStand = false
                end
                hum.PlatformStand = false
            end
            if char then
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("BallSocketConstraint") or string.find(string.lower(obj.Name), "ragdoll") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end))
        Library:Notify("Misc", "Anti Ragdoll enabled.")
    else
        Unbind("AntiRagdoll")
        Library:Notify("Misc", "Anti Ragdoll disabled.")
    end
end, "Try to prevent / recover from ragdoll")

MiscTab:CreateToggle("Auto Hospital (Low HP)", false, function(state)
    State.AutoHospital = state
    if state then
        Bind("AutoHospital", task.spawn(function()
            while State.AutoHospital do
                pcall(function()
                    local hum = GetHumanoid()
                    local hrp = GetHRP()
                    if hum and hrp and hum.Health > 0 and hum.Health <= State.HospitalHP then
                        -- Find hospital / bed / nurse
                        local keywords = { "hospital", "bed", "nurse", "medic", "heal", "clinic" }
                        local best, bestDist = nil, math.huge
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            local n = string.lower(obj.Name)
                            for _, kw in ipairs(keywords) do
                                if string.find(n, kw) then
                                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                                    if part then
                                        local d = (hrp.Position - part.Position).Magnitude
                                        if d < bestDist then
                                            bestDist = d
                                            best = part
                                        end
                                    end
                                    break
                                end
                            end
                        end
                        if best then
                            hrp.CFrame = best.CFrame + Vector3.new(0, 3, 0)
                            Library:Notify("Hospital", "Low HP! Escaped to hospital area.")
                            task.wait(3)
                        end
                    end
                end)
                task.wait(0.5)
            end
        end))
        Library:Notify("Misc", "Auto Hospital enabled.")
    else
        Unbind("AutoHospital")
        Library:Notify("Misc", "Auto Hospital disabled.")
    end
end, "TP to hospital when HP is low")

MiscTab:CreateSlider("Hospital HP Threshold", 5, 80, 25, function(value)
    State.HospitalHP = value
end, "HP % threshold to flee")

MiscTab:CreateSeparator()
MiscTab:CreateLabel("Visuals")

MiscTab:CreateToggle("Fullbright", false, function(state)
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

MiscTab:CreateToggle("No Fog", false, function(state)
    State.NoFog = state
    if state then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 10000
    end
end)

MiscTab:CreateDropdown("Time of Day", {"Morning", "Noon", "Evening", "Night"}, "Noon", function(selected)
    local times = { Morning = 6, Noon = 12, Evening = 18, Night = 0 }
    Lighting.ClockTime = times[selected] or 12
end)

MiscTab:CreateSeparator()
MiscTab:CreateLabel("Anti AFK")
MiscTab:CreateRichLabel("Anti-AFK is always on while this script is running.\nYou won't get kicked for being idle.")

--═══════════════════════════════════════════════════════════════
-- TAB 5: TELEPORT
--═══════════════════════════════════════════════════════════════
local TPTab = Window:CreateTab("Teleport")

TPTab:CreateLabel("Player Teleport")

TPTab:CreateSearchBox("Search Players...", function(query)
    -- visual only; dropdown below lists players
end)

local function RefreshPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
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
    Library:Notify("Teleport", "Player list refreshed.")
end)

TPTab:CreateSeparator()
TPTab:CreateLabel("Locations")

TPTab:CreateButton("TP to Spawn", function()
    local hrp = GetHRP()
    if not hrp then return end
    local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if spawn then
        hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        Library:Notify("Teleport", "Teleported to spawn.")
    else
        Library:Notify("Teleport", "Spawn not found.")
    end
end)

TPTab:CreateButton("TP to Nearest Cash", function()
    local hrp = GetHRP()
    if not hrp then return end
    local best, bestDist = nil, math.huge
    local keywords = { "cash", "money", "bill", "dollar", "bag" }
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            for _, kw in ipairs(keywords) do
                if string.find(n, kw) then
                    local d = (hrp.Position - obj.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = obj
                    end
                    break
                end
            end
        end
    end
    if best then
        hrp.CFrame = best.CFrame + Vector3.new(0, 3, 0)
        Library:Notify("Teleport", "Teleported to cash (" .. math.floor(bestDist) .. " studs).")
    else
        Library:Notify("Teleport", "No cash found.")
    end
end)

--═══════════════════════════════════════════════════════════════
-- TAB 6: SETTINGS
--═══════════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateLabel("UI Settings")
SettingsTab:CreateKeybind("Toggle UI", Enum.KeyCode.RightShift, function() end)
SettingsTab:CreateRainbowToggle("Rainbow Mode", false, function(state)
    Library:Notify("Rainbow", state and "Enabled" or "Disabled")
end)

SettingsTab:CreateSeparator()
SettingsTab:CreateLabel("Theme")
SettingsTab:CreateDropdown("Theme", {"Dark", "Midnight", "BloodRed", "Green", "Purple", "Orange"}, "Dark", function(selected)
    local preset = Library.Presets[selected]
    if preset then
        Library:SetTheme(preset)
        Library:Notify("Theme", "Switched to " .. selected)
    end
end)

SettingsTab:CreateSeparator()
SettingsTab:CreateLabel("Config")
SettingsTab:CreateButton("Save Config", function()
    if Library.Config:Save() then
        Library:Notify("Saved", "Config saved.")
    else
        Library:Notify("Error", "writefile not supported.")
    end
end)
SettingsTab:CreateButton("Load Config", function()
    if Library.Config:Load() then
        Library:Notify("Loaded", "Config loaded.")
    else
        Library:Notify("Error", "No config found.")
    end
end)

SettingsTab:CreateSeparator()
SettingsTab:CreateLabel("About")
SettingsTab:CreateRichLabel("<b>GuysModz Baddies Hub v1.0</b>\nMade for Baddies\nPress RightShift to toggle UI.\n\nAuth keys:\nGuysModz-Baddies-2024\nVIP-Baddies-1234\nFree-Key-GuysModz")

SettingsTab:CreateButton("Destroy UI", function()
    Library:CreateConfirmationDialog("Destroy UI", "Close the entire hub?", function()
        for name, _ in pairs(Connections) do Unbind(name) end
        Watermark.Destroy()
        StatsDisplay.Destroy()
        Window:Destroy()
    end)
end)

--═══════════════════════════════════════════════════════════════
-- INIT
--═══════════════════════════════════════════════════════════════
Window:BindToggleKey(Enum.KeyCode.RightShift)

Library.Config:Register("WalkSpeed", function() return State.WalkSpeed end, function(v) State.WalkSpeed = v end)
Library.Config:Register("JumpPower", function() return State.JumpPower end, function(v) State.JumpPower = v end)
Library.Config:Register("FarmRange", function() return State.FarmRange end, function(v) State.FarmRange = v end)
Library.Config:Register("KillAuraRange", function() return State.KillAuraRange end, function(v) State.KillAuraRange = v end)

Library:Notify("GuysModz Baddies", "Loaded! Press RightShift to toggle UI.")
