local uiCreated = false
local QuestDetails = _G.QuestDetails
local QuestList = _G.QuestList

-- Настройки отступов
local OVERLAY_PADDING_LEFT_RIGHT = 5    -- Отступ от границ overlay
local OVERLAY_PADDING_TOP = 30           -- Отступ сверху
local OVERLAY_PADDING_BOTTOM = 10        -- Отступ снизу
local WINDOW_SPACING = 4                 -- Расстояние между элементами

-- Настройки окон
local TITLE_TOP_OFFSET = 5               -- Отступ заголовка

-- Отступы контента внутри окон
local LEFT_WINDOW_PADDING_X = 6          -- Отступ по X в левом окне
local LEFT_WINDOW_PADDING_Y = 3          -- Отступ по Y в левом окне
local RIGHT_WINDOW_PADDING_X = 5         -- Отступ по X в правом окне
local RIGHT_WINDOW_PADDING_Y = 7         -- Отступ по Y в правом окне

-- Настройки кнопок
local BUTTON_HEIGHT = 17                 -- Высота кнопки
local BUTTON_TEXT_PADDING = 5            -- Отступ текста по X
local BUTTON_SPACING = 1                 -- Расстояние между кнопками

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

-- Переменные для предметов-целей
local objectiveItemFrames = {}
local objectiveItemsVisibleCount = 0

-- Таблица пар скроллбаров для утилит
local scrollPairs = {}

-- Переменные для сортировки
local sortType = "level" -- "level", "title", "id"
local sortOrder = "asc" -- "asc" для возрастания, "desc" для убывания
local sortDropdown, orderBtn

-- Функция для создания выпадающего окна сортировки
local function CreateSortDropdown(parent)
    local dropdown = CreateFrame("Frame", "MQSH_SortDropdown", parent, "UIDropDownMenuTemplate")
    
    -- Создаем кнопку для переключения порядка сортировки
    local orderBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    orderBtn:SetSize(50, 20)
    orderBtn:SetText("A->Z")
    
    orderBtn:SetScript("OnClick", function(self)
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
    
    -- Функция для инициализации выпадающего меню
    local function InitializeDropdown(self, level)
        level = level or 1
        local info = UIDropDownMenu_CreateInfo()
        
        if level == 1 then
            info.text = "Сортировка"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
            info.isTitle = false
            info.func = function(self, arg1, arg2, checked)
                sortType = arg1
                UIDropDownMenu_SetSelectedValue(dropdown, arg1)
                QuestList.SetSortParams(sortType, sortOrder)
                QuestList.BuildQuestList()
            end
            
            info.text = "По уровню"
            info.value = "level"
            info.checked = (sortType == "level")
            UIDropDownMenu_AddButton(info, level)
            
            info.text = "По названию"
            info.value = "title"
            info.checked = (sortType == "title")
            UIDropDownMenu_AddButton(info, level)
            
            info.text = "По ID"
            info.value = "id"
            info.checked = (sortType == "id")
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetSelectedValue(dropdown, sortType)
    UIDropDownMenu_SetWidth(dropdown, 120)
    
    return dropdown, orderBtn
end

local function TryCreateQuestUI()
    if uiCreated or not QuestLogFrame then return end

    local showBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    showBtn:SetSize(80, 22)
    showBtn:SetText("История")
    showBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -150, -30)

    overlay = CreateFrame("Frame", "MQSH_QuestOverlay", QuestLogFrame)
    overlay:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 11, -12)
    overlay:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -1, 11)
    ScrollBarUtils.SetBackdrop(overlay, {0.10, 0.10, 0.10, 0.85}, {0, 0, 0, 0.95})
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)

    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 3, 3)
    
    closeBtn:SetScript("OnClick", function()
        overlay:Hide()
        ScrollBarUtils.ResetScrollBars(scrollPairs)
        -- Сбрасываем параметры сортировки
        sortType = "level"
        sortOrder = "asc"
        if sortDropdown then
            UIDropDownMenu_SetSelectedValue(sortDropdown, sortType)
        end
        if orderBtn then
            orderBtn:SetText("A->Z")
        end
        QuestList.SetSortParams(sortType, sortOrder)
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
    local leftWindow, leftScrollFrame, leftContent, leftScrollbar, leftTitle = QuestList.CreateLeftWindow(
        overlay, windowWidth, windowHeight, leftWindowX, elementY, 
        LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y, WINDOW_SPACING, BUTTON_HEIGHT, BUTTON_SPACING
    )

    -- Изменяем заголовок на "История квестов" и центрируем его
    leftTitle:SetText("|cffFFD100История квестов|r")
    leftTitle:ClearAllPoints()
    leftTitle:SetPoint("TOP", overlay, "TOP", 0, -2)

    -- Создаем элементы сортировки в QuestOverlay
    sortDropdown, orderBtn = CreateSortDropdown(overlay)
    sortDropdown:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -2)
    orderBtn:SetPoint("LEFT", sortDropdown, "RIGHT", 5, 0)

    -- Создаем правый ScrollFrame и скроллбар
    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", rightWindowX, elementY)
    rightWindow:SetSize(windowWidth, windowHeight)
    ScrollBarUtils.SetBackdrop(rightWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    rightScrollFrame, rightContent = ScrollBarUtils.CreateScrollFrame(rightWindow, RIGHT_WINDOW_PADDING_X, RIGHT_WINDOW_PADDING_Y)
    rightScrollbar = ScrollBarUtils.CreateScrollBar(overlay, rightScrollFrame, rightWindow, WINDOW_SPACING, ScrollBarUtils.SCROLLBAR_WIDTH, 60)

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
        objectiveItemFrames = objectiveItemFrames,
        rewardsVisibleCount = rewardsVisibleCount,
        objectiveItemsVisibleCount = objectiveItemsVisibleCount,
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
        BUTTON_TEXT_PADDING = BUTTON_TEXT_PADDING,
        BUTTON_SPACING = BUTTON_SPACING,
        scrollPairs = scrollPairs
    })

    showBtn:SetScript("OnClick", function()
        if overlay:IsShown() then
            overlay:Hide()
            ScrollBarUtils.ResetScrollBars(scrollPairs)
            -- Сбрасываем параметры сортировки
            sortType = "level"
            sortOrder = "asc"
            if sortDropdown then
                UIDropDownMenu_SetSelectedValue(sortDropdown, sortType)
            end
            if orderBtn then
                orderBtn:SetText("A->Z")
            end
            QuestList.SetSortParams(sortType, sortOrder)
        else
            overlay:Show()
        end
    end)

    hooksecurefunc(QuestLogFrame, "Hide", function()
        overlay:Hide()
        ScrollBarUtils.ResetScrollBars(scrollPairs)
        -- Сбрасываем параметры сортировки
        sortType = "level"
        sortOrder = "asc"
        if sortDropdown then
            UIDropDownMenu_SetSelectedValue(sortDropdown, sortType)
        end
        if orderBtn then
            orderBtn:SetText("A->Z")
        end
        QuestList.SetSortParams(sortType, sortOrder)
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
    end)

    -- Инициализируем скроллбары
    ScrollBarUtils.UpdateAllScrollBars(scrollPairs)

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