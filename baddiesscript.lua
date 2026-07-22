--[[
    ═══════════════════════════════════════════════════════════════
     GuysModz Hub — Baddies Edition v3.3
     Snowball Launcher Magnet (prop-safe)
     
     Usage:
       loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/baddiesscript.lua"))()
    ═══════════════════════════════════════════════════════════════
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GuysServices/uilibtesting/main/robloxui.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--═══════════════════════════════════════════════════════════════
-- LOADING + WINDOW
--═══════════════════════════════════════════════════════════════
Library:CreateLoadingScreen("Loading GuysModz Baddies Hub...", 1.0)
task.wait(1.0)

local Watermark = Library:CreateWatermark("GuysModz Baddies v3.3")
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
    MagnetRange = 120,      -- snowball launchers need longer range
    MagnetStrength = 0.7,   -- stronger home for launcher projectiles
    TargetPart = "HumanoidRootPart", -- Head / HumanoidRootPart / UpperTorso
    TeamCheck = false,
    OnlyMyThrowables = true,
    MaxTrackTime = 6,       -- seconds to keep steering a projectile
    LauncherAssist = true,  -- extra detection while holding snowball launcher
    DebugTrack = true,      -- show last tracked projectile name

    -- Optional body expand (melee only — does NOT help server throwables)
    ExpandHitbox = false,
    HitboxSize = 12,
    ShowHitbox = false,
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
local Tracked = {} -- [BasePart] = data
local StatusLabel
local LastTrackedName = "none"
local FireWindowUntil = 0 -- after launcher fire, accept nearby new parts briefly
local SeenParts = {} -- weak-ish set of parts we already evaluated this session
local UserInputService = game:GetService("UserInputService")

-- STRICT name hints only. Generic words like "part"/"mesh"/"ball" fling map props.
local THROWABLE_NAME_HINTS = {
    "snowball", "snow ball", "snow_ball", "sball", "sb_",
    "projectile", "proj_", "missile", "rocket",
    "bullet", "pellet", "dart", "slug",
}

local LAUNCHER_TOOL_HINTS = {
    "snowball", "snow ball", "snow launcher", "snowball launcher",
    "launcher", "sball",
}

-- Map / prop names we must NEVER steer
local BLOCKED_NAME_HINTS = {
    "chair", "seat", "couch", "sofa", "table", "desk", "bench",
    "pretzel", "chicken", "bucket", "food", "drink", "juice",
    "box", "crate", "sign", "door", "wall", "floor", "roof",
    "tree", "bush", "plant", "rock", "stone", "fence", "gate",
    "car", "vehicle", "bike", "wheel", "light", "lamp", "neon",
    "spawn", "baseplate", "terrain", "water", "ocean",
    "npc", "dummy", "rig", "man", "woman",
}

local PROJECTILE_FOLDERS = {
    "Projectiles", "Thrown", "Throwables", "Bullets", "Missiles",
    "Snowballs", "Snowball", "ClientProjectiles", "ServerProjectiles",
    "WorkspaceProjectiles",
}

local function NameLooksBlocked(name)
    if not name then return false end
    local lower = string.lower(name)
    for _, hint in ipairs(BLOCKED_NAME_HINTS) do
        if string.find(lower, hint, 1, true) then
            return true
        end
    end
    return false
end

local function NameLooksThrowable(name)
    if not name or NameLooksBlocked(name) then return false end
    local lower = string.lower(name)
    for _, hint in ipairs(THROWABLE_NAME_HINTS) do
        if string.find(lower, hint, 1, true) then
            return true
        end
    end
    return false
end

local function NameLooksLauncher(name)
    if not name then return false end
    local lower = string.lower(name)
    for _, hint in ipairs(LAUNCHER_TOOL_HINTS) do
        if string.find(lower, hint, 1, true) then
            return true
        end
    end
    return false
end

local function IsDescendantOfLocalCharacter(inst)
    local char = LocalPlayer.Character
    return char and inst and inst:IsDescendantOf(char)
end

local function IsPlayerCharacterPart(inst)
    if not inst then return false end
    local model = inst:FindFirstAncestorOfClass("Model")
    if not model then return false end
    if Players:GetPlayerFromCharacter(model) then
        return true
    end
    -- Character-like models (NPCs) — still don't fling
    if model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        return true
    end
    return false
end

local function GetEquippedTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function HoldingLauncherTool()
    local tool = GetEquippedTool()
    if not tool then return false end
    -- Only the tool name itself — scanning descendants matched random parts before
    return NameLooksLauncher(tool.Name)
end

local function InFireWindow()
    return tick() < FireWindowUntil
end

local function OpenFireWindow(seconds)
    FireWindowUntil = math.max(FireWindowUntil, tick() + (seconds or 0.8))
end

local function IsWorldProp(part)
    if not part then return true end
    if NameLooksBlocked(part.Name) then return true end
    if part.Parent and NameLooksBlocked(part.Parent.Name) then return true end
    if part.Parent and part.Parent.Parent and NameLooksBlocked(part.Parent.Parent.Name) then return true end

    -- Anchored map furniture sitting still is never a snowball
    local speed = 0
    pcall(function() speed = part.AssemblyLinearVelocity.Magnitude end)
    if part.Anchored and speed < 1 and not InFireWindow() then
        return true
    end

    -- Very large-ish decorative pieces
    local s = part.Size
    if s.X >= 4 or s.Y >= 4 or s.Z >= 4 then
        -- snowballs are small; allow only if name is clearly projectile
        if not NameLooksThrowable(part.Name) and not (part.Parent and NameLooksThrowable(part.Parent.Name)) then
            return true
        end
    end

    return false
end

local function OwnedByLocalPlayer(inst)
    if not inst or typeof(inst) ~= "Instance" then
        return false
    end

    local checks = { inst }
    if inst.Parent then table.insert(checks, inst.Parent) end
    if inst.Parent and inst.Parent.Parent then table.insert(checks, inst.Parent.Parent) end

    for _, node in ipairs(checks) do
        local ok, val

        ok, val = pcall(function() return node:GetAttribute("Owner") end)
        if ok and val ~= nil then
            if val == LocalPlayer.UserId or val == LocalPlayer.Name or val == tostring(LocalPlayer.UserId) then
                return true
            end
            if typeof(val) == "Instance" and (val == LocalPlayer or val == LocalPlayer.Character) then
                return true
            end
        end

        for _, attr in ipairs({ "OwnerId", "UserId", "ThrowerId", "Shooter", "CreatorId" }) do
            ok, val = pcall(function() return node:GetAttribute(attr) end)
            if ok and (val == LocalPlayer.UserId or val == tostring(LocalPlayer.UserId) or val == LocalPlayer.Name) then
                return true
            end
        end

        for _, childName in ipairs({ "Owner", "Creator", "Player", "Thrower", "Shooter", "creator" }) do
            local okChild, v = pcall(function() return node:FindFirstChild(childName) end)
            if okChild and v then
                if v:IsA("ObjectValue") and (v.Value == LocalPlayer or v.Value == LocalPlayer.Character) then
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
    end

    return false
end

local function GetPartSpeed(part)
    local speed = 0
    pcall(function()
        speed = part.AssemblyLinearVelocity.Magnitude
    end)
    if speed < 1 then
        -- BodyVelocity / LinearVelocity constraints (older + newer projectile systems)
        pcall(function()
            for _, d in ipairs(part:GetDescendants()) do
                if d:IsA("BodyVelocity") then
                    speed = math.max(speed, d.Velocity.Magnitude)
                elseif d.ClassName == "LinearVelocity" then
                    local v = d.VectorVelocity
                    if typeof(v) == "Vector3" then
                        speed = math.max(speed, v.Magnitude)
                    end
                elseif d:IsA("VectorForce") then
                    speed = math.max(speed, 30) -- treat as propelled
                end
            end
        end)
        -- parent-level movers
        pcall(function()
            local p = part.Parent
            if p then
                for _, d in ipairs(p:GetChildren()) do
                    if d:IsA("BodyVelocity") then
                        speed = math.max(speed, d.Velocity.Magnitude)
                    end
                end
            end
        end)
    end
    return speed
end

local function IsSafeProjectileCandidate(part)
    if not part or typeof(part) ~= "Instance" then return false end
    if not part:IsA("BasePart") then return false end
    if not part.Parent then return false end

    -- never touch characters / accessories / backpack tools on people
    if IsDescendantOfLocalCharacter(part) then return false end
    if IsPlayerCharacterPart(part) then return false end
    if part:FindFirstAncestorOfClass("Accessory") then return false end
    if IsWorldProp(part) then return false end

    local toolAnc = part:FindFirstAncestorOfClass("Tool")
    if toolAnc then
        local toolParent = toolAnc.Parent
        if toolParent and (toolParent:IsA("Model") and Players:GetPlayerFromCharacter(toolParent)) then
            return false
        end
        if toolParent and toolParent:IsA("Backpack") then
            return false
        end
    end

    -- snowballs are small
    local size = part.Size
    if size.X > 5 or size.Y > 5 or size.Z > 5 then return false end
    if size.Magnitude < 0.05 or size.Magnitude > 7 then return false end

    return true
end

local function IsLikelyThrowable(part)
    if not IsSafeProjectileCandidate(part) then return false end

    local size = part.Size
    local speed = GetPartSpeed(part)
    local myHRP = GetHRP()
    local cam = Workspace.CurrentCamera
    local origin = myHRP and myHRP.Position or (cam and cam.CFrame.Position)
    if not origin then return false end

    local distMe = (part.Position - origin).Magnitude
    local parent = part.Parent
    local owned = OwnedByLocalPlayer(part) or (parent and OwnedByLocalPlayer(parent)) or false
    local nameHit = NameLooksThrowable(part.Name)
        or (parent and NameLooksThrowable(parent.Name))
        or false

    local launcher = HoldingLauncherTool()
    local fireWin = InFireWindow()
    local nearMe = distMe < 35
    local moving = speed >= 25 -- real shots are fast; chairs/food are not

    -- Must be in front of camera (projectiles leave the gun forward)
    local inFront = true
    if cam then
        local toPart = part.Position - cam.CFrame.Position
        if toPart.Magnitude > 1 then
            inFront = cam.CFrame.LookVector:Dot(toPart.Unit) > 0.35
        end
    end

    -- 1) Explicitly owned projectile near us
    if owned and nearMe and (moving or (part.Anchored and fireWin and nameHit)) and inFront then
        return true
    end

    -- 2) Clear projectile name + moving fast
    if nameHit and moving and distMe < 100 and inFront then
        return true
    end

    -- 3) Launcher fire window ONLY: brand-new FAST part that just spawned near muzzle
    --    Requires fire window + launcher equipped + high speed + small size + in front
    if State.LauncherAssist and launcher and fireWin and nearMe and inFront then
        if moving and size.Magnitude <= 4 and not part.Anchored then
            return true
        end
        -- anchored CFrame projectile with projectile-like name only
        if part.Anchored and nameHit and size.Magnitude <= 4 then
            return true
        end
    end

    return false
end

local function SetMoverVelocity(part, vel)
    -- Prefer constraint movers if present; else AssemblyLinearVelocity
    local set = false
    pcall(function()
        for _, d in ipairs(part:GetDescendants()) do
            if d:IsA("BodyVelocity") then
                d.Velocity = vel
                set = true
            elseif d.ClassName == "LinearVelocity" then
                pcall(function() d.VectorVelocity = vel end)
                set = true
            end
        end
        local p = part.Parent
        if p then
            for _, d in ipairs(p:GetChildren()) do
                if d:IsA("BodyVelocity") then
                    d.Velocity = vel
                    set = true
                end
            end
        end
    end)
    if not set then
        pcall(function()
            part.AssemblyLinearVelocity = vel
        end)
    end
end

local function SteerProjectile(part, data, targetPart)
    if not part or not part.Parent or not targetPart or not targetPart.Parent then return end
    if IsPlayerCharacterPart(part) then return end
    if not IsSafeProjectileCandidate(part) then return end

    local targetPos = targetPart.Position
    pcall(function()
        local vel = targetPart.AssemblyLinearVelocity
        targetPos = targetPos + vel * 0.08
    end)

    local pos = part.Position
    local toTarget = targetPos - pos
    local dist = toTarget.Magnitude
    if dist < 0.2 or dist > State.MagnetRange then return end

    local dir = toTarget.Unit
    local strength = math.clamp(State.MagnetStrength, 0.2, 0.95)

    -- Track last position to estimate speed for anchored projectiles
    local lastPos = data.lastPos or pos
    local dt = data._dt or (1/60)
    local measured = (pos - lastPos).Magnitude / math.max(dt, 1/240)
    data.lastPos = pos

    local speed = GetPartSpeed(part)
    if speed < 10 then
        speed = math.max(measured, 70) -- launcher snowballs are usually fast
    end

    if part.Anchored then
        -- CFrame-based projectiles (common for launcher systems)
        -- Soft step toward target — NOT a full snap onto the player (avoids fling)
        local step = math.clamp(speed * dt * (0.6 + strength), 1, 18)
        local newPos = pos:Lerp(pos + dir * step, 1)
        -- blend current forward with to-target so path curves in
        local look = pos + dir
        pcall(function()
            part.CFrame = CFrame.new(newPos, look)
        end)
    else
        local current = Vector3.zero
        pcall(function() current = part.AssemblyLinearVelocity end)
        if current.Magnitude < 5 and measured > 5 then
            current = (pos - lastPos) / math.max(dt, 1/240)
        end
        local desired = dir * math.max(speed, 50)
        local newVel = current:Lerp(desired, strength)
        SetMoverVelocity(part, newVel)
    end
end

local function TryTrack(part)
    if not State.MagnetEnabled then return end
    if not part or typeof(part) ~= "Instance" then return end
    if Tracked[part] then return end
    if SeenParts[part] and not InFireWindow() then
        -- still allow recheck during fire window
    end
    if IsPlayerCharacterPart(part) then return end
    if not IsLikelyThrowable(part) then
        SeenParts[part] = true
        return
    end

    local fromPos = part.Position
    local _, targetPart = GetClosestTarget(fromPos, State.MagnetRange)
    Tracked[part] = {
        start = tick(),
        targetPart = targetPart,
        lastPos = fromPos,
        _dt = 1/60,
        name = part.Name,
    }
    LastTrackedName = part.Name .. (part.Parent and ("/" .. part.Parent.Name) or "")
    SeenParts[part] = true
end

local function TryTrackModel(model)
    if not model then return end
    if IsPlayerCharacterPart(model) then return end
    -- Prefer PrimaryPart / largest small part
    local best, bestScore = nil, -1
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") and IsSafeProjectileCandidate(d) then
            local score = 1
            if model.PrimaryPart == d then score = score + 5 end
            if NameLooksThrowable(d.Name) then score = score + 3 end
            local sp = GetPartSpeed(d)
            score = score + math.min(sp / 20, 3)
            if score > bestScore then
                bestScore = score
                best = d
            end
        end
    end
    if best then TryTrack(best) end
end

local function ScanWorkspaceForThrowables()
    local myHRP = GetHRP()
    local cam = Workspace.CurrentCamera
    if not myHRP and not cam then return end
    local origin = myHRP and myHRP.Position or cam.CFrame.Position
    -- Only scan near muzzle during/after fire — never vacuum the whole map
    if not (HoldingLauncherTool() or InFireWindow()) then
        return
    end
    local radius = 30

    local roots = {}
    for _, name in ipairs(PROJECTILE_FOLDERS) do
        local f = Workspace:FindFirstChild(name)
        if f then table.insert(roots, f) end
    end

    -- During fire window, also check direct Workspace children that look like projectiles
    -- (NOT every prop — only name match or very fast small parts)
    table.insert(roots, Workspace)

    for _, root in ipairs(roots) do
        local ok, children = pcall(function() return root:GetChildren() end)
        if ok and children then
            for _, inst in ipairs(children) do
                if inst:IsA("BasePart") then
                    if (inst.Position - origin).Magnitude < radius then
                        TryTrack(inst)
                    end
                elseif inst:IsA("Model") and not Players:GetPlayerFromCharacter(inst) then
                    local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
                    if pp and (pp.Position - origin).Magnitude < radius then
                        -- only models that look like projectiles or are moving fast
                        if NameLooksThrowable(inst.Name) or GetPartSpeed(pp) >= 25 then
                            TryTrackModel(inst)
                        end
                    end
                elseif inst:IsA("Folder") then
                    for _, d in ipairs(inst:GetChildren()) do
                        if d:IsA("BasePart") and (d.Position - origin).Magnitude < radius then
                            TryTrack(d)
                        elseif d:IsA("Model") then
                            local p2 = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
                            if p2 and (p2.Position - origin).Magnitude < radius then
                                if NameLooksThrowable(d.Name) or GetPartSpeed(p2) >= 25 then
                                    TryTrackModel(d)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function StartMagnet()
    -- New instances anywhere under Workspace
    Bind("MagnetAdded", Workspace.DescendantAdded:Connect(function(inst)
        if not State.MagnetEnabled then return end
        task.defer(function()
            -- wait a couple frames so velocity/owner/name settle
            task.wait()
            task.wait()
            if inst:IsA("BasePart") then
                TryTrack(inst)
            elseif inst:IsA("Model") then
                TryTrackModel(inst)
            end
        end)
    end))

    -- When player fires while holding a real launcher tool only
    Bind("MagnetTool", UserInputService.InputBegan:Connect(function(input, gp)
        if not State.MagnetEnabled or gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
            or input.KeyCode == Enum.KeyCode.ButtonR2 then
            if HoldingLauncherTool() then
                OpenFireWindow(0.8)
                task.spawn(function()
                    for _ = 1, 10 do
                        if not State.MagnetEnabled then break end
                        pcall(ScanWorkspaceForThrowables)
                        task.wait(0.03)
                    end
                end)
            end
        end
    end))

    -- Also hook Tool.Activated if available
    local function HookTool(tool)
        if not tool or not tool:IsA("Tool") then return end
        if tool:GetAttribute("GuysModzHooked") then return end
        tool:SetAttribute("GuysModzHooked", true)
        tool.Activated:Connect(function()
            if not State.MagnetEnabled then return end
            if not NameLooksLauncher(tool.Name) then return end
            OpenFireWindow(0.8)
            task.spawn(function()
                for _ = 1, 10 do
                    pcall(ScanWorkspaceForThrowables)
                    task.wait(0.03)
                end
            end)
        end)
    end

    local function HookCharacter(char)
        if not char then return end
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then HookTool(c) end
        end
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then HookTool(c) end
        end)
    end

    if LocalPlayer.Character then HookCharacter(LocalPlayer.Character) end
    Bind("MagnetChar", LocalPlayer.CharacterAdded:Connect(HookCharacter))

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then HookTool(t) end
        end
        Bind("MagnetBag", backpack.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then HookTool(c) end
        end))
    end

    -- Steer loop
    local last = tick()
    Bind("Magnet", RunService.Heartbeat:Connect(function()
        if not State.MagnetEnabled then return end

        local now = tick()
        local dt = math.clamp(now - last, 1/240, 0.05)
        last = now

        local trackedCount = 0

        for part, data in pairs(Tracked) do
            if not part or not part.Parent then
                Tracked[part] = nil
            elseif IsPlayerCharacterPart(part) or not IsSafeProjectileCandidate(part) then
                Tracked[part] = nil
            elseif (now - data.start) > State.MaxTrackTime then
                Tracked[part] = nil
            else
                trackedCount += 1
                data._dt = dt
                local t = data.targetPart
                if not t or not t.Parent then
                    local _, newT = GetClosestTarget(part.Position, State.MagnetRange)
                    data.targetPart = newT
                    t = newT
                end
                if t then
                    local _, closer, dist = GetClosestTarget(part.Position, State.MagnetRange)
                    if closer and dist + 2 < (t.Position - part.Position).Magnitude then
                        data.targetPart = closer
                        t = closer
                    end
                    pcall(SteerProjectile, part, data, t)
                end
            end
        end

        if StatusLabel then
            local launcher = HoldingLauncherTool()
            local fire = InFireWindow()
            local extra = ""
            if State.DebugTrack then
                extra = string.format("  |  Last: <font color=\"rgb(200,200,120)\">%s</font>", LastTrackedName)
            end
            StatusLabel.Set(string.format(
                "<b>Magnet:</b> <font color=\"rgb(80,200,120)\">ON</font>  |  Tracking: <font color=\"rgb(100,180,255)\">%d</font>  |  Launcher: %s%s%s",
                trackedCount,
                launcher and "<font color=\"rgb(80,200,120)\">YES</font>" or "no",
                fire and "  |  <font color=\"rgb(255,200,80)\">FIRE</font>" or "",
                extra
            ))
        end
    end))

    -- Backup scan
    local lastScan = 0
    Bind("MagnetScan", RunService.Heartbeat:Connect(function()
        if not State.MagnetEnabled then return end
        local t = tick()
        local interval = (HoldingLauncherTool() or InFireWindow()) and 0.05 or 0.12
        if t - lastScan < interval then return end
        lastScan = t
        pcall(ScanWorkspaceForThrowables)
    end))
end

local function StopMagnet()
    Unbind("Magnet")
    Unbind("MagnetAdded")
    Unbind("MagnetScan")
    Unbind("MagnetTool")
    Unbind("MagnetChar")
    Unbind("MagnetBag")
    Tracked = {}
    FireWindowUntil = 0
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

ThrowTab:CreateLabel("Snowball Launcher Magnet")
ThrowTab:CreateBadge("Launcher", Color3.fromRGB(100, 180, 255))
ThrowTab:CreateRichLabel(
    "<font color=\"rgb(180,180,200)\">v3.3 is <b>prop-safe</b>:\n• ignores chairs, food, boxes, map parts\n• only tracks fast projectiles after launcher fire\n• requires snowball launcher equipped\n\nWatch <b>Tracking</b> / <b>Last:</b> when you shoot.</font>"
)

ThrowTab:CreateSeparator()

StatusLabel = ThrowTab:CreateRichLabel("<b>Magnet:</b> <font color=\"rgb(255,80,80)\">OFF</font>  |  Tracking: 0")

ThrowTab:CreateToggle("Throwable Magnet", false, function(state)
    State.MagnetEnabled = state
    if state then
        StartMagnet()
        Library:Notify("Throwables", "Magnet ON — equip snowball launcher and shoot")
    else
        StopMagnet()
        Library:Notify("Throwables", "Magnet OFF")
    end
end, "Home launcher snowballs onto nearby players")

ThrowTab:CreateToggle("Launcher Assist", true, function(state)
    State.LauncherAssist = state
end, "While holding launcher / after fire, grab nearby new projectiles")

ThrowTab:CreateSlider("Magnet Range", 30, 250, 120, function(value)
    State.MagnetRange = value
end, "How far snowballs will lock onto someone")

ThrowTab:CreateSlider("Magnet Strength", 0.2, 0.95, 0.7, function(value)
    State.MagnetStrength = value
end, "Higher = stronger home", 2)

ThrowTab:CreateDropdown("Target Part", {"HumanoidRootPart", "Head", "UpperTorso", "Torso"}, "HumanoidRootPart", function(selected)
    State.TargetPart = selected
end, "Where snowballs home to")

ThrowTab:CreateToggle("Only My Throwables", true, function(state)
    State.OnlyMyThrowables = state
end, "Prefer projectiles that look like yours (keep ON)")

ThrowTab:CreateToggle("Show Last Tracked", true, function(state)
    State.DebugTrack = state
end, "Show projectile name in status (helps debugging)")

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

VisualsTab:CreateLabel("Visuals")
VisualsTab:CreateRichLabel(
    "<font color=\"rgb(180,180,200)\">Fullbright and Time of Day were removed.\nThis tab is ready for ESP / tracers later if you want them.</font>"
)

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
SettingsTab:CreateRichLabel("<b>GuysModz Baddies Hub v3.3</b>\nProp-safe Snowball Launcher Magnet\nPress RightShift to toggle UI.")

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

Library:Notify("GuysModz Baddies", "v3.3 — magnet won't grab chairs/food. RightShift toggles UI.")
