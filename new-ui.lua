-- ====================================================================
-- GDEV LOGGER v9.6 - Enchant Update
-- ====================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

-- Request Handler
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (identifyexecutor and request)

-- [1] LOAD WINDUI LIBRARY
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [2] CONFIG DATA
local IMAGE_EMBED = "https://cdn.discordapp.com/attachments/1449462744028811499/1449987836756627547/f7f9b6065f0db9b67dff28c80a17acd4_720w_1.gif?ex=695de6e7&is=695c9567&hm=15c22720a777a44b6061441bf6f68f459f07d0bf243aab8caf5e6d0cc6bbcefb&"

local DEFAULT_WEBHOOK = "https://discord.com/api/webhooks/1457726463636672512/_LFDG-8cN1tgPAJ8nX2BzkZOCr9CzFOOU1aPhpTl8jgkszzUA3g8x_1b2r5FD-hGPCQf"

local SETTINGS = {
    WebhookURL = DEFAULT_WEBHOOK,
    LogFish = false,
    LogEnchant = false, -- [NEW] Setting Enchant
    LogJoinLeave = false
}

local WEBHOOK_NAME = "10s Area"
local WEBHOOK_AVATAR = "https://cdn.discordapp.com/attachments/1452251463337377902/1456009509632737417/GDEV_New.png"

local RARITY_CONFIG = {
    Epic      = { Enabled = false, Color = 0xB373F8, Icon = "🟣" },
    Legendary = { Enabled = false, Color = 0xFFB92B, Icon = "🟡" },
    Mythic    = { Enabled = false, Color = 0xFF1919, Icon = "🔴" },
    Secret    = { Enabled = false, Color = 0x18FF98, Icon = "💎" },
}

local FOCUS_FISH = {
    ["Sacred Guardian Squid"] = { Enabled = false, Color = 0x00FBFF },
    ["GEMSTONE Ruby"]         = { Enabled = false, Color = 0xFF0040 },
    ["Ruby"]                  = { Enabled = false, Color = 0xFF0040 },
    ["Evolved Enchant Stone"] = { Enabled = false, Color = 0xFF0040 }
}

local RGB_RARITY = {
    ["179,115,248"] = "Epic", ["255,185,43"] = "Legendary", 
    ["255,25,25"] = "Mythic", ["24,255,152"] = "Secret"
}

-- ====================================================================
-- LOGIC FUNCTIONS
-- ====================================================================

local function stripRichText(t)
    return t:gsub("<.->", "")
end

local function extractDisplayName(text)
    local clean = stripRichText(text)
    return clean:match("^%[Server%]:%s*(.-)%s*obtained") or clean:match("^(.-)%s*obtained") or "Unknown"
end

local function detectChance(t)
    return t:match("1 in ([%dKMB]+)") or "?"
end

local function detectRarity(text)
    local r, g, b = text:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
    return r and (RGB_RARITY[r .. "," .. g .. "," .. b] or "Other") or "Other"
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
    return (fish and fish:gsub("%s+$", "") or "Unknown Fish"), (weight or "-")
end

-- [NEW] Function detect Enchant
local function detectEnchantData(text)
    local clean = stripRichText(text)
    -- Pattern: [Server]: Alice4JAV rolled a Stormhunter I Enchant on their Diamond Rod!
    local player, enchant, rod = clean:match("^%[Server%]:%s*(.-)%s+rolled%s+a%s+(.-)%s+on%s+their%s+(.-)!$")
    return player, enchant, rod
end

local function send(payload)
    if SETTINGS.WebhookURL == "" or not req then return end
    task.spawn(function()
        pcall(function()
            req({
                Url = SETTINGS.WebhookURL, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function testWebhook()
    if SETTINGS.WebhookURL == "" then
        WindUI:Notify({ Title = "Error", Content = "Webhook URL is empty!", Icon = "alert-circle" })
        return
    end
    send({
        username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR,
        embeds = {{
            title = "✅ Berhasil Terhubung", description = "10s Dev Logger Ready", color = 0x2ECC71,
            footer = { text = "10s Area • System" }, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
    WindUI:Notify({ Title = "Sent", Content = "Test payload sent.", Icon = "send" })
end

-- [NEW] Send Enchant Webhook
local function sendEnchant(data)
    send({
        username = WEBHOOK_NAME,
        embeds = {{
            title = "✨ ENCHANTMENT ROLLED! ✨",
            description = "**" .. data.Player .. "** Kamu Berhasil Mendapatkan Enchant Baru !",
            color = 0xD000FF, -- Warna Ungu Magic
            fields = {
                { name = "🧙 Player", value = "`" .. data.Player .. "`", inline = true },
                { name = "🔮 Enchant", value = "`" .. data.Enchant .. "`", inline = true },
                { name = "🎣 Rod", value = "`" .. data.Rod .. "`", inline = true }
            },
            thumbnail = { url = IMAGE_EMBED },
            {
                iamge = { url = IMAGE_EMBED },
            },
            footer = { text = "10s Area • Enchant Logger" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
end

local function sendFish(data)
    local focusData = FOCUS_FISH[data.Fish]
    -- 1. PRIORITY LOG (FOCUS)
    if focusData and focusData.Enabled then
        send({
            username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR,
            embeds = {{
                title = "🚨 Target Di Temukan! 🚨",
                description = "**👑 CAUGHT: " .. data.Fish .. " 👑**",
                color = focusData.Color,
                fields = {
                    { name = "👤 Player", value = "`" .. data.Player .. "`", inline = true },
                    { name = "⚖️ Weight", value = "`" .. data.Weight .. "`", inline = true },
                    { name = "🎲 Chance", value = "`1 in " .. data.Chance .. "`", inline = true }
                },
                image = { url = IMAGE_EMBED },
                footer = { text = "10s Area • Focus Tracker" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
        return
    end
    -- 2. RARITY LOG
    local cfg = RARITY_CONFIG[data.Rarity]
    if cfg and cfg.Enabled then
        send({
            username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR,
            embeds = {{
                title = cfg.Icon .. " " .. data.Rarity .. " Tertangkap!",
                description = "Selamat Kamu Berhasil Mendapatkan " .. data.Fish .. "!",
                color = cfg.Color,
                fields = {
                    { name = "👤 Player", value = "`" .. data.Player .. "`", inline = true },
                    { name = "🐟 Fish", value = "`" .. data.Fish .. "`", inline = true },
                    { name = "⚖️ Weight", value = "`" .. data.Weight .. "`", inline = true },
                    { name = "🎲 Chance", value = "`1 in " .. data.Chance .. "`", inline = true }
                },
                image = { url = IMAGE_EMBED },
                footer = { text = "10s Area • Fish Logger" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
    end
end

local function sendJoinLeave(player, joined)
    if not SETTINGS.LogJoinLeave then return end
    send({
        username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR,
        embeds = {{
            title = joined and "👋 Telah Bergabung!" or "🚪 Telah Keluar!",
            color = joined and 0x2ECC71 or 0xE74C3C,
            fields = {
                { name = "👤 Player", value = "`" .. player.Name .. "`" },
                { name = "👤 Display Name", value = "`" .. player.DisplayName .. "`" }
            },
            thumbnail = { url = IMAGE_EMBED },
            footer = { text = "10s Area • Server Activity" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
end

-- ====================================================================
-- WINDUI CONSTRUCTION
-- ====================================================================

local Window = WindUI:CreateWindow({
    Title = "GDEV LOGGER",
    Icon = "fish",
    Author = "10s Area",
    Folder = "GDEVLogger",
    Transparent = true
})

Window:EditOpenButton({
    Title = "Open Logger",
    Icon = "fish-symbol",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

-- TABS
local DashboardTab = Window:Tab({ Title = "Dashboard", Icon = "layout-dashboard" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local InfoTab = Window:Tab({ Title = "Information", Icon = "info" })

-- >> DASHBOARD
local WebhookSection = DashboardTab:Section({ Title = "Webhook Configuration", Icon = "link" })

WebhookSection:Input({
    Title = "Webhook URL",
    Desc = "Default webhook is already set",
    Value = SETTINGS.WebhookURL,
    Placeholder = "https://discord.com/...",
    Callback = function(text) SETTINGS.WebhookURL = text end
})

WebhookSection:Button({
    Title = "Test Connection",
    Desc = "Send a test message",
    Callback = testWebhook
})

local ControlSection = DashboardTab:Section({ Title = "Main Controls", Icon = "power" })

ControlSection:Toggle({
    Title = "Enable Fish Logger",
    Desc = "Log when players catch fish",
    Value = SETTINGS.LogFish,
    Callback = function(val) SETTINGS.LogFish = val end
})

-- [NEW] Toggle Enchant
ControlSection:Toggle({
    Title = "Enable Enchant Logger",
    Desc = "Log when players roll enchants",
    Value = SETTINGS.LogEnchant,
    Callback = function(val) SETTINGS.LogEnchant = val end
})

ControlSection:Toggle({
    Title = "Log Join/Leave",
    Desc = "Notify when players enter or exit",
    Value = SETTINGS.LogJoinLeave,
    Callback = function(val) SETTINGS.LogJoinLeave = val end
})

-- >> SETTINGS
local FocusSection = SettingsTab:Section({ Title = "Focus Targets", Icon = "crosshair" })
FocusSection:Paragraph({ Title = "Info", Content = "These fish will be logged with priority ping." })

for fishName, config in pairs(FOCUS_FISH) do
    FocusSection:Toggle({
        Title = "Focus: " .. fishName,
        Value = config.Enabled,
        Callback = function(val) config.Enabled = val end
    })
end

local RaritySection = SettingsTab:Section({ Title = "Rarity Filters", Icon = "filter" })
local RarityOrder = {"Epic", "Legendary", "Mythic", "Secret"}

for _, rarityName in ipairs(RarityOrder) do
    local config = RARITY_CONFIG[rarityName]
    if config then
        RaritySection:Toggle({
            Title = "Log " .. rarityName,
            Desc = "Rarity Color: " .. config.Icon,
            Value = config.Enabled,
            Callback = function(val) config.Enabled = val end
        })
    end
end

-- >> INFO
local InfoSection = InfoTab:Section({ Title = "About", Icon = "book-open" })
InfoSection:Paragraph({ Title = "GDEV LOGGER v9.6", Content = "Added Enchant Logger.\nUsing WindUI (Footagesus Fork)." })
InfoSection:Button({
    Title = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/jvGR68CkQj")
        WindUI:Notify({ Title = "Copied", Content = "Link copied!", Icon = "copy" })
    end
})

-- ====================================================================
-- LISTENERS (LOGIC UTAMA)
-- ====================================================================

local function ProcessText(text)
    if not text then return end

    -- [CHECK 1] LOG FISH
    if SETTINGS.LogFish and text:find("obtained") then
        local fishName, weight = detectFishNameAndWeight(text)
        local rarity = detectRarity(text)
        
        -- Filter Rarity/Focus
        if rarity == "Other" and not FOCUS_FISH[fishName] then return end

        sendFish({
            Player = extractDisplayName(text),
            Fish = fishName,
            Weight = weight,
            Chance = detectChance(text),
            Rarity = rarity
        })
    end

    -- [CHECK 2] LOG ENCHANT (NEW)
    -- Format: [Server]: Player rolled a Enchant on their Rod!
    if SETTINGS.LogEnchant and text:find("rolled a") and text:find("on their") then
        local player, enchant, rod = detectEnchantData(text)
        if player and enchant and rod then
            sendEnchant({ Player = player, Enchant = enchant, Rod = rod })
        end
    end
end

-- Listener Modern Chat
TextChatService.MessageReceived:Connect(function(textChatMessage)
    ProcessText(textChatMessage.Text)
end)

-- Listener Legacy Chat (System Message)
TextChatService.OnIncomingMessage = function(textChatMessage)
    if textChatMessage.Status == Enum.TextChatMessageStatus.Success then
        ProcessText(textChatMessage.Text)
    end
end

Players.PlayerAdded:Connect(function(player) sendJoinLeave(player, true) end)
Players.PlayerRemoving:Connect(function(player) sendJoinLeave(player, false) end)

WindUI:Notify({
    Title = "GDEV Logger",
    Content = "Script Loaded (Fish + Enchant Support)",
    Duration = 5,
    Icon = "check"
})
