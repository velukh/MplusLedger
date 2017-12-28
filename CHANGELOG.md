# Changelog

This project adheres to [Semantic Versioning 2.0](http://semver.org/) (semver). We are 
currently in 0.y.x development and there may be breaking changes between minor releases, 
though we strive to limit breaking changes as much as possible.

## v0.6.2 - 2017-12-27

#### Fixed

- Bug where being in a raid could cause erroneous errors trying to parse out party member's keys.

## v0.6.1 - 2017-12-26

#### Fixed

- Bug where if a user had unchecked 'Show party members and other characters with no keys' and had 
no other characters with keys the minimap tooltip would still show the label 'Other characters:'

## v0.6.0 - 2017-12-25

#### Added

- Added ability to view party member keys if they also have M+ Ledger installed. You may 
view party member keys in the new "Party Keys" tab in your M+ Ledger, in the minimap button while 
you're in a party, and by executing "/mplus party" which will output your party member's keys to chat.
- Added a new config window to allow various settings to be changed. You can open up the config window 
by right clicking the minimap button, by executing "/mplus config", or by going into the default 
Blizzard addon configuration. Currently you may set the following options:
  - Show or hide the minimap button
  - Show or hide character with no keys in the tooltip and 'Your Keys' section. This will not impact 
  the currently logged in character; they will always display regardless of whether or not they have 
  a key.
  - Show or hide party members in minimap button.

#### Changed

- Reordered the tabs in the ledger to prioritize the keys you have across your characters as 
well as the keys your party members may have.
- Redesigned the tooltip and 'Your Keys' tab section to always show the character you're currently 
logged in at the top.
- Changed the M+ Ledger minimap butto from a custom icon to the same icon used for MYthic keystones.

#### Deprecated

- Deprecated the below chat commands. They will be removed in the next version of the addon. 
Additionally they will output an additional deprecation message warning of there removal as well 
as alternatives that you should use in its place. 
  - /mplus history
  - /mplus keys
  - /mplus button

## v0.5.0 - 2017-10-28

#### Added

- Added a new 'Your Keys' tab that allows you to track what keys you have across all 
of your characters. *Please note that the key will not appear until you have logged onto 
that character each week.*
- Added a minimap button to show your keystones as a tooltip and to open the main ledger window when clicked on. You may turn the button off with /mplus button off and turn it back on with /mplus button on.

#### Changed

- Updated the title shown in the WoW interface to "M+ Ledger"
- Several improvements to clean up the internal codebase, no user-facing functionality should change
- Refactors how the addon was getting version and title information to pull directly from .toc file

#### Fixed

- Possible bug where an event handler for checking deaths is not properly unregistered if the run fails.
- Possible bug where a succesful key may not be marked as completed properly.

## v0.4.0 - 2017-10-15

#### Added

- For each dungeon the total amount of time lost to death added to display.
- For each dungeon display the amount of time it would take to complete on time, +2 or +3
- A message will appear in chat when the ledger has stopped or started tracking a run.

#### Changed

- Updated Current Dungeon tab to show the total run time *from the moment you opened
  the MplusLedger window*. This is not a running timer and is not meant to track 
  your progress in real time.
- Changed sorting of History tab to show most recent dungeon first.

#### Fixed

- Bug where a user could disconnect during a M+ and have their run 
  improperly marked as failed
- Bug where the calculation for determining if the key was 2-chested or 
  3-chested did not propertly take into account the time lost to deaths.
- Bug where the run time calculation was not taking into account the 10 
  second window before the M+ actually begins.
- When a player has died only 1 time use appropriate grammar

## v0.3.1 - 2017-10-14

#### Fixed

- Current Dungeon tab displays properly by handling endedAt being nil

## v0.3.0 - 2017-10-13

#### Added

- Add amount of time the run took as well as when the run ended to the UI for each dungeon
- Determine whether or not the dungeon was completed +1, +2 or +3 and display accordingly

#### Changed

- Disable ability to resize the main window to ensure UI consistency

## v0.2.0 - 2017-10-12

#### Changed

- Adjusts the dungeon display to show basic information about dungeon, level, affixes and party members

## v0.1.0 - 2017-10-06

#### Added

- Initial UI frame showing basically raw output of the current M+ and previously ran M+
- Tracks the following pieces of information about each M+:
  - Dungeon
  - Level
  - Affixes
  - Date
  - Run Time
  - Party members (class, race, sex, realm, GUID)
  - Total and individual death counts for the run
