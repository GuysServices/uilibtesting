--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║          GuysModz Executor UI Library — Full Edition          ║
    ║                  Created for GuysModz                         ║
    ║                                                               ║
    ║  Elements:                                                    ║
    ║   • Button          • Toggle          • Slider                ║
    ║   • TextBox         • NumberBox       • SearchBox             ║
    ║   • Dropdown        • MultiDropdown   • ColorPicker           ║
    ║   • Keybind         • Label           • RichLabel             ║
    ║   • Separator       • Badge           • ImageLabel            ║
    ║   • ProgressBar     • Console         • CollapsibleSection    ║
    ║   • Tooltip system  • Watermark       • ConfirmationDialog    ║
    ║   • RainbowToggle   • StatsDisplay    • LoadingScreen         ║
    ║   • Config save/load • Notification system                     ║
    ║   • Tab icons       • Theme customization                      ║
    ║   • AuthModal (key system)                                    ║
    ║                                                               ║
    ║  Usage:                                                       ║
    ║    local Library = loadstring(game:HttpGet("URL"))()          ║
    ║    local Window = Library:CreateWindow("My Hub")              ║
    ║    local Tab = Window:CreateTab("Main", "rbxassetid://...")   ║
    ║    Tab:CreateButton("Click", function() print("Hi") end)      ║
    ║    Library:Notify("Title", "Message")                         ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--// ─── Theme ───────────────────────────────────────────────────
local Theme = {
    Background        = Color3.fromRGB(25, 25, 35),
    BackgroundAccent  = Color3.fromRGB(35, 35, 50),
    Sidebar           = Color3.fromRGB(20, 20, 30),
    Text              = Color3.fromRGB(240, 240, 250),
    TextDim           = Color3.fromRGB(150, 150, 170),
    Accent            = Color3.fromRGB(100, 120, 255),
    AccentHover       = Color3.fromRGB(120, 140, 255),
    ToggleOn          = Color3.fromRGB(80, 200, 120),
    ToggleOff         = Color3.fromRGB(60, 60, 75),
    SliderTrack       = Color3.fromRGB(50, 50, 70),
    DropdownBg        = Color3.fromRGB(30, 30, 45),
    NotificationBg    = Color3.fromRGB(30, 30, 45),
    ConsoleBg         = Color3.fromRGB(18, 18, 28),
    ConsoleText       = Color3.fromRGB(180, 220, 180),
    ProgressBarBg     = Color3.fromRGB(45, 45, 65),
    BadgeBg           = Color3.fromRGB(60, 70, 100),
    WatermarkBg       = Color3.fromRGB(20, 20, 30),
    DialogBg          = Color3.fromRGB(30, 30, 45),
    SectionBg         = Color3.fromRGB(28, 28, 42),
    Corner            = UDim.new(0, 8),
    Font              = Enum.Font.Gotham,
    FontBold          = Enum.Font.GothamBold,
    FontMono          = Enum.Font.Code,
}

--// ─── Utilities ───────────────────────────────────────────────
local function Create(className, props, children)
    local obj = Instance.new(className)
    for prop, value in pairs(props or {}) do
        obj[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = radius or Theme.Corner, Parent = parent })
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 80),
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent,
    })
end

local function AddPadding(parent, all)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all),
        PaddingRight = UDim.new(0, all),
        Parent = parent,
    })
end

local function Tween(obj, props, time, style, direction)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function GetParent()
    if RunService:IsStudio() then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    local ok = pcall(function() return CoreGui end)
    if ok then
        local existing = CoreGui:FindFirstChild("GuysModzUILibrary")
        if existing then existing:Destroy() end
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--// ─── Tooltip System ──────────────────────────────────────────
local TooltipGui
local TooltipFrame
local TooltipLabel

local function InitTooltip(parentGui)
    TooltipGui = parentGui
    TooltipFrame = Create("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, 200, 0, 0),
        BackgroundColor3 = Theme.BackgroundAccent,
        Visible = false,
        ZIndex = 9999,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    AddCorner(TooltipFrame, UDim.new(0, 6))
    AddStroke(TooltipFrame, Theme.Accent, 1, 0.3)
    TooltipLabel = Create("TextLabel", {
        Text = "",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    AddPadding(TooltipLabel, 8)
    TooltipLabel.Parent = TooltipFrame
    TooltipFrame.Parent = TooltipGui
end

local function AttachTooltip(element, text)
    if not text or text == "" then return end
    element.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        local mousePos = UserInputService:GetMouseLocation()
        TooltipFrame.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y + 15)
        TooltipFrame.Visible = true
        Tween(TooltipFrame, { BackgroundColor3 = Theme.BackgroundAccent }, 0.1)
    end)
    element.MouseLeave:Connect(function()
        TooltipFrame.Visible = false
    end)
    element.MouseMoved:Connect(function()
        if TooltipFrame.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            TooltipFrame.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y + 15)
        end
    end)
end

--// ─── Notification System ─────────────────────────────────────
local NotificationContainer

function Library:Notify(title, message, duration)
    duration = duration or 4
    if not NotificationContainer then return end

    local notif = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = Theme.NotificationBg,
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
    }, {
        Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
        Create("TextLabel", {
            Text = title, Font = Theme.FontBold, TextSize = 14,
            TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1,
        }),
        Create("TextLabel", {
            Text = message or "", Font = Theme.Font, TextSize = 13,
            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 2,
        }),
    })
    AddCorner(notif)
    AddStroke(notif, Theme.Accent, 1, 0.3)
    notif.Parent = NotificationContainer

    Tween(notif, { Position = UDim2.new(0, 10, 1, -10 - notif.AbsoluteSize.Y - 10) }, 0.3)

    task.delay(duration, function()
        Tween(notif, { Position = UDim2.new(1, 0, notif.Position.Y.Offset, 0) }, 0.3)
        task.wait(0.3)
        notif:Destroy()
    end)
end

--// ─── Watermark ───────────────────────────────────────────────
function Library:CreateWatermark(text)
    local wm = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Theme.WatermarkBg,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
    })
    AddCorner(wm, UDim.new(0, 6))
    AddStroke(wm, Theme.Accent, 1, 0.3)
    AddPadding(wm, 10)

    local label = Create("TextLabel", {
        Text = text or "GuysModz Hub",
        Font = Theme.FontBold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 1, 0),
    })
    label.Parent = wm

    local fpsLabel = Create("TextLabel", {
        Text = "0 fps",
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
    })
    fpsLabel.Parent = wm

    -- FPS counter
    local frames = 0
    local lastUpdate = tick()
    RunService.RenderStepped:Connect(function()
        frames += 1
        if tick() - lastUpdate >= 1 then
            fpsLabel.Text = frames .. " fps"
            frames = 0
            lastUpdate = tick()
        end
    end)

    wm.Position = UDim2.new(0, 10, 0, 10)
    wm.Parent = NotificationContainer.Parent

    return {
        Set = function(newText) label.Text = newText end,
        Destroy = function() wm:Destroy() end,
    }
end

--// ─── Loading Screen ──────────────────────────────────────────
function Library:CreateLoadingScreen(text, duration)
    duration = duration or 3
    text = text or "Loading..."

    local screen = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Background,
        ZIndex = 10000,
    })
    screen.Parent = NotificationContainer.Parent

    local container = Create("Frame", {
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(0.5, -150, 0.5, -40),
        BackgroundTransparency = 1,
    })
    container.Parent = screen

    local label = Create("TextLabel", {
        Text = text,
        Font = Theme.FontBold,
        TextSize = 18,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
    })
    label.Parent = container

    local barBg = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundColor3 = Theme.SliderTrack,
        BorderSizePixel = 0,
    })
    AddCorner(barBg, UDim.new(1, 0))
    barBg.Parent = container

    local barFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    })
    AddCorner(barFill, UDim.new(1, 0))
    barFill.Parent = barBg

    Tween(barFill, { Size = UDim2.new(1, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(screen, { BackgroundTransparency = 1 }, 0.3)
        Tween(label, { TextTransparency = 1 }, 0.3)
        Tween(barBg, { BackgroundTransparency = 1 }, 0.3)
        Tween(barFill, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.3)
        screen:Destroy()
    end)

    return screen
end

--// ─── Confirmation Dialog ─────────────────────────────────────
function Library:CreateConfirmationDialog(title, message, onConfirm, onCancel)
    local overlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 8000,
    })
    overlay.Parent = NotificationContainer.Parent

    local dialog = Create("Frame", {
        Size = UDim2.new(0, 360, 0, 0),
        Position = UDim2.new(0.5, -180, 0.5, -80),
        BackgroundColor3 = Theme.DialogBg,
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
    })
    AddCorner(dialog, UDim.new(0, 10))
    AddStroke(dialog, Theme.Accent, 1, 0.3)
    AddPadding(dialog, 16)
    dialog.Parent = overlay

    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
    })
    layout.Parent = dialog

    local titleLabel = Create("TextLabel", {
        Text = title or "Confirm",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = 1,
    })
    titleLabel.Parent = dialog

    local msgLabel = Create("TextLabel", {
        Text = message or "Are you sure?",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        LayoutOrder = 2,
    })
    msgLabel.Parent = dialog

    local btnRow = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })
    local rowLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
    })
    rowLayout.Parent = btnRow
    btnRow.Parent = dialog

    local function closeDialog()
        Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
        Tween(dialog, { Size = UDim2.new(0, 360, 0, 0) }, 0.15)
        task.wait(0.15)
        overlay:Destroy()
    end

    local cancelBtn = Create("TextButton", {
        Text = "Cancel",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.TextDim,
        BackgroundColor3 = Theme.BackgroundAccent,
        Size = UDim2.new(0, 90, 0, 34),
        AutoButtonColor = false,
    })
    AddCorner(cancelBtn)
    cancelBtn.Parent = btnRow
    cancelBtn.MouseEnter:Connect(function() Tween(cancelBtn, { BackgroundColor3 = Theme.SliderTrack }, 0.15) end)
    cancelBtn.MouseLeave:Connect(function() Tween(cancelBtn, { BackgroundColor3 = Theme.BackgroundAccent }, 0.15) end)
    cancelBtn.MouseButton1Click:Connect(function()
        closeDialog()
        if onCancel then onCancel() end
    end)

    local confirmBtn = Create("TextButton", {
        Text = "Confirm",
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 90, 0, 34),
        AutoButtonColor = false,
    })
    AddCorner(confirmBtn)
    confirmBtn.Parent = btnRow
    confirmBtn.MouseEnter:Connect(function() Tween(confirmBtn, { BackgroundColor3 = Theme.AccentHover }, 0.15) end)
    confirmBtn.MouseLeave:Connect(function() Tween(confirmBtn, { BackgroundColor3 = Theme.Accent }, 0.15) end)
    confirmBtn.MouseButton1Click:Connect(function()
        closeDialog()
        if onConfirm then onConfirm() end
    end)

    return overlay
end

--// ─── Stats Display ───────────────────────────────────────────
function Library:CreateStatsDisplay()
    local container = Create("Frame", {
        Size = UDim2.new(0, 180, 0, 70),
        Position = UDim2.new(0, 10, 1, -80),
        BackgroundColor3 = Theme.WatermarkBg,
        BorderSizePixel = 0,
    })
    AddCorner(container, UDim.new(0, 8))
    AddStroke(container, Theme.Accent, 1, 0.3)
    AddPadding(container, 8)
    container.Parent = NotificationContainer.Parent

    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    layout.Parent = container

    local fpsLabel = Create("TextLabel", {
        Text = "FPS: 0",
        Font = Theme.FontMono,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = 1,
    })
    fpsLabel.Parent = container

    local pingLabel = Create("TextLabel", {
        Text = "Ping: 0ms",
        Font = Theme.FontMono,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = 2,
    })
    pingLabel.Parent = container

    local memLabel = Create("TextLabel", {
        Text = "Memory: 0 MB",
        Font = Theme.FontMono,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = 3,
    })
    memLabel.Parent = container

    local frames = 0
    local lastUpdate = tick()
    RunService.RenderStepped:Connect(function()
        frames += 1
        if tick() - lastUpdate >= 1 then
            fpsLabel.Text = "FPS: " .. frames
            local ping = tonumber(Stats:FindFirstChild("Performance") and Stats.Performance:FindFirstChild("DataReceive") and "0" or "0")
            pcall(function()
                pingLabel.Text = "Ping: " .. math.floor(Stats.Network.ServerStatsItem["Data Ping"].Value) .. "ms"
            end)
            pcall(function()
                memLabel.Text = "Memory: " .. string.format("%.1f", collectgarbage("count") / 1024) .. " MB"
            end)
            frames = 0
            lastUpdate = tick()
        end
    end)

    return {
        Destroy = function() container:Destroy() end,
    }
end

--// ─── Config System ───────────────────────────────────────────
local ConfigSystem = {}
ConfigSystem.FileName = "GuysModzConfig"
ConfigSystem.Data = {}
ConfigSystem.Callbacks = {}

function ConfigSystem:Set(key, value)
    self.Data[key] = value
end

function ConfigSystem:Get(key, default)
    return self.Data[key] or default
end

function ConfigSystem:Register(key, getValue, setValue)
    self.Callbacks[key] = { Get = getValue, Set = setValue }
end

function ConfigSystem:Save()
    if not writefile then return false end
    local data = {}
    for key, callbacks in pairs(self.Callbacks) do
        data[key] = callbacks.Get()
    end
    for key, value in pairs(self.Data) do
        data[key] = value
    end
    pcall(function()
        writefile(self.FileName .. ".json", HttpService:JSONEncode(data))
    end)
    return true
end

function ConfigSystem:Load()
    if not readfile then return false end
    local ok, content = pcall(function() return readfile(self.FileName .. ".json") end)
    if not ok or not content then return false end
    local data = HttpService:JSONDecode(content)
    for key, value in pairs(data) do
        if self.Callbacks[key] then
            self.Callbacks[key].Set(value)
        else
            self.Data[key] = value
        end
    end
    return true
end

function ConfigSystem:Clear()
    if not delfile then return false end
    pcall(function() delfile(self.FileName .. ".json") end)
    self.Data = {}
    return true
end

Library.Config = ConfigSystem

--// ─── Window ──────────────────────────────────────────────────
function Library:CreateWindow(title)
    local ScreenGui = Create("ScreenGui", {
        Name = "GuysModzUILibrary",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    ScreenGui.Parent = GetParent()

    InitTooltip(ScreenGui)

    -- Main Window
    local MainWindow = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 580, 0, 420),
        Position = UDim2.new(0.5, -290, 0.5, -210),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
    })
    AddCorner(MainWindow, UDim.new(0, 10))
    AddStroke(MainWindow, Color3.fromRGB(50, 50, 70), 1, 0.3)
    MainWindow.Parent = ScreenGui

    -- Title Bar
    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
    })
    AddCorner(TitleBar, UDim.new(0, 10))
    TitleBar.Parent = MainWindow

    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
    }).Parent = TitleBar

    local TitleLabel = Create("TextLabel", {
        Text = title or "Script Hub",
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
    })
    TitleLabel.Parent = TitleBar

    -- Close
    local CloseBtn = Create("TextButton", {
        Text = "✕", Font = Theme.FontBold, TextSize = 14,
        TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -35, 0, 5),
        AutoButtonColor = false,
    })
    CloseBtn.Parent = TitleBar
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { TextColor3 = Color3.fromRGB(255, 80, 80) }, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { TextColor3 = Theme.TextDim }, 0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow, { Size = UDim2.new(0, 580, 0, 0) }, 0.2)
        task.wait(0.2)
        ScreenGui:Destroy()
    end)

    -- Minimize
    local MinBtn = Create("TextButton", {
        Text = "—", Font = Theme.FontBold, TextSize = 14,
        TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -65, 0, 5),
        AutoButtonColor = false,
    })
    MinBtn.Parent = TitleBar
    local minimized = false
    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, { TextColor3 = Theme.Accent }, 0.15) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, { TextColor3 = Theme.TextDim }, 0.15) end)
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainWindow, { Size = UDim2.new(0, 580, 0, 40) }, 0.2)
        else
            Tween(MainWindow, { Size = UDim2.new(0, 580, 0, 420) }, 0.2)
        end
    end)

    -- Sidebar
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
    })
    AddCorner(Sidebar, UDim.new(0, 10))
    Sidebar.Parent = MainWindow

    Create("Frame", {
        Size = UDim2.new(0, 10, 1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0,
    }).Parent = Sidebar

    local TabList = Create("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    local TabListLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })
    TabListLayout.Parent = TabList
    TabList.Parent = Sidebar

    -- Content Area
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
    })
    ContentArea.Parent = MainWindow

    -- Notification container
    NotificationContainer = Create("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 280, 1, 0),
        Position = UDim2.new(1, -290, 0, 10),
        BackgroundTransparency = 1,
    })
    local NotifLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })
    NotifLayout.Parent = NotificationContainer
    NotificationContainer.Parent = ScreenGui

    --// Dragging
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(MainWindow, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) }, 0.05)
        end
    end)

    --// Window Object
    local Window = {}
    Window.Tabs = {}
    Window.SelectedTab = nil
    Window.ScreenGui = ScreenGui

    function Window:CreateTab(name, icon)
        local TabButton = Create("TextButton", {
            Text = "",
            BackgroundColor3 = Theme.Sidebar,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            AutoButtonColor = false,
        })
        local btnLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
        })
        btnLayout.Parent = TabButton
        local btnPadding = Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
        })
        btnPadding.Parent = TabButton
        TabButton.Parent = TabList

        -- Icon (optional)
        if icon then
            local IconImg = Create("ImageLabel", {
                Image = icon,
                Size = UDim2.new(0, 18, 0, 18),
                BackgroundTransparency = 1,
            })
            IconImg.Parent = TabButton
        end

        local TabLabel = Create("TextLabel", {
            Text = name or "Tab",
            Font = Theme.Font,
            TextSize = 14,
            TextColor3 = Theme.TextDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -30, 1, 0),
        })
        TabLabel.Parent = TabButton

        -- Indicator
        local Indicator = Create("Frame", {
            Size = UDim2.new(0, 3, 0, 20),
            Position = UDim2.new(0, 0, 0.5, -10),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        })
        AddCorner(Indicator, UDim.new(0, 2))
        Indicator.Parent = TabButton

        -- Tab page
        local Page = Create("ScrollingFrame", {
            Name = (name or "Page"):gsub("%s", ""),
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        })
        local PageLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })
        PageLayout.Parent = Page
        Page.Parent = ContentArea

        local Tab = {}
        Tab.Page = Page
        Tab.Button = TabButton
        Tab.Elements = {}

        local function SelectTab()
            for _, tab in ipairs(Window.Tabs) do
                tab.Page.Visible = false
                Tween(tab.Button:FindFirstChild("TextLabel"), { TextColor3 = Theme.TextDim }, 0.15)
                Tween(tab.Button:FindFirstChild("Indicator"), { BackgroundTransparency = 1 }, 0.15)
            end
            Page.Visible = true
            Tween(TabLabel, { TextColor3 = Theme.Text }, 0.15)
            Tween(Indicator, { BackgroundTransparency = 0 }, 0.15)
            Window.SelectedTab = Tab
        end

        TabButton.MouseButton1Click:Connect(SelectTab)
        TabButton.MouseEnter:Connect(function()
            if Window.SelectedTab ~= Tab then Tween(TabLabel, { TextColor3 = Theme.Text }, 0.15) end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.SelectedTab ~= Tab then Tween(TabLabel, { TextColor3 = Theme.TextDim }, 0.15) end
        end)

        if #Window.Tabs == 0 then SelectTab() end

        --═══════════════════════════════════════════════════════════
        --  TAB ELEMENTS
        --═══════════════════════════════════════════════════════════

        --// Button
        function Tab:CreateButton(text, callback, tooltip)
            local Btn = Create("TextButton", {
                Text = text or "Button",
                Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text,
                BackgroundColor3 = Theme.BackgroundAccent,
                Size = UDim2.new(1, 0, 0, 36), AutoButtonColor = false,
            })
            AddCorner(Btn)
            AddStroke(Btn, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Btn.Parent = Page

            Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.AccentHover }, 0.15) end)
            Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.BackgroundAccent }, 0.15) end)
            Btn.MouseButton1Click:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.1)
                task.wait(0.1)
                Tween(Btn, { BackgroundColor3 = Theme.BackgroundAccent }, 0.15)
                if callback then callback() end
            end)
            if tooltip then AttachTooltip(Btn, tooltip) end

            return {
                Set = function(newText) Btn.Text = newText end,
                Destroy = function() Btn:Destroy() end,
            }
        end

        --// Toggle
        function Tab:CreateToggle(text, defaultState, callback, tooltip)
            local state = defaultState or false

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = text or "Toggle", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
            })
            Label.Parent = Container

            local ToggleFrame = Create("TextButton", {
                Size = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(1, -54, 0.5, -11),
                BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                Text = "", AutoButtonColor = false,
            })
            AddCorner(ToggleFrame, UDim.new(1, 0))
            ToggleFrame.Parent = Container

            local Knob = Create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
            })
            AddCorner(Knob, UDim.new(1, 0))
            Knob.Parent = ToggleFrame

            local function UpdateToggle(animated)
                if animated == nil then animated = true end
                if state then
                    if animated then
                        Tween(ToggleFrame, { BackgroundColor3 = Theme.ToggleOn }, 0.15)
                        Tween(Knob, { Position = UDim2.new(1, -19, 0.5, -8) }, 0.15)
                    else
                        ToggleFrame.BackgroundColor3 = Theme.ToggleOn
                        Knob.Position = UDim2.new(1, -19, 0.5, -8)
                    end
                else
                    if animated then
                        Tween(ToggleFrame, { BackgroundColor3 = Theme.ToggleOff }, 0.15)
                        Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -8) }, 0.15)
                    else
                        ToggleFrame.BackgroundColor3 = Theme.ToggleOff
                        Knob.Position = UDim2.new(0, 3, 0.5, -8)
                    end
                end
            end

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle(true)
                if callback then callback(state) end
            end)
            UpdateToggle(false)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newState) state = newState; UpdateToggle(true); if callback then callback(state) end end,
                Get = function() return state end,
            }
        end

        --// Slider
        function Tab:CreateSlider(text, min, max, default, callback, tooltip, decimals)
            local value = default or min
            local isFloat = decimals and decimals > 0

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = text or "Slider", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -60, 0, 20),
            })
            Label.Parent = Container

            local ValueLabel = Create("TextLabel", {
                Text = tostring(value), Font = Theme.FontBold, TextSize = 14,
                TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1, Position = UDim2.new(1, -50, 0, 6),
                Size = UDim2.new(0, 38, 0, 20),
            })
            ValueLabel.Parent = Container

            local Track = Create("Frame", {
                Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = Theme.SliderTrack, BorderSizePixel = 0,
            })
            AddCorner(Track, UDim.new(1, 0))
            Track.Parent = Container

            local Fill = Create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
            })
            AddCorner(Fill, UDim.new(1, 0))
            Fill.Parent = Track

            local SliderBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0.5, -10),
                BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            })
            SliderBtn.Parent = Track

            local dragging = false
            local function UpdateValue(inputPos)
                local rel = math.clamp((inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                if isFloat then
                    value = min + (max - min) * rel
                    value = tonumber(string.format("%." .. decimals .. "f", value))
                else
                    value = math.floor(min + (max - min) * rel)
                end
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                ValueLabel.Text = tostring(value)
                if callback then callback(value) end
            end

            SliderBtn.MouseButton1Down:Connect(function()
                dragging = true
                UpdateValue(UserInputService:GetMouseLocation())
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateValue(input.Position)
                end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newValue)
                    value = math.clamp(newValue, min, max)
                    Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    if callback then callback(value) end
                end,
                Get = function() return value end,
            }
        end

        --// TextBox
        function Tab:CreateTextBox(text, callback, tooltip)
            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Placeholder = Create("TextLabel", {
                Text = text or "Enter text...", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -24, 1, 0),
            })
            Placeholder.Parent = Container

            local Box = Create("TextBox", {
                Text = "", Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0),
                ClearTextOnFocus = false,
            })
            Box.Parent = Container

            Box.Focused:Connect(function() Placeholder.Visible = false end)
            Box.FocusLost:Connect(function(enter)
                if Box.Text == "" then Placeholder.Visible = true end
                if callback then callback(Box.Text) end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newText) Box.Text = newText; Placeholder.Visible = (newText == "") end,
                Get = function() return Box.Text end,
                Clear = function() Box.Text = ""; Placeholder.Visible = true end,
            }
        end

        --// NumberBox
        function Tab:CreateNumberBox(text, default, callback, tooltip)
            local value = default or 0

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = text or "Number", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -80, 1, 0),
            })
            Label.Parent = Container

            local Box = Create("TextBox", {
                Text = tostring(value), Font = Theme.FontBold, TextSize = 14,
                TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1, Position = UDim2.new(1, -68, 0, 0),
                Size = UDim2.new(0, 56, 1, 0),
            })
            Box.Parent = Container

            Box.FocusLost:Connect(function()
                local num = tonumber(Box.Text)
                if num then
                    value = num
                    Box.Text = tostring(value)
                    if callback then callback(value) end
                else
                    Box.Text = tostring(value)
                end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newValue) value = newValue; Box.Text = tostring(value); if callback then callback(value) end end,
                Get = function() return value end,
            }
        end

        --// SearchBox
        function Tab:CreateSearchBox(text, callback, tooltip)
            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Icon = Create("TextLabel", {
                Text = "🔍", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 20, 1, 0),
            })
            Icon.Parent = Container

            local Placeholder = Create("TextLabel", {
                Text = text or "Search...", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0),
                Size = UDim2.new(1, -46, 1, 0),
            })
            Placeholder.Parent = Container

            local Box = Create("TextBox", {
                Text = "", Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -46, 1, 0),
                ClearTextOnFocus = false,
            })
            Box.Parent = Container

            Box.Focused:Connect(function() Placeholder.Visible = false end)
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Placeholder.Visible = (Box.Text == "")
                if callback then callback(Box.Text) end
            end)
            Box.FocusLost:Connect(function()
                if Box.Text == "" then Placeholder.Visible = true end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Get = function() return Box.Text end,
                Clear = function() Box.Text = ""; Placeholder.Visible = true end,
            }
        end

        --// Dropdown
        function Tab:CreateDropdown(text, options, default, callback, tooltip)
            local selected = default or (options and options[1] or "")
            local expanded = false

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
                ZIndex = 10,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = (text or "Dropdown") .. ": " .. selected,
                Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -40, 1, 0),
            })
            Label.Parent = Container

            local Arrow = Create("TextLabel", {
                Text = "▼", Font = Theme.Font, TextSize = 10,
                TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
                Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0, 20, 1, 0),
            })
            Arrow.Parent = Container

            local ToggleBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false,
            })
            ToggleBtn.Parent = Container

            local DropdownList = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.DropdownBg, BorderSizePixel = 0,
                Visible = false, ClipsDescendants = true, ZIndex = 11,
            })
            AddCorner(DropdownList)
            AddStroke(DropdownList, Color3.fromRGB(55, 55, 75), 1, 0.3)
            DropdownList.Parent = Container

            local ListLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2),
            })
            ListLayout.Parent = DropdownList

            local function BuildOptions()
                for _, child in ipairs(DropdownList:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, option in ipairs(options) do
                    local OptionBtn = Create("TextButton", {
                        Text = option, Font = Theme.Font, TextSize = 13,
                        TextColor3 = option == selected and Theme.Accent or Theme.TextDim,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundColor3 = Theme.DropdownBg, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 28), AutoButtonColor = false,
                    })
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = OptionBtn })
                    OptionBtn.Parent = DropdownList

                    OptionBtn.MouseEnter:Connect(function()
                        Tween(OptionBtn, { BackgroundTransparency = 0.8, TextColor3 = Theme.Text }, 0.1)
                    end)
                    OptionBtn.MouseLeave:Connect(function()
                        Tween(OptionBtn, { BackgroundTransparency = 1, TextColor3 = option == selected and Theme.Accent or Theme.TextDim }, 0.1)
                    end)
                    OptionBtn.MouseButton1Click:Connect(function()
                        selected = option
                        Label.Text = (text or "Dropdown") .. ": " .. selected
                        BuildOptions()
                        if callback then callback(selected) end
                        expanded = false
                        Tween(DropdownList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                        Tween(Arrow, { Rotation = 0 }, 0.15)
                        task.wait(0.15)
                        DropdownList.Visible = false
                    end)
                end
            end

            BuildOptions()

            ToggleBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    DropdownList.Visible = true
                    local targetHeight = #options * 30
                    DropdownList.Size = UDim2.new(1, 0, 0, 0)
                    Tween(DropdownList, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.15)
                    Tween(Arrow, { Rotation = 180 }, 0.15)
                else
                    Tween(DropdownList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    Tween(Arrow, { Rotation = 0 }, 0.15)
                    task.wait(0.15)
                    DropdownList.Visible = false
                end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newSelected)
                    selected = newSelected
                    Label.Text = (text or "Dropdown") .. ": " .. selected
                    BuildOptions()
                    if callback then callback(selected) end
                end,
                Get = function() return selected end,
                Refresh = function(newOptions)
                    options = newOptions
                    selected = options[1] or ""
                    Label.Text = (text or "Dropdown") .. ": " .. selected
                    BuildOptions()
                end,
            }
        end

        --// MultiDropdown
        function Tab:CreateMultiDropdown(text, options, defaults, callback, tooltip)
            local selected = {}
            for _, d in ipairs(defaults or {}) do table.insert(selected, d) end
            local expanded = false

            local function isSelected(opt)
                for _, s in ipairs(selected) do if s == opt then return true end end
                return false
            end

            local function toggleSelected(opt)
                for i, s in ipairs(selected) do
                    if s == opt then table.remove(selected, i); return end
                end
                table.insert(selected, opt)
            end

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
                ZIndex = 10,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local function getLabel()
                if #selected == 0 then return (text or "Multi") .. ": None" end
                return (text or "Multi") .. ": " .. table.concat(selected, ", ")
            end

            local Label = Create("TextLabel", {
                Text = getLabel(), Font = Theme.Font, TextSize = 13,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
            })
            Label.Parent = Container

            local Arrow = Create("TextLabel", {
                Text = "▼", Font = Theme.Font, TextSize = 10,
                TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
                Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0, 20, 1, 0),
            })
            Arrow.Parent = Container

            local ToggleBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false,
            })
            ToggleBtn.Parent = Container

            local DropdownList = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.DropdownBg, BorderSizePixel = 0,
                Visible = false, ClipsDescendants = true, ZIndex = 11,
            })
            AddCorner(DropdownList)
            AddStroke(DropdownList, Color3.fromRGB(55, 55, 75), 1, 0.3)
            DropdownList.Parent = Container

            local ListLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2),
            })
            ListLayout.Parent = DropdownList

            local function BuildOptions()
                for _, child in ipairs(DropdownList:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
                for _, option in ipairs(options) do
                    local OptFrame = Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = Theme.DropdownBg, BackgroundTransparency = 1,
                    })
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = OptFrame })

                    local Check = Create("TextLabel", {
                        Text = isSelected(option) and "☑" or "☐",
                        Font = Theme.Font, TextSize = 13,
                        TextColor3 = isSelected(option) and Theme.Accent or Theme.TextDim,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 20, 1, 0),
                    })
                    Check.Parent = OptFrame

                    local OptLabel = Create("TextLabel", {
                        Text = option, Font = Theme.Font, TextSize = 13,
                        TextColor3 = isSelected(option) and Theme.Text or Theme.TextDim,
                        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
                        Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -24, 1, 0),
                    })
                    OptLabel.Parent = OptFrame

                    local OptBtn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                        Text = "", AutoButtonColor = false,
                    })
                    OptBtn.Parent = OptFrame

                    OptBtn.MouseEnter:Connect(function()
                        Tween(OptFrame, { BackgroundTransparency = 0.8 }, 0.1)
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        Tween(OptFrame, { BackgroundTransparency = 1 }, 0.1)
                    end)
                    OptBtn.MouseButton1Click:Connect(function()
                        toggleSelected(option)
                        Check.Text = isSelected(option) and "☑" or "☐"
                        Check.TextColor3 = isSelected(option) and Theme.Accent or Theme.TextDim
                        OptLabel.TextColor3 = isSelected(option) and Theme.Text or Theme.TextDim
                        Label.Text = getLabel()
                        if callback then callback(selected) end
                    end)
                    OptFrame.Parent = DropdownList
                end
            end

            BuildOptions()

            ToggleBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    DropdownList.Visible = true
                    local targetHeight = #options * 30
                    DropdownList.Size = UDim2.new(1, 0, 0, 0)
                    Tween(DropdownList, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.15)
                    Tween(Arrow, { Rotation = 180 }, 0.15)
                else
                    Tween(DropdownList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    Tween(Arrow, { Rotation = 0 }, 0.15)
                    task.wait(0.15)
                    DropdownList.Visible = false
                end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Get = function() return selected end,
                Set = function(newSelected)
                    selected = newSelected or {}
                    Label.Text = getLabel()
                    BuildOptions()
                    if callback then callback(selected) end
                end,
                Refresh = function(newOptions)
                    options = newOptions
                    selected = {}
                    Label.Text = getLabel()
                    BuildOptions()
                end,
            }
        end

        --// ColorPicker
        function Tab:CreateColorPicker(text, defaultColor, callback, tooltip)
            local color = defaultColor or Color3.fromRGB(255, 0, 0)
            local hue, sat, val = Color3.toHSV(color)
            local pickerOpen = false

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = text or "Color", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
            })
            Label.Parent = Container

            local ColorBox = Create("TextButton", {
                Size = UDim2.new(0, 36, 0, 22),
                Position = UDim2.new(1, -46, 0.5, -11),
                BackgroundColor3 = color, Text = "", AutoButtonColor = false,
            })
            AddCorner(ColorBox, UDim.new(0, 4))
            AddStroke(ColorBox, Color3.fromRGB(80, 80, 100), 1, 0.3)
            ColorBox.Parent = Container

            -- Picker panel
            local Picker = Create("Frame", {
                Size = UDim2.new(0, 220, 0, 200),
                Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.DropdownBg, BorderSizePixel = 0,
                Visible = false, ZIndex = 20,
            })
            AddCorner(Picker, UDim.new(0, 8))
            AddStroke(Picker, Color3.fromRGB(55, 55, 75), 1, 0.3)
            AddPadding(Picker, 8)
            Picker.Parent = Container

            -- SV area
            local SVArea = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 120),
                BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                Text = "", AutoButtonColor = false,
            })
            AddCorner(SVArea, UDim.new(0, 4))
            SVArea.Parent = Picker

            -- Gradient overlays
            local whiteGrad = Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            })
            Create("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
                Transparency = NumberSequence.new(0, 1),
                Rotation = 0,
                Parent = whiteGrad,
            })
            whiteGrad.Parent = SVArea

            local blackGrad = Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
            })
            Create("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0)),
                Transparency = NumberSequence.new(1, 0),
                Rotation = 90,
                Parent = blackGrad,
            })
            blackGrad.Parent = SVArea

            -- SV cursor
            local SVCursor = Create("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(sat, -4, 1 - val, -4),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            AddCorner(SVCursor, UDim.new(1, 0))
            AddStroke(SVCursor, Color3.fromRGB(0, 0, 0), 1, 0)
            SVCursor.Parent = SVArea

            -- Hue slider
            local HueBar = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 16),
                Position = UDim2.new(0, 0, 0, 130),
                Text = "", AutoButtonColor = false,
            })
            AddCorner(HueBar, UDim.new(0, 4))
            HueBar.Parent = Picker

            Create("UIGradient", {
                Color = ColorSequence.new(
                    Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0),
                    Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 255, 255),
                    Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 0, 255),
                    Color3.fromRGB(255, 0, 0)
                ),
                Parent = HueBar,
            })

            local HueCursor = Create("Frame", {
                Size = UDim2.new(0, 4, 0, 20),
                Position = UDim2.new(hue / 360, -2, 0, -2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            AddCorner(HueCursor, UDim.new(1, 0))
            AddStroke(HueCursor, Color3.fromRGB(0, 0, 0), 1, 0)
            HueCursor.Parent = HueBar

            -- Preview + hex
            local Preview = Create("Frame", {
                Size = UDim2.new(0, 30, 0, 24),
                Position = UDim2.new(0, 0, 0, 156),
                BackgroundColor3 = color, BorderSizePixel = 0,
            })
            AddCorner(Preview, UDim.new(0, 4))
            Preview.Parent = Picker

            local HexLabel = Create("TextLabel", {
                Text = "#FF0000", Font = Theme.FontMono, TextSize = 13,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 38, 0, 156),
                Size = UDim2.new(0, 100, 0, 24),
            })
            HexLabel.Parent = Picker

            local function UpdateColor()
                color = Color3.fromHSV(hue, sat, val)
                ColorBox.BackgroundColor3 = color
                Preview.BackgroundColor3 = color
                SVArea.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
                HexLabel.Text = string.format("#%02X%02X%02X", r, g, b)
                SVCursor.Position = UDim2.new(sat, -4, 1 - val, -4)
                HueCursor.Position = UDim2.new(hue / 360, -2, 0, -2)
                if callback then callback(color) end
            end

            -- SV dragging
            local svDragging = false
            SVArea.MouseButton1Down:Connect(function()
                svDragging = true
                local rel = UserInputService:GetMouseLocation() - SVArea.AbsolutePosition
                sat = math.clamp(rel.X / SVArea.AbsoluteSize.X, 0, 1)
                val = 1 - math.clamp(rel.Y / SVArea.AbsoluteSize.Y, 0, 1)
                UpdateColor()
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local rel = input.Position - SVArea.AbsolutePosition
                    sat = math.clamp(rel.X / SVArea.AbsoluteSize.X, 0, 1)
                    val = 1 - math.clamp(rel.Y / SVArea.AbsoluteSize.Y, 0, 1)
                    UpdateColor()
                end
            end)

            -- Hue dragging
            local hueDragging = false
            HueBar.MouseButton1Down:Connect(function()
                hueDragging = true
                local rel = UserInputService:GetMouseLocation() - HueBar.AbsolutePosition
                hue = math.clamp(rel.X / HueBar.AbsoluteSize.X, 0, 1) * 360
                UpdateColor()
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local rel = input.Position - HueBar.AbsolutePosition
                    hue = math.clamp(rel.X / HueBar.AbsoluteSize.X, 0, 1) * 360
                    UpdateColor()
                end
            end)

            ColorBox.MouseButton1Click:Connect(function()
                pickerOpen = not pickerOpen
                Picker.Visible = pickerOpen
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            UpdateColor()

            return {
                Set = function(newColor)
                    color = newColor
                    hue, sat, val = Color3.toHSV(color)
                    UpdateColor()
                end,
                Get = function() return color end,
                GetHex = function()
                    local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
                    return string.format("#%02X%02X%02X", r, g, b)
                end,
            }
        end

        --// Keybind
        function Tab:CreateKeybind(text, defaultKey, callback, tooltip)
            local key = defaultKey or Enum.KeyCode.Unknown
            local listening = false

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = text or "Keybind", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -100, 1, 0),
            })
            Label.Parent = Container

            local KeyLabel = Create("TextButton", {
                Text = key and key.Name or "None", Font = Theme.FontBold, TextSize = 13,
                TextColor3 = Theme.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -88, 0, 0),
                AutoButtonColor = false,
            })
            KeyLabel.Parent = Container

            KeyLabel.MouseButton1Click:Connect(function()
                listening = true
                KeyLabel.Text = "..."
                KeyLabel.TextColor3 = Theme.TextDim
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        KeyLabel.Text = key.Name
                        KeyLabel.TextColor3 = Theme.Accent
                        listening = false
                    end
                elseif not gameProcessed and input.KeyCode == key then
                    if callback then callback() end
                end
            end)
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newKey) key = newKey; KeyLabel.Text = key.Name end,
                Get = function() return key end,
            }
        end

        --// Label
        function Tab:CreateLabel(text)
            local Label = Create("TextLabel", {
                Text = text or "Label", Font = Theme.FontBold, TextSize = 13,
                TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24),
            })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 4), Parent = Label })
            Label.Parent = Page
            return {
                Set = function(newText) Label.Text = newText end,
            }
        end

        --// RichLabel (multi-line, supports RichText)
        function Tab:CreateRichLabel(text)
            local Label = Create("TextLabel", {
                Text = text or "Rich Text", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true, RichText = true, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 4), Parent = Label })
            Label.Parent = Page
            return {
                Set = function(newText) Label.Text = newText end,
            }
        end

        --// Separator
        function Tab:CreateSeparator()
            local Sep = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Color3.fromRGB(50, 50, 70), BorderSizePixel = 0,
            })
            Sep.Parent = Page
            return Sep
        end

        --// Badge
        function Tab:CreateBadge(text, color)
            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
            })
            local layout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = Container,
            })

            local Badge = Create("TextLabel", {
                Text = text or "Badge", Font = Theme.FontBold, TextSize = 12,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = color or Theme.BadgeBg,
                Size = UDim2.new(0, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = Badge })
            AddCorner(Badge, UDim.new(0, 11))
            Badge.Parent = Container
            Container.Parent = Page

            return {
                Set = function(newText) Badge.Text = newText end,
                SetColor = function(newColor) Badge.BackgroundColor3 = newColor end,
            }
        end

        --// ImageLabel
        function Tab:CreateImageLabel(imageId, size, tooltip)
            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, size or 60),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Img = Create("ImageLabel", {
                Image = imageId or "",
                Size = UDim2.new(1, -20, 1, -20),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
            })
            Img.Parent = Container

            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newImage) Img.Image = newImage end,
            }
        end

        --// ProgressBar
        function Tab:CreateProgressBar(text, initial, callback, tooltip)
            local progress = initial or 0

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = (text or "Progress") .. " - 0%", Font = Theme.Font, TextSize = 13,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 18),
            })
            Label.Parent = Container

            local BarBg = Create("Frame", {
                Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 28),
                BackgroundColor3 = Theme.ProgressBarBg, BorderSizePixel = 0,
            })
            AddCorner(BarBg, UDim.new(1, 0))
            BarBg.Parent = Container

            local BarFill = Create("Frame", {
                Size = UDim2.new(progress / 100, 0, 1, 0),
                BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
            })
            AddCorner(BarFill, UDim.new(1, 0))
            BarFill.Parent = BarBg

            local function UpdateProgress()
                progress = math.clamp(progress, 0, 100)
                BarFill.Size = UDim2.new(progress / 100, 0, 1, 0)
                Label.Text = (text or "Progress") .. " - " .. math.floor(progress) .. "%"
                if callback then callback(progress) end
            end

            UpdateProgress()
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(value) progress = value; UpdateProgress() end,
                Get = function() return progress end,
                Complete = function() progress = 100; UpdateProgress() end,
                Reset = function() progress = 0; UpdateProgress() end,
            }
        end

        --// Console / Output Log
        function Tab:CreateConsole(maxLines)
            maxLines = maxLines or 100
            local lines = {}

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 160),
                BackgroundColor3 = Theme.ConsoleBg, BorderSizePixel = 0,
            })
            AddCorner(Container, UDim.new(0, 6))
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Scroller = Create("ScrollingFrame", {
                Size = UDim2.new(1, -16, 1, -16),
                Position = UDim2.new(0, 8, 0, 8),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
            })
            local LogLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1),
                Parent = Scroller,
            })
            Scroller.Parent = Container

            local function AddLine(msg, msgType)
                local color = Theme.ConsoleText
                local prefix = "[INFO]"
                if msgType == "warn" then color = Color3.fromRGB(255, 200, 80); prefix = "[WARN]"
                elseif msgType == "error" then color = Color3.fromRGB(255, 100, 100); prefix = "[ERROR]"
                elseif msgType == "success" then color = Color3.fromRGB(100, 255, 150); prefix = "[OK]"
                end

                local ts = os.date("%H:%M:%S")
                local Line = Create("TextLabel", {
                    Text = ts .. " " .. prefix .. " " .. tostring(msg),
                    Font = Theme.FontMono, TextSize = 12, TextColor3 = color,
                    TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                })
                Line.Parent = Scroller

                table.insert(lines, Line)
                if #lines > maxLines then
                    local old = table.remove(lines, 1)
                    old:Destroy()
                end

                -- Auto-scroll to bottom
                task.defer(function()
                    Scroller.CanvasPosition = Vector2.new(0, Scroller.CanvasSize.Y.Offset)
                end)
            end

            return {
                Log = function(msg) AddLine(msg, "info") end,
                Warn = function(msg) AddLine(msg, "warn") end,
                Error = function(msg) AddLine(msg, "error") end,
                Success = function(msg) AddLine(msg, "success") end,
                Clear = function()
                    for _, line in ipairs(lines) do line:Destroy() end
                    lines = {}
                end,
                GetLines = function() return lines end,
            }
        end

        --// CollapsibleSection
        function Tab:CreateCollapsibleSection(title, defaultOpen)
            local expanded = defaultOpen ~= false
            local sectionElements = {}

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = Theme.SectionBg, BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            AddCorner(Container, UDim.new(0, 6))
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local layout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
                Parent = Container,
            })

            local Header = Create("TextButton", {
                Text = "", Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.SectionBg, BackgroundTransparency = 1,
                AutoButtonColor = false, LayoutOrder = 0,
            })
            AddCorner(Header, UDim.new(0, 6))
            Header.Parent = Container

            local headerLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
                Parent = Header,
            })
            Create("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = Header })

            local Arrow = Create("TextLabel", {
                Text = expanded and "▼" or "▶", Font = Theme.Font, TextSize = 12,
                TextColor3 = Theme.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(0, 16, 0, 20),
            })
            Arrow.Parent = Header

            local Title = Create("TextLabel", {
                Text = title or "Section", Font = Theme.FontBold, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Size = UDim2.new(1, -30, 0, 20),
            })
            Title.Parent = Header

            -- Content frame
            local Content = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = expanded,
                LayoutOrder = 1,
            })
            Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = Content })
            local ContentLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6),
                Parent = Content,
            })
            Content.Parent = Container

            Header.MouseButton1Click:Connect(function()
                expanded = not expanded
                Content.Visible = expanded
                Arrow.Text = expanded and "▼" or "▶"
            end)

            -- Section API — same element creation methods as Tab
            local Section = {}

            function Section:CreateButton(text, callback, tooltip)
                local btn = Tab:CreateButton(text, callback, tooltip)
                btn.Parent = Content
                return btn
            end
            function Section:CreateToggle(text, defaultState, callback, tooltip)
                local el = Tab:CreateToggle(text, defaultState, callback, tooltip)
                -- Reparent
                return el
            end

            -- Generic reparenting wrapper
            local function WrapCreate(methodName)
                return function(_, ...)
                    local result = Tab[methodName](Tab, ...)
                    -- Find the last child added to Page and move it to Content
                    local lastChild = nil
                    for _, child in ipairs(Page:GetChildren()) do
                        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                            if child.Parent == Page then lastChild = child end
                        end
                    end
                    if lastChild then lastChild.Parent = Content end
                    return result
                end
            end

            -- Override all element methods to reparent to Content
            for methodName, method in pairs(Tab) do
                if type(method) == "function" and methodName:match("^Create") and methodName ~= "CreateCollapsibleSection" then
                    Section[methodName] = WrapCreate(methodName)
                end
            end

            return Section
        end

        --// RainbowToggle (animated rainbow accent)
        function Tab:CreateRainbowToggle(text, defaultState, callback, tooltip)
            local state = defaultState or false
            local rainbowConnection = nil

            local Container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.BackgroundAccent, BorderSizePixel = 0,
            })
            AddCorner(Container)
            AddStroke(Container, Color3.fromRGB(55, 55, 75), 1, 0.3)
            Container.Parent = Page

            local Label = Create("TextLabel", {
                Text = text or "Rainbow", Font = Theme.Font, TextSize = 14,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
            })
            Label.Parent = Container

            local ToggleFrame = Create("TextButton", {
                Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -54, 0.5, -11),
                BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                Text = "", AutoButtonColor = false,
            })
            AddCorner(ToggleFrame, UDim.new(1, 0))
            ToggleFrame.Parent = Container

            local Knob = Create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
            })
            AddCorner(Knob, UDim.new(1, 0))
            Knob.Parent = ToggleFrame

            local function UpdateToggle()
                if state then
                    Tween(ToggleFrame, { BackgroundColor3 = Theme.ToggleOn }, 0.15)
                    Tween(Knob, { Position = UDim2.new(1, -19, 0.5, -8) }, 0.15)
                    if not rainbowConnection then
                        local hue = 0
                        rainbowConnection = RunService.RenderStepped:Connect(function(dt)
                            hue = (hue + dt * 0.3) % 1
                            Theme.Accent = Color3.fromHSV(hue, 0.8, 1)
                            AddStroke(Container, Theme.Accent, 1, 0.3)
                        end)
                    end
                else
                    Tween(ToggleFrame, { BackgroundColor3 = Theme.ToggleOff }, 0.15)
                    Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -8) }, 0.15)
                    if rainbowConnection then
                        rainbowConnection:Disconnect()
                        rainbowConnection = nil
                        Theme.Accent = Color3.fromRGB(100, 120, 255)
                    end
                end
                if callback then callback(state) end
            end

            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
            end)
            UpdateToggle()
            if tooltip then AttachTooltip(Container, tooltip) end

            return {
                Set = function(newState) state = newState; UpdateToggle() end,
                Get = function() return state end,
            }
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    --// Window methods
    function Window:SetTitle(newTitle) TitleLabel.Text = newTitle end
    function Window:Destroy() ScreenGui:Destroy() end

    function Window:BindToggleKey(keyCode)
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == keyCode then
                MainWindow.Visible = not MainWindow.Visible
            end
        end)
    end

    return Window
end

--// ─── Auth Modal (Key System) ────────────────────────────────
--[[
    Library:CreateAuthModal({
        Title = "GuysModz Hub",
        Subtitle = "Enter your key to continue",
        Placeholder = "Enter key...",
        ValidateKey = function(key)
            -- Return true if key is valid, false otherwise
            local validKeys = { "GuysModz-1234", "VIP-5678", "Free-Key" }
            for _, valid in ipairs(validKeys) do
                if key == valid then return true end
            end
            return false
        end,
        OnSuccess = function()
            print("Auth success!")
        end,
        OnFail = function()
            print("Auth failed!")
        end,
        MaxAttempts = 3,
        SaveKey = true,        -- saves valid key to file
        KeyFileName = "GuysModzKey",
        GetKeyLink = "https://your-link.com",  -- optional link button
    })
]]
function Library:CreateAuthModal(config)
    config = config or {}

    local parent = GetParent()

    local ScreenGui = Create("ScreenGui", {
        Name = "GuysModzAuthModal",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    ScreenGui.Parent = parent

    -- Full screen overlay
    local Overlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.1,
        ZIndex = 10000,
    })
    Overlay.Parent = ScreenGui

    -- Animated background gradient
    local BgGradient = Create("UIGradient", {
        Color = ColorSequence.new(Theme.Background, Theme.Sidebar),
        Rotation = 45,
        Parent = Overlay,
    })

    -- Centered modal
    local Modal = Create("Frame", {
        Size = UDim2.new(0, 380, 0, 0),
        Position = UDim2.new(0.5, -190, 0.5, -150),
        BackgroundColor3 = Theme.BackgroundAccent,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 10001,
    })
    AddCorner(Modal, UDim.new(0, 12))
    AddStroke(Modal, Theme.Accent, 1.5, 0.2)
    AddPadding(Modal, 20)
    Modal.Parent = Overlay

    local ModalLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = Modal,
    })

    -- Logo / Icon area
    local LogoFrame = Create("Frame", {
        Size = UDim2.new(0, 60, 0, 60),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        LayoutOrder = 0,
    })
    AddCorner(LogoFrame, UDim.new(0, 30))
    LogoFrame.Parent = Modal

    local LogoLabel = Create("TextLabel", {
        Text = "🔒",
        Font = Theme.FontBold,
        TextSize = 28,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = LogoFrame,
    })

    -- Title
    local Title = Create("TextLabel", {
        Text = config.Title or "Authentication Required",
        Font = Theme.FontBold,
        TextSize = 20,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        LayoutOrder = 1,
    })
    Title.Parent = Modal

    -- Subtitle
    local Subtitle = Create("TextLabel", {
        Text = config.Subtitle or "Enter your key to access the script.",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextDim,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = 2,
    })
    Subtitle.Parent = Modal

    -- Key input box
    local InputContainer = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    })
    AddCorner(InputContainer, UDim.new(0, 8))
    AddStroke(InputContainer, Color3.fromRGB(55, 55, 75), 1, 0.3)
    InputContainer.Parent = Modal

    local Placeholder = Create("TextLabel", {
        Text = config.Placeholder or "Enter key...",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    })
    Placeholder.Parent = InputContainer

    local KeyInput = Create("TextBox", {
        Text = "",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        ClearTextOnFocus = false,
    })
    KeyInput.Parent = InputContainer

    KeyInput.Focused:Connect(function()
        Placeholder.Visible = false
    end)
    KeyInput.FocusLost:Connect(function()
        if KeyInput.Text == "" then Placeholder.Visible = true end
    end)

    -- Status label
    local StatusLabel = Create("TextLabel", {
        Text = "",
        Font = Theme.Font,
        TextSize = 13,
        TextColor3 = Theme.TextDim,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 4,
    })
    StatusLabel.Parent = Modal

    -- Submit button
    local SubmitBtn = Create("TextButton", {
        Text = "Submit Key",
        Font = Theme.FontBold,
        TextSize = 15,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 40),
        AutoButtonColor = false,
        LayoutOrder = 5,
    })
    AddCorner(SubmitBtn, UDim.new(0, 8))
    SubmitBtn.Parent = Modal

    SubmitBtn.MouseEnter:Connect(function()
        Tween(SubmitBtn, { BackgroundColor3 = Theme.AccentHover }, 0.15)
    end)
    SubmitBtn.MouseLeave:Connect(function()
        Tween(SubmitBtn, { BackgroundColor3 = Theme.Accent }, 0.15)
    end)

    -- Get Key link button (optional)
    local GetKeyBtn
    if config.GetKeyLink then
        GetKeyBtn = Create("TextButton", {
            Text = "Get Key 🔑",
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Accent,
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(1, 0, 0, 34),
            AutoButtonColor = false,
            LayoutOrder = 6,
        })
        AddCorner(GetKeyBtn, UDim.new(0, 8))
        AddStroke(GetKeyBtn, Theme.Accent, 1, 0.4)
        GetKeyBtn.Parent = Modal

        GetKeyBtn.MouseEnter:Connect(function()
            Tween(GetKeyBtn, { BackgroundTransparency = 0.5 }, 0.15)
        end)
        GetKeyBtn.MouseLeave:Connect(function()
            Tween(GetKeyBtn, { BackgroundTransparency = 0 }, 0.15)
        end)
        GetKeyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(config.GetKeyLink)
                StatusLabel.Text = "Link copied to clipboard!"
                StatusLabel.TextColor3 = Theme.ToggleOn
            end
            pcall(function()
                if httprequest then httprequest({ Url = config.GetKeyLink }) end
            end)
        end)
    end

    -- Attempts counter
    local maxAttempts = config.MaxAttempts or 0  -- 0 = unlimited
    local attempts = 0
    local AttemptsLabel
    if maxAttempts > 0 then
        AttemptsLabel = Create("TextLabel", {
            Text = "Attempts remaining: " .. maxAttempts,
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.TextDim,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            LayoutOrder = 7,
        })
        AttemptsLabel.Parent = Modal
    end

    --// Logic
    local authed = false
    local locked = false

    local function CloseModal()
        Tween(Overlay, { BackgroundTransparency = 1 }, 0.3)
        Tween(Modal, { Size = UDim2.new(0, 380, 0, 0) }, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end

    local function ShowError(msg)
        StatusLabel.Text = "❌ " .. msg
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        -- Shake animation
        local origPos = Modal.Position
        Tween(Modal, { Position = UDim2.new(origPos.X.Scale, origPos.X.Offset - 10, origPos.Y.Scale, origPos.Y.Offset) }, 0.05)
        task.wait(0.05)
        Tween(Modal, { Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + 10, origPos.Y.Scale, origPos.Y.Offset) }, 0.05)
        task.wait(0.05)
        Tween(Modal, { Position = UDim2.new(origPos.X.Scale, origPos.X.Offset - 6, origPos.Y.Scale, origPos.Y.Offset) }, 0.05)
        task.wait(0.05)
        Tween(Modal, { Position = origPos }, 0.05)
    end

    local function ShowSuccess(msg)
        StatusLabel.Text = "✅ " .. msg
        StatusLabel.TextColor3 = Theme.ToggleOn
    end

    local function SubmitKey()
        if locked or authed then return end
        local key = KeyInput.Text

        if key == "" or key == nil then
            ShowError("Please enter a key.")
            return
        end

        attempts += 1

        local isValid = false
        if config.ValidateKey then
            isValid = config.ValidateKey(key)
        else
            isValid = true  -- No validation = always pass
        end

        if isValid then
            authed = true
            ShowSuccess("Key accepted! Loading...")

            -- Save key if enabled
            if config.SaveKey and writefile then
                pcall(function()
                    writefile((config.KeyFileName or "GuysModzKey") .. ".txt", key)
                end)
            end

            Tween(SubmitBtn, { BackgroundColor3 = Theme.ToggleOn }, 0.2)

            task.delay(1, function()
                CloseModal()
                if config.OnSuccess then config.OnSuccess(key) end
            end)
        else
            if maxAttempts > 0 then
                local remaining = maxAttempts - attempts
                if AttemptsLabel then
                    AttemptsLabel.Text = "Attempts remaining: " .. remaining
                end
                if remaining <= 0 then
                    locked = true
                    ShowError("Max attempts reached. Locked.")
                    KeyInput.Text = ""
                    SubmitBtn.Text = "Locked"
                    SubmitBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
                    if config.OnFail then config.OnFail("locked") end
                    task.delay(3, function()
                        CloseModal()
                    end)
                    return
                end
            end
            ShowError("Invalid key. Try again.")
            KeyInput.Text = ""
            if config.OnFail then config.OnFail("invalid") end
        end
    end

    SubmitBtn.MouseButton1Click:Connect(SubmitKey)
    KeyInput.FocusLost:Connect(function(enter)
        if enter then SubmitKey() end
    end)

    -- Auto-load saved key
    if config.SaveKey and readfile then
        local ok, savedKey = pcall(function() return readfile((config.KeyFileName or "GuysModzKey") .. ".txt") end)
        if ok and savedKey and savedKey ~= "" then
            KeyInput.Text = savedKey
            Placeholder.Visible = false
            StatusLabel.Text = "Saved key found. Press Submit."
            StatusLabel.TextColor3 = Theme.Accent
        end
    end

    -- Animate in
    Modal.Size = UDim2.new(0, 380, 0, 0)
    Tween(Modal, { Size = UDim2.new(0, 380, 0, 0) }, 0) -- trigger automatic size
    Tween(Overlay, { BackgroundTransparency = 0.1 }, 0.3)

    -- Animated logo pulse
    task.spawn(function()
        while ScreenGui.Parent do
            Tween(LogoFrame, { Size = UDim2.new(0, 56, 0, 56) }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
            Tween(LogoFrame, { Size = UDim2.new(0, 64, 0, 64) }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
        end
    end)

    -- Animated gradient rotation
    task.spawn(function()
        local rot = 0
        while ScreenGui.Parent do
            rot = (rot + 1) % 360
            BgGradient.Rotation = rot
            task.wait(0.05)
        end
    end)

    return {
        IsAuthed = function() return authed end,
        IsLocked = function() return locked end,
        Close = CloseModal,
        ScreenGui = ScreenGui,
    }
end

--// ─── Theme Override ──────────────────────────────────────────
function Library:SetTheme(themeTable)
    for key, value in pairs(themeTable) do
        Theme[key] = value
    end
end

--// ─── Theme Presets ───────────────────────────────────────────
Library.Presets = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 35),
        BackgroundAccent = Color3.fromRGB(35, 35, 50),
        Sidebar = Color3.fromRGB(20, 20, 30),
        Accent = Color3.fromRGB(100, 120, 255),
    },
    Midnight = {
        Background = Color3.fromRGB(15, 15, 25),
        BackgroundAccent = Color3.fromRGB(25, 25, 40),
        Sidebar = Color3.fromRGB(10, 10, 20),
        Accent = Color3.fromRGB(80, 100, 220),
    },
    BloodRed = {
        Background = Color3.fromRGB(30, 15, 15),
        BackgroundAccent = Color3.fromRGB(45, 20, 20),
        Sidebar = Color3.fromRGB(25, 10, 10),
        Accent = Color3.fromRGB(220, 50, 50),
        AccentHover = Color3.fromRGB(240, 70, 70),
        ToggleOn = Color3.fromRGB(200, 40, 40),
    },
    Green = {
        Background = Color3.fromRGB(15, 30, 15),
        BackgroundAccent = Color3.fromRGB(20, 45, 20),
        Sidebar = Color3.fromRGB(10, 25, 10),
        Accent = Color3.fromRGB(50, 200, 80),
        AccentHover = Color3.fromRGB(70, 220, 100),
        ToggleOn = Color3.fromRGB(40, 180, 60),
    },
    Purple = {
        Background = Color3.fromRGB(25, 15, 35),
        BackgroundAccent = Color3.fromRGB(35, 20, 50),
        Sidebar = Color3.fromRGB(20, 10, 30),
        Accent = Color3.fromRGB(160, 80, 255),
        AccentHover = Color3.fromRGB(180, 100, 255),
    },
    Orange = {
        Background = Color3.fromRGB(30, 20, 10),
        BackgroundAccent = Color3.fromRGB(45, 30, 15),
        Sidebar = Color3.fromRGB(25, 15, 5),
        Accent = Color3.fromRGB(255, 140, 30),
        AccentHover = Color3.fromRGB(255, 160, 50),
        ToggleOn = Color3.fromRGB(220, 120, 20),
    },
}

return Library
