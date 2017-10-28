MplusLedgerUiUtils = LibStub:NewLibrary("MplusLedgerUiUtils-1.0", 1)

local AceGUI = LibStub("AceGUI-3.0")
local ColorText = LibStub("MplusLedgerColorText-1.0")
local MplusLedger = MplusLedger
local defaultFont, defaultFontSize, defaultFontFlags

local function GetGameFontNormal()
  if not defaultFont then
    defaultFont, defaultFontSize, defaultFontFlags = GameFontNormal:GetFont()
  end
  return defaultFont, defaultFontSize, defaultFontFlags
end

function MplusLedgerUiUtils:CreateLabel(labelSettings)
  local label = AceGUI:Create("Label")

  if not labelSettings.relativeWidth then
    labelSettings.relativeWidth = 1.0
  end

  label:SetText(labelSettings.text)
  label:SetRelativeWidth(labelSettings.relativeWidth)
  label:SetFont(self:Font(), self:FontSize(labelSettings.fontSizeMultiplier), self:FontFlags())

  if labelSettings.justifyH then
    label:SetJustifyH(labelSettings.justifyH)
  end

  return label
end

function MplusLedgerUiUtils:Indent(text, indentLevel)
  if not indentLevel then
    indentLevel = 1
  end

  return string.rep("    ", indentLevel) .. text
end

function MplusLedgerUiUtils:Font()
  font = GetGameFontNormal()
  return font
end

function MplusLedgerUiUtils:FontSize(sizeMultiplier)
  _, size = GetGameFontNormal()
  return size * sizeMultiplier
end

function MplusLedgerUiUtils:FontFlags()
  _, _, flags = GetGameFontNormal()
  return flags
end

function MplusLedgerUiUtils:SecondsToClock(seconds, excludeHours)
  local seconds = tonumber(seconds)

  if seconds == nil or seconds <= 0 then
    if not excludeHours then
      return "00:00:00"
    else
      return "00:00"
    end
  else
    hours = string.format("%02.f", math.floor(seconds / 3600))
    mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
    secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))

    if not excludeHours then
      return hours .. ":" .. mins .. ":" .. secs
    else
      return mins .. ":" .. secs
    end
  end
end

function MplusLedgerUiUtils:DungeonName(dungeon)
  return MplusLedger:DungeonName(dungeon)
end

function MplusLedgerUiUtils:DungeonLevel(dungeon)
  return "Level " .. dungeon.mythicLevel
end

function MplusLedgerUiUtils:DungeonStartedAt(dungeon)
  return "Started on " .. date("%c", dungeon.startedAt)
end

function MplusLedgerUiUtils:DungeonEndedAt(dungeon)
  if dungeon.endedAt then
    return "Ended on " .. date("%c", dungeon.endedAt)
  else
    return ""
  end
end

function MplusLedgerUiUtils:DungeonBoostProgress(dungeon)
  local keyMod = MplusLedger:DungeonBoostProgress(dungeon)

  if keyMod == 0 then
    keyMod = ""
  elseif keyMod > 0 then
    keyMod = ColorText:Green(keyMod)
  else
    keyMod = ColorText:Red(keyMod)
  end

  return keyMod
end

function MplusLedgerUiUtils:DungeonTotalRuntime(dungeon)
  return "Run time: " .. self:SecondsToClock(MplusLedger:DungeonTotalRuntime(dungeon))
end

function MplusLedgerUiUtils:DungeonTotalRuntimeWithDeaths(dungeon)
  return "Run time w/ deaths: " .. self:SecondsToClock(MplusLedger:DungeonTotalRuntimeWithDeaths(dungeon))
end

function MplusLedgerUiUtils:DungeonTimeLimit(dungeon)
  local timeLimit = MplusLedger:DungeonTimeLimit(dungeon)
  return "Limit: " .. self:SecondsToClock(timeLimit, true)
end

function MplusLedgerUiUtils:DungeonTimeLimitBoostTwo(dungeon)
  local timeLimit = MplusLedger:DungeonTimeLimitBoostTwo(dungeon)
  return "    +2: " .. self:SecondsToClock(timeLimit, true)
end

function MplusLedgerUiUtils:DungeonTimeLimitBoostThree(dungeon)
  local timeLimit = MplusLedger:DungeonTimeLimitBoostThree(dungeon)
  return "    +3: " .. self:SecondsToClock(timeLimit, true)
end

function MplusLedgerUiUtils:DungeonDeathPenalty(dungeon)
  local totalDeaths = MplusLedger:DungeonTotalDeathCount(dungeon)
  local totalTimeLostToDeath = totalDeaths * 5
  return "Lost to deaths: " .. self:SecondsToClock(totalTimeLostToDeath, true) .. " (" .. totalDeaths .. ")"
end

function MplusLedgerUiUtils:DungeonAffixInfo(dungeon)
  local affixInfo
  for _, name in pairs(MplusLedger:DungeonAffixNames(dungeon)) do
    if not affixInfo then
      affixInfo = name
    else
      affixInfo = affixInfo .. ", " .. name
    end
  end

  if not affixInfo then
    affixInfo = "No affixes"
  end

  return affixInfo
end

function MplusLedgerUiUtils:ClassColoredName(characterName, classToken)
  local color = RAID_CLASS_COLORS[classToken]
  return ColorText:FromRGB(characterName, color)
end

function MplusLedgerUiUtils:PartyMemberName(partyMember)
  local name = self:ClassColoredName(partyMember.name, partyMember.classToken)
  if partyMember.realm then
    name = name .. " - " .. partyMember.realm
  end

  return name
end

function MplusLedgerUiUtils:PartyMemberRaceAndClass(partyMember)
  return partyMember.race .. " " .. partyMember.class
end

function MplusLedgerUiUtils:PartyMemberDeathCount(partyMember)
  local timesText
  if partyMember.deathCount == 1 then
    timesText = "time"
  else
    timesText = "times"
  end

  return "Died " .. partyMember.deathCount .. " " .. timesText
end
