local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
local MplusLedger = MplusLedger
local UiUtils = MplusLedgerUiUtils

local ldbPlugin = ldb:NewDataObject("MplusLedger", {
  type = "data source",
  text = "0",
  icon = "Interface\\Addons\\MplusLedger\\Media\\mplusledger_logo"
})

function ldbPlugin.OnClick(self) 
  MplusLedger:ToggleFrame()
end

function ldbPlugin.OnTooltipShow(tooltip)
  tooltip:AddLine("M+ Ledger")
  tooltip:AddLine(" ")
  local keystones = MplusLedger:GetCurrentKeystones()
  for character, stoneInfo in pairs(keystones) do
    tooltip:AddLine(UiUtils:ClassColoredName(character, stoneInfo.classToken))
    if not stoneInfo.keystone then
      tooltip:AddLine(UiUtils:Indent("No keystone"))
    else
      local mythicName = stoneInfo.keystone.name
      local mythicLevel = stoneInfo.keystone.mythicLevel
      local affixes = stoneInfo.keystone.affixes
      local affixString

      for _, affixName in pairs(affixes) do
        if not affixString then
          affixString = affixName
        else
          affixString = affixString .. ", " .. affixName
        end
      end
      
      local labelText = "+" .. mythicLevel .. " " .. mythicName
      if affixString then
        labelText = labelText .. " (" .. affixString .. ")"
      end
      tooltip:AddLine(UiUtils:Indent(labelText))
    end
  end
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
  local icon = LibStub("LibDBIcon-1.0", true)
  if not MplusLedgerIconDB then MplusLedgerIconDB = {} end
  icon:Register("MplusLedger", ldbPlugin, MplusLedgerIconDB)
end)

f:RegisterEvent("PLAYER_LOGIN")