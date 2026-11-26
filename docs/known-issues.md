# Known issues and decisions

## VICTORY_DYNAMIC_SLOTS (patch 0029): opt-in only, not in the preset
On a host that caps view heaps (NVIDIA: 1,000,000 slots for the title's 1,245,184) the heap is laid out as
title slots kept in place `[0, cap - ring)`, then the ring of dynamic slots `[cap - ring, cap)`, then null. Shaders
clamp view indices only at the null slot. So a title index inside the ring's range reads a dynamic slot, i.e. some
other table's descriptor. The default ring (2^18) already has this for title indices 737,856..999,999; a ring of
524,288 widens it to 475,712..999,999. (Pointed out by ThomasHFWright.) It measured +11 % on our checkpoint, with
no visible change there, but a title that names those indices would read wrong views. Fix before it can be a
default: remap title indices past the kept range (or clamp them to null) instead of letting them alias the ring.

## VICTORY_BACK_QUIET (patch 0030): not in the preset
Resetting the write watch after a copy-back can erase a title store that landed concurrently. It measured
+0.0 % +- 8.6 %, so it is out of the preset; the patch stays as an opt-in switch.

## The dark cell -> VICTORY_PIPELINE_WAIT_FIRST_MS (patches 0034-0036)
Symptom: on a cold driver shader cache the cell comes up dark (few shader lookups). Cause: the world's first
passes were dropped while the driver compiled pipelines missing from its cache. Fix: a pipeline's first draw
waits up to N ms (preset 5000) for it instead of being dropped. Inert with warm caches; on a cold start the world
appears later (about 7.5 min instead of 2) but lit.

## Series notes
- `0037-own-resolution-e4245f3c1.patch`: the series was resolved against fork main e4245f3c1 as one merge and
  linearised; the conflicting hunks of the other patches were taken from the picked side and 0037 brings in the
  merge-time resolutions (`docs/rebase.md` lists the decisions). Only the full series is build-tested; intermediate
  trees may not compile.
- Fork main switches that do nothing in the kit: `VICTORY_DIRTY_4K` (left out: #995's fine pages,
  `VICTORY_FINE_PAGES`, do the same). `VICTORY_CLAMP_WINDOW`, `VICTORY_CLAMP_LEAN` and `VICTORY_GATHER_SEGMENTS` run
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
