-- [amongus-style UD bridge] The real module-function swaps (what the anti-cheat
-- actually detects) are installed by preload.lua DURING the game's script-hold, i.e.
-- BEFORE AssetContainer captures its baselines. This file only writes handler closures
-- into __SCORP.hooks slots, which are plain table writes the AC does not watch.
-- If run WITHOUT the preload, the block below installs the trampolines now as a
-- non-UD fallback so the script still works standalone.
do
    local __S = getgenv().__SCORP
    if not (__S and __S.real and __S.real.CreateProjectile) then
        __S = __S or { real = {}, hooks = {} }
        getgenv().__SCORP = __S
        local RS = game:GetService("ReplicatedStorage")
        local Mods = RS:WaitForChild("Modules", 10)
        local function tramp(tbl, name)
            if not tbl or type(tbl[name]) ~= "function" or __S.real[name] then return end
            __S.real[name] = tbl[name]
            tbl[name] = function(...)
                local h = __S.hooks[name]
                if h then return h(...) end
                return __S.real[name](...)
            end
        end
        if Mods then
            pcall(function() local m = require(Mods:WaitForChild("VFXModule", 10)); tramp(m, "CreateProjectile"); tramp(m, "CreateBlood"); tramp(m, "CreateHole") end)
            pcall(function() local m = require(Mods:WaitForChild("ItemClass", 10)); tramp(m, "AttachmentStats") end)
            pcall(function() local m = require(Mods:WaitForChild("RaycastUtil", 10)); tramp(m, "Raycast") end)
        end
        pcall(function()
            if setreadonly then setreadonly(math, false) end
            __S.real.abs = math.abs
            math.abs = function(...) local h = __S.hooks.abs; if h then return h(...) end return __S.real.abs(...) end
            if setreadonly then setreadonly(math, true) end
        end)
    end
end

local _dbg = {}
do
    local d = debug
    _dbg.tb   = function(...) return d.traceback(...) end
    _dbg.info = function(...) return d.info(...) end
    _dbg.gup  = function(...) return d.getupvalues(...) end
    _dbg.gc   = function(...) return d.getconstants(...) end
    _dbg.sc   = function(...) return d.setconstant(...) end
    _dbg.gs   = function(...) return d.getstack(...) end
    _dbg.ss   = function(...) return d.setstack(...) end
end

local _env = getgenv and getgenv() or {}
local _hook = (hookfunction and function(a,b) return hookfunction(a,b) end) or nil
local _conn = (getconnections and function(a) return getconnections(a) end) or nil
local _senv = (getsenv and function(a) return getsenv(a) end) or nil
local _shp  = (sethiddenproperty and function(a,b,c) return sethiddenproperty(a,b,c) end) or nil
local _sff  = (setfflag and function(a,b) return setfflag(a,b) end) or nil
local _sr   = (setreadonly and function(a,b) return setreadonly(a,b) end) or nil
local _ilv  = (isvalidlevel and function(a) return isvalidlevel(a) end) or nil
local _gs2  = (getstack and function(a) return getstack(a) end) or nil
local _ss2  = (setstack and function(a,b,c) return setstack(a,b,c) end) or nil

local CoreGuiRef    = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local gethuiFn      = gethui or function() return CoreGuiRef end
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService  = game:GetService("SoundService")
local Debris        = game:GetService("Debris")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local Camera        = Workspace.CurrentCamera
local Client        = Players.LocalPlayer
local RAY_FILTER_EXCLUDE = Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Blacklist

local SETTINGS

local function CreateUndetectedGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = "\0"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = gethuiFn()
    return gui
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/i77lhm/Libraries/refs/heads/main/Utopia/Library.lua"))()

local _keyValidated = false
local _keyCode = "SCORPION-WTF-JJZ9V-BMSCZ-8H6JY-127U8"
local _discordUrl = "https://discord.gg/reQwaRfXyX"
do
    local keyGui = CreateUndetectedGui("KeySystem")
    keyGui.DisplayOrder = 2147483647

    local keyFont = nil
    pcall(function() if Library and Library.Font then keyFont = Library.Font end end)
    if not keyFont then
        pcall(function() keyFont = Font.new("rbxasset://fonts/families/Tahoma.json", Enum.FontWeight.Regular) end)
    end
    if not keyFont then keyFont = Enum.Font.Code end
    local function F(lbl)
        local ok = pcall(function() lbl.FontFace = keyFont end)
        if not ok or not lbl.FontFace then
            pcall(function() lbl.Font = keyFont end)
        end
        if not lbl.FontFace then lbl.Font = Enum.Font.Code end
    end

    local white = Color3.fromRGB(255, 255, 255)
    local lightGray = Color3.fromRGB(200, 200, 200)
    local green = Color3.fromRGB(50, 220, 110)
    local greenBright = Color3.fromRGB(80, 255, 140)
    local greenDark = Color3.fromRGB(30, 120, 60)
    local red = Color3.fromRGB(255, 80, 80)
    local bg = Color3.fromRGB(0, 0, 0)
    local box = Color3.fromRGB(12, 12, 12)

    local blocker = Instance.new("Frame")
    blocker.Size = UDim2.fromScale(1, 1)
    blocker.BackgroundColor3 = bg
    blocker.BackgroundTransparency = 0.4
    blocker.BorderSizePixel = 0
    blocker.Active = true
    blocker.Parent = keyGui

    local win = Instance.new("Frame")
    win.Size = UDim2.fromOffset(360, 400)
    win.Position = UDim2.new(0.5, -180, 0.5, -200)
    win.BackgroundColor3 = bg
    win.BorderSizePixel = 0
    win.Active = true
    win.Parent = keyGui
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 4)
    local winStroke = Instance.new("UIStroke", win)
    winStroke.Color = greenDark
    winStroke.Thickness = 1

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = win

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.Position = UDim2.fromOffset(0, 12)
    title.BackgroundTransparency = 1
    title.Text = "scorpion.wtf"
    F(title)
    title.TextSize = 22
    title.TextColor3 = white
    title.Parent = titleBar

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(0, 60)
    subtitle.Size = UDim2.new(1, 0, 0, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "enter your key"
    F(subtitle)
    subtitle.TextSize = 13
    subtitle.TextColor3 = white
    subtitle.Parent = win

    local tb = Instance.new("TextBox")
    tb.Position = UDim2.fromOffset(20, 92)
    tb.Size = UDim2.new(1, -40, 0, 42)
    tb.BackgroundColor3 = box
    tb.BorderSizePixel = 0
    tb.PlaceholderText = "paste key..."
    tb.PlaceholderColor3 = lightGray
    tb.Text = ""
    tb.TextColor3 = white
    F(tb)
    tb.TextSize = 14
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.Parent = win
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 3)
    local tbStroke = Instance.new("UIStroke", tb)
    tbStroke.Color = greenDark
    tbStroke.Thickness = 1
    local tbPad = Instance.new("UIPadding", tb)
    tbPad.PaddingLeft = UDim.new(0, 12)
    tbPad.PaddingRight = UDim.new(0, 12)

    local submit = Instance.new("TextButton")
    submit.Position = UDim2.fromOffset(20, 144)
    submit.Size = UDim2.new(1, -40, 0, 40)
    submit.BackgroundColor3 = box
    submit.BorderSizePixel = 0
    submit.Text = "submit"
    submit.TextColor3 = white
    F(submit)
    submit.TextSize = 14
    submit.AutoButtonColor = false
    submit.Parent = win
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 3)
    local subStroke = Instance.new("UIStroke", submit)
    subStroke.Color = greenDark
    subStroke.Thickness = 1
    submit.MouseEnter:Connect(function() subStroke.Color = green end)
    submit.MouseLeave:Connect(function() subStroke.Color = greenDark end)

    local discordBtn = Instance.new("TextButton")
    discordBtn.Position = UDim2.fromOffset(20, 196)
    discordBtn.Size = UDim2.new(1, -40, 0, 54)
    discordBtn.BackgroundColor3 = box
    discordBtn.BorderSizePixel = 0
    discordBtn.Text = "discord.gg/reQwaRfXyX"
    discordBtn.TextColor3 = white
    F(discordBtn)
    discordBtn.TextSize = 16
    discordBtn.AutoButtonColor = false
    discordBtn.Parent = win
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 3)
    local discStroke = Instance.new("UIStroke", discordBtn)
    discStroke.Color = greenDark
    discStroke.Thickness = 1
    discordBtn.MouseEnter:Connect(function() discStroke.Color = green end)
    discordBtn.MouseLeave:Connect(function() discStroke.Color = greenDark end)

    local discordHint = Instance.new("TextLabel")
    discordHint.Position = UDim2.fromOffset(20, 254)
    discordHint.Size = UDim2.new(1, -40, 0, 16)
    discordHint.BackgroundTransparency = 1
    discordHint.Text = "click to copy"
    F(discordHint)
    discordHint.TextSize = 11
    discordHint.TextColor3 = white
    discordHint.Parent = win

    local status = Instance.new("TextLabel")
    status.Position = UDim2.fromOffset(20, 274)
    status.Size = UDim2.new(1, -40, 0, 18)
    status.BackgroundTransparency = 1
    status.Text = ""
    F(status)
    status.TextSize = 12
    status.TextColor3 = red
    status.Parent = win

    local footer = Instance.new("TextLabel")
    footer.Position = UDim2.new(0, 0, 1, -28)
    footer.Size = UDim2.new(1, 0, 0, 16)
    footer.BackgroundTransparency = 1
    footer.Text = "need a key? join discord"
    F(footer)
    footer.TextSize = 11
    footer.TextColor3 = white
    footer.Parent = win

    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    discordBtn.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(_discordUrl) end)
        if ok then
            status.Text = "copied"
            status.TextColor3 = greenBright
            task.delay(1.5, function()
                if status and status.Parent then status.Text = ""; status.TextColor3 = red end
            end)
        else
            status.Text = _discordUrl
            status.TextColor3 = white
        end
    end)

    local function check()
        if tb.Text == _keyCode then
            status.Text = "accepted"
            status.TextColor3 = greenBright
            task.wait(0.4)
            keyGui:Destroy()
        else
            status.Text = "invalid key"
            status.TextColor3 = red
            tb.Text = ""
        end
    end
    submit.MouseButton1Click:Connect(check)
    tb.FocusLost:Connect(function(enter) if enter then check() end end)
end

local function MakeDraggable(frame, dragArea, guiParent)
    dragArea = dragArea or frame
    local dragging, dragStart, startPos = false, nil, nil
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

do
    local NotifGui = CreateUndetectedGui("Notifications")
    local Holder = Instance.new("Frame")
    Holder.Name = "NotifHolder"
    Holder.AnchorPoint = Vector2.new(0, 0)
    Holder.Position = UDim2.new(0, 15, 0, 15)
    Holder.Size = UDim2.new(0, 260, 0, 0)
    Holder.AutomaticSize = Enum.AutomaticSize.Y
    Holder.BackgroundTransparency = 1
    Holder.Parent = NotifGui
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = Holder
    MakeDraggable(Holder, Holder, NotifGui)
    local function createNotif(title, description, duration)
        title = title or "Notification"; description = description or ""; duration = duration or 3
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0; frame.Position = UDim2.new(-0.4, 0, 0, 0); frame.Parent = Holder
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(35, 90, 55); stroke.Thickness = 1; stroke.Transparency = 0.35
        local padding = Instance.new("UIPadding", frame)
        padding.PaddingTop = UDim.new(0, 6); padding.PaddingBottom = UDim.new(0, 6)
        padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)
        local layoutInner = Instance.new("UIListLayout", frame)
        layoutInner.Padding = UDim.new(0, 2); layoutInner.SortOrder = Enum.SortOrder.LayoutOrder
        local titleLabel = Instance.new("TextLabel", frame)
        titleLabel.BackgroundTransparency = 1; titleLabel.Size = UDim2.new(1, 0, 0, 16)
        titleLabel.AutomaticSize = Enum.AutomaticSize.Y; titleLabel.FontFace = Library.Font
        titleLabel.TextSize = 13; titleLabel.TextColor3 = Color3.fromRGB(235, 255, 240)
        titleLabel.Text = title; titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Top; titleLabel.LayoutOrder = 1
        if description ~= "" then
            local descLabel = Instance.new("TextLabel", frame)
            descLabel.BackgroundTransparency = 1; descLabel.Size = UDim2.new(1, 0, 0, 14)
            descLabel.AutomaticSize = Enum.AutomaticSize.Y; descLabel.FontFace = Library.Font
            descLabel.TextSize = 12; descLabel.TextColor3 = Color3.fromRGB(150, 215, 170)
            descLabel.Text = description; descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.TextYAlignment = Enum.TextYAlignment.Top; descLabel.TextWrapped = true; descLabel.LayoutOrder = 2
        end
        TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
        task.delay(duration, function()
            if not frame or not frame.Parent then return end
            local outTween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Position = UDim2.new(-0.5,0,0,0), BackgroundTransparency = 1})
            outTween:Play()
            TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
            for _, child in ipairs(frame:GetDescendants()) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                end
            end
            outTween.Completed:Connect(function() if frame and frame.Parent then frame:Destroy() end end)
        end)
    end
    function HitNotification() createNotif("Hit", "", 0.8) end
    _G.HitNotification = HitNotification
    if Library and Library.Notification then
        Library.Notification = function(self, a, b, c)
            if type(a) == "table" then
                createNotif(a.Title or "Notification", a.Description or "", a.Duration or 3)
            else
                createNotif(tostring(a or "Notification"), "", tonumber(b) or 3)
            end
        end
    end
end

do
    local GreenTheme = {
        Main = Color3.fromRGB(12,24,16), Background = Color3.fromRGB(10,20,13),
        Accent = Color3.fromRGB(50,220,110), Outline = Color3.fromRGB(35,90,55),
        Text = Color3.fromRGB(235,255,240), SubText = Color3.fromRGB(150,215,170),
        Button = Color3.fromRGB(22,48,32), Toggle = Color3.fromRGB(50,220,110),
        Slider = Color3.fromRGB(50,220,110), Dropdown = Color3.fromRGB(22,48,32),
        Tab = Color3.fromRGB(18,40,26), Section = Color3.fromRGB(16,34,22),
        Window = Color3.fromRGB(12,24,16), ScrollBar = Color3.fromRGB(50,220,110),
    }
    for k, v in pairs(GreenTheme) do
        pcall(function()
            if Library.Theme[k] ~= nil then
                Library.Theme[k] = v; Library:ChangeTheme(k, v)
                if Library.ThemeColorpickers and Library.ThemeColorpickers[k] then
                    Library.ThemeColorpickers[k]:Set(v)
                end
            end
        end)
    end
end

local TracerProperties = {
    ["Default"] = {Texture="rbxassetid://115789305736770", Brightness=1, Transparency=NumberSequence.new(0), LightEmission=1, Segments=1, TextureLength=4, TextureMode=Enum.TextureMode.Stretch, TextureSpeed=1, Width=0.15, FaceCamera=true},
    ["Obelus"] = {Texture="rbxassetid://2382169232", Brightness=1.5, Transparency=NumberSequence.new(0.45), LightEmission=1, LightInfluence=0, Segments=1, TextureLength=5, TextureMode=Enum.TextureMode.Stretch, TextureSpeed=0, Width=0.3, FaceCamera=true},
    ["Lightning"] = {Texture="rbxassetid://7151778302", Brightness=1.5, Transparency=NumberSequence.new(0.45), LightEmission=1, LightInfluence=0, Segments=10, TextureLength=1, TextureMode=Enum.TextureMode.Stretch, TextureSpeed=1, Width=1.2, FaceCamera=true},
    ["DNA"] = {Texture="rbxassetid://7071778278", Brightness=1.5, Transparency=NumberSequence.new(0.45), LightEmission=1, LightInfluence=0, Segments=1, TextureLength=12, TextureMode=Enum.TextureMode.Wrap, TextureSpeed=1, Width=0.6, FaceCamera=true},
    ["Minecraft"] = {Texture="rbxassetid://301464986", Brightness=1.5, Transparency=NumberSequence.new(0.3), LightEmission=1, LightInfluence=0, Segments=1, TextureLength=2, TextureMode=Enum.TextureMode.Wrap, TextureSpeed=2, Width=0.25, FaceCamera=true},
    ["Beam"] = {Texture="rbxassetid://4494641460", Brightness=2, Transparency=NumberSequence.new(0.2), LightEmission=1, LightInfluence=0, Segments=1, TextureLength=6, TextureMode=Enum.TextureMode.Stretch, TextureSpeed=0, Width=0.5, FaceCamera=true},
    ["Galaxy"] = {Texture="rbxassetid://1120738433", Brightness=1.5, Transparency=NumberSequence.new(0.3), LightEmission=1, LightInfluence=0, Segments=1, TextureLength=8, TextureMode=Enum.TextureMode.Wrap, TextureSpeed=1.5, Width=0.4, FaceCamera=true},
}

local HITSOUNDS = {
    ["Minecraft"]         = {id="73369656122118",  vol=1, pitch=1},
    ["Telegram"]          = {id="6696469190",      vol=1, pitch=1},
    ["Rust Headshot"]     = {id="127036469955037", vol=1, pitch=1},
    ["CSGO Kill"]         = {id="7269900245",      vol=1, pitch=1},
    ["Minecraft Bow"]     = {id="72656167409567",  vol=1, pitch=1},
    ["CSGO Headshot"]     = {id="93671116663771",  vol=1, pitch=1},
    ["Minecraft XP"]      = {id="101023147710668", vol=1, pitch=1},
    ["Minecraft Drop"]    = {id="90752223133261",  vol=1, pitch=1},
    ["Fortnite Headshot"] = {id="136947670419465", vol=1, pitch=1},
    ["Gamesense"]         = {id="4817809188",      vol=1, pitch=1},
    ["Primordial"]        = {id="97511223764004",  vol=1, pitch=1},
}
local HitsoundNames = {}
for name in pairs(HITSOUNDS) do table.insert(HitsoundNames, name) end
table.sort(HitsoundNames)
local SHOOTSOUNDS = {["Minecraft Bow"] = {id="116617548245274", vol=0.4, pitch=1}}
local HitsoundPool, HitsoundIdx = {}, {}
local ShootsoundPool, ShootsoundIdx = {}, {}
local POOL_SIZE = 8
do
    local SS = game:GetService("SoundService")
    for name, entry in pairs(HITSOUNDS) do
        HitsoundPool[name] = {}; HitsoundIdx[name] = 1
        for i = 1, POOL_SIZE do
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://"..entry.id
            s.Volume = (entry.vol or 1)
            s.PlaybackSpeed = entry.pitch or 1
            s:SetAttribute("__scorpion", true); s.Parent = SS
            table.insert(HitsoundPool[name], s)
        end
    end
    for name, entry in pairs(SHOOTSOUNDS) do
        if entry.id then
            ShootsoundPool[name] = {}; ShootsoundIdx[name] = 1
            for i = 1, POOL_SIZE do
                local s = Instance.new("Sound")
                s.SoundId = "rbxassetid://"..entry.id
                s.Volume = (entry.vol or 1)
                s.PlaybackSpeed = entry.pitch or 1
                s:SetAttribute("__scorpion", true); s.Parent = SS
                table.insert(ShootsoundPool[name], s)
            end
        end
    end
end
local function PlayHitsound(name)
    local pool = HitsoundPool[name]; if not pool then return end
    local entry = HITSOUNDS[name]; if not entry then return end
    local idx = HitsoundIdx[name]; local s = pool[idx]
    HitsoundIdx[name] = (idx % #pool) + 1
    s:Stop(); s.TimePosition = 0
    s.Volume = math.clamp((entry.vol or 1) * (SETTINGS and SETTINGS.Hitsound.Volume or 1), 0, 10)
    s:Play()
end
local function PlayShootsound(name)
    local pool = ShootsoundPool[name]; if not pool then return end
    local entry = SHOOTSOUNDS[name]; if not entry or not entry.id then return end
    local idx = ShootsoundIdx[name]; local s = pool[idx]
    ShootsoundIdx[name] = (idx % #pool) + 1
    s:Stop(); s.TimePosition = 0
    s.Volume = math.clamp((entry.vol or 1) * (SETTINGS and SETTINGS.ShootSound.Volume or 1), 0, 10)
    s:Play()
end
local Window = Library:Window({
    Name = "S C O R P I O N . W T F",
    GradientTitle = {Enabled=true, Start=Color3.fromRGB(255,255,255), Middle=Color3.fromRGB(80,255,140), End=Color3.fromRGB(30,160,80), Speed=1}
})
local Watermark  = Library:Watermark("scorpion.wtf", {"77974153657891", Color3.fromRGB(100,255,150)})
local KeybindList = Library:KeybindList()
pcall(function() KeybindList:SetVisibility(false) end)
local CombatTab   = Window:Page({Name="Combat",   Columns=2})
local MovementTab = Window:Page({Name="Movement", Columns=2})
local ESPTab      = Window:Page({Name="ESP",      Columns=2})
local MiscTab     = Window:Page({Name="Misc",     Columns=2})
local SettingsTab = Window:Page({Name="Settings", Columns=2})

SETTINGS = {
    Hitsound     = {Enabled=false, Sound="Minecraft", Volume=1.0, Notify=true},
    ShootSound   = {Enabled=false, Sound="Minecraft Bow", Volume=1.0},
    Tracer       = {Enabled=false, Color=Color3.fromRGB(255,255,255), Duration=1, Thickness=0.15, Style="Default"},
    Ambience     = {Enabled=false, Brightness=0.12, IndoorBrightness=0.04, Color=Color3.fromRGB(166,60,255)},
    NoRecoil     = {Enabled=false},
    NoSway       = {Enabled=false},
    RPM          = {Enabled=false, Multiplier=1},
    NoBob        = {Enabled=false},
    RemoveGrass  = {Enabled=false},
    Speed        = {Enabled=false, Speed=30},
    Fly          = {Enabled=false, Speed=10, DisableRestrictions=true},
    Noclip       = {Enabled=false},
    Freecam      = {Enabled=false, Speed=30},
    Fov          = {Enabled=false, Amount=100, Base=70},
    Zoom         = {Enabled=false, Amount=30, Base=70, AnimationSpeed=8},
    PlayersMaxDist=10000, BossMaxDist=3000, AIMaxDist=3000,
    ArmorViewer  = {Enabled=false, ShowLocal=false, MaxDistance=500},
    InstantBullet=false, InstantEoka=false,
    NoFallDamage=false, InstantLoot=false,
    PerfectFarm=false,
    ReloadBar=false, RangeMult=false, RangeAmount=5,
    ManipTargetColor=Color3.fromRGB(255,0,0),
    StoneMaxDist=1000, MetalMaxDist=1000, PhosphateMaxDist=1000,
    PlayersBoundingType="Static",
    PlayersSkeleton=false,
    PlayersSkeletonColor=Color3.fromRGB(235,255,240),
    PlayersWeaponIcon=false,
    PlayersWeaponIconColor=Color3.fromRGB(235,255,240),
    WeaponIcons = {},
    GunVFX = {
        SkinEnabled=false, Skin="Aurora", ScrollSpeed=0.1,
        GunChams=false, GunColor=Color3.fromRGB(166,147,243),
        GunMaterial="ForceField", GunTexture="None",
        ArmsChams=false, ArmsColor=Color3.fromRGB(255,255,255),
        ArmsMaterial="ForceField", ArmsTexture="None",
    },
    SilentAim = {
        Enabled=false, HitChance=100,
        Manipulation=false, ManipulationKey=false, ManipulationDistance=10,
        ManipulationIndicator=true, ManipulationIndicatorColor=Color3.fromRGB(255,0,0),
        VisibleCheck=false, DownCheck=true, TargetTeammates=false,
        TargetHead=true, TargetBody=false, FovSize=200,
        Autoshoot=false,
        FovCircle=false, FovCircleSize=200, FovColor=Color3.fromRGB(50,220,110),
        FovColor2=Color3.fromRGB(255,255,255), FovThickness=2, FovFill=false,
        FovFillTransparency=0.8, FovRainbow=false, FovRainbowSpeed=1,
        FovGradientRotation=0, FovRotate=false, FovRotateSpeed=1.2,
    },
}

local OriginalNoclipCollision = {}
local function ApplyNoclipState(enabled)
    local Character = Client.Character
    if not Character then return end
    for _, Part in ipairs(Character:GetDescendants()) do
        if Part:IsA("BasePart") then
            if enabled then
                if OriginalNoclipCollision[Part] == nil then
                    OriginalNoclipCollision[Part] = Part.CanCollide
                end
                Part.CanCollide = false
            else
                if OriginalNoclipCollision[Part] ~= nil then
                    Part.CanCollide = OriginalNoclipCollision[Part]
                    OriginalNoclipCollision[Part] = nil
                end
            end
        end
    end
end
RunService.Stepped:Connect(function()
    if not SETTINGS.Noclip.Enabled then return end
    local Character = Client.Character
    if not Character then return end
    for _, Part in ipairs(Character:GetDescendants()) do
        if Part:IsA("BasePart") then
            if OriginalNoclipCollision[Part] == nil then
                OriginalNoclipCollision[Part] = Part.CanCollide
            end
            Part.CanCollide = false
        end
    end
end)
Client.CharacterAdded:Connect(function()
    OriginalNoclipCollision = {}
end)

do
    local Mods = ReplicatedStorage:FindFirstChild('Modules') or ReplicatedStorage:WaitForChild('Modules', 10)
    if Mods then
        local Items = Mods:FindFirstChild('Items')
        if Items then
            local ok, ItemsM = pcall(require, Items)
            if ok and ItemsM then
                for i = 1, #ItemsM do
                    local item = ItemsM[i]
                    local img = item.Image
                    local imgId = ""
                    if typeof(img) == "table" then
                        if img.Default then imgId = img.Default end
                    elseif typeof(img) == "string" then
                        imgId = img
                    end
                    SETTINGS.WeaponIcons[item.Name] = imgId or ""
                end
            end
        end
    end
end
local function GetWeaponIcon(name)
    return SETTINGS.WeaponIcons[name] or ""
end

local AimSec = CombatTab:Section({Name="Silent Aim", Side=1})
AimSec:Toggle({Name="Enabled", Flag="SA_Enabled", Default=false, Callback=function(v) SETTINGS.SilentAim.Enabled=v end})
AimSec:Slider({Name="Silent Aim FOV", Flag="SA_Fov", Min=0, Default=20, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovSize=v*10 end})
AimSec:Slider({Name="Hit Chance", Flag="SA_HitChance", Min=0, Default=100, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.SilentAim.HitChance=v end})
AimSec:Dropdown({Name="Target Parts", Flag="SA_TargetParts", Items={"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, Multi=true, Default={"Head"},
    Callback=function(v)
        SETTINGS.SilentAim.TargetHead=false; SETTINGS.SilentAim.TargetBody=false
        if typeof(v)=="table" then
            for _, name in ipairs(v) do
                if name=="Head" then SETTINGS.SilentAim.TargetHead=true end
                if name~="Head" then SETTINGS.SilentAim.TargetBody=true end
            end
        end
    end})
AimSec:Toggle({Name="Manipulation",       Flag="SA_Manipulation",    Default=false, Callback=function(v) SETTINGS.SilentAim.Manipulation=v end})
AimSec:Label("Manip Keybind","Left"):Keybind({Name="Manip Key", Flag="SA_ManipKey", Default=Enum.KeyCode.None, Mode="Toggle", Callback=function(v) end})
AimSec:Slider({Name="Manip Distance", Flag="SA_ManipDist", Min=1, Default=10, Max=15, Suffix="s", Decimals=1, Callback=function(v) SETTINGS.SilentAim.ManipulationDistance=v end})
AimSec:Toggle({Name="Manip Indicator",    Flag="SA_ManipIndicator",  Default=true,  Callback=function(v) SETTINGS.SilentAim.ManipulationIndicator=v end})
AimSec:Label("Manip Indicator Color","Left"):Colorpicker({Name="Manip Ind Color", Flag="SA_ManipIndColor", Default=Color3.fromRGB(255,0,0), Callback=function(v) SETTINGS.SilentAim.ManipulationIndicatorColor=v end})
AimSec:Label("Manip Target Color","Left"):Colorpicker({Name="Manip Target Color", Flag="SA_ManipTargetColor", Default=Color3.fromRGB(255,0,0), Callback=function(v) SETTINGS.ManipTargetColor=v end})
AimSec:Toggle({Name="Autoshoot",          Flag="SA_Autoshoot",       Default=false, Callback=function(v) SETTINGS.SilentAim.Autoshoot=v end})
AimSec:Label("Autoshoot Keybind","Left"):Keybind({Name="Autoshoot Key", Flag="SA_AutoshootKey", Default=Enum.KeyCode.T, Mode="Toggle", Callback=function(v) end})
AimSec:Toggle({Name="Visible Check",      Flag="SA_VisibleCheck",    Default=false, Callback=function(v) SETTINGS.SilentAim.VisibleCheck=v end})
AimSec:Toggle({Name="Ignore Downed",      Flag="SA_DownCheck",       Default=true,  Callback=function(v) SETTINGS.SilentAim.DownCheck=v end})
AimSec:Toggle({Name="Target Teammates",   Flag="SA_TargetTeammates", Default=false, Callback=function(v) SETTINGS.SilentAim.TargetTeammates=v end})
AimSec:Toggle({Name="Draw FOV Circle",    Flag="SA_FovCircle",       Default=false, Callback=function(v) SETTINGS.SilentAim.FovCircle=v end})
AimSec:Slider({Name="Circle FOV Size",    Flag="SA_FovCircleSize",   Min=0, Default=20, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovCircleSize=v*10 end})
AimSec:Slider({Name="Circle Thickness",   Flag="SA_FovThickness",    Min=1, Default=2,  Max=10, Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovThickness=v end})
AimSec:Toggle({Name="Fill Circle",        Flag="SA_FovFill",         Default=false, Callback=function(v) SETTINGS.SilentAim.FovFill=v end})
AimSec:Slider({Name="Fill Transparency",  Flag="SA_FovFillTransparency", Min=0, Default=80, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovFillTransparency=v/100 end})
AimSec:Label("Color 1","Left"):Colorpicker({Name="Circle Color 1", Flag="SA_FovColor",  Default=Color3.fromRGB(50,220,110),   Callback=function(v) SETTINGS.SilentAim.FovColor=v end})
AimSec:Label("Color 2","Left"):Colorpicker({Name="Circle Color 2", Flag="SA_FovColor2", Default=Color3.fromRGB(255,255,255), Callback=function(v) SETTINGS.SilentAim.FovColor2=v end})
AimSec:Toggle({Name="Rainbow",            Flag="SA_FovRainbow",      Default=false, Callback=function(v) SETTINGS.SilentAim.FovRainbow=v end})
AimSec:Slider({Name="Rainbow Speed",      Flag="SA_FovRainbowSpeed", Min=0, Default=1, Max=5, Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovRainbowSpeed=v end})
AimSec:Slider({Name="Gradient Rotation",  Flag="SA_FovGradientRotation", Min=0, Default=0, Max=360, Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovGradientRotation=v end})
AimSec:Toggle({Name="Rotate Gradient",    Flag="SA_FovRotate",       Default=false, Callback=function(v) SETTINGS.SilentAim.FovRotate=v end})
AimSec:Slider({Name="Rotate Speed",       Flag="SA_FovRotateSpeed",  Min=0, Default=1.2, Max=5, Decimals=1, Callback=function(v) SETTINGS.SilentAim.FovRotateSpeed=v end})

local GunSec = CombatTab:Section({Name="Gun Mods & Misc", Side=2})
GunSec:Toggle({Name="No Recoil",        Flag="NoRecoil_Enabled",   Default=false, Callback=function(v) SETTINGS.NoRecoil.Enabled=v end})
GunSec:Toggle({Name="No Sway",          Flag="NoSway_Enabled",     Default=false, Callback=function(v) SETTINGS.NoSway.Enabled=v end})
GunSec:Toggle({Name="RPM",              Flag="RPM_Enabled",        Default=false, Callback=function(v) SETTINGS.RPM.Enabled=v end})
GunSec:Slider({Name="RPM Multiplier",   Flag="RPM_Mult",           Min=1, Default=1, Max=15, Suffix="x", Decimals=1, Callback=function(v) SETTINGS.RPM.Multiplier=v end})
GunSec:Toggle({Name="No Bob",           Flag="NoBob_Enabled",      Default=false, Callback=function(v) SETTINGS.NoBob.Enabled=v end})
GunSec:Toggle({Name="Instant Bullet",   Flag="InstantBullet",      Default=false, Callback=function(v) SETTINGS.InstantBullet=v end})
GunSec:Toggle({Name="Range Multiplier", Flag="RangeMult",          Default=false, Callback=function(v) SETTINGS.RangeMult=v end})
GunSec:Slider({Name="Range Amount",     Flag="RangeAmount",        Min=1, Default=5, Max=20, Suffix="x", Decimals=1, Callback=function(v) SETTINGS.RangeAmount=v end})
GunSec:Toggle({Name="Hitsound",         Flag="Hit_Enabled",        Default=false, Callback=function(v) SETTINGS.Hitsound.Enabled=v end})
GunSec:Dropdown({Name="Hitsound Select",Flag="Hit_Sound",          Items=HitsoundNames, Default="Minecraft", Callback=function(v) SETTINGS.Hitsound.Sound=v end})
GunSec:Slider({Name="Hitsound Volume",  Flag="Hit_Volume",         Min=0, Default=100, Max=1000, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.Hitsound.Volume=v/100 end})
GunSec:Toggle({Name="Hit Notifications",Flag="Hit_Notify",         Default=true, Callback=function(v) SETTINGS.Hitsound.Notify=v end})
GunSec:Toggle({Name="Shoot Sound (Minecraft Bow)",Flag="Shoot_Enabled",    Default=false, Callback=function(v) SETTINGS.ShootSound.Enabled=v end})
GunSec:Slider({Name="Shoot Volume",     Flag="Shoot_Volume",       Min=0, Default=100, Max=1000, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.ShootSound.Volume=v/100 end})
GunSec:Toggle({Name="Tracer",           Flag="Tracer_Enabled",     Default=false, Callback=function(v) SETTINGS.Tracer.Enabled=v end})
GunSec:Dropdown({Name="Tracer Style",   Flag="Tracer_Style",       Items={"Default","Obelus","Lightning","DNA","Minecraft","Beam","Galaxy"}, Default="Default", Callback=function(v) SETTINGS.Tracer.Style=v end})
GunSec:Label("Tracer Color","Left"):Colorpicker({Name="Tracer Color", Flag="Tracer_Color", Default=Color3.fromRGB(100,255,150), Callback=function(v) SETTINGS.Tracer.Color=v end})
GunSec:Slider({Name="Tracer Duration",  Flag="Tracer_Duration",    Min=0, Default=1, Max=15, Suffix="s", Decimals=2, Callback=function(v) SETTINGS.Tracer.Duration=v end})
GunSec:Slider({Name="Tracer Thickness", Flag="Tracer_Thickness",   Min=0, Default=15, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.Tracer.Thickness=v/100 end})

local ExploitSec = CombatTab:Section({Name="Exploits", Side=2})
ExploitSec:Toggle({Name="Instant Eoka",      Flag="InstantEoka_Enabled",     Default=false, Callback=function(v) SETTINGS.InstantEoka=v end})
ExploitSec:Toggle({Name="No Fall Damage",    Flag="NoFallDamage_Enabled",    Default=false, Callback=function(v) SETTINGS.NoFallDamage=v end})
ExploitSec:Toggle({Name="Instant Loot",      Flag="InstantLoot_Enabled",     Default=false,
    Callback=function(v)
        SETTINGS.InstantLoot=v
        local QS = _G.ScorpionQuickStackFunctions or {}
        if #QS > 0 then
            for _, func in ipairs(QS) do
                pcall(function()
                    _dbg.sc(func, 19, v and 0 or 0.9)
                    _dbg.sc(func, 20, v and 0 or 0.3)
                    _dbg.sc(func, 21, v and 0 or 0.1)
                end)
            end
        end
    end})
ExploitSec:Toggle({Name="Reload Bar",        Flag="ReloadBar_Enabled",       Default=false, Callback=function(v) SETTINGS.ReloadBar=v end})
ExploitSec:Toggle({Name="Perfect Farm",      Flag="PerfectFarm_Enabled",     Default=false, Callback=function(v) SETTINGS.PerfectFarm=v end})

local WorldSec = CombatTab:Section({Name="World", Side=2})
WorldSec:Toggle({Name="Remove Grass",   Flag="RemoveGrass_Enabled",   Default=false, Callback=function(v) SETTINGS.RemoveGrass.Enabled=v end})

local SpeedSec = MovementTab:Section({Name="Speed", Side=1})
SpeedSec:Toggle({Name="Enabled", Flag="SpeedEnabled", Default=false, Callback=function(v) SETTINGS.Speed.Enabled=v end})
SpeedSec:Slider({Name="Speed Amount", Flag="SpeedAmount", Min=16, Default=30, Max=200, Suffix=" studs", Decimals=1, Callback=function(v) SETTINGS.Speed.Speed=v end})
SpeedSec:Label("Toggle Keybind","Left"):Keybind({Name="Speed Keybind", Flag="SpeedKeybind", Default=Enum.KeyCode.B, Mode="Toggle", Callback=function(v) end})

local NoclipSec = MovementTab:Section({Name="Rocket Factory Noclip", Side=1})
NoclipSec:Toggle({Name="Enabled", Flag="NoclipEnabled", Default=false, Callback=function(v) SETTINGS.Noclip.Enabled=v; ApplyNoclipState(v) end})

local FlySec = MovementTab:Section({Name="Fly", Side=2})
FlySec:Toggle({Name="Enabled",               Flag="FlyEnabled",            Default=false, Callback=function(v) SETTINGS.Fly.Enabled=v end})
FlySec:Slider({Name="Fly Speed",             Flag="FlySpeed",              Min=1, Default=10, Max=100, Suffix=" spd", Decimals=1, Callback=function(v) SETTINGS.Fly.Speed=v end})
FlySec:Toggle({Name="Disable Restrictions",  Flag="FlyDisableRestrictions",Default=true,  Callback=function(v) SETTINGS.Fly.DisableRestrictions=v end})
FlySec:Label("Toggle Keybind","Left"):Keybind({Name="Fly Keybind", Flag="FlyKeybind", Default=Enum.KeyCode.F, Mode="Toggle", Callback=function(v) end})
FlySec:Label("Hold [Space] to fly up","Left")

local PlayerSec = ESPTab:Section({Name="Players", Side=1})
PlayerSec:Toggle({Name="Enabled",         Flag="PlayersESPEnabled",      Default=false})
PlayerSec:Toggle({Name="Visible Check",   Flag="PlayersVisibleCheck",    Default=false})
PlayerSec:Toggle({Name="Boxes",           Flag="PlayersBoxes",           Default=false})
PlayerSec:Dropdown({Name="Box Style",     Flag="PlayersBoxStyle",        Default="Full", Items={"Full","Corner"}, Callback=function(v) SETTINGS.PlayersBoxStyle=v end})
PlayerSec:Label("Box Color 1"):Colorpicker({Name="PC1",  Flag="PlayersBoxColor1",     Default=Color3.fromRGB(50,220,110)})
PlayerSec:Label("Box Color 2"):Colorpicker({Name="PC2",  Flag="PlayersBoxColor2",     Default=Color3.fromRGB(120,255,160)})
PlayerSec:Label("Not Vis Box Color 1"):Colorpicker({Name="PNV1",Flag="PlayersNotVisBoxColor1",Default=Color3.fromRGB(120,120,120)})
PlayerSec:Label("Not Vis Box Color 2"):Colorpicker({Name="PNV2",Flag="PlayersNotVisBoxColor2",Default=Color3.fromRGB(60,60,60)})

PlayerSec:Dropdown({Name="Bounding Type", Flag="PlayersBoundingType", Default="Static",
    Items={"Static","Dynamic"},
    Callback=function(v) SETTINGS.PlayersBoundingType=v end})

PlayerSec:Toggle({Name="Chams",           Flag="PlayersChams",           Default=false})
PlayerSec:Label("Chams Fill"):Colorpicker({Name="ChF",  Flag="PlayersChamsColor1",   Default=Color3.fromRGB(50,220,110)})
PlayerSec:Label("Chams Outline"):Colorpicker({Name="ChO",Flag="PlayersChamsColor2",  Default=Color3.fromRGB(120,255,160)})
PlayerSec:Label("Not Vis Chams Fill"):Colorpicker({Name="PNVC1",Flag="PlayersNotVisChamsColor1",Default=Color3.fromRGB(120,120,120)})
PlayerSec:Label("Not Vis Chams Outline"):Colorpicker({Name="PNVC2",Flag="PlayersNotVisChamsColor2",Default=Color3.fromRGB(60,60,60)})

PlayerSec:Toggle({Name="Skeleton",        Flag="PlayersSkeleton",       Default=false,
    Callback=function(v) SETTINGS.PlayersSkeleton=v end})
PlayerSec:Label("Skeleton Color"):Colorpicker({Name="PSkC", Flag="PlayersSkeletonColor", Default=Color3.fromRGB(235,255,240),
    Callback=function(v) SETTINGS.PlayersSkeletonColor=v end})

PlayerSec:Toggle({Name="Names",           Flag="PlayersNames",           Default=false})
PlayerSec:Label("Name Color"):Colorpicker({Name="PNC",  Flag="PlayersNameColor",     Default=Color3.fromRGB(235,255,240)})
PlayerSec:Toggle({Name="Health Bar",      Flag="PlayersHealth",          Default=false})
PlayerSec:Label("HP Color 1"):Colorpicker({Name="PH1",  Flag="PlayersHealthColor1",  Default=Color3.fromRGB(255,70,70)})
PlayerSec:Label("HP Color 2"):Colorpicker({Name="PH2",  Flag="PlayersHealthColor2",  Default=Color3.fromRGB(255,220,70)})
PlayerSec:Label("HP Color 3"):Colorpicker({Name="PH3",  Flag="PlayersHealthColor3",  Default=Color3.fromRGB(80,255,120)})
PlayerSec:Toggle({Name="Distance",        Flag="PlayersDistance",        Default=false})
PlayerSec:Label("Dist Color"):Colorpicker({Name="PDC",  Flag="PlayersDistanceColor", Default=Color3.fromRGB(235,255,240)})
PlayerSec:Toggle({Name="Weapon",          Flag="PlayersWeapon",          Default=false})
PlayerSec:Label("Weapon Color"):Colorpicker({Name="PWC",Flag="PlayersWeaponColor",   Default=Color3.fromRGB(235,255,240)})

PlayerSec:Toggle({Name="Weapon Icon",     Flag="PlayersWeaponIcon",      Default=false,
    Callback=function(v) SETTINGS.PlayersWeaponIcon=v end})
PlayerSec:Label("Weapon Icon Color"):Colorpicker({Name="PWIC", Flag="PlayersWeaponIconColor", Default=Color3.fromRGB(235,255,240),
    Callback=function(v) SETTINGS.PlayersWeaponIconColor=v end})

PlayerSec:Slider({Name="Max Distance", Flag="PlayersMaxDistance", Min=0, Default=100, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.PlayersMaxDist=v*100 end})

local BossSec = ESPTab:Section({Name="Boss", Side=1})
BossSec:Toggle({Name="Enabled",       Flag="BossESPEnabled",     Default=false})
BossSec:Toggle({Name="Visible Check", Flag="BossVisibleCheck",   Default=false})
BossSec:Toggle({Name="Boxes",         Flag="BossBoxes",          Default=false})
BossSec:Dropdown({Name="Box Style",   Flag="BossBoxStyle",       Default="Full", Items={"Full","Corner"}, Callback=function(v) SETTINGS.BossBoxStyle=v end})
BossSec:Label("Box Color 1"):Colorpicker({Name="BC1",  Flag="BossBoxColor1",     Default=Color3.fromRGB(255,80,80)})
BossSec:Label("Box Color 2"):Colorpicker({Name="BC2",  Flag="BossBoxColor2",     Default=Color3.fromRGB(255,200,80)})
BossSec:Label("Not Vis Box Color 1"):Colorpicker({Name="BNV1",Flag="BossNotVisBoxColor1",Default=Color3.fromRGB(120,120,120)})
BossSec:Label("Not Vis Box Color 2"):Colorpicker({Name="BNV2",Flag="BossNotVisBoxColor2",Default=Color3.fromRGB(60,60,60)})
BossSec:Toggle({Name="Chams",         Flag="BossChams",          Default=false})
BossSec:Label("Chams Fill"):Colorpicker({Name="BChF",Flag="BossChamsColor1",   Default=Color3.fromRGB(255,80,80)})
BossSec:Label("Chams Outline"):Colorpicker({Name="BChO",Flag="BossChamsColor2",Default=Color3.fromRGB(255,200,80)})
BossSec:Label("Not Vis Chams Fill"):Colorpicker({Name="BNVC1",Flag="BossNotVisChamsColor1",Default=Color3.fromRGB(120,120,120)})
BossSec:Label("Not Vis Chams Outline"):Colorpicker({Name="BNVC2",Flag="BossNotVisChamsColor2",Default=Color3.fromRGB(60,60,60)})
BossSec:Toggle({Name="Names",         Flag="BossNames",          Default=false})
BossSec:Label("Name Color"):Colorpicker({Name="BNC", Flag="BossNameColor",     Default=Color3.fromRGB(235,255,240)})
BossSec:Toggle({Name="Health Bar",    Flag="BossHealth",         Default=false})
BossSec:Label("HP Color 1"):Colorpicker({Name="BH1", Flag="BossHealthColor1",  Default=Color3.fromRGB(255,70,70)})
BossSec:Label("HP Color 2"):Colorpicker({Name="BH2", Flag="BossHealthColor2",  Default=Color3.fromRGB(255,220,70)})
BossSec:Label("HP Color 3"):Colorpicker({Name="BH3", Flag="BossHealthColor3",  Default=Color3.fromRGB(80,255,120)})
BossSec:Toggle({Name="Distance",      Flag="BossDistance",       Default=false})
BossSec:Label("Dist Color"):Colorpicker({Name="BDC", Flag="BossDistanceColor", Default=Color3.fromRGB(235,255,240)})
BossSec:Toggle({Name="Weapon",        Flag="BossWeapon",         Default=false})
BossSec:Label("Weapon Color"):Colorpicker({Name="BWC",Flag="BossWeaponColor",  Default=Color3.fromRGB(235,255,240)})
BossSec:Slider({Name="Max Distance", Flag="BossMaxDistance", Min=0, Default=100, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.BossMaxDist=v*100 end})

local AISec = ESPTab:Section({Name="AI", Side=2})
AISec:Toggle({Name="Enabled",       Flag="AIESPEnabled",    Default=false})
AISec:Toggle({Name="Visible Check", Flag="AIVisibleCheck",  Default=false})
AISec:Toggle({Name="Boxes",         Flag="AIBoxes",         Default=false})
AISec:Dropdown({Name="Box Style",   Flag="AIBoxStyle",      Default="Full", Items={"Full","Corner"}, Callback=function(v) SETTINGS.AIBoxStyle=v end})
AISec:Label("Box Color 1"):Colorpicker({Name="AC1",  Flag="AIBoxColor1",     Default=Color3.fromRGB(255,120,80)})
AISec:Label("Box Color 2"):Colorpicker({Name="AC2",  Flag="AIBoxColor2",     Default=Color3.fromRGB(255,220,120)})
AISec:Label("Not Vis Box Color 1"):Colorpicker({Name="ANV1",Flag="AINotVisBoxColor1",Default=Color3.fromRGB(120,120,120)})
AISec:Label("Not Vis Box Color 2"):Colorpicker({Name="ANV2",Flag="AINotVisBoxColor2",Default=Color3.fromRGB(60,60,60)})
AISec:Toggle({Name="Chams",         Flag="AIChams",         Default=false})
AISec:Label("Chams Fill"):Colorpicker({Name="AChF",Flag="AIChamsColor1",   Default=Color3.fromRGB(255,120,80)})
AISec:Label("Chams Outline"):Colorpicker({Name="AChO",Flag="AIChamsColor2",Default=Color3.fromRGB(255,220,120)})
AISec:Label("Not Vis Chams Fill"):Colorpicker({Name="ANVC1",Flag="AINotVisChamsColor1",Default=Color3.fromRGB(120,120,120)})
AISec:Label("Not Vis Chams Outline"):Colorpicker({Name="ANVC2",Flag="AINotVisChamsColor2",Default=Color3.fromRGB(60,60,60)})
AISec:Toggle({Name="Names",         Flag="AINames",         Default=false})
AISec:Label("Name Color"):Colorpicker({Name="ANC", Flag="AINameColor",     Default=Color3.fromRGB(235,255,240)})
AISec:Toggle({Name="Health Bar",    Flag="AIHealth",        Default=false})
AISec:Label("HP Color 1"):Colorpicker({Name="AH1", Flag="AIHealthColor1",  Default=Color3.fromRGB(255,70,70)})
AISec:Label("HP Color 2"):Colorpicker({Name="AH2", Flag="AIHealthColor2",  Default=Color3.fromRGB(255,220,70)})
AISec:Label("HP Color 3"):Colorpicker({Name="AH3", Flag="AIHealthColor3",  Default=Color3.fromRGB(80,255,120)})
AISec:Toggle({Name="Distance",      Flag="AIDistance",      Default=false})
AISec:Label("Dist Color"):Colorpicker({Name="ADC", Flag="AIDistanceColor", Default=Color3.fromRGB(235,255,240)})
AISec:Toggle({Name="Weapon",        Flag="AIWeapon",        Default=false})
AISec:Label("Weapon Color"):Colorpicker({Name="AWC",Flag="AIWeaponColor",  Default=Color3.fromRGB(235,255,240)})
AISec:Slider({Name="Max Distance", Flag="AIMaxDistance", Min=0, Default=100, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.AIMaxDist=v*100 end})

local MiscESPSec = ESPTab:Section({Name="Misc ESP", Side=2})
MiscESPSec:Toggle({Name="Enabled", Flag="MiscEnabledESP", Default=false})
local MiscItems = {"Stone","Metal","Phosphate","Wool","Animals","Care Package","Drops","Body Bag","Salvaged Flycopter","Auto Turret","Shotgun Turret"}
for _, v in ipairs(MiscItems) do
    MiscESPSec:Toggle({Name=v, Flag=v.."Enabled"}):Colorpicker({Name=v.." Color", Flag=v.."Color", Default=Color3.fromRGB(235,255,240)})
    MiscESPSec:Slider({Name=v.." Dist", Flag=v.."MaxDistance", Min=0, Default=50, Max=100, Suffix="%", Decimals=1,
        Callback=function(val) SETTINGS[v.."MaxDist"]=val*30 end})
end

local AmbienceSection = MiscTab:Section({Name="Ambience", Side=1})
AmbienceSection:Toggle({Name="Enabled",           Flag="Amb_Enabled",    Default=false, Callback=function(v) SETTINGS.Ambience.Enabled=v end})
AmbienceSection:Slider({Name="Brightness",         Flag="Amb_Brightness", Min=0, Default=12, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.Ambience.Brightness=v/100 end})
AmbienceSection:Slider({Name="Indoor Brightness",  Flag="Amb_Indoor",     Min=0, Default=4,  Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.Ambience.IndoorBrightness=v/100 end})
AmbienceSection:Label("Color","Left"):Colorpicker({Name="Color", Flag="Amb_Color", Default=Color3.fromRGB(80,255,140), Callback=function(v) SETTINGS.Ambience.Color=v end})

local ArmorSec = MiscTab:Section({Name="Armor Viewer", Side=1})
ArmorSec:Toggle({Name="Enabled",          Flag="Armor_Enabled",   Default=false, Callback=function(v) SETTINGS.ArmorViewer.Enabled=v end})
ArmorSec:Toggle({Name="Show Local Player",Flag="Armor_ShowLocal", Default=false, Callback=function(v) SETTINGS.ArmorViewer.ShowLocal=v end})
ArmorSec:Slider({Name="Max Distance",     Flag="Armor_MaxDist",   Min=0, Default=50, Max=100, Suffix="%", Decimals=1, Callback=function(v) SETTINGS.ArmorViewer.MaxDistance=v*30 end})

local FreecamSec = MiscTab:Section({Name="Freecam", Side=2})
FreecamSec:Toggle({Name="Enabled",Flag="Freecam_Enabled",Default=false,Callback=function(v) SETTINGS.Freecam.Enabled=v end})
FreecamSec:Label("Toggle Keybind","Left"):Keybind({Name="Freecam Keybind",Flag="Freecam_Keybind",Default=Enum.KeyCode.U,Mode="Toggle",Callback=function(v) end})
FreecamSec:Slider({Name="Speed",Flag="Freecam_Speed",Min=0,Default=30,Max=100,Suffix="%",Decimals=1,Callback=function(v) SETTINGS.Freecam.Speed=v/10*3 end})

local FovSec = MiscTab:Section({Name="FOV Changer", Side=2})
FovSec:Toggle({Name="FOV Changer",  Flag="FovChanger_Enabled", Default=false,
    Callback=function(v) SETTINGS.Fov.Enabled=v; if not v then Camera.FieldOfView=SETTINGS.Fov.Base end end})
FovSec:Slider({Name="FOV Amount",   Flag="FovChanger_Amount",  Min=70, Default=100, Max=120, Suffix="fov", Decimals=1, Callback=function(v) SETTINGS.Fov.Amount=v end})
FovSec:Toggle({Name="Zoom Enabled", Flag="FovZoom_Enabled",    Default=false, Callback=function(v) SETTINGS.Zoom.Enabled=v end})
FovSec:Label("Zoom Keybind","Left"):Keybind({Name="Zoom Key",Flag="FovZoom_Key",Default=Enum.KeyCode.Z,Mode="Toggle"})
FovSec:Slider({Name="Zoom Amount",     Flag="FovZoom_Amount",    Min=1,  Default=30, Max=80,  Decimals=1, Callback=function(v) SETTINGS.Zoom.Amount=v end})
FovSec:Slider({Name="Animation Speed", Flag="FovZoom_AnimSpeed", Min=1,  Default=8,  Max=30,  Decimals=1, Callback=function(v) SETTINGS.Zoom.AnimationSpeed=v end})

local GunVFXSec = MiscTab:Section({Name="Gun Chams & Skin", Side=2})
GunVFXSec:Toggle({Name="Weapon Skin",   Flag="GunVFX_SkinEnabled",  Default=false, Callback=function(v) SETTINGS.GunVFX.SkinEnabled=v end})
GunVFXSec:Dropdown({Name="Shader Preset",Flag="GunVFX_Skin",        Default="Aurora", Items={"Galaxy","Universe","Grooves","Liquid","Galaxy2","Tunnel","Aurora"}, Callback=function(v) SETTINGS.GunVFX.Skin=v end})
GunVFXSec:Slider({Name="Skin Scroll Speed",Flag="GunVFX_ScrollSpeed",Min=1,Default=10,Max=100,Suffix="%",Decimals=1,Callback=function(v) SETTINGS.GunVFX.ScrollSpeed=v/100 end})
GunVFXSec:Toggle({Name="Gun Chams",     Flag="GunVFX_GunChams",     Default=false, Callback=function(v) SETTINGS.GunVFX.GunChams=v end})
GunVFXSec:Label("Gun Color","Left"):Colorpicker({Name="Gun Color",Flag="GunVFX_GunColor",Default=Color3.fromRGB(166,147,243),Callback=function(v) SETTINGS.GunVFX.GunColor=v end})
GunVFXSec:Dropdown({Name="Gun Material",Flag="GunVFX_GunMaterial",Default="ForceField",Items={"ForceField","Neon","Glass","Ice","Wood","Plastic","Metal"},Callback=function(v) SETTINGS.GunVFX.GunMaterial=v end})
GunVFXSec:Dropdown({Name="Gun Texture", Flag="GunVFX_GunTexture", Default="None",Items={"Web","Swirl","Checkers","CandyCane","Dots","Scanning","Bubbles","Player FF Texture","Shield Forcefield","Water","America","Rainbow","Akatsuki","None"},Callback=function(v) SETTINGS.GunVFX.GunTexture=v end})
GunVFXSec:Toggle({Name="Arms Chams",    Flag="GunVFX_ArmsChams",    Default=false, Callback=function(v) SETTINGS.GunVFX.ArmsChams=v end})
GunVFXSec:Label("Arms Color","Left"):Colorpicker({Name="Arms Color",Flag="GunVFX_ArmsColor",Default=Color3.fromRGB(255,255,255),Callback=function(v) SETTINGS.GunVFX.ArmsColor=v end})
GunVFXSec:Dropdown({Name="Arms Material",Flag="GunVFX_ArmsMaterial",Default="ForceField",Items={"ForceField","Neon","Glass","Ice","Wood","Plastic","Metal"},Callback=function(v) SETTINGS.GunVFX.ArmsMaterial=v end})
GunVFXSec:Dropdown({Name="Arms Texture", Flag="GunVFX_ArmsTexture", Default="None",Items={"Web","Swirl","Checkers","CandyCane","Dots","Scanning","Bubbles","Player FF Texture","Shield Forcefield","Water","America","Rainbow","Akatsuki","None"},Callback=function(v) SETTINGS.GunVFX.ArmsTexture=v end})

local ThemesSection = SettingsTab:Section({Name="Themes", Side=1})
pcall(function()
    for Index, Value in Library.Theme do
        Library.ThemeColorpickers[Index] = ThemesSection:Label(Index,"Left"):Colorpicker({
            Name=Index, Flag="Theme"..Index, Default=Value,
            Callback=function(v) Library.Theme[Index]=v; Library:ChangeTheme(Index,v) end})
    end
end)

local ConfigsSection = SettingsTab:Section({Name="Configs", Side=2})
do
    local CN, SC
    local CL = ConfigsSection:Listbox({Name="Configs list",Flag="Configs List",Items={},Multi=false,Default=nil,Callback=function(v) SC=v end})
    ConfigsSection:Textbox({Name="Name",Flag="Config Name",Default="",Placeholder=". . .",Callback=function(v) CN=v end})
    ConfigsSection:Button({Name="Load Config",Callback=function() if SC then Library:LoadConfig(readfile(Library.Folders.Configs.."/"..SC)) end end}):SubButton({
        Name="Save Config",Callback=function() if SC then Library:SaveConfig(SC) end end})
    ConfigsSection:Button({Name="Create Config",Callback=function()
        if CN=="" then return end
        if not isfile(Library.Folders.Configs.."/"..CN..".json") then
            writefile(Library.Folders.Configs.."/"..CN..".json",Library:GetConfig())
            Library:RefreshConfigsList(CL)
        else Library:Notification("Config exists",3,Color3.fromRGB(255,0,0)) end
    end}):SubButton({Name="Delete Config",Callback=function() if SC then Library:DeleteConfig(SC); Library:RefreshConfigsList(CL) end end})
    ConfigsSection:Button({Name="Refresh Configs",Callback=function() Library:RefreshConfigsList(CL) end})
    Library:RefreshConfigsList(CL)
    ConfigsSection:Label("Menu Keybind","Left"):Keybind({Name="Menu Keybind",Flag="Menu Keybind",Default=Enum.KeyCode.RightControl,Mode="Toggle",
        Callback=function(_) Library.MenuKeybind=Library.Flags["Menu Keybind"].Key end})
    ConfigsSection:Toggle({Name="Watermark",   Flag="Watermark",   Default=false,Callback=function(v) Watermark:SetVisibility(v) end})
    ConfigsSection:Toggle({Name="Keybind List",Flag="Keybind List",Default=false,Callback=function(v) KeybindList:SetVisibility(v) end})
end

local Flags = Library.Flags

local FlyGui = CreateUndetectedGui("FlyIndicator")
local FlyLabel = Instance.new("TextLabel")
FlyLabel.BackgroundTransparency=1; FlyLabel.AnchorPoint=Vector2.new(0.5,0.5)
FlyLabel.Position=UDim2.fromScale(0.5,0.55); FlyLabel.Size=UDim2.fromOffset(200,24)
FlyLabel.FontFace=Library.Font; FlyLabel.TextSize=16; FlyLabel.Text="FlyHack"
FlyLabel.TextColor3=Color3.fromRGB(255,255,0); FlyLabel.TextStrokeTransparency=0
FlyLabel.TextStrokeColor3=Color3.fromRGB(0,0,0); FlyLabel.Visible=false; FlyLabel.ZIndex=100; FlyLabel.Parent=FlyGui

local ManipIndicatorGui = CreateUndetectedGui("ManipIndicator")
local ManipIndicator = Instance.new("TextLabel")
ManipIndicator.BackgroundTransparency=1; ManipIndicator.AnchorPoint=Vector2.new(0.5,0.5)
ManipIndicator.Position=UDim2.fromScale(0.5,0.45); ManipIndicator.Size=UDim2.fromOffset(200,20)
ManipIndicator.FontFace=Library.Font; ManipIndicator.TextSize=14; ManipIndicator.Text="manipulated"
ManipIndicator.TextColor3=Color3.fromRGB(255,0,0); ManipIndicator.TextStrokeTransparency=0
ManipIndicator.TextStrokeColor3=Color3.fromRGB(0,0,0); ManipIndicator.Visible=false; ManipIndicator.ZIndex=100; ManipIndicator.Parent=ManipIndicatorGui

local ReloadBarGui   = CreateUndetectedGui("ReloadBar")
local ReloadBarFrame = Instance.new("Frame")
ReloadBarFrame.AnchorPoint=Vector2.new(0.5,1); ReloadBarFrame.Position=UDim2.new(0.5,0,1,-80)
ReloadBarFrame.Size=UDim2.fromOffset(280,32); ReloadBarFrame.BackgroundColor3=Color3.fromRGB(15,15,15)
ReloadBarFrame.BackgroundTransparency=0.15; ReloadBarFrame.BorderSizePixel=0; ReloadBarFrame.Visible=false; ReloadBarFrame.Parent=ReloadBarGui
Instance.new("UICorner",ReloadBarFrame).CornerRadius=UDim.new(0,4)
local ReloadBarStroke=Instance.new("UIStroke",ReloadBarFrame); ReloadBarStroke.Color=Color3.fromRGB(35,90,55); ReloadBarStroke.Thickness=1; ReloadBarStroke.Transparency=0.35
local ReloadBarTitle=Instance.new("TextLabel"); ReloadBarTitle.BackgroundTransparency=1
ReloadBarTitle.Position=UDim2.new(0,10,0,4); ReloadBarTitle.Size=UDim2.new(1,-20,0,12)
ReloadBarTitle.FontFace=Library.Font; ReloadBarTitle.TextSize=11; ReloadBarTitle.TextColor3=Color3.fromRGB(235,255,240)
ReloadBarTitle.TextXAlignment=Enum.TextXAlignment.Left; ReloadBarTitle.Text="Reloading"; ReloadBarTitle.ZIndex=3; ReloadBarTitle.Parent=ReloadBarFrame
local ReloadBarBg=Instance.new("Frame"); ReloadBarBg.Position=UDim2.new(0,10,0,19); ReloadBarBg.Size=UDim2.new(1,-20,0,6)
ReloadBarBg.BackgroundColor3=Color3.fromRGB(20,40,26); ReloadBarBg.BorderSizePixel=0; ReloadBarBg.Parent=ReloadBarFrame
Instance.new("UICorner",ReloadBarBg).CornerRadius=UDim.new(1,0)
local ReloadBarFill=Instance.new("Frame"); ReloadBarFill.Size=UDim2.new(0,0,1,0)
ReloadBarFill.BackgroundColor3=Color3.fromRGB(50,220,110); ReloadBarFill.BorderSizePixel=0; ReloadBarFill.Parent=ReloadBarBg
Instance.new("UICorner",ReloadBarFill).CornerRadius=UDim.new(1,0)
local ReloadBarGrad=Instance.new("UIGradient",ReloadBarFill)
ReloadBarGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(50,220,110)),ColorSequenceKeypoint.new(1,Color3.fromRGB(120,255,160))})

local function StartReloadBar(duration)
    if not SETTINGS.ReloadBar then return end
    duration = duration or 2
    ReloadBarFrame.Visible=true; ReloadBarFill.Size=UDim2.new(0,0,1,0)
    TweenService:Create(ReloadBarFill,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,1,0)}):Play()
    task.delay(duration+0.1, function() if ReloadBarFrame then ReloadBarFrame.Visible=false end end)
end

local function GetEffectiveFov()
    local kb=Flags["FovZoom_Key"]; local zoomOn=false
    if kb then zoomOn=((kb.Toggled==true)or(kb.Active==true)) end
    zoomOn=SETTINGS.Zoom.Enabled and zoomOn
    local fovOn=SETTINGS.Fov.Enabled
    if (not zoomOn) and (not fovOn) then return Camera.FieldOfView end
    return zoomOn and SETTINGS.Zoom.Amount or SETTINGS.Fov.Amount
end
local function Project(worldPos)
    local vp=Camera.ViewportSize; local cf=Camera.CFrame
    local camSpace=cf:PointToObjectSpace(worldPos); local z=-camSpace.Z
    if z<=0.001 then return nil,0,false end
    local fov=GetEffectiveFov(); local t=math.tan(math.rad(fov*0.5))
    if t<=0 then return nil,0,false end
    local aspect=vp.X/vp.Y
    local ndcX=(camSpace.X/z)/(t*aspect); local ndcY=(camSpace.Y/z)/t
    local screenX=(ndcX*0.5+0.5)*vp.X; local screenY=(-ndcY*0.5+0.5)*vp.Y
    local onScreen=(screenX>=0 and screenX<=vp.X)and(screenY>=0 and screenY<=vp.Y)
    return Vector2.new(screenX,screenY),z,onScreen
end

local AvatarCache,AvatarPending={},{}
local function GetAvatarUrl(userId)
    if AvatarCache[userId] then return AvatarCache[userId] end
    if not AvatarPending[userId] then
        AvatarPending[userId]=true
        task.spawn(function()
            local ok,url=pcall(function() return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
            if ok and url then AvatarCache[userId]=url end; AvatarPending[userId]=nil
        end)
    end
    return ""
end
local function ApplyAvatar(imgLabel,userId)
    if not imgLabel then return end
    local cached=AvatarCache[userId]
    if cached and cached~="" then imgLabel.Image=cached; return end
    local url=GetAvatarUrl(userId)
    if url~="" then imgLabel.Image=url end
    task.spawn(function()
        local waited=0
        while waited<5 and not(AvatarCache[userId] and AvatarCache[userId]~="") do task.wait(0.1); waited=waited+0.1 end
        if imgLabel and imgLabel.Parent and AvatarCache[userId] then imgLabel.Image=AvatarCache[userId] end
    end)
end

_G.scorpionManipTarget=nil
RunService.Heartbeat:Connect(function(dt)
    if not SETTINGS.Speed.Enabled then return end
    local kb=Flags["SpeedKeybind"]; local keyOn=false
    if kb then keyOn=(kb.Toggled==true)or(kb.Active==true) end
    if not keyOn then return end
    local Character=Client.Character; if not Character then return end
    local Root=Character:FindFirstChild("HumanoidRootPart")
    local Humanoid=Character:FindFirstChildOfClass("Humanoid")
    if not Root or not Humanoid or Humanoid.Health<=0 then return end
    local x,z=0,0
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then x+=1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then x-=1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then z+=1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then z-=1 end
    if x~=0 or z~=0 then
        local cf=Camera.CFrame
        local forward=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
        local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
        local move=(right*x+forward*z).Unit; local speed=SETTINGS.Speed.Speed or 30
        Root.Velocity=Vector3.new(move.X*speed,Root.Velocity.Y,move.Z*speed)
    end
end)

do
    local function disable_restrictions(humanoid)
        if not _conn then return end
        for _, v in ipairs(_conn(humanoid.StateChanged)) do
            if v.Function then
                local data = _dbg.info(v.Function,"s")
                if data and data:find("ViewmodelController",1,true) then
                    local old
                    old = _hook(v.Function, function(...)
                        if SETTINGS.Fly.DisableRestrictions then return end
                        return old(...)
                    end)
                end
            end
        end
    end
    local function attach(c)
        local humanoid=c:WaitForChild("Humanoid",5)
        local vmc=c:WaitForChild("ViewmodelController",5)
        if humanoid and vmc then disable_restrictions(humanoid) end
    end
    if Client.Character then attach(Client.Character) end
    Client.CharacterAdded:Connect(attach)
end

RunService.Heartbeat:Connect(function(delta)
    local kb=Flags["FlyKeybind"]; local keyOn=kb and((kb.Toggled==true)or(kb.Active==true))
    if not SETTINGS.Fly.Enabled or not keyOn then FlyLabel.Visible=false; return end
    local hrp=Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")
    local human=Client.Character and Client.Character:FindFirstChildOfClass("Humanoid")
    if not(hrp and human) then FlyLabel.Visible=false; return end
    local space=UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local climb_speed=SETTINGS.Fly.Speed or 10
    local old_sigma=hrp.AssemblyLinearVelocity
    if space then
        FlyLabel.Visible=true
        hrp.CFrame=hrp.CFrame*CFrame.new(0,climb_speed*delta,0)
        hrp.AssemblyLinearVelocity=Vector3.new(0,-9e9,0)
        RunService.RenderStepped:Wait()
        hrp.AssemblyLinearVelocity=Vector3.new(old_sigma.X,climb_speed,old_sigma.Z)
    elseif human:GetState()==Enum.HumanoidStateType.Freefall and not space then
        FlyLabel.Visible=false
        local current_velocity=hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity=Vector3.new(0,-9e9,0)
        RunService.RenderStepped:Wait()
        hrp.AssemblyLinearVelocity=Vector3.new(current_velocity.X,math.clamp(current_velocity.Y,-7.5,0),current_velocity.Z)
    else
        FlyLabel.Visible=false
    end
end)

do
    local baseFov=Camera.FieldOfView; SETTINGS.Fov.Base=baseFov; local displayFov=baseFov
    RunService.RenderStepped:Connect(function(dt)
        local kb=Flags["FovZoom_Key"]; local keyOn=false
        if kb then keyOn=(kb.Toggled==true)or(kb.Active==true) end
        local zoomOn=SETTINGS.Zoom.Enabled and keyOn; local fovOn=SETTINGS.Fov.Enabled
        if (not zoomOn) and (not fovOn) then
            if math.abs(displayFov-baseFov)<0.5 then
                baseFov=Camera.FieldOfView; displayFov=baseFov; SETTINGS.Fov.Base=baseFov; return
            end
        end
        local targetFov=baseFov
        if zoomOn then targetFov=SETTINGS.Zoom.Amount
        elseif fovOn then targetFov=SETTINGS.Fov.Amount end
        local animSpeed=SETTINGS.Zoom.AnimationSpeed or 8
        displayFov=displayFov+(targetFov-displayFov)*math.min(dt*animSpeed,1)
        if displayFov<=80 then
            Camera.FieldOfView=displayFov
        else
            Camera.FieldOfView=baseFov
            local scale=math.tan(math.rad(baseFov*0.5))/math.tan(math.rad(displayFov*0.5))
            Camera.CFrame=Camera.CFrame*CFrame.new(0,0,0,scale,0,0,0,scale,0,0,0,1)
        end
    end)
end

do
    local __S=getgenv().__SCORP
    local oldabs=(__S and (__S.hooks.abs or __S.real.abs)) or math.abs
    __S.hooks.abs=function(x)
        if SETTINGS.NoBob.Enabled and _dbg.tb():find('ViewmodelController') then
            for level=2,4 do
                if _ilv and _ilv(level) then
                    local stack=_gs2 and _gs2(level)
                    local v=stack and stack[2]
                    if type(v)=='boolean' then
                        if _ss2 then _ss2(level,2,true) end
                    end
                end
            end
        end
        return oldabs(x)
    end
end

do
    local GUNVFX_ASSETS = {
        Textures = {
            Web="rbxassetid://301464986", Swirl="rbxassetid://8133639623",
            Checkers="rbxassetid://5790215150", CandyCane="rbxassetid://6853532738",
            Dots="rbxassetid://5830615971", Scanning="rbxassetid://5843010904",
            Bubbles="rbxassetid://1461576423", ["Player FF Texture"]="rbxassetid://4494641460",
            ["Shield Forcefield"]="rbxassetid://361073795",
            Water="rbxasset://textures/water/normal_21.dds",
            America="rbxassetid://936775406", Rainbow="rbxassetid://252684207",
            Akatsuki="rbxassetid://10913193650", None="",
        },
        Shaders = {
            Galaxy="rbxassetid://102123368175852", Universe="rbxassetid://118495641668346",
            Grooves="rbxassetid://125656202528237", Liquid="rbxassetid://125656202528237",
            Galaxy2="rbxassetid://125656202528237", Tunnel="rbxassetid://71437209144052",
            Aurora="rbxassetid://129433290925875",
        },
        AnimatedTextures={},
    }
    local function makeChamClone(part,color3,transparency,materialName,textureKey)
        local clone=part:Clone(); clone.Name="\0"; clone:SetAttribute("__cloned",true)
        clone.Anchored=false; clone.CanCollide=false; clone.CanTouch=false
        clone.CanQuery=false; clone.Massless=true; clone.Transparency=transparency or 0
        clone.LocalTransparencyModifier=0
        if color3 then clone.Color=color3 end
        if materialName then clone.Material=Enum.Material[materialName] end
        if clone:IsA("MeshPart") and materialName=="ForceField" and textureKey then
            clone.TextureID=GUNVFX_ASSETS.Textures[textureKey] or ""
        end
        clone.Parent=part.Parent; clone.CFrame=part.CFrame
        local wc=Instance.new("WeldConstraint"); wc.Part0=clone; wc.Part1=part; wc.Parent=clone
        return clone
    end
    task.spawn(function()
        while true do
            task.wait(1/30)
            local list=GUNVFX_ASSETS.AnimatedTextures; local i=1
            while i<=#list do
                local d=list[i]; local t=d.texture
                if t and t.Parent then t.OffsetStudsU=t.OffsetStudsU+d.speed*0.03; t.OffsetStudsV=t.OffsetStudsV+d.speed*0.03; i+=1
                else table.remove(list,i) end
            end
        end
    end)
    local VMsFolder=Workspace:FindFirstChild("VFX") and Workspace.VFX:FindFirstChild("VMs")
    if not VMsFolder then
        local vfx=Workspace:WaitForChild("VFX",10); VMsFolder=vfx and vfx:WaitForChild("VMs",10)
    end
    if VMsFolder then
        VMsFolder.ChildAdded:Connect(function(VM)
            if VM.Name=="IgnoreMe" then return end
            task.spawn(function()
                task.wait(0.2)
                local Viewmodel=Workspace.VFX.VMs:FindFirstChildOfClass("Model"); if not Viewmodel then return end
                local Arms=Viewmodel:WaitForChild("Arms",9e9); local Weapon=Viewmodel:WaitForChild("Weapon",9e9)
                local GVF=SETTINGS.GunVFX
                for _, Part in next, Viewmodel:GetDescendants() do
                    if GVF.SkinEnabled and Part:IsDescendantOf(Weapon) and Part:IsA("MeshPart") and GVF.Skin then
                        for _, c in pairs(Part:GetChildren()) do if c:IsA("Texture") and c.Name=="WeaponShaderTexture" then c:Destroy() end end
                        local faces={Enum.NormalId.Front,Enum.NormalId.Back,Enum.NormalId.Left,Enum.NormalId.Right,Enum.NormalId.Top,Enum.NormalId.Bottom}
                        local shaderId=GUNVFX_ASSETS.Shaders[GVF.Skin]
                        if shaderId then
                            for _, face in pairs(faces) do
                                local tex=Instance.new("Texture"); tex.Name="WeaponShaderTexture"
                                tex.Face=face; tex.Texture=shaderId; tex.StudsPerTileU=1; tex.StudsPerTileV=1; tex.Parent=Part
                                if GVF.ScrollSpeed~=0 then table.insert(GUNVFX_ASSETS.AnimatedTextures,{texture=tex,speed=GVF.ScrollSpeed}) end
                            end
                        end
                    end
                    if GVF.GunChams and Part:IsDescendantOf(Weapon) and (Part:IsA("Part") or Part:IsA("MeshPart")) and not Part:GetAttribute("__hidden") then
                        makeChamClone(Part,GVF.GunColor,0,GVF.GunMaterial,GVF.GunTexture)
                        Part.Transparency=1; Part.LocalTransparencyModifier=1; Part:SetAttribute("__hidden",true)
                    end
                    if GVF.ArmsChams and Part:IsDescendantOf(Arms) and (Part:IsA("Part") or Part:IsA("MeshPart")) and not Part:GetAttribute("__hidden") then
                        makeChamClone(Part,GVF.ArmsColor,0,GVF.ArmsMaterial,GVF.ArmsTexture)
                        Part.Transparency=1; Part.LocalTransparencyModifier=1; Part:SetAttribute("__hidden",true)
                    end
                    if Part:IsA("SurfaceAppearance") and (Part:IsDescendantOf(Arms) or Part:IsDescendantOf(Weapon)) and not Part.Parent:GetAttribute("__cloned") then
                        Part:Destroy()
                    end
                end
            end)
        end)
    end
end

do
    local Modules=ReplicatedStorage:WaitForChild('Modules',10)
    if Modules then
        local ItemClass=Modules:FindFirstChild('ItemClass')
        if ItemClass then
            ItemClass=require(ItemClass)
            local __S=getgenv().__SCORP
            local oldAS=(__S and (__S.hooks.AttachmentStats or __S.real.AttachmentStats)) or ItemClass.AttachmentStats
            __S.hooks.AttachmentStats=function(v50,v51)
                local tb
                local okTb=pcall(function() tb = debug.traceback() end)
                if not okTb or type(tb) ~= "string" then tb = "" end
                local r = oldAS(v50,v51)
                if tb:find('ViewmodelController') and r then
                    if SETTINGS.NoRecoil.Enabled  then r.RecoilMult=-1 end
                    if SETTINGS.NoSway.Enabled     then r.SwayMult=-1 end
                    if SETTINGS.RPM.Enabled        then r.FireRateMult=SETTINGS.RPM.Multiplier-1 end
                    if SETTINGS.InstantBullet       then r.SpeedMult=100 end
                    if SETTINGS.RangeMult           then r.RangeMult=SETTINGS.RangeAmount end
                end
                return r
            end
        end
    end
end

do
    if not _hook then return end
    local Modules=ReplicatedStorage:WaitForChild('Modules',10)
    if not Modules then return end
    local RaycastModule=Modules:FindFirstChild('RaycastUtil')
    if not RaycastModule then return end
    local ok, RaycastUtil = pcall(require, RaycastModule)
    if not ok or not RaycastUtil or type(RaycastUtil.Raycast) ~= "function" then return end
    local __S=getgenv().__SCORP
    local OriginalRaycast=(__S and (__S.hooks.Raycast or __S.real.Raycast)) or RaycastUtil.Raycast
    __S.hooks.Raycast = function(...)
        local tb
        local okTb=pcall(function() tb=debug.traceback() end)
        if not okTb or type(tb)~="string" then tb="" end
        if tb:find('ViewmodelController') and SETTINGS.PerfectFarm then
            local Output={OriginalRaycast(...)}
            local HitInstance=Output[1]
            local HitPosition=Output[2]
            if typeof(HitInstance)=="Instance" and typeof(HitPosition)=="Vector3" then
                local Model=HitInstance.Parent
                if Model and Model:IsA("Model") then
                    local Folder=Model.Parent
                    if Folder and Folder:IsA("Folder") and (Folder.Name=="Trees" or Folder.Name=="Nodes") then
                        local CriticalPart=Model:FindFirstChild("NodeSpark") or Model:FindFirstChild("TreeX")
                        if CriticalPart and CriticalPart:IsA("Model") then
                            local PrimaryPart=CriticalPart.PrimaryPart
                            if PrimaryPart then
                                Output[1]=PrimaryPart
                            end
                        end
                    end
                end
            end
            return unpack(Output)
        end
        return OriginalRaycast(...)
    end
end

do
    local function hookEoka(c)
        task.wait(1)
        local VMC=c:FindFirstChild("ViewmodelController"); if not VMC then return end
        local ok,vmcEnv=pcall(_senv,VMC); if not ok or not vmcEnv then return end
        local old=vmcEnv.ChooseRandom; if type(old)~="function" then return end
        vmcEnv.ChooseRandom=function(...)
            if SETTINGS.InstantEoka then return 0 end
            return old(...)
        end
    end
    if Client.Character then task.spawn(hookEoka,Client.Character) end
    Client.CharacterAdded:Connect(hookEoka)
end

do
    local fallRayParams=RaycastParams.new(); fallRayParams.FilterType=RAY_FILTER_EXCLUDE; fallRayParams.IgnoreWater=true; fallRayParams.FilterDescendantsInstances={}
    RunService.Heartbeat:Connect(function()
        if not SETTINGS.NoFallDamage then return end
        local Character=Client.Character; if not Character then return end
        local Root=Character:FindFirstChild("HumanoidRootPart"); local Humanoid=Character:FindFirstChildOfClass("Humanoid")
        if not Root or not Humanoid or Humanoid.Health<=0 then return end
        if Humanoid:GetState()==Enum.HumanoidStateType.Dead then return end
        fallRayParams.FilterDescendantsInstances={Character,Camera}
        local Result=Workspace:Raycast(Root.Position,Vector3.new(0,-1000,0),fallRayParams)
        if Result and Result.Distance>10 then
            task.spawn(function()
                local OldVel=Root.AssemblyLinearVelocity
                for _, Part in ipairs(Character:GetChildren()) do if Part:IsA("BasePart") then Part.AssemblyLinearVelocity=Vector3.new(0,9999,0) end end
                RunService.RenderStepped:Wait()
                for _, Part in ipairs(Character:GetChildren()) do if Part:IsA("BasePart") then Part.AssemblyLinearVelocity=OldVel end end
            end)
        end
    end)
end

do
    _G.ScorpionQuickStackFunctions=_G.ScorpionQuickStackFunctions or {}
    local function scanEquipArmor(c)
        task.wait(1)
        local IC=c:FindFirstChild("InventoryController"); if not IC then return end
        local EA=IC:FindFirstChild("EquipArmor"); if not EA then return end
        if not _conn then return end
        for _, conn in _conn(EA.Event) do
            local f=conn.Function; if not f then continue end
            local ok,upvalues=pcall(_dbg.gup,f); if not ok or type(upvalues)~="table" then continue end
            for _, v in ipairs(upvalues) do
                if type(v)~="function" then continue end
                local okC,constants=pcall(_dbg.gc,v); if not okC or type(constants)~="table" then continue end
                if constants[1]=="ArmorEquip" and constants[5]=="GetAttribute" then
                    if SETTINGS.InstantLoot then
                        pcall(function() _dbg.sc(v,19,0); _dbg.sc(v,20,0); _dbg.sc(v,21,0) end)
                    end
                    table.insert(_G.ScorpionQuickStackFunctions,v)
                end
            end
        end
    end
    if Client.Character then task.spawn(scanEquipArmor,Client.Character) end
    Client.CharacterAdded:Connect(scanEquipArmor)
end

do
    local VMsFolder=Workspace:FindFirstChild("VFX") and Workspace.VFX:FindFirstChild("VMs")
    if VMsFolder then
        VMsFolder.ChildAdded:Connect(function(VM)
            if VM.Name=="IgnoreMe" then return end
            task.spawn(function()
                task.wait(0.3); if not VM or not VM.Parent then return end
                local Humanoid=VM:FindFirstChildOfClass("Humanoid"); if not Humanoid then return end
                Humanoid.AnimationPlayed:Connect(function(Track)
                    if not SETTINGS.ReloadBar then return end
                    local anim=Track and Track.Animation
                    if anim and anim.Name and anim.Name:lower():find("reload") then
                        local reloadDuration=2; local weaponName=VM.Name
                        local ok,Modules=pcall(function() return ReplicatedStorage:FindFirstChild("Modules") end)
                        if ok and Modules then
                            local ToolInfo=Modules:FindFirstChild("ToolInfo")
                            if ToolInfo then
                                local okR,ToolInfoM=pcall(require,ToolInfo)
                                if okR and ToolInfoM and ToolInfoM[weaponName] and ToolInfoM[weaponName].Weapon then
                                    reloadDuration=ToolInfoM[weaponName].Weapon.ReloadDuration or 2
                                end
                            end
                        end
                        StartReloadBar(reloadDuration)
                    end
                end)
            end)
        end)
    end
end

do
    local FCState={Active=false,SavedPosition=nil,SavedVelocity=nil}
    RunService.Heartbeat:Connect(function(dt)
        local Character=Client.Character; local Root=Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid=Character and Character:FindFirstChildOfClass("Humanoid")
        if not Root or not Humanoid or Humanoid.Health<=0 then
            if FCState.Active and Root and Humanoid then pcall(function() Root.Anchored=false; Humanoid.AutoRotate=true end) end
            FCState.Active=false; return
        end
        local kb=Flags["Freecam_Keybind"]; local keyOn=false
        if kb then keyOn=(kb.Toggled==true)or(kb.Active==true) end
        local isActive=SETTINGS.Freecam.Enabled and keyOn
        if isActive then
            if not FCState.Active then
                FCState.Active=true; FCState.SavedPosition=Root.CFrame; FCState.SavedVelocity=Root.Velocity
                pcall(_shp,Root,"NetworkIsSleeping",true)
            end
            local CLV=Camera.CFrame.LookVector; local NL=CLV
            local UpPos=Vector3.new(0,1,0); local DownPos=Vector3.new(0,-1,0); local NonePos=Vector3.new(0,0,0)
            local BaseCFrame=Root.CFrame
            local Up=UserInputService:IsKeyDown(Enum.KeyCode.E); local Down=UserInputService:IsKeyDown(Enum.KeyCode.Q)
            local Fwd=UserInputService:IsKeyDown(Enum.KeyCode.W); local Back=UserInputService:IsKeyDown(Enum.KeyCode.S)
            Root.Anchored=true; Root.Velocity=NonePos
            local Delta=dt*SETTINGS.Freecam.Speed*3
            local MoveVec=(Humanoid.MoveDirection+(Up and UpPos or NonePos)+(Down and DownPos or NonePos)+(Fwd and Vector3.new(0,NL.Y,0) or NonePos)+(Back and Vector3.new(0,-NL.Y,0) or NonePos))*Delta
            BaseCFrame=BaseCFrame+MoveVec
            local Position=BaseCFrame.p
            Root.CFrame=CFrame.new(Position,Position+Vector3.new(CLV.X,0,CLV.Z))
            Humanoid.AutoRotate=false
        else
            if FCState.Active then
                FCState.Active=false; Humanoid.AutoRotate=true
                pcall(_shp,Root,"NetworkIsSleeping",false)
                for _, p in ipairs(Character:GetChildren()) do if p:IsA("BasePart") then pcall(_shp,p,"NetworkIsSleeping",false) end end
                if FCState.SavedPosition then
                    Root.CFrame=FCState.SavedPosition; Root.Anchored=false
                    if FCState.SavedVelocity then Root.Velocity=FCState.SavedVelocity end
                    FCState.SavedPosition=nil; FCState.SavedVelocity=nil
                end
            end
        end
    end)
end

local ESP={}
local ScreenGui=CreateUndetectedGui("ESP")
local OUTLINE=1; local BOX_THICKNESS=2
local NAME_PADDING_X=6; local NAME_PADDING_Y=2

local visParams=RaycastParams.new(); visParams.FilterType=RAY_FILTER_EXCLUDE; visParams.IgnoreWater=true
local visCache={}
local function isCharVisible(char)
    if not char or not char.Parent then return false end
    local now=tick(); local cached=visCache[char]
    if cached and (now-cached.lastCheck)<0.05 then return cached.visible end
    local myChar=Client.Character
    local head=char:FindFirstChild("Head") or char:FindFirstChild("Head",true) or char:FindFirstChild("HumanoidRootPart",true)
    if not myChar or not head then visCache[char]={visible=false,lastCheck=now}; return false end
    local filter={myChar,Camera}
    local vfx=Workspace:FindFirstChild("VFX"); local walls=Workspace:FindFirstChild("RocketFactoryPinkCardInvisWalls")
    if vfx then table.insert(filter,vfx) end; if walls then table.insert(filter,walls) end
    visParams.FilterDescendantsInstances=filter
    local origin=Camera.CFrame.Position
    local result=Workspace:Raycast(origin,head.Position-origin,visParams)
    local visible=false
    if not result then visible=true
    else local inst=result.Instance; if inst and inst:IsDescendantOf(char) then visible=true end end
    visCache[char]={visible=visible,lastCheck=now}; return visible
end

local function BoxMath(item, boundType)
    if not item then return nil,nil,false end
    boundType = boundType or "Static"

    if boundType == "Dynamic" then
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local any = false
        for _, part in ipairs(item:GetChildren()) do
            if part:IsA("BasePart") then
                local name = part.Name
                if (name == "Head" or name:find("Torso") or name:find("Arm") or
                    name:find("Hand") or name:find("Leg") or name:find("Foot")) then
                    local cf = part.CFrame
                    local size = part.Size
                    local hx, hy, hz = size.X/2, size.Y/2, size.Z/2
                    local corners = {
                        Vector3.new(hx,hy,hz), Vector3.new(-hx,hy,hz),
                        Vector3.new(hx,-hy,hz), Vector3.new(-hx,-hy,hz),
                        Vector3.new(hx,hy,-hz), Vector3.new(-hx,hy,-hz),
                        Vector3.new(hx,-hy,-hz), Vector3.new(-hx,-hy,-hz),
                    }
                    for i = 1, 8 do
                        local sp = Project(cf * corners[i])
                        if sp then
                            minX = math.min(minX, sp.X)
                            minY = math.min(minY, sp.Y)
                            maxX = math.max(maxX, sp.X)
                            maxY = math.max(maxY, sp.Y)
                            any = true
                        end
                    end
                end
            end
        end
        if not any then return nil,nil,false end
        local w = math.floor(maxX - minX)
        local h = math.floor(maxY - minY)
        if w <= 0 or h <= 0 then return nil,nil,false end
        return Vector2.new(math.floor(minX), math.floor(minY)), Vector2.new(w, h), true
    end

    local Torso=item:FindFirstChild('HumanoidRootPart') or item:FindFirstChild('HumanoidRootPart',true) or item:FindFirstChild('UpperTorso') or item:FindFirstChild('Torso')
    if not Torso then return nil,nil,false end
    local cf=Torso.CFrame; local pos=Torso.Position
    local vTop=pos+(cf.UpVector*2); local vBottom=pos-(cf.UpVector*2.8)
    local top,tz,tv=Project(vTop); local bottom,bz,bv=Project(vBottom)
    if (not tv and not bv) or not top or not bottom then return nil,nil,false end
    local height=math.abs(bottom.Y-top.Y); if height<=0 then return nil,nil,false end
    local width=height/1.2
    return Vector2.new(math.floor((top.X+bottom.X)*0.5-width*0.5),math.min(top.Y,bottom.Y)),Vector2.new(width,height),true
end

local function createBox(parent,color)
    local box=Instance.new('Frame'); box.BackgroundTransparency=1; box.Parent=parent
    local sides={}
    for i=1,8 do local f=Instance.new('Frame'); f.BorderSizePixel=0; f.BackgroundColor3=color; f.Parent=box; sides[i]=f end
    return box,sides
end
local function newText()
    local t=Instance.new('TextLabel'); t.BackgroundTransparency=1; t.TextColor3=Color3.new(1,1,1)
    t.TextStrokeColor3=Color3.new(0,0,0); t.TextStrokeTransparency=0; t.FontFace=Library.Font; t.TextSize=11
    t.TextXAlignment=Enum.TextXAlignment.Center; t.TextYAlignment=Enum.TextYAlignment.Center; return t
end

local SKELETON_JOINTS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function createESP(char,name,classname)
    local holder=Instance.new('Frame'); holder.BackgroundTransparency=1; holder.Visible=false; holder.Parent=ScreenGui
    local nameText=newText(); nameText.Text=name; nameText.Parent=holder
    local boxGroup=Instance.new('Frame'); boxGroup.BackgroundTransparency=1; boxGroup.Parent=holder

    local outerBox,outerSides=createBox(boxGroup,Color3.new(0,0,0))
    local gradBox,gradSides=createBox(boxGroup,Color3.new(1,1,1))
    local innerBox,innerSides=createBox(boxGroup,Color3.new(0,0,0))

    local gradients={}
    for i=1,8 do local g=Instance.new('UIGradient'); g.Rotation=90; g.Parent=gradSides[i]; gradients[i]=g end

    local healthBack=Instance.new('Frame'); healthBack.BackgroundTransparency=1; healthBack.BorderSizePixel=0; healthBack.Parent=holder
    local healthOutline=Instance.new('Frame'); healthOutline.BackgroundColor3=Color3.new(0,0,0); healthOutline.BorderSizePixel=0; healthOutline.Parent=healthBack
    local healthInner=Instance.new('Frame'); healthInner.BackgroundColor3=Color3.fromRGB(35,35,35); healthInner.BorderSizePixel=0; healthInner.Parent=healthBack
    local healthFillHolder=Instance.new('Frame'); healthFillHolder.BackgroundTransparency=1; healthFillHolder.BorderSizePixel=0; healthFillHolder.ClipsDescendants=true; healthFillHolder.Parent=healthInner
    local healthFill=Instance.new('Frame'); healthFill.BorderSizePixel=0; healthFill.AnchorPoint=Vector2.new(0,1)
    healthFill.Position=UDim2.fromScale(0,1); healthFill.Size=UDim2.fromScale(1,1); healthFill.BackgroundColor3=Color3.new(1,1,1); healthFill.Parent=healthFillHolder
    local healthGradient=Instance.new('UIGradient'); healthGradient.Rotation=90; healthGradient.Parent=healthFill
    local distText=newText(); distText.Parent=holder
    local weaponText=newText(); weaponText.Text='[None]'; weaponText.Parent=holder

    local weaponIcon=Instance.new('ImageLabel')
    weaponIcon.BackgroundTransparency=1
    weaponIcon.Size=UDim2.fromOffset(24,24)
    weaponIcon.Visible=false
    weaponIcon.Parent=holder

    local skeleton = {}
    pcall(function()
        for i=1,#SKELETON_JOINTS do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Color = Color3.fromRGB(235,255,240)
            line.Visible = false
            skeleton[i] = line
        end
    end)

    local cham=Instance.new('Highlight'); cham.Parent=ScreenGui; cham.Adornee=char
    cham.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; cham.Enabled=false

    ESP[char]={
        Holder=holder,Name=nameText,BoxGroup=boxGroup,OuterBox=outerBox,OuterSides=outerSides,
        GradBox=gradBox,GradSides=gradSides,Gradients=gradients,InnerBox=innerBox,InnerSides=innerSides,
        HealthBack=healthBack,HealthOutline=healthOutline,HealthInner=healthInner,
        HealthFillHolder=healthFillHolder,HealthFill=healthFill,HealthGradient=healthGradient,
        Distance=distText,Weapon=weaponText,Class=classname,Cham=cham,
        Skeleton=skeleton, WeaponIcon=weaponIcon,
    }
end

local function sizeSides(sides,w,h,t,style)
    if style == "Corner" then
        local cw = math.clamp(w/3, 8, 25)
        local ch = math.clamp(h/4, 8, 25)
        sides[1].Position=UDim2.fromOffset(0,0); sides[1].Size=UDim2.fromOffset(cw,t)
        sides[2].Position=UDim2.fromOffset(0,0); sides[2].Size=UDim2.fromOffset(t,ch)
        sides[3].Position=UDim2.fromOffset(w-cw,0); sides[3].Size=UDim2.fromOffset(cw,t)
        sides[4].Position=UDim2.fromOffset(w-t,0); sides[4].Size=UDim2.fromOffset(t,ch)
        sides[5].Position=UDim2.fromOffset(0,h-t); sides[5].Size=UDim2.fromOffset(cw,t)
        sides[6].Position=UDim2.fromOffset(0,h-ch); sides[6].Size=UDim2.fromOffset(t,ch)
        sides[7].Position=UDim2.fromOffset(w-cw,h-t); sides[7].Size=UDim2.fromOffset(cw,t)
        sides[8].Position=UDim2.fromOffset(w-t,h-ch); sides[8].Size=UDim2.fromOffset(t,ch)
    else
        sides[1].Position=UDim2.fromOffset(0,0); sides[1].Size=UDim2.fromOffset(w,t)
        sides[2].Position=UDim2.fromOffset(0,0); sides[2].Size=UDim2.fromOffset(t,h)
        sides[3].Position=UDim2.fromOffset(0,0); sides[3].Size=UDim2.fromOffset(0,0)
        sides[4].Position=UDim2.fromOffset(w-t,0); sides[4].Size=UDim2.fromOffset(t,h)
        sides[5].Position=UDim2.fromOffset(0,h-t); sides[5].Size=UDim2.fromOffset(w,t)
        sides[6].Position=UDim2.fromOffset(0,0); sides[6].Size=UDim2.fromOffset(0,0)
        sides[7].Position=UDim2.fromOffset(0,0); sides[7].Size=UDim2.fromOffset(0,0)
        sides[8].Position=UDim2.fromOffset(0,0); sides[8].Size=UDim2.fromOffset(0,0)
    end
end

local function getGun(character)
    if not character then return "None" end
    for _, model in character:GetChildren() do
        if not model:IsA('Model') then continue end
        if model.Name=='Hair' or model.Name=='HolsterModel' then continue end
        if not model.PrimaryPart then continue end
        if model:FindFirstChild("Detail") or model:FindFirstChild("Main") or model:FindFirstChild("Handle") or model:FindFirstChild("Attachments") or model:FindFirstChild("ArrowAttach") or model:FindFirstChild("Attach") then
            return model.Name
        end
    end
    return "None"
end

RunService.RenderStepped:Connect(function()
    local camPos=Camera.CFrame.Position
    for char,e in pairs(ESP) do
        if e.Cham and e.Cham.Adornee ~= char then
            e.Cham:Destroy()
            e.Cham=Instance.new('Highlight'); e.Cham.Parent=ScreenGui; e.Cham.Adornee=char
            e.Cham.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; e.Cham.Enabled=false
        end

        local class=e.Class
        if not Flags[class.."ESPEnabled"] then
            e.Holder.Visible=false
            if e.Cham then e.Cham.Enabled=false end
            if e.Skeleton then for i=1,#e.Skeleton do e.Skeleton[i].Visible=false end end
            if e.WeaponIcon then e.WeaponIcon.Visible=false end
            continue
        end

        local isNPC=(class=="AI" or class=="Boss")
        local hum=char:FindFirstChildOfClass('Humanoid')

        if isNPC then
            local hrpCheck=char:FindFirstChild("HumanoidRootPart",true)
            if not hrpCheck or hrpCheck.Position.Y<-1000 or char:GetAttribute("Loaded")==false then
                e.Holder.Visible=false
                if e.Cham then e.Cham.Enabled=false end
                if e.Skeleton then for i=1,#e.Skeleton do e.Skeleton[i].Visible=false end end
                if e.WeaponIcon then e.WeaponIcon.Visible=false end
                continue
            end
        else
            if not hum or hum.Health<=0 then
                e.Holder.Visible=false
                if e.Cham then e.Cham.Enabled=false end
                if e.Skeleton then for i=1,#e.Skeleton do e.Skeleton[i].Visible=false end end
                if e.WeaponIcon then e.WeaponIcon.Visible=false end
                continue
            end
        end

        local boundType = SETTINGS.PlayersBoundingType or "Static"
        local pos,size,ok=BoxMath(char, boundType)
        if not ok then
            e.Holder.Visible=false
            if e.Cham then e.Cham.Enabled=false end
            if e.Skeleton then for i=1,#e.Skeleton do e.Skeleton[i].Visible=false end end
            if e.WeaponIcon then e.WeaponIcon.Visible=false end
            continue
        end

        local hrp=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart",true)
        local distance=hrp and (camPos-hrp.Position).Magnitude or 99999
        local maxD=SETTINGS[class.."MaxDist"] or 10000
        if distance>maxD then
            e.Holder.Visible=false
            if e.Cham then e.Cham.Enabled=false end
            if e.Skeleton then for i=1,#e.Skeleton do e.Skeleton[i].Visible=false end end
            if e.WeaponIcon then e.WeaponIcon.Visible=false end
            continue
        end

        local isVisible=true
        if Flags[class.."VisibleCheck"] then isVisible=isCharVisible(char) end
        local isManipTarget=(_G.scorpionManipTarget==char)
        local barW=4; local gap=4; local reservedLeft=barW+gap+OUTLINE

        e.Holder.Position=UDim2.fromOffset(pos.X-reservedLeft,pos.Y); e.Holder.Visible=true
        e.BoxGroup.Position=UDim2.fromOffset(reservedLeft,0); e.BoxGroup.Size=UDim2.fromOffset(size.X,size.Y)

        e.Name.Position=UDim2.fromOffset(reservedLeft-NAME_PADDING_X,-15-NAME_PADDING_Y)
        e.Name.Size=UDim2.fromOffset(size.X+NAME_PADDING_X*2,14+NAME_PADDING_Y*2)
        e.Name.Visible=Flags[class.."Names"] and true or false
        local nc=Flags[class.."NameColor"]; if nc then e.Name.TextColor3=nc.Color end

        local boxStyle = Flags[class.."BoxStyle"] or "Full"

        e.OuterBox.Position=UDim2.fromOffset(-OUTLINE,-OUTLINE); e.OuterBox.Size=UDim2.fromOffset(size.X+OUTLINE*2,size.Y+OUTLINE*2)
        sizeSides(e.OuterSides,size.X+OUTLINE*2,size.Y+OUTLINE*2,OUTLINE,boxStyle)

        e.GradBox.Position=UDim2.fromOffset(0,0); e.GradBox.Size=UDim2.fromOffset(size.X,size.Y)
        sizeSides(e.GradSides,size.X,size.Y,BOX_THICKNESS,boxStyle)

        e.InnerBox.Position=UDim2.fromOffset(OUTLINE,OUTLINE); e.InnerBox.Size=UDim2.fromOffset(size.X-OUTLINE*2,size.Y-OUTLINE*2)
        sizeSides(e.InnerSides,size.X-OUTLINE*2,size.Y-OUTLINE*2,OUTLINE,boxStyle)

        local on=Flags[class.."Boxes"]; e.OuterBox.Visible=on; e.GradBox.Visible=on; e.InnerBox.Visible=on

        if isManipTarget then
            local red=SETTINGS.ManipTargetColor or Color3.fromRGB(255,0,0)
            for _,g in ipairs(e.Gradients) do g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,red),ColorSequenceKeypoint.new(1,red)}) end
            for _,s in ipairs(e.GradSides) do s.BackgroundColor3=red end
        else
            local c1,c2
            if not isVisible then c1=Flags[class.."NotVisBoxColor1"]; c2=Flags[class.."NotVisBoxColor2"]
            else c1=Flags[class.."BoxColor1"]; c2=Flags[class.."BoxColor2"] end
            if c1 and c2 then
                for _,g in ipairs(e.Gradients) do g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c1.Color),ColorSequenceKeypoint.new(1,c2.Color)}) end
            end
        end

        e.HealthBack.Visible=Flags[class.."Health"] and true or false
        e.HealthBack.Position=UDim2.fromOffset(reservedLeft-barW-gap,0); e.HealthBack.Size=UDim2.fromOffset(barW,size.Y)
        e.HealthOutline.Position=UDim2.fromOffset(0,0); e.HealthOutline.Size=UDim2.fromOffset(barW,size.Y)
        e.HealthInner.Position=UDim2.fromOffset(1,1); e.HealthInner.Size=UDim2.fromOffset(barW-2,size.Y-2)
        e.HealthFillHolder.Position=UDim2.fromOffset(0,0); e.HealthFillHolder.Size=UDim2.fromScale(1,1)
        if hum then
            local hp=math.clamp(hum.Health/hum.MaxHealth,0,1); e.HealthFill.Size=UDim2.fromScale(1,hp)
        else
            local lH=char:GetAttribute("Health"); local lM=char:GetAttribute("MaxHealth")
            if lH and lM and lM>0 then e.HealthFill.Size=UDim2.fromScale(1,math.clamp(lH/lM,0,1))
            else e.HealthFill.Size=UDim2.fromScale(1,1) end
        end
        local h1=Flags[class.."HealthColor1"]; local h2=Flags[class.."HealthColor2"]; local h3=Flags[class.."HealthColor3"]
        if h1 and h2 and h3 then
            e.HealthGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,h1.Color),ColorSequenceKeypoint.new(0.5,h2.Color),ColorSequenceKeypoint.new(1,h3.Color)})
        end

        if Flags[class.."Chams"] then
            local cc1,cc2
            if isManipTarget then
                cc1={Color=SETTINGS.ManipTargetColor or Color3.fromRGB(255,0,0)}; cc2=cc1
            elseif not isVisible then
                cc1=Flags[class.."NotVisChamsColor1"]; cc2=Flags[class.."NotVisChamsColor2"]
            else
                cc1=Flags[class.."ChamsColor1"]; cc2=Flags[class.."ChamsColor2"]
            end
            if cc1 and cc2 then
                e.Cham.Enabled=true
                e.Cham.FillColor=cc1.Color
                e.Cham.OutlineColor=cc2.Color
            end
        else
            if e.Cham then e.Cham.Enabled=false end
        end

        if SETTINGS.PlayersSkeleton and e.Skeleton and #e.Skeleton>0 then
            local skelColor = SETTINGS.PlayersSkeletonColor or Color3.fromRGB(235,255,240)
            local skelDraw = (not Flags[class.."VisibleCheck"]) or isVisible
            if not skelDraw then
                for i = 1, #e.Skeleton do e.Skeleton[i].Visible = false end
            else
                for i = 1, #SKELETON_JOINTS do
                    local joint = SKELETON_JOINTS[i]
                    local partA = char:FindFirstChild(joint[1], true)
                    local partB = char:FindFirstChild(joint[2], true)
                    local line = e.Skeleton[i]
                    if partA and partB and line then
                        local spA,_,onA = Project(partA.Position + (joint[1]=="UpperTorso" and Vector3.new(0,0.4,0) or Vector3.zero))
                        local spB,_,onB = Project(partB.Position + (joint[2]=="UpperTorso" and Vector3.new(0,0.4,0) or Vector3.zero))
                        if spA and spB and (onA or onB) then
                            line.From = spA
                            line.To = spB
                            line.Color = skelColor
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    elseif line then
                        line.Visible = false
                    end
                end
            end
        elseif e.Skeleton then
            for i = 1, #e.Skeleton do e.Skeleton[i].Visible = false end
        end

        e.Distance.Position=UDim2.fromOffset(reservedLeft,size.Y+6); e.Distance.Size=UDim2.fromOffset(size.X,14)
        e.Distance.Visible=Flags[class.."Distance"] and true or false; e.Distance.Text=math.floor(distance)..' studs'
        local dc=Flags[class.."DistanceColor"]; if dc then e.Distance.TextColor3=dc.Color end

        local weaponName = isNPC and "Military AI" or getGun(char)
        e.Weapon.Position=UDim2.fromOffset(reservedLeft,size.Y+20); e.Weapon.Size=UDim2.fromOffset(size.X,14)
        e.Weapon.Visible=Flags[class.."Weapon"] and true or false
        e.Weapon.Text="["..weaponName.."]"
        local wc=Flags[class.."WeaponColor"]; if wc then e.Weapon.TextColor3=wc.Color end

        if SETTINGS.PlayersWeaponIcon and e.WeaponIcon then
            local iconUrl = GetWeaponIcon(weaponName)
            if iconUrl and iconUrl ~= "" and not isNPC then
                e.WeaponIcon.Image = iconUrl
                e.WeaponIcon.ImageColor3 = SETTINGS.PlayersWeaponIconColor or Color3.fromRGB(235,255,240)
                e.WeaponIcon.Position = UDim2.fromOffset(reservedLeft + size.X/2 - 12, size.Y + 34)
                e.WeaponIcon.Visible = true
            else
                e.WeaponIcon.Visible = false
            end
        elseif e.WeaponIcon then
            e.WeaponIcon.Visible = false
        end
    end
end)

local function hookPlayer(p)
    if p==Client then return end
    p.CharacterAdded:Connect(function(c) createESP(c,p.Name,'Players') end)
    p.CharacterRemoving:Connect(function(c)
        local e=ESP[c]
        if e then
            e.Holder:Destroy()
            if e.Cham then e.Cham:Destroy() end
            if e.Skeleton then for i=1,#e.Skeleton do pcall(function() e.Skeleton[i]:Remove() end) end end
            ESP[c]=nil
        end
        visCache[c]=nil
    end)
    if p.Character then createESP(p.Character,p.Name,'Players') end
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(p)
    if p.Character and ESP[p.Character] then
        local e=ESP[p.Character]
        e.Holder:Destroy()
        if e.Cham then e.Cham:Destroy() end
        if e.Skeleton then for i=1,#e.Skeleton do pcall(function() e.Skeleton[i]:Remove() end) end end
        ESP[p.Character]=nil
        visCache[p.Character]=nil
    end
end)

local SoldierClassType={Brutus="Boss",Bruno="Boss",BTR="Boss",Boris="Boss",Soldier="AI",MilitaryHitbox="AI"}
local Military=Workspace:FindFirstChild('Military'); local Events=Workspace:FindFirstChild('Events')
local function CacheSoldier(model)
    if not model or not model.Parent then return end
    local classType=SoldierClassType[model.Name]; if not classType then return end
    if ESP[model] then return end; createESP(model,model.Name,classType)
end
local function RemoveSoldier(s)
    local e=ESP[s]
    if e then
        e.Holder:Destroy()
        if e.Cham then e.Cham:Destroy() end
        if e.Skeleton then for i=1,#e.Skeleton do pcall(function() e.Skeleton[i]:Remove() end) end end
        ESP[s]=nil
    end
    visCache[s]=nil
end
if Military then
    for _, folder in ipairs(Military:GetChildren()) do
        for _, s in ipairs(folder:GetChildren()) do if s:IsA('Model') then CacheSoldier(s) end end
        folder.ChildAdded:Connect(function(s) task.wait(0.5); if s:IsA('Model') then CacheSoldier(s) end end)
        folder.ChildRemoved:Connect(RemoveSoldier)
    end
end
if Events then
    for _, obj in ipairs(Events:GetChildren()) do if obj.Name=='BTR' then CacheSoldier(obj) end end
    Events.ChildAdded:Connect(function(obj) task.wait(0.5); if obj.Name=='BTR' then CacheSoldier(obj) end end)
    Events.ChildRemoved:Connect(RemoveSoldier)
end
task.spawn(function()
    local animals=Workspace:WaitForChild("Animals",60); if not animals then return end
    local mv=animals:WaitForChild("MilitaryVisuals",60); if not mv then return end
    for _, m in ipairs(mv:GetChildren()) do if m:IsA("Model") then CacheSoldier(m) end end
    mv.ChildAdded:Connect(function(m) if m:IsA("Model") then CacheSoldier(m) end end)
    mv.ChildRemoved:Connect(RemoveSoldier)
end)

local miscCache={}
local Drops=Workspace:FindFirstChild('Drops'); local Plants=Workspace:FindFirstChild('Plants')
local Animals=Workspace:FindFirstChild('Animals'); local NodesFolder=Workspace:FindFirstChild('Nodes')
local NODE_FLAG_MAP={
    Stone="Stone",StoneNode="Stone",Stone_Node="Stone",["Stone Node"]="Stone",
    Metal="Metal",MetalNode="Metal",Metal_Node="Metal",["Metal Node"]="Metal",
    Iron="Metal",IronNode="Metal",Iron_Node="Metal",["Iron Node"]="Metal",
    IronOre="Metal",Iron_Ore="Metal",["Iron Ore"]="Metal",
    Phosphate="Phosphate",PhosphateNode="Phosphate",Phosphate_Node="Phosphate",["Phosphate Node"]="Phosphate",
    PhosphateOre="Phosphate",Phosphate_Ore="Phosphate",["Phosphate Ore"]="Phosphate",
}
local VALID_NODE_FLAGS={Stone=true,Metal=true,Phosphate=true}
local BASE_FLAG_MAP={
    ["Care Package"]="Care Package",CarePackage="Care Package",Care_Package="Care Package",
    ["Body Bag"]="Body Bag",BodyBag="Body Bag",Body_Bag="Body Bag",
    ["Salvaged Flycopter"]="Salvaged Flycopter",SalvagedFlycopter="Salvaged Flycopter",Salvaged_Flycopter="Salvaged Flycopter",Flycopter="Salvaged Flycopter",
    ["Auto Turret"]="Auto Turret",AutoTurret="Auto Turret",Auto_Turret="Auto Turret",
    ["Shotgun Turret"]="Shotgun Turret",ShotgunTurret="Shotgun Turret",Shotgun_Turret="Shotgun Turret",
    ["Timed Crate"]="Care Package",TimedCrate="Care Package",Sleeper="Body Bag",
}
local VALID_BASE_FLAGS={["Care Package"]=true,["Body Bag"]=true,["Salvaged Flycopter"]=true,["Auto Turret"]=true,["Shotgun Turret"]=true}
local function normalizeName(name) return name:gsub('%s+',''):gsub('_',''):lower() end
local BASE_FLAG_MAP_LOWER={}
for k,v in pairs(BASE_FLAG_MAP) do BASE_FLAG_MAP_LOWER[normalizeName(k)]=v end
local function getNodeFlag(node)
    if not node or not node.Name then return nil end
    if NODE_FLAG_MAP[node.Name] then return NODE_FLAG_MAP[node.Name] end
    local base=node.Name:gsub('_Node$',''):gsub('Node$',''):gsub('_Ore$',''):gsub('Ore$',''):gsub('%s+',''):gsub('_','')
    if NODE_FLAG_MAP[base] then return NODE_FLAG_MAP[base] end
    if VALID_NODE_FLAGS[base] then return base end; return nil
end
local function getBaseFlag(obj)
    if not obj or not obj.Name then return nil end
    if BASE_FLAG_MAP[obj.Name] then return BASE_FLAG_MAP[obj.Name] end
    local key=normalizeName(obj.Name); if BASE_FLAG_MAP_LOWER[key] then return BASE_FLAG_MAP_LOWER[key] end
    if VALID_BASE_FLAGS[obj.Name] then return obj.Name end; return nil
end
local function espify(obj,staticname,manualflag)
    if not obj or miscCache[obj] then return end
    local flag=manualflag or obj.Name:gsub('_Node$','')
    local label=Instance.new('TextLabel'); label.BackgroundTransparency=1; label.TextSize=12
    label.FontFace=Library.Font; label.TextColor3=Color3.new(1,1,1); label.AnchorPoint=Vector2.new(0.5,0.5)
    label.AutomaticSize=Enum.AutomaticSize.XY; label.Size=UDim2.fromOffset(0,0); label.Visible=false; label.Parent=ScreenGui
    local stroke=Instance.new('UIStroke'); stroke.Thickness=1; stroke.Color=Color3.new(0,0,0); stroke.Parent=label
    miscCache[obj]={obj=obj,label=label,stroke=stroke,flag=flag,staticname=staticname}
end
local function removeEsp(obj) local data=miscCache[obj]; if data then data.label:Destroy(); miscCache[obj]=nil end end
local function handleNode(node)
    if not node or miscCache[node] then return end
    if not node:IsA("Model") and not node:IsA("BasePart") then return end
    local flag=getNodeFlag(node); if not flag then return end
    local displayName=flag; if flag=="Metal" then displayName="Iron" end; espify(node,displayName,flag)
end
local function handleBaseObject(obj)
    if not obj or miscCache[obj] then return end; if not obj:IsA("Model") then return end
    local flag=getBaseFlag(obj); if not flag then return end; espify(obj,flag,flag)
end
if NodesFolder then
    for _, node in pairs(NodesFolder:GetChildren()) do handleNode(node) end
    for _, desc in pairs(NodesFolder:GetDescendants()) do if desc~=NodesFolder and (desc:IsA("Model") or desc:IsA("BasePart")) then handleNode(desc) end end
    NodesFolder.ChildAdded:Connect(function(node) task.wait(0.1); handleNode(node) end)
    NodesFolder.DescendantAdded:Connect(function(node) if node:IsA("Model") or node:IsA("BasePart") then task.wait(0.1); handleNode(node) end end)
    NodesFolder.ChildRemoved:Connect(removeEsp)
    NodesFolder.DescendantRemoving:Connect(function(d) if d:IsA("Model") or d:IsA("BasePart") then removeEsp(d) end end)
end
for _, obj in pairs(Workspace:GetChildren()) do
    if obj:IsA("Model") and (obj.Name:match('_Node$') or obj.Name:match('Node$')) then handleNode(obj) end
end
local Bases=Workspace:FindFirstChild("Bases")
if Bases then
    for _, obj in pairs(Bases:GetDescendants()) do handleBaseObject(obj) end
    Bases.DescendantAdded:Connect(function(obj) task.wait(0.3); handleBaseObject(obj) end)
    Bases.DescendantRemoving:Connect(function(obj) if obj:IsA("Model") then removeEsp(obj) end end)
end
if Drops and Plants then
    RunService.RenderStepped:Connect(function()
        if not Flags.MiscEnabledESP then return end
        for _, item in pairs(Drops:GetChildren()) do
            if item:IsA('Model') and not miscCache[item] then
                local distance=(Camera.CFrame.Position-item:GetPivot().Position).Magnitude
                if distance<=(SETTINGS.DropsMaxDist or 400) then espify(item,item.Name,'Drops') end
            end
        end
        for _, plant in pairs(Plants:GetChildren()) do
            if plant:IsA('Model') and not miscCache[plant] then
                local name=string.gsub(plant.Name,' Plant','')
                local distance=(Camera.CFrame.Position-plant:GetPivot().Position).Magnitude
                if name=='Wool' and distance<=(SETTINGS.WoolMaxDist or 400) then espify(plant,'Wool','Wool') end
            end
        end
    end)
end
if Animals then
    for _, animal in pairs(Animals:GetChildren()) do
        if animal:IsA('Model') and animal.Name~="MilitaryVisuals" then
            local name=animal.Name:lower():gsub('prefab_animal_',''):gsub('_',' '); espify(animal,name,'Animals')
        end
    end
    Animals.ChildAdded:Connect(function(animal)
        if animal:IsA('Model') and animal.Name~="MilitaryVisuals" then
            local name=animal.Name:lower():gsub('prefab_animal_',''):gsub('_',' '); espify(animal,name,'Animals')
        end
    end)
    Animals.ChildRemoved:Connect(removeEsp)
end
local lastTick=tick()
RunService.RenderStepped:Connect(function()
    local now=tick(); if now-lastTick<1/60 then return end; lastTick=now
    local miscEnabled=Flags.MiscEnabledESP; local camPos=Camera.CFrame.Position
    for obj,data in pairs(miscCache) do
        if not obj or not obj.Parent then data.label:Destroy(); miscCache[obj]=nil; continue end
        if not miscEnabled then data.label.Visible=false; continue end
        local toggleFlag=data.flag; local flagObj=Flags[toggleFlag..'Enabled']
        if flagObj==nil or flagObj==false then data.label.Visible=false; continue end
        local worldPos
        if obj:IsA('BasePart') then worldPos=obj.Position
        else local ok,pivot=pcall(function() return obj:GetPivot().Position end); if not ok then data.label.Visible=false; continue end; worldPos=pivot end
        local screenPos,_,onScreen=Project(worldPos)
        if not onScreen or not screenPos then data.label.Visible=false; continue end
        local dist=(camPos-worldPos).Magnitude
        if dist>(SETTINGS[data.flag.."MaxDist"] or 400) then data.label.Visible=false; continue end
        data.label.Visible=true; data.label.Position=UDim2.fromOffset(screenPos.X,screenPos.Y)
        data.label.Text=string.format('%s\n%.1f Studs',data.staticname or data.flag,dist)
        local col=Flags[data.flag..'Color']; if col then data.label.TextColor3=col.Color end
    end
end)

do
    local screenGui=CreateUndetectedGui("FovCircle")
    local fov=Instance.new("Frame"); fov.AnchorPoint=Vector2.new(0.5,0.5); fov.BackgroundTransparency=1; fov.ZIndex=5; fov.Parent=screenGui
    local fill=Instance.new("Frame"); fill.AnchorPoint=Vector2.new(0.5,0.5); fill.Position=UDim2.fromScale(0.5,0.5)
    fill.ZIndex=5; fill.Size=UDim2.new(1,0,1,0); fill.BackgroundColor3=Color3.new(1,1,1); fill.BackgroundTransparency=0.8; fill.Parent=fov
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local fillGrad=Instance.new("UIGradient",fill)
    local ring=Instance.new("Frame"); ring.AnchorPoint=Vector2.new(0.5,0.5); ring.BackgroundTransparency=1
    ring.Position=UDim2.fromScale(0.5,0.5); ring.Size=UDim2.new(1,0,1,0); ring.ZIndex=6; ring.Parent=fov
    local ringStroke=Instance.new("UIStroke",ring); ringStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    ringStroke.Thickness=2; ringStroke.Color=Color3.new(1,1,1)
    local ringGrad=Instance.new("UIGradient",ringStroke); Instance.new("UICorner",ring).CornerRadius=UDim.new(1,0)
    local rotOffset=0; local smoothPos=Vector2.new(0,0)
    RunService.RenderStepped:Connect(function(dt)
        if not SETTINGS.SilentAim.FovCircle then fov.Visible=false; return end
        fov.Visible=true; fov.Size=UDim2.fromOffset(SETTINGS.SilentAim.FovCircleSize,SETTINGS.SilentAim.FovCircleSize)
        ringStroke.Thickness=SETTINGS.SilentAim.FovThickness or 2
        fill.Visible=SETTINGS.SilentAim.FovFill and true or false
        fill.BackgroundTransparency=SETTINGS.SilentAim.FovFillTransparency or 0.8
        local viewport=Camera.ViewportSize; local targetPos=Vector2.new(viewport.X/2,viewport.Y/2)
        smoothPos=smoothPos:Lerp(targetPos,math.clamp(dt*12,0,1)); fov.Position=UDim2.fromOffset(smoothPos.X,smoothPos.Y)
        if SETTINGS.SilentAim.FovRotate then rotOffset=(rotOffset+SETTINGS.SilentAim.FovRotateSpeed*dt*60)%360
        else rotOffset=SETTINGS.SilentAim.FovGradientRotation%360 end
        ringGrad.Rotation=rotOffset; fillGrad.Rotation=rotOffset
        if SETTINGS.SilentAim.FovRainbow then
            local t=tick()*0.25*SETTINGS.SilentAim.FovRainbowSpeed; local seq={}
            for i=0,1,0.1 do seq[#seq+1]=ColorSequenceKeypoint.new(i,Color3.fromHSV(((t%1)+i*0.33)%1,1,1)) end
            local rs=ColorSequence.new(seq); ringGrad.Color=rs; fillGrad.Color=rs
        else
            local c1=SETTINGS.SilentAim.FovColor or Color3.fromRGB(50,220,110)
            local c2=SETTINGS.SilentAim.FovColor2 or Color3.fromRGB(255,255,255)
            local seq=ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c2)})
            ringGrad.Color=seq; fillGrad.Color=seq
        end
    end)
end

do
    local Modules=ReplicatedStorage:WaitForChild("Modules",15); if not Modules then return end
    local VFXModule=Modules:FindFirstChild("VFXModule")
    if VFXModule then local ok,m=pcall(require,VFXModule); if ok then VFXModule=m end end
    local ToolInfo=Modules:FindFirstChild("ToolInfo")
    if ToolInfo then local ok,m=pcall(require,ToolInfo); if ok then ToolInfo=m end end
    local ItemsModule=Modules:FindFirstChild("Items")
    if ItemsModule then local ok,m=pcall(require,ItemsModule); if ok then ItemsModule=m end end
    if not VFXModule or not VFXModule.CreateProjectile then return end

    local ClientCharacter=Client.Character or Client.CharacterAdded:Wait()
    Client.CharacterAdded:Connect(function(char) ClientCharacter=char end)

    local RayParams=RaycastParams.new(); RayParams.FilterType=RAY_FILTER_EXCLUDE; RayParams.IgnoreWater=true
    RayParams.FilterDescendantsInstances={Camera,ClientCharacter}

    local IsPartVisible=function(Part,Origin)
        if not Part then return false end
        local Head=ClientCharacter and ClientCharacter:FindFirstChild("Head"); if not Head then return false end
        Origin=Origin or Head.CFrame.Position
        local result=Workspace:Raycast(Origin,Part.CFrame.Position-Origin,RayParams)
        if not result then return true end
        return result.Instance and result.Instance:IsDescendantOf(Part.Parent) or false
    end

    local ManipOffsets={
        Vector3.new(0.5,0,0),Vector3.new(-0.5,0,0),Vector3.new(1,0,0),Vector3.new(-1,0,0),
        Vector3.new(1.5,0,0),Vector3.new(-1.5,0,0),Vector3.new(2,0,0),Vector3.new(-2,0,0),
        Vector3.new(2.5,0,0),Vector3.new(-2.5,0,0),Vector3.new(3,0,0),Vector3.new(-3,0,0),
        Vector3.new(3.5,0,0),Vector3.new(-3.5,0,0),Vector3.new(4,0,0),Vector3.new(-4,0,0),
        Vector3.new(0.5,0.5,0),Vector3.new(-0.5,0.5,0),Vector3.new(1,0.5,0),Vector3.new(-1,0.5,0),
        Vector3.new(1,1,0),Vector3.new(-1,1,0),Vector3.new(1.5,1,0),Vector3.new(-1.5,1,0),
        Vector3.new(2,1,0),Vector3.new(-2,1,0),Vector3.new(2,1.5,0),Vector3.new(-2,1.5,0),
        Vector3.new(0,1,0),Vector3.new(0,1.5,0),Vector3.new(0,2,0),
        Vector3.new(0.5,2,0),Vector3.new(-0.5,2,0),Vector3.new(1,2,0),Vector3.new(-1,2,0),
        Vector3.new(0,2.5,0),Vector3.new(0,3,0),Vector3.new(0.5,3,0),Vector3.new(-0.5,3,0),
        Vector3.new(0,3.5,0),Vector3.new(0,4,0),
        Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(0.5,0,1),Vector3.new(-0.5,0,1),
        Vector3.new(1,0,1),Vector3.new(-1,0,1),Vector3.new(0,1,1),Vector3.new(0,1,-1),Vector3.new(0,2,1),
    }

    local IsCandidateReachable=function(originPos,candidatePos)
        if not(originPos and candidatePos) then return false end
        local dir=candidatePos-originPos; if dir.Magnitude<0.05 then return true end
        local result=Workspace:Raycast(originPos,dir,RayParams); if not result then return true end
        if result.Instance and ClientCharacter and result.Instance:IsDescendantOf(ClientCharacter) then return true end
        return false
    end
    local IsManipPathClear=function(originPos,targetPart)
        if not(originPos and targetPart) then return false end
        local to=targetPart.CFrame.Position; local result=Workspace:Raycast(originPos,to-originPos,RayParams)
        if not result then return true end
        return result.Instance and result.Instance:IsDescendantOf(targetPart.Parent) or false
    end
    local FindVisiblePosition=function(Origin,Destination)
        local o=(typeof(Origin)=="CFrame") and Origin or CFrame.new(Origin); local oPos=o.Position
        local maxDist=SETTINGS.SilentAim.ManipulationDistance or 10
        for i=1,#ManipOffsets do
            local off=ManipOffsets[i]
            if off.Magnitude<=maxDist then
                local pos=o*off
                if IsCandidateReachable(oPos,pos) and IsManipPathClear(pos,Destination) then return pos end
            end
        end
        return nil
    end

    local GetGun=function(character)
        if not character then return "None" end
        for _, model in ipairs(character:GetChildren()) do
            if not model:IsA("Model") then continue end
            if model.Name=="Hair" or model.Name=="HolsterModel" then continue end
            if not model.PrimaryPart then continue end
            if model:FindFirstChild("Detail") or model:FindFirstChild("Main") or model:FindFirstChild("Handle") or model:FindFirstChild("Attachments") or model:FindFirstChild("ArrowAttach") or model:FindFirstChild("Attach") then return model.Name end
        end
        return "None"
    end

    local ClanShared
    pcall(function()
        if Client:FindFirstChild("PlayerScripts") and Client.PlayerScripts:FindFirstChild("ClanController") then
            local env=_senv(Client.PlayerScripts.ClanController); ClanShared=env and env.shared
        end
    end)
    local IsTeam=function(player)
        if typeof(player)~="Instance" or not player:IsA("Player") then return false end
        local cache=ClanShared and ClanShared.cachedTeamModels
        return cache and cache[player.UserId] or false
    end

    local Targeting={TargetPart=nil,TargetCharacter=nil,TargetObject=nil,ManipulatedPosition=nil,Targets={}}
    local GetDistanceFromCenter=function(part)
        local position=part; if typeof(part)=="Instance" then position=part.CFrame.Position end
        local sp,on=Project(position); if not on or not sp then return math.huge end
        local c=Vector2.new(Camera.ViewportSize.X*0.5,Camera.ViewportSize.Y*0.5); return(c-sp).Magnitude
    end

    local RegisterPlayer=function(Player)
        if Player==Client then return end
        Targeting.Targets[Player]={Class="Player",Player=Player,Character=Player.Character,LastUpdate=0,LastManip=0,LastManipCFG=nil,Root=nil,CoreInformation={Visible=false,OnScreen=false,Root=nil}}
    end
    for _, p in ipairs(Players:GetPlayers()) do RegisterPlayer(p) end
    Players.PlayerAdded:Connect(RegisterPlayer)
    Players.PlayerRemoving:Connect(function(p) Targeting.Targets[p]=nil end)

    local SoldierClassTypeLocal={Brutus="Boss",Bruno="Boss",BTR="Boss",Boris="Boss",Soldier="AI",MilitaryHitbox="AI"}
    local RegisterSoldier=function(Soldier)
        if not Soldier or not Soldier.Parent then return end
        local classType=SoldierClassTypeLocal[Soldier.Name]; if not classType then return end
        if Targeting.Targets[Soldier] then return end
        Targeting.Targets[Soldier]={Class=classType,Player=Soldier,Character=Soldier,LastUpdate=0,LastManip=0,LastManipCFG=nil,Root=nil,CoreInformation={Visible=false,OnScreen=false,Root=nil}}
    end
    for _, folderName in ipairs({"Military","Events"}) do
        local root=Workspace:FindFirstChild(folderName)
        if root then
            for _, Folder in ipairs(root:GetChildren()) do
                for _, s in ipairs(Folder:GetChildren()) do if s:IsA("Model") then RegisterSoldier(s) end end
                Folder.ChildAdded:Connect(function(s) task.wait(0.5); if s:IsA("Model") then RegisterSoldier(s) end end)
            end
        end
    end
    task.spawn(function()
        local animals=Workspace:WaitForChild("Animals",60); if not animals then return end
        local mv=animals:WaitForChild("MilitaryVisuals",60); if not mv then return end
        for _, m in ipairs(mv:GetChildren()) do if m:IsA("Model") then RegisterSoldier(m) end end
        mv.ChildAdded:Connect(function(m) if m:IsA("Model") then RegisterSoldier(m) end end)
        mv.ChildRemoved:Connect(function(m) Targeting.Targets[m]=nil end)
    end)

    local RandomGen=Random.new()
    RunService.Heartbeat:Connect(function()
        RayParams.FilterDescendantsInstances={Camera,ClientCharacter,Workspace:FindFirstChild("VFX"),Workspace:FindFirstChild("RocketFactoryPinkCardInvisWalls")}
        local TargetParts={}
        if SETTINGS.SilentAim.TargetHead then table.insert(TargetParts,"Head") end
        if SETTINGS.SilentAim.TargetBody then table.insert(TargetParts,"HumanoidRootPart"); table.insert(TargetParts,"UpperTorso"); table.insert(TargetParts,"LowerTorso") end
        if #TargetParts==0 then return end
        local DesiredPart=TargetParts[math.random(#TargetParts)] or "Head"
        local ManipActive=SETTINGS.SilentAim.Manipulation
        if Flags["SA_ManipKey"] then local kb=Flags["SA_ManipKey"]; ManipActive=ManipActive and((kb.Toggled==true)or(kb.Active==true)) end
        local UseVisible=SETTINGS.SilentAim.VisibleCheck; local DownCheck=SETTINGS.SilentAim.DownCheck
        local ClosestDistance=SETTINGS.SilentAim.FovSize or 200
        local ClosestTarget,EntityCharacter,EntityData=nil,nil,nil
        local Manipulated,Visible,ManipulatedPosition,ManipulatedPart=false,false,nil,nil
        local now=tick()
        for Entity,Object in next,Targeting.Targets do
            if not Object then continue end
            if not Object.Character or not Object.Character.Parent then
                Object.Character=(Object.Class=="Player" and Object.Player.Character) or nil
            end
            local character=Object.Character; if not character or not character.Parent then Object.CoreInformation={Visible=false,OnScreen=false,Root=nil}; continue end
            local isNPCObj=(Object.Class=="AI" or Object.Class=="Boss")
            if isNPCObj then
                local hrpCheck=character:FindFirstChild("HumanoidRootPart",true)
                if not hrpCheck or hrpCheck.Position.Y<-1000 then Object.CoreInformation={Visible=false,OnScreen=false,Root=nil}; continue end
                if character:GetAttribute("Loaded")==false then Object.CoreInformation={Visible=false,OnScreen=false,Root=nil}; continue end
            end
            if now-(Object.LastUpdate or 0)>1/30 then
                Object.LastUpdate=now
                local H=character:FindFirstChildOfClass("Humanoid")
                Object.Root=(H and H.RootPart) or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("HumanoidRootPart",true) or character:FindFirstChild("RootPart")
                local root=Object.Root
                if not root then Object.CoreInformation={Visible=false,OnScreen=false,Root=nil}
                elseif(Camera.CFrame.Position-root.Position).Magnitude>3000 then Object.CoreInformation={Visible=false,OnScreen=false,Root=root}
                else
                    local _,_,on=Project(root.Position)
                    local head=character:FindFirstChild("Head") or character:FindFirstChild("Head",true)
                    local vis=head and IsPartVisible(head) or false
                    Object.CoreInformation={Root=root,RootPosition=root.Position,OnScreen=on,Visible=vis,VisiblePart=vis and head or nil}
                end
            end
            local Core=Object.CoreInformation
            if not SETTINGS.SilentAim.TargetTeammates and IsTeam(Entity) then continue end
            if not(Core and Core.Root and Entity~=Client) then continue end
            if not(Core.OnScreen and SETTINGS.SilentAim.Enabled) then continue end
            local humanoid=character:FindFirstChildOfClass("Humanoid")
            if not isNPCObj then
                if not humanoid or humanoid.Health<=0 then continue end
                if DownCheck and humanoid:GetAttribute("Downed") then continue end
            end
            local Distance=GetDistanceFromCenter(Core.Root); if Distance>=ClosestDistance then continue end
            local tpart
            if isNPCObj then tpart=character:FindFirstChild(DesiredPart,true) or character:FindFirstChild("HumanoidRootPart",true)
            else
                if UseVisible and Core.Visible then tpart=Core.VisiblePart
                elseif not UseVisible then tpart=character:FindFirstChild(DesiredPart) end
            end
            if character.Name=="BTR" then tpart=character:FindFirstChild("HumanoidRootPart",true) end
            if tpart then ClosestDistance=Distance; ClosestTarget,EntityCharacter,EntityData=tpart,character,Object; Visible=Core.Visible end
        end
        if not Visible and ClientCharacter and ClientCharacter:FindFirstChild("Head") and ClosestTarget and EntityData then
            if now-(EntityData.LastManip or 0)>0.1 then
                EntityData.LastManip=now
                if ManipActive then
                    local vp=FindVisiblePosition(ClientCharacter.Head.CFrame,ClosestTarget)
                    if vp then Manipulated=true; ManipulatedPart=ClosestTarget; ManipulatedPosition=vp end
                end
                EntityData.LastManipCFG={Manipulated=Manipulated,ManipulatedPosition=ManipulatedPosition,ManipulatedPart=ManipulatedPart}
            elseif EntityData.LastManipCFG then
                Manipulated=EntityData.LastManipCFG.Manipulated
                ManipulatedPosition=EntityData.LastManipCFG.ManipulatedPosition
                ManipulatedPart=EntityData.LastManipCFG.ManipulatedPart
            end
        end
        Targeting.TargetPart=ClosestTarget; Targeting.TargetCharacter=EntityCharacter; Targeting.TargetObject=EntityData
        Targeting.ManipulatedPosition=Manipulated and ManipulatedPosition or nil
        if Manipulated and EntityCharacter then _G.scorpionManipTarget=EntityCharacter else _G.scorpionManipTarget=nil end
        if Flags["SA_ManipIndicator"] then
            ManipIndicator.TextColor3=SETTINGS.SilentAim.ManipulationIndicatorColor or Color3.fromRGB(255,0,0)
            ManipIndicator.Visible=Manipulated and SETTINGS.SilentAim.ManipulationIndicator or false
        else ManipIndicator.Visible=false end
    end)

    _G.scorpionTargeting=Targeting

    local ShouldHit=false
    local __S=getgenv().__SCORP
    local OriginalCreateProjectile=(__S and (__S.hooks.CreateProjectile or __S.real.CreateProjectile)) or VFXModule.CreateProjectile
    __S.hooks.CreateProjectile=function(self,...)
        local Args={...}
        local Traceback=_dbg.tb()
        if Traceback:find("ViewmodelController") and Args[1].StepFunction~="FakeStepFunc" and Args[1].HitFunction~="FakeHitFunc" and not tostring(Args[1].HitFunction):find("Ignore") then
            if SETTINGS.ShootSound.Enabled then PlayShootsound("Minecraft Bow") end
            ShouldHit=((math.floor(RandomGen:NextNumber(0,1)*100)/100)<=(SETTINGS.SilentAim.HitChance/100))
            local stacklevel=(_ilv and _ilv(3)) and 3 or ((_ilv and _ilv(2)) and 2 or nil)
            if stacklevel and Targeting.TargetPart and ClientCharacter then
                local targetPos=Targeting.TargetPart.Position
                local gun=GetGun(ClientCharacter); local oldspeed=Args[1].Speed or 500
                if gun and ToolInfo and ToolInfo[gun] and ToolInfo[gun].Bullet and ClientCharacter:FindFirstChild("InventoryController") and ClientCharacter:FindFirstChild("ViewmodelController") then
                    pcall(function()
                        local fetch=ClientCharacter.InventoryController.Fetch:Invoke()
                        if fetch and fetch.Toolbar then
                            local equipped=ClientCharacter.ViewmodelController:GetAttribute("Equipped")
                            local tool=equipped and fetch.Toolbar[equipped]
                            if tool and tool.Ammo and ItemsModule[tool.Ammo.ID] then
                                local ammo=ItemsModule[tool.Ammo.ID]
                                if ammo and ammo.AmmoStats then oldspeed=ToolInfo[gun].Bullet.Speed*(ammo.AmmoStats.SpeedMult or 1) end
                            end
                        end
                    end)
                end
                local Speed=oldspeed; local Gravity=Args[1].Gravity or 1; local Distance=(Camera.CFrame.Position-targetPos).Magnitude
                local TimeToHit=Distance/Speed; local G=Gravity*-196.2; local Drop=-0.5*G*TimeToHit*TimeToHit
                if tostring(Drop):find("nan") then Drop=0 end
                local PredictionOffset=Vector3.new(0,Drop,0)
                local Stack=debug.getstack(stacklevel)
                local CameraIndex,HRPIndex,FlashIndex,MouseIndex,CameraValue,HRPValue,FlashValue,MouseValue
                for i=1,100 do
                    local v=rawget(Stack,i)
                    if v then
                        local t=typeof(v)
                        if t=="CFrame" and not CameraValue then local ok,p=pcall(function() return v.p end); if ok and typeof(p)=="Vector3" then CameraValue=v; CameraIndex=i end
                        elseif t=="CFrame" and CameraValue and not HRPValue and v~=CameraValue then local ok,p=pcall(function() return v.p end); if ok and typeof(p)=="Vector3" then HRPValue=v; HRPIndex=i end
                        elseif t=="Vector3" and not FlashValue then FlashValue=v; FlashIndex=i
                        elseif t=="Vector3" and FlashValue and v~=FlashValue and not MouseValue then MouseValue=v; MouseIndex=i end
                    end
                end
                local manipPos=Targeting.ManipulatedPosition
                if CameraValue and HRPValue and FlashValue and MouseValue and PredictionOffset then
                    local finalTarget=targetPos+PredictionOffset; local camPos2=CameraValue.p; local hrpPos=HRPValue.p
                    local newFlash=CFrame.new(FlashValue,finalTarget).p
                    if manipPos then
                        local offC=camPos2-FlashValue; local offH=hrpPos-FlashValue
                        CameraValue=CFrame.new(manipPos+offC,finalTarget); HRPValue=CFrame.new(manipPos+offH,finalTarget); newFlash=manipPos
                    else CameraValue=CFrame.new(camPos2,finalTarget); HRPValue=CFrame.new(hrpPos,finalTarget) end
                    debug.setstack(stacklevel,CameraIndex,CameraValue); debug.setstack(stacklevel,HRPIndex,HRPValue)
                    debug.setstack(stacklevel,FlashIndex,newFlash); debug.setstack(stacklevel,MouseIndex,finalTarget)
                end
            end
            if Args[1]["Terminate"] then Args[1]["Terminate"]=nil end
            if Targeting.TargetPart and ShouldHit then
                local p=Targeting.TargetPart; local hit=p and p.Position
                if hit then
                    local origin=Args[1].Position; local dir=(hit-origin).Unit; local cp=CFrame.new(origin,hit).Position
                    if Targeting.ManipulatedPosition then
                        local mp=Targeting.ManipulatedPosition; dir=(hit-mp).Unit; cp=CFrame.new(mp,hit).p
                    end
                    Args[1].Position=cp; if Args[1].PositionFirst then Args[1].PositionFirst=cp end
                    Args[1].DirectionFirst=dir; Args[1].Direction=dir
                end
            end
        end
        return OriginalCreateProjectile(self,unpack(Args))
    end
end

do
    local Modules = ReplicatedStorage:FindFirstChild('Modules') or ReplicatedStorage:WaitForChild('Modules', 10)
    local ItemsModule
    if Modules then
        local ok, m = pcall(require, Modules:WaitForChild('Items', 5))
        if ok then ItemsModule = m end
    end
    if not ItemsModule then return end
    local GunTable = {}
    for _, gun in next, ItemsModule do
        if typeof(gun.Image) == 'table' then GunTable[gun.Name] = gun.Image
        else GunTable[gun.Name] = {['Default'] = gun.Image} end
    end
    local function GetArmor(Character)
        local result, seen = {}, {}
        if not Character or type(Character) == 'string' then return result end
        for _, child in Character:GetChildren() do
            local armorNumber, skinName = child.Name:match('Armor_(%d+)/(.*)')
            if not armorNumber then continue end
            local key = tonumber(armorNumber)
            if not key then continue end
            local item = ItemsModule[key]
            if not item or item.Type ~= 'Armor' then continue end
            if table.find(seen, item.Name) then continue end
            local image = ''
            if type(item.Image) == 'table' then
                if skinName and item.Image[skinName] then image = item.Image[skinName]
                elseif item.Image.Default then image = item.Image.Default end
            elseif type(item.Image) == 'string' then image = item.Image end
            local id = string.match(image or '', '%d+')
            table.insert(seen, item.Name)
            table.insert(result, {Skin = skinName, Name = item.Name, Type = item.ArmorType, Image = id})
        end
        return result
    end
    local COLORS = {
        PanelBg = Color3.fromRGB(15, 15, 15), PanelStroke = Color3.fromRGB(35, 90, 55),
        Title = Color3.fromRGB(235, 255, 240), ItemText = Color3.fromRGB(235, 255, 240),
        RowBg = Color3.fromRGB(20, 20, 20), RowStroke = Color3.fromRGB(35, 35, 35),
        SubText = Color3.fromRGB(150, 215, 170), AvatarBg = Color3.fromRGB(25, 25, 25),
    }
    local ArmorGui = CreateUndetectedGui("ArmorViewer")
    local panel = Instance.new('Frame')
    panel.AnchorPoint = Vector2.new(1, 0.5)
    panel.Position = UDim2.new(1, -20, 0.5, 0)
    panel.Size = UDim2.fromOffset(240, 130)
    panel.BackgroundColor3 = COLORS.PanelBg
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = ArmorGui
    Instance.new('UICorner', panel).CornerRadius = UDim.new(0, 4)
    local panelStroke = Instance.new('UIStroke', panel)
    panelStroke.Color = COLORS.PanelStroke
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.35

    local profile = Instance.new('Frame', panel)
    profile.BackgroundTransparency = 1
    profile.Position = UDim2.fromOffset(10, 10)
    profile.Size = UDim2.new(1, -20, 0, 52)
    profile.ZIndex = 3

    local avatarFrame = Instance.new('Frame', profile)
    avatarFrame.BackgroundColor3 = COLORS.AvatarBg
    avatarFrame.Size = UDim2.fromOffset(52, 52)
    avatarFrame.BorderSizePixel = 0
    avatarFrame.ZIndex = 3
    Instance.new('UICorner', avatarFrame).CornerRadius = UDim.new(0, 4)
    local avatarStroke = Instance.new('UIStroke', avatarFrame)
    avatarStroke.Color = COLORS.PanelStroke
    avatarStroke.Thickness = 1
    avatarStroke.Transparency = 0.35

    local avatarImg = Instance.new('ImageLabel', avatarFrame)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Size = UDim2.fromScale(1, 1)
    avatarImg.Image = ''
    avatarImg.ZIndex = 4
    Instance.new('UICorner', avatarImg).CornerRadius = UDim.new(0, 4)

    local avatarInitial = Instance.new('TextLabel', avatarFrame)
    avatarInitial.BackgroundTransparency = 1
    avatarInitial.Size = UDim2.fromScale(1, 1)
    avatarInitial.FontFace = Library.Font
    avatarInitial.TextSize = 20
    avatarInitial.TextColor3 = COLORS.SubText
    avatarInitial.Text = '?'
    avatarInitial.ZIndex = 4

    local nameLabel = Instance.new('TextLabel', profile)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.fromOffset(62, 2)
    nameLabel.Size = UDim2.new(1, -62, 0, 24)
    nameLabel.FontFace = Library.Font
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = COLORS.Title
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Top
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Text = 'Target'
    nameLabel.ZIndex = 3

    local subtitleLabel = Instance.new('TextLabel', profile)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Position = UDim2.fromOffset(62, 26)
    subtitleLabel.Size = UDim2.new(1, -62, 0, 16)
    subtitleLabel.FontFace = Library.Font
    subtitleLabel.TextSize = 11
    subtitleLabel.TextColor3 = COLORS.SubText
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextYAlignment = Enum.TextYAlignment.Top
    subtitleLabel.Text = 'Inventory'
    subtitleLabel.ZIndex = 3

    local dragBar = Instance.new('Frame', panel)
    dragBar.BackgroundTransparency = 1
    dragBar.Position = UDim2.new(0, 0, 0, 0)
    dragBar.Size = UDim2.new(1, 0, 0, 72)
    dragBar.ZIndex = 10

    local list = Instance.new('Frame', panel)
    list.BackgroundTransparency = 1
    list.Position = UDim2.fromOffset(10, 72)
    list.Size = UDim2.new(1, -20, 1, -82)
    local layout = Instance.new('UIListLayout', list)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    MakeDraggable(panel, dragBar, ArmorGui)

    local function ClearList()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA('Frame') then c:Destroy() end
        end
    end
    local function AddItem(name, imageUrl)
        local row = Instance.new('Frame')
        row.BackgroundColor3 = COLORS.RowBg
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, 0, 0, 26)
        row.Parent = list
        Instance.new('UICorner', row).CornerRadius = UDim.new(0, 3)
        local rowStroke = Instance.new('UIStroke', row)
        rowStroke.Color = COLORS.RowStroke
        rowStroke.Thickness = 1
        local textX = 8
        if imageUrl and imageUrl ~= '' then
            local img = Instance.new('ImageLabel', row)
            img.BackgroundTransparency = 1
            img.Position = UDim2.fromOffset(6, 4)
            img.Size = UDim2.fromOffset(18, 18)
            img.Image = imageUrl
            textX = 30
        end
        local txt = Instance.new('TextLabel', row)
        txt.BackgroundTransparency = 1
        txt.Position = UDim2.fromOffset(textX, 0)
        txt.Size = UDim2.new(1, -textX - 4, 1, 0)
        txt.FontFace = Library.Font
        txt.TextSize = 12
        txt.TextColor3 = COLORS.ItemText
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextTruncate = Enum.TextTruncate.AtEnd
        txt.Text = name
    end
    local function ResizePanel()
        local count = 0
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA('Frame') then count += 1 end
        end
        panel.Size = UDim2.fromOffset(240, 72 + math.max(count, 1) * 30 + 10)
    end

    local lastProfileTarget = nil
    local function UpdateProfile(target, targetObj)
        local player = Players:GetPlayerFromCharacter(target)
        local classType = (targetObj and targetObj.Class) or (player and "Player") or "NPC"
        if player then
            nameLabel.Text = player.DisplayName
            subtitleLabel.Text = "@" .. player.Name .. " · " .. classType
            avatarInitial.Visible = false
            avatarImg.Visible = true
            avatarImg.Image = ''
            ApplyAvatar(avatarImg, player.UserId)
        else
            nameLabel.Text = target.Name
            subtitleLabel.Text = classType .. " · Inventory"
            avatarImg.Image = ''
            avatarImg.Visible = false
            avatarInitial.Visible = true
            local ch = target.Name:sub(1,1):upper()
            avatarInitial.Text = (ch ~= '' and ch) or '?'
        end
    end

    local lastHash = ""
    RunService.RenderStepped:Connect(function()
        if not SETTINGS.ArmorViewer.Enabled then panel.Visible = false; lastProfileTarget = nil; return end
        local Targeting = _G.scorpionTargeting
        local target = Targeting and Targeting.TargetCharacter
        if not target or not target.Parent then panel.Visible = false; lastHash = ""; lastProfileTarget = nil; return end
        local root = target:FindFirstChild('HumanoidRootPart') or target:FindFirstChild('UpperTorso')
        if root then
            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            if dist > SETTINGS.ArmorViewer.MaxDistance then panel.Visible = false; return end
        end
        if target ~= lastProfileTarget then
            lastProfileTarget = target
            UpdateProfile(target, Targeting.TargetObject)
            lastHash = ""
        end
        local armorData = GetArmor(target)
        local hash = HttpService:JSONEncode(armorData) .. target.Name
        if hash ~= lastHash then
            lastHash = hash
            ClearList()
            for _, armor in ipairs(armorData) do
                local imageUrl = ''
                if armor.Image and tonumber(armor.Image) then imageUrl = 'rbxassetid://' .. tostring(armor.Image)
                elseif armor.Skin and GunTable[armor.Name] and GunTable[armor.Name][armor.Skin] then imageUrl = GunTable[armor.Name][armor.Skin]
                elseif GunTable[armor.Name] and GunTable[armor.Name]['Default'] then imageUrl = GunTable[armor.Name]['Default'] end
                AddItem(armor.Name, imageUrl)
            end
            ResizePanel()
        end
        panel.Visible = true
    end)
end

pcall(function()
    local Lighting=game:GetService('Lighting'); local AMB=SETTINGS.Ambience
    local folder=Instance.new('Folder'); folder.Name='AmbienceNodes'; folder.Parent=workspace
    local chunks,lights,bases={},{},{}
    local rayParams2=RaycastParams.new(); rayParams2.FilterType=RAY_FILTER_EXCLUDE; rayParams2.FilterDescendantsInstances={folder}
    local function key(cx,cy,cz) return cx..':'..cy..':'..cz end
    local function classify(pos) return Workspace:Raycast(pos,Vector3.new(0,200,0),rayParams2)~=nil and 'Indoor' or 'Outdoor' end
    local function createNode(pos)
        local p=Instance.new('Part'); p.Size=Vector3.new(0.1,0.1,0.1); p.Anchored=true; p.CanCollide=false; p.Transparency=1
        p.CFrame=CFrame.new(pos); p.Parent=folder
        local t=classify(pos); p:SetAttribute('AmbienceType',t)
        local base=(t=='Indoor' and AMB.IndoorBrightness) or AMB.Brightness
        local l=Instance.new('PointLight'); l.Range=140; l.Shadows=false; l.Brightness=base; l.Color=AMB.Color; l.Parent=p
        lights[l]=true; bases[l]=base; return p
    end
    local function buildChunk(cx,cy,cz)
        local k=key(cx,cy,cz); if chunks[k] then return end
        local group,basePos={},Vector3.new(cx*150,cy*150,cz*150)
        for x=0,150,100 do for y=0,150,100 do for z=0,150,100 do group[#group+1]=createNode(basePos+Vector3.new(x,y,z)) end end end
        chunks[k]=group
    end
    local function destroyChunk(k) local g=chunks[k]; if not g then return end; for i=1,#g do g[i]:Destroy() end; chunks[k]=nil end
    folder.DescendantRemoving:Connect(function(d) if d:IsA('PointLight') then lights[d]=nil; bases[d]=nil end end)
    local function sceneLuminance()
        local t=Lighting.ClockTime; local sun=math.clamp(math.cos((t-14)/24*math.pi*2)*-0.5+0.5,0,1)
        local amb=(Lighting.Ambient.R+Lighting.Ambient.G+Lighting.Ambient.B)/3
        return math.max(0.05,(sun*0.7+amb*0.3)*(2^Lighting.ExposureCompensation))
    end
    local function recomputeBases()
        for light in pairs(lights) do local par=light.Parent; if par then local t=par:GetAttribute('AmbienceType'); bases[light]=(t=='Indoor' and AMB.IndoorBrightness) or AMB.Brightness end end
    end
    local lastCenter; local scale,lastAppliedScale,acc=1,1,0
    local saved={Brightness=AMB.Brightness,IndoorBrightness=AMB.IndoorBrightness,Enabled=AMB.Enabled,Color=AMB.Color}
    RunService.RenderStepped:Connect(function(dt)
        local cam=Workspace.CurrentCamera; if not cam then return end
        local pos=cam.CFrame.Position; local center=Vector3.new(math.floor(pos.X/150),math.floor(pos.Y/150),math.floor(pos.Z/150))
        if not lastCenter or center~=lastCenter then
            lastCenter=center; local needed={}
            for x=-2,2 do for y=-2,2 do for z=-2,2 do local k=key(center.X+x,center.Y+y,center.Z+z); needed[k]=true; buildChunk(center.X+x,center.Y+y,center.Z+z) end end end
            for k in pairs(chunks) do if not needed[k] then destroyChunk(k) end end; acc=0.11
        end
        acc=acc+dt; if acc<0.2 then return end; acc=0
        local desired=math.clamp(1.0/sceneLuminance(),0.25,1.6); scale=scale+(desired-scale)*0.6
        local changed=false
        if math.abs(saved.Brightness-AMB.Brightness)>1e-4 then saved.Brightness=AMB.Brightness; changed=true end
        if math.abs(saved.IndoorBrightness-AMB.IndoorBrightness)>1e-4 then saved.IndoorBrightness=AMB.IndoorBrightness; changed=true end
        if saved.Enabled~=AMB.Enabled then saved.Enabled=AMB.Enabled; changed=true end
        if saved.Color~=AMB.Color then saved.Color=AMB.Color; changed=true end
        if changed then recomputeBases(); lastAppliedScale=-1 end
        if math.abs(scale-lastAppliedScale)<0.02 and not changed then return end
        lastAppliedScale=scale
        for light in pairs(lights) do
            if light.Parent then
                if AMB.Enabled then light.Brightness=bases[light]*scale; light.Color=AMB.Color
                else light.Brightness=0 end
            end
        end
    end)
end)

do
    local Mods=ReplicatedStorage:WaitForChild('Modules',10); if not Mods then return end
    local VFX=Mods:FindFirstChild('VFXModule'); if not VFX then return end
    VFX=require(VFX)
    local wsVFXFolder=Workspace:FindFirstChild('VFX'); local VMs=wsVFXFolder and wsVFXFolder:FindFirstChild('VMs')
    local SHOT_WINDOW,AIM_TOLERANCE,MAX_START_DIST=0.3,0.94,15
    local hitsoundBind=Instance.new('BindableEvent'); hitsoundBind.Parent=ReplicatedStorage
    hitsoundBind.Event:Connect(function()
        if not SETTINGS.Hitsound.Enabled then return end
        PlayHitsound(SETTINGS.Hitsound.Sound or "Minecraft")
        if SETTINGS.Hitsound.Notify then HitNotification() end
    end)
    local rayParams3=RaycastParams.new(); rayParams3.FilterType=RAY_FILTER_EXCLUDE; rayParams3.IgnoreWater=true
    local function drawTracer(fromPos,toPos)
        if not SETTINGS.Tracer.Enabled then return end
        local props = TracerProperties[SETTINGS.Tracer.Style] or TracerProperties["Default"]
        local widthScale = (SETTINGS.Tracer.Thickness or 0.15) / 0.15
        local parent=VMs or Workspace
        local a0=Instance.new('Attachment'); a0.Name='IgnoreMe'; a0.WorldPosition=fromPos; a0.Parent=parent
        local a1=Instance.new('Attachment'); a1.Name='IgnoreMe'; a1.WorldPosition=toPos; a1.Parent=parent
        local beam=Instance.new('Beam'); beam.Name='IgnoreMe'
        beam.Attachment0=a0; beam.Attachment1=a1
        beam.Color=ColorSequence.new(SETTINGS.Tracer.Color)
        beam.Texture=props.Texture
        beam.Brightness=props.Brightness
        beam.Transparency=props.Transparency
        beam.LightEmission=props.LightEmission
        if props.LightInfluence~=nil then beam.LightInfluence=props.LightInfluence end
        beam.Segments=props.Segments
        beam.TextureLength=props.TextureLength
        beam.TextureMode=props.TextureMode
        beam.TextureSpeed=props.TextureSpeed
        beam.Width0=props.Width*widthScale
        beam.Width1=props.Width*widthScale
        beam.FaceCamera=props.FaceCamera
        beam.Parent=parent
        local d=SETTINGS.Tracer.Duration
        Debris:AddItem(a0,d); Debris:AddItem(a1,d); Debris:AddItem(beam,d)
    end
    local function fireTracer(origin,direction)
        local filter={Client.Character}; if wsVFXFolder then table.insert(filter,wsVFXFolder) end
        rayParams3.FilterDescendantsInstances=filter
        local result=Workspace:Raycast(origin,direction*2000,rayParams3)
        drawTracer(origin,result and result.Position or (origin+direction*2000))
    end
    local function isMyOrigin(origin)
        local char=Client.Character; if not char then return false end
        local root=char:FindFirstChild('HumanoidRootPart'); local head=char:FindFirstChild('Head')
        if not root then return false end
        if(origin-root.Position).Magnitude<=MAX_START_DIST then return true end
        if head and(origin-head.Position).Magnitude<=MAX_START_DIST then return true end
        return false
    end
    local lastShotTime,lastShotPos,lastShotDir=0,Vector3.zero,Vector3.zero
    local __S=getgenv().__SCORP
    local OrigCP=(__S and (__S.hooks.CreateProjectile or __S.real.CreateProjectile)) or VFX.CreateProjectile
    __S.hooks.CreateProjectile=function(self,...)
        local Args={...}; local tb=_dbg.tb()
        if tb:find('ViewmodelController') and Args[1] then
            local origin=Args[1].Position or Args[1].PositionFirst; local dir=Args[1].Direction or Args[1].DirectionFirst
            if typeof(origin)=='Vector3' and typeof(dir)=='Vector3' and isMyOrigin(origin) then
                lastShotTime=tick(); lastShotPos=origin; lastShotDir=dir.Unit
                task.spawn(function() pcall(fireTracer,origin,dir.Unit) end)
            end
        end
        return OrigCP(self,...)
    end
    local function isCharacterHit(hit)
        local inst=hit; if typeof(hit)=='RaycastResult' then inst=hit.Instance end; if not inst then return false end
        local model=inst:IsA('Model') and inst or inst:FindFirstAncestorOfClass('Model'); if not model then return false end
        if model:FindFirstChildOfClass('Humanoid') then return true end
        if model:GetAttribute("Loaded")~=nil then return true end
        if model.Name=="MilitaryHitbox" then return true end; return false
    end
    local function isMyHit(position)
        if(tick()-lastShotTime)>SHOT_WINDOW then return false end
        if lastShotDir.Magnitude<0.1 then return false end
        local toHit=position-lastShotPos; if toHit.Magnitude<1 then return true end
        return toHit.Unit:Dot(lastShotDir)>=AIM_TOLERANCE
    end
    local __S=getgenv().__SCORP
    local OrigBlood=(__S and (__S.hooks.CreateBlood or __S.real.CreateBlood)) or VFX.CreateBlood
    __S.hooks.CreateBlood=function(self,hit,position)
        local tb=_dbg.tb()
        if not tb:find("function HitVFX") then if isCharacterHit(hit) and isMyHit(position) then hitsoundBind:Fire() end end
        return OrigBlood(self,hit,position)
    end
    local OrigHole=(__S and (__S.hooks.CreateHole or __S.real.CreateHole)) or VFX.CreateHole
    __S.hooks.CreateHole=function(self,hit,position,normal,material,item,impactOnly)
        local tb=_dbg.tb()
        if not tb:find("function HitVFX") then if isCharacterHit(hit) and isMyHit(position) then hitsoundBind:Fire() end end
        return OrigHole(self,hit,position,normal,material,item,impactOnly)
    end
end

do
    local lastGrassState=SETTINGS.RemoveGrass.Enabled
    RunService.Heartbeat:Connect(function()
        if SETTINGS.RemoveGrass.Enabled~=lastGrassState then
            lastGrassState=SETTINGS.RemoveGrass.Enabled
            if lastGrassState then pcall(_sff,"FRMMinGrassDistance","-1"); pcall(_sff,"FRMMaxGrassDistance","-1")
            else pcall(_sff,"FRMMinGrassDistance","100"); pcall(_sff,"FRMMaxGrassDistance","290") end
        end
    end)
    if SETTINGS.RemoveGrass.Enabled then pcall(_sff,"FRMMinGrassDistance","-1"); pcall(_sff,"FRMMaxGrassDistance","-1") end
end

do
    local _m1c=(_env.mouse1click) or (type(mouse1click)=="function" and mouse1click) or nil
    if _m1c then
        RunService.RenderStepped:Connect(function()
            if not SETTINGS.SilentAim.Autoshoot then return end
            if not SETTINGS.SilentAim.Enabled then return end
            local kb=Flags["SA_AutoshootKey"]; if not kb then return end
            local keyOn=(kb.Toggled==true)or(kb.Active==true); if not keyOn then return end
            local T=_G.scorpionTargeting; if not T then return end
            local hasTrigger=(T.TargetObject and T.TargetObject.CoreInformation and T.TargetObject.CoreInformation.Visible) or T.ManipulatedPosition
            if not hasTrigger then return end
            local char=Client.Character; if not char then return end
            local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
            if hum:GetState()==Enum.HumanoidStateType.Dead then return end
            local wheel=char:FindFirstChild("WheelController"); local inv=char:FindFirstChild("InventoryController")
            local water=char:FindFirstChild("WaterController"); local vm=char:FindFirstChild("ViewmodelController")
            if wheel and wheel:GetAttribute("Open") then return end
            if inv   and inv:GetAttribute("Open")   then return end
            if water and water:GetAttribute("IsSwim") then return end
            if vm    and(vm:GetAttribute("LocalAmmo") or 0)<=0 then return end
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
            if UserInputService.MouseBehavior~=Enum.MouseBehavior.LockCenter then return end
            _m1c()
        end)
    end
end

Library:Notification("scorpion.wtf loaded!", 3, Color3.fromRGB(50, 220, 110))