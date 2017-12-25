--[[
MplusLedger

A WoW addon to keep long-term track of a player's Mythic+ runs so they may analyze how they're doing for 
a given spec, dungeon, affixes, level, and party composition.

@copyright Velukh 2017
--]]
MplusLedger = LibStub("AceAddon-3.0"):NewAddon(
  "MplusLedger",
  "AceComm-3.0",
  "AceConsole-3.0",
  "AceEvent-3.0",
  "AceHook-3.0",
  "AceTimer-3.0"
)

MplusLedger.ShowingMainFrame = false

MplusLedger.CommMessages = {
  ResyncKeys = "RESYNC_KEYS"
}

MplusLedger.Events = {
  ShowMainFrame = "MPLUS_SHOW_MAIN_FRAME",
  HideMainFrame = "MPLUS_HIDE_MAIN_FRAME",

  TrackingStarted = "MPLUS_TRACKING_STARTED",
  TrackingStopped = "MPLUS_TRACKING_STOPPED"
}

MplusLedger.Wow = {
  Events = {
    ChallengeModeStarted = "CHALLENGE_MODE_START",
    ChallengeModeCompleted = "CHALLENGE_MODE_COMPLETED",
    GroupRosterUpdate = "GROUP_ROSTER_UPDATE",
    PlayerEnteringWorld = "PLAYER_ENTERING_WORLD"
  },
  TwoBoostPercentage = 0.8,
  ThreeBoostPercentage = 0.6,
  SpellIds = {
    SurrenderedSoul = 212570
  }
}

local next = next
local cache = {
  title = nil,
  version = nil,
  dungeonInfo = {},
  affixInfo = {}
}
local ColorText = LibStub("MplusLedgerColorText-1.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local icon = LibStub("LibDBIcon-1.0", true)

function MplusLedger:SetConfig(key, value)
  if not self.db.realm.configOptions then
    self.db.realm.configOptions = {}
  end

  self.db.realm.configOptions[key] = value
end

function MplusLedger:GetConfig(key)
  if not self.db.realm.configOptions then
    self.db.realm.configOptions = {}
  end

  local defaultNilsToTrue = {
    enable_minimap = true,
    display_no_key_characters = true,
    display_party_in_minimap = true
  }

  local value = self.db.realm.configOptions[key]
  if value == nil and defaultNilsToTrue[key] ~= nil then
    return true
  else
    return value
  end
end

function MplusLedger:OnInitialize()
  local defaults = {}
  self.db = LibStub("AceDB-3.0"):New("MplusLedgerDB", defaults)
end

function MplusLedger:OnEnable()
  local ResetMythicPlusRuns = function()
    if self:IsRunningMythicPlus() then
      self:EndMythicPlusAsFailed("The instance was intentionally reset, likely in an effort to lower the key level.")
    end
    self:StoreKeystoneFromBags()
  end
  self:SecureHook("ResetInstances", ResetMythicPlusRuns)
end

function MplusLedger:OnDisable()
  self:Unhook("ResetInstances")
end

function MplusLedger:Title()
  if not cache.title then
    cache.title = GetAddOnMetadata("MplusLedger", "Title")
  end

  return cache.title
end

function MplusLedger:Version()
  if not cache.version then
    cache.version = GetAddOnMetadata("MplusLedger", "Version")
  end

  return cache.version
end

function MplusLedger:ToggleFrame(tabToShow)
  if self.ShowingMainFrame then
    self:SendMessage(self.Events.HideMainFrame)
  else
    self:SendMessage(self.Events.ShowMainFrame, tabToShow)
  end
end

function MplusLedger:StartMythicPlus(challengeMapId)
  if not challengeMapId then 
    error("MplusLedger encountered an error attempting to start your dungeon")
    return 
  end
  local level, affixes = C_ChallengeMode:GetActiveKeystoneInfo()

  self.db.char.currentDungeon = {
    state = "running",
    challengeMapId = challengeMapId,
    mythicLevel = level,
    affixes = affixes,
    startedAt = time(),
    endedAt = nil,
    runTime = nil,
    party = {}
  }

  local partyUnits = {"player", "party1", "party2", "party3", "party4"}
  for _, unitId in pairs(partyUnits) do
    if UnitExists(unitId) then
      local guid = UnitGUID(unitId)
      local player, realm = UnitName(unitId)
      local class, classToken = UnitClass(unitId)
      local race = UnitRace(unitId)
      local genderId = UnitSex(unitId)

      table.insert(self.db.char.currentDungeon.party, {
        guid = guid,
        unitId = unitId,
        name = player,
        realm = realm,
        race = race,
        genderId = genderId,
        class = class,
        classToken = classToken,
        deathCount = 0
      })
    end
  end

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(_, _, event, _, _, _, _, _, destGUID, destName, destFlags)
    self:HandlePossiblePlayerDeath(event, destGUID, destName, destFlags)
  end)
  self:SendMessage(self.Events.TrackingStarted, self.db.char.currentDungeon)
end

local function storeAndResetCurrentDungeon(ledger)
  ledger.db.char.currentDungeon.endedAt = time()

  if not ledger.db.char.finishedMythicRuns then
    ledger.db.char.finishedMythicRuns = {}
  end

  table.insert(ledger.db.char.finishedMythicRuns, ledger.db.char.currentDungeon)
  ledger.db.char.currentDungeon = nil
  ledger:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function MplusLedger:EndMythicPlusAsCompleted()
  if not self:IsRunningMythicPlus() then return end

  self.db.char.currentDungeon.state = "success"
  local eventDungeon = self.db.char.currentDungeon
  storeAndResetCurrentDungeon(self)
  self:SendMessage(self.Events.TrackingStopped, eventDungeon)  
end

function MplusLedger:EndMythicPlusAsFailed(failureReason)
  if not self:IsRunningMythicPlus() then return end

  self.db.char.currentDungeon.state = "failed"
  self.db.char.currentDungeon.failureReason = failureReason
  local eventDungeon = self.db.char.currentDungeon
  storeAndResetCurrentDungeon(self)
  self:SendMessage(self.Events.TrackingStopped, eventDungeon)
end

local surrenderedSoul
function MplusLedger:HandlePossiblePlayerDeath(event, destGUID, destName, destFlags)
  if self:IsRunningMythicPlus() and event == "UNIT_DIED" and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
    if not surrenderedSoul then
      surrenderedSoul = GetSpellInfo(self.Wow.SpellIds.SurrenderedSoul)
    end

    local unitIsFeignDeath = UnitIsFeignDeath(destName)
    local unitSurrenderedSoul = UnitDebuff(destName, surrenderedSoul) == surrenderedSoul

    if not unitIsFeignDeath and not unitSurrenderedSoul then
      for index, partyMember in pairs(self.db.char.currentDungeon.party) do
        if partyMember.guid == destGUID then
          local deathCount = self.db.char.currentDungeon.party[index].deathCount 

          self.db.char.currentDungeon.party[index].deathCount = deathCount + 1
        end
      end
    end
  end
end

function MplusLedger:CurrentDungeon()
  return self.db.char.currentDungeon
end

function MplusLedger:FinishedDungeons()
  local finishedRuns = self.db.char.finishedMythicRuns
  if finishedRuns == nil then
    return {}
  else
    return finishedRuns
  end
end

function MplusLedger:DungeonTotalRuntime(dungeon)
  return difftime(dungeon.endedAt or time(), dungeon.startedAt)
end

function MplusLedger:DungeonTotalRuntimeWithDeaths(dungeon)
  local totalRuntime = self:DungeonTotalRuntime(dungeon)
  local totalDeaths = self:DungeonTotalDeathCount(dungeon)
  local totalTimeLostToDeath = totalDeaths * 5

  return totalRuntime + totalTimeLostToDeath
end

function MplusLedger:DungeonTotalDeathCount(dungeon)
  local count = 0

  for _, partyMember in pairs(dungeon.party) do
    count = count + partyMember.deathCount
  end

  return count
end

local function PrimeDungeonInfoCache(challengeMapId)
  if not cache.dungeonInfo[challengeMapId] then
    cache.dungeonInfo[challengeMapId] = {}
  end
end

function MplusLedger:DungeonName(dungeon)
  local challengeMapId = dungeon.challengeMapId
  PrimeDungeonInfoCache(challengeMapId)
  if not cache.dungeonInfo[challengeMapId].name then
    cache.dungeonInfo[challengeMapId].name = C_ChallengeMode.GetMapInfo(challengeMapId)
  end

  return cache.dungeonInfo[challengeMapId].name
end

function MplusLedger:DungeonTimeLimit(dungeon)
  local challengeMapId = dungeon.challengeMapId
  PrimeDungeonInfoCache(challengeMapId)
  if not cache.dungeonInfo[challengeMapId].timeLimit then
    local _, _, timeLimit = C_ChallengeMode.GetMapInfo(challengeMapId)
    cache.dungeonInfo[challengeMapId].timeLimit = timeLimit
  end

  return cache.dungeonInfo[challengeMapId].timeLimit
end

function MplusLedger:DungeonTimeLimitBoostTwo(dungeon)
  local challengeMapId = dungeon.challengeMapId
  PrimeDungeonInfoCache(challengeMapId)
  if not cache.dungeonInfo[challengeMapId].timeLimitBoostTwo then
    local timeLimit = self:DungeonTimeLimit(dungeon)
    cache.dungeonInfo[challengeMapId].timeLimitBoostTwo = timeLimit * self.Wow.TwoBoostPercentage
  end

  return cache.dungeonInfo[challengeMapId].timeLimitBoostTwo
end

function MplusLedger:DungeonTimeLimitBoostThree(dungeon)
  local challengeMapId = dungeon.challengeMapId
  PrimeDungeonInfoCache(challengeMapId)
  if not cache.dungeonInfo[challengeMapId].timeLimitBoostThree then
    local timeLimit = self:DungeonTimeLimit(dungeon)
    cache.dungeonInfo[challengeMapId].timeLimitBoostThree = timeLimit * self.Wow.ThreeBoostPercentage
  end

  return cache.dungeonInfo[challengeMapId].timeLimitBoostThree
end

function MplusLedger:DungeonAffixNames(dungeon)
  local affixes = {}
  for _, affixId in pairs(dungeon.affixes) do
    if not cache.affixInfo[affixId] then
      local name = C_ChallengeMode.GetAffixInfo(affixId)
      cache.affixInfo[affixId] = name
    end
    table.insert(affixes, cache.affixInfo[affixId])
  end

  return affixes
end

function MplusLedger:IsRunningMythicPlus()
  return self.db.char.currentDungeon ~= nil
end

function MplusLedger:DungeonBoostProgress(dungeon)
  if dungeon.state == "failed" then
    return -1
  end

  local timeLimit = self:DungeonTimeLimit(dungeon)
  local plusTwo = self:DungeonTimeLimitBoostTwo(dungeon)
  local plusThree = self:DungeonTimeLimitBoostThree(dungeon)
  local totalRuntimePlusDeaths = self:DungeonTotalRuntimeWithDeaths(dungeon)
  
  if not dungeon.endedAt then
    return 0
  elseif totalRuntimePlusDeaths <= plusThree then
    return 3
  elseif totalRuntimePlusDeaths <= plusTwo then
    return 2
  elseif totalRuntimePlusDeaths <= timeLimit then
    return 1
  else
    return -1
  end
end

function MplusLedger:FetchKeystoneFromBags()
  for container=BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(container)
		for slot=1, slots do
      local textureId, _, _, _, _, _, slotLink = GetContainerItemInfo(container, slot)
			local itemString = slotLink and slotLink:match("|Hkeystone:([0-9:]+)|h(%b[])|h")
      if itemString then
        local info = { strsplit(":", itemString) }
        local name = C_ChallengeMode.GetMapInfo(info[1])
        local mapLevel = tonumber(info[2])

        local affixes = {}
        for _, affixId in ipairs({info[3], info[4], info[5]}) do
          local affixName = C_ChallengeMode.GetAffixInfo(affixId)
          table.insert(affixes, affixName)
        end

        return {
          name = name,
          mythicLevel = mapLevel,
          affixes = affixes
        }
			end
		end
	end
end

function MplusLedger:StoreKeystoneFromBags()
  local keystone = self:FetchKeystoneFromBags()
  local characterName = UnitName("player")
  local _, classToken = UnitClass("player")
  local level = UnitLevel("player")

  if level == 110 then
    if not self.db.realm.keystones then
      self.db.realm.keystones = {}
    end
  
    self.db.realm.keystones[characterName] = {
      keystone = keystone,
      classToken = classToken
    }
  end
end

function MplusLedger:GetSpecificCharacterKeystone()
  local characterName = UnitName("player")

  if not self.db.realm.keystones then 
    return 
  end

  return self.db.realm.keystones[characterName]
end

function MplusLedger:GetCurrentKeystones()
  return self.db.realm.keystones or {}
end

function MplusLedger:SendPartyYourKeystone()
  local stoneInfo = self:GetSpecificCharacterKeystone()
  local characterName, realm = UnitName("player")
  if not realm then
    realm = GetRealmName()
  end
  local _, classToken = UnitClass("player")
  local level = UnitLevel("player")
  local message = characterName .. "," .. realm .. "," .. classToken .. ","

  if level == 110 then
    if stoneInfo.keystone then
      message = message .. stoneInfo.keystone.mythicLevel .. "," .. stoneInfo.keystone.name
    else
      message = message .. 0 .. ","
    end
    self:SendCommMessage("MplusLedger", message, "PARTY")
  end
end

function MplusLedger:GetPartyMemberKeystones()
  return self.db.char.currentParty
end

function MplusLedger:ResetCurrentParty()
  self.db.char.currentParty = {}
end

function MplusLedger:SavePartyMemberKeystone(partyMemberString)
  local characterName, realm, classToken, mythicLevel, dungeon = strsplit(",", partyMemberString)
  if not self.db.char.currentParty then
    self.db.char.currentParty = {}
  end

  self.db.char.currentParty[characterName] = {
    name = characterName,
    realm = realm,
    classToken = classToken,
    mythicLevel = mythicLevel,
    dungeon = dungeon
  }
end

function MplusLedger:ClearRemovedPartyMembers()
  local units = {"party1", "party2", "party3", "party4"}
  local unitNames = {}
  for unit in ipairs(units) do
    local characterName = UnitName(unit)
    table.insert(unitNames, characterName)
  end

  for storedCharacterName, _ in pairs(self.db.char.currentParty) do
    if unitNames[storedCharacterName] == nil then
      self.db.char.currentParty[storedCharacterName] = nil
    end
  end
end

function MplusLedger:CheckForPartyKeyResync()
  self:SendCommMessage("MplusLedger", MplusLedger.CommMessages.ResyncKeys, "PARTY")
end

function MplusLedger:ProcessAddonMessage(message)
  local knownCommands = {}
  knownCommands[self.CommMessages.ResyncKeys] = function()
    self:SendPartyYourKeystone()
  end

  if knownCommands[message] ~= nil then
    knownCommands[message]()
  else
    MplusLedger:SavePartyMemberKeystone(message)
  end
end

function MplusLedger:CountTable(table)
  local count = 0
  if type(table) == "table" then
    for _ in pairs(table) do
      count = count + 1
    end
  end

  return count
end

function MplusLedger:SendPartyKeystonesToChat()
  local keystones = MplusLedger:GetPartyMemberKeystones()
  local numGroupMembers = GetNumGroupMembers()
  if numGroupMembers > 1 then
    if not keystones then
      SendChatMessage("M+ Ledger could not find any keys in this party. Go run a Mythic! Or if you feel this is an error please submit a bug.")
    else
      SendChatMessage("M+ Ledger found the following keys in this party:", "PARTY")
      for _, partyMemberKeystone in pairs(keystones) do
        local name = partyMemberKeystone.name
        if partyMemberKeystone.mythicLevel == "0" then
          SendChatMessage(name .. ": Does not have a key", "PARTY")
        else
          SendChatMessage(name .. ": +" .. partyMemberKeystone.mythicLevel .. " " .. partyMemberKeystone.dungeon, "PARTY")
        end
      end
    end
  else
    print(ColorText:Red("You may not list a party's keys when not in a party!"))
  end
end

local commandMapping = {
  show = function(...)
    MplusLedger:ToggleFrame()
  end,

  keys = function(...)
    MplusLedger:ToggleFrame("keys")
  end,

  history = function(...)
    MplusLedger:ToggleFrame("history")
  end,

  reset = function(...)
    if MplusLedger:IsRunningMythicPlus() then
      MplusLedger:EndMythicPlusAsFailed("Dungeon was intentionally reset using the /mplus reset command")
    end
  end,

  button = function(...)
    args = {...}
    if args[1] == "on" or args[1] == "show" then
      icon:Show("MplusLedger")
    elseif args[1] == "off" or args[1] == "hide" then
      icon:Hide("MplusLedger")
    end
  end,

  help = function(...)
    local commands = {
      help = "Show this list of commands.",
      reset = "Force the reset of your currently running dungeon.",
      show = "Show the current dungeon for your M+ Ledger",
      button = "(on|off|show|hide) Pass an option to show or hide the minimap button",
      keys = "Show the keystones you ahve for your characters",
      party = "Show in party chat what keys your party members have; party members must have M+ Ledger installed for this to function",
      config = "Show the options for this addon"
    }
  
    print(ColorText:Yellow(MplusLedger:Title() .. " v" .. MplusLedger:Version()))
    for command, description in pairs(commands) do
      print("/mplus " .. command .. " - " .. description)
    end
  end,

  party = function(...)
    MplusLedger:SendPartyKeystonesToChat()
  end,

  config = function(...)
    AceConfigDialog:Open("M+ Ledger")
  end
}

function MplusLedger:ProcessChatCommand(args)
  local command, commandArg1 = self:GetArgs(args, 2)
  local func = commandMapping[command]
  local deprecatedCommands = {
    keys = "Use minimap button or the chat command /mplus show.",
    history = "Use minimap button or the chat command /mplus show.",
    button = "Please use the addon options for this by using Blizzard's default addon UI or by right-clicking the minimap button."
  }
  if func then
    func(commandArg1)
    if deprecatedCommands[command] ~= nil then
      print(ColorText:Red("Warning! This command is deprecated and will be removed in the next version of M+ Ledger!"))
      print(deprecatedCommands[command])
    end
  else
    print(ColorText:Red("You MUST pass something valid to the /mplus command"))
    ShowChatCommands()
  end
end