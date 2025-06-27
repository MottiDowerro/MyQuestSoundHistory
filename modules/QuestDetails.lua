-- QuestDetails.lua
-- Модуль для отображения деталей квеста

local QuestDetails = {}

-- Вспомогательные переменные (будут передаваться через параметры или инициализироваться снаружи)
local rewardItemFrames, objectiveItemFrames, rewardsVisibleCount, objectiveItemsVisibleCount
local objectivesSummaryFS, objectivesTextFS, detailsFS, rewardsHeadingFS, rewardExtraFS, choiceLabelFS, descHeadingFS, detailsTitle
local rightContent, rightScrollFrame, rightScrollbar
local selectedButton

-- Функции для инициализации переменных (чтобы не было глобальных зависимостей)
function QuestDetails.InitVars(vars)
    rewardItemFrames = vars.rewardItemFrames
    objectiveItemFrames = vars.objectiveItemFrames
    rewardsVisibleCount = vars.rewardsVisibleCount
    objectiveItemsVisibleCount = vars.objectiveItemsVisibleCount
    objectivesSummaryFS = vars.objectivesSummaryFS
    objectivesTextFS = vars.objectivesTextFS
    detailsFS = vars.detailsFS
    rewardsHeadingFS = vars.rewardsHeadingFS
    rewardExtraFS = vars.rewardExtraFS
    choiceLabelFS = vars.choiceLabelFS
    descHeadingFS = vars.descHeadingFS
    detailsTitle = vars.detailsTitle
    rightContent = vars.rightContent
    rightScrollFrame = vars.rightScrollFrame
    rightScrollbar = vars.rightScrollbar
    selectedButton = vars.selectedButton
end

-- Вспомогательные функции для отображения деталей квеста
QuestDetails.ClearQuestDetails = function()
    if objectivesSummaryFS then objectivesSummaryFS:SetText("") end
    if objectivesTextFS then objectivesTextFS:SetText("") end
    if detailsFS then detailsFS:SetText("") end
    if rewardsHeadingFS then rewardsHeadingFS:SetText("") end
    if rewardExtraFS then rewardExtraFS:SetText("") end
    if choiceLabelFS then choiceLabelFS:SetText("") end
    
    for _, f in ipairs(rewardItemFrames) do f:Hide() end
    rewardsVisibleCount = 0
    
    -- Очистка предметов-целей
    for _, f in ipairs(objectiveItemFrames) do f:Hide() end
    objectiveItemsVisibleCount = 0
end

QuestDetails.SetupQuestTitle = function(questID, q)
    local gold = "|cffFFD100"
    local reset = "|r"
    local title = q.title or ("ID " .. tostring(questID))
    
    if detailsTitle then
        detailsTitle:SetText(gold .. title .. reset)
    end
end

QuestDetails.SetupObjectivesSummary = function(q)
    local white = "|cffffffff"
    local reset = "|r"
    
    if not objectivesSummaryFS then
        objectivesSummaryFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
        objectivesSummaryFS:SetJustifyH("LEFT")
    end
    
    if q.objectivesText and q.objectivesText ~= "" then
        objectivesSummaryFS:SetText(white .. q.objectivesText .. reset)
    else
        objectivesSummaryFS:SetText("")
    end
end

QuestDetails.SetupDetailedObjectives = function(q)
    local grey = "|cffAAAAAA"
    local reset = "|r"
    
    if q.objectives and #q.objectives > 0 then
        if not objectivesTextFS then
            objectivesTextFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
            objectivesTextFS:SetJustifyH("LEFT")
        end

        local objLines = {}
        local objectiveItems = q.objectiveItems or {}
        
        -- Создаем словарь предметов-целей для быстрого поиска
        local itemObjectives = {}
        for _, item in ipairs(objectiveItems) do
            itemObjectives[item.name] = item
        end
        
        for _, obj in ipairs(q.objectives) do
            -- Проверяем, является ли эта цель предметом
            local isItemObjective = false
            for itemName, itemData in pairs(itemObjectives) do
                if obj:find(itemName, 1, true) then -- Точное совпадение имени предмета
                    isItemObjective = true
                    break
                end
            end
            
            if not isItemObjective then
                -- Если это не предмет, добавляем как обычный текст
                table.insert(objLines, grey .. obj .. reset .. "\n")
            end
            -- Если это предмет, пропускаем - он будет отображен отдельно
        end
        objectivesTextFS:SetText(table.concat(objLines, ""))
    elseif objectivesTextFS then
        objectivesTextFS:SetText("")
    end
end

QuestDetails.SetupDescription = function(q)
    local white = "|cffffffff"
    local gold = "|cffFFD100"
    local reset = "|r"
    
    if not descHeadingFS then
        descHeadingFS = ScrollBarUtils.CreateFS(rightContent, "GameFontNormalHuge")
        ScrollBarUtils.RemoveFontOutline(descHeadingFS)
        descHeadingFS:SetJustifyH("LEFT")
    end
    
    if q.description and q.description ~= "" then
        descHeadingFS:SetText(gold .. "Описание:" .. reset)
        
        local descText = white .. q.description:gsub("\n+$", "") .. reset
        if detailsFS then
            detailsFS:SetText(descText)
        end
    else
        descHeadingFS:SetText("")
        if detailsFS then
            detailsFS:SetText("")
        end
    end
end

-- Универсальные функции для работы с предметами
QuestDetails.GetItemTexture = function(item)
    local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    if item.itemID then
        local itemTexture = GetItemIcon(item.itemID)
        if itemTexture then
            texture = itemTexture
        end
    elseif item.name then
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item.name)
        if itemTexture then
            texture = itemTexture
        end
    end
    return texture
end

QuestDetails.SetupItemFrame = function(row, item, frameWidth, ICON_SIZE, ITEM_HEIGHT)
    row:SetWidth(frameWidth)
    row:SetHeight(ITEM_HEIGHT)
    
    -- Получаем текстуру предмета
    local texture = QuestDetails.GetItemTexture(item)
    row.icon:SetTexture(texture)
    
    -- Настраиваем текст
    local nameTxt = item.name or ""
    row.text:SetWidth(frameWidth - (ICON_SIZE+10))
    row.text:SetText(nameTxt)
    if not row.text.SetMaxLines then
        row.text:SetHeight(ITEM_HEIGHT - 5)
    end
    
    -- Позиционируем элементы
    row.iconBorder:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text:SetPoint("LEFT", row.iconBorder, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    
    -- Сохраняем данные предмета
    row.itemID = item.itemID
    row.itemName = item.name
    row:Show()
end

QuestDetails.HideUnusedFrames = function(frames, usedCount)
    for i = usedCount + 1, #frames do
        frames[i]:Hide()
    end
end

QuestDetails.CreateItemFrame = function(index, showCount)
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    
    local row = CreateFrame("Frame", nil, rightContent)
    ScrollBarUtils.SetBackdrop(row, {0,0,0,0.2}, {1,1,1,1})
    row:EnableMouse(true)

    row.iconBorder = CreateFrame("Frame", nil, row)
    ScrollBarUtils.SetBackdrop(row.iconBorder, {0,0,0,1}, {1,1,1,1})
    row.iconBorder:SetSize(ICON_SIZE+4, ICON_SIZE+4)

    row.icon = row.iconBorder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("CENTER")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetTexCoord(5/64,59/64,5/64,59/64)

    row.text = ScrollBarUtils.CreateFS(row, "GameFontHighlight")
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("MIDDLE")
    
    -- Добавляем текст количества на иконку только для предметов-целей
    if showCount then
        row.countText = row.iconBorder:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        row.countText:SetJustifyH("RIGHT")
        row.countText:SetJustifyV("BOTTOM")
        row.countText:SetPoint("BOTTOMRIGHT", row.iconBorder, "BOTTOMRIGHT", -2, 2)
        row.countText:SetTextColor(1, 1, 1)
    end
    
    return row
end

-- Обратная совместимость - оставляем старые функции как алиасы
QuestDetails.CreateRewardItemFrame = function(index)
    return QuestDetails.CreateItemFrame(index, false)
end

QuestDetails.CreateObjectiveItemFrame = function(index)
    return QuestDetails.CreateItemFrame(index, true)
end

QuestDetails.SetupItemTooltip = function(row)
    row:SetScript("OnEnter", function(self)
        if not self.highlight then
            self.highlight = self:CreateTexture(nil, "BACKGROUND")
            self.highlight:SetAllPoints(self)
            self.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
            self.highlight:SetAlpha(0.4)
            self.highlight:SetBlendMode("ADD")
        end
        self.highlight:Show()

        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then
                GameTooltip:SetItemByID(self.itemID)
            else
                GameTooltip:SetHyperlink("item:" .. self.itemID)
            end
            GameTooltip:Show()
        elseif self.itemName then
            local _, name = GetItemInfo(self.itemName)
            if name then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(name)
                GameTooltip:Show()
            end
        end
    end)

    row:SetScript("OnLeave", function(self)
        if self.highlight then
            self.highlight:Hide()
        end
        GameTooltip:Hide()
    end)
end

-- Обратная совместимость - оставляем старые функции как алиасы
QuestDetails.SetupRewardItemTooltip = QuestDetails.SetupItemTooltip
QuestDetails.SetupObjectiveItemTooltip = QuestDetails.SetupItemTooltip

QuestDetails.SetupRewardItems = function(q)
    if not q.rewards then return end
    
    local itemsCount = q.rewards.items and #q.rewards.items or 0
    local choicesCount = q.rewards.choices and #q.rewards.choices or 0
    
    local hasRewards = (itemsCount > 0) or (choicesCount > 0) or 
                      (q.rewards.money and q.rewards.money > 0) or 
                      (q.rewards.xp and q.rewards.xp > 0)
    
    if not hasRewards then return end
    
    if not rewardsHeadingFS then
        rewardsHeadingFS = ScrollBarUtils.CreateFS(rightContent, "GameFontNormalHuge")
        ScrollBarUtils.RemoveFontOutline(rewardsHeadingFS)
    end
    rewardsHeadingFS:SetText("|cffFFD100Награды:|r")
    
    local rewardItems = {}
    if choicesCount > 0 then
        for _, item in ipairs(q.rewards.choices) do
            table.insert(rewardItems, item)
        end
    end
    if itemsCount > 0 then
        for _, item in ipairs(q.rewards.items) do
            table.insert(rewardItems, item)
        end
    end
    
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    local frameWidth = rightScrollFrame:GetWidth()
    
    for i, item in ipairs(rewardItems) do
        local row = rewardItemFrames[i]
        if not row then
            row = QuestDetails.CreateRewardItemFrame(i)
            rewardItemFrames[i] = row
            QuestDetails.SetupRewardItemTooltip(row)
        end
        
        QuestDetails.SetupItemFrame(row, item, frameWidth, ICON_SIZE, ITEM_HEIGHT)
    end
    
    QuestDetails.HideUnusedFrames(rewardItemFrames, #rewardItems)
    
    rewardsVisibleCount = #rewardItems
end

QuestDetails.SetupExtraRewards = function(q)
    if not q.rewards then return end
    
    if not rewardExtraFS then
        rewardExtraFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    end
    
    local extraLines = {}
    
    if q.rewards.money and q.rewards.money > 0 then
        local coinStr = GetCoinTextureString(q.rewards.money, 20)
        table.insert(extraLines, "Вы также получите: " .. coinStr)
    end
    
    if q.rewards.xp and q.rewards.xp > 0 then
        table.insert(extraLines, "Опыт: " .. ((BreakUpLargeNumbers and BreakUpLargeNumbers(q.rewards.xp)) or q.rewards.xp))
    end
    
    rewardExtraFS:SetSpacing(4)
    rewardExtraFS:SetText(table.concat(extraLines, "\n"))
end

QuestDetails.SetupObjectiveItems = function(q)
    if not q.objectiveItems or #q.objectiveItems == 0 then return end
    
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    local frameWidth = rightScrollFrame:GetWidth()
    
    for i, item in ipairs(q.objectiveItems) do
        local row = objectiveItemFrames[i]
        if not row then
            row = QuestDetails.CreateObjectiveItemFrame(i)
            objectiveItemFrames[i] = row
            QuestDetails.SetupObjectiveItemTooltip(row)
        end
        
        QuestDetails.SetupItemFrame(row, item, frameWidth, ICON_SIZE, ITEM_HEIGHT)
        
        -- Устанавливаем количество на иконку (специфично для предметов-целей)
        if item.count and row.countText then
            row.countText:SetText(tostring(item.count))
            row.countText:Show()
        elseif row.countText then
            row.countText:Hide()
        end
        
        -- Применяем цвет к тексту (специфично для предметов-целей)
        row.text:SetText("|cffffffff" .. (item.name or "") .. "|r")
    end
    
    QuestDetails.HideUnusedFrames(objectiveItemFrames, #q.objectiveItems)
    
    objectiveItemsVisibleCount = #q.objectiveItems
end

QuestDetails.LayoutQuestDetails = function()
    local yOffset = -detailsTitle:GetStringHeight() - 5
    
    if objectivesSummaryFS then
        objectivesSummaryFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if objectivesSummaryFS:GetText() ~= "" then
            yOffset = yOffset - objectivesSummaryFS:GetStringHeight() - 6
        end
    end
    
    if objectivesTextFS then
        objectivesTextFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if objectivesTextFS:GetText() ~= "" then
            yOffset = yOffset - objectivesTextFS:GetStringHeight() + 5
        end
    end
    
    -- Размещение предметов-целей сразу после текстовых целей
    if objectiveItemsVisibleCount > 0 then
        yOffset = yOffset - 8 -- Дополнительный отступ перед предметами-целями
        
        local colSpacing, rowSpacing = 4, 4
        local frameWidth = rightScrollFrame:GetWidth()
        local itemW = (frameWidth - colSpacing) / 2
        local currentIndex = 0
        
        for _, row in ipairs(objectiveItemFrames) do
            if row:IsShown() then
                local col = currentIndex % 2
                local rowIdx = math.floor(currentIndex / 2)
                local xOff = col * (itemW + colSpacing)
                local yOff = yOffset - rowIdx * (row:GetHeight() + rowSpacing)
                
                row:SetWidth(itemW)
                row:SetPoint("TOPLEFT", rightContent, "TOPLEFT", xOff, yOff)
                currentIndex = currentIndex + 1
            end
        end
        
        local rows = math.ceil(objectiveItemsVisibleCount / 2)
        if rows > 0 then
            yOffset = yOffset - rows * (objectiveItemFrames[1]:GetHeight() + rowSpacing)
        end
    end
    
    -- Дополнительный отступ перед описанием, если нет серых целей и предметов
    local objectivesText = objectivesTextFS and objectivesTextFS:GetText()
    local hasTextObjectives = objectivesText and objectivesText ~= ""
    local hasObjectiveItems = objectiveItemsVisibleCount > 0
    
    if not hasTextObjectives and not hasObjectiveItems then
        yOffset = yOffset - 6
    end
    
    if descHeadingFS then
        descHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if descHeadingFS:GetText() ~= "" then
            yOffset = yOffset - descHeadingFS:GetStringHeight() - 6
        end
    end
    
    if detailsFS then
        detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if detailsFS:GetText() ~= "" then
            yOffset = yOffset - detailsFS:GetStringHeight() - 10
        end
    end
    
    if rewardsHeadingFS and rewardsHeadingFS:GetText() ~= "" then
        rewardsHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - rewardsHeadingFS:GetStringHeight() - 2
        
        local colSpacing, rowSpacing = 4, 4
        local frameWidth = rightScrollFrame:GetWidth()
        local itemW = (frameWidth - colSpacing) / 2
        local currentIndex = 0
        
        for _, row in ipairs(rewardItemFrames) do
            if row:IsShown() then
                local col = currentIndex % 2
                local rowIdx = math.floor(currentIndex / 2)
                local xOff = col * (itemW + colSpacing)
                local yOff = yOffset - rowIdx * (row:GetHeight() + rowSpacing)
                
                row:SetWidth(itemW)
                row:SetPoint("TOPLEFT", rightContent, "TOPLEFT", xOff, yOff)
                currentIndex = currentIndex + 1
            end
        end
        
        local rows = math.ceil(rewardsVisibleCount / 2)
        if rows > 0 then
            yOffset = yOffset - rows * (rewardItemFrames[1]:GetHeight() + rowSpacing)
        end
        
        if rewardExtraFS then
            rewardExtraFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
            if rewardExtraFS:GetText() ~= "" then
                yOffset = yOffset - rewardExtraFS:GetStringHeight() - 4
            end
        end
    end
    
    local totalHeight = -yOffset + 10
    rightContent:SetHeight(totalHeight)
    rightScrollFrame:SetVerticalScroll(0)
    
    ScrollBarUtils.UpdateScrollBar(rightScrollFrame, rightScrollbar)
end

QuestDetails.ShowQuestDetails = function(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then return end
    
    local q = MQSH_QuestDB[questID]
    
    QuestDetails.ClearQuestDetails()
    QuestDetails.SetupQuestTitle(questID, q)
    QuestDetails.SetupObjectivesSummary(q)
    QuestDetails.SetupDetailedObjectives(q)
    QuestDetails.SetupDescription(q)
    QuestDetails.SetupRewardItems(q)
    QuestDetails.SetupExtraRewards(q)
    QuestDetails.SetupObjectiveItems(q)
    QuestDetails.LayoutQuestDetails()
end

QuestDetails.HighlightQuestButton = function(btn)
    if selectedButton and selectedButton.selTexture then
        selectedButton.selTexture:Hide()
    end
    selectedButton = btn
    if selectedButton and selectedButton.selTexture then
        selectedButton.selTexture:Show()
    end
end

-- Экспортируем модуль в глобальную область
_G.QuestDetails = QuestDetails 