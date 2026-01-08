--[[ 
    FISCH V8 - HYBRID SPAM CONTROL (WINDUI)
    Logic: User Defined Speed. 
    If Delay > 0 = Wait. 
    If Delay 0 = NO WAIT (Pure Speed).
]] -- 1. SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Global Config (Default Setup untuk Fast Catch)
_G.CastDelay = 2.9 -- Waktu tunggu Alert Ikan (User Setting)
_G.ReelDelay = 0.0 -- Jeda antar lemparan (User Setting)

-- 2. REMOTE FINDER (AUTO)
local function GetNetFolder()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local index = packages:FindFirstChild("_Index")
        if index then
            for _, child in ipairs(index:GetChildren()) do
                if child.Name:match("sleitnick_net") then
                    return child:FindFirstChild("net")
                end
            end
        end
    end
    return nil
end

local NetFolder = GetNetFolder() or
                      ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local Remotes = {
    Charge = NetFolder:WaitForChild("RF/ChargeFishingRod"),
    RequestMini = NetFolder:WaitForChild("RF/RequestFishingMinigameStarted"),
    Finish = NetFolder:WaitForChild("RE/FishingCompleted"),
    Equip = NetFolder:WaitForChild("RE/EquipToolFromHotbar"),
    Cancel = NetFolder:WaitForChild("RF/CancelFishingInputs")
}

-- 3. LOGIC HYBRID SPAM
local SpamEnabled = false

local function StartHybridSpam(state)
    SpamEnabled = state
    if state then
        -- Equip Rod
        pcall(function()
            Remotes.Equip:FireServer(1)
        end)
        LocalPlayer:SetAttribute("Loading", nil)

        task.spawn(function()
            task.wait(0.5) -- Safety start

            while SpamEnabled do
                -- [[ FASE 1: CASTING (NON-BLOCKING) ]]
                -- Kita gunakan thread spawn agar pengiriman paket Cast tidak menahan kode di bawahnya
                task.spawn(function()
                    local time = workspace:GetServerTimeNow()
                    pcall(function()
                        Remotes.Cancel:InvokeServer()
                    end)
                    pcall(function()
                        Remotes.Charge:InvokeServer(time)
                    end)
                    pcall(function()
                        Remotes.RequestMini:InvokeServer(-1, 0.999)
                    end)
                end)

                -- [[ FASE 2: CAST DELAY (TITIK TEMU ALERT) ]]
                -- Jika kamu set 0, dia LANGSUNG lanjut ke Finish (Tidak nunggu ikan).
                -- Jika kamu set 2.9, dia diam pas 2.9 detik nunggu ikan makan.
                if _G.CastDelay > 0 then
                    task.wait(_G.CastDelay)
                end

                -- [[ FASE 3: REEL / FINISH ]]
                pcall(function()
                    Remotes.Finish:FireServer()
                end)

                -- [[ FASE 4: REEL DELAY (INTERVAL) ]]
                -- Jika kamu set 0, dia LANGSUNG ulang loop (Spam).
                if _G.ReelDelay > 0 then
                    task.wait(_G.ReelDelay)
                else
                    -- SAFETY: Jika kedua delay 0, kita wajib tunggu 1 frame (Heartbeat)
                    -- Kalau tidak, game akan Freeze/Crash karena loop infinite.
                    if _G.CastDelay <= 0 then
                        RunService.Heartbeat:Wait()
                    end
                end
            end
        end)
    else
        LocalPlayer:SetAttribute("Loading", false)
    end
end

-- 4. UI SETUP (WINDUI)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Fisch Hybrid V8",
    Icon = "zap",
    Author = "ZeroDelay",
    Folder = "FischHybrid",
    Transparent = true
})

Window:EditOpenButton({
    Title = "Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

local Tab = Window:Tab({
    Title = "Fishing",
    Icon = "fish"
})
local MainSec = Tab:Section({
    Title = "Blatant Feature ",
    Icon = "sliders"
})

-- UI COMPONENTS

MainSec:Toggle({
    Title = "Enable Hybrid Spam",
    Desc = "Spam cast dengan delay manual",
    Value = false,
    Callback = function(val)
        StartHybridSpam(val)
    end
})

MainSec:Input({
    Title = "Cast Delay (Wait Alert)",
    Desc = "0 = Instan | 2.9 = Tunggu Ikan",
    Value = tostring(_G.CastDelay),
    InputIcon = "clock",
    Placeholder = "Seconds...",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            _G.CastDelay = num
        end
    end
})

MainSec:Input({
    Title = "Reel Delay (Interval)",
    Desc = "0 = Spam Tanpa Henti",
    Value = tostring(_G.ReelDelay),
    InputIcon = "refresh-cw",
    Placeholder = "Seconds...",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            _G.ReelDelay = num
        end
    end
})

WindUI:Notify({
    Title = "Hybrid V8 Ready",
    Content = "Full control. 0 = Zero Delay.",
    Icon = "check",
    Duration = 5
})
