local MplusLedger = MplusLedger
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local frame
local tabs
local selectedTab
local ColorText = LibStub("MplusLedgerColorText-1.0")
local UiUtils = LibStub("MplusLedgerUiUtils-1.0")

local HideFrame = function(widget)
  AceGUI:Release(widget) 
  MplusLedger.ShowingMainFrame = false
  selectedTab = nil
end

local function AddPartyMemberLabelsToContainer(container, partyMember)   
  local nameLabel = UiUtils:CreateLabel{
    text = UiUtils:Indent(UiUtils:PartyMemberName(partyMember)), 
    fontSizeMultiplier = 1.25
  }
  container:AddChild(nameLabel)
  
  local raceClassLabel = UiUtils:CreateLabel{
    text = UiUtils:Indent(UiUtils:PartyMemberRaceAndClass(partyMember), 2), 
    fontSizeMultiplier = 1.1
  }
  container:AddChild(raceClassLabel)
  
  local deathCountLabel = UiUtils:CreateLabel{
    text = UiUtils:Indent(UiUtils:PartyMemberDeathCount(partyMember), 2),
    fontSizeMultiplier = 0.8
  }
  container:AddChild(deathCountLabel)
end

local function AddDungeonLabelsToContainer(container, dungeon)
  local name, _, timeLimit = C_ChallengeMode.GetMapInfo(dungeon.challengeMapId)
  
  local nameLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonName(dungeon), 
    relativeWidth = 0.8, 
    fontSizeMultiplier = 2.25
  }
  container:AddChild(nameLabel)
  
  local levelLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonLevel(dungeon), 
    relativeWidth = 0.2,
    fontSizeMultiplier = 2.25,
    justifyH = "CENTER"
  }
  container:AddChild(levelLabel)
  
  local startDateLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonStartedAt(dungeon),
    relativeWidth = 0.8,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(startDateLabel)

  local affixesLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonAffixInfo(dungeon),
    relativeWidth = 0.2,
    fontSizeMultiplier = 0.8,
    justifyH = "CENTER"
  }
  container:AddChild(affixesLabel)

  local totalDeaths = MplusLedger:DungeonTotalDeathCount(dungeon)
  local totalTimeLostToDeath = totalDeaths * 5

  local endDateLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonEndedAt(dungeon),
    relativeWidth = 0.8,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(endDateLabel)

  local keyModLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonBoostProgress(dungeon),
    relativeWidth = 0.2,
    fontSizeMultiplier = 1.5,
    justifyH = "CENTER"
  }
  container:AddChild(keyModLabel)

  local timeLimitLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonTimeLimit(dungeon),
    relativeWidth = 0.4,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(timeLimitLabel)
  
  local totalRuntimeLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonTotalRuntime(dungeon),
    relativeWidth = 0.4,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(totalRuntimeLabel)

  local twoChestTimeLimitLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonTimeLimitBoostTwo(dungeon),
    relativeWidth = 0.4,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(twoChestTimeLimitLabel)

  local totalRuntimeWithDeathLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonTotalRuntimeWithDeaths(dungeon),
    relativeWidth = 0.4,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(totalRuntimeWithDeathLabel)

  local threeChestTimeLimitLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonTimeLimitBoostThree(dungeon),
    relativeWidth = 0.4,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(threeChestTimeLimitLabel)
  
  local deathPenaltyLabel = UiUtils:CreateLabel{
    text = UiUtils:DungeonDeathPenalty(dungeon),
    relativeWidth = 0.4,
    fontSizeMultiplier = 1.1
  }
  container:AddChild(deathPenaltyLabel)

  local spacerLabel = UiUtils:CreateLabel{text = "", relativeWidth = 1.0, fontSizeMultiplier = 1}
  container:AddChild(spacerLabel)

  for _, partyMember in pairs(dungeon.party) do
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
    local label = UiUtils:CreateLabel{
      text = "No Mythic+ is currently being ran. Please check again after you've started a M+",
      relativeWidth = 1.0,
      fontSizeMultiplier = 1.5,
      justifyH = "CENTER"
    }
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

  for _, dungeon in pairs(dungeons) do
    local partyGroup = AceGUI:Create("InlineGroup")
    partyGroup:SetLayout("Flow")
    partyGroup:SetRelativeWidth(1.0)
    scrollFrame:AddChild(partyGroup)
    AddDungeonLabelsToContainer(partyGroup, dungeon)
  end
end

local function DrawKeysTab(container)
  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("Flow")
  container:AddChild(scrollFrame)

  for character, stoneInfo in pairs(MplusLedger:GetCurrentKeystones()) do
    local characterGroup = AceGUI:Create("InlineGroup")
    characterGroup:SetRelativeWidth(1.0)
    local nameLabel = UiUtils:CreateLabel{
      text = UiUtils:Indent(UiUtils:ClassColoredName(character, stoneInfo.classToken)), 
      fontSizeMultiplier = 1.25
    }
    characterGroup:AddChild(nameLabel)

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
    local keystoneLabel = UiUtils:CreateLabel{
      text = UiUtils:Indent(labelText, 2),
      fontSizeMultiplier = 1.1
    }
    characterGroup:AddChild(keystoneLabel)

    scrollFrame:AddChild(characterGroup)
  end
end

local function SelectedTab(container, event, tab)
  container:ReleaseChildren()
  selectedTab = tab
  if tab == "current_dungeon" then
    DrawCurrentDungeonTab(container)
  elseif tab == "history" then
    DrawHistoryTab(container)
  elseif tab == "keys" then
    DrawKeysTab(container)
  end
end

MplusLedger:RegisterMessage(MplusLedger.Events.HideMainFrame, function()
  HideFrame(frame)
end)

MplusLedger:RegisterMessage(MplusLedger.Events.ShowMainFrame, function(_, tabToShow)
  if not tabToShow then
    tabToShow = "current_dungeon"
  elseif tabToShow ~= "current_dungeon" and tabToShow ~= "history" and tabToShow ~= "keys" then
    error("A tab that does not exist, " .. tabToShow .. ", was asked to be shown. If you have not modified this addon's source code please submit an issue describing your problem")
  end
  
  MplusLedger.ShowingMainFrame = true
  frame = AceGUI:Create("Frame")
  frame:SetTitle(MplusLedger:Title())
  frame:SetStatusText("v" .. MplusLedger:Version())
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
    },
    {
      text = "Your Keys",
      value = "keys"
    }
  })

  tabs:SetCallback("OnGroupSelected", SelectedTab)
  tabs:SelectTab(tabToShow)

  frame:AddChild(tabs)
end)
