## 1.2.1
* Fixed to work with updated version of cursehelper (guide in last updated log is no longer needed)
* Removed mini curse hud as it is now used in cursehelper

## 1.2.0
* now multiplayer compatible (for now go into cursehelper main.lua and set "mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()" to "mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true))"
* e8 curse now shows up on the minihud
* nerfed e6 (chest prices to +30%)
* nerfed e7 (cooldown reduction to -40%)
* reworked e1 to last 60 seconds and changed scaling, also made description more accurate
* excluded imps from e7
* excluded trokks from e4
* fix tp not requiring boss kill if you killed a boss (anything with bossbar) before activating tp
* fixed crash after beating e8 without starstorm installed
* probably fixed weird sound bug

## 1.1.13
* fixed error spam with last version

## 1.1.12
* reduced enemy credits gain by 40% when tp is at 99%
* nerfed e4 speed gain to 15%

## 1.1.11
* fixed dios not reseting curse
* killing the boss at 99% charge now finishes the tp event

## 1.1.10
* fixed e8 curse

## 1.1.9
* removed e7
* swapped e5 (chest prices) and e6 (healing reduction)
* alt e6 (eclipse level buffs) -> alt e7
* alt e7 (enemy damage) -> alt e5
* alt e5 (empty chests) -> alt e6
* nerfed e4 +60% chest prices -> +40% chest prices
split e4 into +20% speed (e4) and -50% enemy cooldowns (e7)

## 1.1.8
* Added new e7: Enemy credit scaling +25%
* moved previous e7 to alt e7
* moved previous alt e7 to alt e6
* nerfed alt e6 (buffs all eclipse levels)

## 1.1.7
* increased curse apply threshhold to 5% maxhp

## 1.1.6
* e6 is now alt e8
* alt e6 is now normal e6
* enemies spawned by e1 now drop 50% less gold
* e2 teleporter radius only disappears after boss has been killed
* alt e5 time between chests emptied increased to 3 minutes from 2

## 1.1.5
* swapped alt eclipse 6 and 7

## 1.1.4
* Added alt eclipse levels
* 1) Ally Starting Health: -50%
* 5) Every 2 Minutes Empty 1 Random Chest
* 6) Buffs All Eclipse Modifiers
* 7) Ally Healing: -50%
* Eclipse 4: Nerfed speed to 20%
* Eclipse 7: Nerfed Damage to 25%
* Eclipse 8: Extra damage from e7 doesn't apply curse
* Fixed bug with e3 that let enemies drop gold after the tp event
* Reworked e6 artifact display
* Prestige now starts at 2 mountain buffs
* Cognation stage credits increased by 20%
* Tempus now gives 5 Items
* Origin: reduced the amount of Vanguards spawning, increased vanduard damage

## 1.1.3
* Added eclipse 9 back into the game, now working (requires starstorm installed)
* Artifact textures and descriptions

## 1.1.2
* Fixed more errors when you had too many artifact mods installed
* Each eclipse modifier can now be turned on individually with artifacts
* You can hide eclipse artifacts with the imgui window
* removed eclipse 9, since it cannot be unlocked

## 1.1.1
* Fixed error that would occur when not having an artifact mod installed
* Amount of Artifacts now increases every 5 stages instead of every 6
* Amount of Active Artifacts in e6 capped to 3

## 1.1.0
* Eclipse 6 now works with modded artifacts. Unlike base game artifacts, these need to be enabled to get added to the artifact pool (may break for some artifacts)
* This also works for adding enigma and command back to the artifact pool
* Prestige changes now only apply before activating the teleporter
* You now can't get the same artifact again before getting every other artifact
* Increased sacrifice drop chance

## 1.0.8
* Fixed some issues with prestige
* swapped eclipse 6 and 7

## 1.0.7
* fixed enemies not dropping any gold

## 1.0.6
* Made eclipse 1 slightly easier again
* Eclipse 6 enemy damage reduced to +30%
* Fixed eclipse 7 not working without specific dependency

## 1.0.5
* Rebalanced some artifacts (see readme)
* Slightly increased eclipse 2 difficulty
* Reorganized code
* A bunch of bug and error fixes

## 1.0.4
* Replaced Eclipse 7 (Enemy cooldowns -50%) with Activate a Random Artifact every Stage
* View readme for explanations on some artifact changes
* Eclipse 4 now also reduces enemy cooldowns by 25%
* Made Eclipse 1 slightly harder
* Eclipse 5 Enemy damage reduced to +40% from +50%

## 1.0.3
* Eclipse 6 now only gives enemies 50% more damage and not health

## 1.0.1
* Fixed dependencies
* nerfed eclipse 3 in the provi fight

## 1.0.0
* Initial release