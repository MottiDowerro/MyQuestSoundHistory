local addonName = "MyQuestSoundHistory"
local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        CreateSettingsPanel()
        SLASH_MYQUESTSOUNDHISTORY1 = "/MQSH"
        SLASH_MYQUESTSOUNDHISTORYCLEAR1 = "/MQSHC"
        SlashCmdList["MYQUESTSOUNDHISTORY"] = function()
            InterfaceOptionsFrame_OpenToCategory(addonName)
        end
        SlashCmdList["MYQUESTSOUNDHISTORYCLEAR"] = function()
            if MQSH_QuestDB then
                MQSH_QuestDB = {}
                print("MQSH: История квестов полностью очищена")
            else
                print("MQSH: База данных истории квестов пуста")
            end
        end

        -- Подключение модулей согласно новым настройкам
        if MQSH_Config and MQSH_Config.enableSoundAnouncer then
            if _G.SoundAnouncer_OnLoad then 
                _G.SoundAnouncer_OnLoad()
            end
        end
        if MQSH_Config and MQSH_Config.enableHistory then
            if _G.QuestDataBaseController_OnLoad then 
                _G.QuestDataBaseController_OnLoad()
            end
        else
            print("MQSH: История квестов отключена в настройках")
        end
    end
end)