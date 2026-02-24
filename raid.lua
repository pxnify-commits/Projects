return function(Window)
    -- Erstellt den neuen Tab "Raid"
    local Tab = Window:CreateTab("Raid", 4483362458) 
    local Section = Tab:CreateSection("Raid Steuerung")

    -- Das BridgeNet Event (wird für beide Buttons gebraucht)
    local bridgeNet = game:GetService("ReplicatedStorage"):FindFirstChild("ffrostflame_bridgenet2@1.0.0")

    -- Button 1: Create Raid
    Tab:CreateButton({
        Name = "1. Create Raid (TitanTown, Easy)",
        Callback = function()
            local args = {
                [1] = {
                    [1] = {
                        [1] = "GamemodeSystem",
                        [2] = "Create",
                        [3] = "Raid",
                        [4] = "TitanTown",
                        [5] = "Easy",
                        ["n"] = 6
                    },
                    [2] = "\2"
                }
            }

            if bridgeNet and bridgeNet:FindFirstChild("dataRemoteEvent") then
                bridgeNet.dataRemoteEvent:FireServer(unpack(args))
                print("[Hub] Raid erstellt!")
            else
                warn("[Hub] RemoteEvent nicht gefunden!")
            end
        end,
    })

    -- Button 2: Start Raid
    Tab:CreateButton({
        Name = "2. Start Raid",
        Callback = function()
            local args = {
                [1] = {
                    [1] = {
                        [1] = "GamemodeSystem",
                        [2] = "Start",
                        [3] = "Raid",
                        [4] = 8385683692, -- Hinweis: Dies könnte eine Session-ID sein
                        ["n"] = 4
                    },
                    [2] = "\2"
                }
            }

            if bridgeNet and bridgeNet:FindFirstChild("dataRemoteEvent") then
                bridgeNet.dataRemoteEvent:FireServer(unpack(args))
                print("[Hub] Raid gestartet!")
            else
                warn("[Hub] RemoteEvent nicht gefunden!")
            end
        end,
    })
end
