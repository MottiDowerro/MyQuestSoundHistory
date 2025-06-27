local QuestList = {}

-- Вспомогательные переменные (будут передаваться через параметры или инициализироваться снаружи)
local leftContent, leftScrollFrame, leftScrollbar
local selectedButton
local BUTTON_HEIGHT, BUTTON_TEXT_PADDING, BUTTON_SPACING
local scrollPairs

-- Функции для инициализации переменных
function QuestList.InitVars(vars)
    leftContent = vars.leftContent
    leftScrollFrame = vars.leftScrollFrame
    leftScrollbar = vars.leftScrollbar
    selectedButton = vars.selectedButton
    BUTTON_HEIGHT = vars.BUTTON_HEIGHT
    BUTTON_TEXT_PADDING = vars.BUTTON_TEXT_PADDING
    BUTTON_SPACING = vars.BUTTON_SPACING
    scrollPairs = vars.scrollPairs
end

-- Функция для создания кнопки квеста
QuestList.CreateQuestButton = function(index, qID, data)
    local btn = CreateFrame("Button", nil, leftContent)
    
    btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    btn.text:SetJustifyH("LEFT")
    btn.text:SetTextColor(1, 1, 1)

    btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", BUTTON_TEXT_PADDING, 0)
    btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -BUTTON_TEXT_PADDING, 0)

    btn.text.xOffset = BUTTON_TEXT_PADDING
    btn.text.yOffset = 0

    btn.selTexture = btn:CreateTexture(nil, "BACKGROUND")
    btn.selTexture:SetAllPoints(btn)
    btn.selTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    btn.selTexture:SetBlendMode("ADD")
    btn.selTexture:Hide()
    
    return btn
end

-- Функция для настройки кнопки квеста
QuestList.SetupQuestButton = function(btn, index, qID, data)
    btn.questID = qID
    btn:SetHeight(BUTTON_HEIGHT)

    btn:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, -(index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))
    btn:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -(index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))

    local title = data.title or ("ID " .. tostring(qID))
    local level = data.level or "??"
    local color
    if type(level) == "number" and level > 0 then
        color = GetQuestDifficultyColor(level)
    else
        color = { r = 1, g = 0, b = 0 }
    end
    btn.text:SetTextColor(color.r, color.g, color.b)
    btn.text:SetText(string.format("[%s] %s|r", level, title))

    btn:SetScript("OnMouseDown", function(self)
        self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset + 2, self.text.yOffset - 2)
        self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset + 2, self.text.yOffset - 2)
    end)

    btn:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset, self.text.yOffset)
        self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset, self.text.yOffset)
    end)

    btn:SetScript("OnClick", function(self)
        QuestDetails.HighlightQuestButton(self)
        QuestDetails.ShowQuestDetails(self.questID)
    end)

    btn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
    end)

    btn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(color.r, color.g, color.b)
    end)

    btn:Show()
end

-- Основная функция для построения списка квестов
QuestList.BuildQuestList = function()
    if not leftContent then return end

    if leftContent.buttons then
        for _, btn in ipairs(leftContent.buttons) do
            btn:Hide()
        end
    else
        leftContent.buttons = {}
    end

    local questIDs = {}
    local questDB = MQSH_QuestDB or {}
    for qID in pairs(questDB) do
        table.insert(questIDs, qID)
    end

    for index, qID in ipairs(questIDs) do
        local data = questDB[qID]
        local btn = leftContent.buttons[index]
        if not btn then
            btn = QuestList.CreateQuestButton(index, qID, data)
            leftContent.buttons[index] = btn
        end
        
        QuestList.SetupQuestButton(btn, index, qID, data)
    end

    for i = #questIDs + 1, #leftContent.buttons do
        leftContent.buttons[i]:Hide()
    end

    local totalHeight = #questIDs * BUTTON_HEIGHT
    if #questIDs > 1 then
        totalHeight = totalHeight + (#questIDs - 1) * BUTTON_SPACING
    end
    leftContent:SetHeight(totalHeight)
    leftScrollFrame:SetVerticalScroll(0)
    
    ScrollBarUtils.UpdateAllScrollBars(scrollPairs)

    if #questIDs > 0 and (not selectedButton or not selectedButton:IsShown()) then
        local firstBtn = leftContent.buttons[1]
        if firstBtn then
            QuestDetails.HighlightQuestButton(firstBtn)
            QuestDetails.ShowQuestDetails(firstBtn.questID)
        end
    end
end

-- Функция для создания левого окна
QuestList.CreateLeftWindow = function(overlay, windowWidth, windowHeight, leftWindowX, elementY, LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y, WINDOW_SPACING, BUTTON_HEIGHT, BUTTON_SPACING)
    local leftWindow = CreateFrame("Frame", nil, overlay)
    leftWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", leftWindowX, elementY)
    leftWindow:SetSize(windowWidth, windowHeight)
    ScrollBarUtils.SetBackdrop(leftWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    local leftTitle = ScrollBarUtils.CreateFS(overlay, "GameFontNormal")
    leftTitle:SetPoint("BOTTOM", leftWindow, "TOP", 0, 5)
    leftTitle:SetJustifyH("CENTER")
    leftTitle:SetText("|cffFFD100Квесты|r")

    -- Создаем левый ScrollFrame и скроллбар
    local leftScrollFrame, leftContent = ScrollBarUtils.CreateScrollFrame(leftWindow, LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y)
    local leftScrollbar = ScrollBarUtils.CreateScrollBar(overlay, leftScrollFrame, leftWindow, WINDOW_SPACING, ScrollBarUtils.SCROLLBAR_WIDTH, BUTTON_HEIGHT + BUTTON_SPACING)
    
    return leftWindow, leftScrollFrame, leftContent, leftScrollbar, leftTitle
end

-- Экспортируем модуль в глобальную область
_G.QuestList = QuestList 