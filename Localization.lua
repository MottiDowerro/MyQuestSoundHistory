local locale = GetLocale()
local lang = locale == "ruRU" and "ru" or "en"
local ok, L = pcall(function() return dofile("locales/"..lang..".lua") end)
if not ok or not L then
    L = dofile("locales/en.lua")
end
function L_(key)
    return L[key] or key
end
_G.L = L_ 