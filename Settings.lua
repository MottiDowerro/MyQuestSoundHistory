local addonName = "MyQuestSoundHistory"

if not MyQuestSoundHistoryDB then
    MyQuestSoundHistoryDB = {
        enableSoundAnouncer = true,
        enableHistory = true,
        enableWorkComplete = true,
        enableSingleComplete = true,
        enableProgressSound = true,
        workCompleteSound = "Sound\\Creature\\MillhouseManastorm\\TEMPEST_Millhouse_Slay01.wav",
        singleCompleteSound = "Sound\\Creature\\Peon\\PeonBuildingComplete1.wav",
        progressSound = "Sound\\Interface\\igPlayerBind.wav"
    }
end

local SOUND_LIST = {
    {value = "Sound\\Doodad\\BellTollAlliance.wav"},
    {value = "Sound\\Interface\\AuctionWindowOpen.wav"},
    {value = "Sound\\Interface\\LevelUp.wav"},
    {value = "Sound\\Creature\\Peon\\PeonBuildingComplete1.wav"},
    {value = "Sound\\Creature\\Illidan\\BLACK_Illidan_14.wav"},
    {value = "Sound\\Creature\\Murloc\\mMurlocAggroOld.wav"},
    {value = "Sound\\Spells\\SimonGame_Visual_GameStart.wav"},
    {value = "Sound\\Interface\\AlarmClockWarning3.wav"}, 
    {value = "Sound\\Creature\\Peon\\PeonWhat3.wav"},
    {value = "Sound\\Spells\\PVPEnterQueue.wav"},
    {value = "Sound\\Creature\\Peon\\PeonReady1.wav"},
    {value = "Sound\\Creature\\Peasant\\PeasantReady1.wav"},
    {value = "Sound\\Interface\\igPlayerBind.wav"},
    {value = "Sound\\Creature\\MillhouseManastorm\\TEMPEST_Millhouse_Ready01.wav"},
    {value = "Sound\\Creature\\MillhouseManastorm\\TEMPEST_Millhouse_Slay01.wav"},
    {value = "Sound\\Creature\\Cow\\CowDeath.wav"},
    {value = "Sound\\interface\\HumanExploration.wav"},
    {value = "Sound\\Creature\\Peasant\\PeasantWhat3.wav"},
    {value = "Sound\\Creature\\Peon\\PeonYes3.wav"},
    {value = "Sound\\Creature\\Peon\\PeonWhat4.wav"}
}

local function CreateCheckbox(parent, text, configKey, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox.text:SetFontObject("GameFontHighlight")
    checkbox.text:SetText(text)
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox:SetChecked(MyQuestSoundHistoryDB[configKey])
    checkbox:SetScript("OnClick", function(self)
        MyQuestSoundHistoryDB[configKey] = self:GetChecked()
    end)
    return checkbox
end

local function CreateDropdown(parent, configKey, anchorFrame, text, xOffset, yOffset, arg1, arg2)
    local dropdown = CreateFrame("Frame", addonName..configKey.."DropDown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint(arg1, anchorFrame, arg2, xOffset, yOffset)
    UIDropDownMenu_SetWidth(dropdown, 450)
    
    local dropdownText = _G[dropdown:GetName().."Text"]
    dropdownText:ClearAllPoints()
    dropdownText:SetPoint("LEFT", dropdown, "LEFT", 25, 3)
    dropdownText:SetPoint("RIGHT", dropdown, "RIGHT", -30, 3)
    dropdownText:SetJustifyH("LEFT")
    dropdownText:SetFontObject("GameFontHighlightSmall")

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local selectedValue = MyQuestSoundHistoryDB[configKey]
        
        for _, sound in ipairs(SOUND_LIST) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sound.value
            info.value = sound.value
            info.func = function(self)
                MyQuestSoundHistoryDB[configKey] = self.value
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self.value)
                CloseDropDownMenus()
            end
            info.checked = (sound.value == selectedValue)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(dropdown, MyQuestSoundHistoryDB[configKey] or "")
    UIDropDownMenu_SetSelectedValue(dropdown, MyQuestSoundHistoryDB[configKey])

    return dropdown
end

local function CreatePlayButton(parent, anchorFrame, configKey)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:SetNormalTexture("Interface\\Common\\VoiceChat-Speaker")
    button:SetScript("OnClick", function()
        PlaySoundFile(MyQuestSoundHistoryDB[configKey])
    end)
    
    return button
end

-- Главная панель
local function CreateMainSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = L_("ADDON_TITLE")
    panel:SetSize(700, 200)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText(L_("ADDON_TITLE"))

    local soundAnouncerCheck = CreateCheckbox(panel, L_("ENABLE_SOUND_ANOUNCER"), "enableSoundAnouncer", -50)
    local historyCheck = CreateCheckbox(panel, L_("ENABLE_HISTORY"), "enableHistory", -70)

    InterfaceOptions_AddCategory(panel)
end

-- Панель History (заглушка)
local function CreateHistorySettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "History"
    panel.parent = L_("ADDON_TITLE")
    panel:SetSize(700, 200)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("History Settings")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    desc:SetText("Здесь будут настройки истории квестов.")

    InterfaceOptions_AddCategory(panel)
end

-- Панель Sound Anouncer
local function CreateSoundAnouncerSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Sound Anouncer"
    panel.parent = L_("ADDON_TITLE")
    panel:SetSize(700, 400)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Sound Anouncer Settings")

    local contentFrame = CreateFrame("Frame", nil, panel)
    contentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
    contentFrame:SetSize(650, 350)

    -- WORK COMPLETE
    local workCheck = CreateCheckbox(contentFrame, L_("ENABLE_WORK_COMPLETE"), "enableWorkComplete", 10)
    local workDropdown = CreateDropdown(contentFrame, "workCompleteSound", workCheck, L_("WORK_COMPLETE_SOUND"), -15, -3, "TOPLEFT", "BOTTOMLEFT")
    local playWork = CreatePlayButton(contentFrame, workDropdown, "workCompleteSound")
    playWork:SetPoint("LEFT", workDropdown, "RIGHT", -4, 2)

    -- SINGLE COMPLETE
    local singleCheck = CreateCheckbox(contentFrame, L_("ENABLE_SINGLE_COMPLETE"), "enableSingleComplete", -50)
    local singleDropdown = CreateDropdown(contentFrame, "singleCompleteSound", singleCheck, L_("SINGLE_COMPLETE_SOUND"), -15, -3, "TOPLEFT", "BOTTOMLEFT")
    local playSingle = CreatePlayButton(contentFrame, singleDropdown, "singleCompleteSound")
    playSingle:SetPoint("LEFT", singleDropdown, "RIGHT", -4, 2)

    -- PROGRESS SOUND
    local progressCheck = CreateCheckbox(contentFrame, L_("ENABLE_PROGRESS_SOUND"), "enableProgressSound", -110)
    local progressDropdown = CreateDropdown(contentFrame, "progressSound", progressCheck, L_("PROGRESS_SOUND"), -15, -3, "TOPLEFT", "BOTTOMLEFT")
    local playProgress = CreatePlayButton(contentFrame, progressDropdown, "progressSound")
    playProgress:ClearAllPoints()
    playProgress:SetPoint("LEFT", progressDropdown, "RIGHT", -4, 2)

    InterfaceOptions_AddCategory(panel)
end

function CreateSettingsPanel()
    CreateMainSettingsPanel()
    CreateHistorySettingsPanel()
    CreateSoundAnouncerSettingsPanel()
end