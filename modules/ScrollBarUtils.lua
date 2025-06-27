-- ============================================================================
-- ScrollBarUtils.lua
-- Утилиты для работы со скроллбарами и общие функции
-- ============================================================================

local ScrollBarUtils = {}

-- Константы
ScrollBarUtils.SCROLLBAR_WIDTH = 16               -- Ширина скроллбара

-- ============================================================================
-- Функции для работы со скроллбарами
-- ============================================================================

--- Обновляет скроллбар на основе содержимого ScrollFrame
--- @param scrollFrame Frame - ScrollFrame для обновления
--- @param scrollbar Slider - Скроллбар для обновления
function ScrollBarUtils.UpdateScrollBar(scrollFrame, scrollbar)
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

--- Обновляет все скроллбары в списке
--- @param scrollPairs table - Таблица пар {scrollFrame, scrollbar}
function ScrollBarUtils.UpdateAllScrollBars(scrollPairs)
    for _, pair in ipairs(scrollPairs) do
        ScrollBarUtils.UpdateScrollBar(pair.scrollFrame, pair.scrollbar)
    end
end

--- Сбрасывает позицию скроллбаров
--- @param scrollPairs table - Таблица пар {scrollFrame, scrollbar}
function ScrollBarUtils.ResetScrollBars(scrollPairs)
    for _, pair in ipairs(scrollPairs) do
        if pair.scrollFrame then 
            pair.scrollFrame:SetVerticalScroll(0) 
        end
        if pair.scrollbar then 
            pair.scrollbar:SetValue(0) 
        end
    end
end

--- Создает скроллбар для ScrollFrame
--- @param parent Frame - Родительский фрейм
--- @param scrollFrame Frame - ScrollFrame
--- @param anchorFrame Frame - Фрейм для привязки
--- @param spacing number - Расстояние от anchorFrame
--- @param width number - Ширина скроллбара
--- @param scrollStep number - Шаг прокрутки для колесика мыши
--- @return Slider scrollbar - Созданный скроллбар
function ScrollBarUtils.CreateScrollBar(parent, scrollFrame, anchorFrame, spacing, width, scrollStep)
    local scrollbar = CreateFrame("Slider", nil, parent, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", spacing, -14)
    scrollbar:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", spacing, 14)
    scrollbar:SetWidth(width or ScrollBarUtils.SCROLLBAR_WIDTH)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetMinMaxValues(0, 0)
    
    -- Обработчик изменения значения
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    -- Обработчик колесика мыши
    if anchorFrame then
        anchorFrame:EnableMouseWheel(true)
        anchorFrame:SetScript("OnMouseWheel", function(self, delta)
            local currentValue = scrollbar:GetValue()
            local step = scrollStep or 20
            local newValue = currentValue - (delta * step)
            scrollbar:SetValue(newValue)
        end)
    end
    
    return scrollbar
end

--- Создает ScrollFrame с контентом
--- @param parent Frame - Родительский фрейм
--- @param paddingX number - Отступ по X
--- @param paddingY number - Отступ по Y
--- @return Frame scrollFrame - Созданный ScrollFrame
--- @return Frame content - Созданный контентный фрейм
function ScrollBarUtils.CreateScrollFrame(parent, paddingX, paddingY)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", paddingX, -paddingY)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -paddingX, paddingY)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)
    
    return scrollFrame, content
end

-- ============================================================================
-- Общие утилиты
-- ============================================================================

--- Устанавливает фон для фрейма
--- @param frame Frame - Фрейм для установки фона
--- @param color table - Цвет фона {r, g, b, a}
--- @param borderColor table - Цвет границы {r, g, b, a}
function ScrollBarUtils.SetBackdrop(frame, color, borderColor)
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

--- Создает FontString
--- @param parent Frame - Родительский фрейм
--- @param template string - Шаблон шрифта
--- @param width number - Ширина текста (опционально)
--- @return FontString fs - Созданный FontString
function ScrollBarUtils.CreateFS(parent, template, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    if width then
        fs:SetWidth(width)
        fs:SetWordWrap(true)
    end
    return fs
end

--- Убирает контур шрифта
--- @param fs FontString - FontString для изменения
function ScrollBarUtils.RemoveFontOutline(fs)
    local fontFile, fontSize = fs:GetFont()
    if fontFile then
        fs:SetFont(fontFile, fontSize, "")
    end
end

-- ============================================================================
-- Экспорт
-- ============================================================================

_G.ScrollBarUtils = ScrollBarUtils 