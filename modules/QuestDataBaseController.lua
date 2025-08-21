if not MQSH_QuestDB then
    MQSH_QuestDB = {}
end

if not MQSH_Char_HistoryDB then
    MQSH_Char_HistoryDB = {}
end
local function WithQuestLogSelection(index, func)
    local prev = GetQuestLogSelection()
    SelectQuestLogEntry(index)
    local ok, err = pcall(func)
    if prev and prev > 0 then
        SelectQuestLogEntry(prev)
    end
end

local function CleanLocationString(str)
    if not str then return nil end
    return str:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
end

local function GetQuestBasicInfo(questLogIndex)
    local title, level, questType, _, _, _, _, _, qID = GetQuestLogTitle(questLogIndex)
    local questID = qID and qID ~= 0 and qID or (GetQuestID and GetQuestID())
    if not questID then return nil end

    local description, objectivesText = GetQuestLogQuestText()
    return {
        questID = questID,
        title = title,
        level = level,
        questType = questType,
        description = description,
        objectivesText = objectivesText
    }
end

local function GetQuestGroup(questLogIndex, questType)
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

    return questGroup, questType
end

local function GetLocationAndCoordinates()
    local locationName = CleanLocationString(GetRealZoneText() or GetZoneText())
    local x, y = 0, 0
    if SetMapToCurrentZone then SetMapToCurrentZone() end
    if GetPlayerMapPosition then
        x, y = GetPlayerMapPosition("player")
        x = math.floor((x or 0) * 10000) / 100
        y = math.floor((y or 0) * 10000) / 100
    end
    return locationName, { x = x, y = y }
end

local function GetQuestObjectives(questID)
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
    return objectives
end

local function GetQuestRewards(questID)
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

    return rewards
end

local function AssembleQuestData(basicInfo, questGroup, questType, locationName, coordinates, npcName, objectives, rewards)
    return {
        title           = basicInfo.title,
        level           = basicInfo.level,
        description     = basicInfo.description,
        objectivesText  = basicInfo.objectivesText,
        objectives      = objectives,
        rewards         = rewards,
        npcName         = npcName,
        mainZone        = locationName,
        coordinates     = coordinates,
        questGroup      = questGroup,
        questType       = questType,
    }
end

local function GetQuestIDAndData(questLogIndex, currentNPC)
    local questID, questData
    WithQuestLogSelection(questLogIndex, function()
        local basicInfo = GetQuestBasicInfo(questLogIndex)
        if not basicInfo then return end
        questID = basicInfo.questID

        local questGroup, questType = GetQuestGroup(questLogIndex, basicInfo.questType)
        local locationName, coordinates = GetLocationAndCoordinates()
        local objectives = GetQuestObjectives(questID)
        local rewards = GetQuestRewards(questID)
        local npcName = currentNPC and currentNPC ~= "" and currentNPC or "Неизвестный NPC"

        questData = AssembleQuestData(basicInfo, questGroup, questType, locationName, coordinates, npcName, objectives, rewards)
    end)
    return questID, questData
end

local function SaveAcceptedQuestToDB(questLogIndex, currentNPC)
    local questID, questData = GetQuestIDAndData(questLogIndex, currentNPC)
    if questID and questData and not MQSH_QuestDB[questID] then
        MQSH_QuestDB[questID] = questData
        MQSH_Char_HistoryDB[questID] = MQSH_Char_HistoryDB[questID] or {}
        MQSH_Char_HistoryDB[questID].timeAccepted = date("%d.%m.%y %H:%M:%S")
        MQSH_Char_HistoryDB[questID].questID = questID
    end
end

local function GetInfoForHistory(currentNPC)
    local questID = GetQuestID and GetQuestID()
    local questData = questID and questID ~= 0 and MQSH_QuestDB[questID]
    return questID, questData
end

local function SaveQuestInfoToHistory(questID, currentNPC)
    if not questID then return end
    local _, completionCoordinates = GetLocationAndCoordinates()
    local completionNPC = currentNPC or "Неизвестный NPC"
    local historyData = {
        timeCompleted = date("%d.%m.%y %H:%M:%S"),
        completionNPC = completionNPC,
        completionLocation = CleanLocationString(GetRealZoneText() or GetZoneText()),
        completionCoordinates = completionCoordinates
    }
    MQSH_Char_HistoryDB[questID] = historyData
end

local function QuestDataBaseController_OnLoad()
    local currentNPC
    local questComplete = false
    local completedQuestID

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
            questComplete = false
            completedQuestID = nil
            SaveAcceptedQuestToDB(questLogIndex, currentNPC)
            currentNPC = nil
        elseif event == "GOSSIP_CLOSED" then
            currentNPC = nil
        elseif event == "QUEST_FINISHED" then
            if questComplete then
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