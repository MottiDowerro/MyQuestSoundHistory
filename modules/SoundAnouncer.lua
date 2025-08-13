local function SoundAnouncer_OnLoad()
    local pendingQuests = {}
    local completedObjectives = {}
    local objectiveStates = {}
    local f = CreateFrame("Frame")

    local function InitializeQuestObjectives(questId)
        if not questId then return end
        objectiveStates[questId] = objectiveStates[questId] or {}
        local numObjectives = GetNumQuestLeaderBoards(questId)
        if numObjectives and numObjectives > 0 then
            for i = 1, numObjectives do
                local text, _, _ = GetQuestLogLeaderBoard(i, questId)
                if text then
                    objectiveStates[questId][i] = text
                end
            end
        end
    end

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("QUEST_ACCEPTED")
    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "PLAYER_LOGIN" then
            for i = 1, GetNumQuestLogEntries() do
                local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questId = GetQuestLogTitle(i)
                if questId then
                    InitializeQuestObjectives(questId)
                end
            end
        elseif event == "QUEST_ACCEPTED" then
            local questId = arg1
            InitializeQuestObjectives(questId)
        elseif event == "QUEST_WATCH_UPDATE" then
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
                        local progressMade = false
                        completedObjectives[questId] = completedObjectives[questId] or {}
                        objectiveStates[questId] = objectiveStates[questId] or {}
                        
                        for i = 1, numObjectives do
                            local text, type, isCompleted = GetQuestLogLeaderBoard(i, questId)
                            
                            if objectiveStates[questId][i] and objectiveStates[questId][i] ~= text then
                                progressMade = true
                            end
                            objectiveStates[questId][i] = text

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
                            objectiveStates[questId] = nil
                        elseif progressMade and not newObjectiveCompleted and MQSH_Config and MQSH_Config.enableProgressSound then
                            PlaySoundFile(MQSH_Config.progressSound)
                        elseif newObjectiveCompleted and MQSH_Config and MQSH_Config.enableSingleComplete then
                            PlaySoundFile(MQSH_Config.singleCompleteSound)
                        end
                    end
                end
                pendingQuests[questId] = nil
            end
        end
    end)
end

_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad