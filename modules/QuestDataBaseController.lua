-- Модуль сохранения информации о квестах
-- Каждое новое задание, которого ещё нет в базе, добавляется автоматически.

local addonName = "MyQuestSoundHistory"

-- Миграция из старой переменной, если такая существует
if _G.MyQuestSoundHistory_QuestDB and not _G.MQSH_QuestDB then
    _G.MQSH_QuestDB = _G.MyQuestSoundHistory_QuestDB
    _G.MyQuestSoundHistory_QuestDB = nil
end

-- Убедимся, что таблица сохранения существует
if not MQSH_QuestDB then
    MQSH_QuestDB = {}
end

local DEBUG = true -- установите false, чтобы отключить вывод
local function dbg(msg)
    if DEBUG then
        print(string.format("[%s][QuestDB] %s", addonName, msg))
    end
end

-- Вспомогательная функция для безопасного выбора записи в журнале квестов
local function WithQuestLogSelection(index, func)
    local prev = GetQuestLogSelection()
    SelectQuestLogEntry(index)
    local ok, err = pcall(func)
    if prev and prev > 0 then
        SelectQuestLogEntry(prev)
    end
    if not ok then
        -- just print error in chat, shouldn't break addon
        print(string.format("[%s] Quest DB error: %s", addonName, err))
    end
end

-- Универсально получить questID по индексу журнала
local function GetQuestIDByLogIndex(index)
    -- Попытка №1: восьмой аргумент GetQuestLogTitle
    local _, _, _, _, _, _, _, qID = GetQuestLogTitle(index)
    if qID and qID ~= 0 then return qID end

    -- Попытка №2: функция GetQuestID внутри выбранной записи журнала
    if GetQuestID then
        local id
        WithQuestLogSelection(index, function()
            id = GetQuestID()
        end)
        if id and id ~= 0 then return id end
    end

    return nil
end

-- Добавление квеста в БД
local function AddQuestToDB(questID, questLogIndex)
    dbg(string.format("Попытка добавить квест: ID=%s, logIndex=%s", tostring(questID), tostring(questLogIndex)))
    -- если уже есть — выходим
    if MQSH_QuestDB[questID] then
        dbg("Квест уже присутствует в базе, пропускаем.")
        return
    end

    WithQuestLogSelection(questLogIndex, function()
        -- Название, уровень и пр. возвращаются функцией GetQuestLogTitle
        local title = select(1, GetQuestLogTitle(questLogIndex)) or "Unknown"

        -- Описание и сводка целей
        local description, objectivesText = GetQuestLogQuestText()

        -- Цели
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

        -- Награды
        local rewards = {
            items   = {}, -- гарантированные предметы
            choices = {}, -- предметы на выбор
            money   = GetQuestLogRewardMoney() or 0,
            xp      = GetQuestLogRewardXP and (GetQuestLogRewardXP() or 0) or nil,
        }

        -- Гарантированные предметы
        local numRewards = GetNumQuestLogRewards()
        if numRewards and numRewards > 0 then
            for i = 1, numRewards do
                local itemName = select(1, GetQuestLogRewardInfo(i))
                if itemName then
                    table.insert(rewards.items, itemName)
                end
            end
        end

        -- Предметы на выбор
        local numChoices = GetNumQuestLogChoices()
        if numChoices and numChoices > 0 then
            for i = 1, numChoices do
                local itemName = select(1, GetQuestLogChoiceInfo(i))
                if itemName then
                    table.insert(rewards.choices, itemName)
                end
            end
        end

        MQSH_QuestDB[questID] = {
            title       = title,
            description = description,
            objectivesText = objectivesText,
            objectives  = objectives,
            rewards     = rewards,
            addedAt     = time(), -- время добавления (для отладки)
        }

        dbg(string.format("Квест добавлен: '%s' (ID=%s)", title, tostring(questID)))
    end)
end

local function QuestDataBaseController_OnLoad()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_ACCEPTED")
    dbg("QuestDataBaseController_OnLoad инициализирован")

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "QUEST_ACCEPTED" then
            local questLogIndex, questIDFromEvent = ...
            local questID = questIDFromEvent or GetQuestIDByLogIndex(questLogIndex)

            dbg(string.format("Событие QUEST_ACCEPTED: logIndex=%s, questID=%s", tostring(questLogIndex), tostring(questID)))

            if questID then
                AddQuestToDB(questID, questLogIndex)
            else
                dbg("Не удалось определить questID, запись пропущена.")
            end
        end
    end)
end

_G.QuestDataBaseController_OnLoad = QuestDataBaseController_OnLoad