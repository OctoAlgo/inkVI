# Known issues and decisions

## VICTORY_DYNAMIC_SLOTS (patch 0031): opt-in only, not in the preset
On a host that caps view heaps (NVIDIA: 1,000,000 slots for the title's 1,245,184) the heap is laid out as
title slots kept in place `[0, cap - ring)`, then the ring of dynamic slots `[cap - ring, cap)`, then null. Shaders
clamp view indices only at the null slot. So a title index inside the ring's range reads a dynamic slot, i.e. some
other table's descriptor. The default ring (2^18) already has this for title indices 737,856..999,999; a ring of
524,288 widens it to 475,712..999,999. (Pointed out by ThomasHFWright.) It measured +11 % on our checkpoint, with
no visible change there, but a title that names those indices would read wrong views. Fix before it can be a
default: remap title indices past the kept range (or clamp them to null) instead of letting them alias the ring.

## VICTORY_BACK_QUIET (patch 0032): not in the preset
Resetting the write watch after a copy-back can erase a title store that landed concurrently. It measured
+0.0 % +- 8.6 %, so it is out of the preset; the patch stays as an opt-in switch.

## The dark cell -> VICTORY_PIPELINE_WAIT_FIRST_MS (patches 0036-0038)
Symptom: on a cold driver shader cache the cell comes up dark (few shader lookups). Cause: the world's first
passes were dropped while the driver compiled pipelines missing from its cache. Fix: a pipeline's first draw
waits up to N ms (preset 5000) for it instead of being dropped. Inert with warm caches; on a cold start the world
appears later (about 7.5 min instead of 2) but lit.

## Series notes
- `0039-own-resolution-ceb9e1f7a.patch`: our stack was built as merges of fork main; linearised onto ceb9e1f7a,
  the conflicting hunks of 0005/0006/0012/0014/0025/0029 were taken from the picked side and 0043 brings in the
  merge-time resolutions. Only the full series is build-tested; intermediate trees may not compile.
- 0005 (#995, squashed) leaves out the PR's compiled shader blob `brighten.cso`; `build.sh` makes or fetches it.
- 0016 (Belobug's ambient refinements) comes from the VIctory-Belobug-AMD fork (GPL-3.0, its LICENSE checked).
- Left out as dead weight (default-off experiments nothing depends on): our VICTORY_SYNC_BARRIER and Steenax6's
  FILL_HOT/FILL_DIRECT, LATE_COPY, WAIT_RESIDENT (all measured as noise or worse in rounds 7-9).
- Diagnostics-only and run-tooling patches (0004, 0017, 0024, 0025-0028) do nothing in a release build unless
  their switch is set.

## Faces
Complete faces (eyes, teeth, cheeks, hair in strands) render with the full series and the launch flags of
`launch/README.md`. Parts we know matter, beyond #927 + #854/#993: 0021 (after the #993 merge the clamp's
split-dispatch line named a variable that no longer existed: the clamp did not compile and every indirect call
was dropped), #995's indirect path that 0021 fixes, 0009 #683 (compute keeps its own loop limit, so hair strands do
not scatter under `VICTORY_SHADER_LOOP_LIMIT=32`), and #1002/#1489 for shadows on skin. Not bisected per part.
