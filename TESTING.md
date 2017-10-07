# Testing MplusLedger

Right now MplusLedger is still in active development and needs thorough testing over all of its features and 
UI. Currently we're in a phase where gathering and storing the data accurately is priority #1; any UI implementations 
at this point will be basic and meant only to facilitate testing of the data storage.

If you install the addon at this point it is highly recommended that you participate in the testing process to help 
speed development to a stable version.

## How can I test?

1. Ensure that the data collected matches the M+ you have recently ran.
	In the M+ look at the Current Dungeon tab and ensure that things like the Dungeon, Level, Affixes, Start date, and
	party member info is accurate. After you've finished a M+ ensure the Current Dungeon and History tabs are updated 
	appropriately.

2. If you encounter any bugs let me know!
	If you haven't done so already you should check out the Problems or Bugs section of the README; for reporting testing 
	bugs or feedback the same process applies. I highly recommend checking out [BugGrabber](https://mods.curse.com/addons/wow/bug-grabber) 
	and [BugSack](https://mods.curse.com/addons/wow/bugsack) for dealing with those nasty error messages.

3. Give me yo dataz!
	The more data I can look at and analyze for potential improvements and to serve as a testbed for future development 
	the better! It would be awesome if you could send me your MplusLedger data file. You can find this by copying the 
	following file and <a href="mailto:velukh.gaming@gmail.com">emailing it to velukh.gaming@gmail.com</a>.

	```
	YOUR_INSTALL_DIR/World of Warcraft/WTF/Account/YOUR_ACCOUNT_NAME/SavedVariables/MplusLedger.lua
	```

	Where exactly YOUR_INSTALL_DIR and YOUR_ACCOUNT_NAME is for your computer is dependent on where you installed 
	World of Warcraft and, well, what your account name is. This file is ultimately what stores all the data that 
	MplusLedger shows. If you wish to reset your data during testing simply remove this file, and the accompanying, 
	MplusLedger.bak and you will have effectively reset your MplusLedger to a fresh state.