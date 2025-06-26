local uiCreated = false

-- Настройки отступов
local OVERLAY_PADDING_LEFT_RIGHT = 5    -- Отступ от границ overlay
local OVERLAY_PADDING_TOP = 30           -- Отступ сверху
local OVERLAY_PADDING_BOTTOM = 10        -- Отступ снизу
local WINDOW_SPACING = 4                 -- Расстояние между элементами

-- Настройки окон
local SCROLLBAR_WIDTH = 16               -- Ширина скроллбара
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

-- Функции для скроллбаров
local function UpdateScrollBar(scrollFrame, scrollbar)
    if not scrollFrame or not scrollbar then return end
    
    local contentHeight = scrollFrame:GetScrollChild():GetHeight()
    local frameHeight = scrollFrame:GetHeight()
    local maxScroll = math.max(0, contentHeight - frameHeight)
    
    scrollbar:SetMinMaxValues(0, maxScroll)
    scrollbar:Show() -- Всегда показываем скроллбар
    
    -- Принудительно обновляем ползунок
    if maxScroll <= 0 then
        scrollbar:SetValue(0)
    end
end

local function UpdateAllScrollBars()
    UpdateScrollBar(leftScrollFrame, leftScrollbar)
    UpdateScrollBar(rightScrollFrame, rightScrollbar)
end

local function ResetScrollBars()
    if leftScrollFrame then leftScrollFrame:SetVerticalScroll(0) end
    if rightScrollFrame then rightScrollFrame:SetVerticalScroll(0) end
    if leftScrollbar then leftScrollbar:SetValue(0) end
    if rightScrollbar then rightScrollbar:SetValue(0) end
end

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

-- Вспомогательные функции для отображения деталей квеста
local function ClearQuestDetails()
    if objectivesSummaryFS then objectivesSummaryFS:SetText("") end
    if objectivesTextFS then objectivesTextFS:SetText("") end
    if detailsFS then detailsFS:SetText("") end
    if rewardsHeadingFS then rewardsHeadingFS:SetText("") end
    if rewardExtraFS then rewardExtraFS:SetText("") end
    if choiceLabelFS then choiceLabelFS:SetText("") end
    
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
    
    if not descHeadingFS then
        descHeadingFS = CreateFS(rightContent, "GameFontNormalHuge")
        RemoveFontOutline(descHeadingFS)
        descHeadingFS:SetJustifyH("LEFT")
    end
    
    if q.description and q.description ~= "" then
        descHeadingFS:SetText(gold .. "Описание:" .. reset)
        
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
    
    local itemsCount = q.rewards.items and #q.rewards.items or 0
    local choicesCount = q.rewards.choices and #q.rewards.choices or 0
    
    local hasRewards = (itemsCount > 0) or (choicesCount > 0) or 
                      (q.rewards.money and q.rewards.money > 0) or 
                      (q.rewards.xp and q.rewards.xp > 0)
    
    if not hasRewards then return end
    
    if not rewardsHeadingFS then
        rewardsHeadingFS = CreateFS(rightContent, "GameFontNormalHuge")
        RemoveFontOutline(rewardsHeadingFS)
    end
    rewardsHeadingFS:SetText("|cffFFD100Награды:|r")
    
    local rewardItems = {}
    if choicesCount > 0 then
        for _, item in ipairs(q.rewards.choices) do
            table.insert(rewardItems, item)
        end
    end
    if itemsCount > 0 then
        for _, item in ipairs(q.rewards.items) do
            table.insert(rewardItems, item)
        end
    end
    
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
        
        row:SetWidth(frameWidth)
        row:SetHeight(ITEM_HEIGHT)
        
        -- Получаем текстуру предмета динамически
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
    local yOffset = -detailsTitle:GetStringHeight() - 5
    
    if objectivesSummaryFS then
        objectivesSummaryFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if objectivesSummaryFS:GetText() ~= "" then
            yOffset = yOffset - objectivesSummaryFS:GetStringHeight() - 6
        end
    end
    
    if objectivesTextFS then
        objectivesTextFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        if objectivesTextFS:GetText() ~= "" then
            yOffset = yOffset - objectivesTextFS:GetStringHeight() + 5
        end
    end
    
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
        
        if rewardExtraFS then
            rewardExtraFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
            if rewardExtraFS:GetText() ~= "" then
                yOffset = yOffset - rewardExtraFS:GetStringHeight() - 4
            end
        end
    end
    
    local totalHeight = -yOffset + 10
    rightContent:SetHeight(totalHeight)
    rightScrollFrame:SetVerticalScroll(0)
    
    UpdateScrollBar(rightScrollFrame, rightScrollbar)
end

local function ShowQuestDetails(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then return end
    
    local q = MQSH_QuestDB[questID]
    
    ClearQuestDetails()
    
    SetupQuestTitle(questID, q)
    
    SetupObjectivesSummary(q)
    SetupDetailedObjectives(q)
    
    SetupDescription(q)
    
    SetupRewardItems(q)
    SetupExtraRewards(q)
    
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

    local width = leftScrollFrame:GetWidth() - 5
    local reset = "|r"

    for index, qID in ipairs(questIDs) do
        local data = MQSH_QuestDB[qID]
        local btn = leftContent.buttons[index]
        if not btn then
            btn = CreateFrame("Button", nil, leftContent)
            leftContent.buttons[index] = btn

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
        end

        btn.questID = qID
        btn:SetHeight(BUTTON_HEIGHT)

        btn:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, -(index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))
        btn:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -(index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))

        local title = data.title or ("ID " .. tostring(qID))
        local level = data.level or "??"
        local color
        if type(level) == "number" then
            color = GetQuestDifficultyColor(level)
        else
            color = { r = 1, g = 0, b = 0 }
        end
        btn.text:SetTextColor(color.r, color.g, color.b)
        btn.text:SetText(string.format("[%s] %s%s", level, title, reset))

        btn:SetScript("OnMouseDown", function(self)
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset + 2, self.text.yOffset - 2)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset + 2, self.text.yOffset - 2)
        end)

        btn:SetScript("OnMouseUp", function(self)
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.text.xOffset, self.text.yOffset)
            self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.text.xOffset, self.text.yOffset)
        end)

        btn:SetScript("OnClick", function(self)
            HighlightQuestButton(self)
            ShowQuestDetails(self.questID)
        end)

        btn:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 1)
        end)

        btn:SetScript("OnLeave", function(self)
            self.text:SetTextColor(color.r, color.g, color.b)
        end)

        btn:Show()
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
    
    UpdateAllScrollBars()

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

    local overlayWidth = QuestLogFrame:GetWidth() - 12
    local overlayHeight = QuestLogFrame:GetHeight() - 23
    
    local totalFixedWidth = OVERLAY_PADDING_LEFT_RIGHT + SCROLLBAR_WIDTH + WINDOW_SPACING + SCROLLBAR_WIDTH + OVERLAY_PADDING_LEFT_RIGHT
    local totalSpacing = WINDOW_SPACING * 3
    local availableWidth = overlayWidth - totalFixedWidth - totalSpacing
    local windowWidth = availableWidth / 2
    
    local windowHeight = overlayHeight - OVERLAY_PADDING_TOP - OVERLAY_PADDING_BOTTOM
    local rightScrollbarHeight = windowHeight - WINDOW_SPACING * 2
    
    local leftWindowX = OVERLAY_PADDING_LEFT_RIGHT
    local leftScrollbarX = leftWindowX + windowWidth + WINDOW_SPACING
    local rightWindowX = leftScrollbarX + SCROLLBAR_WIDTH + WINDOW_SPACING
    local rightScrollbarX = rightWindowX + windowWidth + WINDOW_SPACING
    
    local elementY = -OVERLAY_PADDING_TOP

    local leftWindow = CreateFrame("Frame", nil, overlay)
    leftWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", leftWindowX, elementY)
    leftWindow:SetSize(windowWidth, windowHeight)
    SetBackdrop(leftWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    local leftTitle = CreateFS(overlay, "GameFontNormal")
    leftTitle:SetPoint("BOTTOM", leftWindow, "TOP", 0, 5)
    leftTitle:SetJustifyH("CENTER")
    leftTitle:SetText("|cffFFD100Квесты|r")

    leftScrollFrame = CreateFrame("ScrollFrame", nil, leftWindow)
    leftScrollFrame:SetPoint("TOPLEFT", leftWindow, "TOPLEFT", LEFT_WINDOW_PADDING_X, -LEFT_WINDOW_PADDING_Y)
    leftScrollFrame:SetPoint("BOTTOMRIGHT", leftWindow, "BOTTOMRIGHT", -LEFT_WINDOW_PADDING_X, LEFT_WINDOW_PADDING_Y)

    leftContent = CreateFrame("Frame", nil, leftScrollFrame)
    leftContent:SetSize(leftScrollFrame:GetWidth(), 1)
    leftScrollFrame:SetScrollChild(leftContent)

    leftScrollbar = CreateFrame("Slider", nil, overlay, "UIPanelScrollBarTemplate")
    leftScrollbar:SetPoint("TOPLEFT", leftWindow, "TOPRIGHT", WINDOW_SPACING, -14)
    leftScrollbar:SetPoint("BOTTOMLEFT", leftWindow, "BOTTOMRIGHT", WINDOW_SPACING, 14)
    leftScrollbar:SetWidth(SCROLLBAR_WIDTH)
    leftScrollbar:SetValueStep(1)
    leftScrollbar:SetValue(0)
    leftScrollbar:SetMinMaxValues(0, 0)
    
    leftScrollbar:SetScript("OnValueChanged", function(self, value)
        leftScrollFrame:SetVerticalScroll(value)
    end)
    
    leftWindow:EnableMouseWheel(true)
    leftWindow:SetScript("OnMouseWheel", function(self, delta)
        local currentValue = leftScrollbar:GetValue()
        local scrollStep = BUTTON_HEIGHT + BUTTON_SPACING
        local newValue = currentValue - (delta * scrollStep)
        leftScrollbar:SetValue(newValue)
    end)

    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", rightWindowX, elementY)
    rightWindow:SetSize(windowWidth, windowHeight)
    SetBackdrop(rightWindow, {0.08, 0.08, 0.08, 0.93}, {0, 0, 0, 0.95})

    rightScrollFrame = CreateFrame("ScrollFrame", nil, rightWindow)
    rightScrollFrame:SetPoint("TOPLEFT", rightWindow, "TOPLEFT", RIGHT_WINDOW_PADDING_X, -RIGHT_WINDOW_PADDING_Y)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", rightWindow, "BOTTOMRIGHT", -RIGHT_WINDOW_PADDING_X, RIGHT_WINDOW_PADDING_Y)

    rightContent = CreateFrame("Frame", nil, rightScrollFrame)
    rightContent:SetSize(rightScrollFrame:GetWidth(), 1)
    rightScrollFrame:SetScrollChild(rightContent)

    rightScrollbar = CreateFrame("Slider", nil, overlay, "UIPanelScrollBarTemplate")
    rightScrollbar:SetPoint("TOPLEFT", rightWindow, "TOPRIGHT", WINDOW_SPACING, -14)
    rightScrollbar:SetPoint("BOTTOMLEFT", rightWindow, "BOTTOMRIGHT", WINDOW_SPACING, 14)
    rightScrollbar:SetWidth(SCROLLBAR_WIDTH)
    rightScrollbar:SetValueStep(1)
    rightScrollbar:SetValue(0)
    rightScrollbar:SetMinMaxValues(0, 0)
    
    rightScrollbar:SetScript("OnValueChanged", function(self, value)
        rightScrollFrame:SetVerticalScroll(value)
    end)
    
    rightWindow:EnableMouseWheel(true)
    rightWindow:SetScript("OnMouseWheel", function(self, delta)
        local currentValue = rightScrollbar:GetValue()
        local scrollStep = 20 -- Фиксированный шаг для правого окна
        local newValue = currentValue - (delta * scrollStep)
        rightScrollbar:SetValue(newValue)
    end)

    detailsTitle = CreateFS(rightContent, "GameFontNormalHuge")
    RemoveFontOutline(detailsTitle)
    detailsTitle:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)
    detailsTitle:SetJustifyH("LEFT")

    detailsFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, -25)

    showBtn:SetScript("OnClick", function()
        if overlay:IsShown() then
            overlay:Hide()
            ResetScrollBars()
        else
            overlay:Show()
        end
    end)

    hooksecurefunc(QuestLogFrame, "Hide", function()
        overlay:Hide()
        ResetScrollBars()
    end)

    overlay:SetScript("OnShow", function()
        BuildQuestList()
        UpdateAllScrollBars()
    end)

    -- Инициализируем скроллбары
    UpdateAllScrollBars()

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