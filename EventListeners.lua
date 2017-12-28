local MplusLedger = MplusLedger
local ColorText = LibStub("MplusLedgerColorText-1.0")

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.ChallengeModeStarted, function(_, dungeonId)
  -- it is possible for this even to fire while the mythic+ is ongoing if the player 
  -- logs out and back... silently handle this scenario and do not replay init
  if not MplusLedger:IsRunningMythicPlus() then
    MplusLedger:StartMythicPlus(C_ChallengeMode.GetActiveChallengeMapID())
  end
end)

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.ChallengeModeCompleted, function()
  MplusLedger:EndMythicPlusAsCompleted()
  MplusLedger:StoreKeystoneFromBags()
end)

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.PlayerEnteringWorld, function()
  MplusLedger:StoreKeystoneFromBags()
  local numMembers = GetNumGroupMembers()
  if numMembers == 0 then
    MplusLedger:ResetCurrentParty()
  elseif numMembers > 1 and MplusLedger:IsRunningMythicPlus() then
    MplusLedger:ClearRemovedPartyMembers()
    MplusLedger:SendPartyYourKeystone()
    MplusLedger:CheckForPartyKeyResync()
  end
end)

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.GroupRosterUpdate, function()
  local numMembers = GetNumGroupMembers()
  if numMembers == 0 then
    MplusLedger:ResetCurrentParty()
  else
    MplusLedger:ClearRemovedPartyMembers()
    MplusLedger:SendPartyYourKeystone()
    MplusLedger:CheckForPartyKeyResync()
  end
end)

MplusLedger:RegisterEvent("CHAT_MSG_LOOT", function(event, ...)
  local LOOT_ITEM_SELF_PATTERN = _G.LOOT_ITEM_SELF
  LOOT_ITEM_SELF_PATTERN = LOOT_ITEM_SELF_PATTERN:gsub('%%s', '(.+)')
  local LOOT_ITEM_PATTERN = _G.LOOT_ITEM
  LOOT_ITEM_PATTERN = LOOT_ITEM_PATTERN:gsub('%%s', '(.+)')
  local message, _, _, _, looter = ...
	
	local lootedItem = message:match(LOOT_ITEM_SELF_PATTERN)
	if lootedItem == nil then
		_, lootedItem = message:match(LOOT_ITEM_PATTERN)
  end
  
  if lootedItem then
    MplusLedger:StoreReceivedLoot(lootedItem, looter)
    if MplusLedger.lootGroup then
      MplusLedger.lootGroup:ReleaseChildren()
      MplusLedger:DrawLootedItems(MplusLedger.completedDungeon)
    end
  end
end)

MplusLedger:RegisterMessage(MplusLedger.Events.TrackingStopped, function(_, dungeon)
  local stateMsg
  if dungeon.state == "failed" then
    stateMsg = "failed"
  else
    stateMsg = "successful"
  end
  print(ColorText:Yellow(MplusLedger:Title()) .. ": Stored your " .. stateMsg .. " M+!")
end)

MplusLedger:RegisterMessage(MplusLedger.Events.TrackingStarted, function(_, dungeon)
  local name = C_ChallengeMode.GetMapInfo(dungeon.challengeMapId)
  print(ColorText:Yellow(MplusLedger:Title()) .. ": Tracking your " .. name .. " +" .. dungeon.mythicLevel)
end)

MplusLedger:RegisterComm("MplusLedger", function(_, message)
  MplusLedger:ProcessAddonMessage(message)
end)
