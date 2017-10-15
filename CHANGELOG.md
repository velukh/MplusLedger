# Changelog

## v0.4.0

- Fix when a player has died 1 time to use proper grammar
- Add a total time lost to death stat onto each run.
- Added the amount of time it would take to clear, 2-chest or 3-chest a key
- Added a message in chat when the dungeon has started and stopped tracking.
- Updated Current Dungeon tab to show the total run time *from the moment you opened
  the MplusLedger window*. This is not a running timer and is not meant to track 
  your progress in real time.
- Changed sorting of History tab to show most recent dungeon first.
- [BUGFIX] Fixed a bug where a user could disconnect during a M+ and have their run 
  improperly marked as failed
- [BUGFIX] Fixed a bug where the calculation for determining if the key was 2-chested or 
  3-chested did not propertly take into account the time lost to deaths.
- [BUGFIX] Fixed a bug where the run time calculation was not taking into account the 10 
  second window before the M+ actually begins.

## v0.3.1

- [BUGFIX] Fixes the Current Dungeon tab to display properly by properly handling endedAt being nil

## v0.3.0

- Add amount of time the run took as well as when the run ended to the UI for each dungeon
- Determine whether or not the dungeon was completed +1, +2 or +3 and display accordingly
- Disable ability to resize the main window to ensure UI consistency

## v0.2.0

- Adjusts the dungeon display to show basic information about dungeon, level, affixes and party members

## v0.1.0

- Initial UI frame showing basically raw output of the current M+ and previously ran M+
- Tracks the following pieces of information about each M+:
  - Dungeon
  - Level
  - Affixes
  - Date
  - Run Time
  - Party members (class, race, sex, realm, GUID)
  - Total and individual death counts for the run
