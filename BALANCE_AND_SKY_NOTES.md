# Sky investigation and progression model

## What the existing code establishes

The old generator gave `LunarSky` six empty texture fields. Empty content does **not** define a black cubemap. It achieved blackness with six ordinary Workspace walls centered 800 studs from the origin. Edit mode displays the full Workspace; a runtime streaming client can lack or stream out distant parts. Removing an extra Sky does not restore a missing backdrop or turn an empty cubemap black. The old runtime server/client scripts did not restore Lighting, inspect Terrain Clouds, or handle an environment object added after generation.

Roblox's official [Sky reference](https://create.roblox.com/docs/reference/engine/classes/Sky) describes the six sky textures and their default Roblox sky content. Its [streaming documentation](https://create.roblox.com/docs/workspace/streaming) explains that streaming is enabled by default for new places and distant parts can be absent from the client's Workspace. [Clouds](https://create.roblox.com/docs/reference/engine/classes/Clouds) render through Terrain; deleting Sky does not disable them. These sources were consulted during investigation.

These are confirmed generator defects and explain a plausible Edit-versus-Play failure path. Codex cannot inspect the owner's live Studio runtime, installed plugins, or Output from this workspace. The exact origin of the reported extra `Sky`, whether streaming was active in that particular run, and whether the reported clouds were skybox imagery or a Terrain Clouds instance remain unconfirmed. None of the old generated gameplay scripts added the reported extra Sky during Play. Do not attribute it to a particular external script without runtime evidence.

The updated generator prints an inventory of actual environment instances and flags accessible place scripts containing environment references, without dumping their source. Runtime conflict messages give the object class and full path. These diagnostics distinguish observed conflicts from suspected script ownership. Plugins or inaccessible CoreScripts are outside that source audit.

## Implemented environment correction

- Retain the owned Edit-mode backdrop, and create six actual black, opaque, camera-relative parts **locally on each client**, before waiting for streamed yard geometry. They require no image uploads or guessed IDs. The background no longer depends on a distant server part being streamed in.
- Camera translation updates each frame; the backdrop does not rotate with the head. It does not collide, cast shadows, trigger touch, or participate in queries. Six local static-shaped parts are the only added per-client geometry.
- Use one shared Environment module during Edit generation and runtime startup on both server and client. Archive extra Sky and Atmosphere objects, disable/archive Terrain Clouds, and respond to new environment children and Lighting changes. A two-second check also catches later reparenting. Objects are preserved, not destroyed.
- Preserve brightness 3.5, clock time 15.7, hard shadows, and the existing ambient fill and exposure. Do not darken the surface to get a black sky. Turn off sky-derived diffuse/specular contributions so the unused default cubemap cannot tint metal blue; direct sunlight remains active. Floodlights and the restrained grading/bloom remain.
- There is still a LunarSky object for consistent celestial settings. Its empty fields are **not** claimed to supply black imagery; the local backdrop supplies the black background deliberately.

The structural tests exercise conflict archiving, Lighting restoration, recreating a removed LunarSky, and an independent local backdrop after removing world backdrop parts. They cannot validate Roblox rendering or show which external script created an object. Follow the Studio checklist in the setup guide.

## Balance configuration

All adjustable values are in the **BALANCE CONFIGURATION** block near the top of `LunarCleanupGenerator.lua`. Edit that source and regenerate in Edit mode for permanent changes. During a temporary Play test, changing generated Config does not reliably update already-required module values; stop and regenerate instead.

| Tool | Radius, studs | Power, health/sec per patch before falloff | Unlock price |
| --- | ---: | ---: | ---: |
| Toothbrush | 0.48 | 1.2 | Free |
| Regolith Brush | 0.85 | 1.7 | 1,000 |
| Industrial Scrubber | 1.35 | 2.6 | 4,500 |

A patch retains 12 health. Damage is now fractional, evaluated at roughly 10 requests/sec, with distance falloff up to 45%. The old `max(1, floor(...))` imposed at least 10 health/sec per affected patch even if tool Power was reduced. Removing that floor is essential: a center patch now fades by approximately 1% per 0.1-second starting-brush request and needs 10 seconds of continuous center contact. Neighboring patches take longer according to falloff. Long gaps are capped at 0.14 seconds of damage, with no offline scrubbing gain.

Each removed health unit yields **0.5 dust**, and selling yields **2 credits per whole dust**. Thus a full patch still contains 12 credits of potential value, but earns it through slower, deliberate work. Fractional dust is saved as `DustCarry`; it survives sales and rejoins. Integer HUD storage remains compatible. A full bag prevents further damage, including fractional overflow. The server continues to own raycast validation, damage, rewards, sales, and purchases.

| Upgrade | Successive prices | Effect |
| --- | --- | --- |
| Speed | 220 / 650 / 2,100 / 5,500 | +20% of base power per level |
| Radius | 300 / 950 / 4,200 | +10% of base radius per level; more covered patches |
| Storage | 180 / 550 / 1,200 / 3,800 / 7,800 | Capacity 100 → 260 → 560 → 1,000 → 1,700 → 2,600 |

Storage gives substantially longer work sessions and fewer sales trips, with no movement penalty. Every capacity is at least its old equivalent. The coating refresh delay is reduced from 35 to 12 seconds after a deck is completely cleaned, keeping work available for groups. There are no new waiting gates, energy timers, or earnings caps.

## Mathematical timing estimates

The model integrates the actual brush footprint/falloff over uniformly distributed aim offsets in a 0.85-stud patch cell. Unupgraded theoretical rates on fully dirty interior ground are approximately **2.03, 6.40, and 20.52 health/sec** for the three tools. These include overlap across multiple patches, rather than treating Power as total brush output. Brush upgrades are approximately three times better at each tier before other upgrades.

Let `R` be theoretical health/sec, `e` effective contact efficiency, `Y=0.5` dust/health, `P=2` credits/dust, `B` bag capacity, and `T=12` seconds per round trip and sale:

```
Dust/sec while working = R × e × Y
Work time per bag = B / (R × e × Y)
Average credits/sec = (B × P) / (B / (R × e × Y) + T)
Time to afford a purchase ≈ cost / average credits/sec
```

Baseline `e=0.65` covers missed aim, already-clean patches, edge losses, and repositioning **apart from** selling travel. It is an assumption, not measured telemetry or a code-imposed multiplier. The model uses continuous average sales; actual whole-bag sales, leftover wallet money, shop decisions, and shared-deck contention add variation. Full 12-health patch work is not simulated as a player path. The footprint integration and allowance are a pacing estimate, not a guaranteed clear-rate measurement.

A reference route from a new, zero-credit profile:

1. Buy Storage 1, then Regolith Brush: about **15.4 minutes cumulative**.
2. Buy Speed 1, Radius 1, Storage 2, then Industrial Scrubber: about **33.1 minutes cumulative**.
3. Finish Storage 3, Speed 2, Radius 2, Speed 3, Storage 4, Radius 3, Speed 4, Storage 5: about **49.7 minutes cumulative**.

“Complete progression” here means all three tools **and all currently available support upgrades**. All tools alone are unlocked at the advanced-equipment milestone. This makes the late stage a series of useful upgrades rather than delaying the third tool until the end of an hour.

| Contact efficiency assumption | First tool upgrade | Advanced tool | All tools and upgrades |
| --- | ---: | ---: | ---: |
| 50% | 19.9 min | 42.5 min | 63.4 min |
| 65% baseline | 15.4 min | 33.1 min | 49.7 min |
| 80% | 12.7 min | 27.3 min | 41.1 min |

Targets are achieved by the baseline route, not guaranteed for every player or purchase order. Existing players deliberately retain their money and equipment and may skip most of this route. Buying different upgrades first changes the rates. Use observed Studio/published-session times to tune the values after testing.

## Save compatibility and validation

The DataStore stays `LunarCleanup_v1`, with unchanged player keys, session leases, and save scheduling. Money, whole dust, tool indices 1–3, and upgrade levels keep their meanings. No account is reset or charged retroactively. Existing carried dust sells at the new price; it is not silently converted or removed. Missing fractional carry defaults to zero. Over-capacity legacy dust is retained and can be sold before collecting more. Older backup versions do not understand fractional carry and can discard that sub-unit field if used after this update, so save backups and avoid switching live save writers back and forth.

Run with an official Luau interpreter/compiler installed:

```sh
python3 tools/validate_generator.py --luau /path/to/luau --compiler /path/to/luau-compile
```

Checks compile the generator plus Config, Environment, Economy, server, and client sources; execute the actual production fractional-accounting functions and save sanitizer; check shared rewards, bag caps, repeated sales, sub-unit conservation, legacy level preservation, and timing estimates; and generate the map twice in a structural Roblox API stub. The stub also tests runtime environment conflict handling and local backdrop independence. It does **not** implement Roblox physics, streaming, replication, rendering, real DataStores, or Studio execution.

The pre-change generator is `backups/LunarCleanupGenerator.pre-sky-balance.lua`. The older initially tested version remains in `backups/LunarCleanupGenerator.studio-tested.lua`. Do not delete or reset production player data to test new-user pacing. This update has not been playtested in Studio by Codex.
