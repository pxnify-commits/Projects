-- ==============================================================================
-- 👑 SABER GOD MODE - MAIN SCRIPT (FINAL VERSION WITH EGGS)
-- ==============================================================================

if not getgenv().Config then
    warn("Config nicht gefunden! Lade Standard...")
    getgenv().Config = {
        BoostFPS = true, WhiteScreen = false, AutoDungeon = false,
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
local sessionEggs = 0 -- Zähler für diese Sitzung

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
-- 🥚 EGG SCANNER LOGIC
-- ==============================================================================
local targetEggName = ""
local function ScanForEggs()
    local EggList = {}
    local success, PetShopInfo = pcall(function()
        return require(RS.Modules.PetsInfo:WaitForChild("PetShopInfo", 10))
    end)

    if success and PetShopInfo then
        local function scan(t)
            for k, v in pairs(t) do
                if type(v) == "table" then
                    if v.EggName then
                        if not table.find(EggList, v.EggName) then
                            table.insert(EggList, v.EggName)
                        end
                    else
                        scan(v)
                    end
                end
            end
        end
        scan(PetShopInfo)
    end

    -- Logik für "Latest"
    if Config.SelectEgg == "Latest" then
        if #EggList > 0 then
            targetEggName = EggList[#EggList] -- Das letzte in der Liste
            print("🥚 'Latest' ausgewählt: " .. targetEggName)
        else
            targetEggName = "Basic Egg" -- Fallback
        end
    else
        targetEggName = Config.SelectEgg
    end
end
ScanForEggs() -- Einmal beim Start ausführen

-- ==============================================================================
-- 1. OPTIMIERUNG
-- ==============================================================================
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
-- 2. STATS HUD (INKL. HATCH COUNTER)
-- ==============================================================================
local function CreateStatsHUD()
    if game.CoreGui:FindFirstChild("SaberGodHUD") then return end
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "SaberGodHUD"

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 250, 0, 180) -- Etwas größer für Egg Stats
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
    local lblSession = createLabel("🔥 Session Hatched", 50) -- Neu
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
                lblSession.Text = "🔥 Session Hatched: " .. sessionEggs -- Zeigt an, wie viele du seit Start geöffnet hast
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
-- 3. FARMING & HATCH LOOPS
-- ==============================================================================

-- AUTO HATCH LOOP
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

-- Auto Swing
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoSwing then
            RS.Events.SwingSaber:FireServer("Slash1")
            RS.Events.SwingSaber:FireServer("Slash2")
            RS.Events.SwingSaber:FireServer("Slash3")
        end
    end
end)

-- Auto Sell
task.spawn(function()
    while task.wait(1) do
        if Config.AutoSell then RS.Events.SellStrength:FireServer() end
    end
end)

-- NEW PICKUP SYSTEM
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

print("✅ SCRIPT UPDATED: EGG MODULE ACTIVE")
