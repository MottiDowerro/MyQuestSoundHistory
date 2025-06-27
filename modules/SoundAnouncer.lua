local function SoundAnouncer_OnLoad()
    
    local pendingQuests = {}
    local f = CreateFrame("Frame")

    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "QUEST_WATCH_UPDATE" then
            -- Добавляем квест в список ожидающих проверки
            if arg1 then
                pendingQuests[arg1] = true
            end
        elseif event == "QUEST_LOG_UPDATE" then
            -- Проверяем только квесты, которые были обновлены
            for questId, _ in pairs(pendingQuests) do
                if IsQuestWatched(questId) then
                    local numObjectives = GetNumQuestLeaderBoards(questId)
                    
                    if numObjectives and numObjectives > 0 then 
                        local allComplete = true
                        local singleCompleted = false
                    
                        for i = 1, numObjectives do
                            local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
                            if isCompleted then
                                singleCompleted = true
                            elseif allComplete then
                                allComplete = false
                            end
                        end
                    
                        if allComplete and MQSH_Config and MQSH_Config.enableWorkComplete then
                            PlaySoundFile(MQSH_Config.workCompleteSound)
                            pendingQuests[questId] = nil
                            return
                        elseif singleCompleted and MQSH_Config and MQSH_Config.enableSingleComplete then
                            PlaySoundFile(MQSH_Config.singleCompleteSound)
                            pendingQuests[questId] = nil
                            return
                        elseif not singleCompleted and MQSH_Config and MQSH_Config.enableProgressSound then
                            PlaySoundFile(MQSH_Config.progressSound)
                            pendingQuests[questId] = nil
                            return
                        end
                    end
                end
                -- Удаляем квест из списка ожидающих
                pendingQuests[questId] = nil
            end
        end
    end)
end

_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad