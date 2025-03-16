local addonName = "QuestSoundAnouncer"
local f = CreateFrame("Frame")

local questCache = {}
local checkForUpdate

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("QUEST_WATCH_UPDATE")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        CreateSettingsPanel()
        
        SLASH_QUESTSOUNDANOUNCER1 = "/QSA"
        SlashCmdList["QUESTSOUNDANOUNCER"] = function()
            InterfaceOptionsFrame_OpenToCategory(addonName)
        end
        
    elseif event == "QUEST_WATCH_UPDATE" then
        checkForUpdate = arg1
    elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
        local questId = checkForUpdate
        local numObjectives = GetNumQuestLeaderBoards(questId)
        
        questCache[questId] = questCache[questId] or { objectives = {} }
        local cache = questCache[questId]
        
        local allComplete = true
        for i = 1, numObjectives do
            local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
            allComplete = allComplete and isCompleted
        end
        
        if allComplete and not cache.wasComplete then
            if QuestSoundAnouncerDB.enableWorkComplete then
                PlaySoundFile(QuestSoundAnouncerDB.workCompleteSound)
            end
            cache.wasComplete = true
            return
        end
        
        local anyCompleted = false
        for i = 1, numObjectives do
            local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
            local wasCompleted = cache.objectives[i] or false
            
            if isCompleted and not wasCompleted then
                if QuestSoundAnouncerDB.enableSingleComplete then
                    PlaySoundFile(QuestSoundAnouncerDB.singleCompleteSound)
                end
                anyCompleted = true
            end
            cache.objectives[i] = isCompleted
        end
        
        if not anyCompleted and not allComplete and QuestSoundAnouncerDB.enableProgressSound then
            PlaySoundFile(QuestSoundAnouncerDB.progressSound)
        end
        
        cache.wasComplete = allComplete
        checkForUpdate = nil
    end
end)