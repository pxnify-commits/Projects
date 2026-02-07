-- ==============================================================================
-- 👑 SABER GOD MODE - MAIN SCRIPT (SEPARATE FUNCTIONS)
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
local eggSpotCoords = Vector3.new(558.31, 184.32, -25.65)
local eggSpotFrame = CFrame.new(558.311035, 184.320892, -25.6451225, -0.659114897, 3.71071751e-09, -0.752042234, -6.06633819e-08, 1, 5.81015982e-08, 0.752042234, 8.39170511e-08, -0.659114897)

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
    print("🔄 Scanne Egg Module...")
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
-- 1. OPTIMIERUNG (FPS & MAP WIPE GETRENNT)
-- ==============================================================================

-- A) TEXTUREN & LICHT (BoostFPS)
if Config.BoostFPS then
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    lighting.FogEnd = 9e9
    lighting.Brightness = 0
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then v:Destroy() end
    end
    
    local function clearTextures()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then
                v:Destroy()
            end
        end
    end
    clearTextures()
    Workspace.DescendantAdded:Connect(function(v)
        if v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then
            task.wait()
            v:Destroy()
        end
    end)
end

-- B) MAP WIPE (Extra Funktion)
if Config.MapWipe then
    print("🔥 MAP WIPE AKTIVIERT...")
    
    -- 1. Plattform bauen
    local safePlat = Instance.new("Part")
    safePlat.Name = "FPS_SafePlatform"
    safePlat.Size = Vector3.new(50, 1, 50)
    safePlat.Position = eggSpotCoords - Vector3.new(0, 3, 0) 
    safePlat.Anchored = true
    safePlat.CanCollide = true
    safePlat.Transparency = 0.5
    safePlat.Color = Color3.fromRGB(0, 255, 100)
    safePlat.Material = Enum.Material.Neon
    safePlat.Parent = Workspace

    -- 2. Teleport zur Sicherheit
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(eggSpotCoords) end

    -- 3. Löschen
    local keepNames = {
        [LocalPlayer.Name] = true, ["Camera"] = true, ["FPS_SafePlatform"] = true,
        ["Gameplay"] = true, ["DungeonStorage"] = true, ["Terrain"] = true
    }
    
    task.wait(1)
    for _, obj in pairs(Workspace:GetChildren()) do
        if not keepNames[obj.Name] and not obj:IsA("Camera") and not Players:GetPlayerFromCharacter(obj) then
            pcall(function() obj:Destroy() end)
        end
    end
    if Workspace.Terrain then Workspace.Terrain:Clear() end
    print("✅ MAP GELÖSCHT")
end

if Config.WhiteScreen then
    local WScreen = Instance.new("ScreenGui", game.CoreGui)
    WScreen.Name = "FPSSaver"
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
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 25)
    Title.BackgroundTransparency = 1
    Title.Text = "📊 PXNIFY STATS"
    Title.TextColor3 = Color3.fromRGB(0, 255, 100)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16

    local function createLabel(name, pos)
        local lbl = Instance.new("TextLabel", MainFrame)
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.Position = UDim2.new(0, 5, 0, pos)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 12
        lbl.Text = name .. ": Loading..."
        return lbl
    end

    local lblEggs = createLabel("🥚 Total Eggs", 30)
    local lblSession = createLabel("🔥 Session Hatched", 50)
    local lblCoins = createLabel("💰 Coins", 70)
    local lblGems = createLabel("💎 Gems", 90)
    local lblCrowns = createLabel("👑 Crowns", 110)
    local lblKills = createLabel("☠️ Kills", 130)
    local lblTime = createLabel("⏳ AFK Time", 150)

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local guiPath = LocalPlayer.PlayerGui.MainGui.OtherFrames.Stats.Frame
                local eggs = guiPath:FindFirstChild("EggsOpened") and guiPath.EggsOpened:FindFirstChild("Amount") and guiPath.EggsOpened.Amount.Text or "0"
                local coins = guiPath:FindFirstChild("TotalCoins") and guiPath.TotalCoins.Text or "0"
                local crowns = guiPath:FindFirstChild("TotalCrowns") and guiPath.TotalCrowns.Text or "0"
                local kills = guiPath:FindFirstChild("TotalKills") and guiPath.TotalKills.Text or "0"
                local gems = guiPath:FindFirstChild("TotalGems") and guiPath.TotalGems.Text or "0"

                lblEggs.Text = "🥚 Total Eggs: " .. eggs
                lblSession.Text = "🔥 Session Hatched: " .. sessionEggs
                lblCoins.Text = "💰 Coins: " .. coins
                lblGems.Text = "💎 Gems: " .. gems
                lblCrowns.Text = "👑 Crowns: " .. crowns
                lblKills.Text = "☠️ Kills: " .. kills
                
                local diff = os.time() - startTime
                local hours = math.floor(diff / 3600)
                local minutes = math.floor((diff % 3600) / 60)
                local seconds = diff % 60
                lblTime.Text = string.format("⏳ AFK Time: %02d:%02d:%02d", hours, minutes, seconds)
            end)
        end
    end)
end
CreateStatsHUD()

-- ==============================================================================
-- 3. LOGIC LOOPS (HATCH, TP 30s, FARM, PICKUP)
-- ==============================================================================

-- AUTO HATCH (Kaufen)
task.spawn(function()
    while true do
        if Config.AutoHatch and targetEggName ~= "" then
            pcall(function()
                RS.Events.UIAction:FireServer("BuyEgg", targetEggName)
                sessionEggs = sessionEggs + 1
            end)
        end
        task.wait(Config.HatchDelay or 0.3)
    end
end)

-- AUTO TP (Nur alle 30 Sekunden!)
task.spawn(function()
    while true do
        if Config.AutoHatch then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = eggSpotFrame
                    hrp.Velocity = Vector3.new(0,0,0)
                end
            end)
        end
        -- Hier ist der 30 Sekunden Cooldown
        task.wait(30)
    end
end)

-- SWING
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoSwing then
            RS.Events.SwingSaber:FireServer("Slash1")
            RS.Events.SwingSaber:FireServer("Slash2")
            RS.Events.SwingSaber:FireServer("Slash3")
        end
    end
end)

-- SELL
task.spawn(function()
    while task.wait(1) do
        if Config.AutoSell then RS.Events.SellStrength:FireServer() end
    end
end)

-- PICKUP (HEART TELEPORT)
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
-- 4. AUTO BUY & DUNGEON
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

local function GetDungeonTarget()
    local dId = LocalPlayer:GetAttribute("DungeonId")
    if not dId then return nil end
    local dFolder = Workspace.DungeonStorage:FindFirstChild(tostring(dId))
    if not dFolder or not dFolder:FindFirstChild("Important") then return nil end
    local spawners = {"PurpleBossEnemySpawner", "PurpleEnemySpawner", "RedEnemySpawner", "BlueEnemySpawner", "GreenEnemySpawner"}
    for _, sName in pairs(spawners) do
        for _, folder in pairs(dFolder.Important:GetChildren()) do
            if folder.Name == sName then
                for _, bot in pairs(folder:GetChildren()) do
                    local hp = bot:GetAttribute("Health") or (bot:FindFirstChild("Humanoid") and bot.Humanoid.Health) or 0
                    if hp > 0 then return bot.PrimaryPart or bot:FindFirstChild("HumanoidRootPart") end
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoDungeon then
            local inDungeon = LocalPlayer:GetAttribute("InDungeon")
            if not inDungeon then
                pcall(function()
                    local Info = require(RS.Modules.DungeonInfo)
                    local dName = Config.DungeonName
                    local dDiff = 1 
                    for i,v in pairs(Info.Difficulties) do if v.Name == Config.Difficulty then dDiff = i end end
                    if dName == "" then for name, _ in pairs(Info.Dungeons) do dName = name break end end
                    RS.Events.UIAction:FireServer("DungeonGroupAction", "Create", "Public", dName, dDiff)
                    task.wait(1)
                    RS.Events.UIAction:FireServer("DungeonGroupAction", "Start")
                end)
            else
                local target = GetDungeonTarget()
                if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, Config.FarmHeight, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
                    hrp.Velocity = Vector3.new(0,0,0)
                    RS.Events.UIAction:FireServer("BuyDungeonUpgrade", "DungeonDamage")
                end
            end
        end
    end
end)

-- ==============================================================================
-- 5. MERCHANT
-- ==============================================================================
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

print("✅ SCRIPT UPDATED: 30S TP + MAP WIPE FUNCTION")
