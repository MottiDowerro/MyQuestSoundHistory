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
        -- Backward compatibility: Ascension возвращает 9 параметров, стандартный WoW - 8
        local title, level, questType, _, _, _, _, qID8, qID9 = GetQuestLogTitle(questLogIndex)
        local qID = qID9 or qID8  -- Используем 9-й параметр если есть, иначе 8-й
        
        if qID and qID ~= 0 then
            questID = qID
        elseif GetQuestID then
            questID = GetQuestID()
        end

        if questID then
            local description, objectivesText = GetQuestLogQuestText()
            local questGroup = nil
            
            for i = questLogIndex - 1, 1, -1 do
                local headerTitle, headerLevel, headerType, _, _, _, _, headerQID, _, _, _, isHeader = GetQuestLogTitle(i)
                if headerLevel == 0 and headerType == nil and headerQID == nil then
                    questGroup = headerTitle
                    break
                end
            end
            
            if questGroup and (questGroup:lower():find("сюжет") or questGroup:lower():find("story")) then
                questType = "(Сюжетный)"
                questGroup = nil
            end

            if questGroup and not questGroup:lower():find("особ") and questType and not questType:lower():find("рей") and not questType:lower():find("подземель") then
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

-- Helper to safely delay execution using OnUpdate
local function SafeAfter(delaySeconds, callback)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delaySeconds then
            self:SetScript("OnUpdate", nil)
            if callback then
                pcall(callback)
            end
        end
    end)
end

local function QuestDataBaseController_OnLoad()
    local currentNPC = nil
    local questComplete = false
    
    local function GetInfoForHistory()
        local questID = nil
        local questData = nil
        
        if GetQuestID then
            questID = GetQuestID()
            if questID and questID ~= 0 then
                questData = MQSH_QuestDB[questID]
            end
        end
        
        -- Если не получилось, ищем по квест логу
        if not questID or questID == 0 then
            local numQuestLogEntries = GetNumQuestLogEntries()
            
            for i = 1, numQuestLogEntries do
                local title, level, questType, _, _, _, _, qID8, qID9 = GetQuestLogTitle(i)
                local qID = qID9 or qID8  -- Backward compatibility
                
                if qID and qID ~= 0 and MQSH_QuestDB[qID] then
                    questID = qID
                    questData = MQSH_QuestDB[qID]
                    break
                end
            end
            
            -- Последняя попытка - поиск по названию
            if not questID and GetTitleText then
                local currentTitle = GetTitleText()
                if currentTitle then
                    for id, data in pairs(MQSH_QuestDB) do
                        if data.title == currentTitle then
                            questID = id
                            questData = data
                            break
                        end
                    end
                end
            end
        end
        
        return questID, questData
    end

    local completedQuestID = nil

    local function SaveQuestInfoToHistory()
        local questID = completedQuestID
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
            currentNPC = UnitName("npc")
            questComplete = true
            
            local questID, questData = GetInfoForHistory()
            
            -- Если не нашли через GetInfoForHistory, попробуем напрямую по квест логу
            if not questID then
                local numQuestLogEntries = GetNumQuestLogEntries()
                for i = 1, numQuestLogEntries do
                    local title, level, questType, _, _, _, _, qID8, qID9 = GetQuestLogTitle(i)
                    local qID = qID9 or qID8  -- Backward compatibility
                    
                    if qID and qID ~= 0 and MQSH_QuestDB[qID] then
                        questID = qID
                        questData = MQSH_QuestDB[qID]
                        break
                    end
                end
            end
            
            completedQuestID = questID
        elseif event == "QUEST_ACCEPTED" then
            local questLogIndex, questIDFromEvent = ...
            local npcName = currentNPC
            questComplete = false
            completedQuestID = nil
            SafeAfter(0.05, function()
                local questID, questData = GetQuestIDAndData(questLogIndex, npcName)
                
                if questID and questData and not MQSH_QuestDB[questID] then
                    MQSH_QuestDB[questID] = questData
                    
                    -- Update UI if overlay is visible
                    if _G.MQSH_QuestOverlay and _G.MQSH_QuestOverlay:IsVisible() then
                        if _G.QuestList and _G.QuestList.BuildQuestList then
                            _G.QuestList.BuildQuestList()
                        end
                        if _G.UpdateQuestCountText then
                            _G.UpdateQuestCountText()
                        end
                    end
                end
                currentNPC = nil
            end)
        elseif event == "GOSSIP_CLOSED" then
            currentNPC = nil
        elseif event == "QUEST_FINISHED" then
            if questComplete == true then
                SaveQuestInfoToHistory()
                
                -- Update UI if overlay is visible
                if _G.MQSH_QuestOverlay and _G.MQSH_QuestOverlay:IsVisible() then
                    if _G.QuestList and _G.QuestList.BuildQuestList then
                        _G.QuestList.BuildQuestList()
                    end
                    if _G.UpdateQuestCountText then
                        _G.UpdateQuestCountText()
                    end
                end
                
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