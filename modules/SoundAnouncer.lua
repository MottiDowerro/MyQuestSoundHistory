local function SoundAnouncer_OnLoad()
    local pendingQuests = {}
    local completedObjectives = {}
    local objectiveStates = {}
    local f = CreateFrame("Frame")

    local function GetRealQuestID(logIndex)
        local link = GetQuestLink(logIndex)
        if link then
            return tonumber(link:match("|Hquest:(%d+):"))
        end
        return nil
    end

    local function InitializeQuestObjectives(logIndex)
        local realID = GetRealQuestID(logIndex)
        if not realID then return end
        objectiveStates[realID] = objectiveStates[realID] or {}
        local numObjectives = GetNumQuestLeaderBoards(logIndex)
        if numObjectives and numObjectives > 0 then
            for i = 1, numObjectives do
                local text, _, _ = GetQuestLogLeaderBoard(i, logIndex)
                if text then
                    objectiveStates[realID][i] = text
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
                local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(i)
                if not isHeader then
                    InitializeQuestObjectives(i)
                end
            end
        elseif event == "QUEST_ACCEPTED" then
            local logIndex = arg1
            InitializeQuestObjectives(logIndex)
        elseif event == "QUEST_WATCH_UPDATE" then
            if arg1 then
                pendingQuests[arg1] = true
            end
        elseif event == "QUEST_LOG_UPDATE" then
            for logIndex, _ in pairs(pendingQuests) do
                if IsQuestWatched(logIndex) then
                    local realID = GetRealQuestID(logIndex)
                    if realID then
                        local numObjectives = GetNumQuestLeaderBoards(logIndex)
                        
                        if numObjectives and numObjectives > 0 then 
                            local allComplete = true
                            local newObjectiveCompleted = false
                            local progressMade = false
                            completedObjectives[realID] = completedObjectives[realID] or {}
                            objectiveStates[realID] = objectiveStates[realID] or {}
                            
                            for i = 1, numObjectives do
                                local text, type, isCompleted = GetQuestLogLeaderBoard(i, logIndex)
                                
                                if objectiveStates[realID][i] and objectiveStates[realID][i] ~= text then
                                    progressMade = true
                                end
                                objectiveStates[realID][i] = text

                                if isCompleted then
                                    if not completedObjectives[realID][i] then
                                        newObjectiveCompleted = true
                                        completedObjectives[realID][i] = true
                                    end
                                else
                                    allComplete = false
                                end
                            end
                            
                            if allComplete and MQSH_Config and MQSH_Config.enableWorkComplete then
                                PlaySoundFile(MQSH_Config.workCompleteSound)
                                completedObjectives[realID] = nil
                                objectiveStates[realID] = nil
                            elseif progressMade and not newObjectiveCompleted and MQSH_Config and MQSH_Config.enableProgressSound then
                                PlaySoundFile(MQSH_Config.progressSound)
                            elseif newObjectiveCompleted and MQSH_Config and MQSH_Config.enableSingleComplete then
                                PlaySoundFile(MQSH_Config.singleCompleteSound)
                            end
                        end
                    end
                end
                pendingQuests[logIndex] = nil
            end
        end
    end)
end

_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad