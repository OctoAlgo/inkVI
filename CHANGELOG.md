# Changelog

All numbers: RTX 5090, release build, the prison-cell checkpoint of `docs/scene.md`, mean fps over world frames
300-600 with a warm shader cache unless noted. "Desktop" = a real Wayland session; Xvfb numbers are lower and only
compared with each other. Single runs; the 95 % range is given where we had a pooled spread.

## v0.2 (base e4245f3c1, 37 patches)

| step | what | measured | picture |
|------|------|----------|---------|
| base | ceb9e1f7a -> fork main e4245f3c1 (#646, #1002, #1314, #1324, #589, #702, #1112, VIctory #3198, #927 + #3124 in 58de9bf4c; `VICTORY_PAGE_WRITES` default 1\|2\|8) | | |
| dropped | 0012 #927 and 0013 #1002 (in fork main; #1002 byte-identical, #927 a newer revision); 0039 replaced by 0037 (resolution on e4245f3c1) | | |
| kept ours | #995's clamp (main's clamp window / lean clamps / gather segments run on it), #993 split dispatches over upstream's spread (#646 thread counts wired in), #995 fine pages over `VICTORY_DIRTY_4K` (left out); see `docs/rebase.md` | | |
| tests | `cargo check --tests` (Windows target) for victory, victory-gpu, victory-hle, victory-shader: clean (v0.1's own test code did not compile; fixed in 0037); native `cargo test -p victory-shader --lib`: 209 passed, 3 ignored | | |
| proof | `build.sh` into an empty dir, release + diag, brighten.cso fetched and checked; tree = the resolved merge | builds (76 s on the 5090 host, deps from scratch) | |
| run 1 | diag, `scene:robbery`, Xvfb, cold (new translator: 877 translated), capture of the world's first frames | 0 Xid; world 4 min after start | faces complete and lit from world frame ~75 (close-up at 80); the cutscene's first shot (world frame 2) still dark-faced, as v0.1's world frame 6; 3,261 texture slots made due again by the page-writes fix |
| run 2 | release, prison-cell checkpoint, preset + `DYNAMIC_SLOTS=524288` (= `--pr9b`), **desktop**, first run after the translator change (825 translated) | **7.49 fps** world frames 300-600 (quarters 8.13 7.83 7.71 6.50), 0 Xid. v0.1 on the desktop: `--pr9b` 7.99, warm runs 7.40-8.22; v0.1's kit proof 6.95 was Xvfb | no picture taken (2-run limit) |

Housekeeping: `launch/README.md` no longer lists `VICTORY_BORDERLESS=1`, which no patch of this kit adds (the
borderless window is `0001-own-borderless-window` of inkVI-ultrawide). `launch/speed.env` unchanged: every switch it
sets is still read. Known issue "black faces while the world streams in" is fixed in the base (docs/known-issues.md).
Shader counts: with a warm cache the run line reports the cache's size (3661 on this machine, any scene); a run
after a translator change reports the shaders translated in that run, so "3661 = lit" does not apply to it.

## v0.1 (base ceb9e1f7a; = our `--pr9b`)

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
