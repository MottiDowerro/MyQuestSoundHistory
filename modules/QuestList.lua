local QuestList = {}

-- Вспомогательные переменные (будут передаваться через параметры или инициализироваться снаружи)
local leftContent, leftScrollFrame, leftScrollbar
local selectedButton
local BUTTON_HEIGHT, BUTTON_TEXT_PADDING_X, BUTTON_TEXT_PADDING_Y, BUTTON_SPACING
local scrollPairs

-- Переменные для сортировки
local sortType = "level" -- "level", "title", "id"
local sortOrder = "asc" -- "asc" для возрастания, "desc" для убывания

-- Переменные для группировки
local SECTION_HEADER_PADDING = 1
local SECTION_SPACING = 1    -- Минимальное расстояние между секциями
local collapsedSections = {} -- Хранит состояние свернутых разделов

-- Функции для инициализации переменных
function QuestList.InitVars(vars)
    leftContent = vars.leftContent
    leftScrollFrame = vars.leftScrollFrame
    leftScrollbar = vars.leftScrollbar
    selectedButton = vars.selectedButton
    BUTTON_HEIGHT = vars.BUTTON_HEIGHT
    BUTTON_TEXT_PADDING_X = vars.BUTTON_TEXT_PADDING_X
    BUTTON_TEXT_PADDING_Y = vars.BUTTON_TEXT_PADDING_Y
    BUTTON_SPACING = vars.BUTTON_SPACING
    scrollPairs = vars.scrollPairs
end

-- Функция для установки параметров сортировки
function QuestList.SetSortParams(type, order)
    sortType = type or "level"
    sortOrder = order or "asc"
end

-- Новые функции для получения текущих параметров сортировки
function QuestList.GetSortType()
    return sortType
end

function QuestList.GetSortOrder()
    return sortOrder
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
    
    -- Получаем текущий шрифт и увеличиваем его размер
    local font, size, flags = header.toggleBtn.text:GetFont()
    header.toggleBtn.text:SetFont(font, size * 1.50, "") -- Убираем обводку
    
    header.toggleBtn.text:SetPoint("CENTER", header.toggleBtn, "CENTER", -6, 0)
    
    -- Текст заголовка (размер как у квестов)
    header.text = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header.text:SetJustifyH("LEFT")
    header.text:SetTextColor(0.8, 0.8, 0.8) -- светлосерый
    header.text:SetPoint("LEFT", header.toggleBtn, "RIGHT", -8, 0)
    header.text:SetPoint("RIGHT", header, "RIGHT", -SECTION_HEADER_PADDING, 0)
    
    -- Обработчики событий для заголовка
    header:SetScript("OnClick", function(self)
        QuestList.ToggleSection(self.sectionName)
    end)
    
    header:SetScript("OnMouseDown", function(self)
        self.text:SetPoint("LEFT", self.toggleBtn, "RIGHT", -6, -2)
    end)
    
    header:SetScript("OnMouseUp", function(self)
        self.text:SetPoint("LEFT", self.toggleBtn, "RIGHT", -8, 0)
    end)
    
    header:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1) -- подстветка при наведении
    end)
    
    header:SetScript("OnLeave", function(self)
        self.text:SetTextColor(0.8, 0.8, 0.8) -- возврат к светлосерому
    end)
    
    -- Обработчики событий для кнопки сворачивания
    header.toggleBtn:SetScript("OnClick", function(self, button)
        QuestList.ToggleSection(self:GetParent().sectionName)
    end)
    
    return header
end

-- Функция для настройки заголовка раздела
QuestList.SetupSectionHeader = function(header, sectionName, isCollapsed, yOffset)
    header.sectionName = sectionName
    header:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, yOffset)
    header:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, yOffset)
    
    local displayName = sectionName
    
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

    -- Начальные координаты для текста (будут изменяться в зависимости от наличия метки)
    btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", BUTTON_TEXT_PADDING_X + 4, BUTTON_TEXT_PADDING_Y)
    btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -BUTTON_TEXT_PADDING_X, BUTTON_TEXT_PADDING_Y)

    btn.text.xOffset = BUTTON_TEXT_PADDING_X + 4
    btn.text.yOffset = BUTTON_TEXT_PADDING_Y

    -- Добавляем текст для метки типа квеста в правой части
    btn.typeText = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    btn.typeText:SetJustifyH("RIGHT")
    btn.typeText:SetTextColor(0.8, 0.8, 0.8) -- Светло-серый цвет для метки
    btn.typeText:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -BUTTON_TEXT_PADDING_X, BUTTON_TEXT_PADDING_Y)
    btn.typeText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -BUTTON_TEXT_PADDING_X, BUTTON_TEXT_PADDING_Y)

    btn.selTexture = btn:CreateTexture(nil, "BACKGROUND")
    btn.selTexture:SetAllPoints(btn)
    btn.selTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.selTexture:SetBlendMode("ADD")
    btn.selTexture:SetVertexColor(1, 1, 1, 0.3) -- Белый цвет с прозрачностью
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
    local questType = data.questType
    
    -- Формируем метку типа квеста на основе questType
    local typeLabel = ""
    local typeColor = {0.8, 0.8, 0.8} -- По умолчанию светло-серый
    if questType then
        if questType:lower():find("сюжет") or questType:lower():find("story") then
            typeLabel = "(Сюжетный)"
            typeColor = {1, 0, 0}
        elseif questType:lower():find("групп") or questType:lower():find("group") then
            typeLabel = "(Групповой)"
            typeColor = {0.60, 0.60, 1} -- Голубовато-фиолетовый цвет для групповых квестов
        elseif questType:lower():find("подземель") or questType:lower():find("dungeon") then
            typeLabel = "(Подземелье)"
            typeColor = {0.2, 0.8, 0.6} -- Зеленовато-бирюзовый цвет для подземелий
        elseif questType:lower():find("рей") or questType:lower():find("dungeon") then
            typeLabel = "(Рейд)"
            typeColor = {1, 0.50, 0} 
        end
    end
    
    local color
    if type(level) == "number" and level > 0 then
        color = GetQuestDifficultyColor(level)
    else
        color = { r = 1, g = 0, b = 0 }
    end
    
    -- Сохраняем цвета для использования в обработчиках событий
    btn.normalTextColor = {r = color.r, g = color.g, b = color.b}
    btn.normalTypeColor = {r = typeColor[1], g = typeColor[2], b = typeColor[3]}
    btn.difficultyColor = {r = color.r, g = color.g, b = color.b}
    
    -- Устанавливаем основной текст (название квеста)
    local displayLeft
    if QuestList.GetSortType and QuestList.GetSortType() == "id" then
        displayLeft = tostring(qID)
    else
        displayLeft = level
    end
    btn.text:SetTextColor(color.r, color.g, color.b)
    btn.text:SetText(string.format("[%s] %s", displayLeft, title))
    
    -- Устанавливаем метку типа в правой части
    btn.typeText:SetText(typeLabel)
    btn.typeText:SetTextColor(typeColor[1], typeColor[2], typeColor[3])
    
    -- Настраиваем позиционирование текста в зависимости от наличия метки
    if typeLabel ~= "" then
        -- Если есть метка, сокращаем область текста квеста
        btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -95, BUTTON_TEXT_PADDING_Y) -- Оставляем 95 пикселей для метки
        btn.text.hasTypeLabel = true
    else
        -- Если метки нет, текст занимает всю ширину
        btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -BUTTON_TEXT_PADDING_X, BUTTON_TEXT_PADDING_Y)
        btn.text.hasTypeLabel = false
    end

    btn:SetScript("OnMouseDown", function(self)
        if self.text.hasTypeLabel then
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset + 2, self.text.yOffset - 2)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -95 + 2, self.text.yOffset - 2)
        else
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset + 2, self.text.yOffset - 2)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset + 2, self.text.yOffset - 2)
        end
        -- Метка типа не сдвигается при нажатии
    end)

    btn:SetScript("OnMouseUp", function(self)
        if self.text.hasTypeLabel then
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset, self.text.yOffset)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -95, self.text.yOffset)
        else
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset, self.text.yOffset)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset, self.text.yOffset)
        end
        -- Метка типа не сдвигается при нажатии
    end)

    btn:SetScript("OnClick", function(self)
        QuestDetails.HighlightQuestButton(self)
        QuestDetails.ShowQuestDetails(self.questID)
        -- Если мышь наведена на кнопку, делаем метку типа белой
        if self:IsMouseOver() then
            self.typeText:SetTextColor(1, 1, 1)
        end
        -- Сброс только позиции скроллбара правого окна
        if _G.QuestDetails and _G.QuestDetails.rightScrollFrame and _G.QuestDetails.rightScrollbar then
            _G.QuestDetails.rightScrollFrame:SetVerticalScroll(0)
            _G.QuestDetails.rightScrollbar:SetValue(0)
        elseif scrollPairs and scrollPairs[2] then
            if scrollPairs[2].scrollFrame then scrollPairs[2].scrollFrame:SetVerticalScroll(0) end
            if scrollPairs[2].scrollbar then scrollPairs[2].scrollbar:SetValue(0) end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        -- При наведении: только текст белый, метка типа тоже белая
        self.text:SetTextColor(1, 1, 1)
        self.typeText:SetTextColor(1, 1, 1)
    end)

    btn:SetScript("OnLeave", function(self)
        -- При уходе мыши: возвращаем нормальные цвета только если квест не выбран
        if _G.selectedButton ~= self then
            self.text:SetTextColor(self.normalTextColor.r, self.normalTextColor.g, self.normalTextColor.b)
            self.typeText:SetTextColor(self.normalTypeColor.r, self.normalTypeColor.g, self.normalTypeColor.b)
        else
            -- Если квест выбран, основной текст остается белым, метка типа возвращается к нормальному цвету
            self.text:SetTextColor(1, 1, 1)
            self.typeText:SetTextColor(self.normalTypeColor.r, self.normalTypeColor.g, self.normalTypeColor.b)
        end
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
    local showWithoutGroups = MQSH_Config and MQSH_Config.showWithoutGroups
    
    local sections = {}
    if showWithoutGroups then
        -- Все квесты одной секцией
        sections["Все квесты"] = {}
        for qID, data in pairs(questDB) do
            table.insert(sections["Все квесты"], {id = qID, data = data})
        end
    else
        -- Группируем квесты по группам или локациям
        local locationQuests = {}
        for qID, data in pairs(questDB) do
            local sectionName = data.questGroup or data.mainZone or "Неизвестная локация"
            if not locationQuests[sectionName] then
                locationQuests[sectionName] = {}
            end
            table.insert(locationQuests[sectionName], {id = qID, data = data})
        end
        for locationName, quests in pairs(locationQuests) do
            if #quests > 0 then
                sections[locationName] = quests
            end
        end
    end
    
    -- Сортируем секции
    local sortedSections = {}
    for sectionName, _ in pairs(sections) do
        table.insert(sortedSections, sectionName)
    end
    table.sort(sortedSections)
    
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
        currentYOffset = currentYOffset - BUTTON_HEIGHT + 1 -- Добавляем 2 пикселя между заголовком и квестами
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
        
        -- Добавляем небольшое расстояние между секциями (но не между заголовком и квестами)
        currentYOffset = currentYOffset - SECTION_SPACING
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

    -- Обновляем количество квестов в оверлее, если функция есть
    if overlay and overlay.UpdateQuestCount then
        overlay.UpdateQuestCount()
    end

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


    -- Создаем левый ScrollFrame и скроллбар
    local leftScrollFrame, leftContent = ScrollBarUtils.CreateScrollFrame(leftWindow, LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y)
    local leftScrollbar = ScrollBarUtils.CreateScrollBar(overlay, leftScrollFrame, leftWindow, WINDOW_SPACING, ScrollBarUtils.SCROLLBAR_WIDTH, (BUTTON_HEIGHT + BUTTON_SPACING) * 2)
    
    return leftWindow, leftScrollFrame, leftContent, leftScrollbar
end

-- Экспортируем модуль в глобальную область
_G.QuestList = QuestList 