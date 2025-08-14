local QuestDetails = {}

-- Вспомогательные переменные (будут передаваться через параметры или инициализироваться снаружи)
local rewardItemFrames, rewardsVisibleCount
local objectivesSummaryFS, objectivesTextFS, detailsFS, rewardsHeadingFS, rewardExtraFS, choiceLabelFS, descHeadingFS, detailsTitle
local questMetaFS -- Новый элемент для метаданных квеста
local rightContent, rightScrollFrame, rightScrollbar
local selectedButton

function QuestDetails.InitVars(vars)
    rewardItemFrames = vars.rewardItemFrames
    rewardsVisibleCount = vars.rewardsVisibleCount
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
        questMetaFS = Utils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
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
    if q.npcName then
        local npcColor = blue
        if q.npcName == "Неизвестный NPC" then
            npcColor = grey
        end
        table.insert(metaLines, gold .. "От кого:" .. reset .. " " .. npcColor .. q.npcName .. reset)
    end
    
    -- Локация
    if q.mainZone then
        table.insert(metaLines, gold .. "Локация:" .. reset .. " " .. blue .. q.mainZone .. reset)
    end
    
    -- Добавляем информацию о завершении квеста (только если есть данные)
    if q.timeCompleted then
        table.insert(metaLines, gold .. "Завершен:" .. reset .. " " .. grey .. q.timeCompleted .. reset)
    end
    
    if q.completionNPC then
        local npcColor = blue
        if q.completionNPC == "Неизвестный NPC" then
            npcColor = grey
        end
        table.insert(metaLines, gold .. "Завершен у:" .. reset .. " " .. npcColor .. q.completionNPC .. reset)
    end
    
    if q.completionLocation then
        table.insert(metaLines, gold .. "Локация завершения:" .. reset .. " " .. blue .. q.completionLocation .. reset)
    end
    
    if q.completionCoordinates and q.completionCoordinates.x and q.completionCoordinates.y then
        local completionCoordText = string.format("%.2f, %.2f", q.completionCoordinates.x, q.completionCoordinates.y)
        table.insert(metaLines, gold .. "Координаты завершения:" .. reset .. " " .. grey .. completionCoordText .. reset)
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
        objectivesSummaryFS = Utils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
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
            objectivesTextFS = Utils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
            objectivesTextFS:SetJustifyH("LEFT")
        end

        local objLines = {}
        for i, obj in ipairs(objectives) do
            local desc, type = select(1, GetQuestLogLeaderBoard(i))
            if type ~= "item" then
                table.insert(objLines, grey .. obj .. reset .. "\n")
            end
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
        descHeadingFS = Utils.CreateFS(rightContent, "GameFontNormalHuge")
        Utils.RemoveFontOutline(descHeadingFS)
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
    if item.name then
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item.name)
        if itemTexture then
            texture = itemTexture
        end
    end
    return texture
end

-- Настройка отображения предмета
QuestDetails.SetupItemFrame = function(row, item, frameWidth, ICON_SIZE, ITEM_HEIGHT)
    row:SetWidth(frameWidth)
    row:SetHeight(ITEM_HEIGHT)
    
    -- Установка текстуры
    local texture = QuestDetails.GetItemTexture(item)
    row.icon:SetTexture(texture)
    
    -- Настройка текста названия
    local nameTxt = item.name or ""
    row.text:SetWidth(frameWidth - (ICON_SIZE + 10))
    row.text:SetText(nameTxt)
    
    -- Отображение количества
    if item.numItems and item.numItems > 1 then
        row.countText:SetText(item.numItems) -- Без символа "x"
        row.countText:Show()
    else
        row.countText:Hide()
    end
    
    -- Позиционирование элементов
    row.iconBorder:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text:SetPoint("LEFT", row.iconBorder, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    
    -- Сохранение данных
    row.itemID = item.itemID
    row.itemName = item.name
    row:Show()
end

QuestDetails.HideUnusedFrames = function(frames, usedCount)
    for i = usedCount + 1, #frames do
        frames[i]:Hide()
    end
end

QuestDetails.CreateItemFrame = function(index)
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    local row = CreateFrame("Frame", nil, rightContent)
    
    -- Настройка фона фрейма
    Utils.SetBackdrop(row, {0,0,0,0.2}, {1,1,1,1})
    row:EnableMouse(true)
    
    -- Контейнер для иконки
    row.iconBorder = CreateFrame("Frame", nil, row)
    Utils.SetBackdrop(row.iconBorder, {0,0,0,1}, {1,1,1,1})
    row.iconBorder:SetSize(ICON_SIZE+4, ICON_SIZE+4)
    
    -- Иконка предмета
    row.icon = row.iconBorder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("CENTER")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetTexCoord(5/64,59/64,5/64,59/64)
    
    -- Основной текст предмета
    row.text = Utils.CreateFS(row, "GameFontHighlight")
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("MIDDLE")
    
    -- Текст количества с автоматическим определением шрифта
    row.countText = row.iconBorder:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.countText:SetFontObject(GameFontNormal) -- Используем системный шрифт
    row.countText:SetJustifyH("RIGHT")
    row.countText:SetJustifyV("BOTTOM")
    row.countText:SetPoint("BOTTOMRIGHT", row.iconBorder, "BOTTOMRIGHT", -2, 2)
    row.countText:SetTextColor(1, 1, 1) -- Белый цвет
    
    -- Добавляем обводку через флаги шрифта
    local font, size, flags = row.countText:GetFont()
    row.countText:SetFont(font, size, "OUTLINE") -- Сохраняем оригинальные параметры + обводка
    
    return row
end

-- Обратная совместимость - оставляем старые функции как алиасы
QuestDetails.CreateRewardItemFrame = function(index)
    return QuestDetails.CreateItemFrame(index)
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
        rewardsHeadingFS = Utils.CreateFS(rightContent, "GameFontNormalHuge")
        Utils.RemoveFontOutline(rewardsHeadingFS)
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
        rewardExtraFS = Utils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
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
    
    Utils.UpdateScrollBar(rightScrollFrame, rightScrollbar)
end

QuestDetails.ShowQuestDetails = function(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then 
        return 
    end
    
    local q = MQSH_QuestDB[questID]
    
    -- Проверяем состояние галочки "текущий персонаж"
    local currentPlayerEnabled = true -- По умолчанию включено
    if _G.MQSH_QuestOverlay and _G.MQSH_QuestOverlay.currentPlayerCheck then
        currentPlayerEnabled = _G.MQSH_QuestOverlay.currentPlayerCheck:GetChecked()
    end
    
    -- Добавляем данные из истории персонажа только если галочка включена
    if currentPlayerEnabled then
        local charHistoryDB = MQSH_Char_HistoryDB or {}
        if charHistoryDB[questID] then
            -- Создаем копию данных квеста
            local combinedData = {}
            for k, v in pairs(q) do
                combinedData[k] = v
            end
            -- Добавляем данные из истории персонажа
            if charHistoryDB[questID].timeCompleted then
                combinedData.timeCompleted = charHistoryDB[questID].timeCompleted
            end
            if charHistoryDB[questID].completionNPC then
                combinedData.completionNPC = charHistoryDB[questID].completionNPC
            end
            if charHistoryDB[questID].completionLocation then
                combinedData.completionLocation = charHistoryDB[questID].completionLocation
            end
            if charHistoryDB[questID].completionCoordinates then
                combinedData.completionCoordinates = charHistoryDB[questID].completionCoordinates
            end
            q = combinedData
        end
    end
    
    QuestDetails.ClearQuestDetails()
    QuestDetails.SetupQuestTitle(questID, q)
    QuestDetails.SetupQuestMeta(q)
    QuestDetails.SetupObjectivesSummary(q)
    QuestDetails.SetupDetailedObjectives(q)
    QuestDetails.SetupDescription(q)
    QuestDetails.SetupRewardItems(q)
    QuestDetails.SetupExtraRewards(q)
    QuestDetails.LayoutQuestDetails()
end

QuestDetails.HighlightQuestButton = function(btn)
    -- Убираем выделение с предыдущей кнопки
    if selectedButton then
        if selectedButton.selTexture then
            selectedButton.selTexture:Hide()
        end
        -- Возвращаем нормальные цвета текста
        if selectedButton.normalTextColor then
            selectedButton.text:SetTextColor(selectedButton.normalTextColor.r, selectedButton.normalTextColor.g, selectedButton.normalTextColor.b)
        end
        if selectedButton.normalTypeColor then
            selectedButton.typeText:SetTextColor(selectedButton.normalTypeColor.r, selectedButton.normalTypeColor.g, selectedButton.normalTypeColor.b)
        end
    end
    
    selectedButton = btn
    _G.selectedButton = selectedButton -- Обновляем глобальную переменную
    
    -- Применяем выделение к новой кнопке
    if selectedButton then
        if selectedButton.selTexture then
            selectedButton.selTexture:Show()
            -- Устанавливаем фон цвета сложности (цвет который был у текста изначально)
            if selectedButton.difficultyColor then
                selectedButton.selTexture:SetVertexColor(selectedButton.difficultyColor.r, selectedButton.difficultyColor.g, selectedButton.difficultyColor.b, 0.3)
            end
        end
        -- Делаем основной текст белым, метка типа остается своего цвета
        selectedButton.text:SetTextColor(1, 1, 1)
        if selectedButton.typeText and selectedButton.normalTypeColor then
            selectedButton.typeText:SetTextColor(selectedButton.normalTypeColor.r, selectedButton.normalTypeColor.g, selectedButton.normalTypeColor.b)
        end
    end
end

-- Экспортируем переменную selectedButton в глобальную область
_G.selectedButton = selectedButton
_G.QuestDetails = QuestDetails 