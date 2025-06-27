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

local function TryCreateQuestUI()
    if uiCreated or not QuestLogFrame then return end

    local showBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    showBtn:SetSize(80, 22)
    showBtn:SetText("История")
    showBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -150, -30)

    overlay = CreateFrame("Frame", "MQSH_QuestOverlay", QuestLogFrame)
    overlay:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 11, -12)
    overlay:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -1, 11)
    ScrollBarUtils.SetBackdrop(overlay, {0.05, 0.05, 0.05, 0.85}, {0, 0, 0, 0.95})
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)

    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 3, 3)

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

    -- Создаем правый ScrollFrame и скроллбар
    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", rightWindowX, elementY)
    rightWindow:SetSize(windowWidth, windowHeight)
    ScrollBarUtils.SetBackdrop(rightWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    rightScrollFrame, rightContent = ScrollBarUtils.CreateScrollFrame(rightWindow, RIGHT_WINDOW_PADDING_X, RIGHT_WINDOW_PADDING_Y)
    rightScrollbar = ScrollBarUtils.CreateScrollBar(overlay, rightScrollFrame, rightWindow, WINDOW_SPACING, ScrollBarUtils.SCROLLBAR_WIDTH, 20)

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
        else
            overlay:Show()
        end
    end)

    hooksecurefunc(QuestLogFrame, "Hide", function()
        overlay:Hide()
        ScrollBarUtils.ResetScrollBars(scrollPairs)
    end)

    overlay:SetScript("OnShow", function()
        QuestList.BuildQuestList()
        ScrollBarUtils.UpdateAllScrollBars(scrollPairs)
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