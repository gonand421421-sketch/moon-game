# LUNAR CLEANUP — Studio setup

`LunarCleanupGenerator.lua` is the complete generator, including its embedded server script, client script, and configuration module. No plugins, downloads, or marketplace asset IDs are required. Use a new Baseplate place so unrelated maps or spawn points do not interfere.

## Generate the game

1. Open **Roblox Studio** and create a **Baseplate** place. Save a backup if using an existing place.
2. Stop any running Play/Test session. The generator must run in **EDIT mode**.
3. Open **Command Bar** from Studio's **View** toolbar/menu (the location may vary with Studio's layout). Also open **Explorer** and **Output**.
4. Open `LunarCleanupGenerator.lua` in a text editor. Select **all its contents**, copy, paste into Studio's **Command Bar**, and press Enter. Paste the script contents, not the filename, and do not put it inside an ordinary Script.
5. Wait for Output to say **LUNAR CLEANUP generated**. In Explorer, you should see `LunarCleanup` under Workspace, ReplicatedStorage, ServerScriptService, and StarterPlayer → StarterPlayerScripts.
6. Save the place, then press **Play**. Start on the base platform, facing three dirty maintenance decks. Walk closer and look down at their surfaces.

The generator replaces only its named generated objects and its marked lighting effects. It does change global Lighting settings and first-person StarterPlayer settings. It rewrites only a bounded 320 × 80 × 320-stud Terrain region centered on the yard, and preserves a copy of that region before the first overhaul. It moves any Workspace Baseplate into `ServerStorage → LunarCleanupOriginalEnvironment` so it cannot fill the craters. Do not sculpt inside that region between reruns unless you have separately saved those edits. The generator also changes the global Sand terrain color. Other terrain outside that region is retained. Running it again in Edit mode rebuilds the prototype and resets map dirt; it does not erase saved player accounts. Stop Play before regenerating. Avoid naming your own objects `LunarCleanup` in those services.

## Play

- **WASD**: move. **Mouse**: look. **Hold left mouse**: scrub within 14 studs.
- Aim at the dust-coated deck tops. Nearby patches gradually become transparent as they are scrubbed, exposing the metal beneath. Fully cleaned patches remain aimable so you can sweep continuously across a deck.
- Storage fills with the actual dust removed. When full, return to the **DUST DEPOT**, face its front, and hold **E** to sell. One dust unit earns two credits. Each removed health unit produces half a dust unit; fractional dust is retained between scrubs, sales, and saves.
- At **EQUIPMENT**, hold **E** to open the terminal. Click an upgrade. Close with **TAB** or **CLOSE**.
- Tools progress from **Toothbrush → Regolith Brush → Industrial Scrubber**. Speed, brush radius, and storage upgrades are separate. Purchases apply immediately.
- A completely reclaimed deck gets a new dust coating after 12 seconds. Deck progress and dirt are shared by all players; each removed dust unit pays only once.

## Saving

For persistent progress, first publish your place using Studio. In **Game Settings → Security**, enable **Studio Access to API Services** only for a separate test experience if you want to test DataStores in Studio. Studio tests can access that experience's actual stored data. Published servers use Roblox DataStores normally.

The game saves money, carried dust, tool tier, and upgrades about every 55 seconds, on leaving, and during shutdown. A session lease guards against two servers writing the same profile. If loading fails or another session owns the profile, you can still try the game with temporary progress; the HUD displays a session-only warning and that session will never overwrite the existing account. Rejoin after API access or connectivity is fixed. Dirt on decks is server-local and intentionally resets in each new server. No implementation can guarantee saving during a crash or DataStore outage.

## Studio verification checklist

The project owner successfully tested cleaning, selling, upgrades, and saving in the previous visual version. This **sky-and-balance update has not been playtested in Studio** by Codex. Its generator and all embedded scripts have been checked with the official Luau compiler. Structural mock runs generated the map twice with 941 static map parts, 588 cleaning patches, valid voxel-array dimensions, one preserved terrain snapshot, and no duplicate generated roots. Additional tests cover fractional reward conservation, full bags, sales, legacy save values, and runtime environment repair. Clients add six non-colliding backdrop parts, independently of streamed geometry. This is not engine or performance testing. Roblox engine behavior still needs these checks:

1. In Play, confirm the HUD loads, movement is first-person, and the brush is visible. Hold mouse on a dirty deck: only the area around your aim should fade, dust should increase, and full storage should stop rewards.
2. Sell at the depot, then buy each upgrade near the terminal. Check money decreases by the displayed price and capacity/tool changes immediately. Remote purchase requests away from the terminal should not work.
3. Use Studio's **Test** controls to start a server with **two players**. Scrub the same patch simultaneously: both clients should see the same fading and the total dust plus fractional carry collected by both players must not exceed 6 dust units per full 12-health patch (worth 12 credits). Sell inventories separately.
4. Fully clean a deck; check progress reaches 100%, then the coating returns after 12 seconds. Check other decks retain their progress.
5. In a published test experience with API access, earn and sell dust, leave, wait for the server to save/release, then rejoin. Check credits and upgrades return. With API access unavailable, check the session-only warning appears instead of a script crash.
6. Watch **Output** for errors. Stop, run the generator again, and verify there is one generated root in each service and one HUD per player on the next Play run.

## Design and limits

There are 588 anchored dirt patches across three decks. There are no per-patch scripts, physical dust pickups, vehicles, or automation. A bounded grid lookup and server raycasts validate each scrub request. Server-owned health/transparency replicate to all clients, including late joiners. Dust collection is immediate at the brush rather than a network-heavy cloud of collectible physical objects.

The lunar landscape is a smooth voxel heightfield with six crater bowls, raised rims, noise-based ridges, and a flat work yard. The base, equipment, rocks, decks, and tool view models use Roblox primitives. Lighting requests the current Realistic style when supported and uses shadows and neutral grading. Edit-mode backdrop walls and a non-streamed, camera-relative runtime backdrop avoid external sky textures. The shared Environment module removes conflicting Sky/Atmosphere/Clouds objects from rendering and reapplies sunlight settings on the server and client. Decorative geometry is static, and small industrial details do not intercept cleaning rays. There are two non-shadow-casting floodlights and a restrained bloom effect; no global atmospheric haze is added. Restrained dust particles use Roblox's shipped smoke texture; brush audio uses a Roblox-shipped local footstep sound at low volume, so it requires no uploaded audio ID. Audio/particle appearance and performance should be checked on your target devices. Desktop mouse and keyboard are the supported controls for this prototype.

For tuning, edit the `Config` module source near the top of the generator, then regenerate in Edit mode. Do not edit player account versions casually: the DataStore name is `LunarCleanup_v1`. Generated Scripts are readable in Studio if you want to learn how they work.

## Visual overhaul and rollback

The Studio-tested generator is preserved at `backups/LunarCleanupGenerator.studio-tested.lua`. The pre-sky/balance visual generator is separately preserved at `backups/LunarCleanupGenerator.pre-sky-balance.lua`. This update intentionally changes balance and fractional reward accounting, while retaining RemoteEvents, patch coordinates, interaction anchors, tools and upgrade level identities, session locking, and the `LunarCleanup_v1` DataStore. It adds shared Environment and Economy modules inside the same self-contained generator. Money and purchased levels are not reset. Existing carried dust is preserved, and new fractional dust carry is an additive save field.

Before trying the new generator, save a separate `.rbxl` copy of your working Studio place. Run the new complete generator in Edit mode using the same steps above. On reruns it replaces the generated roots and rewrites the same Terrain region, rather than adding another map. The preserved original environment folder is reused, not replaced.

To restore the pre-overhaul terrain, stop Play, then run this in the Command Bar **before** regenerating with the backup script:

```lua
local folder = game:GetService('ServerStorage'):FindFirstChild('LunarCleanupOriginalEnvironment')
if folder then
 local region = folder:FindFirstChild('TerrainBeforeOverhaul')
 if region then workspace.Terrain:PasteRegion(region, Vector3int16.new(-40,-10,-40), true) end
 local tint = folder:FindFirstChild('OriginalSandColor')
 if tint then workspace.Terrain:SetMaterialColor(Enum.Material.Sand, tint.Value) end
 local baseplate = folder:FindFirstChild('Baseplate')
 if baseplate and not workspace:FindFirstChild('Baseplate') then baseplate.Parent = workspace end
end
```

A saved `.rbxl` backup is the complete rollback option, including global Lighting settings. The original environment folder preserves Terrain in the generated bounds, the Baseplate, and template sky/atmosphere/post-processing instances under `LightingBeforeOverhaul`. Those original lighting instances are moved out of Lighting to prevent template haze or stacked effects. The folder does not preserve arbitrary user changes or all global Lighting properties.

## Testing this sky-and-balance update

1. Save a `.rbxl` backup of your tested place. Stop Play and run the complete updated generator in Edit mode. Use the same published test experience to check existing save compatibility; do not clear its DataStores.
2. Open **Output** before generating. `[LunarCleanup audit]` reports `StreamingEnabled`, existing Sky/Atmosphere/Clouds instances, and accessible place scripts containing environment references. A reference is a review hint, not proof that the script caused the bug. Other scripts are not automatically deleted or disabled.
3. Press **Play**. Look straight up, rotate through every direction, walk around, and respawn. Space should remain black while the ground receives bright sunlight with strong shadows. Repeat with two clients and the place's existing streaming settings. Do not disable streaming as a substitute for this test.
4. In the **client** Explorer view, `Workspace → LunarCleanupLocalSpace` should contain six black parts. Their centers follow the camera but their orientation does not rotate with your view. Lighting should have one active `LunarSky` and no active Atmosphere; Clouds are disabled and moved to an archive. Server conflicts are preserved under `ServerStorage → LunarCleanupOriginalEnvironment → LightingBeforeOverhaul`. Client-only conflicts are preserved locally under `ReplicatedStorage → LunarCleanup → LunarCleanupClientEnvironmentArchive`.
5. To test a conflicting object without changing the saved place, switch the Command Bar to the **server during Play** and run `Instance.new("Sky").Parent = game:GetService("Lighting")`. It should be archived and logged with `[LunarCleanup environment]`. A newly added `Clouds` under Terrain should also be disabled and archived. Stop Play to discard those test additions.
6. Scrub one patch with the starting brush. Its center now needs roughly **10 seconds of continuous contact** for full cleaning, with smooth intermediate fades; overlap and aim affect neighboring patches. A fractional scrub should still change the dirt even before the whole-unit dust counter increases.
7. Test full storage, sell, buy upgrades, then rejoin. Check your pre-existing money, tools, and purchased levels remain. Full storage must stop removal; repeated selling must not create more money. Compare two players on the same patch.
8. For a fresh-player pacing trial, use a separate test account/experience rather than resetting your real progress. Existing balances and previously purchased equipment intentionally let returning players progress faster. Record actual unlock times and effective scrubbing/travel time for the next tuning pass.

See `BALANCE_AND_SKY_NOTES.md` for the cause analysis, values, timing assumptions, and reproducible command-line checks. This update is delivered through the project's GitHub `main` branch; Codex reports the actual push result separately. No Roblox publication or Studio playtesting is performed by the command-line checks.
