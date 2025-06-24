local function SoundAnouncer_OnLoad()
    local completedQuests = {}
    local questCache = {}
    local checkForUpdate
    local f = CreateFrame("Frame")
    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    f:RegisterEvent("QUEST_ACCEPTED")
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "QUEST_ACCEPTED" then
            completedQuests[arg1] = nil
            questCache[arg1] = nil
        elseif event == "QUEST_WATCH_UPDATE" then
            checkForUpdate = arg1
        elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
            local questId = checkForUpdate
            if not questId then 
                checkForUpdate = nil 
                return 
            end
            if completedQuests[questId] then 
                checkForUpdate = nil 
                return 
            end
            questCache[questId] = questCache[questId] or { objectives = {} }
            local cache = questCache[questId]
            local numObjectives = GetNumQuestLeaderBoards(questId)
            local allComplete = true
            local anyCompleted = false
            for i = 1, numObjectives do
                local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
                allComplete = allComplete and isCompleted
                local wasCompleted = cache.objectives[i] or false
                if isCompleted and not wasCompleted then
                    anyCompleted = true
                end
                cache.objectives[i] = isCompleted
            end
            if allComplete then
                if MyQuestSoundHistoryDB.enableWorkComplete then
                    PlaySoundFile(MyQuestSoundHistoryDB.workCompleteSound)
                end
                completedQuests[questId] = true
                checkForUpdate = nil
                return
            end
            if anyCompleted and MyQuestSoundHistoryDB.enableSingleComplete then
                PlaySoundFile(MyQuestSoundHistoryDB.singleCompleteSound)
            elseif not anyCompleted and MyQuestSoundHistoryDB.enableProgressSound then
                PlaySoundFile(MyQuestSoundHistoryDB.progressSound)
            end
            checkForUpdate = nil
        end
    end)
end
_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad