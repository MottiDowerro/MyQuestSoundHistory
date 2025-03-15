local f, checkForUpdate = CreateFrame("Frame"), nil
local WORK_COMPLETE = "Sound\\Creature\\Peon\\PeonBuildingComplete1.wav"
local SINGLE_COMPLETE = "Sound\\Interface\\LevelUp.wav"
local PROGRESS_SOUND = "Sound\\Interface\\AuctionWindowOpen.wav"

local questCache = {}

f:RegisterEvent("QUEST_WATCH_UPDATE")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:SetScript("OnEvent", function(self, event, questIndex)
    if event == "QUEST_WATCH_UPDATE" then
        checkForUpdate = questIndex
    elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
        local questId = checkForUpdate
        local numObjectives = GetNumQuestLeaderBoards(questId)
        
        questCache[questId] = questCache[questId] or { objectives = {} }
        local cache = questCache[questId]
        
        -- Проверка полного завершения
        local allComplete = true
        for i = 1, numObjectives do
            local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
            allComplete = allComplete and (isCompleted == 1)
        end
        
        if allComplete and not (cache.wasComplete or false) then
            PlaySoundFile(WORK_COMPLETE)
            cache.wasComplete = true
            return
        end
        
        -- Проверка единичных завершений
        local anyCompleted = false
        for i = 1, numObjectives do
            local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
            local wasCompleted = cache.objectives[i] or false
            
            if isCompleted == 1 and not wasCompleted then
                PlaySoundFile(SINGLE_COMPLETE)
                anyCompleted = true
            end
            cache.objectives[i] = (isCompleted == 1)
        end
        
        -- Если ничего не завершено - звук прогресса
        if not anyCompleted and not allComplete then
            PlaySoundFile(PROGRESS_SOUND)
        end
        
        cache.wasComplete = allComplete
        checkForUpdate = nil
    end
end)