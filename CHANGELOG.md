# Changelog

All numbers: RTX 5090, release build, the prison-cell checkpoint of `docs/scene.md`, mean fps over world frames
300-600 with a warm shader cache unless noted. "Desktop" = a real Wayland session; Xvfb numbers are lower and only
compared with each other. Single runs; the 95 % range is given where we had a pooled spread.

## Unreleased (kit 0.1, base ceb9e1f7a; = our `--pr9b`)

| round | patches | measured | picture |
|-------|---------|----------|---------|
| 1 | 0005 #995, 0006 #1005, 0007-0008 build fixes; preset from #995's notes | 1.87 -> 3.54 fps, first room | same; leaving VIEW_GUARD=0 / COMMIT_FLOOR_MB out keeps the cell's left wall and window mesh |
| 2 | 0012 #927 faces, 0013 #1002 shadows | 4.2-4.8 fps first rooms (3.54 before) | faces skin-shaded, mouths move; wall + mesh kept |
| 3 | 0014 #854/#993, 0015 #1489, 0016 ambient refinements, 0018-0020 #938, 0021 clamp fix | 4.72 fps checkpoint stretch (diag) | complete faces in the bar cutscene; warm lit cell with `VICTORY_AMBIENT*` |
| 4 | 0022 #1032 in-place write-back (+ COPY_PLAIN, JOIN_PARTS, BACK_OWN_VIEW, GPU_UPLOAD, CARD_REHASH_RUNS) | 5.79 fps / 173 ms steady (4.72 before); whole world 4.36 (3.62) | same |
| 7 | 0029 striped host-heap lock (MADE_STRIPES=1024, SYNC_WIDE=8), TEXTURE_BACK | +8.3 % +- 3.8 % (Xvfb) | same lit room; the boat no longer sinks (#999 read-back) |
| 8 | 0031 DYNAMIC_SLOTS, 0032 BACK_QUIET, CARD_HASH_WIDE, TABLE_STAGES, CARD_BUFFERS_MB=1536 | +15.8 % as a set (desktop 6.58 vs 5.68) | same |
| 9a | CARD_BUFFERS_MIN_KB=64 (small title buffers resident on the card) | **+33.5 % +- 6.4 %** (desktop 8.31 / 8.08 vs 6.14); card wait 60 -> 26 ms | lit cell, same picture |
| 9a | take-outs on top: DYNAMIC_SLOTS off -10.8 %, CARD_BUFFERS_MB=1024 -50 %, BACK_QUIET off +0.0 % (+- 8.6 %) | | BACK_QUIET dropped from the preset |
| 9b | base -> ceb9e1f7a; 0036-0038 dark-cell fix (PIPELINE_WAIT_FIRST_MS=5000) | 7.99 fps desktop (7.94 before: the new base costs nothing) | cold starts come up lit (world at 7.5 min instead of 2) instead of a dark cell |
| kit | DYNAMIC_SLOTS taken out of the preset (docs/known-issues.md) | expect about -11 % vs `--pr9b` | |
| kit proof (39 patches) | `build.sh` into an empty dir, release + diag, brighten.cso fetched and checked | builds; tree = the 43-patch proof minus the 4 dropped default-off experiments | no run (only default-off code left out) |
| kit proof (43 patches) | `build.sh` into an empty dir, release, preset + DYNAMIC_SLOTS=524288 (= `--pr9b`), Xvfb | 6.95 fps (quarters 6.68-7.15), 0 Xid | lit cell (all 3661 shader lookups hit; a dark cell shows ~825) |

Other fork patches in the series (0009 #683, 0010 #917, 0023 #989, 0034 #868, 0035 VIctory #2723) are correctness
fixes or opt-in switches that measured as noise or are off in the preset.

kit 0.1 housekeeping: 39 patches (was 43): dropped SYNC_BARRIER and Steenax6 FILL_HOT/LATE_COPY/WAIT_RESIDENT
(default-off dead weight), #995's compiled blob no longer shipped, PR authors set on the squashed PR patches.
