local locale = GetLocale()
L = L or {}

if locale == "ruRU" then
    L["ADDON_TITLE"] = "MyQuestSoundHistory"
    L["WORK_COMPLETE"] = "Квест полностью завершён"
    L["SINGLE_COMPLETE"] = "Этап квеста завершён"
    L["PROGRESS"] = "Прогресс квеста"
    L["ENABLE_SOUND_ANOUNCER"] = "Включить анонсер квестов"
    L["ENABLE_HISTORY"] = "Включить историю квестов"
    L["README_TITLE"] = "MyQuestSoundHistory для WoW (3.3.5a)"
    L["README_DESC"] = "Аддон, при помощи которого можно настроить воспроизведение звуков при квестинге :>"
    L["ENABLE_WORK_COMPLETE"] = "Включить звук завершения квеста"
    L["ENABLE_SINGLE_COMPLETE"] = "Включить звук завершения этапа"
    L["ENABLE_PROGRESS_SOUND"] = "Включить звук прогресса квеста"
    L["WORK_COMPLETE_SOUND"] = "Звук завершения квеста"
    L["SINGLE_COMPLETE_SOUND"] = "Звук завершения этапа"
    L["PROGRESS_SOUND"] = "Звук прогресса квеста"
    L["PLAY_SOUND"] = "Прослушать звук"
    L["SELECT_SOUND"] = "Выбрать звук"
else
    L["ADDON_TITLE"] = "MyQuestSoundHistory"
    L["WORK_COMPLETE"] = "Quest fully completed"
    L["SINGLE_COMPLETE"] = "Quest stage completed"
    L["PROGRESS"] = "Quest progress"
    L["ENABLE_SOUND_ANOUNCER"] = "Enable Sound Anouncer"
    L["ENABLE_HISTORY"] = "Enable Quest History"
    L["README_TITLE"] = "MyQuestSoundHistory for WoW (3.3.5a)"
    L["README_DESC"] = "Addon that lets you configure questing sound playback :>"
    L["ENABLE_WORK_COMPLETE"] = "Enable quest complete sound"
    L["ENABLE_SINGLE_COMPLETE"] = "Enable quest stage complete sound"
    L["ENABLE_PROGRESS_SOUND"] = "Enable quest progress sound"
    L["WORK_COMPLETE_SOUND"] = "Quest complete sound"
    L["SINGLE_COMPLETE_SOUND"] = "Quest stage complete sound"
    L["PROGRESS_SOUND"] = "Quest progress sound"
    L["PLAY_SOUND"] = "Play sound"
    L["SELECT_SOUND"] = "Select sound"
end

function L_(key)
    return L[key] or key
end 