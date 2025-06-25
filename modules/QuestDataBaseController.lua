if not MQSH_QuestDB then
    MQSH_QuestDB = {}
end

local function WithQuestLogSelection(index, func)
    local prev = GetQuestLogSelection()
    SelectQuestLogEntry(index)
    local ok, err = pcall(func)
    if prev and prev > 0 then
        SelectQuestLogEntry(prev)
    end
end

local function GetQuestIDByLogIndex(index)
    local _, _, _, _, _, _, _, qID = GetQuestLogTitle(index)
    if qID and qID ~= 0 then return qID end

    if GetQuestID then
        local id
        WithQuestLogSelection(index, function()
            id = GetQuestID()
        end)
        if id and id ~= 0 then return id end
    end

    return nil
end

local function AddQuestToDB(questID, questLogIndex)
    if MQSH_QuestDB[questID] then
        return
    end

    WithQuestLogSelection(questLogIndex, function()
        local title, level = select(1, GetQuestLogTitle(questLogIndex)) or "Unknown", select(2, GetQuestLogTitle(questLogIndex)) or 0
        local description, objectivesText = GetQuestLogQuestText()

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

        local rewards = {
            items   = {},
            choices = {},
            money   = GetQuestLogRewardMoney() or 0,
            xp      = GetQuestLogRewardXP and (GetQuestLogRewardXP() or 0) or nil,
        }

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

        local numChoices = GetNumQuestLogChoices()
        if numChoices and numChoices > 0 then
            for i = 1, numChoices do
                local itemName, itemTexture, _, _, _, itemID = GetQuestLogChoiceInfo(i)
                if itemName then
                    table.insert(rewards.choices, {
                        name    = itemName,
                        texture = itemTexture,
                        itemID  = itemID,
                    })
                end
            end
        end

        MQSH_QuestDB[questID] = {
            title       = title,
            level       = level,
            description = description,
            objectivesText = objectivesText,
            objectives  = objectives,
            rewards     = rewards,
        }
    end)
end

local function QuestDataBaseController_OnLoad()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("QUEST_ACCEPTED")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "QUEST_ACCEPTED" then
            local questLogIndex, questIDFromEvent = ...

            C_Timer:After(1, function()
                local questID = questIDFromEvent or GetQuestIDByLogIndex(questLogIndex)
                if questID then
                    AddQuestToDB(questID, questLogIndex)
                end
            end)
        end
    end)
end

_G.QuestDataBaseController_OnLoad = QuestDataBaseController_OnLoad