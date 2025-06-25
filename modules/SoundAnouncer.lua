local function SoundAnouncer_OnLoad()
    
    local checkForUpdate = nil
    local f = CreateFrame("Frame")

    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    
    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "QUEST_WATCH_UPDATE" then
            if arg1 then
                checkForUpdate = arg1
            end
        elseif event == "QUEST_LOG_UPDATE" and checkForUpdate then
            print(self, event, arg1, arg2)
            local questId = checkForUpdate
            local numObjectives = GetNumQuestLeaderBoards(questId)

            if numObjectives == 0 then 
                checkForUpdate = nil 
                return 
            end
            
            local allComplete = true
            local singleCompleted = false
            
            for i = 1, numObjectives do
                local _, _, isCompleted = GetQuestLogLeaderBoard(i, questId)
                if isCompleted then
                    singleCompleted = true
                elseif allComplete then
                    allComplete = false
                end
            end
            
            if allComplete and MyQuestSoundHistoryDB.enableWorkComplete then
                PlaySoundFile(MyQuestSoundHistoryDB.workCompleteSound)
                checkForUpdate = nil
            elseif singleCompleted and MyQuestSoundHistoryDB.enableSingleComplete then
                PlaySoundFile(MyQuestSoundHistoryDB.singleCompleteSound)
            elseif not singleCompleted and MyQuestSoundHistoryDB.enableProgressSound then
                PlaySoundFile(MyQuestSoundHistoryDB.progressSound)
            end
        end
    end)
end

_G.SoundAnouncer_OnLoad = SoundAnouncer_OnLoad