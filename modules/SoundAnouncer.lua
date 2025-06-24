-- Объявление локальной функции инициализации аддона
local function SoundAnouncer_OnLoad()
    
    -- Кэш для хранения состояний целей квестов (ID квеста -> {objectives = {}})
    local questCache = {}
    
    -- Переменная для временного хранения ID квеста, требующего проверки
    local checkForUpdate
    
    -- Создание невидимого фрейма для обработки событий
    local f = CreateFrame("Frame")
    
    -- Регистрация события при принятии нового квеста
    f:RegisterEvent("QUEST_ACCEPTED")
    
    -- Регистрация события при обновлении отслеживаемого квеста
    f:RegisterEvent("QUEST_WATCH_UPDATE")
    
    -- Регистрация события при обновлении журнала квестов
    f:RegisterEvent("QUEST_LOG_UPDATE")
    
    -- Установка обработчика событий для фрейма
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        -- Обработка события принятия квеста
        if event == "QUEST_ACCEPTED" then
            -- Сброс данных о новом квесте в таблицах отслеживания
            questCache[arg1] = nil
        
        -- Обработка события обновления отслеживания квеста
        elseif event == "QUEST_WATCH_UPDATE" then
            -- Сохраняем ID квеста для последующей проверки
            checkForUpdate = arg1
        
        -- Обработка события обновления журнала квестов
        elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
            -- Получаем ID квеста из временной переменной
            local questId = checkForUpdate
            
            -- Если ID квеста не существует - сброс и выход
            if not questId then 
                checkForUpdate = nil 
                return 
            end
            
            -- Инициализация кэша для квеста при первом обращении
            questCache[questId] = questCache[questId] or { objectives = {} }
            local cache = questCache[questId]  -- Сокращение для удобства
            
            -- Получаем количество целей в квесте
            local numObjectives = GetNumQuestLeaderBoards(questId)
            
            -- Флаги для отслеживания состояния целей
            local allComplete = false     -- Все цели завершены
            local anyCompleted = false   -- Хотя бы одна цель завершена
            
            -- Перебор всех целей квеста
            for i = 1, numObjectives do
                -- Получаем данные о цели (текст, тип, завершена)
                local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
                
                -- Проверка общего завершения всех целей
                allComplete = isCompleted
                -- Проверка изменений состояния цели
                local wasCompleted = cache.objectives[i] or false
                if isCompleted and not wasCompleted then
                    anyCompleted = true
                end
                
                -- Обновление кэша текущим состоянием цели
                cache.objectives[i] = isCompleted
            end
            
            -- Если все цели завершены
            if allComplete then
                -- Воспроизведение звука завершения квеста (если включено)
                if MyQuestSoundHistoryDB.enableWorkComplete then
                    PlaySoundFile(MyQuestSoundHistoryDB.workCompleteSound)
                end
                
                checkForUpdate = nil
                questCache[questId] = nil
                return
            end
            
            -- Воспроизведение звуков прогресса
            if anyCompleted and MyQuestSoundHistoryDB.enableSingleComplete then
                -- Звук при завершении отдельной цели
                PlaySoundFile(MyQuestSoundHistoryDB.singleCompleteSound)
            elseif not anyCompleted and MyQuestSoundHistoryDB.enableProgressSound then
                -- Звук при обновлении прогресса (если нет завершенных целей)
                PlaySoundFile(MyQuestSoundHistoryDB.progressSound)
            end
            
            -- Сброс временной переменной после обработки
            checkForUpdate = nil
        end
    end)
end

-- Регистрация функции в глобальной таблице для доступа из других файлов
_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad