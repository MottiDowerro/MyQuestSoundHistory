local addonName = "MyQuestSoundHistory"
local f = CreateFrame("Frame")

if not _G.MQSH_API then
    _G.MQSH_API = {}
end

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
                print("MQSH: База данных квестов полностью очищена")
            else
                print("MQSH: База данных квестов пуста")
            end
            if MQSH_Char_HistoryDB then
                MQSH_Char_HistoryDB = {}
                print("MQSH: История квестов персонажа очищена")
            else
                print("MQSH: История квестов персонажа пуста")
            end
        end

        if MQSH_Config and MQSH_Config.enableSoundAnouncer then
            if _G.SoundAnouncer_OnLoad then 
                _G.SoundAnouncer_OnLoad()
            end
        end
        if MQSH_Config and MQSH_Config.enableHistory then
            if _G.QuestDB_OnLoad then 
                _G.QuestDB_OnLoad()
            end
            if _G.CharacterQuestDB_OnLoad then
                _G.CharacterQuestDB_OnLoad()
            end
        end
    end
end)