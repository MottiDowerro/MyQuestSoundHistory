local addonName = ...

-- Флаг, чтобы не создавать UI повторно
local uiCreated = false

-- Ссылки на ключевые элементы UI, понадобятся позже
local overlay
local leftScrollFrame, leftContent
local rightScrollFrame, rightContent, detailsFS

------------------------------------------------------------
-- Утилиты --------------------------------------------------
------------------------------------------------------------
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

-- Быстрое создание FontString с нужными параметрами
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

------------------------------------------------------------
-- Правый блок: подробная информация о задании --------------
------------------------------------------------------------
local function ShowQuestDetails(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then return end

    local q = MQSH_QuestDB[questID]

    local gold  = "|cffFFD100"
    local white = "|cffffffff"
    local grey  = "|cffAAAAAA"
    local reset = "|r"

    local text = {}
    -- Заголовок
    table.insert(text, gold .. q.title .. reset .. "\n\n")
    -- Описание
    if q.description and q.description ~= "" then
        table.insert(text, white .. q.description .. reset .. "\n\n")
    end
    -- Цели задания
    if q.objectives and #q.objectives > 0 then
        table.insert(text, gold .. "Цели:" .. reset .. "\n")
        for _, obj in ipairs(q.objectives) do
            table.insert(text, "  - " .. obj .. "\n")
        end
        table.insert(text, "\n")
    end
    -- Награды
    if q.rewards then
        local hasRewards = (#q.rewards.items > 0) or (#q.rewards.choices > 0) or (q.rewards.money and q.rewards.money > 0)
        if hasRewards then
            table.insert(text, gold .. "Награды:" .. reset .. "\n")
            if q.rewards.money and q.rewards.money > 0 then
                table.insert(text, "  " .. GetCoinTextureString(q.rewards.money) .. "\n")
            end
            for _, item in ipairs(q.rewards.items) do
                table.insert(text, "  " .. item .. "\n")
            end
            if #q.rewards.choices > 0 then
                table.insert(text, grey .. "  Возможный выбор: " .. reset .. "\n")
                for _, item in ipairs(q.rewards.choices) do
                    table.insert(text, "    " .. item .. "\n")
                end
            end
        end
    end

    -- Объединяем всё в одну строку
    detailsFS:SetText(table.concat(text, ""))
    -- Обновляем высоту контейнера, чтобы скролл работал корректно
    rightContent:SetHeight(detailsFS:GetStringHeight() + 20)
    rightScrollFrame:SetVerticalScroll(0)
end

------------------------------------------------------------
-- Левый блок: список квестов ------------------------------
------------------------------------------------------------
local function BuildQuestList()
    if not leftContent then return end

    -- Очищаем старые кнопки если они были
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

    local btnHeight = 20
    local width = leftScrollFrame:GetWidth() - 5
    local gold = "|cffFFD100"
    local reset = "|r"

    for index, qID in ipairs(questIDs) do
        local data = MQSH_QuestDB[qID]
        local btn = leftContent.buttons[index]
        if not btn then
            btn = CreateFrame("Button", nil, leftContent)
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            leftContent.buttons[index] = btn

            btn.text = CreateFS(btn, "GameFontNormal")
            btn.text:SetAllPoints(btn)
            btn.text:SetJustifyH("LEFT")
        end

        btn.questID = qID
        btn:SetHeight(btnHeight)
        btn:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, -(index - 1) * btnHeight)
        btn:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -(index - 1) * btnHeight)

        btn.text:SetText(gold .. (data.title or ("Quest " .. tostring(qID))) .. reset)

        btn:SetScript("OnClick", function(self)
            ShowQuestDetails(self.questID)
        end)

        btn:Show()
    end

    -- Скрываем неиспользуемые кнопки (могли остаться от предыдущего построения)
    for i = #questIDs + 1, #leftContent.buttons do
        leftContent.buttons[i]:Hide()
    end

    -- Обновляем высоту контента для скролла
    leftContent:SetHeight(#questIDs * btnHeight)
    leftScrollFrame:SetVerticalScroll(0)
end

------------------------------------------------------------
-- Создание интерфейса -------------------------------------
------------------------------------------------------------
local function TryCreateQuestListUI()
    if uiCreated or not QuestLogFrame then return end

    --------------------------------------------------------
    -- Кнопка вызова окна ----------------------------------
    --------------------------------------------------------
    local showBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    showBtn:SetSize(80, 22)
    showBtn:SetText("История")
    showBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -150, -30)

    --------------------------------------------------------
    -- Основной оверлей ------------------------------------
    --------------------------------------------------------
    overlay = CreateFrame("Frame", "MQSH_ListOverlay", QuestLogFrame)
    overlay:SetAllPoints(QuestLogFrame)
    SetBackdrop(overlay, {0.05, 0.05, 0.05, 0.95}, {1, 1, 1, 1})
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)

    -- Кнопка закрытия
    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -5, -5)

    --------------------------------------------------------
    -- Левый блок ------------------------------------------
    --------------------------------------------------------
    local leftWindow = CreateFrame("Frame", nil, overlay)
    leftWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -40)
    leftWindow:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 10, 10)
    leftWindow:SetWidth((QuestLogFrame:GetWidth() - 30) / 2)
    SetBackdrop(leftWindow, {0.1, 0.1, 0.1, 0.95}, {1, 1, 1, 1})

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

    --------------------------------------------------------
    -- Правый блок -----------------------------------------
    --------------------------------------------------------
    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -10, -40)
    rightWindow:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -10, 10)
    rightWindow:SetWidth((QuestLogFrame:GetWidth() - 30) / 2)
    SetBackdrop(rightWindow, {0.1, 0.1, 0.1, 0.95}, {1, 1, 1, 1})

    local rightTitle = CreateFS(rightWindow, "GameFontNormal")
    rightTitle:SetPoint("TOP", rightWindow, "TOP", 0, -5)
    rightTitle:SetJustifyH("CENTER")
    rightTitle:SetText("|cffFFD100Описание квеста|r")

    rightScrollFrame = CreateFrame("ScrollFrame", nil, rightWindow, "UIPanelScrollFrameTemplate")
    rightScrollFrame:SetPoint("TOPLEFT", rightWindow, "TOPLEFT", 10, -20)
    rightScrollFrame:SetPoint("BOTTOMRIGHT", rightWindow, "BOTTOMRIGHT", -30, 10)

    rightContent = CreateFrame("Frame", nil, rightScrollFrame)
    rightContent:SetSize(rightScrollFrame:GetWidth(), 1)
    rightScrollFrame:SetScrollChild(rightContent)

    detailsFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
    detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, 0)

    --------------------------------------------------------
    -- Поведение окна --------------------------------------
    --------------------------------------------------------
    showBtn:SetScript("OnClick", function()
        if overlay:IsShown() then
            overlay:Hide()
        else
            overlay:Show()
            BuildQuestList() -- Обновляем список при каждом открытии
        end
    end)

    overlay:SetScript("OnShow", BuildQuestList)

    uiCreated = true
end

------------------------------------------------------------
-- Инициализация после загрузки -----------------------------
------------------------------------------------------------
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