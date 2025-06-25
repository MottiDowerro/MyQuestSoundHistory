local addonName = ...

local DEBUG = true
local function dbg(msg)
    if DEBUG then
        print(string.format("[MQSH List] %s", tostring(msg)))
    end
end

local uiCreated = false

local BUTTON_OFFSET_X = -150
local BUTTON_OFFSET_Y = -30

local function TryCreateQuestListUI()
    if uiCreated then return end

    local showBtn = CreateFrame("Button", "MQSH_ShowListButton", QuestLogFrame, "UIPanelButtonTemplate")
    showBtn:SetSize(60, 20)
    showBtn:SetText("List")
    showBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", BUTTON_OFFSET_X, BUTTON_OFFSET_Y)

    local overlay = CreateFrame("Frame", "MQSH_ListOverlay", QuestLogFrame)
    overlay:SetAllPoints(QuestLogFrame)

    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    overlay:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    overlay:SetBackdropBorderColor(1, 1, 1, 1)
    overlay:SetFrameStrata("DIALOG")
    overlay:Hide()

    overlay:EnableMouse(true)
    overlay:SetScript("OnMouseDown", function() end)

    local closeBtn = CreateFrame("Button", nil, overlay, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        overlay:Hide()
    end)

    local leftWindow = CreateFrame("Frame", nil, overlay)
    leftWindow:SetSize(overlay:GetWidth() / 2 - 10, overlay:GetHeight() - 90)
    leftWindow:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -40)
    leftWindow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    leftWindow:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    leftWindow:SetBackdropBorderColor(1, 1, 1, 1)

    local leftTitle = leftWindow:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    leftTitle:SetJustifyH("CENTER")
    leftTitle:SetPoint("TOP", leftWindow, "TOP", 0, -5)
    leftTitle:SetText("Active Quests")

    local leftScrollFrame = CreateFrame("ScrollFrame", nil, leftWindow, "UIPanelScrollFrameTemplate")
    leftScrollFrame:SetPoint("TOPLEFT", leftWindow, "TOPLEFT", 10, -20)
    leftScrollFrame:SetPoint("BOTTOMRIGHT", leftWindow, "BOTTOMRIGHT", -30, 10)

    local leftContent = CreateFrame("Frame", nil, leftScrollFrame)
    leftContent:SetSize(leftScrollFrame:GetWidth(), 1000)
    leftScrollFrame:SetScrollChild(leftContent)

    local rightWindow = CreateFrame("Frame", nil, overlay)
    rightWindow:SetSize(overlay:GetWidth() / 2 - 10, overlay:GetHeight() - 90)
    rightWindow:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -10, -40)
    rightWindow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    rightWindow:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    rightWindow:SetBackdropBorderColor(1, 1, 1, 1)

    local rightTitle = rightWindow:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rightTitle:SetJustifyH("CENTER")
    rightTitle:SetPoint("TOP", rightWindow, "TOP", 0, -5)
    rightTitle:SetText("Completed Quests")

    for i = 1, 100 do
        local lineLeft = leftContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        lineLeft:SetJustifyH("LEFT")
        lineLeft:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, -14 * (i - 1))
        lineLeft:SetText("Quest " .. tostring(i))
    end

    showBtn:SetScript("OnClick", function()
        if overlay:IsShown() then
            overlay:Hide()
        else
            overlay:Show()
        end
    end)

    uiCreated = true
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, arg1)
    dbg(string.format("Событие %s (arg=%s)", event, tostring(arg1)))
    if event == "PLAYER_LOGIN" then
        TryCreateQuestListUI()
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_QuestLog" then
        TryCreateQuestListUI()
    end
end)

_G.QuestListOverlay_TryInit = TryCreateQuestListUI