if not MQSH_QuestDB then
    MQSH_QuestDB = {}
end

if not MQSH_Char_HistoryDB then
    MQSH_Char_HistoryDB = {}
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

-- Удаляем эти функции отсюда, они будут определены внутри QuestDataBaseController_OnLoad

-- Функция для получения ID и данных о квесте
local function GetQuestIDAndData(questLogIndex, currentNPC)
    local questID, questData = nil, nil

    WithQuestLogSelection(questLogIndex, function()
        local title, level, questType, _, _, _, _, qID = GetQuestLogTitle(questLogIndex)
        if qID and qID ~= 0 then
            questID = qID
        elseif GetQuestID then
            questID = GetQuestID()
        end

        if questID then
            local description, objectivesText = GetQuestLogQuestText()

            -- Определение группы квеста для группировки
            local questGroup = nil
            
            -- Ищем заголовок выше в журнале квестов
            for i = questLogIndex - 1, 1, -1 do
                local headerTitle, headerLevel, headerType, _, _, _, _, headerQID, _, _, _, isHeader = GetQuestLogTitle(i)
                -- В WoW 3.3.5 заголовки имеют Level: 0, Type: nil, QID: nil
                if headerLevel == 0 and headerType == nil and headerQID == nil then
                    -- Нашли заголовок категории - используем его для группировки
                    questGroup = headerTitle
                    break
                end
            end
            
            -- Если заголовок не найден, questGroup остается nil (будет использована локация)
            
            -- Автоматически устанавливаем questType для квестов в группе "Сюжетные"
            if questGroup and (questGroup:lower():find("сюжет") or questGroup:lower():find("story")) then
                questType = "(Сюжетный)"
                questGroup = nil
            end

            if questGroup and not questGroup:lower():find("особ") and questType and not questType:lower():find("рей") and not questType:lower():find("подземель") then
                questGroup = nil
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

            -- NPC - улучшенное получение с использованием сохраненного NPC
            local npcName = nil
            
            -- Сначала проверяем сохраненного NPC
            if currentNPC and currentNPC ~= "" then
                npcName = currentNPC
            else
                npcName = "Неизвестный NPC"
            end

            -- Цели
            local objectives = {}
            local numObjectives = GetNumQuestLeaderBoards()
            if numObjectives and numObjectives > 0 then
                for i = 1, numObjectives do
                    local desc, type = select(1, GetQuestLogLeaderBoard(i))
                    if desc and type ~= "item" then
                        table.insert(objectives, desc)
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
                rewards         = rewards,
                npcName         = npcName,
                mainZone        = locationName,
                coordinates     = coordinates,
                timeAccepted    = timeAccepted,
                questGroup      = questGroup,
                questType       = questType,
            }
        end
    end)

    return questID, questData
end

-- Обработчик события QUEST_ACCEPTED
local function QuestDataBaseController_OnLoad()
    -- Локальная переменная для хранения текущего NPC
    local currentNPC = nil
    local questComplete = nil
    
    -- Локальные функции для работы с историей
    local function GetInfoForHistory()
        local questID = nil
        local questData = nil
        
        -- Получаем quest ID только через GetQuestID()
        if GetQuestID then
            questID = GetQuestID()
            if questID and questID ~= 0 then
                -- Получаем данные из базы квестов
                questData = MQSH_QuestDB[questID]
            end
        end
        
        return questID, questData
    end

    local function SaveQuestInfoToHistory()
        local questID, questData = GetInfoForHistory()
        
        if questID then
            -- Создаем минимальную запись для истории
            local historyData = {
                timeCompleted = date("%d.%m.%y %H:%M:%S"),
                completionNPC = currentNPC or "Неизвестный NPC",
                completionLocation = CleanLocationString(GetRealZoneText() or GetZoneText())
            }
            
            -- Сохраняем в историю персонажа
            MQSH_Char_HistoryDB[questID] = historyData
        end
    end
    
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("QUEST_COMPLETE")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "GOSSIP_SHOW" or event == "QUEST_DETAIL" then
            questComplete = 0
            currentNPC = UnitName("npc")
        elseif event == "QUEST_COMPLETE" then
            GetInfoForHistory()   -- при открытии окна завершения квеста получаем информацию о questID, локации в которой находимся. имя епрсонажа уже определяется в OnEvent
            questComplete = 2
            currentNPC = UnitName("npc")
        elseif event == "QUEST_ACCEPTED" then
            questComplete = 0
            local questLogIndex, questIDFromEvent = ...
            local npcName = currentNPC
            C_Timer:After(0.05, function()
                local questID, questData = GetQuestIDAndData(questLogIndex, npcName)
                if questID and questData and not MQSH_QuestDB[questID] then
                    MQSH_QuestDB[questID] = questData
                end
            end)
        elseif event == "GOSSIP_CLOSED" then
            currentNPC = nil
        elseif event == "QUEST_FINISHED" then
            C_Timer:After(0.35, function()   --должно быть больше чем задержка в QUEST_ACCEPTED на 0.30 +
                if questComplete == 2 then
                    questComplete = 1
                elseif questComplete == 1 then
                    SaveQuestInfoToHistory()  -- ЛОГИКА СОХРАНЕНИЯ в перчарактер (MQSH_Char_HistoryDB). отправляем сюда всю информацию из GetInfoForHistory(), 
                                              -- плюс получаем время завершения квеста в этот момент, плюс текущего npc отправляем. всё это делаем MQSH_Char_HistoryDB[questID] = questDataForHistory
                else
                    questComplete = 0
                    currentNPC = nil
                end
            end)
        end
    end)
end

_G.QuestDataBaseController_OnLoad = QuestDataBaseController_OnLoad