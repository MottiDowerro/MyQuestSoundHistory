local function SoundAnouncer_OnLoad()
    local pendingQuests = {}
    local completedObjectives = {}
    local f = CreateFrame("Frame")

    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "QUEST_WATCH_UPDATE" then
            if arg1 then
                pendingQuests[arg1] = true
            end
        elseif event == "QUEST_LOG_UPDATE" then
            for questId, _ in pairs(pendingQuests) do
                if IsQuestWatched(questId) then
                    local numObjectives = GetNumQuestLeaderBoards(questId)
                    
                    if numObjectives and numObjectives > 0 then 
                        local allComplete = true
                        local newObjectiveCompleted = false
                        completedObjectives[questId] = completedObjectives[questId] or {}
                        
                        for i = 1, numObjectives do
                            local text, type, isCompleted = GetQuestLogLeaderBoard(i, questId)
                            if isCompleted then
                                if not completedObjectives[questId][i] then
                                    newObjectiveCompleted = true
                                    completedObjectives[questId][i] = true
                                end
                            else
                                allComplete = false
                            end
                        end
                        
                        if allComplete and MQSH_Config and MQSH_Config.enableWorkComplete then
                            PlaySoundFile(MQSH_Config.workCompleteSound)
                            completedObjectives[questId] = nil
                            pendingQuests[questId] = nil
                        elseif newObjectiveCompleted and MQSH_Config and MQSH_Config.enableSingleComplete then
                            PlaySoundFile(MQSH_Config.singleCompleteSound)
                        elseif not allComplete and not newObjectiveCompleted and MQSH_Config and MQSH_Config.enableProgressSound then
                            PlaySoundFile(MQSH_Config.progressSound)
                        end
                    end
                end
                pendingQuests[questId] = nil
            end
        end
    end)
end

_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad