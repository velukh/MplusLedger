local MplusLedger = MplusLedger
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local frame
local tabs
local selectedTab
local font, fontSize, flags = GameFontNormal:GetFont()

local OneIndent = "     "
local TwoIndent = OneIndent .. OneIndent

local HideFrame = function(widget)
  AceGUI:Release(widget) 
  MplusLedger.ShowingMainFrame = false
  selectedTab = nil
end

local function ClassColorText(text, classToken)
  local color = RAID_CLASS_COLORS[classToken]
  return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

local function RedText(text)
  return "|cFFFF0000" .. text .. "|r"
end

local function GreenText(text)
  return "|cFF00FF00" .. text .. "|r"
end

local function AddPartyMemberLabelsToContainer(container, partyMember) 
  local nameLabel = AceGUI:Create("Label")
  local name = ClassColorText(partyMember.name, partyMember.classToken)
  if partyMember.realm then
    name = name .. " - " .. partyMember.realm
  end
  nameLabel:SetText(OneIndent .. name)
  nameLabel:SetRelativeWidth(1.0)
  nameLabel:SetFont(font, fontSize * 1.25, flags)
  
  container:AddChild(nameLabel)
  
  local raceClassLabel = AceGUI:Create("Label")
  raceClassLabel:SetText(TwoIndent .. partyMember.race .. " " .. partyMember.class)
  raceClassLabel:SetRelativeWidth(1.0)
  raceClassLabel:SetFont(font, fontSize * 1.1, flags)
  
  container:AddChild(raceClassLabel)
  
  local deathCountLabel = AceGUI:Create("Label")
  local timesText
  if partyMember.deathCount == 1 then
    timesText = "time"
  else
    timesText = "times"
  end
  deathCountLabel:SetText(TwoIndent .. "Died " .. partyMember.deathCount .. " " .. timesText)
  deathCountLabel:SetRelativeWidth(1.0)
  deathCountLabel:SetFont(font, fontSize * 0.8, flags)
  
  container:AddChild(deathCountLabel)
end

local function SecondsToClock(seconds, excludeHours)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00"
  else
    hours = string.format("%02.f", math.floor(seconds/3600))
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60))

    if not excludeHours then
      return hours .. ":" .. mins .. ":" .. secs
    else
      return mins .. ":" .. secs
    end
  end
end

local function AddDungeonLabelsToContainer(container, dungeon)
  local name, _, timeLimit = C_ChallengeMode.GetMapInfo(dungeon.challengeMapId)
  local nameLabel = AceGUI:Create("Label")
  nameLabel:SetText(name)
  nameLabel:SetFont(font, fontSize * 2.25, flags)
  nameLabel:SetRelativeWidth(0.8)
  
  container:AddChild(nameLabel)

  local levelLabel = AceGUI:Create("Label")
  levelLabel:SetText("Level " .. dungeon.mythicLevel)
  levelLabel:SetFont(font, fontSize * 2.25, flags)
  levelLabel:SetRelativeWidth(0.2)
  levelLabel:SetJustifyH("CENTER")
  
  container:AddChild(levelLabel)
  
  local startDateLabel = AceGUI:Create("Label")
  startDateLabel:SetText("Started on " .. date("%c", dungeon.startedAt))
  startDateLabel:SetFont(font, fontSize * 1.1, flags)
  startDateLabel:SetRelativeWidth(0.8)
  
  container:AddChild(startDateLabel)

  local affixInfo
  for _, affixId in ipairs(dungeon.affixes) do
    local name, description = C_ChallengeMode.GetAffixInfo(affixId)
    if not affixInfo then
      affixInfo = name
    else
      affixInfo = affixInfo .. ", " .. name
    end
  end

  if not affixInfo then
    affixInfo = "No affixes"
  end

  local affixesLabel = AceGUI:Create("Label")
  affixesLabel:SetText(affixInfo)
  affixesLabel:SetFont(font, fontSize * 0.8, flags)
  affixesLabel:SetRelativeWidth(0.2)
  affixesLabel:SetJustifyH("CENTER")

  container:AddChild(affixesLabel)

  local totalDeaths = MplusLedger:DungeonTotalDeathCount(dungeon)
  local totalTimeLostToDeath = totalDeaths * 5

  local endDateText
  if dungeon.endedAt then
    endDateText = "Ended on " .. date("%c", dungeon.endedAt)
  else
    endDateText = ""
  end

  local endDateLabel = AceGUI:Create("Label")
  endDateLabel:SetText(endDateText)
  endDateLabel:SetFont(font, fontSize * 1.1, flags) 
  endDateLabel:SetRelativeWidth(0.8)

  container:AddChild(endDateLabel)

  local keyMod
  local endTime = dungeon.endedAt
  if not endTime then
    endTime = time()
  end
  local totalRuntime = difftime(endTime, (dungeon.startedAt + 10))

  if dungeon.state == "failed" then
    keyMod = RedText("-1")
  else
    local plusTwo = timeLimit * 0.8
    local plusThree = timeLimit * 0.6
    local totalRuntimePlusDeaths = totalRuntime + totalTimeLostToDeath
    
    if not dungeon.endedAt then
      keyMod = ""
    elseif totalRuntimePlusDeaths <= plusThree then
      keyMod = GreenText("+3")
    elseif totalRuntimePlusDeaths <= plusTwo then
      keyMod = GreenText("+2")
    elseif totalRuntimePlusDeaths <= timeLimit then
      keyMod = GreenText("+1")
    else
      keyMod = RedText("-1")
    end
  end

  local keyModLabel = AceGUI:Create("Label")
  keyModLabel:SetText(keyMod)
  keyModLabel:SetRelativeWidth(0.2)
  keyModLabel:SetFont(font, fontSize * 1.5, flags)
  keyModLabel:SetJustifyH("CENTER")

  container:AddChild(keyModLabel)

  local timeLimitLabel = AceGUI:Create("Label")
  timeLimitLabel:SetText("Limit: " .. SecondsToClock(timeLimit, true))
  timeLimitLabel:SetRelativeWidth(0.4)
  timeLimitLabel:SetFont(font, fontSize * 1.1, flags)

  container:AddChild(timeLimitLabel)

  local totalRunTimeLabel = AceGUI:Create("Label") 
  totalRunTimeLabel:SetText("Run time: " .. SecondsToClock(totalRuntime))
  totalRunTimeLabel:SetFont(font, fontSize * 1.1, flags)
  totalRunTimeLabel:SetRelativeWidth(0.4)

  container:AddChild(totalRunTimeLabel)

  local twoChestTimeLimitLabel = AceGUI:Create("Label")
  twoChestTimeLimitLabel:SetText("    +2: " .. SecondsToClock(timeLimit * 0.8, true))
  twoChestTimeLimitLabel:SetRelativeWidth(0.4)
  twoChestTimeLimitLabel:SetFont(font, fontSize * 1.1, flags)

  container:AddChild(twoChestTimeLimitLabel)

  local totalRunTimeWithDeathLabel = AceGUI:Create("Label")
  totalRunTimeWithDeathLabel:SetText("Run time w/ deaths: " .. SecondsToClock(totalRuntime + totalTimeLostToDeath))
  totalRunTimeWithDeathLabel:SetRelativeWidth(0.4)
  totalRunTimeWithDeathLabel:SetFont(font, fontSize * 1.1, flags)

  container:AddChild(totalRunTimeWithDeathLabel)

  local threeChestTimeLimitLabel = AceGUI:Create("Label")
  threeChestTimeLimitLabel:SetText("    +3: " .. SecondsToClock(timeLimit * 0.6, true))
  threeChestTimeLimitLabel:SetRelativeWidth(0.4)
  threeChestTimeLimitLabel:SetFont(font, fontSize * 1.1, flags)

  container:AddChild(threeChestTimeLimitLabel)
  
  local deathPenaltyLabel = AceGUI:Create("Label")
  deathPenaltyLabel:SetText("Lost to deaths: " .. SecondsToClock(totalTimeLostToDeath, true) .. " (" .. totalDeaths .. ")")
  deathPenaltyLabel:SetFont(font, fontSize * 1.1, flags)
  deathPenaltyLabel:SetRelativeWidth(0.4)

  container:AddChild(deathPenaltyLabel)

  local spacerLabel = AceGUI:Create("Label")
  spacerLabel:SetText("")
  spacerLabel:SetRelativeWidth(1.0)

  container:AddChild(spacerLabel)

  local anotherSpacerLabel = AceGUI:Create("Label")
  anotherSpacerLabel:SetText("")
  anotherSpacerLabel:SetRelativeWidth(1.0)

  container:AddChild(anotherSpacerLabel)

  for _, partyMember in ipairs(dungeon.party) do
    AddPartyMemberLabelsToContainer(container, partyMember)
  end
end

local function DrawCurrentDungeonTab(container)
  if MplusLedger:IsRunningMythicPlus() then
    local currentDungeon = MplusLedger:CurrentDungeon()    
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    container:AddChild(scrollFrame)
    AddDungeonLabelsToContainer(scrollFrame, currentDungeon)
  else
    local label = AceGUI:Create("Label")
    label:SetText("No Mythic+ is currently being ran. Please check again after you've started a M+")
    label:SetFullWidth(true)
    label:SetFont(font, fontSize * 1.5, flags)
    label:SetJustifyH("CENTER")
    container:AddChild(label)
  end
end

local function DrawHistoryTab(container)
  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("Flow")
  container:AddChild(scrollFrame)
  local dungeons = MplusLedger:FinishedDungeons()
  table.sort(dungeons, function(arg1, arg2)
    return arg1.startedAt >= arg2.startedAt
  end)

  for _, dungeon in ipairs(dungeons) do
    local partyGroup = AceGUI:Create("InlineGroup")
    partyGroup:SetLayout("Flow")
    partyGroup:SetRelativeWidth(1.0)
    scrollFrame:AddChild(partyGroup)
    AddDungeonLabelsToContainer(partyGroup, dungeon)
  end
end

local function SelectedTab(container, event, tab)
  container:ReleaseChildren()
  selectedTab = tab
  if tab == "current_dungeon" then
    DrawCurrentDungeonTab(container)
  elseif tab == "history" then
    DrawHistoryTab(container)
  end
end

MplusLedger:RegisterMessage(MplusLedger.Events.HideMainFrame, function()
  HideFrame(frame)
end)

MplusLedger:RegisterMessage(MplusLedger.Events.ShowMainFrame, function(_, tabToShow)
  if not tabToShow then
    tabToShow = "current_dungeon"
  elseif tabToShow ~= "current_dungeon" and tabToShow ~= "history" then
    error("A tab that does not exist, " .. tabToShow .. ", was asked to be shown. If you have not modified this addon's source code please submit an issue describing your problem")
  end
  
  MplusLedger.ShowingMainFrame = true
  frame = AceGUI:Create("Frame")
  frame:SetTitle(MplusLedger.Title)
  frame:SetStatusText("v" .. MplusLedger.Version)
  frame:SetCallback("OnClose", function(widget) 
    HideFrame(widget)  
  end)
  frame:SetLayout("Fill")
  frame:EnableResize(false)

  tabs = AceGUI:Create("TabGroup")
  tabs:SetLayout("Fill")

  tabs:SetTabs({
    {
      text = "Current Dungeon",
      value = "current_dungeon"
    },
    {
      text = "History",
      value = "history"
    }
  })

  tabs:SetCallback("OnGroupSelected", SelectedTab)
  tabs:SelectTab(tabToShow)

  frame:AddChild(tabs)
end)
