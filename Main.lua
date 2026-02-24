return function(Window)
    -- Erstellt einen neuen Tab für Farming-Funktionen
    local Tab = Window:CreateTab("Auto Farm", 4483362458) 
    local Section = Tab:CreateSection("Klicker System")

    -- Variable, die speichert, ob der Autoclicker an oder aus ist
    local autoClicking = false

    -- Erstellt den An/Aus-Knopf (Toggle)
    Tab:CreateToggle({
        Name = "Auto Click",
        CurrentValue = false,
        Flag = "Toggle_AutoClick",
        Callback = function(Value)
            autoClicking = Value -- Aktualisiert den Status (true = an, false = aus)
            
            -- Wenn angeschaltet, starte die Schleife in einem eigenen Thread (task.spawn)
            if autoClicking then
                task.spawn(function()
                    while autoClicking do
                        -- Die Argumente aus deinem SimpleSpy Log
                        local args = {
                            [1] = {
                                [1] = {
                                    [1] = "ClickSystem",
                                    [2] = "Execute",
                                    [3] = "381079411a0a4499a0f21053b2fb12a1",
                                    ["n"] = 3
                                },
                                [2] = "\2"
                            }
                        }

                        -- Das Event im ReplicatedStorage suchen und feuern
                        local bridgeNet = game:GetService("ReplicatedStorage"):FindFirstChild("ffrostflame_bridgenet2@1.0.0")
                        
                        if bridgeNet and bridgeNet:FindFirstChild("dataRemoteEvent") then
                            bridgeNet.dataRemoteEvent:FireServer(unpack(args))
                        else
                            warn("[Hub] RemoteEvent nicht gefunden! Bist du im richtigen Spiel?")
                            autoClicking = false -- Stoppt die Schleife sicherheitshalber
                        end
                        
                        -- WICHTIG: Die Pause (0.1 Sekunden). Ohne das crasht dein Roblox sofort!
                        -- Du kannst die Zahl anpassen, z.B. 0.05 für schnelleres Klicken.
                        task.wait(0.1) 
                    end
                end)
            end
        end,
    })
end
