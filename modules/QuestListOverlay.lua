local uiCreated = false

local overlay
local leftScrollFrame, leftContent
local rightScrollFrame, rightContent, detailsFS, detailsTitle
local selectedButton
local objectivesSummaryFS, objectivesTextFS
local rewardsHeadingFS, rewardsTextFS
local descHeadingFS
local rewardItemFrames = {}
local choiceLabelFS, rewardExtraFS
local rewardsVisibleCount = 0

local function SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile     = true,
        tileSize = 8,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(unpack(borderColor))
end

local function CreateFS(parent, template, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    if width then
        fs:SetWidth(width)
        fs:SetWordWrap(true)
    end
    return fs
end

local function RemoveFontOutline(fs)
    local fontFile, fontSize = fs:GetFont()
    if fontFile then
        fs:SetFont(fontFile, fontSize, "")
    end
end

-- ============================================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ОТОБРАЖЕНИЯ ДЕТАЛЕЙ КВЕСТА
-- ============================================================================

local function ClearQuestDetails()
    -- Принудительная очистка всех UI-элементов перед отображением нового квеста
    if objectivesSummaryFS then objectivesSummaryFS:SetText("") end
    if objectivesTextFS then objectivesTextFS:SetText("") end
    if detailsFS then detailsFS:SetText("") end
    if rewardsHeadingFS then rewardsHeadingFS:SetText("") end
    if rewardExtraFS then rewardExtraFS:SetText("") end
    if choiceLabelFS then choiceLabelFS:SetText("") end
    
    -- Скрываем все фреймы наград
    for _, f in ipairs(rewardItemFrames) do f:Hide() end
    rewardsVisibleCount = 0
end

local function SetupQuestTitle(questID, q)
    local gold = "|cffFFD100"
    local reset = "|r"
    local title = q.title or ("ID " .. tostring(questID))
    
    if detailsTitle then
        detailsTitle:SetText(gold .. title .. reset)
    end
end

local function SetupObjectivesSummary(q)
    local white = "|cffffffff"
    local reset = "|r"
    
    if not objectivesSummaryFS then
        objectivesSummaryFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
        objectivesSummaryFS:SetJustifyH("LEFT")
    end
    
    if q.objectivesText and q.objectivesText ~= "" then
        objectivesSummaryFS:SetText(white .. q.objectivesText .. reset)
    else
        objectivesSummaryFS:SetText("")
    end
end

local function SetupDetailedObjectives(q)
    local grey = "|cffAAAAAA"
    local reset = "|r"
    
    if q.objectives and #q.objectives > 0 then
        if not objectivesTextFS then
            objectivesTextFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
            objectivesTextFS:SetJustifyH("LEFT")
        end

        local objLines = {}
        for _, obj in ipairs(q.objectives) do
            table.insert(objLines, grey .. obj .. reset .. "\n")
        end
        objectivesTextFS:SetText(table.concat(objLines, ""))
    elseif objectivesTextFS then
        objectivesTextFS:SetText("")
    end
end

local function SetupDescription(q)
    local white = "|cffffffff"
    local gold = "|cffFFD100"
    local reset = "|r"
    
    -- Заголовок «Описание»
    if not descHeadingFS then
        descHeadingFS = CreateFS(rightContent, "GameFontNormalHuge")
        RemoveFontOutline(descHeadingFS)
        descHeadingFS:SetJustifyH("LEFT")
    end
    
    if q.description and q.description ~= "" then
        descHeadingFS:SetText(gold .. "Описание:" .. reset)
        
        -- Текст описания
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

local function CreateRewardItemFrame(index)
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    
    local row = CreateFrame("Frame", nil, rightContent)
    SetBackdrop(row, {0,0,0,0.2}, {1,1,1,1})
    row:EnableMouse(true)

    row.iconBorder = CreateFrame("Frame", nil, row)
    SetBackdrop(row.iconBorder, {0,0,0,1}, {1,1,1,1})
    row.iconBorder:SetSize(ICON_SIZE+4, ICON_SIZE+4)

    row.icon = row.iconBorder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("CENTER")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetTexCoord(5/64,59/64,5/64,59/64)

    row.text = CreateFS(row, "GameFontHighlight")
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("MIDDLE")
    
    return row
end

local function SetupRewardItemTooltip(row)
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

local function SetupRewardItems(q)
    if not q.rewards then return end
    
    local hasRewards = (#q.rewards.items > 0) or (#q.rewards.choices > 0) or 
                      (q.rewards.money and q.rewards.money > 0) or 
                      (q.rewards.xp and q.rewards.xp > 0)
    
    if not hasRewards then return end
    
    -- Создаём заголовок «Награды»
    if not rewardsHeadingFS then
        rewardsHeadingFS = CreateFS(rightContent, "GameFontNormalHuge")
        RemoveFontOutline(rewardsHeadingFS)
    end
    rewardsHeadingFS:SetText("|cffFFD100Награды:|r")
    
    -- Собираем все предметы наград
    local rewardItems = {}
    if #q.rewards.choices > 0 then
        for _, item in ipairs(q.rewards.choices) do
            table.insert(rewardItems, item)
        end
    end
    for _, item in ipairs(q.rewards.items) do
        table.insert(rewardItems, item)
    end
    
    -- Создаём/обновляем фреймы для предметов
    local ICON_SIZE = 40
    local ITEM_HEIGHT = ICON_SIZE + 4
    local frameWidth = rightScrollFrame:GetWidth()
    
    for i, item in ipairs(rewardItems) do
        local row = rewardItemFrames[i]
        if not row then
            row = CreateRewardItemFrame(i)
            rewardItemFrames[i] = row
            SetupRewardItemTooltip(row)
        end
        
        -- Настраиваем размеры и позиции
        row:SetWidth(frameWidth)
        row:SetHeight(ITEM_HEIGHT)
        
        -- Устанавливаем содержимое
        local texture = item.texture or "Interface\\Icons\\INV_Misc_QuestionMark"
        row.icon:SetTexture(texture)
        
        local nameTxt = item.name or ""
        row.text:SetWidth(frameWidth - (ICON_SIZE+10))
        row.text:SetText(nameTxt)
        if not row.text.SetMaxLines then
            row.text:SetHeight(ITEM_HEIGHT - 5)
        end
        
        row.iconBorder:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.text:SetPoint("LEFT", row.iconBorder, "RIGHT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        
        row.itemID = item.itemID
        row.itemName = item.name
        row:Show()
    end
    
    -- Скрываем неиспользуемые фреймы
    for i = #rewardItems + 1, #rewardItemFrames do
        rewardItemFrames[i]:Hide()
    end
    
    rewardsVisibleCount = #rewardItems
end

local function SetupExtraRewards(q)
    if not q.rewards then return end
    
    if not rewardExtraFS then
        rewardExtraFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
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

local function LayoutQuestDetails()
    -- Начинаем с заголовка квеста
    local yOffset = -detailsTitle:GetStringHeight() - 5
    
    -- Summary целей
    if objectivesSummaryFS then
        objectivesSummaryFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if objectivesSummaryFS:GetText() ~= "" then
            yOffset = yOffset - objectivesSummaryFS:GetStringHeight() - 6
        end
    end
    
    -- Подробные цели
    if objectivesTextFS then
        objectivesTextFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if objectivesTextFS:GetText() ~= "" then
            yOffset = yOffset - objectivesTextFS:GetStringHeight()
        end
    end
    
    -- Заголовок и текст описания
    if descHeadingFS then
        descHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if descHeadingFS:GetText() ~= "" then
            yOffset = yOffset - descHeadingFS:GetStringHeight() - 10
        end
    end
    
    if detailsFS then
        detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if detailsFS:GetText() ~= "" then
            yOffset = yOffset - detailsFS:GetStringHeight() - 10
        end
    end
    
    -- Награды
    if rewardsHeadingFS and rewardsHeadingFS:GetText() ~= "" then
        rewardsHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - rewardsHeadingFS:GetStringHeight() - 2
        
        -- Раскладка предметов в две колонки
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
        
        -- Смещаем yOffset на количество строк
        local rows = math.ceil(rewardsVisibleCount / 2)
        if rows > 0 then
            yOffset = yOffset - rows * (rewardItemFrames[1]:GetHeight() + rowSpacing)
        end
        
        -- Дополнительные награды
        if rewardExtraFS then
            rewardExtraFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
            if rewardExtraFS:GetText() ~= "" then
                yOffset = yOffset - rewardExtraFS:GetStringHeight() - 4
            end
        end
    end
    
    -- Устанавливаем общую высоту контента
    local totalHeight = -yOffset + 10
    rightContent:SetHeight(totalHeight)
    rightScrollFrame:SetVerticalScroll(0)
end

-- ============================================================================
-- ОСНОВНАЯ ФУНКЦИЯ ОТОБРАЖЕНИЯ ДЕТАЛЕЙ КВЕСТА
-- ============================================================================

local function ShowQuestDetails(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then return end
    
    local q = MQSH_QuestDB[questID]
    
    -- 1. Очищаем все элементы интерфейса
    ClearQuestDetails()
    
    -- 2. Настраиваем заголовок квеста
    SetupQuestTitle(questID, q)
    
    -- 3. Настраиваем цели квеста
    SetupObjectivesSummary(q)
    SetupDetailedObjectives(q)
    
    -- 4. Настраиваем описание
    SetupDescription(q)
    
    -- 5. Настраиваем награды
    SetupRewardItems(q)
    SetupExtraRewards(q)
    
    -- 6. Раскладываем все элементы на экране
    LayoutQuestDetails()
end

local function HighlightQuestButton(btn)
    if selectedButton and selectedButton.selTexture then
        selectedButton.selTexture:Hide()
    end
    selectedButton = btn
    if selectedButton and selectedButton.selTexture then
        selectedButton.selTexture:Show()
    end
end

local function BuildQuestList()
    if not leftContent then return end

    if leftContent.buttons then
        for _, btn in ipairs(leftContent.buttons) do
            btn:Hide()
        end
    else
        leftContent.buttons = {}
    end

    local questIDs = {}
    if MQSH_QuestDB then
        for qID in pairs(MQSH_QuestDB) do
            table.insert(questIDs, qID)
        end
    end
    table.sort(questIDs, function(a, b)
        local qa, qb = MQSH_QuestDB[a], MQSH_QuestDB[b]
        if qa and qb then
            return (qa.addedAt or 0) > (qb.addedAt or 0)
        end
        return a < b
    end)

    local btnHeight = 17
    local width = leftScrollFrame:GetWidth() - 5
    local reset = "|r"

    for index, qID in ipairs(questIDs) do
        local data = MQSH_QuestDB[qID]
        local btn = leftContent.buttons[index]
        if not btn then
            btn = CreateFrame("Button", nil, leftContent)
            leftContent.buttons[index] = btn

            -- Создание текста для кнопки
            btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            btn.text:SetJustifyH("LEFT")
            btn.text:SetTextColor(1, 1, 1) -- стандартный цвет

            -- Сдвиг текста вправо и вниз
            local xOffset = 7  -- Отступ вправо (в пикселях)
            local yOffset = 0  -- Отступ вниз (в пикселях)
            btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", xOffset, yOffset)
            btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -xOffset, yOffset)

            -- Сохранение исходных координат текста
            btn.text.xOffset = xOffset
            btn.text.yOffset = yOffset

            -- Выделение фона при выборе
            btn.selTexture = btn:CreateTexture(nil, "BACKGROUND")
            btn.selTexture:SetAllPoints(btn)
            btn.selTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            btn.selTexture:SetBlendMode("ADD")
            btn.selTexture:Hide()
        end

        btn.questID = qID
        btn:SetHeight(btnHeight)

        -- Увеличиваем расстояние между кнопками на 1 пиксель
        local spacing = 1  -- Дополнительное расстояние между кнопками
        btn:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, -(index - 1) * (btnHeight + spacing))
        btn:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -(index - 1) * (btnHeight + spacing))

        -- Установка текста кнопки с уровнем квеста
        local title = data.title or ("ID " .. tostring(qID))
        local level = data.level or "??" -- Если уровень неизвестен, показываем "??"
        local color
        if type(level) == "number" then
            color = GetQuestDifficultyColor(level)
        else
            color = { r = 1, g = 0, b = 0 }
        end
        btn.text:SetTextColor(color.r, color.g, color.b)
        btn.text:SetText(string.format("[%s] %s%s", level, title, reset))

        -- Обработчик клика
        btn:SetScript("OnMouseDown", function(self)
            -- При нажатии сдвигаем текст на 1 пиксель вниз и вправо
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset + 2, self.text.yOffset - 2)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset + 2, self.text.yOffset - 2)
        end)

        btn:SetScript("OnMouseUp", function(self)
            -- При отпускании возвращаем текст в исходное положение
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset, self.text.yOffset)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset, self.text.yOffset)
        end)

        btn:SetScript("OnClick", function(self)
            HighlightQuestButton(self)
            ShowQuestDetails(self.questID)
        end)

        -- Изменение цвета текста при наведении мыши
        btn:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self.text:SetTextColor(color.r, color.g, color.b)
        end)

        btn:Show()
    end

    -- Скрываем лишние кнопки
    for i = #questIDs + 1, #leftContent.buttons do
        leftContent.buttons[i]:Hide()
    end

    -- Обновляем высоту контейнера
    leftContent:SetHeight(#questIDs * btnHeight)
    leftScrollFrame:SetVerticalScroll(0)

    -- Автовыбор первого квеста, если ничего не выбрано
    if #questIDs > 0 and (not selectedButton or not selectedButton:IsShown()) then
        local firstBtn = leftContent.buttons[1]
        if firstBtn then
            HighlightQuestButton(firstBtn)
            ShowQuestDetails(firstBtn.questID)
        end
    end
end

local function TryCreateQuestListUI()
    if uiCreated or not QuestLogFrame then return end

    local showBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    showBtn:SetSize(80, 22)
    showBtn:SetText("История")
    showBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -150, -30)

    overlay = CreateFrame("Frame", "MQSH_ListOverlay", QuestLogFrame)
    overlay:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 11, -12)
    overlay:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -1, 11)
    SetBackdrop(overlay, {0.05, 0.05, 0.05, 0.85}, {0, 0, 0, 0.95})
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)

    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -2, -2)

    local leftWindow = CreateFrame("Frame", nil, overlay)
    leftWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -30)
    leftWindow:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 10, 10)
    leftWindow:SetWidth((QuestLogFrame:GetWidth() - 30) / 2)
    SetBackdrop(leftWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    local leftTitle = CreateFS(leftWindow, "GameFontNormal")
    leftTitle:SetPoint("TOP", leftWindow, "TOP", 0, -5)
    leftTitle:SetJustifyH("CENTER")
    leftTitle:SetText("|cffFFD100Квесты|r")

    leftScrollFrame = CreateFrame("ScrollFrame", nil, leftWindow, "UIPanelScrollFrameTemplate")
    leftScrollFrame:SetPoint("TOPLEFT", leftWindow, "TOPLEFT", 10, -20)
    leftScrollFrame:SetPoint("BOTTOMRIGHT", leftWindow, "BOTTOMRIGHT", -30, 10)

    leftContent = CreateFrame("Frame", nil, leftScrollFrame)
    leftContent:SetSize(leftScrollFrame:GetWidth(), 1)
    leftScrollFrame:SetScrollChild(leftContent)

    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -10, -30)
    rightWindow:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -10, 10)
    rightWindow:SetWidth((QuestLogFrame:GetWidth() - 30) / 2)
    SetBackdrop(rightWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    rightScrollFrame = CreateFrame("ScrollFrame", nil, rightWindow, "UIPanelScrollFrameTemplate")
    rightScrollFrame:SetPoint("TOPLEFT", rightWindow, "TOPLEFT", 10, -10)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", rightWindow, "BOTTOMRIGHT", -30, 10)

    rightContent = CreateFrame("Frame", nil, rightScrollFrame)
    rightContent:SetSize(rightScrollFrame:GetWidth(), 1)
    rightScrollFrame:SetScrollChild(rightContent)

    detailsTitle = CreateFS(rightContent, "GameFontNormalHuge")
    RemoveFontOutline(detailsTitle)
    detailsTitle:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)
    detailsTitle:SetJustifyH("LEFT")

    detailsFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, -25)

    showBtn:SetScript("OnClick", function()
        if overlay:IsShown() then
            overlay:Hide()
        else
            overlay:Show()
        end
    end)

    hooksecurefunc(QuestLogFrame, "Hide", function()
        overlay:Hide()
    end)

    overlay:SetScript("OnShow", BuildQuestList)

    uiCreated = true
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        TryCreateQuestListUI()
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_QuestLog" then
        TryCreateQuestListUI()
    end
end)

_G.QuestListOverlay_TryInit = TryCreateQuestListUI