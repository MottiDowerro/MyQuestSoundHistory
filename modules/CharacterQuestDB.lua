if not MQSH_Char_HistoryDB then
    MQSH_Char_HistoryDB = {}
end

-- Функция для очистки строки от лишних пробелов
local function CleanLocationString(str)
    if not str then return nil end
    return str:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
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

local function CharacterQuestDB_OnLoad()
    local currentNPC = nil
    local questComplete = false
    local completedQuestID = nil

    local frame = CreateFrame("Frame")
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

_G.CharacterQuestDB_OnLoad = CharacterQuestDB_OnLoad

-- API для доступа к данным
_G.MQSH_API.GetQuestHistory = function(questID)
    return MQSH_Char_HistoryDB[questID]
end

_G.MQSH_API.GetAllHistory = function()
    local history = {}
    for id, data in pairs(MQSH_Char_HistoryDB) do
        table.insert(history, {id = id, data = data})
    end
    return history
end
