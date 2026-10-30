# Hex sectors, cleanable terrain, grounded base and workshop

## Confirmed causes of the non-responsive coating

The old renderer created dirt using a horizontal grid and the Terrain normal, but the server added a **3D spherical distance veto** on candidate cell centers. On a steep plane, a valid horizontal neighbor is much farther vertically. Thus the client could show eligible-looking coating that the server rejected even though it was within the configured horizontal brush footprint. This was not a shortage of cleaning range or Power.

The server also rejected an entire scrub using `Regions.At(rawHitX,rawHitZ)`, whereas saved cells/rendered coating used `Regions.Cell(gridX,gridZ)` at **cell centers**. Near irregular region edges the two can have different memberships. The brush could be aimed at an unlocked coating edge, while the raw-point check classified it as locked or outside the survey. Locked coating itself had almost the same appearance as unlocked coating, making valid denials look like broken cleaning.

Finally, decorative rock WedgeParts had `CanQuery=false` but retained default `CanCollide=true`. Roblox query exclusion requires non-colliding geometry; those wedges could leave a queryable bounding volume. Invisible SpawnLocation geometry was also collidable/queryable above the already-raised base floor. These flags are corrected. Real colliding structures still block ground aim normally.

The current generated code has been inspected and these failure paths are covered by tests. Codex has **not reproduced the owner's particular camera views in Studio**, so these findings do not prove every possible occlusion/visual artifact is resolved on every slope.

## Cleaning corrections without a balance change

- `Regions.Resolve` is the canonical world-hit → grid-cell lookup for the aim HUD. Saved health, render membership and permissions use the same cell centers. Zero coordinates are normalized to avoid signed-zero key artifacts.
- The server iterates the unchanged horizontal brush footprint and checks **each candidate's actual region access**, rather than denying all overlap at the center's raw region boundary. A brush can naturally cross into an unlocked neighbor, but it cannot reward a locked cell.
- `Regions.BrushDistance` preserves the existing horizontal falloff, Power, radius and reward calculation. It replaces the inappropriate sphere veto with a tangent-plane continuity test for neighbors. The canonical target cell remains eligible at a sharp lip if its rendered normal is eligible; a neighboring disconnected ledge is still rejected.
- Both renderer and server use the same minimum upward normal, 0.35. Cliff faces below this threshold do not receive coating and do not yield rewards. Terrain range, head-origin checks, line of sight, request rate limits, bag caps and world lease guards are retained.
- The HUD explicitly reports LOCKED, UNSURVEYED, SYNCING, CLEAN GROUND, a steep face with NO CLEANABLE COATING, or unavailable surface saving as appropriate. Locked coating has a subtly warmer neutral tint. The server supplies throttled lock/structure hints instead of silent denials in those cases.
- Config, Economy and Environment remain **byte-for-byte identical** to the tested baseline. The account loading/saving, selling, purchase and character-setting block is unchanged. Starting center speed remains about 4.5 seconds; tool efficiency on a level plane and all prices/rewards/storage are unchanged. Fixing previously rejected slope cells restores intended eligibility, rather than increasing range or damage.

## Hex sectors and save compatibility

There are **64 derived hex sectors**, with a 16-stud circumradius (32 studs vertex-to-vertex). Pointy-top axial coordinates identify sectors, displayed as `HX +00 / -01`, etc. Deterministic cube rounding handles shared edges; integer formatting prevents a negative-zero `-0` key from duplicating sector `0`.

The existing 39,767 cell positions, original region masks/priority, chunk keys/local IDs, sparse encoding and DataStore names are unchanged. Every cell is assigned to its nearest hex **by its existing center**. Sectors are an organizational view over this saved map, not a new health grid. No reset, rounding migration or new sector DataStore is needed. Sector counters are rebuilt from existing saved health at load and incremented with shared damage. Full-precision cell saves continue as before.

Sector percentages count partial health removal. Sector states are DIRTY, IN PROGRESS, LOCKED, MIXED ACCESS and COMPLETE. A hex spanning two regions may have mixed cleaning permission: access is still checked per cell using the existing tool-or-5%-prior-region rule. A completed sector stays completed even if its region would otherwise require a higher tool. No sector purchase, completion requirement, new price or progression currency was added.

Client-side survey filaments follow sampled Terrain in short segments. Shared edges are deduplicated, and out-of-survey segments are omitted. At most 420 line Parts render within 54 studs, with a maximum of 70 new segments built per update, with local depth-tested labels. Colors remain muted: ochre dirty, gray locked, teal in progress and pale restored. They are visual guides, **not flat hex platforms, colliders or cleaning targets**. Because the original 0.85-stud cells are preserved, the displayed geometric hex edge can differ from a cell-center ownership boundary by a fraction of a cell. Both sides remain scrubbable according to cell permission.

No extra DataStore writes are performed for hexes; nearby sector summaries join the existing subscription responses. The previous survey-slot behavior and crash-window limitations remain: there are 16 leased persistent survey worlds, matchmaking need not return an account to the same slot, and player/world writes are separate transactions. See REGIONAL_SURFACE_NOTES.md.

## Grounded base and equipment workshop

The old foundation top was Y=1 while the intended base Terrain was around Y=-0.6. The new generator raycasts the **actual generated Terrain** and sets the foundation top 0.08 studs above it. The foundation is thinner and partially embedded. The habitat, depot, terminal and workshop move down together, keeping machinery grounded instead of leaving it floating after the floor adjustment. Muted regolith aprons soften the edges.

The SpawnLocation remains above the floor, neutral and invisible, but is non-colliding, non-touching and non-queryable. It no longer creates an invisible raised floor or brush obstacle. Its position is derived from the new sampled floor height. Engine spawning, character movement and the base transition still require a Studio check.

The workshop is built around the existing terminal X/Z interaction location: canopy, structural columns, rear wall, racks, three original primitive tool displays, calibration motor/bench, diagnostics screen, lit sign, conduits and task lighting. Depot/terminal anchor heights follow the floor, while their names, X/Z positions, prompt settings and server proximity rules remain. Upgrade rows show owned tool/levels, effects, next cost, affordability and maximum ownership. They send the same Action keys to the same purchase validator. Prices come from the unchanged Config.

## Earth and stars without another sky workaround

The native black sky and its runtime repair module are untouched. A separate client `Celestial` module creates an original low-resolution primitive Earth with blue oceans, hand-authored geographic silhouettes and polar ice, plus a sparse star field. It creates **no Sky, Atmosphere or Clouds instances**, changes no Lighting values, and uses no new texture/marketplace assets.

Earth is a finite decoration approximately northwest/upward from the base (roughly 3.6 degrees across), not a full-screen backdrop. Its reference model translates with camera position when movement exceeds 0.1 studs, retaining a fixed astronomical direction regardless of head rotation. Its modest local light illuminates the globe at a distance and does not reach the lunar ground. All orbital geometry is anchored, non-queryable, non-colliding and non-shadow-casting. It cannot become a brush hit or block sunlight. There is no new periodic sky repair or blue background fallback.

The structural check counts 343 local celestial Parts. This is a deliberately approximate geographic globe, not a photoreal Earth texture. Very low graphics/draw-distance settings can affect finite-object visibility, but loss of a decoration cannot expose a blue sky because the background remains the existing native black sky. Earth appearance, illumination, point-star visibility and model motion need Studio rendering checks.

## Performance, backups and checks

The static generated map now has 463 Parts in the structural stub. Coating retains its existing 1,600-part pool cap and creation budget; hex lines have a separate 420-part cap; celestial geometry is 343 local Parts. These are allocation limits/counts, **not measured frame-rate guarantees**. Terrain/chunks remain the previous bounded region; neither a planet-sized mesh nor millions of Parts are generated.

Backup: `backups/LunarCleanupGenerator.pre-hex-workshop.lua`. Earlier backups remain intact. The existing bounded Terrain preservation and safe-to-rerun service-root replacement are retained. Neither player nor survey DataStores are cleared. For rollback to the previous regional version, run that complete backup in Edit mode; do not delete saved progress.

Run:

```sh
python3 tools/validate_generator.py --luau /path/to/luau --compiler /path/to/luau-compile
```

Checks compile the generator and all ten embedded sources; freeze the sky/economy/account behavior; compare old and new region ownership/codec functions; test all existing cell/chunk mappings; verify six hex edges, sector totals/states and signed-zero handling; exercise steep-plane and disconnected-ledge eligibility; run the actual scrub callback with simulated slope/region/hex-boundary raycasts and locked targets; check legacy profile and old-format world load/save; and inspect bounded scene geometry, grounded floor/spawn flags, sector counters and non-interference of celestial objects with native sky settings.

All these use explicit stubs or pure Luau. They do not measure Roblox render performance, reproduce real Terrain surface interpolation, simulate actual network replication, or contact Roblox DataStores. **Codex has not playtested this update in Roblox Studio.** Follow the updated guide's slope, edge, lock, two-player, floor/spawn, workshop, persistence and sky-decoration checks before publishing the place.
