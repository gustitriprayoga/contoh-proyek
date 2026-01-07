-- ====================================================================
-- GDEV LOGGER v10.5 - Database Focus Tracker (Auto-Sync Game Data)
-- ====================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (identifyexecutor and request)

-- [1] LOAD WINDUI LIBRARY
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [2] CONFIG DATA & WEBHOOKS
local IMAGE_EMBED = "https://cdn.discordapp.com/attachments/1449462744028811499/1458501140277628970/g_logo.jpeg"

local SETTINGS = {
    WebhookCatch = "https://discord.com/api/webhooks/1457726463636672512/_LFDG-8cN1tgPAJ8nX2BzkZOCr9CzFOOU1aPhpTl8jgkszzUA3g8x_1b2r5FD-hGPCQf",
    WebhookEnchant = "https://discord.com/api/webhooks/1458499915209773137/vTKhmapzHx56_c8rTELfxYYdUhMvZWBh558W6CQoKqwgLmbKbOBkushuHEESjJs8FY3E",
    WebhookJoinLeave = "https://discord.com/api/webhooks/1458500004325884130/NaP2erbHhic9Rd0xn4D5alL5ra6rYFWQsPtw24KeRkRnjpG7ZFSnJy6VeV2QVHc7R9iQ",

    LogFish = true,
    LogEnchant = true,
    LogJoinLeave = true,
}

local WEBHOOK_NAME = "10s Area | Fish It Logger"
local WEBHOOK_AVATAR = IMAGE_EMBED

-- [3] DATABASE INITIALIZATION (MENGAMBIL DARI GAME)
local GlobalData = {
    FishIdToName = {}, FishNameToId = {}, FishIdToTier = {}, FishNames = {},
    Variants = {}, VariantIdToName = {}, VariantNameToId = {},
    -- Selection Storage
    SelectedFishIds = {}, SelectedVariants = {}, SelectedRarities = {},
    -- Remote
    REObtained = ReplicatedStorage:WaitForChild("Net"):WaitForChild("RE/ObtainedNewFishNotification")
}

local TierNames = {
    [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythic", [7] = "Secret", [0] = "Common"
}

-- Ambil Data Item Ikan
for _, item in pairs(ReplicatedStorage.Items:GetChildren()) do
    local ok, data = pcall(require, item)
    if ok and data.Data and data.Data.Type == "Fish" then
        local id, name, tier = data.Data.Id, data.Data.Name, data.Data.Tier
        GlobalData.FishIdToName[id] = name
        GlobalData.FishNameToId[name] = id
        GlobalData.FishIdToTier[id] = tier
        table.insert(GlobalData.FishNames, name)
    end
end

-- Ambil Data Mutasi/Variant
for _, vMod in pairs(ReplicatedStorage.Variants:GetChildren()) do
    local ok, vData = pcall(require, vMod)
    if ok and vData.Data then
        GlobalData.VariantIdToName[vData.Data.Id] = vData.Data.Name
        GlobalData.VariantNameToId[vData.Data.Name] = vData.Data.Id
        table.insert(GlobalData.Variants, vData.Data.Name)
    end
end
table.sort(GlobalData.FishNames)
table.sort(GlobalData.Variants)

-- ====================================================================
-- LOGIC FUNCTIONS
-- ====================================================================

local function sendToDiscord(url, payload)
    if not url or url == "" or not req then return end
    task.spawn(function()
        pcall(function()
            req({
                Url = url, Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- ====================================================================
-- UI CONSTRUCTION
-- ====================================================================

local Window = WindUI:CreateWindow({
    Title = "GDEV FOCUS LOGGER",
    Icon = "target",
    Author = "10s Area",
    Transparent = true
})

local DashTab = Window:Tab({ Title = "Dashboard", Icon = "layout-dashboard" })
local FocusTab = Window:Tab({ Title = "Focus Targets", Icon = "crosshair" })

-- DASHBOARD WEBHOOKS
local WebSec = DashTab:Section({ Title = "Webhook Settings", Icon = "link" })
WebSec:Input({ Title = "Catch URL", Value = SETTINGS.WebhookCatch, Callback = function(t) SETTINGS.WebhookCatch = t end })
WebSec:Button({ Title = "Test Catch Webhook", Callback = function() 
    sendToDiscord(SETTINGS.WebhookCatch, {content = "✅ Catch Webhook Connected!"}) 
end})

-- FOCUS SELECTION (DROPDOWNS)
local TargetSec = FocusTab:Section({ Title = "Target Selection", Icon = "database" })

TargetSec:Toggle({
    Title = "Enable Focus Tracker",
    Value = SETTINGS.LogFish,
    Callback = function(v) SETTINGS.LogFish = v end
})

TargetSec:Dropdown({
    Title = "Focus Fish Names",
    Options = GlobalData.FishNames,
    Multi = true,
    Callback = function(selected)
        GlobalData.SelectedFishIds = {}
        for _, n in ipairs(selected) do
            local id = GlobalData.FishNameToId[n]
            if id then GlobalData.SelectedFishIds[id] = true end
        end
    end
})

TargetSec:Dropdown({
    Title = "Focus Rarities",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Multi = true,
    Callback = function(selected)
        GlobalData.SelectedRarities = {}
        for _, r in ipairs(selected) do GlobalData.SelectedRarities[r] = true end
    end
})

-- ====================================================================
-- MAIN LISTENER (CONNECTION TO GAME DATA)
-- ====================================================================

-- Listener untuk Tangkapan Berdasarkan Remote Game (Lebih Akurat dari Chat)
GlobalData.REObtained.OnClientEvent:Connect(function(itemId, _, data)
    if not SETTINGS.LogFish then return end

    local invItem = data.InventoryItem
    if not invItem then return end

    local fishName = GlobalData.FishIdToName[itemId] or "Unknown"
    local tierName = TierNames[GlobalData.FishIdToTier[itemId]] or "Common"
    local variantId = invItem.Metadata and invItem.Metadata.VariantId
    local variantName = GlobalData.VariantIdToName[variantId] or "Normal"

    -- Logic Cek apakah Ikan ini masuk dalam FOCUS
    local isFocused = GlobalData.SelectedFishIds[itemId] or GlobalData.SelectedRarities[tierName]

    if isFocused then
        sendToDiscord(SETTINGS.WebhookCatch, {
            username = WEBHOOK_NAME,
            avatar_url = WEBHOOK_AVATAR,
            embeds = {{
                title = "🎯 TARGET CAUGHT!",
                color = 0xFF0040,
                fields = {
                    { name = "👤 Player", value = "`" .. Players.LocalPlayer.Name .. "`", inline = true },
                    { name = "🐟 Fish", value = "**" .. fishName .. "**", inline = true },
                    { name = "💎 Rarity", value = "`" .. tierName .. "`", inline = true },
                    { name = "✨ Variant", value = "`" .. variantName .. "`", inline = true }
                },
                image = { url = IMAGE_EMBED },
                footer = { text = "10s Area • Focus Tracker" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
        WindUI:Notify({ Title = "Target Found!", Content = "Caught " .. fishName .. "!", Icon = "target" })
    end
end)

-- Listener untuk Join/Leave
Players.PlayerAdded:Connect(function(p) if SETTINGS.LogJoinLeave then --[[ Logic Join ]] end end)

WindUI:Notify({ Title = "System", Content = "Database Focus Logger Loaded!", Icon = "check" })