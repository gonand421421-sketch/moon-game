# LUNAR CLEANUP — Hex sectors, cleaning fixes and equipment workshop

`LunarCleanupGenerator.lua` is the complete self-contained generator. It contains the server/client scripts and every generated module. No plugins, uploaded assets, or external downloads are required by the game.

The owner tested the previous game's sky, cleaning speed, selling, upgrades and saving successfully. **This hex/workshop bug-fix update has not been playtested in Roblox Studio by Codex.** The existing economy, cleaning coefficients, native black-sky module and reward calculations are unchanged.

## Install in Roblox Studio

1. **Save a separate `.rbxl` backup of your working place.** The previous generator is also preserved in `backups/LunarCleanupGenerator.pre-hex-workshop.lua` (immediately previous version).
2. Stop Play/Test. Open Studio's **Command Bar**, **Explorer** and **Output**.
3. Open the updated `LunarCleanupGenerator.lua` from this repository. Use **Raw** on GitHub, select all, and copy the entire script.
4. Paste the contents into the **Command Bar in EDIT mode** and press Enter. Do not paste just the filename or put the generator inside an ordinary Script.
5. Wait for **LUNAR CLEANUP generated** in Output. Save the place and press **Play**.
6. Walk off the base toward the ground ahead and aim downward. The old three framed plots are gone: dark removable regolith coating now follows the real Terrain.

Expected generated content:

- Workspace → `LunarCleanup`: base, depot, terminal, rocks, survey markers and `SurfaceRegions` metadata. There are no global per-cell dirt Parts.
- ReplicatedStorage → `LunarCleanup`: the original `Scrub`, `Action`, `Feedback` RemoteEvents, a new `Surface` RemoteEvent, and Config/Environment/Economy/Regions/SurfaceRender/SectorView/Celestial modules.
- ServerScriptService → `LunarCleanup`: the existing game server script with its regional targeting adaptation, plus its server-only `SurfaceWorld` child module.
- StarterPlayer → StarterPlayerScripts → `LunarCleanup`: the first-person client.
- During Play, each client creates `Workspace → LunarCleanupSurfaceVisuals` locally for its nearby coating pieces. These are not replicated physical dust objects.

## Play and explore

- **WASD** moves; **mouse** looks; **hold left mouse** scrubs the ground within the unchanged 14-stud range.
- The starting brush still has the same approximately **4.5-second center-cell time** on level ground without speed upgrades. Aim, overlap and slopes affect the visible footprint. No economy values were changed for this expansion.
- Full storage stops removal. Return to the existing **DUST DEPOT** and hold **E** to sell. At **EQUIPMENT**, hold **E** and click an upgrade; close with **TAB** or **CLOSE**.
- The base floor now sits about 0.08 studs above sampled Terrain instead of 1.6 studs above the intended surface. The habitat, depot, terminal and workshop follow that floor height. Depot/terminal X/Z positions, prompts and purchase distance rules remain unchanged. The invisible spawn pad sits above the floor but no longer collides or blocks brush queries. The habitat apron is excluded from the ground coating.
- You can **walk through all three connected survey regions immediately**. Only cleaning permission is gated; there are no invisible walls or movement locks.
- **Tranquility Approach** is the starter survey. **Basalt Expanse** opens for cleaning with the Regolith Brush **or 5% shared restoration of the Approach**. **Kepler Outer Rim** opens with the Industrial Scrubber **or 5% shared restoration of the Expanse**. These alternate gates avoid stranding a new player after others have cleaned the starter area.
- The right-side survey HUD shows world slot, regional restoration percentages and cleaning locks. The center HUD names the hex sector under your aim, its cleaning percentage/state, and the canonical cell region or lock requirement. Locked coating has a muted warmer tint, and locked targets explicitly say LOCKED.

The ground is procedural lunar terrain, not a NASA elevation dataset or a full-scale Moon. Survey edges use gentle noise variation, and the coating uses a continuous color field without plot frames or checkerboard coloring. Internally it remains a 0.85-stud patch system to preserve the working tool footprint and reward scale.

## What changed in this update

- Ground cleaning now uses one cell-coordinate rule for the HUD, saved health and server permissions. It no longer rejects a continuous steep plane just because a neighboring representative cell center falls outside a 3D sphere. Range, horizontal brush footprint, damage, rewards and prices are unchanged.
- Decorative rock wedges and all new visual details are non-colliding/non-queryable. Real habitat/workshop structures can still physically block a brush; aim at exposed ground. Unsurveyed regolith and temporary save/lease pauses have explicit HUD messages instead of pretending every gray surface is dirty coating.
- **64 large hexagonal sectors** organize the same existing cells. Thin, muted survey filaments drape over the Terrain, with local sector identifiers and percentages. Dirty, in-progress, mixed-access, locked and completed sectors have distinct labels/colors. These are not raised hex platforms and do not replace the localized fade mechanic.
- The equipment terminal now sits inside a workshop canopy with racks, tool displays, calibration machinery, lit signs and task lighting. Upgrade rows show your owned tool/levels, effects, next price and affordability. The original purchase actions and server validation are unchanged.
- Look northwest/upward from the base for a low-resolution original primitive **Earth**, with blue oceans, geographic land silhouettes and polar ice. A sparse star field accompanies it. These decorations do not add or modify Lighting Sky, Atmosphere or Clouds objects. The existing native black sky remains the background.

Sector outlines/labels render locally within 54 studs, with at most 420 line segments; full-resolution dirt remains limited to the existing 18-stud nearby coating radius. Earth/stars use 343 local primitive Parts in the structural check and one model translation update when the camera moves; they never rotate with head direction. Very low graphics/draw distance can affect their visibility without changing the native sky.

## Player saves and regional saves

Player accounts remain in **`LunarCleanup_v1`** with the same keys, fields, leases and save schedule. Money, carried dust/fractional carry, tools and upgrade levels are not reset or re-priced. Old players with higher-tier tools can immediately clean the corresponding outer regions.

Regional dirt is new, independent shared-world data in **`LunarCleanup_Surface_v1`**. Each live server exclusively leases one persistent survey slot, displayed as **SURVEY WORLD 1**, etc. All players in that server see the same ground state. Nearby clients receive shared deltas; joining clients receive current nearby chunks.

The server loads regional state once, renews/saves its compact snapshot about every **55 seconds**, and attempts a final save/release at shutdown. Scrubbing and moving between chunks do **not** perform DataStore writes. Partial cell health round-trips at full numeric precision. Another live server gets a different slot rather than writing over the first server's surface.

**Important world behavior:** there are 16 survey slots in this prototype. A later server can reuse and restore a released slot. Joining a different active server can place you in a different survey world with different cleaned ground; there is no personal-world selection/matchmaking UI yet. Your account money and equipment follow you regardless. Check the world number before comparing saved map progress. Different servers are not pretending to modify a single globally synchronized Moon.

Regional dirt stays removed: the former tiny-deck recoat loop is not used for these persistent surveys. These regions contain finite work, with no automatic regional reset. New regions or a deliberately versioned future survey season can add work later. A finished world is finished; it does not silently reset people's map progress.

## Studio API settings and failures

For real save tests, publish a **separate test experience** and enable **Game Settings → Security → Studio Access to API Services** there. Studio can access that experience's real DataStores; do not erase your production data to test a new player.

- If DataStore access fails in **Studio**, the surface system permits a clearly labeled **TEMPORARY STUDIO SURVEY**. Its ground resets between sessions. This does not claim the map was saved.
- In a **published server**, if no persistent slot can be safely loaded/leased, surface cleaning pauses instead of granting rewards against an invented unsaved copy of the Moon. The survey HUD reports the pause; existing player account handling remains separate.
- A world stops granting new surface rewards shortly before its unrenewed lease expires, or immediately if another owner is detected. Failed saves log errors. Recovery may require a new server after access is restored.
- Map and player saves use separate keys. A crash can lose recent map changes within the autosave window; there is no atomic multi-key transaction guaranteeing both saves commit together. No implementation here promises crash-proof durability.

## Studio test checklist

1. **Generate twice in Edit mode.** Confirm only one generated root in each service, three SurfaceRegions entries, and no old MaintenanceDeck/Dust parts. Check the expanded terrain and backups remain sensible. Do not run the generator during Play.
2. **Sky regression:** look up, turn, walk and scrub for several minutes. The working native black sky and bright lighting should be unchanged. There should be no camera-following black backdrop geometry.
3. **Surface fit and bug fixes:** walk the Approach and crater edges. Coating should sit on the Terrain rather than a platform, fade gradually under the brush, expose the lighter Terrain, and keep its cleaned state when you walk away and return. Aim at cell corners, slopes and crater lips, including both sides of sector/region boundaries. Unlocked visible coating should respond. Locked targets must say LOCKED, and clean or unsurveyed ground must not award dust. Inspect for gaps, clipping, slope stretching or shimmering; those require real rendering checks.
4. **Distance/performance:** inspect the **client** Workspace. Only nearby coating Parts should exist under LunarCleanupSurfaceVisuals, never more than 1,600 per client. Walk between regions, respawn and return. Watch frame rate and Output. Distant coating detail intentionally fades out; distant ground does not display a full-resolution cleaning map.
5. **Regional gates:** a new Tool-1 profile can clean the Approach and explore everywhere. Try the Expanse before unlocking it; it should report the requirement and grant no dust. Buy the existing Regolith Brush or reach 5% shared Approach restoration and try again. Repeat for the Outer Rim. Do not alter real account data to simulate a fresh profile.
6. **Two-player test:** start one server with two clients. Scrub the same ground, compare both views, and check the dirt/dust cannot be rewarded twice in that server. Each full 12-health cell still yields a total of 6 dust plus fractional carry, worth 12 credits. Sell and upgrade separately.
7. **Economy regression:** fill a bag, verify cleaning stops, sell, buy existing upgrades and rejoin. Confirm previous money, dust and purchased levels remain. The existing depot/terminal must still reject remote actions from too far away.
8. **Persistence:** with APIs enabled, record the survey world number and an identifiable cleaned spot. Allow an autosave, stop normally, and restart. If the same slot is reacquired, the spot and percentage should return. A second live server should lease a different slot. A temporary survey is not a persistence success.
9. **Hex sectors and workshop:** compare a partly cleaned sector across both clients, walk to its neighbors, and verify its percentage survives a same-world restart. Check locked/dirty/in-progress/mixed/complete labels. Buy upgrades at the new workshop, including insufficient-money and maximum-level cases. Confirm the floor blends into the ground, the invisible spawn pad does not stop movement or aim rays, and respawning is safe.
10. **Earth and stars:** look northwest and up from the base; Earth should have blue oceans and recognizable continent/polar silhouettes. Turn away, walk, scrub and respawn: the background must stay black. No orbital detail should intercept the brush or change ground illumination. Visual fidelity and low-graphics visibility require an actual Studio check.
11. **Terrain streaming:** keep the place's actual streaming setting and test walking into both outer regions. Nearby coating waits for real streamed Terrain hits rather than making floating guesses when geometry is unavailable.

## Reruns, terrain preservation and rollback

The generator writes a bounded **512 × 104 × 512-stud** Terrain region: X/Z `-256..256`, Y `-48..56`. It does not call Terrain:Clear(). It preserves the pre-expansion contents once as `ServerStorage → LunarCleanupOriginalEnvironment → TerrainBeforeRegionalExpansion`. Earlier original-environment snapshots and the saved Baseplate are retained. It also retains the earlier Sand color/lighting-instance backups. Repeated generation reuses snapshots and replaces generated roots; it does not wipe either DataStore.

Save separate backups of any custom sculpting inside those bounds before regenerating; reruns rebuild that footprint. Terrain outside the bounds remains untouched. The global Sand color and existing first-person/Lighting settings are applied as before.

For a code-and-map rollback, prefer your saved `.rbxl`. To restore just the pre-expansion terrain before running `backups/LunarCleanupGenerator.pre-regional-surface.lua`, stop Play and run:

```lua
local saved = game:GetService('ServerStorage'):FindFirstChild('LunarCleanupOriginalEnvironment')
local region = saved and saved:FindFirstChild('TerrainBeforeRegionalExpansion')
if region then
 workspace.Terrain:PasteRegion(region, Vector3int16.new(-64,-12,-64), true)
end
```

Then run the complete pre-regional generator in Edit mode. Regional saves remain in their separate DataStore for a future return to this version; do not delete them as part of a visual rollback.

For this update see **HEX_WORKSHOP_NOTES.md**. The pre-update regional code remains in `backups/LunarCleanupGenerator.pre-hex-workshop.lua`; running it in Edit mode restores the prior regional presentation without deleting player/survey saves. See **REGIONAL_SURFACE_NOTES.md** for architecture, resource limits and tests. **BALANCE_AND_SKY_NOTES.md** documents the preceding sky/balance work; its balance coefficients and sky module are frozen in this expansion. Completed changes are delivered to GitHub `main`; the assistant reports the actual verified push result separately. Nothing here publishes the Roblox place for you.
