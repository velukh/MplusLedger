MplusLedgerColorText = LibStub:NewLibrary("MplusLedgerColorText-1.0", 1)

function MplusLedgerColorText:Red(text)
  return "|cFFFF0000" .. text .. "|r"
end

function MplusLedgerColorText:Yellow(text)
  return "|cFFFFFF00" .. text .. "|r"
end

function MplusLedgerColorText:Green(text)
  return "|cFF00FF00" .. text .. "|r"
end

function MplusLedgerColorText:FromItemQuality(text, itemQuality)
  local r, g, b = GetItemQualityColor(itemQuality)
  local rgbObject = {
    r = r,
    g = g,
    b = b
  }
  return self:FromRGB(text, rgbObject)
end

function MplusLedgerColorText:FromRGB(text, rgbObject)
  return string.format("|cff%02x%02x%02x%s|r", rgbObject.r * 255, rgbObject.g * 255, rgbObject.b * 255, text)
end
