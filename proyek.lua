-- SERVICES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local req = http_request or request

-- GUI PARENT SAFE
local GUI_PARENT = (typeof(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

-- ====================================================================
-- 1. LOGGER SETTINGS & LOGIC
-- ====================================================================
local SETTINGS = {
    WebhookURL = "",
    LogFish = false, -- Default OFF
    LogJoinLeave = false -- Default OFF
}

-- CONFIG DATA
local WEBHOOK_NAME = "10s Area"
local WEBHOOK_AVATAR = "https://cdn.discordapp.com/attachments/1452251463337377902/1456009509632737417/GDEV_New.png"

-- [UPDATE] Removed Common/Uncommon/Rare. All Default OFF.
local RARITY_CONFIG = {
    Epic      = { Enabled = false, Color = 0xB373F8, Icon = "🟣" },
    Legendary = { Enabled = false, Color = 0xFFB92B, Icon = "🟡" },
    Mythic    = { Enabled = false, Color = 0xFF1919, Icon = "🔴" },
    Secret    = { Enabled = false, Color = 0x18FF98, Icon = "💎" },
}

-- [NEW] FOCUS FISH CONFIG (Default OFF)
local FOCUS_FISH = {
    ["Sacred Guardian Squid"] = { Enabled = false, Color = 0x00FBFF }, -- Cyan
    ["GEMSTONE Ruby"]         = { Enabled = false, Color = 0xFF0040 }  -- Ruby Red
}

local RGB_RARITY = {
    ["179,115,248"] = "Epic", ["255,185,43"] = "Legendary", 
    ["255,25,25"] = "Mythic", ["24,255,152"] = "Secret"
}

-- UTIL FUNCTIONS
local function stripRichText(t) return t:gsub("<.->", "") end

local function extractDisplayName(text)
    local clean = stripRichText(text)
    return clean:match("^%[Server%]:%s*(.-)%s*obtained") or clean:match("^(.-)%s*obtained") or "Unknown"
end

local function detectChance(t) return t:match("1 in ([%dKMB]+)") or "?" end

local function detectRarity(text)
    local r,g,b = text:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
    -- Jika warna tidak ada di list (misal Common/Uncommon), kembalikan nil atau Other
    return r and (RGB_RARITY[r..","..g..","..b] or "Other") or "Other"
end

local function detectFishNameAndWeight(text)
    local clean = stripRichText(text)
    local openParen = clean:match("^.*()%(")
    local fish, weight
    if openParen then
        local fishPart = clean:sub(1, openParen - 1)
        local weightPart = clean:sub(openParen + 1)
        fish = fishPart:match("obtained%s+a[n]?%s+(.+)") or fishPart:match("obtained%s+(.+)")
        weight = weightPart:match("^(.-)%)")
    else
        fish = clean:match("obtained%s+a[n]?%s+(.+)") or clean:match("obtained%s+(.+)")
        weight = "-"
    end
    -- Trim trailing spaces
    return (fish and fish:gsub("%s+$", "") or "Unknown Fish"), (weight or "-")
end

-- WEBHOOK FUNCTIONS
local function send(payload)
    if SETTINGS.WebhookURL == "" or not req then return end
    pcall(function()
        req({ Url = SETTINGS.WebhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
    end)
end

local function testWebhook()
    send({ username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR, embeds = {{ title = "✅ Webhook Connected", description = "10s Area is ready to log!", color = 0x2ECC71, footer = { text = "10s Area • System" }, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") }} })
end

local function sendFish(data)
    -- 1. Check Priority: FOCUS FISH (ByName)
    local focusData = FOCUS_FISH[data.Fish]
    if focusData and focusData.Enabled then
        send({ 
            username = WEBHOOK_NAME, 
            avatar_url = WEBHOOK_AVATAR, 
            embeds = {{ 
                title = "🚨 TARGET ACQUIRED! 🚨", 
                description = "**👑 CAUGHT: " .. data.Fish .. " 👑**", 
                color = focusData.Color, 
                fields = { 
                    { name = "👤 Player", value = "`"..data.Player.."`", inline = true }, 
                    { name = "⚖️ Weight", value = "`"..data.Weight.."`", inline = true }, 
                    { name = "🎲 Chance", value = "`1 in "..data.Chance.."`", inline = true } 
                }, 
                footer = { text = "10s Area • Focus Tracker" }, 
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") 
            }} 
        })
        return -- Stop here, don't double log
    end

    -- 2. Check Secondary: RARITY
    local cfg = RARITY_CONFIG[data.Rarity]
    if cfg and cfg.Enabled then
        send({ 
            username = WEBHOOK_NAME, 
            avatar_url = WEBHOOK_AVATAR, 
            embeds = {{ 
                title = cfg.Icon.." "..data.Rarity.." Catch!", 
                description = "A rare fish has been caught!", 
                color = cfg.Color, 
                fields = { 
                    { name = "👤 Player", value = "`"..data.Player.."`", inline = true }, 
                    { name = "🐟 Fish", value = "**"..data.Fish.."**", inline = true }, 
                    { name = "⚖️ Weight", value = "`"..data.Weight.."`", inline = true }, 
                    { name = "🎲 Chance", value = "`1 in "..data.Chance.."`", inline = true } 
                }, 
                footer = { text = "10s Area • Fish Logger" }, 
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") 
            }} 
        })
    end
end

local function sendJoinLeave(player, joined)
    if not SETTINGS.LogJoinLeave then return end
    send({ username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR, embeds = {{ title = joined and "👋 Player Joined" or "🚪 Player Left", description = "**"..player.DisplayName.."** (@"..player.Name..")", color = joined and 0x2ECC71 or 0xE74C3C, footer = { text = "10s Area • Server Activity" }, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") }} })
end

-- LISTENERS
TextChatService.OnIncomingMessage = function(msg)
    if not SETTINGS.LogFish then return end
    if not msg.Text or not msg.Text:find("obtained") then return end
    
    local fishName, weight = detectFishNameAndWeight(msg.Text)
    local rarity = detectRarity(msg.Text)
    
    sendFish({ 
        Player = extractDisplayName(msg.Text), 
        Fish = fishName, 
        Weight = weight, 
        Chance = detectChance(msg.Text), 
        Rarity = rarity 
    })
end

Players.PlayerAdded:Connect(function(player) sendJoinLeave(player, true) end)
Players.PlayerRemoving:Connect(function(player) sendJoinLeave(player, false) end)

-- ====================================================================
-- 2. UI GDEV SETUP (GUI CODE)
-- ====================================================================

-- CLEANUP OLD GUI
if GUI_PARENT:FindFirstChild("GDEV_HUB_LOGGER") then
    GUI_PARENT.GDEV_HUB_LOGGER:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GDEV_HUB_LOGGER"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10000
ScreenGui.Parent = GUI_PARENT
ScreenGui.ResetOnSpawn = false

-- UI CONFIG
local Viewport = Camera.ViewportSize
local StartWidth = math.clamp(Viewport.X * 0.40, 350, 600)
local StartHeight = math.clamp(Viewport.Y * 0.40, 250, 500)
local DEFAULT_SIZE = UDim2.new(0, StartWidth, 0, StartHeight)
local MIN_SIZE = Vector2.new(350, 240)
local MINIMIZED_SIZE = UDim2.new(0, 250, 0, 32)

local MAIN_BG = Color3.fromRGB(15, 15, 15)
local ELEMENT_BG = Color3.fromRGB(30, 30, 30)
local ACCENT_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local TEXT_DIM = Color3.fromRGB(120, 120, 120)

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = DEFAULT_SIZE
MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = MAIN_BG
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 6); MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = ACCENT_COLOR; MainStroke.Transparency = 0.5; MainStroke.Thickness = 1; MainStroke.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Rotation = 45
MainGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.0, Color3.fromRGB(150, 150, 150)) }
MainGradient.Parent = MainFrame

-- HEADER
local Header = Instance.new("Frame", MainFrame); Header.Name = "Header"; Header.Size = UDim2.new(1, 0, 0, 32); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header); Title.Text = "GDEV LOGGER"; Title.Size = UDim2.new(0, 200, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0); Title.BackgroundTransparency = 1; Title.TextColor3 = TEXT_COLOR; Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.TextXAlignment = Enum.TextXAlignment.Left
local MinBtn = Instance.new("TextButton", Header); MinBtn.Name = "MinBtn"; MinBtn.Size = UDim2.new(0, 32, 1, 0); MinBtn.Position = UDim2.new(1, -32, 0, 0); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "-"; MinBtn.TextColor3 = TEXT_COLOR; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 20
local HeaderLine = Instance.new("Frame", Header); HeaderLine.Size = UDim2.new(1, 0, 0, 1); HeaderLine.Position = UDim2.new(0, 0, 1, -1); HeaderLine.BackgroundColor3 = ACCENT_COLOR; HeaderLine.BackgroundTransparency = 0.8; HeaderLine.BorderSizePixel = 0
local LineGradient = Instance.new("UIGradient", HeaderLine); LineGradient.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0.0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1.0, 1) }

-- BODY
local Body = Instance.new("Frame", MainFrame); Body.Name = "Body"; Body.Size = UDim2.new(1, 0, 1, -32); Body.Position = UDim2.new(0, 0, 0, 32); Body.BackgroundTransparency = 1; Body.ClipsDescendants = true
local Sidebar = Instance.new("Frame", Body); Sidebar.Size = UDim2.new(0.28, 0, 1, 0); Sidebar.BackgroundTransparency = 1
local SideLayout = Instance.new("UIListLayout", Sidebar); SideLayout.Padding = UDim.new(0, 2); SideLayout.SortOrder = Enum.SortOrder.LayoutOrder; SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local SidePad = Instance.new("UIPadding", Sidebar); SidePad.PaddingTop = UDim.new(0, 8)
local SepLine = Instance.new("Frame", Body); SepLine.Size = UDim2.new(0, 1, 1, 0); SepLine.Position = UDim2.new(0.28, 0, 0, 0); SepLine.BackgroundColor3 = ACCENT_COLOR; SepLine.BackgroundTransparency = 0.8; SepLine.BorderSizePixel = 0
local Content = Instance.new("Frame", Body); Content.Size = UDim2.new(0.72, 0, 1, 0); Content.Position = UDim2.new(0.28, 0, 0, 0); Content.BackgroundTransparency = 1; Content.ClipsDescendants = true

-- TABS
local Tabs = {"Info", "Dashboard", "Settings"}
local TabFrames = {}
local TabButtons = {}

local function SwitchTab(activeName)
    for name, frame in pairs(TabFrames) do frame.Visible = (name == activeName) end
    for name, btn in pairs(TabButtons) do
        btn.TextColor3 = (name == activeName) and TEXT_COLOR or TEXT_DIM
        btn.BackgroundTransparency = (name == activeName) and 0.9 or 1
    end
end

for i, name in ipairs(Tabs) do
    local Page = Instance.new("ScrollingFrame", Content); Page.Name = name; Page.Size = UDim2.new(1, -10, 1, -10); Page.Position = UDim2.new(0, 5, 0, 5); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 2; Page.ScrollBarImageColor3 = ACCENT_COLOR; Page.AutomaticCanvasSize = Enum.AutomaticSize.Y; Page.CanvasSize = UDim2.new(0,0,0,0)
    local PLayout = Instance.new("UIListLayout", Page); PLayout.Padding = UDim.new(0, 5); PLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local PPad = Instance.new("UIPadding", Page); PPad.PaddingTop = UDim.new(0, 5); PPad.PaddingLeft = UDim.new(0, 5); PPad.PaddingRight = UDim.new(0, 5)
    TabFrames[name] = Page
    local Btn = Instance.new("TextButton", Sidebar); Btn.Name = name; Btn.LayoutOrder = i; Btn.Size = UDim2.new(1, -16, 0, 28); Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Btn.BackgroundTransparency = 1; Btn.Text = name; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 14; Btn.TextColor3 = TEXT_DIM
    local BCorner = Instance.new("UICorner", Btn); BCorner.CornerRadius = UDim.new(0, 4)
    Btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    TabButtons[name] = Btn
end

-- HELPER FUNCTIONS
local function GetOrder(parent) return #parent:GetChildren() end
function CreateSection(parent, text)
    local Lab = Instance.new("TextLabel", parent); Lab.LayoutOrder = GetOrder(parent); Lab.Text = text:upper(); Lab.Size = UDim2.new(1, 0, 0, 24); Lab.BackgroundTransparency = 1; Lab.TextColor3 = ACCENT_COLOR; Lab.TextTransparency = 0.4; Lab.Font = Enum.Font.GothamBold; Lab.TextSize = 12; Lab.TextXAlignment = Enum.TextXAlignment.Left
end
function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton", parent); Btn.LayoutOrder = GetOrder(parent); Btn.Size = UDim2.new(1, 0, 0, 30); Btn.BackgroundColor3 = ELEMENT_BG; Btn.Text = text; Btn.TextColor3 = TEXT_COLOR; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 14
    local Corner = Instance.new("UICorner", Btn); Corner.CornerRadius = UDim.new(0, 4)
    Btn.MouseButton1Click:Connect(function() pcall(callback) end)
end
function CreateToggle(parent, text, defaultVal, callback)
    local Frame = Instance.new("Frame", parent); Frame.LayoutOrder = GetOrder(parent); Frame.Size = UDim2.new(1, 0, 0, 30); Frame.BackgroundColor3 = ELEMENT_BG
    local Corner = Instance.new("UICorner", Frame); Corner.CornerRadius = UDim.new(0, 4)
    local Lab = Instance.new("TextLabel", Frame); Lab.Text = text; Lab.Size = UDim2.new(0.7, 0, 1, 0); Lab.Position = UDim2.new(0, 10, 0, 0); Lab.BackgroundTransparency = 1; Lab.TextColor3 = TEXT_COLOR; Lab.Font = Enum.Font.GothamBold; Lab.TextSize = 14; Lab.TextXAlignment = Enum.TextXAlignment.Left
    local ToggleBtn = Instance.new("TextButton", Frame); ToggleBtn.Size = UDim2.new(0, 36, 0, 18); ToggleBtn.Position = UDim2.new(1, -42, 0.5, -9); ToggleBtn.BackgroundColor3 = defaultVal and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50); ToggleBtn.Text = ""
    local TCorner = Instance.new("UICorner", ToggleBtn); TCorner.CornerRadius = UDim.new(1, 0)
    local Dot = Instance.new("Frame", ToggleBtn); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = defaultVal and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(200, 200, 200)
    local DCorner = Instance.new("UICorner", Dot); DCorner.CornerRadius = UDim.new(1, 0)
    local on = defaultVal
    ToggleBtn.MouseButton1Click:Connect(function()
        on = not on
        if on then TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play(); TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
        else TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play(); TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play() end
        pcall(callback, on)
    end)
end
function CreateInput(parent, placeholder, defaultText, callback)
    local Frame = Instance.new("Frame", parent); Frame.LayoutOrder = GetOrder(parent); Frame.Size = UDim2.new(1, 0, 0, 36); Frame.BackgroundColor3 = ELEMENT_BG
    local Corner = Instance.new("UICorner", Frame); Corner.CornerRadius = UDim.new(0, 4)
    local Box = Instance.new("TextBox", Frame); Box.Size = UDim2.new(1, -20, 1, 0); Box.Position = UDim2.new(0, 10, 0, 0); Box.BackgroundTransparency = 1; Box.Text = defaultText or ""; Box.PlaceholderText = placeholder; Box.TextColor3 = TEXT_COLOR; Box.PlaceholderColor3 = TEXT_DIM; Box.Font = Enum.Font.GothamBold; Box.TextSize = 14; Box.TextXAlignment = Enum.TextXAlignment.Left; Box.ClearTextOnFocus = false
    Box.FocusLost:Connect(function() pcall(callback, Box.Text) end)
end

-- ====================================================================
-- 3. BUILDING THE UI CONTENT
-- ====================================================================

-- [INFO TAB]
CreateSection(TabFrames["Info"], "About")
local InfoTxt = Instance.new("TextLabel", TabFrames["Info"]); InfoTxt.LayoutOrder = GetOrder(TabFrames["Info"]); InfoTxt.Text = "GDEV LOGGER v9.2\n\nFocus Tracking enabled for:\n- Sacred Guardian Squid\n- GEMSTONE Ruby\n\nCommon-Rare filters removed."; InfoTxt.Size = UDim2.new(1, 0, 0, 100); InfoTxt.BackgroundTransparency = 1; InfoTxt.TextColor3 = TEXT_DIM; InfoTxt.Font = Enum.Font.GothamBold; InfoTxt.TextSize = 13; InfoTxt.TextXAlignment = Enum.TextXAlignment.Left; InfoTxt.TextWrapped = true
CreateButton(TabFrames["Info"], "Copy Discord Link", function() setclipboard("https://discord.gg/YOUR_DISCORD_LINK") end)

-- [DASHBOARD TAB]
CreateSection(TabFrames["Dashboard"], "Webhook")
CreateInput(TabFrames["Dashboard"], "Paste Webhook URL Here...", SETTINGS.WebhookURL, function(text) SETTINGS.WebhookURL = text end)
CreateButton(TabFrames["Dashboard"], "Test Webhook", testWebhook)
CreateSection(TabFrames["Dashboard"], "Controls")
CreateToggle(TabFrames["Dashboard"], "Enable Logger", SETTINGS.LogFish, function(val) SETTINGS.LogFish = val end)
CreateToggle(TabFrames["Dashboard"], "Join/Leave Logs", SETTINGS.LogJoinLeave, function(val) SETTINGS.LogJoinLeave = val end)

-- [SETTINGS TAB - FOCUS & RARITY]
CreateSection(TabFrames["Settings"], "Specific Target")

-- Loop untuk Target Fokus (Sacred & Ruby)
for fishName, config in pairs(FOCUS_FISH) do
    CreateToggle(TabFrames["Settings"], "Focus: " .. fishName, config.Enabled, function(val)
        config.Enabled = val
        print("🎯 Focus " .. fishName .. ": " .. tostring(val))
    end)
end

CreateSection(TabFrames["Settings"], "General Rarity")

-- Loop untuk Rarity (Hanya Epic ke atas)
local RarityOrder = {"Epic", "Legendary", "Mythic", "Secret", "rare", "uncommon", "common"}

for _, rarityKey in ipairs(RarityOrder) do
    local config = RARITY_CONFIG[rarityKey]
    local displayName = rarityKey
    if rarityKey == "Legendary" then displayName = "Legend" end

    CreateToggle(TabFrames["Settings"], "Log " .. displayName, config.Enabled, function(val)
        config.Enabled = val
    end)
end

-- ====================================================================
-- 4. WINDOW LOGIC
-- ====================================================================
local HelperLine = Instance.new("TextButton", ScreenGui); HelperLine.Name = "HelperLine"; HelperLine.Text = ""; HelperLine.BackgroundColor3 = ACCENT_COLOR; HelperLine.BorderSizePixel = 0; HelperLine.BackgroundTransparency = 0.3; HelperLine.AnchorPoint = Vector2.new(0.5, 0); HelperLine.ZIndex = MainFrame.ZIndex - 1; Instance.new("UICorner", HelperLine).CornerRadius = UDim.new(1, 0)
local function UpdateHelperLine()
    if not MainFrame or not MainFrame.Parent then return end
    local mainPos = MainFrame.AbsolutePosition; local mainSize = MainFrame.AbsoluteSize; local centerX = mainPos.X + (mainSize.X / 2); local bottomY = mainPos.Y + mainSize.Y
    HelperLine.Position = UDim2.new(0, centerX, 0, bottomY + 4); HelperLine.Size = UDim2.new(0, mainSize.X * 0.5, 0, 5)
end
MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateHelperLine); MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateHelperLine); UpdateHelperLine()
HelperLine.MouseEnter:Connect(function() TweenService:Create(HelperLine, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
HelperLine.MouseLeave:Connect(function() TweenService:Create(HelperLine, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play() end)

local dragging, dragStart, startPos
local function StartDrag(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end end
Header.InputBegan:Connect(StartDrag); HelperLine.InputBegan:Connect(StartDrag)
UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local isMin, lastSize = false, DEFAULT_SIZE
MinBtn.MouseButton1Click:Connect(function()
    if isMin then TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = lastSize}):Play(); Body.Visible = true; HelperLine.Visible = true; MinBtn.Text = "-"
    else lastSize = MainFrame.Size; TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = MINIMIZED_SIZE}):Play(); Body.Visible = false; HelperLine.Visible = false; MinBtn.Text = "+" end; isMin = not isMin
end)

local ResizeBtn = Instance.new("ImageButton", MainFrame); ResizeBtn.Size = UDim2.new(0, 15, 0, 15); ResizeBtn.Position = UDim2.new(1, -15, 1, -15); ResizeBtn.BackgroundTransparency = 1; ResizeBtn.Image = "rbxassetid://3599185146"; ResizeBtn.ImageTransparency = 0.5; ResizeBtn.ImageColor3 = ACCENT_COLOR
local resizing, resizeStart, startSize
ResizeBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = true; resizeStart = input.Position; startSize = MainFrame.AbsoluteSize end end)
UserInputService.InputChanged:Connect(function(input) if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - resizeStart; MainFrame.Size = UDim2.new(0, math.max(MIN_SIZE.X, startSize.X + delta.X), 0, math.max(MIN_SIZE.Y, startSize.Y + delta.Y)) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end end)

SwitchTab("Info")
MainFrame.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = DEFAULT_SIZE}):Play()
print("GDEV LOGGER UI LOADED")
