# factorio-tacticalConstruction

Source repository for the Factorio mod Tactical Construction.

## Description

Logistic Network Channels is an experimental mod for the video game [Factorio](https://factorio.com/). It attempts to allow the player to prioritize their local player's roboport for construction requests (as opposed to allowing construction requests to be satisfied by any statically-placed logistics network that overlaps inside the player's mobile roboport).

**WARNING: This mod is currently very much in "Alpha". I'm doing all sorts of evil things to make this work. You are likely to encounter bugs, crashes - or worse - you may discover your entities have randomly 'jumped' to an alternative force in the game with no clear route to get 'home' to your primary force. In the latter scenario, your save file will not recover even should you disable the mod entirely after-the-fact. So, please, until I have tested this out better, do be VERY careful on which save files you use this mod on!**

## Limitations

1. Deconstruction: Does not work with to-be-deconstructed entities. At present there's no efficient way to find entities marked for deconstruction. Enhancement request has been submitted here: https://forums.factorio.com/viewtopic.php?t=82643
  * In the mean time, I may eventually experiment with iterating through entities and manually filtering them to find ones marked for deconstruction.

1. Base entity disco: At present, a force's "color" (i.e. the color applied to all entities on that force) appears to be automatically equivalent to the color of the first player member of the force. As a result, when player #1 in a multiplayer game toggles the feature (and gets moved to the alternative force), the primary force color will change to player #2's color. Upon player #1 toggling the feature off, the force color reverts. Thus, you get a sort of "light show" every time player #1 uses this feature.
  * Enhancement request submitted here: https://forums.factorio.com/viewtopic.php?t=82644
  * Workaround: Set player colors to the same value :-)

1. Map fog-of-war: When players have the feature enabled, they are moved to a different force in the game. This means that the discovered areas of the map will be reset. I've enabled map sharing between the two forces, but it only seems to share scans of a sector upon next active scan. Thus, your map will likely be significantly-less explored while you have the feature on.

1. Force weapon attributes: At present I don't sync a bunch of force damage attributes from the primary force over the the alternative one. So if you're gonna fight, maybe toggle the feature off first :-)

## Technical Details

When a player joins, the mod reads their 'force' attribute and creates an 'alternative' version of that force.  When the feature is toggled on (via the button at top-left of the screen), the player and all ghost or to-be-upgraded entities in range of the player's roboport are transported to the alternative force.  Upon disabling the feature, the player and all nearby entities are sent 'home' to the original force.

This seems like it should be pretty trivial (which is why I naively set out to make this mod), but actually there are a few problems:

1. The alternative force needs to have the various technologies and resulting stats from the primary force synced over:
  * To make this happen, I copied a bunch of code from LogiNetChannels: https://github.com/ceresward/factorio-logiNetChannels

1. Upon moving a player to a different force, the player's follower construction robots get 'orphaned'.  I thus went through rather great lengths to port the robots over and reattach them to the player.

1. When the player moves and the feature is toggled on, of course the 'in range' entities change.  We therefore need to revert any now-out-of-range entities back to the pimary force so that they aren't sitting there unserviced forever (that would be just plain rude).  We preserve the player's previous bounding box, but we of course don't want to revert any still-in-range entities (old box and new box likely overlap). Originally I was using API calls to try to detect which entities were still in range vs not, but this proved WAY too slow. So instead I threw together some really hacky 'rectangle subtraction' logic to arrive at a set of rectangles that do not include the player's current robotport rectangle.
