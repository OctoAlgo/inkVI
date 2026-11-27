# Known issues and decisions

## VICTORY_DYNAMIC_SLOTS (patch 0029): opt-in only, not in the preset
On a host that caps view heaps (NVIDIA: 1,000,000 slots for the title's 1,245,184) the heap is laid out as
title slots kept in place `[0, cap - ring)`, then the ring of dynamic slots `[cap - ring, cap)`, then null. Shaders
clamp view indices only at the null slot. So a title index inside the ring's range reads a dynamic slot, i.e. some
other table's descriptor. The default ring (2^18) already has this for title indices 737,856..999,999; a ring of
524,288 widens it to 475,712..999,999. (Pointed out by ThomasHFWright.) It measured +11 % on our checkpoint, with
no visible change there, but a title that names those indices would read wrong views. Fix before it can be a
default: remap title indices past the kept range (or clamp them to null) instead of letting them alias the ring.
Confirmed in play: with 524288 the curly-haired lady's face turned green; with the default ring it is gone.
v0.2.1 (fork #1320: lists of split submissions give their tables' dynamic slots back): the default ring held in
every run of the round (no "no free dynamic descriptor slots", RTX 5070 Ti), as it did for v0.2. The larger ring is
still faster: +15 % back to back on the Ti (8.16 vs 7.10 fps, the same load beside both runs; CHANGELOG.md, v0.2.1),
so the gain does not come from a full ring, and remapping the title's indices is worth doing. Note `VICTORY_DYNAMIC_SLOTS=524288` is clamped to half
the capped heap: the log says 499,999 ring slots and 500,000 title slots kept in place, so the aliased title indices
are 500,000..999,998 (not 475,712.. as above).

## VICTORY_BACK_QUIET (patch 0030): not in the preset
Resetting the write watch after a copy-back can erase a title store that landed concurrently. It measured
+0.0 % +- 8.6 %, so it is out of the preset; the patch stays as an opt-in switch.

## The dark cell -> VICTORY_PIPELINE_WAIT_FIRST_MS (patches 0034-0036)
Symptom: on a cold driver shader cache the cell comes up dark (few shader lookups). Cause: the world's first
passes were dropped while the driver compiled pipelines missing from its cache. Fix: a pipeline's first draw
waits up to N ms (preset 5000) for it instead of being dropped. Inert with warm caches; on a cold start the world
appears later (about 7.5 min instead of 2) but lit.

## VICTORY_DT_MAX (patch 0038): opt-in, untested under driving and combat
Below 15 fps the title counts every frame as 1/15 s, so the game runs in slow motion (0.44x real time at 6.5 fps).
`VICTORY_DT_MAX=0.2` lets a step be up to 0.2 s, so game time follows real time down to 5 fps (measured in the cell:
game speed 0.87-0.93 instead of 0.42-0.45, same frame rate). Checked: no crash, the cell and a boat idling on open
water look normal. NOT checked: driving or steering under input, vehicles at speed, ragdolls, swimming, ladders,
combat. Steps of 0.2 s can let fast objects pass through thin walls or make suspension jitter, and the title's own
smoothing code (63 other places read the shared 1/15 and keep it) sees bigger steps. Frames slower than 5 fps still
lose time. If something misbehaves, try 0.1 or leave it unset. It is in `launch/speed.env` as a commented line.

## Series notes
- `0037-own-resolution-4c6046614.patch`: the series was resolved against fork main 4c6046614 as one merge and
  linearised; the conflicting hunks of the other patches were taken from the picked side and 0037 brings in the
  merge-time resolutions of v0.2 and v0.2.1 (`docs/rebase.md` lists the decisions). Only the full series is
  build-tested; intermediate trees may not compile.
- Fork main switches that do nothing in the kit: `VICTORY_DIRTY_4K` (left out: #995's fine pages,
  `VICTORY_FINE_PAGES`, do the same), `VICTORY_SPREAD_LEAN` (#1352: a form of upstream's spread across z, which
  the kit does not have; #993's split dispatches instead).
- New defaults from fork main in v0.2.1 (nothing to set): a dispatch waits for its compute pipeline until it is
  made (#1312, `VICTORY_PIPELINE_COMPUTE_WAIT=0` turns it off), LDS-flag regions as two host waves
  (`VICTORY_LDS_FLAGS=0` off), card hashing a group a piece (`VICTORY_CARD_HASH_WIDE`, already in the preset),
  512 MB of small tiles on a full card (`VICTORY_TILES_SMALL_WHEN_FULL_MB`), never-filled partly mapped textures
  read with zeros for the missing pages (#1392, `VICTORY_NO_WAIT_PARTIAL=0` off), a small scratch chunk may take a
  kept 4 MiB one (#1367, `VICTORY_SCRATCH_ANY_SIZE=0` off). `VICTORY_CLAMP_WINDOW`, `VICTORY_CLAMP_LEAN` and `VICTORY_GATHER_SEGMENTS` run
  on #995's clamp here, off by default as in main, not measured in the kit.
- 0005 (#995, squashed) leaves out the PR's compiled shader blob `brighten.cso`; `build.sh` makes or fetches it.
- 0014 (Belobug's ambient refinements) comes from the VIctory-Belobug-AMD fork (GPL-3.0, its LICENSE checked).
- Left out as dead weight (default-off experiments nothing depends on): our VICTORY_SYNC_BARRIER and Steenax6's
  FILL_HOT/FILL_DIRECT, LATE_COPY, WAIT_RESIDENT (all measured as noise or worse in rounds 7-9).
- Diagnostics-only and run-tooling patches (0004, 0015, 0022, 0023-0026) do nothing in a release build unless
  their switch is set.

## Faces
Complete faces (eyes, teeth, cheeks, hair in strands) render with the full series and the launch flags of
`launch/README.md`. Parts we know matter, beyond #927 (fork main) + #854/#993: 0019 (after the #993 merge the clamp's
split-dispatch line named a variable that no longer existed: the clamp did not compile and every indirect call
was dropped), #995's indirect path that 0019 fixes, 0009 #683 (compute keeps its own loop limit, so hair strands do
not scatter under `VICTORY_SHADER_LOOP_LIMIT=32`), and #1002/#1489 for shadows on skin. Not bisected per part.

## Black faces while the world streams in: fixed in the base
Textures uploaded before their DirectStorage data (or a landed plain read) arrived kept zeros: black faces in the
opening cutscene and in streamed-in scenes. Fork main e4245f3c1 makes them due again (`VICTORY_PAGE_WRITES`
default 1|2|8; `VICTORY_HEAP_RECHECK_EVERY=<frames>` keeps looking after the schedule). On by default since v0.2,
nothing to set.
