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

-- Функция для очистки строки от лишних пробелов
local function CleanLocationString(str)
    if not str then return nil end
    -- Убираем лишние пробелы в начале и конце, а также множественные пробелы внутри
    return str:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
end

-- Функция для получения ID и данных о квесте
local function GetQuestIDAndData(questLogIndex)
    local questID, questData = nil, nil

    WithQuestLogSelection(questLogIndex, function()
        local title, level, _, _, _, _, _, qID = GetQuestLogTitle(questLogIndex)
        if qID and qID ~= 0 then
            questID = qID
        elseif GetQuestID then
            questID = GetQuestID()
        end

        if questID then
            local description, objectivesText = GetQuestLogQuestText()

            -- Проверка на сюжетный квест (проверяем только начало описания для оптимизации)
            local isStoryQuest = false
            if description then
                local storyMarker = "|cFFA52A2A<Обязательное сюжетное задание>|r"
                isStoryQuest = description:sub(1, #storyMarker) == storyMarker
            end

            -- Локация и координаты для WoW 3.3.5
            local locationName = CleanLocationString(GetRealZoneText() or GetZoneText())
            
            local x, y = 0, 0
            if SetMapToCurrentZone then SetMapToCurrentZone() end
            if GetPlayerMapPosition then
                x, y = GetPlayerMapPosition("player")
                x = math.floor((x or 0) * 10000) / 100
                y = math.floor((y or 0) * 10000) / 100
            end
            local coordinates = { x = x, y = y }

            -- NPC - улучшенное получение
            local npcName = nil
            
            -- Сначала проверяем цель
            local target = UnitName("target")
            if target and not UnitIsPlayer("target") then
                npcName = target
            end
            
            -- Если цель не подходит, проверяем GossipFrame (диалог с NPC)
            if not npcName and GossipFrame and GossipFrame:IsShown() then
                -- Пытаемся получить имя из заголовка GossipFrame
                if GossipFrameTitleText then
                    local titleText = GossipFrameTitleText:GetText()
                    if titleText and titleText ~= "" then
                        npcName = titleText
                    end
                end
            end
            
            -- Если все еще нет NPC, проверяем последнего взаимодействовавшего NPC
            if not npcName then
                -- Пытаемся получить из последнего события взаимодействия
                if UnitExists("npc") then
                    npcName = UnitName("npc")
                end
            end
            
            -- Если NPC не найден, устанавливаем значение по умолчанию
            if not npcName or npcName == "" then
                npcName = "Неизвестный NPC"
            end

            -- Цели
            local objectives = {}
            local objectiveItems = {}
            local numObjectives = GetNumQuestLeaderBoards()
            if numObjectives and numObjectives > 0 then
                for i = 1, numObjectives do
                    local desc, type = select(1, GetQuestLogLeaderBoard(i))
                    if desc then
                        table.insert(objectives, desc)
                        if type == "item" then
                            local itemName, itemCount, itemID
                            local itemPattern = "([^:]+):%s*(%d+)/(%d+)"
                            local itemNameMatch, currentCount, totalCount = desc:match(itemPattern)
                            if itemNameMatch then
                                itemName = itemNameMatch:trim()
                                itemCount = tonumber(totalCount)
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

            -- Награды
            local rewards = {
                items   = {},
                choices = {},
                money   = GetQuestLogRewardMoney(),
                xp      = GetQuestLogRewardXP(),
            }

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

            local timeAccepted = date("%d.%m.%y %H:%M:%S")

            questData = {
                title           = title,
                level           = level,
                description     = description,
                objectivesText  = objectivesText,
                objectives      = objectives,
                objectiveItems  = objectiveItems,
                rewards         = rewards,
                npcName         = npcName,
                mainZone        = locationName,
                coordinates     = coordinates,
                timeAccepted    = timeAccepted,
                isStoryQuest    = isStoryQuest,
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
            
            C_Timer:After(0.15, function()
                local questID, questData = GetQuestIDAndData(questLogIndex)
                if questID and questData and not MQSH_QuestDB[questID] then
                    MQSH_QuestDB[questID] = questData
                else
                end
            end)
        end
    end)
end

_G.QuestDataBaseController_OnLoad = QuestDataBaseController_OnLoad