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
function ScrollBarUtils.UpdateAllScrollBars(scrollPairs)
    for _, pair in ipairs(scrollPairs) do
        ScrollBarUtils.UpdateScrollBar(pair.scrollFrame, pair.scrollbar)
    end
end

--- Сбрасывает позицию скроллбаров
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
function ScrollBarUtils.RemoveFontOutline(fs)
    if not fs or type(fs) ~= "table" or not fs.GetFont then
        return -- Если объект не является FontString, просто выходим
    end
    local fontFile, fontSize = fs:GetFont()
    if fontFile then
        fs:SetFont(fontFile, fontSize, "")
    end
end

function ScrollBarUtils.AddFontOutline(fs)
    if not fs or type(fs) ~= "table" or not fs.GetFont then
        return -- Если объект не является FontString, просто выходим
    end
    local fontFile, fontSize = fs:GetFont()
    if fontFile then
        fs:SetFont(fontFile, fontSize, "OUTLINE")
    end
end

_G.ScrollBarUtils = ScrollBarUtils 