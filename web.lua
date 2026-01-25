-- ====================================================================
-- GDEV NEXUS PUSHER v3.1 - FIX SCANNER & JSON ATTRIBUTES
-- ====================================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [1] CONFIGURATION
local API_ENDPOINT = "https://fish-it.10sarea.my.id/api/items/sync" 

local MANUAL_VARIANTS = {
    "Normal", "1x1x1x1", "Albino", "Arctic Frost", "Big", "Bloodmoon", "Color Burn", 
    "Corrupt", "Disco", "Fairy Dust", "Festive", "Frozen", "Galaxy", 
    "Gemstone", "Ghost", "Giant", "Gold", "Holographic", "Leviathan's Rage", 
    "Lightning", "Midnight", "Noob", "Radioactive", "Sandy", "Shiny", "Stone", "Tiny", "N/A"
}
table.sort(MANUAL_VARIANTS)

-- [2] LOAD UI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- [3] SAFETY CHECK
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (identifyexecutor and request)
if not req then return warn("❌ Executor tidak support HTTP Request!") end

-- [4] VARIABLES
local SelectedItem = nil
local SelectedVariant = "Normal"
local SelectedRarity = "Common"

-- [5] IMAGE SYSTEM
local function getThumbnailURL(assetId)
    local id = tostring(assetId):match("%d+")
    if not id then return nil end
    local apiUrl = "https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&type=Asset&size=420x420&format=Png"
    local s, r = pcall(function() return HttpService:JSONDecode(game:HttpGet(apiUrl)) end)
    if s and r.data and r.data[1] then return r.data[1].imageUrl end
    return nil
end

local function GetItemImage(itemName)
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not ItemsFolder then return "https://placehold.co/400?text=No+Folder" end
    
    local target = ItemsFolder:FindFirstChild(itemName)
    if target then
        local ok, data = pcall(require, target)
        if ok and data.Data then
            local rawId = data.Data.Image or data.Data.Texture or data.Data.TextureId or data.Data.Icon or data.Data.ImageId
            if rawId then return getThumbnailURL(rawId) end
        end
    end
    return "https://placehold.co/400?text=No+Image"
end

-- [6] DATA EXTRACTORS
local function GetItemData(itemName)
    local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")
    local item = ItemsFolder and ItemsFolder:FindFirstChild(itemName)
    if item and item:IsA("ModuleScript") then
        local ok, data = pcall(require, item)
        if ok and data.Data then return data.Data end
    end
    return {}
end

-- [7] ATTRIBUTE BUILDER
-- Rarity dan Variant dimasukkan ke sini agar masuk ke kolom JSON 'attributes'
local function BuildAttributes(itemName, itemType, itemData)
    local attr = {}

    -- WAJIB: Rarity dan Variant masuk ke JSON
    attr["rarity"] = SelectedRarity
    attr["variant"] = SelectedVariant
    
    -- Ambil data tambahan dari ModuleScript jika ada
    if itemType == "Rod" then
        attr["luck_boost"] = itemData.Luck or "0%"
        attr["line_distance"] = itemData.Distance or "0m"
    elseif itemType == "Fish" then
        attr["zone"] = itemData.Zone or "Universal"
    end

    return attr
end

-- [8] SEND TO API FUNCTION
local function PushToAPI()
    if not SelectedItem then 
        WindUI:Notify({ Title = "Error", Content = "Pilih Item Terlebih Dahulu!", Icon = "alert-triangle" })
        return 
    end

    WindUI:Notify({ Title = "Processing", Content = "Mengirim data ke Database...", Icon = "loader" })

    local itemData = GetItemData(SelectedItem)
    local itemType = itemData.Type or "Other" -- Mendeteksi kategori (Fish, Rod, Bait, dll)
    local imageUrl = GetItemImage(SelectedItem)
    
    local payload = {
        nama_manual   = SelectedItem,
        kategori_name = itemType, 
        harga         = math.random(1000, 50000), 
        jumlah        = 1,
        status        = "tersedia",
        gambar_url    = imageUrl,
        
        -- Seluruh data Variant & Rarity dibungkus di sini
        attributes    = BuildAttributes(SelectedItem, itemType, itemData)
    }

    local success, response = pcall(function()
        return req({
            Url = API_ENDPOINT,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success then
        if response.StatusCode == 200 or response.StatusCode == 201 then
            WindUI:Notify({ Title = "Berhasil", Content = SelectedItem .. " terkirim ke JSON attributes!", Icon = "check" })
            print("✅ Data Sent: ", HttpService:JSONEncode(payload))
        else
            WindUI:Notify({ Title = "API Error", Content = "Status: " .. response.StatusCode, Icon = "x-octagon" })
            warn("⚠️ Response: " .. response.Body)
        end
    else
        WindUI:Notify({ Title = "Nexus Offline", Content = "Gagal menghubungi server.", Icon = "wifi-off" })
    end
end

-- [9] UI CONSTRUCTION
local Window = WindUI:CreateWindow({ Title = "GDEV UNIVERSAL PUSHER", Icon = "database", Author = "GDEV" })
local MainTab = Window:Tab({ Title = "Sync Items", Icon = "refresh-cw" })
local Section = MainTab:Section({ Title = "Item Config", Icon = "settings" })

-- Pemindaian ulang folder Items secara akurat
local function ScanItems()
    local list = {}
    local f = ReplicatedStorage:FindFirstChild("Items")
    if f then 
        for _, v in ipairs(f:GetChildren()) do 
            if v:IsA("ModuleScript") then 
                table.insert(list, v.Name) 
            end 
        end 
    end
    table.sort(list)
    return list
end

local allItems = ScanItems()

Section:Dropdown({
    Title = "Pilih Item (Module Detected)",
    Values = allItems,
    Callback = function(val) SelectedItem = val end
})

Section:Dropdown({
    Title = "Pilih Variant",
    Values = MANUAL_VARIANTS,
    Default = "Normal",
    Callback = function(val) SelectedVariant = val end
})

Section:Dropdown({
    Title = "Pilih Rarity",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Default = "Common",
    Callback = function(val) SelectedRarity = val end
})

Section:Button({
    Title = "KIRIM KE DATABASE",
    Desc = "Data Rarity & Variant akan masuk ke kolom JSON.",
    Icon = "upload-cloud",
    Callback = function() PushToAPI() end
})

WindUI:Notify({ Title = "Ready", Content = "Ditemukan " .. #allItems .. " items.", Icon = "check" })