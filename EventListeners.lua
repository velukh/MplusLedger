MplusLedger:RegisterEvent("CHALLENGE_MODE_START", function(_, dungeonId)
  -- it is possible for this even to fire while the mythic+ is ongoing if the player 
  -- logs out and back... silently handle this scenario and do not replay init
  if not MplusLedger:IsRunningMythicPlus() then
    MplusLedger:StartMythicPlus(C_ChallengeMode.GetActiveChallengeMapID())  
    MplusLedger:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(_, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags)
      MplusLedger:HandlePossiblePlayerDeath(event, destGUID, destName, destFlags)
    end)
  end
  
end)

-- Marks the currently running dungeon as having completed successfully, successfully here 
-- means that a chest was received at dungeon completion... regardless of timer.
--
-- Please note that there is a CHALLENGE_MODE_COMPLETED event that is fired immediately before 
-- this that we are ignoring because this event includes more details about the run, namely the 
-- amount of time it took.
MplusLedger:RegisterEvent("CHALLENGE_MODE_NEW_RECORD", function(_, _, recordTime)
  MplusLedger:EndMythicPlusAsCompleted(recordTime)
  MplusLedger:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end)