if not MQSH_QuestDB then
    MQSH_QuestDB = {}
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
            local numObjectives = GetNumQuestLeaderBoards(questID)
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

            local numRewards = GetNumQuestLogRewards(questID)
            if numRewards and numRewards > 0 then
                for i = 1, numRewards do
                    local itemName, _, numItems, _, _ = GetQuestLogRewardInfo(i, questID)
                    if itemName then
                        table.insert(rewards.items, {
                            name = itemName,
                            numItems = numItems,
                        })
                    end
                end
            end

            local numChoices = GetNumQuestLogChoices(questID)
            if numChoices and numChoices > 0 then
                for i = 1, numChoices do
                    local itemName, _, numItems, _, _ = GetQuestLogChoiceInfo(i, questID)
                    if itemName then
                        table.insert(rewards.choices, {
                            name = itemName,
                            numItems  = numItems,
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

local function QuestDB_OnLoad()
    local currentNPC = nil

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("QUEST_DETAIL")

    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "GOSSIP_SHOW" or event == "QUEST_DETAIL" then
            currentNPC = UnitName("npc")
        elseif event == "QUEST_ACCEPTED" then
            local questLogIndex, questIDFromEvent = ...
            local npcName = currentNPC
            local questID, questData = GetQuestIDAndData(questLogIndex, npcName)
            if questID and questData and not MQSH_QuestDB[questID] then
                MQSH_QuestDB[questID] = questData
            end
            currentNPC = nil
        end
    end)
end

_G.QuestDB_OnLoad = QuestDB_OnLoad

-- API для доступа к данным
_G.MQSH_API.GetQuestData = function(questID)
    return MQSH_QuestDB[questID]
end

_G.MQSH_API.GetAllQuests = function()
    local quests = {}
    for id, data in pairs(MQSH_QuestDB) do
        table.insert(quests, {id = id, data = data})
    end
    return quests
end
