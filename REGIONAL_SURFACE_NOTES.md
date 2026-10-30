# Regional lunar surface system

## Preserved behavior

The pre-expansion generator is `backups/LunarCleanupGenerator.pre-regional-surface.lua`. The validator compares the new generator against it and requires **byte-for-byte equality** of Config (all cleaning, price, reward, bag and upgrade values), Environment (the tested native black sky), and Economy (fractional reward calculations). It also compares the complete existing account loading/saving, character settings, selling and purchase block. The original three RemoteEvents remain with the same names and arguments. `Surface` is an additional regional subscription/delta event.

The necessary change is targeting/state ownership: scrub raycasts now hit actual Terrain, and a regional health map replaces the old static dirt Parts. Head-origin checks, range, rate limiting, line of sight, tool radius/power formulas, bag caps and server-owned rewards remain. No DataStore call occurs inside a scrub request. Terrain is a single Instance, so the adapted line-of-sight check compares hit positions rather than accepting any second hit on that same Instance.

No new player profile fields are required. The existing `LunarCleanup_v1` profile keys, sanitizer and save cadence are retained. This is not a profile migration or reset.

## Scale and connected regions

The expanded terrain footprint is 512 × 512 studs, with noise-based hills, plains, six crater bowls/rims and a larger rock distribution. It is original procedural terrain, not an imported map of the real Moon. The base/depot/terminal anchors are unchanged. Rectangular maintenance decks and their framed dirt grids are removed.

The deterministic region index used by the command-line checks contains:

| Region | Cleaning cells | Approx. projected area | Cleaning access |
| --- | ---: | ---: | --- |
| Tranquility Approach | 2,428 | 1,754 sq studs | Starting tool |
| Basalt Expanse | 15,794 | 11,411 sq studs | Tool 2 OR 5% shared restoration of Region 1 |
| Kepler Outer Rim | 21,545 | 15,566 sq studs | Tool 3 OR 5% shared restoration of Region 2 |
| Total | 39,767 | 28,732 sq studs | All areas freely walkable |

This is approximately 68 times the projected cleaning area of the previous 588-cell prototype. Noise perturbs the ellipse-based region boundaries; overlapping regions have deterministic priority so a cell belongs to one region only. The habitat apron is excluded. You never need 100% completion or a last-patch hunt to unlock exploration or the next survey.

These permissions are checked on the server. Shared progress provides an alternate cleaning unlock for beginners joining a partly finished world, so a cleaned starter region cannot strand them behind a tool purchase they cannot earn. Purchased higher-tier tools still immediately unlock their respective areas. Regional permissions do not change tool efficiency or any purchase prices.

## Terrain-aligned coating

Cells retain the existing **0.85-stud horizontal spacing, 12 health, fractional damage/falloff and reward values**. There is no server-side Part for each of the roughly 40,000 cells. Regional coordinates and cell IDs are plain data.

Clients create coating only within 18 studs of their own character, with a two-stud edge fade, up to 1,600 pooled local Parts. At most 90 new terrain hits/visuals are attempted per 0.1-second update. Old visuals are returned to a pool when walking away, clearing a cell, or losing the character. Nearby known dirty ground fades in over 0.2 seconds. These are limits on presentation work, not earning rates.

Each coating piece raycasts the **actual streamed Terrain** and aligns to its hit normal using a tangent frame. Slight overlap and a smooth shared color field hide the initial checkerboard/seams; there are no plot frames. Clearing gradually reveals the lighter regolith beneath. Fully cleaned pieces release their visual Part. The terrain itself still supplies collision and shape; cleaning does not excavate voxels.

The original first-person tool model, animation, brush audio, particles, left-mouse input, inventory HUD and upgrade UI remain. The center aim label now names the region, and a right-side survey panel adds all three restoration percentages plus world identity. Percentages include partial health removal rather than only fully cleared cells.

Technical limits: this is a patch approximation of continuous dirt, not an arbitrarily smooth voxel/material paint engine. Some square-ish clearing edges can remain at sub-stud resolution. Tangent planes can overlap or stretch on steep curvature; normals below 0.35 Y are not cleanable. Rocks/structures can obscure ground cells. There is no promise that every indexed spot is conveniently reachable or that 100% is always practical; unlocks never require it. Distant ground does not show the full-resolution coating/cleaning pattern. Pop-in, slope fit and frame rate need Studio testing.

## Server spatial partitioning and synchronization

A chunk is 12 × 12 cells, or 10.2 × 10.2 projected studs. The current region masks occupy **320 chunks**. Negative coordinates are handled with floor-based chunk mapping and tested round-trips.

The server builds only chunk membership/region counts at startup; untouched cell health is implicitly 12. Non-default health is sparse data. Terrain geometry is raycast lazily around a brush and cached per touched cell; generated Terrain is static during Play. If a future feature reshapes Terrain at runtime, that geometry cache needs invalidation.

A client requests subscriptions every 0.8 seconds; the server rate-limits requests and derives the neighborhood from the **server character root**, ignoring supplied coordinates. The maximum subscription footprint is 49 chunks. Newly entered chunks get packed snapshots; unchanged subscriptions do not resend health snapshots. Changes are coalesced per cell and broadcast every 0.2 seconds only to subscribed nearby players. Shared progress summaries refresh with subscription responses. Rendering and subscription messages never write DataStores.

Health reduction, inventory accounting and recording the cell change run without yielding inside a scrub handler. Two players cannot both receive the same removed health in a server. Client visuals are non-colliding, non-touching and non-queryable: they cannot serve as trusted reward targets. The server raycasts Terrain and validates tool permissions, range and aim independently.

## Persistent survey worlds

Regional state lives in a **separate** `LunarCleanup_Surface_v1` DataStore, under `World_1` through `World_16`. A server atomically leases one world for 180 seconds, renews/saves about every 55 seconds, and attempts release at shutdown. Other live servers skip the leased slot. Stale writers are rejected, and surface rewards pause before a lease expires rather than continuing against potentially shared state.

This prototype has **16 concurrent persistent survey slots**. It is a collection of shared survey worlds, not one globally synchronized Moon. Players inside a server share the same progress. Later sessions can restore a released slot, but ordinary Roblox matchmaking does not guarantee that a particular account returns to the same world. The HUD explicitly identifies the slot. Personal currency/equipment always remain in the separate player profile. A world picker or sticky-world matchmaking is future work; the code does not claim it exists.

Sparse chunk health is packed into ASCII strings with **17 significant digits**, preserving actual floating-point health on round-trip. Fully cleared chunks use a single `*` marker. One sampled worst-case partial-health map across all current cells is about **886 KB** before small table metadata; the writer refuses a payload exceeding a conservative 2.5 MB packed limit. It does not write per cell or per subscription. Usually only touched chunks need encoding, then one coherent world record is saved.

World loading and claims are bounded. If Studio APIs are unavailable, the HUD clearly labels a temporary Studio survey; it is not persisted. Published servers do not silently fall back to unsaved reward-bearing copies of the world. No slot/access, a lost lease, or a sufficiently stale lease pauses surface rewards. Errors appear in Output. Recovery from an initial published load failure currently requires a fresh server once the prerequisite is restored.

Saving world health and saving player money are separate operations and **not an atomic multi-key transaction**. An abrupt crash can roll back recent surface work within the approximately 55-second autosave window even if a player save committed. Leases prevent concurrent ownership, not every crash/replay scenario. A production transactional reward journal would be additional work; this prototype does not claim exactly-once rewards across crashes or different survey worlds.

Regional dirt remains removed when its world is restored. The old small-deck recoat loop is retired; the unchanged legacy ResetSeconds value in Config does not reset regions. These are **finite surveys**. At full restoration a world remains clean. There is no hidden auto-wipe, forced waiting timer, or infinite planet generation. Future expansion can add regions with stable world coordinates and an explicit migration; changing region definitions or identifiers casually can change the meaning of saved cells.

## Generation, backups and expansion limits

The generator rewrites only the bounded X/Z `-256..256`, Y `-48..56` Terrain volume. It saves that volume once as `TerrainBeforeRegionalExpansion` alongside older backups in ServerStorage before writing it. It replaces generated service roots and reuses backups on rerun. Neither player nor surface DataStores are cleared by generation. Custom edits inside the generated footprint need a separate `.rbxl` backup before regenerating.

The current server's static scenery has 404 Parts in the structural stub, versus 935 before the expansion. Each client independently caps coating at 1,600 local Parts, plus the pre-existing tool viewmodel and character. These are allocation bounds, **not measured FPS claims**. Terrain generation writes a 128 × 26 × 128 voxel array once in Edit mode. It does not create millions of physics objects or repaint Terrain per scrub.

Before adding substantially larger regions, update the index bounds, Terrain footprint and snapshot bounds together; keep existing cell coordinates stable; re-evaluate the record-size guard; and eventually partition persistent data beyond a single world record. More than 16 concurrent servers needs deliberate slot/matchmaking/budget work. Do not generate the entire real Moon by increasing these constants indiscriminately.

## Validation and required Studio checks

Run:

```sh
python3 tools/validate_generator.py --luau /path/to/luau --compiler /path/to/luau-compile
```

The checks compile the generator and all eight embedded sources; freeze unchanged sky/economy/account behavior against the backup; retain the existing accounting/legacy-save tests; exercise region/chunk mapping, exact sparse codec round-trips and size bounds; and generate twice in an explicit Roblox API stub. World tests execute the actual generated world module against an in-memory DataStore stub to check exclusive leases, save/reload, stale-writer rejection, request budgets, unlocks and offline policies. Expected fault-injection warnings in that test are not evidence of real Roblox service failures.

A coroutine-driven test executes the actual visual loop against synthetic Terrain ray hits: it checks normal alignment, nearby allocation bounds, shared clearing messages, pooling while moving between regions and character cleanup. An additional test inserts the real scrub callback and checks valid terrain rewards, a nearer occluding hit on the same Terrain Instance, forged origins, regional gates, full bags and expired leases. None of these stubs render images, simulate real Roblox streaming/network replication, contact real DataStores, or measure performance.

The owner verified the previous version's sky and cleaning feel. **Codex has not playtested this expansion in Roblox Studio.** Follow the setup guide's single-player, two-player, persistence, streaming, slope-fit and frame-rate checklist before publishing the Roblox place.
