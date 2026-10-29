# Native sky correction and faster-brush balance

## Investigation: what failed in the previous implementation

The previous update still did not define black sky content: all six Sky texture fields were empty. Instead it placed six 1,244-stud-wide background Parts 620 studs from the camera and moved them in a render callback. Six more Edit-mode walls sat 800 studs from the world origin. That was world geometry attempting to substitute for an actual skybox. Client ownership removed one streaming dependency, but could not make the geometry an infinite renderer sky background or remove its clipping/culling/render-update dependencies.

The module also ran separate client/server two-second repair tasks. Both copies could create a primary Sky and reparent conflicting Sky/Atmosphere/Clouds objects. A client could hide the replicated server Sky locally if its own primary Sky already existed. Lighting values were compared with exact Lua numeric equality even though engine properties can round. These were real architectural defects in the generator, not evidence of a cleaning reward bug.

No cleaning, selling, or tool animation handler changes the sky. The two render callbacks had the same priority, but the tool callback never changed camera orientation or sky geometry; equal priority by itself does not prove it caused the flicker. Ordinary character movement also has no explicit sky toggle. The local backdrop was parented directly to Workspace; it is incorrect to assume it streamed out merely because it was client-owned. Camera clipping/culling and competing object repair were risks, but the precise trigger of the owner's intermittent blue frames has **not been reproduced or measured in Studio by Codex**. That limit matters: the earlier fix claimed too much from structural mocks.

## Correction: real black sky content, no overlay

- Removed **all** generated background geometry: both Edit-mode world walls and the client-owned camera-following box. Removed `CreateBackdrop`, `LunarCleanupLocalSpace`, the `LunarCleanupSky` render callback, and its raycast exclusion. The sky no longer has a distance, camera transform, geometric seam, or render-step order to maintain.
- All six faces of the native `LunarSky` now explicitly use `rbxasset://textures/blackBkg_square.png`, a verified file packaged in Roblox's common content. It is configured **before** the Sky is parented to Lighting, so a newly created primary Sky is not activated with its default blue faces.
- **Only the server creates/reparents the primary Sky.** Client observers never create, destroy or reparent a replicated Sky. They set the same face content on additional local-only skies and neutralize local Atmosphere/Clouds in place.
- Removed both periodic polling tasks. Object additions/removals and relevant property changes drive repairs. Numeric comparisons use a 0.0001 tolerance and callbacks guard against re-entry. There is no cleaning-triggered environment update.
- Keep sunlight brightness 3.5, clock time 15.7, hard shadows, existing ambient fill, and exposure. Black sky content does not require darkening the Moon's surface. The existing floodlights, grading, and restrained bloom remain.
- Preload the built-in texture on the client and report actual asset-load failures to Output. There is deliberately no fallback that silently recreates an overlay or substitutes an empty sky. The server preserves conflicting objects in the original environment archive; original Cloud enabled state is recorded before disabling it.

This is a replacement of the faulty background representation and ownership model, not another black overlay. Actual rendering and asset loading still require the Studio test in the setup guide. Engine rendering is not implemented by the structural test stub.

## Texture verification, without guessed assets

The texture was checked against this [pinned Roblox client package snapshot](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/84e5cc5fd8405e75c9f8c70116e450aef327ff56/textures/blackBkg_square.png), including its `rbxManifest.csv` entry at `content\textures\blackBkg_square.png`.

- PNG dimensions: 24 × 24.
- All RGB pixels: `(0, 0, 0)`; alpha is uniformly 179. This is a native skybox texture input, not a translucent GUI placed over the game. The sky's actual rendering is a Studio verification item.
- PNG MD5: `1d87a3860bf4ac735de7c04f985a1f75`, matching the package manifest.
- SHA-256: `17f1afc26a21b79a0fa5cf2568da306a350f23091fdbc270043ef0ee28fe19bf`.

The game uses the Roblox-installed local file, not a GitHub image URL or marketplace asset ID. There are no required downloads, uploaded images, EditableImage permissions, or asset ownership grants. A future Roblox package could change its built-in content; any load failure is reported rather than claimed to work. Official references: [Sky](https://create.roblox.com/docs/reference/engine/classes/Sky), [Clouds](https://create.roblox.com/docs/reference/engine/classes/Clouds), and [instance streaming](https://create.roblox.com/docs/workspace/streaming).

The generator still prints actual environment instances and flags accessible place scripts containing Lighting/Skybox/Atmosphere/Clouds references. A source reference is only a review hint. These diagnostics cannot identify an installed plugin or prove which outside script created an instance. It does not disable arbitrary scripts.

## Faster cleaning, recalculated progression

All pacing values remain in the **BALANCE CONFIGURATION** block near the top of `LunarCleanupGenerator.lua`. Make permanent edits there and regenerate in Edit mode; already-required modules do not reliably hot-reload during a Play test.

| Tool | Radius | Power, health/sec per affected patch before falloff | Unlock price |
| --- | ---: | ---: | ---: |
| Toothbrush | 0.48 | 12 / 4.5 ≈ 2.667 | Free |
| Regolith Brush | 0.85 | 4 | 2,000 |
| Industrial Scrubber | 1.35 | 6 | 9,000 |

Each patch retains 12 health. Continuous unupgraded center contact now takes **4.5 seconds**, rather than 10. At roughly 10 requests/sec, each center request removes about 0.267 health (2.22% of a patch), preserving gradual localized fading. Brush overlap, edge falloff, motion, and existing Speed upgrades change observed clear time. This is not click-to-destroy behavior.

Dust per patch remains rewarding and unchanged: **0.5 dust per removed health**, selling at **2 credits per whole dust**, so a full patch contains 6 dust / 12 credits of value. Extraction is more than twice as fast; tool and upgrade prices approximately double to keep longer-term progression meaningful. Fractional carry is still conserved through scrubs, sales, and saves. We did not hide the faster cleaning behind a new earnings throttle, energy system, or cooldown.

| Upgrade | Successive prices | Effect |
| --- | --- | --- |
| Speed | 440 / 1,300 / 4,200 / 11,000 | +20% base power per level |
| Radius | 600 / 1,900 / 8,400 | +10% base radius per level |
| Storage | 360 / 1,100 / 2,400 / 7,600 / 15,600 | Capacity 100 → 260 → 560 → 1,000 → 1,700 → 2,600 |

Storage values are unchanged from the previous version, preserving carried dust and making fewer selling trips valuable at the faster extraction rate. Existing money and purchased upgrades are not reset, re-priced retroactively, or charged again. Tool indices and upgrade level counts remain the same. The DataStore and all existing save fields are unchanged. The server's raycast, purchase, sale, session-lease, save scheduling, and fractional accounting code are unchanged in this update.

## Timing calculations and limits

Integrating the actual footprint and falloff over uniformly distributed aim offsets in a 0.85-stud grid cell gives unupgraded theoretical rates of approximately **4.52, 15.05, and 47.34 health/sec** on fully dirty interior ground. The larger tools are roughly three times as effective at each step before support upgrades.

With raw health rate `R`, effective contact fraction `e`, dust yield `Y=0.5`, sale price `P=2`, bag `B`, and travel/selling time `T=12 seconds`:

```
Dust/sec while working = R × e × Y
Work time per bag = B / (R × e × Y)
Average credits/sec = (B × P) / (B / (R × e × Y) + T)
Purchase time ≈ cost / average credits/sec
```

The baseline `e=0.65` accounts for missed aim, already-clean patches, edges, and repositioning apart from sales travel. It is a mathematical assumption, not a code-imposed multiplier or measured telemetry. Continuous average sales omit whole-bag rounding, wallet leftovers, shop decision time, and player contention. The model does not simulate a complete player cleaning path. A fully cleared deck recoats after 12 seconds; other decks remain available. There are no new waiting gates.

Reference route: buy Storage 1 then Regolith Brush; buy Speed 1, Radius 1, Storage 2 then Industrial Scrubber; finish Storage 3, Speed 2, Radius 2, Speed 3, Storage 4, Radius 3, Speed 4, Storage 5.

| Contact assumption | Regolith Brush | Industrial Scrubber | All tools and support upgrades |
| --- | ---: | ---: | ---: |
| 50% | 18.5 min | 39.2 min | 59.5 min |
| 65% baseline | 14.5 min | 31.0 min | 47.5 min |
| 80% | 12.0 min | 25.8 min | 40.0 min |

Existing balances/equipment can make returning players much faster; they are intentionally preserved. Purchase order and actual travel/aim efficiency affect these numbers. Complete progression means all three tools **and** current support upgrades; the third tool is available at the advanced-equipment milestone. These are targets for tuning, not guaranteed player-session durations.

## Checks and backups

```sh
python3 tools/validate_generator.py --luau /path/to/luau --compiler /path/to/luau-compile
```

Checks compile the generator and every embedded source; exercise actual fractional accounting and save sanitization; verify the 4–5-second target, conserved shared rewards, full bags, sales and legacy saves; and generate the map twice in an explicit Roblox API stub. Structural checks verify all six native faces, no backdrop parts/render callback/polling loops, client non-creation of primary Sky, server-only archiving, property restoration, and numeric tolerance. Map geometry is now 935 static parts, including 588 cleaning patches, with no client background geometry.

The stub cannot test Roblox rendering, texture decoding, GPU clipping, asset preloading, real streaming, networking, or DataStores. **Codex has not playtested this update in Roblox Studio.**

The immediate pre-change backup is `backups/LunarCleanupGenerator.pre-stable-sky.lua`. Earlier backups remain intact. Never reset real player data to measure first-time progression; use a separate test account/experience. Follow the updated Studio testing guide and record actual errors or screenshots if rendering differs.
