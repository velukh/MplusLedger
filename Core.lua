--[[
MplusLedger

A WoW addon to keep long-term track of a player's Mythic+ runs so they may analyze how they're doing for 
a given spec, dungeon, affixes, level, and party composition.

@copyright Velukh 2017
--]]
MplusLedger = LibStub("AceAddon-3.0"):NewAddon(
	"MplusLedger",
	"AceConsole-3.0",
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

MplusLedger.Title = "MplusLedger"
MplusLedger.Version = "0.1.0"
MplusLedger.ShowingMainFrame = false

MplusLedger.Events = {
	ShowMainFrame = "MPLUS_SHOW_MAIN_FRAME",
	HideMainFrame = "MPLUS_HIDE_MAIN_FRAME",
	RedrawSelectedTab = "MPLUS_REDRAW_SELECTED_TAB"
}

MplusLedger.Wow = {
	SpellIds = {
		SurrenderedSoul = 212570
	}
}

local next = next

function MplusLedger:OnInitialize()
	local defaults = {}
	self.db = LibStub("AceDB-3.0"):New("MplusLedgerDB", defaults)
	if not self.db.char.version then
		self.db.char.version = MplusLedger.Version
	end
end

local function ResetMythicPlusRuns()
	if MplusLedger:IsRunningMythicPlus() then
		MplusLedger:EndMythicPlusAsFailed("The instance was intentionally reset, likely in an effort to lower the key level.")
	end
end

function MplusLedger:OnEnable()
	self:SecureHook("ResetInstances", ResetMythicPlusRuns)
end

function MplusLedger:ToggleFrame(tabToShow)
	if MplusLedger.ShowingMainFrame then
		MplusLedger:SendMessage(MplusLedger.Events.HideMainFrame)
	else
		MplusLedger:SendMessage(MplusLedger.Events.ShowMainFrame, tabToShow)
	end
end

function MplusLedger:StartMythicPlus(challengeMapId)
	if not challengeMapId then 
		error("MplusLedger encountered an error attempting to start your dungeon")
		return 
	end
	local currentDungeon = {
		state = "running",
		challengeMapId = challengeMapId,
		mythicLevel = nil,
		affixes = nil,
		startedAt = nil,
		endedAt = nil,
		runTime = nil,
		party = {}
	}

	local level, affixes = C_ChallengeMode:GetActiveKeystoneInfo()

	currentDungeon.mythicLevel = level
	currentDungeon.affixes = affixes
	currentDungeon.startedAt = time()

	self.db.char.currentDungeon = currentDungeon

	local partyUnits = {"player", "party1", "party2", "party3", "party4"}
	for _, unitId in ipairs(partyUnits) do
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
end

local function storeAndResetCurrentDungeon(ledger)
	ledger.db.char.currentDungeon.endedAt = time()
	local currentDungeon = ledger.db.char.currentDungeon
	local dungeonId = currentDungeon.dungeonId

	if not ledger.db.char.finishedMythicRuns then
		ledger.db.char.finishedMythicRuns = {}
	end

	table.insert(ledger.db.char.finishedMythicRuns, currentDungeon)
	ledger.db.char.currentDungeon = nil
end

function MplusLedger:EndMythicPlusAsCompleted(recordTime)
	if not MplusLedger:IsRunningMythicPlus() then
		return
	end

	self.db.char.currentDungeon.state = "success"
	self.db.char.currentDungeon.runTime = recordTime
	storeAndResetCurrentDungeon(self)
end

function MplusLedger:EndMythicPlusAsFailed(failureReason)
	if not MplusLedger:IsRunningMythicPlus() then
		return
	end

	self.db.char.currentDungeon.state = "failed"
	self.db.char.currentDungeon.failureReason = failureReason
	storeAndResetCurrentDungeon(self)
end

local surrenderedSoul
function MplusLedger:HandlePossiblePlayerDeath(event, destGUID, destName, destFlags)
	if MplusLedger:IsRunningMythicPlus() and event == "UNIT_DIED" and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
		if not surrenderedSoul then
			surrenderedSoul = GetSpellInfo(MplusLedger.Wow.SpellIds.SurrenderedSoul)
		end

		local unitIsFeignDeath = UnitIsFeignDeath(destName)
		local unitSurrenderedSoul = UnitDebuff(destName, surrenderedSoul) == surrenderedSoul

		if not unitIsFeignDeath and not unitSurrenderedSoul then
			for index, partyMember in ipairs(self.db.char.currentDungeon.party) do
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

function MplusLedger:DungeonTotalDeathCount(dungeon)
	local count = 0

	for _, partyMember in ipairs(dungeon.party) do
		count = count + partyMember.deathCount
	end

	return count
end

function MplusLedger:IsRunningMythicPlus()
	return self.db.char.currentDungeon ~= nil
end

local function YellowText(text)
    return "|cFFFFFF00" .. text .. "|r"
end

function MplusLedger:ShowChatCommands()
	local commands = {
		help = "Show this list of commands.",
		reset = "Force the reset of your currently running dungeon.",
		show = "Show the current dungeon for your Mythic+ Ledger",
    history = "Show the history for your Mythic+ Ledger"
	}

	print(YellowText("Mplus Ledger v" .. MplusLedger.Version))
	for command, description in pairs(commands) do
		print("/mplus " .. command .. " - " .. description)
	end
end