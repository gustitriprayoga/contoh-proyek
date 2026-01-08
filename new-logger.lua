-- ====================================================================
-- GDEV LOGGER v28.0 - STRICT COMBINATION (GEMSTONE + RUBY ONLY)
-- ====================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or
                (identifyexecutor and request)

-- [1] LOAD WINDUI LIBRARY
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [2] CONFIG DATA
local IMAGE_EMBED =
    "https://cdn.discordapp.com/attachments/1449462744028811499/1449987836756627547/f7f9b6065f0db9b67dff28c80a17acd4_720w_1.gif"

-- [[ USER MAPPING ]] --
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

    FocusFilterEnabled = true, -- WAJIB TRUE AGAR FITUR STRICT JALAN
    LogEverything = false
}

local WEBHOOK_NAME = "10s Area"
local WEBHOOK_AVATAR = "https://cdn.discordapp.com/attachments/1452251463337377902/1456009509632737417/GDEV_New.png"

local GlobalData = {
    ListFish = {},
    ListStones = {},
    ListMutations = {},

    FocusFish = {},
    FocusMutations = {},
    FocusStones = {}
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

local COLOR_MAP = {
    ["179,115,248"] = "Epic",
    ["#B373F8"] = "Epic",
    ["255,185,43"] = "Legendary",
    ["#FFB92B"] = "Legendary",
    ["255,25,25"] = "Mythic",
    ["#FF1919"] = "Mythic",
    ["24,255,152"] = "Secret",
    ["#18FF98"] = "Secret"
}

-- ====================================================================
-- [3] COMPREHENSIVE DATABASE SCANNER
-- ====================================================================
local function ScanAllDatabases()
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    local fishList, stoneList = {}, {}

    if ItemsFolder then
        for i, item in ipairs(ItemsFolder:GetChildren()) do
            local ok, module = pcall(require, item)
            if ok and module.Data and module.Data.Name then
                local d = module.Data
                local n = d.Name
                if d.Type == "Fish" then
                    table.insert(fishList, n)
                elseif n:match("Stone") or n:match("Enchant") or n:match("Relic") or d.Type == "Stone" then
                    table.insert(stoneList, n)
                end
            end
            if i % 100 == 0 then
                task.wait()
            end
        end
    end

    local mutationList = {}
    local VariantsFolder = ReplicatedStorage:FindFirstChild("Variants")
    if VariantsFolder then
        for i, variantModule in pairs(VariantsFolder:GetChildren()) do
            local ok, variantData = pcall(require, variantModule)
            if ok and variantData.Data and variantData.Data.Name then
                table.insert(mutationList, variantData.Data.Name)
            end
            if i % 50 == 0 then
                task.wait()
            end
        end
    end

    table.sort(fishList)
    table.sort(stoneList)
    table.sort(mutationList)
    return fishList, stoneList, mutationList
end

-- ====================================================================
-- [4] LOGIC FUNCTIONS
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
    if USER_MAPPING[playerName] then
        return "<@" .. USER_MAPPING[playerName] .. ">"
    end
    return ""
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
            description = "Webhook berfungsi normal.",
            color = 0x2ECC71,
            footer = {
                text = "10s Area • System"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
    WindUI:Notify({
        Title = "Sent",
        Content = "Test sent!",
        Icon = "send"
    })
end

local function stripRichText(t)
    return t:gsub("<.->", "")
end

local function extractDisplayName(text)
    local clean = stripRichText(text)
    return clean:match("^%[Server%]:%s*(.-)%s*obtained") or clean:match("^(.-)%s*obtained") or "Unknown"
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
    local itemName, itemWeight = "Unknown", "N/A"

    local nameWithWeight = clean:match("obtained%s+a[n]?%s+(.+)%s+%((.+)%)")
    if nameWithWeight then
        itemName, itemWeight = clean:match("obtained%s+a[n]?%s+(.+)%s+%((.+)%)")
        itemName = itemName:gsub("%s+with.*", "")
        return itemName, itemWeight
    end

    local nameOnly = clean:match("obtained%s+a[n]?%s+(.+)%s+with")
    if nameOnly then
        return nameOnly, "N/A"
    end

    local fallbackName = clean:match("obtained%s+a[n]?%s+(.+)")
    if fallbackName then
        return fallbackName:gsub("%s+$", ""), "N/A"
    end

    return itemName, itemWeight
end

local function detectEnchantData(text)
    local clean = stripRichText(text)
    return clean:match("^%[Server%]:%s*(.-)%s+rolled%s+a%s+(.-)%s+on%s+their%s+(.-)!$")
end

-- ====================================================================
-- [5] SENDING LOGIC (STRICT COMBINATION MODE)
-- ====================================================================

-- Fungsi Pengecekan Utama
local function IsItemFocused(itemName)
    if not SETTINGS.FocusFilterEnabled then
        return false
    end

    -- 1. CEK BATU (Independent)
    -- Batu selalu dicek pertama dan tidak peduli dengan filter Ikan/Mutasi
    for target, _ in pairs(GlobalData.FocusStones) do
        if string.find(itemName, target) then
            return true -- Jika cocok dengan list batu, LANGSUNG TERIMA
        end
    end

    -- 2. LOGIKA KOMBINASI IKAN & MUTASI
    local fishSelected = false
    local fishMatched = false

    local mutationSelected = false
    local mutationMatched = false

    -- Cek apakah user memilih Ikan
    for target, _ in pairs(GlobalData.FocusFish) do
        fishSelected = true
        if string.find(itemName, target) then
            fishMatched = true
            break
        end
    end

    -- Cek apakah user memilih Mutasi
    for target, _ in pairs(GlobalData.FocusMutations) do
        mutationSelected = true
        if string.find(itemName, target) then
            mutationMatched = true
            break
        end
    end

    -- >> LOGIKA KEPUTUSAN (STRICT AND) << --
    if fishSelected and mutationSelected then
        -- Jika user memilih Ikan DAN Mutasi, keduanya HARUS cocok
        return fishMatched and mutationMatched

    elseif fishSelected then
        -- Jika user HANYA memilih Ikan, cukup cocokkan Ikan
        return fishMatched

    elseif mutationSelected then
        -- Jika user HANYA memilih Mutasi, cukup cocokkan Mutasi
        return mutationMatched
    end

    return false
end

local function sendCatchLog(data)
    local rarityCfg = RARITY_CONFIG[data.Rarity] or RARITY_CONFIG["Unknown"]
    local shouldSend = false
    local embedColor = rarityCfg.Color
    local titleText = rarityCfg.Icon .. " " .. data.Rarity .. " | Berhasil Di Dapatkan "

    -- 1. Priority Check (Strict Focus)
    if IsItemFocused(data.Item) then
        shouldSend = true
        embedColor = 0xFF0040
        titleText = "🚨 TARGET SPESIFIK DITEMUKAN! 🚨"

        -- 2. Fallback ke Rarity biasa (Jika Focus Filter tidak menyala atau tidak cocok, tapi rarity dinyalakan)
        -- Note: Jika FocusFilterEnabled = true, maka IsItemFocused sudah menangani logika.
        -- Jika user ingin "Hanya Focus", matikan toggle rarity di UI.
    elseif rarityCfg.Enabled then
        shouldSend = true

    elseif SETTINGS.LogEverything then
        shouldSend = true
        titleText = "❓ LOG (Generic)"
    end

    if shouldSend then
        local userTag = GetMentionContent(data.Player)
        local tagString = (userTag ~= "") and (userTag .. "\n") or ""

        send(SETTINGS.WebhookCatch, {
            username = WEBHOOK_NAME,
            avatar_url = WEBHOOK_AVATAR,
            embeds = {{
                title = titleText,
                description = tagString .. "Selamat Kamu Berhasil Mendapatkan : **" .. data.Item .. "**",
                color = embedColor,
                fields = {{
                    name = "❯ 👤 Player :",
                    value = "```" .. data.Player .. "```"
                }, {
                    name = "❯ 🐟 Item/Fish :",
                    value = "```" .. data.Item .. "```"
                }, {
                    name = "❯ ⚖️ Weight :",
                    value = "```" .. data.Weight .. "```"
                }, {
                    name = "❯ 🎲 Chance :",
                    value = "```1 in " .. data.Chance .. "```"
                }},
                image = {
                    url = IMAGE_EMBED
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
    local tagString = (userTag ~= "") and (userTag .. "\n") or ""

    send(SETTINGS.WebhookEnchant, {
        username = WEBHOOK_NAME,
        embeds = {{
            title = "✨ ENCHANT ROLLED ✨",
            description = tagString .. "**" .. data.Player .. "** Telah Mendapatkan Enchant Baru **" .. data.Enchant ..
                "**",
            color = 0xD000FF,
            fields = {{
                name = "❯👤 Player :",
                value = "```" .. data.Player .. "```"
            }, {
                name = "❯🔮 Enchant :",
                value = "```" .. data.Enchant .. "```"
            }, {
                name = "❯🎣 Rod :",
                value = "```" .. data.Rod .. "```"
            }},
            image = {
                url = IMAGE_EMBED
            },
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

    send(SETTINGS.WebhookJoinLeave, {
        username = WEBHOOK_NAME,
        embeds = {{
            title = title,
            description = "`" .. player.Name .. "` (" .. player.DisplayName .. ")",
            color = color,
            fields = {{
                name = "🆔 User ID",
                value = "`" .. player.UserId .. "`",
                inline = true
            }, {
                name = "📅 Account Age",
                value = player.AccountAge .. " days",
                inline = true
            }},
            imgage = {
                url = IMAGE_EMBED
            },
            footer = {
                text = "Server Join/Leave Logger"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
end

-- ====================================================================
-- [6] UI CONSTRUCTION (WINDUI)
-- ====================================================================
local Window = WindUI:CreateWindow({
    Title = "GDEV LOGGER v28.0",
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
    Title = "v28.0 Strict",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 0
})

local TrackerTab = Window:Tab({
    Title = "Tracker",
    Icon = "crosshair"
})
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})
local InfoTab = Window:Tab({
    Title = "Information",
    Icon = "info"
})

local FocusSec = TrackerTab:Section({
    Title = "Target Database",
    Icon = "database"
})

-- [[ TOMBOL ON/OFF TARGET FILTER ]] --
FocusSec:Toggle({
    Title = "Enable Target Filter",
    Desc = "ON = Harus sesuai pilihan dropdown. OFF = Abaikan dropdown.",
    Value = SETTINGS.FocusFilterEnabled,
    Callback = function(v)
        SETTINGS.FocusFilterEnabled = v
    end
})

FocusSec:Button({
    Title = "Reset All Selections",
    Icon = "trash",
    Callback = function()
        GlobalData.FocusFish = {}
        GlobalData.FocusMutations = {}
        GlobalData.FocusStones = {}
        WindUI:Notify({
            Title = "Reset",
            Content = "Selection cleared!",
            Icon = "check"
        })
    end
})

-- DROPDOWN 1: FISH
local FishDropdown = FocusSec:Dropdown({
    Title = "Search Fish (Kombinasi)",
    Desc = "Pilih Ikan (Contoh: Ruby).",
    Values = {"Scanning..."},
    Multi = true,
    Callback = function(list)
        GlobalData.FocusFish = {}
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

-- DROPDOWN 2: MUTATIONS
local MutationDropdown = FocusSec:Dropdown({
    Title = "Search Mutations (Kombinasi)",
    Desc = "Pilih Mutasi (Contoh: Gemstone).",
    Values = {"Scanning..."},
    Multi = true,
    Callback = function(list)
        GlobalData.FocusMutations = {}
        if type(list) == "string" then
            list = {list}
        end
        for _, name in pairs(list) do
            if name ~= "Scanning..." then
                GlobalData.FocusMutations[name] = true
            end
        end
    end
})

-- DROPDOWN 3: STONES
local StoneDropdown = FocusSec:Dropdown({
    Title = "Search Stones (Independen)",
    Desc = "Pilih Batu/Item (Langsung kirim jika cocok).",
    Values = {"Scanning..."},
    Multi = true,
    Callback = function(list)
        GlobalData.FocusStones = {}
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

local ToggleSec = SettingsTab:Section({
    Title = "Main Toggles",
    Icon = "power"
})
ToggleSec:Toggle({
    Title = "Enable Catch Log",
    Value = SETTINGS.LogFish,
    Callback = function(v)
        SETTINGS.LogFish = v
    end
})
ToggleSec:Toggle({
    Title = "Enable Enchant Log",
    Value = SETTINGS.LogEnchant,
    Callback = function(v)
        SETTINGS.LogEnchant = v
    end
})
ToggleSec:Toggle({
    Title = "Enable Join/Leave Log",
    Value = SETTINGS.LogJoinLeave,
    Callback = function(v)
        SETTINGS.LogJoinLeave = v
    end
})

local WebhookSec = SettingsTab:Section({
    Title = "Webhook Configuration",
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

local InfoSec = InfoTab:Section({
    Title = "About Script",
    Icon = "file-text"
})
InfoSec:Paragraph({
    Title = "GDEV Logger",
    Desc = "Versi: 28.0 (Strict Combo)\nDeveloper: 10s Area"
})

InfoSec:Button({
    Title = "Join Discord",
    Icon = "message-circle",
    Callback = function()
        setclipboard("https://discord.gg/yourlink")
        WindUI:Notify({
            Title = "Copied",
            Content = "Discord Link copied!",
            Icon = "copy"
        })
    end
})

-- >> SCANNER BACKGROUND <<
task.spawn(function()
    local fish, stones, mutations = ScanAllDatabases()
    GlobalData.ListFish = fish
    GlobalData.ListStones = stones
    GlobalData.ListMutations = mutations

    pcall(function()
        if #fish > 0 then
            if FishDropdown.SetValues then
                FishDropdown:SetValues(fish)
            elseif FishDropdown.Refresh then
                FishDropdown:Refresh(fish)
            end
        end
        if #mutations > 0 then
            if MutationDropdown.SetValues then
                MutationDropdown:SetValues(mutations)
            elseif MutationDropdown.Refresh then
                MutationDropdown:Refresh(mutations)
            end
        end
        if #stones > 0 then
            if StoneDropdown.SetValues then
                StoneDropdown:SetValues(stones)
            elseif StoneDropdown.Refresh then
                StoneDropdown:Refresh(stones)
            end
        else
            if StoneDropdown.SetValues then
                StoneDropdown:SetValues({"No Stones Found"})
            end
        end
    end)
    WindUI:Notify({
        Title = "System Ready",
        Content = "Strict Combination Logic Active.",
        Icon = "check"
    })
end)

-- ====================================================================
-- [7] LISTENERS
-- ====================================================================
local LastMsg = ""
local function ProcessText(text)
    if text == LastMsg then
        return
    end
    LastMsg = text

    if SETTINGS.LogFish and text:match("obtained") then
        if text:match("%[Server%]") or text:match("obtained a") then
            local itemName, weight = detectItemData(text)
            local rarity = detectRarity(text)
            local chance = detectChance(text)
            local player = extractDisplayName(text)

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

TextChatService.OnIncomingMessage = function(message)
    if message.TextSource then
        return
    end
    if message.Status == Enum.TextChatMessageStatus.Success then
        ProcessText(message.Text)
    end
end
TextChatService.MessageReceived:Connect(function(msg)
    if not msg.TextSource then
        ProcessText(msg.Text)
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
    Content = "GDEV v28.0 Loaded!",
    Icon = "zap"
})
