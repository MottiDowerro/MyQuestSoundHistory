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
        -- Подключение модулей
        if MyQuestSoundHistoryDB.enableSoundAnouncer then
            if SoundAnouncer_OnLoad then SoundAnouncer_OnLoad() end
        end
        if MyQuestSoundHistoryDB.enableHistory then
            if History_OnLoad then History_OnLoad() end
        end
    end
end)