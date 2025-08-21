local uiCreated = false
local QuestDetails = _G.QuestDetails
local QuestList = _G.QuestList

local function UpdateQuestCountText()
    local count = 0
    
    local currentPlayerEnabled = true
    if _G.MQSH_QuestOverlay and _G.MQSH_QuestOverlay.currentPlayerCheck then
        currentPlayerEnabled = _G.MQSH_QuestOverlay.currentPlayerCheck:GetChecked()
    end
    
    if currentPlayerEnabled then
        local charHistoryDB = MQSH_Char_HistoryDB or {}
        for _ in pairs(charHistoryDB) do count = count + 1 end
    else
        if type(MQSH_QuestDB) == "table" then
            for _ in pairs(MQSH_QuestDB) do count = count + 1 end
        end
    end
    
    if _G.MQSH_QuestOverlay and _G.MQSH_QuestOverlay.questCountFS then
        _G.MQSH_QuestOverlay.questCountFS:SetText("Квестов: " .. count)
    end
end

_G.UpdateQuestCountText = UpdateQuestCountText

local OVERLAY_PADDING_LEFT_RIGHT = 7
local OVERLAY_PADDING_TOP = 45
local OVERLAY_PADDING_BOTTOM = 35
local WINDOW_SPACING = 4

local TITLE_TOP_OFFSET = 5

local LEFT_WINDOW_PADDING_X = 6
local LEFT_WINDOW_PADDING_Y = 3
local RIGHT_WINDOW_PADDING_X = 5
local RIGHT_WINDOW_PADDING_Y = 7

local BUTTON_HEIGHT = 16
local BUTTON_TEXT_PADDING_X = 5
local BUTTON_TEXT_PADDING_Y = 0
local BUTTON_SPACING = 0

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

local scrollPairs = {}

local sortDropdown, orderBtn

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
        UpdateQuestCountText()
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

            info = UIDropDownMenu_CreateInfo()
            info.text = "По уровню"
            info.value = "level"
            info.checked = (sortType == "level")
            info.func = function(self)
                QuestList.SetSortParams("level", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "level")
                QuestList.BuildQuestList()
                UpdateQuestCountText()
            end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "По названию"
            info.value = "title"
            info.checked = (sortType == "title")
            info.func = function(self)
                QuestList.SetSortParams("title", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "title")
                QuestList.BuildQuestList()
                UpdateQuestCountText()
            end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "По ID"
            info.value = "id"
            info.checked = (sortType == "id")
            info.func = function(self)
                QuestList.SetSortParams("id", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "id")
                QuestList.BuildQuestList()
                UpdateQuestCountText()
            end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "По дате принятия"
            info.value = "date"
            info.checked = (sortType == "date")
            info.func = function(self)
                QuestList.SetSortParams("date", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "date")
                QuestList.BuildQuestList()
                UpdateQuestCountText()
            end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "По дате завершения"
            info.value = "completion"
            info.checked = (sortType == "completion")
            info.func = function(self)
                QuestList.SetSortParams("completion", sortOrder)
                UIDropDownMenu_SetSelectedValue(dropdown, "completion")
                QuestList.BuildQuestList()
                UpdateQuestCountText()
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

    local DataBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    DataBtn:SetSize(80, 22)
    DataBtn:SetText("История")
    DataBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -150, -33)

    overlay = CreateFrame("Frame", "MQSH_QuestOverlay", QuestLogFrame)
    overlay:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 11, -12)
    overlay:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -1, 11)
    Utils.SetBackdrop(overlay, {0.10, 0.10, 0.10, 0.95}, {0, 0, 0, 0.95})
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)

    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 3, 3)
    
    closeBtn:SetScript("OnClick", function()
        overlay:Hide()
        Utils.ResetScrollBars(scrollPairs)
        QuestList.SetSortParams(QuestList.GetSortType(), QuestList.GetSortOrder())
    end)

    local overlayWidth = QuestLogFrame:GetWidth() - 12
    local overlayHeight = QuestLogFrame:GetHeight() - 23
    
    local totalFixedWidth = OVERLAY_PADDING_LEFT_RIGHT + Utils.SCROLLBAR_WIDTH + Utils.SCROLLBAR_WIDTH + OVERLAY_PADDING_LEFT_RIGHT
    local totalSpacing = WINDOW_SPACING * 3
    local availableWidth = overlayWidth - totalFixedWidth - totalSpacing
    local windowWidth = availableWidth / 2
    
    local windowHeight = overlayHeight - OVERLAY_PADDING_TOP - OVERLAY_PADDING_BOTTOM
    
    local leftWindowX = OVERLAY_PADDING_LEFT_RIGHT
    local leftScrollbarX = leftWindowX + windowWidth + WINDOW_SPACING
    local rightWindowX = leftScrollbarX + Utils.SCROLLBAR_WIDTH + WINDOW_SPACING
    local rightScrollbarX = rightWindowX + windowWidth + WINDOW_SPACING
    
    local elementY = -OVERLAY_PADDING_TOP

    local leftWindow, leftScrollFrame, leftContent, leftScrollbar, rightTitle = QuestList.CreateLeftWindow(
        overlay, windowWidth, windowHeight, leftWindowX, elementY, 
        LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y, WINDOW_SPACING, BUTTON_HEIGHT, BUTTON_SPACING
    )

    local rightTitle = Utils.CreateFS(overlay, "GameFontHighlight")
    rightTitle:SetText("|cffFFD100История квестов|r")
    rightTitle:ClearAllPoints()
    rightTitle:SetPoint("TOP", overlay, "TOP", 0, -2)

    local sortBtnY = -OVERLAY_PADDING_TOP/2
    local questCountFS = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    questCountFS:SetPoint("TOPLEFT", overlay, "TOPLEFT", 7, sortBtnY)
    questCountFS:SetJustifyH("LEFT")
    if Utils and Utils.AddFontOutline then
        Utils.AddFontOutline(questCountFS)
    end
    
    overlay.questCountFS = questCountFS
    
    overlay.UpdateQuestCountText = UpdateQuestCountText
    _G.UpdateQuestCountText = UpdateQuestCountText
    
    UpdateQuestCountText()

    sortDropdown, orderBtn = CreateSortDropdown(overlay)
    sortDropdown:SetPoint("LEFT", questCountFS, "RIGHT", 30, -1)
    orderBtn:SetPoint("LEFT", sortDropdown, "RIGHT", -13, -1)

    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", rightWindowX, elementY)
    rightWindow:SetSize(windowWidth, windowHeight)
    Utils.SetBackdrop(rightWindow, {0.07, 0.07, 0.07, 0.97}, {0, 0, 0, 0.95})

    rightScrollFrame, rightContent = Utils.CreateScrollFrame(rightWindow, RIGHT_WINDOW_PADDING_X, RIGHT_WINDOW_PADDING_Y)
    rightScrollbar = Utils.CreateScrollBar(rightWindow, rightScrollFrame, rightWindow, WINDOW_SPACING, Utils.SCROLLBAR_WIDTH, 60)

    scrollPairs = {
        {scrollFrame = leftScrollFrame, scrollbar = leftScrollbar},
        {scrollFrame = rightScrollFrame, scrollbar = rightScrollbar}
    }

    detailsTitle = Utils.CreateFS(rightContent, "GameFontNormalHuge")
    Utils.RemoveFontOutline(detailsTitle)
    detailsTitle:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)
    detailsTitle:SetJustifyH("LEFT")

    detailsFS = Utils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, -25)

    local questMetaFS = Utils.CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    questMetaFS:SetJustifyH("LEFT")

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
            Utils.ResetScrollBars(scrollPairs)
            QuestList.SetSortParams(QuestList.GetSortType(), QuestList.GetSortOrder())
        else
            overlay:Show()
        end
    end)

    hooksecurefunc(QuestLogFrame, "Hide", function()
        overlay:Hide()
        Utils.ResetScrollBars(scrollPairs)
        QuestList.SetSortParams(QuestList.GetSortType(), QuestList.GetSortOrder())
    end)

    overlay:SetScript("OnShow", function()
        QuestList.BuildQuestList()
        Utils.UpdateAllScrollBars(scrollPairs)
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

    Utils.UpdateAllScrollBars(scrollPairs)

    local oldBuildQuestList = QuestList.BuildQuestList
    QuestList.BuildQuestList = function(...)
        oldBuildQuestList(...)
        UpdateQuestCountText()
    end

    local leftWindowBottomY = elementY - windowHeight
    local overlayBottomY = -overlayHeight + OVERLAY_PADDING_BOTTOM
    local centerOffset = (overlayBottomY - leftWindowBottomY) / 2 - 2
    local checkboxPanel = CreateFrame("Frame", nil, overlay)
    checkboxPanel:SetPoint("TOPLEFT", leftWindow, "BOTTOMLEFT", 0, centerOffset)
    checkboxPanel:SetPoint("TOPRIGHT", leftWindow, "BOTTOMRIGHT", 0, centerOffset)
    checkboxPanel:SetHeight(28)
    
    local showWithoutGroupsButton = CreateFrame("Button", nil, checkboxPanel)
    showWithoutGroupsButton:SetPoint("LEFT", checkboxPanel, "LEFT", 2, 0)
    showWithoutGroupsButton:SetSize(120, 22)
    
    local showWithoutGroupsCheck = CreateFrame("CheckButton", nil, showWithoutGroupsButton, "UICheckButtonTemplate")
    showWithoutGroupsCheck:SetSize(22, 22)
    showWithoutGroupsCheck:SetPoint("LEFT", showWithoutGroupsButton, "LEFT", 0, 0)
    showWithoutGroupsCheck.text = showWithoutGroupsCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    showWithoutGroupsCheck.text:SetPoint("LEFT", showWithoutGroupsCheck, "RIGHT", 5, 0)
    showWithoutGroupsCheck.text:SetText("Без группировки")
    showWithoutGroupsCheck:SetChecked(false)
    
    showWithoutGroupsButton:SetScript("OnClick", function()
        showWithoutGroupsCheck:SetChecked(not showWithoutGroupsCheck:GetChecked())
        MQSH_Config.showWithoutGroups = showWithoutGroupsCheck:GetChecked()
        QuestList.BuildQuestList()
        UpdateQuestCountText()
    end)
    
    showWithoutGroupsCheck:SetScript("OnClick", function(self)
        MQSH_Config.showWithoutGroups = self:GetChecked()
        QuestList.BuildQuestList()
        UpdateQuestCountText()
    end)

    local currentPlayerButton = CreateFrame("Button", nil, checkboxPanel)
    currentPlayerButton:SetPoint("LEFT", showWithoutGroupsButton, "RIGHT", 20, 0)
    currentPlayerButton:SetSize(140, 22)
    
    local currentPlayerCheck = CreateFrame("CheckButton", nil, currentPlayerButton, "UICheckButtonTemplate")
    currentPlayerCheck:SetSize(22, 22)
    currentPlayerCheck:SetPoint("LEFT", currentPlayerButton, "LEFT", 0, 0)
    currentPlayerCheck.text = currentPlayerCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    currentPlayerCheck.text:SetPoint("LEFT", currentPlayerCheck, "RIGHT", 5, 0)
    currentPlayerCheck.text:SetText("Текущий персонаж")
    currentPlayerCheck:SetChecked(true)
    
    overlay.currentPlayerCheck = currentPlayerCheck
    
    currentPlayerButton:SetScript("OnClick", function()
        currentPlayerCheck:SetChecked(not currentPlayerCheck:GetChecked())
        QuestList.BuildQuestList()
        UpdateQuestCountText()
    end)
    
    currentPlayerCheck:SetScript("OnClick", function(self)
        QuestList.BuildQuestList()
        UpdateQuestCountText()
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