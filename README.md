# factorio-tacticalConstruction

Source repository for the Factorio mod Tactical Construction.

## Description

Tactical Construction is a mod for the video game [Factorio](https://factorio.com/). It provides a per-player toggle that - when enabled - prioritizes the local player's roboport for construction requests (as opposed to allowing construction requests to be satisfied by any statically-placed logistics network that overlaps inside the player's mobile roboport).

Tactical Construction on the Factorio mod portal: https://mods.factorio.com/mod/TacticalConstruction

**CAUTION: This mod is still in BETA; you may encounter crashes/corruption.**

## Usage Instructions

1. Look for the Tactical Construction toggle button (currently in the upper-left corner of the screen):
   - When disabled, looks like this:
   ![Tactical Construction toggle button - disabled](src/graphics/toggle-icon-disabled.png)
   - When enabled, looks like this:
   ![Tactical Construction toggle button - enabled](src/graphics/toggle-icon-enabled.png)
2. Have a personal roboport in your player's armor, construction robots and supplies for building in inventory, etc. Just like normal.
3. Keep the Tactical Construction button toggled off under regular play.
4. Upon encountering an issue where your base's robot network is scheduled to build something that you want to build w your player, toggle the button on:
   - When enabled, your player and any entities needing construction around you will be transported to an 'alternative' force in the game that is auto-created and - to the maximum extent possible - synced with your regular force.
   - However, even allied forces don't fulfill each-other's construction requests. This means your player's robots will handle the construction despite your base's network overlapping.
   - As you move, now-out-of-range entities are sent back to your base's primary force. And new in-range entities needing construction are moved to the alternative force.
5. Once the construction is complete, toggle off the button. You will be sent back to your primary force and any as-yet alternate-force entities will be reverted along with you.

## Considerations

1. This mod auto-creates one alternative (allied) force per each player force. In most games there is one player force (thus, only one alternative force will be created); however, this mod tries to handle scenarios where there are multiple player forces (each getting its own alternate force).
2. Due to the alternate force behavior, once you save your game with this mod active, it's probably not advisable to disable the mod on that save file moving forward.  Tactical Construction makes a point to clean up any alternative forces when there are no longer any connected players that might use them; however, if you disable the mod, that logic will of course not be able to run to clean up any alternative forces that were still determined to be needed at the point of save.
   - I **may** eventually add a console command that can be used to tell the mod to clean itself up and go into a permanent 'zombie' state. This could be run right before saving the game, after which the mod could be disabled. File a Github issue if something like this would be of use to you.

## Limitations

1. Deconstruction: Does not work with to-be-deconstructed entities. At present there's no efficient way to find entities marked for deconstruction. Enhancement request has been submitted here: https://forums.factorio.com/viewtopic.php?t=82643
   1. In the mean time, I may eventually experiment with iterating through entities and manually filtering them to find ones marked for deconstruction.
2. Base entity disco: At present, a force's "color" (i.e. the color applied to all entities on that force) appears to be automatically equivalent to the color of the first player member of the force. As a result, when player #1 in a multiplayer game toggles the feature (and gets moved to the alternative force), the primary force color will change to player #2's color. Upon player #1 toggling the feature off, the force color reverts. Thus, you get a sort of "light show" every time player #1 uses this feature.
   1. Enhancement request submitted here: https://forums.factorio.com/viewtopic.php?t=82644
   2. Workaround: Set player colors to the same value :-)
3. Map fog-of-war: When players have the feature enabled, they are moved to a different force in the game. This means that the discovered areas of the map will be reset. I've enabled map sharing between the two forces, but it only seems to share scans of a sector upon next active scan. Thus, your map will likely be significantly-less explored while you have the feature on.
4. Force weapon attributes: At present I don't sync a bunch of force damage attributes from the primary force over the the alternative one. So if you're gonna fight, maybe toggle the feature off first :-)

## Technical Details

When a player joins, the mod reads their 'force' attribute and creates an 'alternative' version of that force.  When the feature is toggled on (via the button at top-left of the screen), the player and all ghost or to-be-upgraded entities in range of the player's roboport are transported to the alternative force.  Upon disabling the feature, the player and all nearby entities are sent 'home' to the original force.

This seems like it should be pretty trivial (which is why I naively set out to make this mod), but actually there are a few problems:

1. The alternative force needs to have the various technologies and resulting stats from the primary force synced over:
   1. To make this happen, I copied a bunch of code from LogiNetChannels: https://github.com/ceresward/factorio-logiNetChannels
2. Upon moving a player to a different force, the player's follower construction robots get 'orphaned'.  I thus went through rather great lengths to port the robots over and reattach them to the player.
3. When the player moves and the feature is toggled on, of course the 'in range' entities change.  We therefore need to revert any now-out-of-range entities back to the pimary force so that they aren't sitting there unserviced forever (that would be just plain rude).  We preserve the player's previous bounding box, but we of course don't want to revert any still-in-range entities (old box and new box likely overlap). Originally I was using API calls to try to detect which entities were still in range vs not, but this proved WAY too slow. So instead I threw together some really hacky 'rectangle subtraction' logic to arrive at a set of rectangles that do not include the player's current robotport rectangle.
