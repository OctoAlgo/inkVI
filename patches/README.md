# The series

Applied in this order on the pinned base (`../BASE`) by `build.sh`. Each patch carries `Kit-Source:` and
`Kit-Licence:` trailers; squashed PR patches carry the PR author as the commit author.
v0.2 dropped v0.1's 0012 (#927) and 0013 (#1002), both in fork main now, and renumbered the rest in order;
0037 replaces v0.1's resolution patch 0039 (`../docs/rebase.md`).

| # | patch | subject | source | licence |
|---|-------|---------|--------|---------|
| 0001 | `0001-vpr2143-desp.patch` | Shaders: the code table starts after the instructions (port of Marvisak/VIctory#2143) | Marvisak/VIctory #2143 (desp), port | GPL-3.0 |
| 0002 | `0002-fork20-dxc-fallback.patch` | DXC fallback for runtime HLSL under Wine (fork PR #20) | victory-fork PR #20, ported by Octo | GPL-3.0 |
| 0003 | `0003-vpr454-no-watchdog.patch` | VICTORY_NO_WATCHDOG loader hook | Marvisak/VIctory PR #454 (via the testers integration build), ported by Octo | GPL-3.0 |
| 0004 | `0004-own-diag-scripted-keys.patch` | scripted keys VICTORY_KEYS_HOLD / VICTORY_KEYS_FILE (diagnostics only) | own (diagnostics build only) | GPL-3.0 |
| 0005 | `0005-fork995-tunczzz.patch` | merge fork PR #995 (frame rate: indirect clamps in runs, landing fetches from card slots; tunczzz) | victory-fork PR #995 (tunczzz), squashed; brighten.cso left out: build.sh makes it from brighten.hlsl or takes it from #995 | GPL-3.0 |
| 0006 | `0006-fork1005-spaghettimaster545.patch` | xmem: tell the GPU side of an unmapped view after unmapping it | victory-fork PR #1005 (SpaghettiMaster545) | GPL-3.0 |
| 0007 | `0007-own-fix995-indirect-import.patch` | indirect.rs needs windows::core::s after the merge | own (build fix after #995) | GPL-3.0 |
| 0008 | `0008-own-fix995-keys-diag-only.patch` | the keys file is read in diagnostics builds only (release build after the #995 merge) | own (build fix after #995) | GPL-3.0 |
| 0009 | `0009-fork683-danigamer05.patch` | A loop limit for compute programs alone (hair strands no longer scatter with VICTORY_SHADER_LOOP_LIMIT=32) | victory-fork PR #683 (Danigamer05) | GPL-3.0 |
| 0010 | `0010-fork917-uwucammie-ambient.patch` | GPU: a constant can stand in for indirect light while rays do not run (VICTORY_AMBIENT, off by default) | victory-fork PR #917 (UwUCammie, port of Belobug's ambient) | GPL-3.0 |
| 0011 | `0011-own-fix917-dxc.patch` | ambient stand-in compiles through the DXC fallback; #995's title tests on Windows only | own (build fix for #917 under the DXC fallback) | GPL-3.0 |
| 0012 | `0012-fork854-993-pilotecode-wave64.patch` | merge fork PRs #854 + #993 (PiloteCode: wave64 programs in a paired form on 32-lane GPUs, geometry programs, l | victory-fork PRs #854 + #993 (PiloteCode), squashed together | GPL-3.0 |
| 0013 | `0013-vpr1489-ascilch-gather4-c.patch` | Shaders: lower image_gather4_c_lz and image_gather4_c_lz_o (MIMG 0x4f, 0x5f) | Marvisak/VIctory #1489 (AscilCH) | GPL-3.0 |
| 0014 | `0014-belobug-ambient-refinements.patch` | Belobug's ambient light refinements on #917's stand-in (beloooo, VIctory-Belobug-AMD 4ffc4766 cd9f78ce 44dcd43 | Belobug, VIctory-Belobug-AMD 4ffc4766 cd9f78ce 44dcd437 c3bd5612, ported by Octo | GPL-3.0 (VIctory-Belobug-AMD LICENSE checked) |
| 0015 | `0015-own-diag-slow-pipeline.patch` | name the host pipelines that take long to make (SLOW-PIPELINE log lines; missing() names the shaders being mad | own (diagnostics build only) | GPL-3.0 |
| 0016 | `0016-fork938-powplusplus-back-edge.patch` | Shaders: one back edge per loop header | victory-fork PR #938 (hh-ze; powplusplus, from Marvisak/VIctory #2309) | GPL-3.0 |
| 0017 | `0017-fork938-desp-back-edge.patch` | Shaders: one back edge per block, for vkd3d-proton | victory-fork PR #938 (hh-ze; desp, from Marvisak/VIctory #2309) | GPL-3.0 |
| 0018 | `0018-fork938-hzaidi-warmup-keys.patch` | Persist pipeline warmup keys without an application cache | victory-fork PR #938 (hh-ze; Husain Zaidi) | GPL-3.0 |
| 0019 | `0019-own-fix993-clamp-name.patch` | the clamp's split-dispatch line reads rec_records (the #993 merge left #993's name: the clamp did not compile, | own (fix of the #993 merge: the clamp did not compile) | GPL-3.0 |
| 0020 | `0020-fork1032-uwucammie-copy-plain.patch` | GPU: fault-guarded in-place write-back in plaincopy for write_mapped (VICTORY_COPY_PLAIN=1) | victory-fork PR #1032 (UwUCammie) | GPL-3.0 |
| 0021 | `0021-fork989-gmanka-detile-bound.patch` | GPU: bound detiling slices to the upload allocation | victory-fork PR #989 (gmanka) | GPL-3.0 |
| 0022 | `0022-own-diag-backreads.patch` | backreads' page stamp reads #995's Written map (diagnostics build) | own (diagnostics build only) | GPL-3.0 |
| 0023 | `0023-own-tools-frame-clock.patch` | world-frame clock for short repeatable runs | own (run tooling, opt-in) | GPL-3.0 |
| 0024 | `0024-own-tools-run-end.patch` | runs end when their purpose is done; press-until-ready keys | own (run tooling, opt-in) | GPL-3.0 |
| 0025 | `0025-own-tools-exit-after-shots.patch` | VICTORY_EXIT_AFTER_SHOTS hook in the frame shot | own (run tooling, opt-in) | GPL-3.0 |
| 0026 | `0026-own-tools-exit-after-last-shot.patch` | VICTORY_EXIT_AFTER_SHOTS waits for the last listed frame's own shot | own (run tooling, opt-in) | GPL-3.0 |
| 0027 | `0027-own-made-stripes.patch` | Host heap slots behind striped locks (VICTORY_MADE_STRIPES; 1 = one lock as before) | own | GPL-3.0 |
| 0028 | `0028-own-made-check.patch` | VICTORY_MADE_CHECK on #995's wide sync (fable-lock 3b39c666's check, ported) | own | GPL-3.0 |
| 0029 | `0029-own-dynamic-slots.patch` | VICTORY_DYNAMIC_SLOTS=<n>: a larger ring of dynamic view slots on a capped host heap (off by default) | own (opt-in; see docs/known-issues.md) | GPL-3.0 |
| 0030 | `0030-fork1188-yorivel-back-quiet.patch` | GPU: VICTORY_BACK_QUIET=1: copy-backs of write-watched memory no longer read as title writes | victory-fork PR #1188 (Yorivel) | GPL-3.0 |
| 0031 | `0031-own-back-no-wait.patch` | VICTORY_BACK_NO_WAIT=1, title copies into flights' writes run at once, marked fresher than their landing | own (opt-in) | GPL-3.0 |
| 0032 | `0032-fork868-chipsrain-skip-wc-back.patch` | fork #868 VICTORY_SKIP_WC_BACK (census.rs from fef959240, hand-ported onto our relay / in-flight / merge piece | victory-fork PR #868 (Chipsrain), hand-ported by Octo | GPL-3.0 |
| 0033 | `0033-vpr2723-image-atomics.patch` | VIctory #2723: image atomics name a U32 element in the handle annotation (d678bc26a; the handle key by element | Marvisak/VIctory #2723, ported by Octo | GPL-3.0 |
| 0034 | `0034-own-pipeline-watch.patch` | pipeline workers' watch line + VICTORY_PIPELINE_PRIORITY=normal (dark-cell hunt) | own (diagnostics + VICTORY_PIPELINE_PRIORITY) | GPL-3.0 |
| 0035 | `0035-own-pipeline-wait-early.patch` | VICTORY_PIPELINE_WAIT_EARLY_MS: a pipeline's first draw waits for it while early pipelines are queued (dark-ce | own (dark-cell fix, step 1) | GPL-3.0 |
| 0036 | `0036-own-pipeline-wait-first.patch` | the first-draw wait for every pipeline, renamed VICTORY_PIPELINE_WAIT_FIRST_MS | own (dark-cell fix: VICTORY_PIPELINE_WAIT_FIRST_MS) | GPL-3.0 |
| 0037 | `0037-own-resolution-e4245f3c1.patch` | Resolution: the fork-main conflicts of this series on e4245f3c1 | own (merge-time conflict resolutions, linearised) | GPL-3.0 |
