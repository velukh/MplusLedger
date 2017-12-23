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
			local _, _, _, _, _, _, slotLink = GetContainerItemInfo(container, slot)
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

  return self.db.realm.keystones[characterName].keystone
end

function MplusLedger:GetCurrentKeystones()
  return self.db.realm.keystones or {}
end

function MplusLedger:SendPartyYourKeystone()
  local keystone = self:GetSpecificCharacterKeystone()
  local characterName, realm = UnitName("player")
  if not realm then
    realm = GetRealmName()
  end
  local _, classToken = UnitClass("player")
  local level = UnitLevel("player")
  local message = characterName .. "," .. realm .. ","

  if level == 110 then
    if keystone then
      message = message .. keystone.mythicLevel .. "," .. keystone.name
    else
      message = message .. 0 .. ","
    end
    self:SendMessage("MplusLedger", message, "PARTY")
  end
end