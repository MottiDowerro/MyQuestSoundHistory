print("[MQSH] Загрузка файла SoundAnouncer.lua")

local function FindQuestLogIndexByID(questId)
    for i = 1, GetNumQuestLogEntries() do
        local id = select(8, GetQuestLogTitle(i))
        if id == questId then
            return i
        end
    end
    return nil
end

local function SoundAnouncer_OnLoad()
    local completedQuests = {}
    local questCache = {}
    local checkForUpdate
    local f = CreateFrame("Frame")
    print("[MQSH] Frame создан, регистрируем события")
    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    f:RegisterEvent("QUEST_ACCEPTED")
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        print("[MQSH] Event:", event, "arg1:", arg1, "arg2:", arg2)
        if event == "QUEST_ACCEPTED" then
            print("[MQSH] QUEST_ACCEPTED, questId:", arg1)
            completedQuests[arg1] = nil
            questCache[arg1] = nil
        elseif event == "QUEST_WATCH_UPDATE" then
            print("[MQSH] QUEST_WATCH_UPDATE, questLogIndex:", arg1)
            checkForUpdate = arg1 -- это индекс квеста в журнале!
        elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
            local questId = checkForUpdate
            print("[MQSH] QUEST_LOG_UPDATE, questId:", questId)
            if not questId then print("[MQSH] Нет questId"); checkForUpdate = nil return end
            if completedQuests[questId] then print("[MQSH] Квест уже завершён"); checkForUpdate = nil return end
            questCache[questId] = questCache[questId] or { objectives = {} }
            local cache = questCache[questId]
            local numObjectives = GetNumQuestLeaderBoards(questId)
            print("[MQSH] numObjectives:", numObjectives)
            local allComplete = true
            local anyCompleted = false
            for i = 1, numObjectives do
                local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
                print("[MQSH] Objective", i, "isCompleted:", isCompleted)
                allComplete = allComplete and isCompleted
                local wasCompleted = cache.objectives[i] or false
                if isCompleted and not wasCompleted then
                    print("[MQSH] Новая выполненная задача:", i)
                    anyCompleted = true
                end
                cache.objectives[i] = isCompleted
            end
            if allComplete then
                print("[MQSH] Квест полностью завершён!")
                if MyQuestSoundHistoryDB.enableWorkComplete then
                    print("[MQSH] Пытаюсь воспроизвести workCompleteSound:", MyQuestSoundHistoryDB.workCompleteSound)
                    PlaySoundFile(MyQuestSoundHistoryDB.workCompleteSound)
                end
                completedQuests[questId] = true
                checkForUpdate = nil
                return
            end
            if anyCompleted and MyQuestSoundHistoryDB.enableSingleComplete then
                print("[MQSH] Пытаюсь воспроизвести singleCompleteSound:", MyQuestSoundHistoryDB.singleCompleteSound)
                PlaySoundFile(MyQuestSoundHistoryDB.singleCompleteSound)
            elseif not anyCompleted and MyQuestSoundHistoryDB.enableProgressSound then
                print("[MQSH] Пытаюсь воспроизвести progressSound:", MyQuestSoundHistoryDB.progressSound)
                PlaySoundFile(MyQuestSoundHistoryDB.progressSound)
            end
            checkForUpdate = nil
        end
    end)
end
_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad 