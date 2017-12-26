local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
local MplusLedger = MplusLedger
local UiUtils = MplusLedgerUiUtils
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local ldbPlugin = ldb:NewDataObject("MplusLedger", {
  type = "data source",
  text = "0",
  icon = "Interface\\ICONS\\INV_Relics_Hourglass"
})

function ldbPlugin.OnClick(self, button) 
  if button == "RightButton" then
    AceConfigDialog:Open("M+ Ledger")
  else
    MplusLedger:ToggleFrame()
  end
end

local function GenerateKeystoneString(keystone)
  local mythicName = keystone.name
  local mythicLevel = keystone.mythicLevel
  local affixes = keystone.affixes
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
  return UiUtils:Indent(labelText)
end

function ldbPlugin.OnTooltipShow(tooltip)
  tooltip:AddLine("M+ Ledger")
  tooltip:AddLine(" ")
  local keystones = MplusLedger:GetCurrentKeystones()
  local yourKeystone = MplusLedger:GetSpecificCharacterKeystone()
  local characterName = UnitName("player")
  local showNoKeyCharacters = MplusLedger:GetConfig("display_no_key_characters")
  tooltip:AddLine(UiUtils:ClassColoredName(characterName, yourKeystone.classToken))
  if yourKeystone.keystone then
    tooltip:AddLine(GenerateKeystoneString(yourKeystone.keystone))
  else
    tooltip:AddLine(UiUtils:Indent("No keystone"))
  end

  local numOtherKeystones = 0
  for character, stoneInfo in pairs(keystones) do
    if characterName ~= character then
      if stoneInfo.keystone ~= nil then
        numOtherKeystones = numOtherKeystones + 1
      end
    end
  end

  if numOtherKeystones > 0 then
    tooltip:AddLine(" ")
    tooltip:AddLine("Other Characters:")
    tooltip:AddLine(" ")

    for character, stoneInfo in pairs(keystones) do
      if characterName ~= character then
        local shouldShowNoKeys = stoneInfo.keystone == nil and showNoKeyCharacters
        if stoneInfo.keystone or shouldShowNoKeys then
          tooltip:AddLine(UiUtils:ClassColoredName(character, stoneInfo.classToken))
          if not stoneInfo.keystone then
            tooltip:AddLine(UiUtils:Indent("No keystone"))
          else
            tooltip:AddLine(GenerateKeystoneString(stoneInfo.keystone))
          end
        end
      end
    end
  end

  local showPartyInMinimap = MplusLedger:GetConfig("display_party_in_minimap")
  local numGroupMembers = GetNumGroupMembers()
  if showPartyInMinimap and numGroupMembers > 1 then
    local partyKeystones = MplusLedger:GetPartyMemberKeystones()
    tooltip:AddLine(" ")
    tooltip:AddLine("Party members:")
    tooltip:AddLine(" ")

    for _, partyStoneInfo in pairs(partyKeystones) do
      if characterName ~= partyStoneInfo.name then
        local shouldShowNoKeys = partyStoneInfo.mythicLevel == "0" and showNoKeyCharacters
        if tonumber(partyStoneInfo.mythicLevel) > 0 or shouldShowNoKeys then
          tooltip:AddLine(UiUtils:ClassColoredName(partyStoneInfo.name, partyStoneInfo.classToken))
          if partyStoneInfo.mythicLevel == "0" then
            tooltip:AddLine(UiUtils:Indent("No keystone"))
          else
            tooltip:AddLine(UiUtils:Indent("+" .. partyStoneInfo.mythicLevel .. " " .. partyStoneInfo.dungeon))
          end
        end
      end
    end
  end

  tooltip:AddLine(" ")
  tooltip:AddLine("Left-click to toggle your M+ Ledger")
  tooltip:AddLine("Right-click to open M+ Ledger config options")
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
  local icon = LibStub("LibDBIcon-1.0", true)
  if not MplusLedgerIconDB then MplusLedgerIconDB = {} end
  if MplusLedger:GetConfig("enable_minimap") then
    icon:Register("MplusLedger", ldbPlugin, MplusLedgerIconDB)
  end
end)

f:RegisterEvent("PLAYER_LOGIN")