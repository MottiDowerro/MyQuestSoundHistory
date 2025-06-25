local addonName = ...

local uiCreated = false

local overlay
local leftScrollFrame, leftContent
local rightScrollFrame, rightContent, detailsFS, detailsTitle
local selectedButton -- currently highlighted quest button
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

local function ShowQuestDetails(questID)
    if not MQSH_QuestDB or not MQSH_QuestDB[questID] then return end

    local q = MQSH_QuestDB[questID]

    local gold  = "|cffFFD100"
    local white = "|cffffffff"
    local grey  = "|cffAAAAAA"
    local reset = "|r"

    if detailsTitle then
        detailsTitle:SetText(gold .. q.title .. reset)
        detailsFS:ClearAllPoints()
        detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, -detailsTitle:GetStringHeight() - 5)
    end

    -- Summary целей (objectivesText)
    if not objectivesSummaryFS then
        objectivesSummaryFS = CreateFS(rightContent, "GameFontHighlight", rightScrollFrame:GetWidth())
        objectivesSummaryFS:SetJustifyH("LEFT")
    end
    if q.objectivesText and q.objectivesText ~= "" then
        objectivesSummaryFS:SetText(white .. q.objectivesText .. reset)
    else
        objectivesSummaryFS:SetText("")
    end

    local descText = ""
    if q.description and q.description ~= "" then
        descText = white .. q.description:gsub("\n+$", "") .. reset
    end

    -- Создаём/обновляем блок описания
    if detailsFS then
        detailsFS:SetText(descText)
    end

    -- Цели (без заголовка)
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

    -- Заголовок «Описание»
    if not descHeadingFS then
        descHeadingFS = CreateFS(rightContent, "GameFontNormalHuge")
        RemoveFontOutline(descHeadingFS)
        descHeadingFS:SetJustifyH("LEFT")
    end
    descHeadingFS:SetText(gold .. "Описание:" .. reset)

    if q.rewards then
        local hasRewards = (#q.rewards.items > 0) or (#q.rewards.choices > 0) or (q.rewards.money and q.rewards.money > 0) or (q.rewards.xp and q.rewards.xp > 0)
        if hasRewards then
            -- Динамический заголовок «Награды» крупным шрифтом
            if not rewardsHeadingFS then
                rewardsHeadingFS = CreateFS(rightContent, "GameFontNormalHuge")
                RemoveFontOutline(rewardsHeadingFS)
            end

            -- Вспомогательная функция для форматирования предмета с иконкой
            local function FormatRewardItem(item)
                if type(item) == "table" then
                    local texture = item.texture or "Interface\\Icons\\INV_Misc_QuestionMark"
                    local link    = item.link or item.name or ""

                    -- Максимальная видимая длина названия
                    local MAX_LEN = 35

                    -- Функция обрезки названия внутри ссылки, чтобы не ломать цвет/линк
                    local function TruncateItemLink(l)
                        if type(l) ~= "string" then return l end

                        return l:gsub("%[(.-)%]", function(name)
                            if strlenutf8(name) > MAX_LEN then
                                local trimmed = strsub(name, 1, MAX_LEN - 3) .. "..."
                                return "[" .. trimmed .. "]"
                            else
                                return "[" .. name .. "]"
                            end
                        end, 1) -- только первое совпадение
                    end

                    link = TruncateItemLink(link)

                    local ICON_SIZE = 40
                    -- Координаты усечения: обрезаем ~5 пикселей по краям (64px база)
                    return string.format("|T%s:%d:%d:0:0:64:64:5:59:5:59|t %s", texture, ICON_SIZE, ICON_SIZE, link)
                else
                    return tostring(item)
                end
            end

            -- Собираем список предметов (choices + items)
            local rewardItems = {}
            if #q.rewards.choices > 0 then
                for _, item in ipairs(q.rewards.choices) do
                    table.insert(rewardItems, item)
                end
            end
            for _, item in ipairs(q.rewards.items) do
                table.insert(rewardItems, item)
            end

            rewardsHeadingFS:SetText(gold .. "Награды:" .. reset)

            -- Создаём/обновляем фреймы для каждого предмета
            local function TruncateItemText(text, maxLen)
                if strlenutf8(text) <= maxLen then return text end
                return strsub(text, 1, maxLen - 3) .. "..."
            end

            local ICON_SIZE = 40
            local ITEM_HEIGHT = ICON_SIZE + 4

            local frameWidth = rightScrollFrame:GetWidth()

            for i, item in ipairs(rewardItems) do
                local row = rewardItemFrames[i]
                if not row then
                    row = CreateFrame("Frame", nil, rightContent)
                    SetBackdrop(row, {0,0,0,0.2}, {1,1,1,1})
                    row:EnableMouse(true)
                    rewardItemFrames[i] = row

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
                end
                row:SetWidth(frameWidth)
                row:SetHeight(ITEM_HEIGHT)

                -- Set content
                local texture = item.texture or "Interface\\Icons\\INV_Misc_QuestionMark"
                row.icon:SetTexture(texture)

                local linkTxt = item.link or item.name or ""
                row.text:SetWidth(frameWidth - (ICON_SIZE+10))
                row.text:SetText(TruncateItemText(linkTxt, 40))
                if not row.text.SetMaxLines then
                    row.text:SetHeight(ITEM_HEIGHT - 5)
                end

                row.iconBorder:SetPoint("LEFT", row, "LEFT", 0, 0)
                row.text:SetPoint("LEFT", row.iconBorder, "RIGHT", 4, 0)
                row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)

                if item.link and item.link:find("|Hitem:") then
                    row.itemLink = item.link
                else
                    local id = item.itemID
                    if not id and item.name then
                        id = select(1, GetItemInfoInstant(item.name))
                    end
                    if id and id ~= 0 then
                        row.itemLink = "item:" .. id
                    else
                        row.itemLink = nil
                    end
                end

                row.itemID = item.itemID
                row.itemName = item.name

                row:SetScript("OnEnter", function(self)
                    if not self.highlight then
                        self.highlight = self:CreateTexture(nil, "BACKGROUND")
                        self.highlight:SetAllPoints(self)
                        self.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
                        self.highlight:SetAlpha(0.4)
                        self.highlight:SetBlendMode("ADD")
                    end
                    self.highlight:Show()
    
                    -- существующий код для отображения тултипа
                    if self.itemLink then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(self.itemLink)
                        GameTooltip:Show()
                    elseif self.itemID then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        if GameTooltip.SetItemByID then
                            GameTooltip:SetItemByID(self.itemID)
                        else
                            GameTooltip:SetHyperlink("item:" .. self.itemID)
                        end
                        GameTooltip:Show()
                    elseif self.itemName then
                        local _, link = GetItemInfo(self.itemName)
                        if link then
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(link)
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

                row:Show()
            end

            -- Hide unused frames
            for i = #rewardItems + 1, #rewardItemFrames do
                rewardItemFrames[i]:Hide()
            end

            -- Сохраняем количество видимых наград для раскладки
            rewardsVisibleCount = #rewardItems

            -- Дополнительные награды (деньги/опыт)
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

            rewardExtraFS:SetSpacing(4) -- небольшой отступ между строками
            rewardExtraFS:SetText(table.concat(extraLines, "\n"))

        elseif rewardsHeadingFS then
            rewardsHeadingFS:SetText("")
            -- Скрываем все ранее созданные фреймы
            for _, f in ipairs(rewardItemFrames) do f:Hide() end
        end
    end

    -- Теперь перестраиваем расположение блоков в rightContent
    local yOffset = -detailsTitle:GetStringHeight() - 5

    -- Summary целей
    if objectivesSummaryFS and objectivesSummaryFS:GetText() ~= "" then
        objectivesSummaryFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - objectivesSummaryFS:GetStringHeight() - 6
    end

    -- Подробные цели (список)
    if objectivesTextFS and objectivesTextFS:GetText() ~= "" then
        objectivesTextFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - objectivesTextFS:GetStringHeight()
    end

    -- Заголовок «Описание»
    if descHeadingFS and descHeadingFS:GetText() ~= "" then
        descHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - descHeadingFS:GetStringHeight() - 10
    end

    -- Текст описания
    if detailsFS and detailsFS:GetText() ~= "" then
        detailsFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - detailsFS:GetStringHeight() - 10
    end

    if rewardsHeadingFS and rewardsHeadingFS:GetText() ~= "" then
        rewardsHeadingFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
        yOffset = yOffset - rewardsHeadingFS:GetStringHeight() - 2

        -- подпись выбора
        if choiceLabelFS and choiceLabelFS:GetText() ~= "" then
            choiceLabelFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
            yOffset = yOffset - choiceLabelFS:GetStringHeight() - 4
        end

        -- раскладка в две колонки
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
        -- смещаем yOffset на количество строк
        local rows = math.ceil(rewardsVisibleCount / 2)
        if rows > 0 then
            yOffset = yOffset - rows * (rewardItemFrames[1]:GetHeight() + rowSpacing)
        end

        if rewardExtraFS and rewardExtraFS:GetText() ~= "" then
            rewardExtraFS:SetPoint("TOPLEFT", rightContent, "TOPLEFT", 0, yOffset)
            yOffset = yOffset - rewardExtraFS:GetStringHeight() - 4
        end
    end

    local totalHeight = -yOffset + 10
    rightContent:SetHeight(totalHeight)
    rightScrollFrame:SetVerticalScroll(0)
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

    local btnHeight = 20
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
            btn.text:SetTextColor(1, 1, 1)

            -- Сдвиг текста вправо и вниз
            local xOffset = 7  -- Отступ вправо (в пикселях)
            local yOffset = 0 -- Отступ вниз (в пикселях)
            btn.text:SetPoint("TOPLEFT", btn, "TOPLEFT", xOffset, yOffset)
            btn.text:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -xOffset, yOffset)

            -- Выделение фона при выборе
            btn.selTexture = btn:CreateTexture(nil, "BACKGROUND")
            btn.selTexture:SetAllPoints(btn)
            btn.selTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            btn.selTexture:SetBlendMode("ADD")
            btn.selTexture:Hide()
        end

        btn.questID = qID
        btn:SetHeight(btnHeight)
        btn:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, -(index - 1) * btnHeight)
        btn:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, -(index - 1) * btnHeight)

        -- Установка текста кнопки
        btn.text:SetText((data.title or ("Quest " .. tostring(qID))) .. reset)

        -- Обработчик клика
        btn:SetScript("OnClick", function(self)
            HighlightQuestButton(self)
            ShowQuestDetails(self.questID)
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
    overlay:SetAllPoints(QuestLogFrame)
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
    SetBackdrop(leftWindow, {0.08, 0.08, 0.08, 0.90}, {0, 0, 0, 0.95})

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
    SetBackdrop(rightWindow, {0.08, 0.08, 0.08, 0.90}, {0, 0, 0, 0.95})

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
            BuildQuestList()
        end
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