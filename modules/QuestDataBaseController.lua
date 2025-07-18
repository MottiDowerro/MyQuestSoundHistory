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
    if prev and prev > 0 then
        SelectQuestLogEntry(prev)
    end
end

-- Функция для очистки строки от лишних пробелов
local function CleanLocationString(str)
    if not str then return nil end
    return str:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
end

-- Функция для получения ID и данных о квесте
local function GetQuestIDAndData(questLogIndex, currentNPC)
    local questID, questData = nil, nil

    WithQuestLogSelection(questLogIndex, function()
        local title, level, questType, _, _, _, _, _, qID = GetQuestLogTitle(questLogIndex)
        if qID and qID ~= 0 then
            questID = qID
        elseif GetQuestID then
            questID = GetQuestID()
        end

        if questID then
            local description, objectivesText = GetQuestLogQuestText()
            local questGroup = nil
            
            for i = questLogIndex - 1, 1, -1 do
                local headerTitle, headerLevel, headerType, _, _, _, _, _, _, _, _, isHeader = GetQuestLogTitle(i)
                if headerLevel == 0 and headerType == nil then
                    questGroup = headerTitle
                    break
                end
            end
            
            
            if questGroup and (questGroup:lower():find("сюжет")) then
                questType = "(Сюжетный)"
                questGroup = nil
            elseif (questGroup and not questGroup:lower():find("особ")) and ((questType and not questType:lower():find("рей") and not questType:lower():find("подземель")) or (not questType)) then
                questGroup = nil
            end

            local locationName = CleanLocationString(GetRealZoneText() or GetZoneText())

            local x, y = 0, 0
            if SetMapToCurrentZone then SetMapToCurrentZone() end
            if GetPlayerMapPosition then
                x, y = GetPlayerMapPosition("player")
                x = math.floor((x or 0) * 10000) / 100
                y = math.floor((y or 0) * 10000) / 100
            end
            local coordinates = { x = x, y = y }

            local npcName = nil
            
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

-- Получение информации для истории по текущему квесту
local function GetInfoForHistory(currentNPC)
    local questID = nil
    local questData = nil
    if GetQuestID then
        questID = GetQuestID()
        if questID and questID ~= 0 then
            questData = MQSH_QuestDB[questID]
        end
    end
    return questID, questData
end

-- Сохранение информации о завершении квеста в историю
local function SaveQuestInfoToHistory(questID, currentNPC)
    local questData = nil
    if questID then
        questData = MQSH_QuestDB[questID]
        local x, y = 0, 0
        if SetMapToCurrentZone then SetMapToCurrentZone() end
        if GetPlayerMapPosition then
            x, y = GetPlayerMapPosition("player")
            x = math.floor((x or 0) * 10000) / 100
            y = math.floor((y or 0) * 10000) / 100
        end
        local completionCoordinates = { x = x, y = y }
        local completionNPC = currentNPC or "Неизвестный NPC"
        local historyData = {
            timeCompleted = date("%d.%m.%y %H:%M:%S"),
            completionNPC = completionNPC,
            completionLocation = CleanLocationString(GetRealZoneText() or GetZoneText()),
            completionCoordinates = completionCoordinates
        }
        MQSH_Char_HistoryDB[questID] = historyData
    end
end

local function QuestDataBaseController_OnLoad()
    local currentNPC = nil
    local questComplete = false
    local completedQuestID = nil

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_FINISHED")
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:RegisterEvent("QUEST_COMPLETE")

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "GOSSIP_SHOW" or event == "QUEST_DETAIL" then
            currentNPC = UnitName("npc")
        elseif event == "QUEST_COMPLETE" then
            local questID, questData = GetInfoForHistory(currentNPC)
            completedQuestID = questID
            questComplete = true
            currentNPC = UnitName("npc")
        elseif event == "QUEST_ACCEPTED" then
            local questLogIndex, questIDFromEvent = ...
            local npcName = currentNPC
            questComplete = false
            completedQuestID = nil
            C_Timer:After(0.05, function()
                local questID, questData = GetQuestIDAndData(questLogIndex, npcName)
                if questID and questData and not MQSH_QuestDB[questID] then
                    MQSH_QuestDB[questID] = questData
                end
                currentNPC = nil
            end)
        elseif event == "GOSSIP_CLOSED" then
            currentNPC = nil
        elseif event == "QUEST_FINISHED" then
            if questComplete == true then
                SaveQuestInfoToHistory(completedQuestID, currentNPC)
                questComplete = false
                currentNPC = nil
                completedQuestID = nil
            else
                questComplete = false
                completedQuestID = nil
            end
        end
    end)
end

_G.QuestDataBaseController_OnLoad = QuestDataBaseController_OnLoad