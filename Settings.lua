local addonName = "MyQuestSoundHistory"

if not MQSH_Config then
    MQSH_Config = {
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

local function CreateCheckbox(parent, text, configKey, point, relativeTo, relativePoint, xOffset, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    checkbox.text:SetFontObject("GameFontHighlight")
    checkbox.text:SetText(text)
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox:SetChecked(MQSH_Config[configKey])
    checkbox:SetScript("OnClick", function(self)
        MQSH_Config[configKey] = self:GetChecked()
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
        local selectedValue = MQSH_Config[configKey]
        
        for _, sound in ipairs(SOUND_LIST) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sound.value
            info.value = sound.value
            info.func = function(self)
                MQSH_Config[configKey] = self.value
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self.value)
                CloseDropDownMenus()
            end
            info.checked = (sound.value == selectedValue)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(dropdown, MQSH_Config[configKey] or "")
    UIDropDownMenu_SetSelectedValue(dropdown, MQSH_Config[configKey])

    return dropdown
end

local function CreatePlayButton(parent, anchorFrame, configKey, point, relativeTo, relativePoint, xOffset, yOffset)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    button:SetNormalTexture("Interface\\Common\\VoiceChat-Speaker")
    
    button:SetHighlightTexture("Interface\\Common\\VoiceChat-Speaker")
    local highlight = button:GetHighlightTexture()
    highlight:SetVertexColor(1, 1, 1, 0.4)
    
    button:SetPushedTexture("Interface\\Common\\VoiceChat-Speaker")
    local pushed = button:GetPushedTexture()
    pushed:SetVertexColor(1, 1, 1, 0.8)
    
    button:SetScript("OnClick", function()
        PlaySoundFile(MQSH_Config[configKey])
    end)
    return button
end

-- Главная панель
local function CreateMainSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "MyQuestSoundHistory"
    panel:SetSize(700, 200)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("MyQuestSoundHistory")

    local soundAnouncerCheck = CreateCheckbox(panel, "Модуль звукового анонсера квестов", "enableSoundAnouncer", "TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    local historyCheck = CreateCheckbox(panel, "Модуль истории квестов", "enableHistory", "TOPLEFT", soundAnouncerCheck, "BOTTOMLEFT", 0, -10)

    InterfaceOptions_AddCategory(panel)
end

-- Панель History (заглушка)
local function CreateHistorySettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "History"
    panel.parent = "MyQuestSoundHistory"
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
    panel.parent = "MyQuestSoundHistory"
    panel:SetSize(700, 400)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Sound Anouncer Settings")

    local workCheck = CreateCheckbox(panel, "Звук завершения квеста", "enableWorkComplete", "TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    local workDropdown = CreateDropdown(panel, "workCompleteSound", workCheck, "Завершения квеста", -15, -3, "TOPLEFT", "BOTTOMLEFT")
    local playWork = CreatePlayButton(panel, workDropdown, "workCompleteSound", "LEFT", workDropdown, "RIGHT", -4, 2)

    local singleCheck = CreateCheckbox(panel, "Звук завершения этапа", "enableSingleComplete", "TOPLEFT", workCheck, "BOTTOMLEFT", 0, -45)
    local singleDropdown = CreateDropdown(panel, "singleCompleteSound", singleCheck, "Завершения этапа", -15, -3, "TOPLEFT", "BOTTOMLEFT")
    local playSingle = CreatePlayButton(panel, singleDropdown, "singleCompleteSound", "LEFT", singleDropdown, "RIGHT", -4, 2)

    local progressCheck = CreateCheckbox(panel, "Звук прогресса квеста", "enableProgressSound", "TOPLEFT", singleCheck, "BOTTOMLEFT", 0, -45)
    local progressDropdown = CreateDropdown(panel, "progressSound", progressCheck, "Прогресс квеста", -15, -3, "TOPLEFT", "BOTTOMLEFT")
    local playProgress = CreatePlayButton(panel, progressDropdown, "progressSound", "LEFT", progressDropdown, "RIGHT", -4, 2)

    InterfaceOptions_AddCategory(panel)
end

function CreateSettingsPanel()
    CreateMainSettingsPanel()
    CreateHistorySettingsPanel()
    CreateSoundAnouncerSettingsPanel()
end