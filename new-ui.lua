-- ====================================================================
-- GDEV LOGGER v9.7 - Multi-Webhook (Default Set)
-- ====================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (identifyexecutor and request)

-- [1] LOAD WINDUI LIBRARY
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [2] CONFIG DATA & DEFAULT WEBHOOKS
local IMAGE_EMBED = "https://cdn.discordapp.com/attachments/1449462744028811499/1449987836756627547/f7f9b6065f0db9b67dff28c80a17acd4_720w_1.gif"

local SETTINGS = {
    -- Webhook Defaults
    WebhookCatch = "https://discord.com/api/webhooks/1457726463636672512/_LFDG-8cN1tgPAJ8nX2BzkZOCr9CzFOOU1aPhpTl8jgkszzUA3g8x_1b2r5FD-hGPCQf",
    WebhookEnchant = "https://discord.com/api/webhooks/1458499915209773137/vTKhmapzHx56_c8rTELfxYYdUhMvZWBh558W6CQoKqwgLmbKbOBkushuHEESjJs8FY3E",
    WebhookJoinLeave = "https://discord.com/api/webhooks/1458500004325884130/NaP2erbHhic9Rd0xn4D5alL5ra6rYFWQsPtw24KeRkRnjpG7ZFSnJy6VeV2QVHc7R9iQ",
    
    -- Toggles
    LogFish = false,
    LogEnchant = false, 
    LogJoinLeave = false
}

local WEBHOOK_NAME = "10s Area"
local WEBHOOK_AVATAR = "https://cdn.discordapp.com/attachments/1452251463337377902/1456009509632737417/GDEV_New.png"

local RARITY_CONFIG = {
    Uncommon  = { Enabled = false, Color = 0xCCCCCC, Icon = "⬜" },
    Common    = { Enabled = false, Color = 0x00FF00, Icon = "🟩" },
    Rare      = { Enabled = false, Color = 0x3D85C6, Icon = "🟦" },
    Epic      = { Enabled = false, Color = 0xB373F8, Icon = "🟪" },
    Legendary = { Enabled = false, Color = 0xFFB92B, Icon = "🟨" },
    Mythic    = { Enabled = false, Color = 0xFF1919, Icon = "🟥" },
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

local function send(url, payload)
    if not url or url == "" or not req then return end
    task.spawn(function()
        pcall(function()
            req({
                Url = url, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function testWebhook(url, category)
    if url == "" then
        WindUI:Notify({ Title = "Error", Content = category .. " URL is empty!", Icon = "alert-circle" })
        return
    end
    send(url, {
        username = WEBHOOK_NAME, avatar_url = WEBHOOK_AVATAR,
        embeds = {{
            title = "✅ Test Connection: " .. category,
            description = "Webhook ini berhasil terhubung untuk log " .. category,
            color = 0x2ECC71,
            footer = { text = "10s Area • System" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
    WindUI:Notify({ Title = "Sent", Content = "Test sent to " .. category, Icon = "send" })
end

-- Helper detection functions (keeping original logic)
local function stripRichText(t) return t:gsub("<.->", "") end
local function extractDisplayName(text)
    local clean = stripRichText(text)
    return clean:match("^%[Server%]:%s*(.-)%s*obtained") or clean:match("^(.-)%s*obtained") or "Unknown"
end
local function detectChance(t) return t:match("1 in ([%dKMB]+)") or "?" end
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
local function detectEnchantData(text)
    local clean = stripRichText(text)
    return clean:match("^%[Server%]:%s*(.-)%s+rolled%s+a%s+(.-)%s+on%s+their%s+(.-)!$")
end

-- ====================================================================
-- LOGGING SENDER FUNCTIONS
-- ====================================================================

local function sendFish(data)
    local focusData = FOCUS_FISH[data.Fish]
    local cfg = RARITY_CONFIG[data.Rarity]
    local payload = nil

    if focusData and focusData.Enabled then
        payload = {
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
        }
    elseif cfg and cfg.Enabled then
        payload = {
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
        }
    end

    if payload then send(SETTINGS.WebhookCatch, payload) end
end

local function sendEnchant(data)
    send(SETTINGS.WebhookEnchant, {
        username = WEBHOOK_NAME,
        embeds = {{
            title = "✨ ENCHANTMENT ROLLED! ✨",
            description = "**" .. data.Player .. "** Kamu Berhasil Mendapatkan Enchant Baru !",
            color = 0xD000FF,
            fields = {
                { name = "🧙 Player", value = "`" .. data.Player .. "`", inline = true },
                { name = "🔮 Enchant", value = "`" .. data.Enchant .. "`", inline = true },
                { name = "🎣 Rod", value = "`" .. data.Rod .. "`", inline = true }
            },
            thumbnail = { url = IMAGE_EMBED },
            footer = { text = "10s Area • Enchant Logger" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
end

local function sendJoinLeave(player, joined)
    if not SETTINGS.LogJoinLeave then return end
    send(SETTINGS.WebhookJoinLeave, {
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
    Title = "GDEV LOGGER MULTI",
    Icon = "fish",
    Author = "10s Area",
    Folder = "GDEVLogger_Multi",
    Transparent = true
})

Window:EditOpenButton({
    Title = "Open Logger",
    Icon = "fish-symbol",
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
})

local DashboardTab = Window:Tab({ Title = "Dashboard", Icon = "layout-dashboard" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- >> DASHBOARD: WEBHOOKS & TEST BUTTONS
local WebhookSection = DashboardTab:Section({ Title = "Webhook URLs (Auto-Set)", Icon = "link" })

-- Tangkapan
WebhookSection:Input({
    Title = "Webhook Tangkapan",
    Value = SETTINGS.WebhookCatch,
    Callback = function(text) SETTINGS.WebhookCatch = text end
})
WebhookSection:Button({
    Title = "Test Webhook Tangkapan",
    Callback = function() testWebhook(SETTINGS.WebhookCatch, "Tangkapan") end
})

-- Enchant
WebhookSection:Input({
    Title = "Webhook Enchant",
    Value = SETTINGS.WebhookEnchant,
    Callback = function(text) SETTINGS.WebhookEnchant = text end
})
WebhookSection:Button({
    Title = "Test Webhook Enchant",
    Callback = function() testWebhook(SETTINGS.WebhookEnchant, "Enchant") end
})

-- Masuk/Keluar
WebhookSection:Input({
    Title = "Webhook Masuk/Keluar",
    Value = SETTINGS.WebhookJoinLeave,
    Callback = function(text) SETTINGS.WebhookJoinLeave = text end
})
WebhookSection:Button({
    Title = "Test Webhook Masuk/Keluar",
    Callback = function() testWebhook(SETTINGS.WebhookJoinLeave, "Masuk/Keluar") end
})

local ControlSection = DashboardTab:Section({ Title = "Logger Controls", Icon = "power" })

ControlSection:Toggle({
    Title = "Enable Fish Logger",
    Value = SETTINGS.LogFish,
    Callback = function(val) SETTINGS.LogFish = val end
})

ControlSection:Toggle({
    Title = "Enable Enchant Logger",
    Value = SETTINGS.LogEnchant,
    Callback = function(val) SETTINGS.LogEnchant = val end
})

ControlSection:Toggle({
    Title = "Log Join/Leave",
    Value = SETTINGS.LogJoinLeave,
    Callback = function(val) SETTINGS.LogJoinLeave = val end
})

-- >> SETTINGS: FOCUS & RARITY
local FocusSection = SettingsTab:Section({ Title = "Focus Targets", Icon = "crosshair" })
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
            Value = config.Enabled,
            Callback = function(val) config.Enabled = val end
        })
    end
end

-- ====================================================================
-- LISTENERS
-- ====================================================================

local LastMsg = ""
local LastTime = 0

local function ProcessText(text)
    if not text then return end
    if text == LastMsg and (os.clock() - LastTime) < 1 then return end
    LastMsg = text
    LastTime = os.clock()

    if SETTINGS.LogFish and text:find("obtained") then
        local fishName, weight = detectFishNameAndWeight(text)
        local rarity = detectRarity(text)
        if rarity == "Other" and not FOCUS_FISH[fishName] then return end
        sendFish({
            Player = extractDisplayName(text),
            Fish = fishName, Weight = weight,
            Chance = detectChance(text), Rarity = rarity
        })
    end

    if SETTINGS.LogEnchant and text:find("rolled a") and text:find("on their") then
        local p, e, r = detectEnchantData(text)
        if p and e and r then
            sendEnchant({ Player = p, Enchant = e, Rod = r })
        end
    end
end

TextChatService.MessageReceived:Connect(function(m) ProcessText(m.Text) end)
TextChatService.OnIncomingMessage = function(m)
    if m.Status == Enum.TextChatMessageStatus.Success then ProcessText(m.Text) end
end

Players.PlayerAdded:Connect(function(p) sendJoinLeave(p, true) end)
Players.PlayerRemoving:Connect(function(p) sendJoinLeave(p, false) end)

WindUI:Notify({ Title = "System", Content = "Webhooks Initialized!", Duration = 3, Icon = "check" })