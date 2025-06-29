local QuestList = {}

-- Вспомогательные переменные (будут передаваться через параметры или инициализироваться снаружи)
local leftContent, leftScrollFrame, leftScrollbar
local selectedButton
local BUTTON_HEIGHT, BUTTON_TEXT_PADDING, BUTTON_SPACING
local scrollPairs

-- Переменные для сортировки
local sortType = "level" -- "level", "title", "id"
local sortOrder = "asc" -- "asc" для возрастания, "desc" для убывания

-- Переменные для группировки
local SECTION_HEADER_PADDING = 1
local collapsedSections = {} -- Хранит состояние свернутых разделов

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

-- Функция для установки параметров сортировки
function QuestList.SetSortParams(type, order)
    sortType = type or "level"
    sortOrder = order or "asc"
end

-- Функция для создания заголовка раздела
QuestList.CreateSectionHeader = function(sectionName, isCollapsed)
    local header = CreateFrame("Button", nil, leftContent)
    header:SetHeight(BUTTON_HEIGHT)
    
    -- Кнопка сворачивания/разворачивания (слева)
    header.toggleBtn = CreateFrame("Button", nil, header)
    header.toggleBtn:SetSize(16, 16)
    header.toggleBtn:SetPoint("LEFT", header, "LEFT", SECTION_HEADER_PADDING, 0)
    
    header.toggleBtn.text = header.toggleBtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header.toggleBtn.text:SetJustifyH("CENTER")
    header.toggleBtn.text:SetTextColor(0.8, 0.8, 0.8)
    header.toggleBtn.text:SetPoint("CENTER", header.toggleBtn, "CENTER", -8, 0)
    
    -- Текст заголовка (размер как у квестов)
    header.text = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header.text:SetJustifyH("LEFT")
    header.text:SetTextColor(0.8, 0.8, 0.8) -- светлосерый
    header.text:SetPoint("LEFT", header.toggleBtn, "RIGHT", -12, 0)
    header.text:SetPoint("RIGHT", header, "RIGHT", -SECTION_HEADER_PADDING, 0)
    
    -- Обработчики событий для заголовка
    header:SetScript("OnClick", function(self)
        QuestList.ToggleSection(sectionName)
    end)
    
    header:SetScript("OnMouseDown", function(self)
        self.text:SetPoint("LEFT", self.toggleBtn, "RIGHT", -10, -2)
    end)
    
    header:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("LEFT", self.toggleBtn, "RIGHT", -12, 0)
    end)
    
    header:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1) -- подстветка при наведении
    end)
    
    header:SetScript("OnLeave", function(self)
        self.text:SetTextColor(0.8, 0.8, 0.8) -- возврат к светлосерому
    end)
    
    -- Обработчики событий для кнопки сворачивания
    header.toggleBtn:SetScript("OnClick", function(self, button)
        QuestList.ToggleSection(sectionName)
    end)
    
    return header
end

-- Функция для настройки заголовка раздела
QuestList.SetupSectionHeader = function(header, sectionName, isCollapsed, yOffset)
    header.sectionName = sectionName
    header:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, yOffset)
    header:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, yOffset)
    
    local displayName = sectionName
    if sectionName == "story" then
        displayName = "Сюжетные"
    end
    
    header.text:SetText(displayName)
    
    if isCollapsed then
        header.toggleBtn.text:SetText("+")
    else
        header.toggleBtn.text:SetText("-")
    end
    
    header:Show()
end

-- Функция для переключения состояния раздела
QuestList.ToggleSection = function(sectionName)
    collapsedSections[sectionName] = not collapsedSections[sectionName]
    QuestList.BuildQuestList()
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
QuestList.SetupQuestButton = function(btn, index, qID, data, yOffset)
    btn.questID = qID
    btn:SetHeight(BUTTON_HEIGHT)

    btn:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, yOffset)
    btn:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, yOffset)

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

    -- Очищаем все существующие элементы
    if leftContent.elements then
        for _, element in ipairs(leftContent.elements) do
            element:Hide()
        end
    else
        leftContent.elements = {}
    end

    local questDB = MQSH_QuestDB or {}
    
    -- Группируем квесты по разделам
    local sections = {}
    local storyQuests = {}
    local locationQuests = {}
    
    for qID, data in pairs(questDB) do
        if data.isStoryQuest then
            table.insert(storyQuests, {id = qID, data = data})
        else
            -- Используем основную зону
            local locationName = data.mainZone or "Неизвестная локация"
            if not locationQuests[locationName] then
                locationQuests[locationName] = {}
            end
            table.insert(locationQuests[locationName], {id = qID, data = data})
        end
    end
    
    -- Добавляем сюжетные квесты в секции
    if #storyQuests > 0 then
        sections["story"] = storyQuests
    end
    
    -- Добавляем квесты по локациям в секции
    for locationName, quests in pairs(locationQuests) do
        if #quests > 0 then
            sections[locationName] = quests
        end
    end
    
    -- Сортируем секции (сюжетные всегда первыми)
    local sortedSections = {}
    if sections["story"] then
        table.insert(sortedSections, "story")
    end
    
    local otherSections = {}
    for sectionName, _ in pairs(sections) do
        if sectionName ~= "story" then
            table.insert(otherSections, sectionName)
        end
    end
    table.sort(otherSections)
    
    for _, sectionName in ipairs(otherSections) do
        table.insert(sortedSections, sectionName)
    end
    
    -- Сортируем квесты внутри каждой секции
    for sectionName, quests in pairs(sections) do
        table.sort(quests, function(a, b)
            local dataA = a.data
            local dataB = b.data
            
            local valueA, valueB
            
            if sortType == "level" then
                valueA = dataA.level or 0
                valueB = dataB.level or 0
            elseif sortType == "title" then
                valueA = dataA.title or ("ID " .. tostring(a.id))
                valueB = dataB.title or ("ID " .. tostring(b.id))
            elseif sortType == "id" then
                valueA = a.id
                valueB = b.id
            else
                valueA = dataA.level or 0
                valueB = dataB.level or 0
            end
            
            if sortOrder == "asc" then
                if sortType == "title" then
                    return valueA < valueB
                else
                    return valueA < valueB
                end
            else
                if sortType == "title" then
                    return valueA > valueB
                else
                    return valueA > valueB
                end
            end
        end)
    end
    
    -- Строим интерфейс
    local currentYOffset = 0
    local elementIndex = 1
    
    for _, sectionName in ipairs(sortedSections) do
        local quests = sections[sectionName]
        local isCollapsed = collapsedSections[sectionName]
        
        -- Создаем заголовок секции
        local header = leftContent.elements[elementIndex]
        if not header or not header.isHeader then
            header = QuestList.CreateSectionHeader(sectionName, isCollapsed)
            header.isHeader = true
            leftContent.elements[elementIndex] = header
        end
        
        QuestList.SetupSectionHeader(header, sectionName, isCollapsed, currentYOffset)
        currentYOffset = currentYOffset - BUTTON_HEIGHT + 2
        elementIndex = elementIndex + 1
        
        -- Если секция не свернута, показываем квесты
        if not isCollapsed then
            for i, questInfo in ipairs(quests) do
                local btn = leftContent.elements[elementIndex]
                if not btn or btn.isHeader then
                    btn = QuestList.CreateQuestButton(elementIndex, questInfo.id, questInfo.data)
                    leftContent.elements[elementIndex] = btn
                end
                
                QuestList.SetupQuestButton(btn, i, questInfo.id, questInfo.data, currentYOffset)
                currentYOffset = currentYOffset - BUTTON_HEIGHT - BUTTON_SPACING
                elementIndex = elementIndex + 1
            end
        end
        
        -- Добавляем отступ между разделами (минимальный)
        if _ < #sortedSections then
            currentYOffset = currentYOffset + 1
        end
    end
    
    -- Скрываем неиспользуемые элементы
    for i = elementIndex, #leftContent.elements do
        leftContent.elements[i]:Hide()
    end
    
    -- Устанавливаем общую высоту контента
    local totalHeight = -currentYOffset
    leftContent:SetHeight(totalHeight)
    leftScrollFrame:SetVerticalScroll(0)
    
    ScrollBarUtils.UpdateAllScrollBars(scrollPairs)

    -- Выбираем первый квест, если ничего не выбрано
    if #sortedSections > 0 and (not selectedButton or not selectedButton:IsShown()) then
        local firstSection = sortedSections[1]
        local firstQuests = sections[firstSection]
        if #firstQuests > 0 and not collapsedSections[firstSection] then
            local firstBtn = leftContent.elements[2] -- Первый элемент после заголовка
            if firstBtn and not firstBtn.isHeader then
                QuestDetails.HighlightQuestButton(firstBtn)
                QuestDetails.ShowQuestDetails(firstBtn.questID)
            end
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
    local leftScrollbar = ScrollBarUtils.CreateScrollBar(overlay, leftScrollFrame, leftWindow, WINDOW_SPACING, ScrollBarUtils.SCROLLBAR_WIDTH, (BUTTON_HEIGHT + BUTTON_SPACING) * 2)
    
    return leftWindow, leftScrollFrame, leftContent, leftScrollbar, leftTitle
end

-- Экспортируем модуль в глобальную область
_G.QuestList = QuestList 