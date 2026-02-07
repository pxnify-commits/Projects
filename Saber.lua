-- ==============================================================================
-- 👑 SABER GOD MODE - MAIN SCRIPT (REJOIN REQUIRED FOR FIX)
-- ==============================================================================

if not getgenv().Config then
    warn("Config nicht gefunden! Lade Standard...")
    getgenv().Config = {
        BoostFPS = true, MapWipe = false, WhiteScreen = false, AutoDungeon = false,
        DungeonName = "", Difficulty = "Easy", FarmHeight = 8,
        AutoSwing = true, AutoSell = true, AutoPickup = true, AutoBuy = true,
        AutoHatch = false, SelectEgg = "Latest", HatchDelay = 0.5,
        Priorities = {Sabers=true, DNA=true, Classes=true, Auras=true, PetAuras=true, BossHits=true},
        AutoMerchant = false, MerchantItems = {}
    }
end

local Config = getgenv().Config

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local startTime = os.time()
local sessionEggs = 0 
-- Deine Koordinaten:
local eggSpotFrame = CFrame.new(558.31, 184.32, -25.65) 
local eggSpotVector = Vector3.new(558.31, 184.32, -25.65)

-- ==============================================================================
-- 🛠️ ANTI-AFK
-- ==============================================================================
if getconnections then
    for _, v in pairs(getconnections(LocalPlayer.Idled)) do v:Disable() end
else
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end)
end

-- ==============================================================================
-- 🥚 EGG SELECTOR
-- ==============================================================================
local targetEggName = ""
local function ScanAndSelectEgg()
    local EggList = {}
    local success, PetShopInfo = pcall(function() return require(RS.Modules.PetsInfo:WaitForChild("PetShopInfo", 10)) end)

    if success and PetShopInfo then
        local function scan(t)
            for k, v in pairs(t) do
                if type(v) == "table" then
                    if v.EggName then
                        if not table.find(EggList, v.EggName) then table.insert(EggList, v.EggName) end
                    else scan(v) end
                end
            end
        end
        scan(PetShopInfo)
    end

    local selection = Config.SelectEgg
    if selection == "Latest" then
        if #EggList > 0 then targetEggName = EggList[#EggList] end
    elseif selection == "First" then
        if #EggList >= 1 then targetEggName = EggList[1] end
    elseif selection == "Second" then
        if #EggList >= 2 then targetEggName = EggList[2] else targetEggName = EggList[1] end
    elseif selection == "Third" then
        if #EggList >= 3 then targetEggName = EggList[3] else targetEggName = EggList[1] end
    elseif selection == "Fourth" then
        if #EggList >= 4 then targetEggName = EggList[4] else targetEggName = EggList[1] end
    else
        if table.find(EggList, selection) then targetEggName = selection else if #EggList > 0 then targetEggName = EggList[#EggList] end end
    end
    print("✅ Ziel-Ei: " .. targetEggName)
end
task.spawn(ScanAndSelectEgg)

-- ==============================================================================
-- 1. AGGRESSIVE MAP WIPE & PLATFORM
-- ==============================================================================
if Config.MapWipe then
    -- Plattform erstellen (bleibt für immer da)
    local safePlat = Instance.new("Part")
    safePlat.Name = "FPS_SafePlatform_Persistent"
    safePlat.Size = Vector3.new(50, 1, 50)
    safePlat.Position = eggSpotVector - Vector3.new(0, 3, 0)
    safePlat.Anchored = true
    safePlat.CanCollide = true
    safePlat.Material = Enum.Material.ForceField
    safePlat.Color = Color3.new(0,0,0)
    safePlat.Parent = Workspace

    -- Whitelist: Was darf NICHT gelöscht werden?
    local keepNames = {
        [LocalPlayer.Name] = true,
        ["Camera"] = true,
        ["FPS_SafePlatform_Persistent"] = true,
        ["Gameplay"] = true,       -- Coins/Herzen
        ["DungeonStorage"] = true, -- Dungeons
        ["Terrain"] = true
    }

    -- ACTIVE CLEANER LOOP (Löscht alle 5 Sekunden ALLES was neu spawnt)
    task.spawn(function()
        while true do
            if Config.MapWipe then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if not keepNames[obj.Name] and not obj:IsA("Camera") and not Players:GetPlayerFromCharacter(obj) then
                        pcall(function() obj:Destroy() end)
                    end
                end
                if Workspace.Terrain then Workspace.Terrain:Clear() end
            end
            task.wait(5) -- Check alle 5 Sekunden
        end
    end)
end

if Config.BoostFPS and not Config.MapWipe then
    -- Nur Texturen löschen (Fallback)
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("BlurEffect") then v:Destroy() end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then v:Destroy() end
    end
end

if Config.WhiteScreen then
    local WScreen = Instance.new("ScreenGui", game.CoreGui)
    local Frame = Instance.new("Frame", WScreen)
    Frame.Size = UDim2.new(1,0,1,0)
    Frame.BackgroundColor3 = Color3.new(1,1,1)
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then WScreen.Enabled = not WScreen.Enabled end
    end)
end

-- ==============================================================================
-- 2. STATS HUD
-- ==============================================================================
local function CreateStatsHUD()
    if game.CoreGui:FindFirstChild("SaberGodHUD") then return end
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "SaberGodHUD"
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 250, 0, 180) 
    MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    
    local labels = {}
    local function addLabel(text, y)
        local l = Instance.new("TextLabel", MainFrame)
        l.Size = UDim2.new(1, -10, 0, 20)
        l.Position = UDim2.new(0, 5, 0, y)
        l.BackgroundTransparency = 1
        l.TextColor3 = Color3.new(1,1,1)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text
        return l
    end
    
    labels.eggs = addLabel("🥚 Eggs: 0", 30)
    labels.session = addLabel("🔥 Session: 0", 50)
    labels.coins = addLabel("💰 Coins: 0", 70)
    labels.time = addLabel("⏳ Time: 00:00:00", 150)

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local gp = LocalPlayer.PlayerGui.MainGui.OtherFrames.Stats.Frame
                labels.eggs.Text = "🥚 Total: " .. (gp.EggsOpened.Amount.Text or "0")
                labels.session.Text = "🔥 Session: " .. sessionEggs
                labels.coins.Text = "💰 Coins: " .. (gp.TotalCoins.Text or "0")
                
                local d = os.time() - startTime
                labels.time.Text = string.format("⏳ %02d:%02d:%02d", math.floor(d/3600), math.floor((d%3600)/60), d%60)
            end)
        end
    end)
end
CreateStatsHUD()

-- ==============================================================================
-- 3. LOGIC LOOPS (STRICTLY SEPARATED)
-- ==============================================================================

-- [A] AUTO HATCH (NUR KAUFEN - KEIN TP)
task.spawn(function()
    while true do
        if Config.AutoHatch and targetEggName ~= "" then
            pcall(function()
                RS.Events.UIAction:FireServer("BuyEgg", targetEggName)
                sessionEggs = sessionEggs + 1
            end)
        end
        -- Hier passiert der Kauf. KEIN Teleport hier.
        task.wait(Config.HatchDelay or 0.3)
    end
end)

-- [B] AUTO TP (NUR ALLE 30 SEKUNDEN)
task.spawn(function()
    while true do
        if Config.AutoHatch then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Einmaliger Teleport
                    hrp.CFrame = eggSpotFrame
                    hrp.Velocity = Vector3.new(0,0,0)
                    print("🔄 30s Check: Teleport zum Egg Spot")
                end
            end)
        end
        -- Hier ist der harte Cooldown. Das Script KANN gar nicht öfter teleportieren.
        task.wait(30)
    end
end)

-- SWING
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoSwing then RS.Events.SwingSaber:FireServer("Slash1") end
    end
end)

-- SELL
task.spawn(function()
    while task.wait(1) do
        if Config.AutoSell then RS.Events.SellStrength:FireServer() end
    end
end)

-- PICKUP
local heartsNearPlayer = {}
local currencyRemote = RS.Events:FindFirstChild("CollectCurrencyPickup")
local currencyHolder = Workspace.Gameplay:FindFirstChild("CurrencyPickup") and Workspace.Gameplay.CurrencyPickup:FindFirstChild("CurrencyHolder")

if currencyRemote and currencyHolder then
    RunService.Heartbeat:Connect(function()
        if not Config.AutoPickup then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            heartsNearPlayer = {} 
            for _, item in pairs(currencyHolder:GetChildren()) do
                if item.Name == "Heart" then
                    local part = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")))
                    if part then
                        part.CanCollide = false
                        part.Velocity = Vector3.new(0,0,0)
                        part.RotVelocity = Vector3.new(0,0,0)
                        part.CFrame = root.CFrame
                        table.insert(heartsNearPlayer, item)
                    end
                end
            end
        end
    end)
    task.spawn(function()
        while task.wait(0.1) do
            if Config.AutoPickup and #heartsNearPlayer > 0 then
                pcall(function() currencyRemote:FireServer(heartsNearPlayer) end)
            end
        end
    end)
end

-- ==============================================================================
-- 4. AUTO BUY & MERCHANT
-- ==============================================================================
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoBuy then
            local P = Config.Priorities
            if P.Auras then RS.Events.UIAction:FireServer("BuyAllAuras") end
            if P.PetAuras then RS.Events.UIAction:FireServer("BuyAllPetAuras") end
            if P.BossHits then RS.Events.UIAction:FireServer("BuyAllBossHits") end
            if P.Sabers then RS.Events.UIAction:FireServer("BuyAllWeapons") end
            if P.DNA then RS.Events.UIAction:FireServer("BuyAllDNAs") end
            if P.Classes then 
                pcall(function()
                    local classes = require(RS.Modules.ItemInfo.Classes)
                    for name, _ in pairs(classes) do RS.Events.UIAction:FireServer("BuyClass", name) end
                end)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if Config.AutoMerchant then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local mainGui = playerGui:FindFirstChild("MainGui")
                local merchantFrame = mainGui and mainGui:FindFirstChild("OtherFrames") and mainGui.OtherFrames:FindFirstChild("EventMerchant")
                if merchantFrame then
                    if not merchantFrame.Visible then merchantFrame.Visible = true end
                    merchantFrame.Position = UDim2.new(10, 0, 10, 0)
                    task.wait(0.5)
                    local listingsFolder = merchantFrame:FindFirstChild("Listings")
                    if listingsFolder then
                        for i = 1, 6 do
                            local listing = listingsFolder:FindFirstChild("Listing" .. i)
                            if listing then
                                local success, imgLabel = pcall(function() return listing.ItemFrame.Holder.Item.ImageLabel end)
                                if success and imgLabel then
                                    local imgId = imgLabel.Image
                                    for _, targetID in pairs(Config.MerchantItems) do
                                        if imgId == targetID then
                                            local serverTime = workspace:GetServerTimeNow()
                                            local currentTimestamp = math.floor(serverTime / 1800) * 1800
                                            local timesToTry = {currentTimestamp, currentTimestamp - 1800, currentTimestamp + 1800}
                                            for _, timeTry in ipairs(timesToTry) do
                                                local args = {[1] = "EventMerchantBuyItem", [2] = i, [3] = timeTry}
                                                RS.Events.UIAction:FireServer(unpack(args))
                                            end
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

print("✅ SCRIPT UPDATED: TP ISOLATED & MAP WIPER ACTIVE")
