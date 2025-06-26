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
        local _, _, _, _, _, _, _, qID = GetQuestLogTitle(questLogIndex)
        if qID and qID ~= 0 then
            questID = qID
        elseif GetQuestID then
            questID = GetQuestID()
        end

        -- Если ID найден, собираем данные о квесте
        if questID then
            local title, level = select(1, GetQuestLogTitle(questLogIndex)) or "Unknown", select(2, GetQuestLogTitle(questLogIndex)) or 0
            local description, objectivesText = GetQuestLogQuestText()

            -- Получение целей квеста
            local objectives = {}
            local numObjectives = GetNumQuestLeaderBoards()
            if numObjectives and numObjectives > 0 then
                for i = 1, numObjectives do
                    local desc = select(1, GetQuestLogLeaderBoard(i))
                    if desc then
                        table.insert(objectives, desc)
                    end
                end
            end

            -- Получение наград
            local rewards = {
                items   = {},
                choices = {},
                money   = GetQuestLogRewardMoney() or 0,
                xp      = GetQuestLogRewardXP and (GetQuestLogRewardXP() or 0) or nil,
            }

            -- Добавление предметов в награды
            local numRewards = GetNumQuestLogRewards()
            if numRewards and numRewards > 0 then
                for i = 1, numRewards do
                    local itemName, itemTexture, _, _, _, itemID = GetQuestLogRewardInfo(i)
                    if itemName then
                        table.insert(rewards.items, {
                            name    = itemName,
                            texture = itemTexture,
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