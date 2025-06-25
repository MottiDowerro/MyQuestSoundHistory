local addonName = "MyQuestSoundHistory"
local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        CreateSettingsPanel()
        SLASH_MYQUESTSOUNDHISTORY1 = "/MQSH"
        SlashCmdList["MYQUESTSOUNDHISTORY"] = function()
            InterfaceOptionsFrame_OpenToCategory(addonName)
        end

        -- Подключение модулей согласно новым настройкам
        if MQSH_Config and MQSH_Config.enableSoundAnouncer then
            if _G.SoundAnouncer_OnLoad then _G.SoundAnouncer_OnLoad() end
        end
        if MQSH_Config and MQSH_Config.enableHistory then
            if _G.QuestDataBaseController_OnLoad then _G.QuestDataBaseController_OnLoad() end
        end
    end
end)