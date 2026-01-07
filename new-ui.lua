-- ====================================================================
-- GDEV LOGGER v10.6 - STABLE VERSION
-- ====================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or
                (identifyexecutor and request)

-- [1] LOAD WINDUI LIBRARY
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [2] CONFIG DATA
local IMAGE_EMBED = "https://cdn.discordapp.com/attachments/1449462744028811499/1458501140277628970/g_logo.jpeg"

local SETTINGS = {
    WebhookCatch = "https://discord.com/api/webhooks/1457726463636672512/_LFDG-8cN1tgPAJ8nX2BzkZOCr9CzFOOU1aPhpTl8jgkszzUA3g8x_1b2r5FD-hGPCQf",
    WebhookEnchant = "https://discord.com/api/webhooks/1458499915209773137/vTKhmapzHx56_c8rTELfxYYdUhMvZWBh558W6CQoKqwgLmbKbOBkushuHEESjJs8FY3E",
    WebhookJoinLeave = "https://discord.com/api/webhooks/1458500004325884130/NaP2erbHhic9Rd0xn4D5alL5ra6rYFWQsPtw24KeRkRnjpG7ZFSnJy6VeV2QVHc7R9iQ",

    LogFish = true,
    LogEnchant = true,
    LogJoinLeave = true
}

local GlobalData = {
    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    SelectedFishIds = {},
    SelectedRarities = {},
    -- Remote Detection
    Net = ReplicatedStorage:WaitForChild("Net", 10)
}

-- [3] INITIALIZE DATABASE
local function InitDatabase()
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            local ok, data = pcall(require, item)
            if ok and data.Data and data.Data.Type == "Fish" then
                local id, name = data.Data.Id, data.Data.Name
                GlobalData.FishIdToName[id] = name
                GlobalData.FishNameToId[name] = id
                table.insert(GlobalData.FishNames, name)
            end
        end
        table.sort(GlobalData.FishNames)
    end
end
InitDatabase()

-- [4] WEBHOOK SEND FUNCTION
local function sendToDiscord(url, payload)
    if not url or url == "" or not req then
        return
    end
    task.spawn(function()
        pcall(function()
            req({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- [5] UI CONSTRUCTION
local Window = WindUI:CreateWindow({
    Title = "GDEV FOCUS LOGGER",
    Icon = "target",
    Author = "10s Area",
    Transparent = true
})

local DashTab = Window:Tab({
    Title = "Dashboard",
    Icon = "layout-dashboard"
})
local FocusTab = Window:Tab({
    Title = "Focus Targets",
    Icon = "crosshair"
})

-- DASHBOARD
local WebSec = DashTab:Section({
    Title = "Discord Configuration",
    Icon = "link"
})
WebSec:Input({
    Title = "Catch URL",
    Value = SETTINGS.WebhookCatch,
    Callback = function(t)
        SETTINGS.WebhookCatch = t
    end
})
WebSec:Button({
    Title = "Test Webhook",
    Callback = function()
        sendToDiscord(SETTINGS.WebhookCatch, {
            username = "10s Area",
            embeds = {{
                title = "✅ Webhook Active",
                color = 0x2ECC71,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
    end
})

local ControlSec = DashTab:Section({
    Title = "Switches",
    Icon = "power"
})
ControlSec:Toggle({
    Title = "Log Enchant",
    Value = SETTINGS.LogEnchant,
    Callback = function(v)
        SETTINGS.LogEnchant = v
    end
})
ControlSec:Toggle({
    Title = "Log Join/Leave",
    Value = SETTINGS.LogJoinLeave,
    Callback = function(v)
        SETTINGS.LogJoinLeave = v
    end
})

-- FOCUS TAB
local FocusSec = FocusTab:Section({
    Title = "Target Selection",
    Icon = "database"
})
FocusSec:Toggle({
    Title = "Enable Focus Tracker",
    Value = SETTINGS.LogFish,
    Callback = function(v)
        SETTINGS.LogFish = v
    end
})

FocusSec:Dropdown({
    Title = "Select Target Fish",
    Options = GlobalData.FishNames,
    Multi = true,
    Callback = function(selected)
        GlobalData.SelectedFishIds = {}
        for _, name in ipairs(selected) do
            local id = GlobalData.FishNameToId[name]
            if id then
                GlobalData.SelectedFishIds[id] = true
            end
        end
    end
})

FocusSec:Dropdown({
    Title = "Select Target Rarities",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Multi = true,
    Callback = function(selected)
        GlobalData.SelectedRarities = {}
        for _, r in ipairs(selected) do
            GlobalData.SelectedRarities[r] = true
        end
    end
})

-- [6] CORE LOGIC
local function triggerFocusLog(fishName, rarity, variant)
    sendToDiscord(SETTINGS.WebhookCatch, {
        username = "10s Area | Focus Tracker",
        avatar_url = IMAGE_EMBED,
        embeds = {{
            title = "🎯 TARGET CAUGHT!",
            color = 0xFF0040,
            fields = {{
                name = "👤 Player",
                value = "`" .. Players.LocalPlayer.Name .. "`",
                inline = true
            }, {
                name = "🐟 Fish",
                value = "**" .. fishName .. "**",
                inline = true
            }, {
                name = "💎 Rarity",
                value = "`" .. (rarity or "Unknown") .. "`",
                inline = true
            }, {
                name = "✨ Variant",
                value = "`" .. (variant or "Normal") .. "`",
                inline = true
            }},
            image = {
                url = IMAGE_EMBED
            },
            footer = {
                text = "GDEV Logger • Stable"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
    WindUI:Notify({
        Title = "Target Found!",
        Content = "Caught " .. fishName,
        Icon = "target"
    })
end

-- REMOTE LISTENER
if GlobalData.Net then
    local ObtainedRE = GlobalData.Net:WaitForChild("RE/ObtainedNewFishNotification", 5)
    if ObtainedRE then
        ObtainedRE.OnClientEvent:Connect(function(itemId, _, data)
            if not SETTINGS.LogFish then
                return
            end

            local fishName = GlobalData.FishIdToName[itemId] or "Unknown"
            -- Sederhanakan penentuan rarity dari data game
            local isFocused = GlobalData.SelectedFishIds[itemId]

            if isFocused then
                triggerFocusLog(fishName, "From Database", "Detected")
            end
        end)
    end
end

-- JOIN/LEAVE
Players.PlayerAdded:Connect(function(p)
    if SETTINGS.LogJoinLeave then
        sendToDiscord(SETTINGS.WebhookJoinLeave, {
            embeds = {{
                title = "👋 " .. p.Name .. " Joined",
                color = 0x2ECC71
            }}
        })
    end
end)

WindUI:Notify({
    Title = "System",
    Content = "Script Ready!",
    Icon = "check"
})
