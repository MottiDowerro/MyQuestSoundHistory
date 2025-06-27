if not MQSH_QuestDB then
    MQSH_QuestDB = {}
end

-- Функция для безопасного выполнения действий с выбранным квестом
local function WithQuestLogSelection(index, func)
    local prev = GetQuestLogSelection()
    SelectQuestLogEntry(index)
    local ok, err = pcall(func)
    -- Возвращаем предыдущее состояние журнала (если он был) после выполнения GetQuestIDAndData()
    if prev and prev > 0 then
        SelectQuestLogEntry(prev)
    end
end

-- Функция для получения ID и данных о квесте
local function GetQuestIDAndData(questLogIndex)
    local questID, questData = nil, nil

    WithQuestLogSelection(questLogIndex, function()
        -- Получаем ID квеста
        local title, level, _, _, _, _, _, qID = GetQuestLogTitle(questLogIndex)
        if qID and qID ~= 0 then
            questID = qID
        elseif GetQuestID then
            questID = GetQuestID()
        end

        -- Если ID найден, собираем данные о квесте
        if questID then
            local description, objectivesText = GetQuestLogQuestText()

            -- Получение целей квеста
            local objectives = {}
            local objectiveItems = {} -- Новый массив для предметов-целей
            local numObjectives = GetNumQuestLeaderBoards()
            if numObjectives and numObjectives > 0 then
                for i = 1, numObjectives do
                    local desc, type = select(1, GetQuestLogLeaderBoard(i))
                    if desc then
                        table.insert(objectives, desc)
                        
                        -- Проверяем, является ли цель предметом
                        if type == "item" then
                            -- Пытаемся извлечь информацию о предмете из описания
                            local itemName, itemCount, itemID
                            
                            -- Парсим описание цели для извлечения информации о предмете
                            -- Пример: "Добыть банданы: 0/12" или "Собрать банданы (0/12)"
                            local itemPattern = "([^:]+):%s*(%d+)/(%d+)"
                            local itemNameMatch, currentCount, totalCount = desc:match(itemPattern)
                            
                            if itemNameMatch then
                                itemName = itemNameMatch:trim()
                                itemCount = tonumber(totalCount)
                                
                                -- Пытаемся найти itemID по имени предмета
                                if itemName then
                                    local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, itemID = GetItemInfo(itemName)
                                end
                                
                                if itemName and itemCount then
                                    table.insert(objectiveItems, {
                                        name = itemName,
                                        count = itemCount,
                                        itemID = itemID
                                    })
                                end
                            end
                        end
                    end
                end
            end

            -- Получение наград
            local rewards = {
                items   = {},
                choices = {},
                money   = GetQuestLogRewardMoney(),
                xp      = GetQuestLogRewardXP(),
            }

            -- Добавление предметов в награды
            local numRewards = GetNumQuestLogRewards()
            if numRewards and numRewards > 0 then
                for i = 1, numRewards do
                    local itemName, _, _, _, _, itemID = GetQuestLogRewardInfo(i)
                    if itemName then
                        table.insert(rewards.items, {
                            name    = itemName,
                            itemID  = itemID,
                        })
                    end
                end
            end

            -- Добавление предметов выбора
            local numChoices = GetNumQuestLogChoices()
            if numChoices and numChoices > 0 then
                for i = 1, numChoices do
                    local itemName, _, _, _, _, itemID = GetQuestLogChoiceInfo(i)
                    if itemName then
                        table.insert(rewards.choices, {
                            name    = itemName,
                            itemID  = itemID,
                        })
                    end
                end
            end

            -- Сохраняем данные о квесте
            questData = {
                title           = title,
                level           = level,
                description     = description,
                objectivesText  = objectivesText,
                objectives      = objectives,
                objectiveItems  = objectiveItems, -- Добавляем предметы-цели
                rewards         = rewards,
            }
        end
    end)

    return questID, questData
end

-- Обработчик события QUEST_ACCEPTED
local function QuestDataBaseController_OnLoad()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "QUEST_ACCEPTED" then
            local questLogIndex, questIDFromEvent = ...

            C_Timer:After(1, function() -- Задержка, чтобы в базе данных не было предметов с именем "nil"
                -- Получаем ID и данные о квесте
                local questID, questData = GetQuestIDAndData(questLogIndex)

                -- Если ID найден, добавляем квест в базу данных, если квеста с таким Id еще нету
                if questID and not MQSH_QuestDB[questID] then
                    MQSH_QuestDB[questID] = questData
                end
            end)
        end
    end)
end

_G.QuestDataBaseController_OnLoad = QuestDataBaseController_OnLoad