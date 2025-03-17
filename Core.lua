local addonName = "QuestSoundAnouncer"
local f = CreateFrame("Frame")
local completedQuests = {}
local questCache = {} -- Вернули кэш задач
local checkForUpdate

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("QUEST_WATCH_UPDATE")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:RegisterEvent("QUEST_ACCEPTED")

f:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        CreateSettingsPanel()
        
        SLASH_QUESTSOUNDANOUNCER1 = "/QSA"
        SlashCmdList["QUESTSOUNDANOUNCER"] = function()
            InterfaceOptionsFrame_OpenToCategory(addonName)
        end
        
    elseif event == "QUEST_ACCEPTED" then
        completedQuests[arg1] = nil
        questCache[arg1] = nil -- Очищаем и кэш задач
        
    elseif event == "QUEST_WATCH_UPDATE" then
        checkForUpdate = arg1
        
    elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
        local questId = checkForUpdate
        if completedQuests[questId] then return end
        
        questCache[questId] = questCache[questId] or { objectives = {} }
        local cache = questCache[questId]
        
        local numObjectives = GetNumQuestLeaderBoards(questId)
        local allComplete = true
        local anyCompleted = false
        
        -- Основной цикл проверки задач
        for i = 1, numObjectives do
            local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
            
            -- Проверка полного завершения
            allComplete = allComplete and isCompleted
            
            -- Проверка новых выполненных задач
            local wasCompleted = cache.objectives[i] or false
            if isCompleted and not wasCompleted then
                anyCompleted = true
            end
            cache.objectives[i] = isCompleted
        end
        
        -- Приоритетная проверка полного завершения
        if allComplete then
            if QuestSoundAnouncerDB.enableWorkComplete then
                PlaySoundFile(QuestSoundAnouncerDB.workCompleteSound)
            end
            completedQuests[questId] = true
            checkForUpdate = nil
            return
        end
        
        -- Воспроизведение звуков по приоритету
        if anyCompleted and QuestSoundAnouncerDB.enableSingleComplete then
            PlaySoundFile(QuestSoundAnouncerDB.singleCompleteSound)
        elseif not anyCompleted and QuestSoundAnouncerDB.enableProgressSound then
            PlaySoundFile(QuestSoundAnouncerDB.progressSound) -- Старая логика прогресса
        end
        
        checkForUpdate = nil
    end
end)