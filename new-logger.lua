-- ====================================================================
-- GDEV LOGGER v32.0 - MANUAL VARIANT & SMART IMAGE
-- ====================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Safety Check
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or
                (identifyexecutor and request)
if not req then
    warn("Executor tidak support HTTP Request.")
end

-- [1] LOAD WINDUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [2] CONFIG DATA
local DEFAULT_IMAGE =
    "https://cdn.discordapp.com/attachments/1449462744028811499/1449987836756627547/f7f9b6065f0db9b67dff28c80a17acd4_720w_1.gif"
local DEBUG_WEBHOOK =
    "https://discord.com/api/webhooks/1449748090033799268/vSgX3XxENIRMAYKCzgSLXMlvIvlJR1zphXRPt0x3RNWSWLgiFdnMzTOrHh6CxD7hX_b4"

local USER_MAPPING = {
    ["Alice4JAV"] = "425852550672023552",
    ["Lia4JAV"] = "425852550672023552",
    ["Ti4JAV"] = "425852550672023552",
    ["Lya4JAV"] = "425852550672023552",
    ["Clay4JAV"] = "425852550672023552",
    ["AbgRichOmon"] = "592612835960422411",
    ["PriaTerzolimi22"] = "592612835960422411",
    ["NanikAAA4JAV"] = "592612835960422411",
    ["Hana4JAV"] = "592612835960422411"
}

local SETTINGS = {
    WebhookCatch = "https://discord.com/api/webhooks/1457726463636672512/_LFDG-8cN1tgPAJ8nX2BzkZOCr9CzFOOU1aPhpTl8jgkszzUA3g8x_1b2r5FD-hGPCQf",
    WebhookEnchant = "https://discord.com/api/webhooks/1458499915209773137/vTKhmapzHx56_c8rTELfxYYdUhMvZWBh558W6CQoKqwgLmbKbOBkushuHEESjJs8FY3E",
    WebhookJoinLeave = "https://discord.com/api/webhooks/1458500004325884130/NaP2erbHhic9Rd0xn4D5alL5ra6rYFWQsPtw24KeRkRnjpG7ZFSnJy6VeV2QVHc7R9iQ",

    LogFish = true,
    LogEnchant = true,
    LogJoinLeave = true,
    FocusFilterEnabled = true,
    LogEverything = false
}

local WEBHOOK_NAME = "10s Area"
local WEBHOOK_AVATAR = "https://cdn.discordapp.com/attachments/1452251463337377902/1456009509632737417/GDEV_New.png"

-- [[ MANUAL VARIANT LIST (REQUESTED) ]]
local MANUAL_VARIANTS = {"1x1x1x1", "ALBINO", "ARTIC FROST", "BLOODMOON", "COLOR BURN", "CORRUPT", "DISCO",
                         "FAIRY DUST", "FESTIVE", "FROZEN", "GALAXY", "GEMSTONE", "GHOST", "GOLD", "HOLOGRAPHIC",
                         "LEVIATHAN'S RAGE", "LIGHTNING", "MIDNIGHT", "NOOB", "RADIOACTIVE", "SANDY", "STONE"}
-- Kita sort agar rapi di dropdown
table.sort(MANUAL_VARIANTS)

local GlobalData = {
    ListFish = {},
    ListStones = {},
    ListMutations = MANUAL_VARIANTS, -- Menggunakan List Manual
    FocusFish = {},
    FocusMutations = {},
    FocusStones = {},
    DebugTarget = nil
}

local COLOR_MAP = {
    ["179,115,248"] = "Epic",
    ["#B373F8"] = "Epic",
    ["255,185,43"] = "Legendary",
    ["#FFB92B"] = "Legendary",
    ["255,25,25"] = "Mythic",
    ["#FF1919"] = "Mythic",
    ["24,255,152"] = "Secret",
    ["#18FF98"] = "Secret",
    ["0,255,0"] = "Common",
    ["#00FF00"] = "Common",
    ["204,204,204"] = "Uncommon",
    ["#CCCCCC"] = "Uncommon",
    ["61,133,198"] = "Rare",
    ["#3D85C6"] = "Rare"
}

local RARITY_CONFIG = {
    Uncommon = {
        Enabled = false,
        Color = 0xCCCCCC,
        Icon = "⬜"
    },
    Common = {
        Enabled = false,
        Color = 0x00FF00,
        Icon = "🟩"
    },
    Rare = {
        Enabled = false,
        Color = 0x3D85C6,
        Icon = "🟦"
    },
    Epic = {
        Enabled = false,
        Color = 0xB373F8,
        Icon = "🟪"
    },
    Legendary = {
        Enabled = false,
        Color = 0xFFB92B,
        Icon = "🟨"
    },
    Mythic = {
        Enabled = false,
        Color = 0xFF1919,
        Icon = "🟥"
    },
    Secret = {
        Enabled = true,
        Color = 0x18FF98,
        Icon = "💎"
    },
    Unknown = {
        Enabled = false,
        Color = 0xFFFFFF,
        Icon = "❓"
    }
}

-- ====================================================================
-- [3] IMAGE SYSTEM (SMART MATCHER)
-- ====================================================================
local function getThumbnailURL(assetString)
    if not assetString then
        return nil
    end
    local assetId = assetString:match("rbxassetid://(%d+)") or (tonumber(assetString) and assetString)
    if not assetId then
        return nil
    end

    local apiUrl = string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png", assetId)
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(apiUrl))
    end)

    if success and result and result.data and result.data[1] and result.data[1].imageUrl then
        return result.data[1].imageUrl
    end
    return nil
end

-- Helper untuk mengambil ID dari Module
local function ExtractIDFromModule(moduleInstance)
    if not moduleInstance then
        return nil
    end
    local ok, data = pcall(require, moduleInstance)
    if ok and data.Data then
        return data.Data.Image or data.Data.Texture or data.Data.TextureId or data.Data.Icon
    end
    return nil
end

-- [[ FUNGSI PENCARI GAMBAR PINTAR ]] --
local function GetItemImageURL(itemName)
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not ItemsFolder then
        return DEFAULT_IMAGE
    end

    -- 1. Coba Cari Nama Persis (Ex: "Angler Fish")
    local exactModule = ItemsFolder:FindFirstChild(itemName)
    if exactModule then
        local rawId = ExtractIDFromModule(exactModule)
        if rawId then
            return getThumbnailURL(tostring(rawId)) or DEFAULT_IMAGE
        end
    end

    -- 2. Coba Bersihkan Nama dari Variant
    local cleanName = itemName
    for _, variantName in pairs(GlobalData.ListMutations) do
        -- Hapus kata variant (Case sensitive sesuai database manual)
        cleanName = cleanName:gsub(variantName, "")
    end
    -- Hapus spasi berlebih di awal/akhir
    cleanName = cleanName:gsub("^%s*(.-)%s*$", "%1")

    local cleanModule = ItemsFolder:FindFirstChild(cleanName)
    if cleanModule then
        local rawId = ExtractIDFromModule(cleanModule)
        if rawId then
            return getThumbnailURL(tostring(rawId)) or DEFAULT_IMAGE
        end
    end

    -- 3. (Fallback) Fuzzy Search
    for _, itemMod in pairs(ItemsFolder:GetChildren()) do
        if #itemMod.Name > 3 and string.find(itemName, itemMod.Name) then
            local rawId = ExtractIDFromModule(itemMod)
            if rawId then
                return getThumbnailURL(tostring(rawId)) or DEFAULT_IMAGE
            end
        end
    end

    return DEFAULT_IMAGE
end

-- ====================================================================
-- [4] DATABASE SCANNER (Modified for Manual Variants)
-- ====================================================================
local function ScanAllDatabases()
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    local fishList, stoneList = {}, {}

    if ItemsFolder then
        for i, item in ipairs(ItemsFolder:GetChildren()) do
            local ok, module = pcall(require, item)
            if ok and module.Data and module.Data.Name then
                local n = module.Data.Name
                if module.Data.Type == "Fish" then
                    table.insert(fishList, n)
                elseif n:match("Stone") or n:match("Enchant") or n:match("Relic") or module.Data.Type == "Stone" then
                    table.insert(stoneList, n)
                end
            end
            if i % 100 == 0 then
                task.wait()
            end
        end
    end

    -- KITA GUNAKAN LIST MANUAL, JADI BAGIAN SCAN VARIANTS DI-SKIP AGAR LEBIH CEPAT
    local mutationList = MANUAL_VARIANTS

    table.sort(fishList)
    table.sort(stoneList)
    -- mutationList sudah di sort di atas

    return fishList, stoneList, mutationList
end

-- ====================================================================
-- [5] UTILS & WEBHOOK
-- ====================================================================
local function send(url, payload)
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

local function GetMentionContent(playerName)
    return USER_MAPPING[playerName] and ("<@" .. USER_MAPPING[playerName] .. ">") or ""
end

local function testWebhook(url, category)
    if url == "" then
        WindUI:Notify({
            Title = "Error",
            Content = "URL Kosong!",
            Icon = "alert-circle"
        })
        return
    end
    send(url, {
        username = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        embeds = {{
            title = "✅ Test Connection: " .. category,
            description = "Webhook OK.",
            color = 0x2ECC71
        }}
    })
    WindUI:Notify({
        Title = "Sent",
        Content = "Test sent!",
        Icon = "send"
    })
end

local function TestDebugImage()
    local target = GlobalData.DebugTarget
    if not target then
        WindUI:Notify({
            Title = "Error",
            Content = "Pilih Ikan dulu!",
            Icon = "alert-triangle"
        })
        return
    end
    WindUI:Notify({
        Title = "Debugging",
        Content = "Fetching: " .. target,
        Icon = "loader"
    })

    local url = GetItemImageURL(target)

    send(DEBUG_WEBHOOK, {
        username = "GDEV Debugger",
        embeds = {{
            title = "🖼️ DEBUG RESULT",
            description = "Target Asli: **" .. target .. "**\nURL Hasil: " ..
                (url == DEFAULT_IMAGE and "Default (Not Found)" or "Found!"),
            color = 0xE67E22,
            image = {
                url = url
            }
        }}
    })
end

local function stripRichText(t)
    return t:gsub("<.->", "")
end
local function extractDisplayName(text)
    return
        stripRichText(text):match("^%[Server%]:%s*(.-)%s*obtained") or stripRichText(text):match("^(.-)%s*obtained") or
            "Unknown"
end
local function detectChance(t)
    return t:match("1 in ([%dKMB%.]+)") or "?"
end

local function detectRarity(text)
    local r, g, b = text:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
    if r then
        local key = r .. "," .. g .. "," .. b
        if COLOR_MAP[key] then
            return COLOR_MAP[key]
        end
    end
    local hex = text:match("color=\"(#[%w]+)\"") or text:match("color='(#[%w]+)'")
    if hex then
        hex = string.upper(hex)
        if COLOR_MAP[hex] then
            return COLOR_MAP[hex]
        end
    end
    return "Unknown"
end

local function detectItemData(text)
    local clean = stripRichText(text)
    local itemName, weight = "Unknown", "N/A"

    local match1, weight1 = clean:match("obtained%s+a[n]?%s+(.+)%s+%((.+)%)")
    if match1 then
        return match1, weight1
    end

    local matchIndo = clean:match("Mendapatkan%s*:%s*(.+)")
    if matchIndo then
        return matchIndo:gsub("%s+$", ""), "N/A"
    end

    local match3 = clean:match("obtained%s+a[n]?%s+(.+)")
    if match3 then
        return match3:gsub("%s+$", ""), "N/A"
    end

    return itemName, weight
end

local function detectEnchantData(text)
    return stripRichText(text):match("^%[Server%]:%s*(.-)%s+rolled%s+a%s+(.-)%s+on%s+their%s+(.-)!$")
end

-- ====================================================================
-- [6] SEND LOGIC
-- ====================================================================
local function IsItemFocused(itemName)
    if not SETTINGS.FocusFilterEnabled then
        return false
    end
    if not itemName then
        return false
    end

    for target, _ in pairs(GlobalData.FocusStones) do
        if string.find(itemName, target) then
            return true
        end
    end

    local fishSel, fishMat = false, false
    local mutSel, mutMat = false, false

    for target, _ in pairs(GlobalData.FocusFish) do
        fishSel = true;
        if string.find(itemName, target) then
            fishMat = true;
            break
        end
    end
    for target, _ in pairs(GlobalData.FocusMutations) do
        mutSel = true;
        if string.find(itemName, target) then
            mutMat = true;
            break
        end
    end

    if fishSel and mutSel then
        return fishMat and mutMat
    elseif fishSel then
        return fishMat
    elseif mutSel then
        return mutMat
    end
    return false
end

local function sendCatchLog(data)
    local rarityCfg = RARITY_CONFIG[data.Rarity] or RARITY_CONFIG["Unknown"]
    local shouldSend = false
    local embedColor = rarityCfg.Color
    local titleText = rarityCfg.Icon .. " " .. data.Rarity .. " | Berhasil Di Dapatkan "

    if IsItemFocused(data.Item) then
        shouldSend = true;
        embedColor = 0xFF0040;
        titleText = "🚨 TARGET DITEMUKAN KAWAN! 🚨"
    elseif rarityCfg.Enabled then
        shouldSend = true
    elseif SETTINGS.LogEverything then
        shouldSend = true;
        titleText = "❓ LOG (Generic)"
    end

    if shouldSend then
        -- > SMART IMAGE FETCH <
        local dynamicImage = GetItemImageURL(data.Item)

        local userTag = GetMentionContent(data.Player)
        local subjectName = (userTag ~= "") and userTag or ("**" .. data.Player .. "**")
        local discordField = (userTag ~= "") and userTag or "N/A"

        send(SETTINGS.WebhookCatch, {
            username = WEBHOOK_NAME,
            avatar_url = WEBHOOK_AVATAR,
            embeds = {{
                title = titleText,
                description = "Selamat " .. subjectName .. " Kamu Berhasil Mendapatkan : **" .. data.Item .. "**",
                color = embedColor,
                fields = { -- 1. Display Name
                {
                    name = "❯ | 📛 Display Name",
                    value = "```" .. player.DisplayName .. "```",
                    inline = false
                }, -- 2. Player Name (Username)
                {
                    name = "❯ | 👤 Username",
                    value = "```" .. player.Name .. "```",
                    inline = false
                }, {
                    name = "❯ | 🐟 Item/Fish :",
                    value = "```" .. data.Item .. "```"
                }, {
                    name = "❯ | ⚖️ Weight :",
                    value = "```" .. data.Weight .. "```"
                }, {
                    name = "❯ | 🎲 Chance :",
                    value = "```1 in " .. data.Chance .. "```"
                }, {
                    name = "❯ | 🆔 Discord :",
                    value = "```" .. discordField .. "```"
                }},
                image = {
                    url = dynamicImage
                },
                footer = {
                    text = "10s Area • Fish Logger",
                    inline = true
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        })
    end
end

local function sendEnchant(data)
    local userTag = GetMentionContent(data.Player)
    local subjectName = (userTag ~= "") and userTag or ("**" .. data.Player .. "**")
    local discordField = (userTag ~= "") and userTag or "N/A"

    send(SETTINGS.WebhookEnchant, {
        username = WEBHOOK_NAME,
        embeds = {{
            title = "✨ ENCHANT ROLLED ✨",
            description = "Selamat " .. subjectName .. " Telah Mendapatkan Enchant Baru **" .. data.Enchant .. "**",
            color = 0xD000FF,
            fields = { -- 1. Display Name
            {
                name = "❯ | 📛 Display Name",
                value = "```" .. player.DisplayName .. "```",
                inline = false
            }, -- 2. Player Name (Username)
            {
                name = "❯ | 👤 Username",
                value = "```" .. player.Name .. "```",
                inline = false
            }, {
                name = "❯ | 🔮 Enchant :",
                value = "```" .. data.Enchant .. "```"
            }, {
                name = "❯ | 🎣 Rod :",
                value = "```" .. data.Rod .. "```"
            }, {
                name = "❯ | 🆔 Discord :",
                value = "```" .. discordField .. "```"
            }},
            footer = {
                text = "10s Area • Enchant Logger",
                inline = true
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
end

local function sendJoinLeave(player, joined)
    if not SETTINGS.LogJoinLeave then
        return
    end
    local title = joined and "👋 PLAYER TELAH BERGABUNG" or "🚪 PLAYER TELAH KELUAR"
    local color = joined and 0x00FF00 or 0xFF0000
    local userTag = GetMentionContent(player.Name)
    local descText = (userTag ~= "") and (userTag .. " | `" .. player.Name .. "`") or ("`" .. player.Name .. "`")
    local discordField = (userTag ~= "") and userTag or "N/A"

    send(SETTINGS.WebhookJoinLeave, {
        -- username = WEBHOOK_NAME,
        -- avatar_url = WEBHOOK_AVATAR,
        description = "👋 PLAYER TELAH BERGABUNG/KELUAR",
        embeds = {{
            title = title,
            description = descText,
            color = color,
            fields = { -- 1. Display Name
            {
                name = "❯ 📛 Display Name",
                value = "```" .. player.DisplayName .. "```",
                inline = false
            }, -- 2. Player Name (Username)
            {
                name = "❯ 👤 Username",
                value = "```" .. player.Name .. "```",
                inline = false
            }, {
                name = "❯ 📅 Account Age",
                value = "```" .. player.AccountAge .. " days```",
                inline = false
            }, {
                name = "❯ 🆔 Discord",
                value = "```" .. discordField .. "```",
                inline = false
            }},
            footer = {
                text = "Server Join/Leave Logger"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
end

-- ====================================================================
-- [7] UI & INIT
-- ====================================================================
local Window = WindUI:CreateWindow({
    Title = "GDEV LOGGER v32.0",
    Icon = "target",
    Author = "10s Area",
    Transparent = true
})
Window:EditOpenButton({
    Title = "Open Logger",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})
Window:Tag({
    Title = "v32.0 Manual",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 0
})

local TrackerTab = Window:Tab({
    Title = "Tracker",
    Icon = "crosshair"
})
local DebugTab = Window:Tab({
    Title = "Debug",
    Icon = "bug"
})
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info"
})

local ControlSec = TrackerTab:Section({
    Title = "Main Controls",
    Icon = "power"
})
ControlSec:Toggle({
    Title = "Enable Catch Log",
    Value = SETTINGS.LogFish,
    Callback = function(v)
        SETTINGS.LogFish = v
    end
})
ControlSec:Toggle({
    Title = "Enable Enchant Log",
    Value = SETTINGS.LogEnchant,
    Callback = function(v)
        SETTINGS.LogEnchant = v
    end
})
ControlSec:Toggle({
    Title = "Enable Join/Leave Log",
    Value = SETTINGS.LogJoinLeave,
    Callback = function(v)
        SETTINGS.LogJoinLeave = v
    end
})

local WebhookSec = TrackerTab:Section({
    Title = "Webhook Setup",
    Icon = "link"
})
WebhookSec:Input({
    Title = "Webhook Catch",
    Value = SETTINGS.WebhookCatch,
    Callback = function(v)
        SETTINGS.WebhookCatch = v
    end
})
WebhookSec:Button({
    Title = "Test Catch",
    Callback = function()
        testWebhook(SETTINGS.WebhookCatch, "Catch")
    end
})
WebhookSec:Input({
    Title = "Webhook Enchant",
    Value = SETTINGS.WebhookEnchant,
    Callback = function(v)
        SETTINGS.WebhookEnchant = v
    end
})
WebhookSec:Button({
    Title = "Test Enchant",
    Callback = function()
        testWebhook(SETTINGS.WebhookEnchant, "Enchant")
    end
})
WebhookSec:Input({
    Title = "Webhook Join/Leave",
    Value = SETTINGS.WebhookJoinLeave,
    Callback = function(v)
        SETTINGS.WebhookJoinLeave = v
    end
})
WebhookSec:Button({
    Title = "Test Join/Leave",
    Callback = function()
        testWebhook(SETTINGS.WebhookJoinLeave, "Join/Leave")
    end
})

local FocusSec = TrackerTab:Section({
    Title = "Target Database",
    Icon = "database"
})
FocusSec:Toggle({
    Title = "Enable Target Filter",
    Desc = "ON = Strict Mode. OFF = All Items.",
    Value = SETTINGS.FocusFilterEnabled,
    Callback = function(v)
        SETTINGS.FocusFilterEnabled = v
    end
})
FocusSec:Button({
    Title = "Reset All Selections",
    Icon = "trash",
    Callback = function()
        GlobalData.FocusFish = {};
        GlobalData.FocusMutations = {};
        GlobalData.FocusStones = {};
        WindUI:Notify({
            Title = "Reset",
            Content = "Selection cleared!",
            Icon = "check"
        })
    end
})

local FishDropdown = FocusSec:Dropdown({
    Title = "Search Fish",
    Values = {"Scanning..."},
    Multi = true,
    Callback = function(list)
        GlobalData.FocusFish = {};
        if type(list) == "string" then
            list = {list}
        end
        for _, name in pairs(list) do
            if name ~= "Scanning..." then
                GlobalData.FocusFish[name] = true
            end
        end
    end
})
-- MENGGUNAKAN MANUAL VARIANTS DI DROPDOWN
local MutationDropdown = FocusSec:Dropdown({
    Title = "Search Mutations",
    Values = MANUAL_VARIANTS,
    Multi = true,
    Callback = function(list)
        GlobalData.FocusMutations = {};
        if type(list) == "string" then
            list = {list}
        end
        for _, name in pairs(list) do
            GlobalData.FocusMutations[name] = true
        end
    end
})
local StoneDropdown = FocusSec:Dropdown({
    Title = "Search Stones",
    Values = {"Scanning..."},
    Multi = true,
    Callback = function(list)
        GlobalData.FocusStones = {};
        if type(list) == "string" then
            list = {list}
        end
        for _, name in pairs(list) do
            if name ~= "Scanning..." then
                GlobalData.FocusStones[name] = true
            end
        end
    end
})

local RaritySec = TrackerTab:Section({
    Title = "Rarity Filter",
    Icon = "palette"
})
for _, rarity in ipairs({"Epic", "Legendary", "Mythic", "Secret"}) do
    RaritySec:Toggle({
        Title = "Log " .. rarity,
        Value = RARITY_CONFIG[rarity].Enabled,
        Callback = function(v)
            RARITY_CONFIG[rarity].Enabled = v
        end
    })
end

local DebugSec = DebugTab:Section({
    Title = "Image Debugger",
    Icon = "image"
})
local DebugDropdown = DebugSec:Dropdown({
    Title = "Select Item",
    Values = {"Scanning..."},
    Multi = false,
    Callback = function(val)
        GlobalData.DebugTarget = val
    end
})
DebugSec:Button({
    Title = "Check & Send to Discord",
    Desc = "Kirim gambar ke Debug Webhook.",
    Icon = "send",
    Callback = function()
        TestDebugImage()
    end
})

local InfoSec = InfoTab:Section({
    Title = "About",
    Icon = "file-text"
})
InfoSec:Paragraph({
    Title = "GDEV Logger",
    Desc = "Versi: 32.0 (Manual Variant)\nDeveloper: 10s Area"
})
InfoSec:Button({
    Title = "Join Discord",
    Icon = "message-circle",
    Callback = function()
        setclipboard("https://discord.gg/yourlink");
        WindUI:Notify({
            Title = "Copied",
            Content = "Link Copied!",
            Icon = "copy"
        })
    end
})

task.spawn(function()
    local fish, stones, mutations = ScanAllDatabases()
    GlobalData.ListFish = fish;
    GlobalData.ListStones = stones;
    -- GlobalData.ListMutations sudah diisi manual di atas

    pcall(function()
        if #fish > 0 then
            if FishDropdown.SetValues then
                FishDropdown:SetValues(fish)
            elseif FishDropdown.Refresh then
                FishDropdown:Refresh(fish)
            end
            if DebugDropdown.SetValues then
                DebugDropdown:SetValues(fish)
            elseif DebugDropdown.Refresh then
                DebugDropdown:Refresh(fish)
            end
        end
        -- Refresh Stone Dropdown
        if #stones > 0 then
            if StoneDropdown.SetValues then
                StoneDropdown:SetValues(stones)
            elseif StoneDropdown.Refresh then
                StoneDropdown:Refresh(stones)
            end
        end
        -- Mutation Dropdown sudah pakai list manual
    end)
    WindUI:Notify({
        Title = "System Ready",
        Content = "DB Loaded (v32.0)",
        Icon = "check"
    })
end)

local LastMsg = ""
local function ProcessText(text)
    if text == LastMsg then
        return
    end
    LastMsg = text
    if SETTINGS.LogFish and (text:match("obtained") or text:match("Mendapatkan")) then
        local itemName, weight = detectItemData(text)
        if itemName ~= "Unknown" then
            local rarity = detectRarity(text)
            local chance = detectChance(text)
            local player = extractDisplayName(text)
            if player == "Unknown" and text:match("Mendapatkan") then
                player = stripRichText(text):match("^%[Server%]:%s*(.-)%s+Mendapatkan") or
                             stripRichText(text):match("^(.-)%s+Mendapatkan") or "Unknown"
            end
            sendCatchLog({
                Player = player,
                Item = itemName,
                Weight = weight,
                Chance = chance,
                Rarity = rarity
            })
        end
    end
    if SETTINGS.LogEnchant and text:match("rolled a") then
        local p, e, r = detectEnchantData(text)
        if p and e then
            sendEnchant({
                Player = p,
                Enchant = e,
                Rod = r
            })
        end
    end
end

TextChatService.OnIncomingMessage = function(m)
    if m.TextSource then
        return
    end
    if m.Status == Enum.TextChatMessageStatus.Success then
        ProcessText(m.Text)
    end
end
TextChatService.MessageReceived:Connect(function(m)
    if not m.TextSource then
        ProcessText(m.Text)
    end
end)
Players.PlayerAdded:Connect(function(p)
    sendJoinLeave(p, true)
end)
Players.PlayerRemoving:Connect(function(p)
    sendJoinLeave(p, false)
end)
WindUI:Notify({
    Title = "Success",
    Content = "GDEV v32.0 Active!",
    Icon = "zap"
})
