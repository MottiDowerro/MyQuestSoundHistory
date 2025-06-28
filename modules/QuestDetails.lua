local QuestDetails = {}

-- Вспомогательные переменные (будут передаваться через параметры или инициализироваться снаружи)
local rewardItemFrames, objectiveItemFrames, rewardsVisibleCount, objectiveItemsVisibleCount
local objectivesSummaryFS, objectivesTextFS, detailsFS, rewardsHeadingFS, rewardExtraFS, choiceLabelFS, descHeadingFS, detailsTitle
local questMetaFS -- Новый элемент для метаданных квеста
local rightContent, rightScrollFrame, rightScrollbar
local selectedButton

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
    questMetaFS = vars.questMetaFS
    rightContent = vars.rightContent
    rightScrollFrame = vars.rightScrollFrame
    rightScrollbar = vars.rightScrollbar
    selectedButton = vars.selectedButton
end

-- Вспомогательные функции для отображения деталей квеста
QuestDetails.ClearQuestDetails = function()
    -- Очищаем все текстовые элементы и их позиции
    if objectivesSummaryFS then 
        objectivesSummaryFS:SetText("") 
        objectivesSummaryFS:ClearAllPoints()
    end
    if objectivesTextFS then 
        objectivesTextFS:SetText("") 
        objectivesTextFS:ClearAllPoints()
    end
    if detailsFS then 
        detailsFS:SetText("") 
        detailsFS:ClearAllPoints()
    end
    if rewardsHeadingFS then 
        rewardsHeadingFS:SetText("") 
        rewardsHeadingFS:ClearAllPoints()
    end
    if rewardExtraFS then 
        rewardExtraFS:SetText("") 
        rewardExtraFS:ClearAllPoints()
    end
    if choiceLabelFS then 
        choiceLabelFS:SetText("") 
        choiceLabelFS:ClearAllPoints()
    end
    if descHeadingFS then
        descHeadingFS:SetText("")
        descHeadingFS:ClearAllPoints()
    end
    if questMetaFS then
        questMetaFS:SetText("")
        questMetaFS:ClearAllPoints()
    end
    if detailsTitle then
        detailsTitle:SetText("")
        detailsTitle:ClearAllPoints()
    end
    for i, f in ipairs(rewardItemFrames) do 
        f:Hide() 
        f:ClearAllPoints()
    end
    rewardsVisibleCount = 0
    for i, f in ipairs(objectiveItemFrames) do 
        f:Hide() 
        f:ClearAllPoints()
    end
    objectiveItemsVisibleCount = 0
    
    if rightContent then
        rightContent:SetHeight(1)
    end
end

QuestDetails.SetupQuestTitle = function(questID, q)
    local gold = "|cffFFD100"
    local reset = "|r"
    local title = q.title or ("ID " .. tostring(questID))
    
    if detailsTitle then
        detailsTitle:SetText(gold .. title .. reset)
        -- Восстанавливаем позицию заголовка после очистки
        detailsTitle:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)
    end
end

QuestDetails.SetupQuestMeta = function(q)
    local blue = "|cff00B4FF"
    local grey = "|cffAAAAAA"
    local gold = "|cffFFD100"
    local reset = "|r"
    
    if not questMetaFS then
        questMetaFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
        questMetaFS:SetJustifyH("LEFT")
    end
    
    local metaLines = {}
    
    -- Время принятия квеста
    if q.timeAccepted then
        table.insert(metaLines, gold .. "Принят:" .. reset .. " " .. grey .. q.timeAccepted .. reset)
    end
    
    -- Координаты на отдельной строке
    if q.coordinates and q.coordinates.x and q.coordinates.y then
        local coordText = string.format("%.2f, %.2f", q.coordinates.x, q.coordinates.y)
        table.insert(metaLines, gold .. "Координаты:" .. reset .. " " .. grey .. coordText .. reset)
    end
    
    -- NPC, который дал квест
    if q.npcName and q.npcName ~= "Неизвестный NPC" then
        table.insert(metaLines, gold .. "От кого:" .. reset .. " " .. blue .. q.npcName .. reset)
    end
    
    -- Локация
    if q.locationName then
        table.insert(metaLines, gold .. "Локация:" .. reset .. " " .. blue .. q.locationName .. reset)
    end
    
    if #metaLines > 0 then
        questMetaFS:SetSpacing(2)
        questMetaFS:SetText(table.concat(metaLines, "\n"))
    else
        questMetaFS:SetText("")
        questMetaFS:ClearAllPoints()
    end
end

QuestDetails.SetupObjectivesSummary = function(q)
    local white = "|cffffffff"
    local reset = "|r"
    
    if not objectivesSummaryFS then
        objectivesSummaryFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
        objectivesSummaryFS:SetJustifyH("LEFT")
    end
    
    local objectivesText = q.objectivesText or ""
    if objectivesText ~= "" then
        objectivesSummaryFS:SetText(white .. objectivesText .. reset)
    else
        objectivesSummaryFS:SetText("")
        objectivesSummaryFS:ClearAllPoints()
    end
end

QuestDetails.SetupDetailedObjectives = function(q)
    local grey = "|cffAAAAAA"
    local reset = "|r"
    
    local objectives = q.objectives or {}
    if #objectives > 0 then
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
        
        for _, obj in ipairs(objectives) do
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
        
        local finalText = table.concat(objLines, "")
        objectivesTextFS:SetText(finalText)
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
    
    local description = q.description or ""
    if description ~= "" then
        descHeadingFS:SetText(gold .. "Описание:" .. reset)
        
        local descText = white .. description:gsub("\n+$", "") .. reset
        if detailsFS then
            detailsFS:SetText(descText)
        end
    else
        descHeadingFS:SetText("")
        descHeadingFS:ClearAllPoints()
        if detailsFS then
            detailsFS:SetText("")
            detailsFS:ClearAllPoints()
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
    if not q.rewards then 
        -- Очищаем заголовок наград если нет наград
        if rewardsHeadingFS then
            rewardsHeadingFS:SetText("")
            rewardsHeadingFS:ClearAllPoints()
        end
        return 
    end
    
    local items = q.rewards.items or {}
    local choices = q.rewards.choices or {}
    local itemsCount = #items
    local choicesCount = #choices
    
    local hasRewards = (itemsCount > 0) or (choicesCount > 0) or 
                      (q.rewards.money > 0) or 
                      (q.rewards.xp > 0)
    
    if not hasRewards then 
        -- Очищаем заголовок наград если нет наград
        if rewardsHeadingFS then
            rewardsHeadingFS:SetText("")
            rewardsHeadingFS:ClearAllPoints()
        end
        return 
    end
    
    if not rewardsHeadingFS then
        rewardsHeadingFS = ScrollBarUtils.CreateFS(rightContent, "GameFontNormalHuge")
        ScrollBarUtils.RemoveFontOutline(rewardsHeadingFS)
    end
    rewardsHeadingFS:SetText("|cffFFD100Награды:|r")
    
    local rewardItems = {}
    if choicesCount > 0 then
        for _, item in ipairs(choices) do
            table.insert(rewardItems, item)
        end
    end
    if itemsCount > 0 then
        for _, item in ipairs(items) do
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
    if not q.rewards then 
        if rewardExtraFS then
            rewardExtraFS:SetText("")
            rewardExtraFS:ClearAllPoints()
        end
        return 
    end
    
    if not rewardExtraFS then
        rewardExtraFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    end
    
    local extraLines = {}
    
    if q.rewards.money > 0 then
        local coinStr = GetCoinTextureString(q.rewards.money, 20)
        table.insert(extraLines, "Вы также получите: " .. coinStr)
    end
    
    if q.rewards.xp > 0 then
        table.insert(extraLines, "Опыт: " .. ((BreakUpLargeNumbers and BreakUpLargeNumbers(q.rewards.xp)) or q.rewards.xp))
    end
    
    if #extraLines > 0 then
        rewardExtraFS:SetSpacing(4)
        rewardExtraFS:SetText(table.concat(extraLines, "\n"))
    else
        rewardExtraFS:SetText("")
        rewardExtraFS:ClearAllPoints()
    end
end

QuestDetails.SetupObjectiveItems = function(q)
    local objectiveItems = q.objectiveItems or {}
    if #objectiveItems == 0 then return end
    
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    local frameWidth = rightScrollFrame:GetWidth()
    
    for i, item in ipairs(objectiveItems) do
        local row = objectiveItemFrames[i]
        if not row then
            row = QuestDetails.CreateObjectiveItemFrame(i)
            objectiveItemFrames[i] = row
            QuestDetails.SetupObjectiveItemTooltip(row)
        end
        
        QuestDetails.SetupItemFrame(row, item, frameWidth, ICON_SIZE, ITEM_HEIGHT)
        
        -- Устанавливаем количество на иконку (специфично для предметов-целей)
        if item.count and item.count > 0 and row.countText then
            row.countText:SetText(tostring(item.count))
            row.countText:Show()
        elseif row.countText then
            row.countText:Hide()
        end
        
        -- Применяем цвет к тексту (специфично для предметов-целей)
        row.text:SetText("|cffffffff" .. (item.name or "") .. "|r")
    end
    
    QuestDetails.HideUnusedFrames(objectiveItemFrames, #objectiveItems)
    
    objectiveItemsVisibleCount = #objectiveItems
end

QuestDetails.LayoutQuestDetails = function()
    -- Сбрасываем отступ к начальному значению для каждого квеста
    local yOffset = 0
    if detailsTitle then
        yOffset = -detailsTitle:GetStringHeight() - 5
    end
    
    -- Устанавливаем позицию заголовка (если еще не установлена)
    if detailsTitle and not detailsTitle:GetPoint() then
        detailsTitle:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)
    end
    
    -- Добавляем метаданные квеста сразу после заголовка
    if questMetaFS and questMetaFS:GetText() ~= "" then
        questMetaFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - questMetaFS:GetStringHeight() - 8
    end
    
    if objectivesSummaryFS and objectivesSummaryFS:GetText() ~= "" then
        objectivesSummaryFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - objectivesSummaryFS:GetStringHeight() - 6
    end
    
    -- Проверяем objectivesTextFS более строго - только если есть реальный текст
    local objectivesText = objectivesTextFS and objectivesTextFS:GetText()
    if objectivesText and objectivesText ~= "" and objectivesText:match("%S") then
        objectivesTextFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - objectivesTextFS:GetStringHeight() + 5
    end
    
    -- Размещение предметов-целей сразу после текстовых целей
    if objectiveItemsVisibleCount > 0 then
        yOffset = yOffset - 4 -- Дополнительный отступ перед предметами-целями
        
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
    
    local hasTextObjectives = objectivesText and objectivesText ~= "" and objectivesText:match("%S")
    local hasObjectiveItems = objectiveItemsVisibleCount > 0
    
    
    if descHeadingFS and descHeadingFS:GetText() ~= "" then
        descHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - descHeadingFS:GetStringHeight() - 6
    end
    
    if detailsFS and detailsFS:GetText() ~= "" then
        detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - detailsFS:GetStringHeight() - 10
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
        
        if rewardExtraFS and rewardExtraFS:GetText() ~= "" then
            rewardExtraFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
            yOffset = yOffset - rewardExtraFS:GetStringHeight() - 4
        end
    end
    
    local totalHeight = -yOffset + 10
    rightContent:SetHeight(totalHeight)
    rightScrollFrame:SetVerticalScroll(0)
    
    ScrollBarUtils.UpdateScrollBar(rightScrollFrame, rightScrollbar)
end

QuestDetails.ShowQuestDetails = function(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then 
        return 
    end
    
    local q = MQSH_QuestDB[questID]
    
    QuestDetails.ClearQuestDetails()
    QuestDetails.SetupQuestTitle(questID, q)
    QuestDetails.SetupQuestMeta(q)
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

_G.QuestDetails = QuestDetails 