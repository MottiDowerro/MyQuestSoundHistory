local addonName = "QuestSoundAnouncer"

if not QuestSoundAnouncerDB then
    QuestSoundAnouncerDB = {
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
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
    checkbox.text:SetFontObject("GameFontHighlight")
    checkbox.text:SetText(text)
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox:SetChecked(QuestSoundAnouncerDB[configKey])
    checkbox:SetScript("OnClick", function(self)
        QuestSoundAnouncerDB[configKey] = self:GetChecked()
    end)
    return checkbox
end

local function CreateDropdown(parent, configKey, anchorFrame, xOffset, yOffset)
    local dropdown = CreateFrame("Frame", addonName..configKey.."DropDown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", xOffset, yOffset)
    UIDropDownMenu_SetWidth(dropdown, 350)
    
    local dropdownText = _G[dropdown:GetName().."Text"]
    dropdownText:ClearAllPoints()
    dropdownText:SetPoint("LEFT", dropdown, "LEFT", 25, 3)
    dropdownText:SetPoint("RIGHT", dropdown, "RIGHT", -30, 3)
    dropdownText:SetJustifyH("LEFT")
    dropdownText:SetFontObject("GameFontHighlightSmall")

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local selectedValue = QuestSoundAnouncerDB[configKey]
        
        for _, sound in ipairs(SOUND_LIST) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = sound.value
            info.value = sound.value
            info.func = function(self)
                QuestSoundAnouncerDB[configKey] = self.value
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, self.value)
                CloseDropDownMenus()
            end
            info.checked = (sound.value == selectedValue)
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(dropdown, QuestSoundAnouncerDB[configKey] or "")
    UIDropDownMenu_SetSelectedValue(dropdown, QuestSoundAnouncerDB[configKey])

    return dropdown
end

local function CreatePlayButton(parent, anchorFrame, configKey)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)
    button:SetPoint("LEFT", anchorFrame, "RIGHT", 125, -2)
    button:SetNormalTexture("Interface\\Common\\VoiceChat-Speaker")
    
    button:SetScript("OnClick", function()
        PlaySoundFile(QuestSoundAnouncerDB[configKey], "Master")
    end)
    
    return button
end

function CreateSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = addonName
    panel:SetSize(700, 400)
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText(addonName)

    local contentFrame = CreateFrame("Frame", nil, panel)
    contentFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
    contentFrame:SetSize(650, 350)

    local workCheck = CreateCheckbox(contentFrame, "Полное завершение", "enableWorkComplete", -20)
    local playWork = CreatePlayButton(contentFrame, workCheck, "workCompleteSound")
    CreateDropdown(contentFrame, "workCompleteSound", playWork, -15, 3)

    local singleCheck = CreateCheckbox(contentFrame, "Этап задания", "enableSingleComplete", -70)
    local playSingle = CreatePlayButton(contentFrame, singleCheck, "singleCompleteSound")
    CreateDropdown(contentFrame, "singleCompleteSound", playSingle, -15, 3)

    local progressCheck = CreateCheckbox(contentFrame, "Прогресс задания", "enableProgressSound", -120)
    local playProgress = CreatePlayButton(contentFrame, progressCheck, "progressSound")
    CreateDropdown(contentFrame, "progressSound", playProgress, -15, 3)

    InterfaceOptions_AddCategory(panel)
end