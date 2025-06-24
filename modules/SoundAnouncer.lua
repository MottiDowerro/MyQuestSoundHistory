local function SoundAnouncer_OnLoad()
    
    local questCache = {}
    local checkForUpdate = nil
    local f = CreateFrame("Frame")

    f:RegisterEvent("QUEST_ACCEPTED")
    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "QUEST_ACCEPTED" then
            if arg1 then
                questCache[arg1] = nil
            end
        elseif event == "QUEST_WATCH_UPDATE" then
            if arg1 then
                checkForUpdate = arg1
            end
        elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
            local questId = checkForUpdate
            
            questCache[questId] = questCache[questId] or { objectives = {} }
            local cache = questCache[questId]
            
            local numObjectives = GetNumQuestLeaderBoards(questId)

            if numObjectives == 0 then 
                checkForUpdate = nil 
                return 
            end
            
            local allComplete = false
            local anyCompleted = false
            
            for i = 1, numObjectives do
                local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
                
                allComplete = isCompleted

                if isCompleted then
                    anyCompleted = true
                end
                
                cache.objectives[i] = isCompleted
            end
            
            if allComplete then
                if MyQuestSoundHistoryDB.enableWorkComplete then
                    PlaySoundFile(MyQuestSoundHistoryDB.workCompleteSound)
                end
                
                checkForUpdate = nil
                questCache[questId] = nil
                return
            elseif anyCompleted and MyQuestSoundHistoryDB.enableSingleComplete then
                PlaySoundFile(MyQuestSoundHistoryDB.singleCompleteSound)
            elseif not anyCompleted and MyQuestSoundHistoryDB.enableProgressSound then
                PlaySoundFile(MyQuestSoundHistoryDB.progressSound)
            end
            
            checkForUpdate = nil
        end
    end)
end

_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad