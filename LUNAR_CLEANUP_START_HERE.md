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
- Storage fills with the actual dust removed. When full, return to the **DUST DEPOT**, face its front, and hold **E** to sell. One dust unit earns one credit.
- At **EQUIPMENT**, hold **E** to open the terminal. Click an upgrade. Close with **TAB** or **CLOSE**.
- Tools progress from **Toothbrush → Regolith Brush → Industrial Scrubber**. Speed, brush radius, and storage upgrades are separate. Purchases apply immediately.
- A completely reclaimed deck gets a new dust coating after 35 seconds. Deck progress and dirt are shared by all players; each removed dust unit pays only once.

## Saving

For persistent progress, first publish your place using Studio. In **Game Settings → Security**, enable **Studio Access to API Services** only for a separate test experience if you want to test DataStores in Studio. Studio tests can access that experience's actual stored data. Published servers use Roblox DataStores normally.

The game saves money, carried dust, tool tier, and upgrades about every 55 seconds, on leaving, and during shutdown. A session lease guards against two servers writing the same profile. If loading fails or another session owns the profile, you can still try the game with temporary progress; the HUD displays a session-only warning and that session will never overwrite the existing account. Rejoin after API access or connectivity is fixed. Dirt on decks is server-local and intentionally resets in each new server. No implementation can guarantee saving during a crash or DataStore outage.

## Studio verification checklist

The previous version was successfully tested by the project owner in Roblox Studio, including localized cleaning. This **visual overhaul has not been playtested in Studio** by Codex. Its generator and all embedded scripts have been checked with the official Luau compiler. A structural mock run also generated the map twice with 941 static map parts, 588 unchanged cleaning patches, valid voxel-array dimensions, one preserved terrain snapshot, and no duplicate generated roots. This is not engine or performance testing. Roblox engine behavior still needs these checks:

1. In Play, confirm the HUD loads, movement is first-person, and the brush is visible. Hold mouse on a dirty deck: only the area around your aim should fade, dust should increase, and full storage should stop rewards.
2. Sell at the depot, then buy each upgrade near the terminal. Check money decreases by the displayed price and capacity/tool changes immediately. Remote purchase requests away from the terminal should not work.
3. Use Studio's **Test** controls to start a server with **two players**. Scrub the same patch simultaneously: both clients should see the same fading and total payouts must not exceed the patch's original 12 dust units. Sell inventories separately.
4. Fully clean a deck; check progress reaches 100%, then the coating returns after 35 seconds. Check other decks retain their progress.
5. In a published test experience with API access, earn and sell dust, leave, wait for the server to save/release, then rejoin. Check credits and upgrades return. With API access unavailable, check the session-only warning appears instead of a script crash.
6. Watch **Output** for errors. Stop, run the generator again, and verify there is one generated root in each service and one HUD per player on the next Play run.

## Design and limits

There are 588 anchored dirt patches across three decks. There are no per-patch scripts, physical dust pickups, vehicles, or automation. A bounded grid lookup and server raycasts validate each scrub request. Server-owned health/transparency replicate to all clients, including late joiners. Dust collection is immediate at the brush rather than a network-heavy cloud of collectible physical objects.

The lunar landscape is a smooth voxel heightfield with six crater bowls, raised rims, noise-based ridges, and a flat work yard. The base, equipment, rocks, decks, and tool view models use Roblox primitives. Lighting requests the current Realistic style when supported and uses shadows and neutral grading. Black backdrop walls avoid external sky textures. Decorative geometry is static, and small industrial details do not intercept cleaning rays. There are two non-shadow-casting floodlights and a restrained bloom effect; no global atmospheric haze is added. Restrained dust particles use Roblox's shipped smoke texture; brush audio uses a Roblox-shipped local footstep sound at low volume, so it requires no uploaded audio ID. Audio/particle appearance and performance should be checked on your target devices. Desktop mouse and keyboard are the supported controls for this prototype.

For tuning, edit the `Config` module source near the top of the generator, then regenerate in Edit mode. Do not edit player account versions casually: the DataStore name is `LunarCleanup_v1`. Generated Scripts are readable in Studio if you want to learn how they work.

## Visual overhaul and rollback

The Studio-tested generator is preserved at `backups/LunarCleanupGenerator.studio-tested.lua`. Gameplay configuration and the entire server script are byte-for-byte unchanged in this overhaul. The same RemoteEvents, patch grid, surface heights, station interaction anchors, prices, rewards, progression, and DataStore name are retained. Client edits concern HUD presentation, tool geometry, visual animation, and particles.

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

The updated files are saved in the Codex workspace. This visual overhaul has not been pushed to GitHub or published to Roblox.
