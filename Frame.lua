local MplusLedger = MplusLedger
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local frame
local tabs
local selectedTab
local ColorText = LibStub("MplusLedgerColorText-1.0")
local UiUtils = LibStub("MplusLedgerUiUtils-1.0")



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

  local function DrawCharacterKeyGroup(container, character, stoneInfo)
    local characterGroup = AceGUI:Create("InlineGroup")
    characterGroup:SetRelativeWidth(1.0)
    local nameLabel = UiUtils:CreateLabel{
      text = UiUtils:Indent(UiUtils:ClassColoredName(character, stoneInfo.classToken)), 
      fontSizeMultiplier = 1.25
    }
    characterGroup:AddChild(nameLabel)

    local labelText
    if not stoneInfo.keystone then
      labelText = "No keystone."
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

      labelText = "+" .. mythicLevel .. " " .. mythicName
      if affixString then
        labelText = labelText .. " (" .. affixString .. ")"
      end
    end
    local keystoneLabel = UiUtils:CreateLabel{
      text = UiUtils:Indent(labelText, 2),
      fontSizeMultiplier = 1.1
    }
    characterGroup:AddChild(keystoneLabel)
    scrollFrame:AddChild(characterGroup)
  end

  local yourKeystone = MplusLedger:GetSpecificCharacterKeystone()
  local characterName = UnitName("player")
  DrawCharacterKeyGroup(container, characterName, yourKeystone)

  local showNoKeyCharacters = MplusLedger:GetConfig("display_no_key_characters")
  for character, stoneInfo in pairs(MplusLedger:GetCurrentKeystones()) do
    if character ~= characterName then
      local shouldShowNoKeys = stoneInfo.keystone == nil and showNoKeyCharacters
      if stoneInfo.keystone or shouldShowNoKeys then
        DrawCharacterKeyGroup(container, character, stoneInfo)
      end
    end
  end
end

local function DrawPartyKeysTab(container)
  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("Flow")
  container:AddChild(scrollFrame)

  local showNoKeyCharacters = MplusLedger:GetConfig("display_no_key_characters")
  local keystones = MplusLedger:GetPartyMemberKeystones()
  if MplusLedger:CountTable(keystones) == 0 then
    local noKeystonesLabel = UiUtils:CreateLabel{
      text = "Keys will only be shown while in a party",
      fontSizeMultiplier = 1.5,
      justifyH = "CENTER",
      justifyV = "CENTER"
    }
    scrollFrame:AddChild(noKeystonesLabel)
  else
    for stoneInfo in pairs(keystones) do
      local mythicLevel = stoneInfo.mythicLevel
      if tonumber(mythicLevel) > 0 or showNoKeyCharacters then
        local characterGroup = AceGUI:Create("InlineGroup")
        characterGroup:SetRelativeWidth(1.0)
        local nameLabel = UiUtils:CreateLabel{
          text = UiUtils:Indent(UiUtils:ClassColoredName(stoneInfo.name, stoneInfo.classToken)), 
          fontSizeMultiplier = 1.25
        }
        characterGroup:AddChild(nameLabel)

        local dungeon = stoneInfo.dungeon
        local levelText
        if mythicLevel == "0" then
          levelText = "No keystone"
        else
          levelText = "+" .. mythicLevel .. " " .. dungeon
        end

        local keystoneLabel = UiUtils:CreateLabel{
          text = UiUtils:Indent(levelText, 2),
          fontSizeMultiplier = 1.1
        }
        characterGroup:AddChild(keystoneLabel)
        scrollFrame:AddChild(characterGroup)
      end
    end

    local outputToChatButton = UiUtils:CreateButton{
      text = "Output to Chat",
      click = function()
        MplusLedger:SendPartyKeystonesToChat()
      end
    }
    scrollFrame:AddChild(outputToChatButton)
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
  elseif  tab == "party_keys" then
    DrawPartyKeysTab(container)
  end
end



local function ShowLedger(tabToShow)
  tabs = AceGUI:Create("TabGroup")
  tabs:SetLayout("Fill")

  tabs:SetTabs({
    {
      text = "Your Keys",
      value = "keys"
    },
    {
      text = "Party Keys",
      value = "party_keys"
    },
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

  MplusLedger.frame:AddChild(tabs)
end

function MplusLedger:DrawLootedItems(dungeon)
  local lootGroup = MplusLedger.lootGroup

  local loot = MplusLedger:CurrentLoot()
  if loot then
    for _, lootInfo in pairs(loot) do
      local name, _, quality, ilvl, _, _, _, _, _, texture = GetItemInfo(lootInfo.lootLink)
      local looterLabel = UiUtils:CreateLabel{
        text = lootInfo.looter,
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.25,
        justifyH = "LEFT"
      }
      lootGroup:AddChild(looterLabel)

      local lootLabel = UiUtils:CreateLabel{
        text = ColorText:FromItemQuality(name, quality),
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.75,
        justifyH = "LEFT",
        image = texture,
        interactive = true
      }
      
      lootLabel:SetCallback("OnEnter", function()
        MplusLedger.tooltip:SetOwner(lootLabel.frame)
        MplusLedger.tooltip:SetHyperlink(lootInfo.lootLink)
        MplusLedger.tooltip:SetPoint("BOTTOMRIGHT", lootLabel.frame, "BOTTOMRIGHT")
      end)
      lootLabel:SetCallback("OnLeave", function()
        MplusLedger.tooltip:Hide()
      end)
      
      lootGroup:AddChild(lootLabel)

      local ilvlLabel = UiUtils:CreateLabel{
        text = UiUtils:Indent("Item level " .. ilvl),
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.25,
        justifyH = "LEFT"
      }
      lootGroup:AddChild(ilvlLabel)

      local spacerLabel = UiUtils:CreateLabel{
        text = " ",
        relativeWidth = 1.0,
        height = 15
      }
      lootGroup:AddChild(spacerLabel)
    end
  end
end

function MplusLedger:ShowCompletionSplash(dungeon)
  local mainGroup = AceGUI:Create("ScrollFrame")
  mainGroup:SetLayout("Flow")
  mainGroup:SetRelativeWidth(1.0)
  mainGroup:SetFullHeight(true)

  local dungeonName = MplusLedger:DungeonName(dungeon)
  local dungeonBoostProgress = MplusLedger:DungeonBoostProgress(dungeon)

  if dungeon.state == "success" then
    local headingLabel = UiUtils:CreateLabel{
      text = "+" .. dungeon.mythicLevel .. " " .. dungeonName,
      fontSizeMultiplier = 1.75,
      relativeWidth = 1.0,
      justifyH = "CENTER"
    }
    mainGroup:AddChild(headingLabel)

    local headingSpacerLabel = UiUtils:CreateLabel{
      text = " ",
      relativeWidth = 1.0
    }
    mainGroup:AddChild(headingSpacerLabel)

    local boostText
    local newKeyLevel = tonumber(dungeon.mythicLevel) + dungeonBoostProgress
    if dungeonBoostProgress > 0 then      
      boostText = "Pushed key to " .. ColorText:Green("+" .. newKeyLevel) 
    else
      boostText = "Depleted key to " .. ColorText:Red("-" .. newKeyLevel)
    end

    local boostLabel = UiUtils:CreateLabel{
      text = boostText,
      fontSizeMultiplier = 3.25,
      relativeWidth = 1.0,
      justifyH = "CENTER"
    }
    mainGroup:AddChild(boostLabel)

    local boostSpacerLabel = UiUtils:CreateLabel{
      text = " ",
      relativeWidth = 1.0
    }
    mainGroup:AddChild(boostSpacerLabel)

    local totalRuntimeLabel = UiUtils:CreateLabel{
      text = UiUtils:DungeonTotalRuntimeWithDeaths(dungeon),
      relativeWidth = 1.0,
      fontSizeMultiplier = 1.25,
      justifyH = "LEFT"
    }
    mainGroup:AddChild(totalRuntimeLabel)

    local beatTimerBy = MplusLedger:DungeonBeatBoostTimerBy(dungeon)
    if beatTimerBy then
      local beatTimerByLabel = UiUtils:CreateLabel{
        text = UiUtils:DungeonBeatBoostTimerBy(dungeon),
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.25,
        justifyH = "LEFT"
      }
      mainGroup:AddChild(beatTimerByLabel)
    end

    local missedTimerBy = MplusLedger:DungeonMissedBoostTimerBy(dungeon)    
    if missedTimerBy then
      local missedTimerByLabel = UiUtils:CreateLabel{
        text = UiUtils:DungeonMissedBoostTimerBy(dungeon),
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.25,
        justifyH = "LEFT"
      }
      mainGroup:AddChild(missedTimerByLabel)  
    end

    local missedTimerSpacerLabel = UiUtils:CreateLabel{
      text = " ",
      relativeWidth = 1.0
    }

    local lootGroup = AceGUI:Create("SimpleGroup")
    lootGroup:SetLayout("List")
    lootGroup:SetRelativeWidth(1.0)

    MplusLedger.lootGroup = lootGroup
    MplusLedger:DrawLootedItems(dungeon)

    mainGroup:AddChild(missedTimerSpacerLabel)
    mainGroup:AddChild(lootGroup)

    local okButton = UiUtils:CreateButton{
      text = "More Details",
      click = function()
        MplusLedger.frame:Hide()
        MplusLedger:SendMessage(MplusLedger.Events.ShowMainFrame, 'history')
      end
    }
    mainGroup:AddChild(okButton)
  end

  MplusLedger.frame:AddChild(mainGroup)
end

function MplusLedger:ShowCompletionSplash(dungeon)
  local mainGroup = AceGUI:Create("SimpleGroup")
  mainGroup:SetLayout("Flow")
  mainGroup:SetRelativeWidth(1.0)
  mainGroup:SetFullHeight(true)

  local dungeonName = MplusLedger:DungeonName(dungeon)
  local dungeonBoostProgress = MplusLedger:DungeonBoostProgress(dungeon)

  if dungeon.state == "success" then
    local lootGroup = AceGUI:Create("SimpleGroup")
    lootGroup:SetLayout("List")
    lootGroup:SetRelativeWidth(1.0)

    MplusLedger.lootGroup = lootGroup
    MplusLedger:DrawLootedItems()

    local headingLabel = UiUtils:CreateLabel{
      text = "+" .. dungeon.mythicLevel .. " " .. dungeonName,
      fontSizeMultiplier = 1.75,
      relativeWidth = 1.0,
      justifyH = "CENTER"
    }
    mainGroup:AddChild(headingLabel)

    local headingSpacerLabel = UiUtils:CreateLabel{
      text = " ",
      relativeWidth = 1.0,
      height = 10
    }
    mainGroup:AddChild(headingSpacerLabel)

    local boostLabel = UiUtils:CreateLabel{
      text = UiUtils:DungeonBoostProgress(dungeon),
      fontSizeMultiplier = 2.75,
      relativeWidth = 1.0,
      justifyH = "CENTER"
    }
    mainGroup:AddChild(boostLabel)

    local boostSpacerLabel = UiUtils:CreateLabel{
      text = " ",
      relativeWidth = 1.0
    }
    mainGroup:AddChild(boostSpacerLabel)

    local totalRuntimeLabel = UiUtils:CreateLabel{
      text = UiUtils:Indent(UiUtils:DungeonTotalRuntimeWithDeaths(dungeon)),
      relativeWidth = 1.0,
      fontSizeMultiplier = 1.25,
      justifyH = "LEFT"
    }
    mainGroup:AddChild(totalRuntimeLabel)

    local beatTimerBy = MplusLedger:DungeonBeatBoostTimerBy(dungeon)
    if beatTimerBy then
      local beatTimerByLabel = UiUtils:CreateLabel{
        text = UiUtils:Indent(UiUtils:DungeonBeatBoostTimerBy(dungeon)),
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.25,
        justifyH = "LEFT"
      }
      mainGroup:AddChild(beatTimerByLabel)
    end

    local missedTimerBy = MplusLedger:DungeonMissedBoostTimerBy(dungeon)    
    if missedTimerBy then
      local missedTimerByLabel = UiUtils:CreateLabel{
        text = UiUtils:Indent(UiUtils:DungeonMissedBoostTimerBy(dungeon)),
        relativeWidth = 1.0,
        fontSizeMultiplier = 1.25,
        justifyH = "LEFT"
      }
      mainGroup:AddChild(missedTimerByLabel)  
    end

    local missedTimerSpacerLabel = UiUtils:CreateLabel{
      text = " ",
      relativeWidth = 1.0
    }
    mainGroup:AddChild(missedTimerSpacerLabel)
  end

  MplusLedger.frame:AddChild(mainGroup)
end

local HideFrame = function(widget)
  AceGUI:Release(widget) 
  MplusLedger.ShowingLedgerFrame = false
  MplusLedger.ShowingCompletionFrame = false
  selectedTab = nil
end

MplusLedger:RegisterMessage(MplusLedger.Events.HideFrame, function()
  HideFrame(frame)
end)

local ShowFrame = function(panelToShow, auxData)
  frame = AceGUI:Create("Window")
  frame:SetTitle(MplusLedger:Title())
  frame:SetStatusText("v" .. MplusLedger:Version())
  frame:SetCallback("OnClose", function(widget) 
    HideFrame(widget)  
  end)
  frame:SetLayout("Fill")
  frame:EnableResize(false)

  MplusLedger.frame = frame
  
  if panelToShow ~= "completion_splash" then
    local allowedTabs = {
      current_dungeon = true,
      history = true,
      keys = true,
      party_keys = true,
      completion_splash = true
    }
    if not auxData then
      auxData = "keys"
    end
  
    if allowedTabs[auxData] == nil then
      error("A tab that does not exist, " .. auxData .. ", was asked to be shown. If you have not modified this addon's source code please submit an issue describing your problem")
    end

    MplusLedger.ShowingLedgerFrame = true
    frame:SetWidth(700)
    ShowLedger(auxData)
  else
    MplusLedger.ShowingCompletionFrame = true
    frame:SetWidth(350)
    MplusLedger:ShowCompletionSplash(auxData)
  end  
end

MplusLedger:RegisterMessage(MplusLedger.Events.ShowFrame, function(_, panelToShow, auxData)
  ShowFrame(panelToShow, auxData)
end)
