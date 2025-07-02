local uiCreated = false
local QuestDetails = _G.QuestDetails
local QuestList = _G.QuestList

-- Настройки отступов
local OVERLAY_PADDING_LEFT_RIGHT = 7    -- Отступ от границ overlay
local OVERLAY_PADDING_TOP = 45           -- Отступ сверху
local OVERLAY_PADDING_BOTTOM = 35        -- Отступ снизу
local WINDOW_SPACING = 4                 -- Расстояние между элементами

-- Настройки окон
local TITLE_TOP_OFFSET = 5               -- Отступ заголовка

-- Отступы контента внутри окон
local LEFT_WINDOW_PADDING_X = 6          -- Отступ по X в левом окне
local LEFT_WINDOW_PADDING_Y = 3          -- Отступ по Y в левом окне
local RIGHT_WINDOW_PADDING_X = 5         -- Отступ по X в правом окне
local RIGHT_WINDOW_PADDING_Y = 7         -- Отступ по Y в правом окне

-- Настройки кнопок
local BUTTON_HEIGHT = 16                 -- Высота кнопки
local BUTTON_TEXT_PADDING_X = 5          -- Отступ текста по X
local BUTTON_TEXT_PADDING_Y = 0          -- Отступ текста по Y
local BUTTON_SPACING = 0                 -- Расстояние между кнопками

-- Переменные интерфейса
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
local leftScrollbar, rightScrollbar

-- Таблица пар скроллбаров для утилит
local scrollPairs = {}

-- Переменные для сортировки
local sortDropdown, orderBtn

-- Функция для создания выпадающего окна сортировки
local function CreateSortDropdown(parent)
    local dropdown = CreateFrame("Frame", "MQSH_SortDropdown", parent, "UIDropDownMenuTemplate")
    
    local orderBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    orderBtn:SetSize(50, 20)
    orderBtn:SetText(QuestList.GetSortOrder() == "asc" and "A->Z" or "Z->A")
    
    orderBtn:SetScript("OnClick", function(self)
        local sortType = QuestList.GetSortType()
        local sortOrder = QuestList.GetSortOrder()
        if sortOrder == "asc" then
            sortOrder = "desc"
            self:SetText("Z->A")
        else
            sortOrder = "asc"
            self:SetText("A->Z")
        end
        QuestList.SetSortParams(sortType, sortOrder)
        QuestList.BuildQuestList()
    end)
    
    local function InitializeDropdown(self, level)
        level = level or 1
        local sortType = QuestList.GetSortType()
        local sortOrder = QuestList.GetSortOrder()
        if level == 1 then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Сортировка"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)

            -- По уровню
            info = UIDropDownMenu_CreateInfo()
            info.text = "По уровню"
            info.value = "level"
            info.checked = (sortType == "level")
            info.func = function(self)
                QuestList.SetSortParams("level", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "level")
                QuestList.BuildQuestList()
            end
            UIDropDownMenu_AddButton(info, level)

            -- По названию
            info = UIDropDownMenu_CreateInfo()
            info.text = "По названию"
            info.value = "title"
            info.checked = (sortType == "title")
            info.func = function(self)
                QuestList.SetSortParams("title", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "title")
                QuestList.BuildQuestList()
            end
            UIDropDownMenu_AddButton(info, level)

            -- По ID
            info = UIDropDownMenu_CreateInfo()
            info.text = "По ID"
            info.value = "id"
            info.checked = (sortType == "id")
            info.func = function(self)
                QuestList.SetSortParams("id", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "id")
                QuestList.BuildQuestList()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetSelectedValue(dropdown, QuestList.GetSortType())
    UIDropDownMenu_SetWidth(dropdown, 120)
    
    return dropdown, orderBtn
end

local function TryCreateQuestUI()
    if uiCreated or not QuestLogFrame then return end

    local HistoryBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    HistoryBtn:SetSize(65, 22)
    HistoryBtn:SetText("История")
    HistoryBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -250, -34)

    local DataBtn = CreateFrame("Button", "MQSH_ShowListButton", HistoryBtn, "UIPanelButtonTemplate")
    DataBtn:SetSize(95, 22)
    DataBtn:SetText("База данных")
    DataBtn:SetPoint("TOPRIGHT", HistoryBtn, "TOPRIGHT", 98, 0)

    overlay = CreateFrame("Frame", "MQSH_QuestOverlay", QuestLogFrame)
    overlay:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 11, -12)
    overlay:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -1, 11)
    ScrollBarUtils.SetBackdrop(overlay, {0.10, 0.10, 0.10, 0.95}, {0, 0, 0, 0.95})
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)

    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 3, 3)
    
    closeBtn:SetScript("OnClick", function()
        overlay:Hide()
        ScrollBarUtils.ResetScrollBars(scrollPairs)
        -- Сбрасываем параметры сортировки
        QuestList.SetSortParams(QuestList.GetSortType(), QuestList.GetSortOrder())
    end)

    local overlayWidth = QuestLogFrame:GetWidth() - 12
    local overlayHeight = QuestLogFrame:GetHeight() - 23
    
    local totalFixedWidth = OVERLAY_PADDING_LEFT_RIGHT + ScrollBarUtils.SCROLLBAR_WIDTH + WINDOW_SPACING + ScrollBarUtils.SCROLLBAR_WIDTH + OVERLAY_PADDING_LEFT_RIGHT
    local totalSpacing = WINDOW_SPACING * 3
    local availableWidth = overlayWidth - totalFixedWidth - totalSpacing
    local windowWidth = availableWidth / 2
    
    local windowHeight = overlayHeight - OVERLAY_PADDING_TOP - OVERLAY_PADDING_BOTTOM
    local rightScrollbarHeight = windowHeight - WINDOW_SPACING * 2
    
    local leftWindowX = OVERLAY_PADDING_LEFT_RIGHT
    local leftScrollbarX = leftWindowX + windowWidth + WINDOW_SPACING
    local rightWindowX = leftScrollbarX + ScrollBarUtils.SCROLLBAR_WIDTH + WINDOW_SPACING
    local rightScrollbarX = rightWindowX + windowWidth + WINDOW_SPACING
    
    local elementY = -OVERLAY_PADDING_TOP

    -- Создаем левое окно через модуль QuestList
    local leftWindow, leftScrollFrame, leftContent, leftScrollbar, rightTitle = QuestList.CreateLeftWindow(
        overlay, windowWidth, windowHeight, leftWindowX, elementY, 
        LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y, WINDOW_SPACING, BUTTON_HEIGHT, BUTTON_SPACING
    )

    local rightTitle = ScrollBarUtils.CreateFS(overlay, "GameFontHighlight")
    rightTitle:SetText("|cffFFD100История квестов|r")
    rightTitle:ClearAllPoints()
    rightTitle:SetPoint("TOP", overlay, "TOP", 0, -2)

    -- Создаем элементы сортировки в QuestOverlay
    local sortBtnY = -OVERLAY_PADDING_TOP/2
    -- Создаем текст для количества квестов
    local questCountFS = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    questCountFS:SetPoint("TOPLEFT", overlay, "TOPLEFT", 7, sortBtnY)
    questCountFS:SetJustifyH("LEFT")
    if ScrollBarUtils and ScrollBarUtils.AddFontOutline then
        ScrollBarUtils.AddFontOutline(questCountFS)
    end
    
    local function UpdateQuestCountText()
        local count = 0
        if type(MQSH_QuestDB) == "table" then
            for _ in pairs(MQSH_QuestDB) do count = count + 1 end
        end
        questCountFS:SetText("Квестов: " .. count)
    end
    UpdateQuestCountText()

    -- Делаем дропдаун дочерним элементом для questCountFS
    sortDropdown, orderBtn = CreateSortDropdown(overlay)
    sortDropdown:SetPoint("LEFT", questCountFS, "RIGHT", 30, -1)
    orderBtn:SetPoint("LEFT", sortDropdown, "RIGHT", -13, -1)

    -- Создаем правый ScrollFrame и скроллбар
    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", rightWindowX, elementY)
    rightWindow:SetSize(windowWidth, windowHeight)
    ScrollBarUtils.SetBackdrop(rightWindow, {0.07, 0.07, 0.07, 0.97}, {0, 0, 0, 0.95})

    rightScrollFrame, rightContent = ScrollBarUtils.CreateScrollFrame(rightWindow, RIGHT_WINDOW_PADDING_X, RIGHT_WINDOW_PADDING_Y)
    rightScrollbar = ScrollBarUtils.CreateScrollBar(rightWindow, rightScrollFrame, rightWindow, WINDOW_SPACING - 2, ScrollBarUtils.SCROLLBAR_WIDTH, 60)

    -- Инициализируем таблицу пар скроллбаров
    scrollPairs = {
        {scrollFrame = leftScrollFrame, scrollbar = leftScrollbar},
        {scrollFrame = rightScrollFrame, scrollbar = rightScrollbar}
    }

    detailsTitle = ScrollBarUtils.CreateFS(rightContent, "GameFontNormalHuge")
    ScrollBarUtils.RemoveFontOutline(detailsTitle)
    detailsTitle:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)
    detailsTitle:SetJustifyH("LEFT")

    detailsFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, -25)

    -- Создаем элемент для метаданных квеста
    local questMetaFS = ScrollBarUtils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    questMetaFS:SetJustifyH("LEFT")

    -- Инициализируем переменные для модуля QuestDetails
    QuestDetails.InitVars({
        rewardItemFrames = rewardItemFrames,
        rewardsVisibleCount = rewardsVisibleCount,
        objectivesSummaryFS = objectivesSummaryFS,
        objectivesTextFS = objectivesTextFS,
        detailsFS = detailsFS,
        rewardsHeadingFS = rewardsHeadingFS,
        rewardExtraFS = rewardExtraFS,
        choiceLabelFS = choiceLabelFS,
        descHeadingFS = descHeadingFS,
        detailsTitle = detailsTitle,
        questMetaFS = questMetaFS,
        rightContent = rightContent,
        rightScrollFrame = rightScrollFrame,
        rightScrollbar = rightScrollbar,
        selectedButton = selectedButton
    })

    -- Инициализируем переменные для модуля QuestList
    QuestList.InitVars({
        leftContent = leftContent,
        leftScrollFrame = leftScrollFrame,
        leftScrollbar = leftScrollbar,
        selectedButton = selectedButton,
        BUTTON_HEIGHT = BUTTON_HEIGHT,
        BUTTON_TEXT_PADDING_X = BUTTON_TEXT_PADDING_X,
        BUTTON_TEXT_PADDING_Y = BUTTON_TEXT_PADDING_Y,
        BUTTON_SPACING = BUTTON_SPACING,
        scrollPairs = scrollPairs
    })

    DataBtn:SetScript("OnClick", function()
        if overlay:IsShown() then
            overlay:Hide()
            ScrollBarUtils.ResetScrollBars(scrollPairs)
            -- Сбрасываем параметры сортировки
            QuestList.SetSortParams(QuestList.GetSortType(), QuestList.GetSortOrder())
        else
            overlay:Show()
        end
    end)

    hooksecurefunc(QuestLogFrame, "Hide", function()
        overlay:Hide()
        ScrollBarUtils.ResetScrollBars(scrollPairs)
        -- Сбрасываем параметры сортировки
        QuestList.SetSortParams(QuestList.GetSortType(), QuestList.GetSortOrder())
    end)

    overlay:SetScript("OnShow", function()
        QuestList.BuildQuestList()
        ScrollBarUtils.UpdateAllScrollBars(scrollPairs)
        -- Принудительно сбрасываем позицию скроллбаров в начало
        for _, pair in ipairs(scrollPairs) do
            if pair.scrollFrame then 
                pair.scrollFrame:SetVerticalScroll(0) 
            end
            if pair.scrollbar then 
                pair.scrollbar:SetValue(0) 
            end
        end
        UpdateQuestCountText()
    end)

    -- Инициализируем скроллбары
    ScrollBarUtils.UpdateAllScrollBars(scrollPairs)

    -- После BuildQuestList тоже обновляем количество квестов
    local oldBuildQuestList = QuestList.BuildQuestList
    QuestList.BuildQuestList = function(...)
        oldBuildQuestList(...)
        UpdateQuestCountText()
    end

    -- После создания левого окна
    -- Центрируем панель чекбокса между нижней границей левого окна и overlay
    local leftWindowBottomY = elementY - windowHeight
    local overlayBottomY = -overlayHeight + OVERLAY_PADDING_BOTTOM
    local centerOffset = (overlayBottomY - leftWindowBottomY) / 2 - 2
    local checkboxPanel = CreateFrame("Frame", nil, overlay)
    checkboxPanel:SetPoint("TOPLEFT", leftWindow, "BOTTOMLEFT", 0, centerOffset)
    checkboxPanel:SetPoint("TOPRIGHT", leftWindow, "BOTTOMRIGHT", 0, centerOffset)
    checkboxPanel:SetHeight(28)
    
    local showWithoutGroupsCheck = CreateFrame("CheckButton", nil, checkboxPanel, "UICheckButtonTemplate")
    showWithoutGroupsCheck:SetSize(22, 22)
    showWithoutGroupsCheck:SetPoint("LEFT", checkboxPanel, "LEFT", 2, 0)
    showWithoutGroupsCheck.text = showWithoutGroupsCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    showWithoutGroupsCheck.text:SetPoint("LEFT", showWithoutGroupsCheck, "RIGHT", 5, 0)
    showWithoutGroupsCheck.text:SetText("Без группировки")
    showWithoutGroupsCheck:SetChecked(MQSH_Config and MQSH_Config.showWithoutGroups)
    showWithoutGroupsCheck:SetScript("OnClick", function(self)
        MQSH_Config.showWithoutGroups = self:GetChecked()
        QuestList.BuildQuestList()
    end)

    uiCreated = true
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        TryCreateQuestUI()
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_QuestLog" then
        TryCreateQuestUI()
    end
end)

_G.QuestOverlay_TryInit = TryCreateQuestUI 