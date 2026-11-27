# Moving to a newer fork main

    git clone https://github.com/fxceless/victory-fork src && cd src
    git checkout -b inkvi <BASE_COMMIT from ../BASE>
    git am ../patches/*.patch                               # the current series
    git -c rerere.enabled=true rebase <new fork main>      # resolve conflicts patch by patch
    # drop patches whose change is now in fork main (git rebase says "dropping ... already upstream";
    # squashed PR patches like 0005 (#995) and 0012 (#854/#993) must be dropped by hand: check `git log <new main> --grep '#NNN'`)
    cargo build ... (see build.sh) && run the scene of docs/scene.md
    rm ../patches/*.patch && git format-patch --zero-commit --no-signature -o ../patches <new fork main>..HEAD
    # rename to NNNN-<source>-<topic>.patch, keep the Kit-Source/Kit-Licence trailers,
    # then: cd ../patches && ls *.patch > series && sha256sum *.patch > SHA256SUMS; update BASE and CHANGELOG.md.

Instead of `git rebase` patch by patch you may merge the new main into the applied series once, resolve, and
linearise: cherry-pick the patches onto the new main with `-X theirs` (their conflicting hunks as they were), then one
resolution commit whose tree is the merge's (`git read-tree -u --reset <merge>`). v0.2 was made that way; only the
full series is build-tested, intermediate trees may not compile.

## v0.1 -> v0.2: ceb9e1f7a -> e4245f3c1 (fork main of 2026-11-26)

Fork main between: a20809de3, 58de9bf4c (#927 + VIctory #3124 + clamp windows, occlusion queries), 9613092bc,
93db653ad, e4245f3c1 (#646, #1002, #1314, #1324, #589, #702, #1112, VIctory #3198, VICTORY_PAGE_WRITES 1|2|8,
CARD_HASH_WIDE alt, DIRTY_4K, GATHER_SEGMENTS, WAVE_WIDE_ONLY, MERGE_RUNS_ALT). One merge of e4245f3c1 into the
v0.1 stack: 63 conflict hunks in 15 files. Every patch's source was checked against fork main (`git log --grep`,
switch names, diff of the touched files).

Dropped (now in fork main):
- v0.1 0012 (#927 faces): in 58de9bf4c, as a newer revision of the PR than our squash (a d16 access names its place
  only where every access through it does; a run-time pick names none). Fork main's code kept everywhere; our older
  copies of its tests (valu_tests.rs, descriptor.rs, descriptor/host.rs) dropped, its descriptor-data condition
  updated where #854/#993 had moved it (descriptor_data.rs).
- v0.1 0013 (#1002 shadows): in e4245f3c1; its ir.rs diff is byte-identical to ours.
- v0.1 0039 (resolution on ceb9e1f7a): replaced by 0037 (resolution on e4245f3c1).

Kept ours over fork main, where both cover a need (each recorded in 0037):
- Indirect clamp: #995's run clamp (`record_clamp_as`, `rec_*` constants, split-dispatch records; our 0019 fix)
  stays. Fork main's clamp window (`VICTORY_CLAMP_WINDOW`), lean clamps (`VICTORY_CLAMP_LEAN`) and gather segments
  (`VICTORY_GATHER_SEGMENTS`) are not a replacement (off in main, "measured, no gain"; #995's clamp is the frame-rate
  win), so they now run on #995's clamp: the same six root constants, bit 16 (counted table) read as
  `rec_has_count`, lean through `record_clamp_with(.., lean)`. Default off, as in main; not measured here.
- Dispatches past 65,535 groups: #993's split dispatches (`USER_GROUP_BASE`, as v0.1) kept over upstream's spread
  across z (`USER_DISPATCH_SPREAD`, VIctory #2312). #646's `USER_DISPATCH_THREADS` (0x106) and DispatchX thread
  counts wired onto the split path; main's `is_spread` = a split dispatch. Replacing the split by the spread would
  mean redoing #993's clamp records and 0019; left for later.
- 4 KiB dirty pages: #995's fine pages (`VICTORY_FINE_PAGES=1`, in the preset) already copy only the written 4 KiB
  pages; fork main's `VICTORY_DIRTY_4K` (off, "no world gain") is a second journal of the same thing, left out
  (the switch does nothing in the kit).
- Paired wave64 form (#854/#993): main's `VICTORY_WAVE_WIDE_ONLY=<hashes>` selects `Wide::Any` in our wave-wide
  modes; #646/#1112 partial-thread masks added to the paired ballots and the double sums (float64.rs).

Taken from fork main:
- `VICTORY_PAGE_WRITES` default 1|2|8 (the black-face streaming fix; "1" stays guards + slots); our finished-read
  handling replaced by main's bit 8.
- VIctory #3198: host textures retried after "no room" (`Result<_, NoTexture>`) on our `host_desc` / small-texture
  split.
- Card hashing: main's `card_compare_groups_as(wide, ..)` at our table-stage compare as well.

Tests: v0.1's own test code did not compile on Windows (HostShader initialisers of the #854/#993 and #1489 tests
without `half_views`, a Flight / Card field, `compile()` calls with `s!()`); fixed in 0037. Native
`cargo test -p victory-shader --lib`: 209 passed, 3 ignored; `cargo check --tests` for victory-gpu, victory-hle,
victory-shader, victory (Windows target): no errors.

## v0.2 -> v0.2.1: e4245f3c1 -> 4c6046614 (fork main of 2026-11-26 23:15 UTC)

Fork main between (17 commits): #1320 (split submissions give their tables' dynamic slots back), #1321, #1324 (an
empty commit: already in e4245f3c1), #1336, #1353, #1366, #1376, #1380, #1367, #1392, #1352, #1312, and fxceless's
LDS-flag regions (`VICTORY_LDS_FLAGS`, on), scratch spare cap, raw loads by the dwords read, `VICTORY_SHADER_OPT`
bit 128 (off), `VICTORY_CARD_HASH_WIDE` and `VICTORY_TILES_SMALL_WHEN_FULL_MB=512` by default, README. The whole range
up to the then tip b1d777a80 was audited before anything was built (no network, process, file or build-script
changes outside tests and the shader cache's staging file; nothing suspicious).

Not taken yet: b1d777a80 (2026-11-27 00:06 UTC, the tip when v0.2.1 was made). One 4,700-line hand-merge: wide raw
loads on by default and other translator changes (every shader translated again), a second paired-wave64 lowering
(#1397) beside our #854/#993 one, and eight switches turned on by default that the kit runs on #995's clamp and has
not measured (`VICTORY_CLAMP_LEAN`, `_WINDOW`, `GATHER_SEGMENTS`, `GATHER_DISPATCHES`, `WINDOW_UPLOAD`,
`CARD_WINDOWS_MB=1280`, `HEAP_LOCKS`, `BAKE_SOURCES=full`). Its trial merge into the series: 83 conflict hunks in 13
files (4c6046614: 26 in 4). It is the next round, with picture checks.

Made as v0.2 was: one merge of 4c6046614 into the v0.2 series (26 conflict hunks in draw.rs, host.rs, indirect.rs,
pipeline/make.rs), then 0001-0036 cherry-picked onto 4c6046614 with `-X theirs` and one resolution commit whose tree
is the merge's (0037, replacing the one on e4245f3c1). The proof build of `build.sh` gives the same tree.
- Dropped: none (no source of a kit patch is in the range; checked by PR number, switch name and the touched files).
- Patches whose own lines changed: 0005, 0012, 0015 and 0035, only in lines they remove where fork main changed
  those lines (the picked side wins, 0037 brings fork main's change back). Their added lines are as in v0.2.
- Kept ours, unchanged from v0.2 (fork main's versions do not supersede them yet: its clamp window, lean clamps and
  gather segments are still off at 4c6046614; `VICTORY_DIRTY_4K` is unchanged).
- Not taken: #1352 `VICTORY_SPREAD_LEAN` (off in fork main). It is a lean form of upstream's spread across z, which
  the kit replaced by #993's split dispatches; its clamp layout (bits 3 and 5, a predicate word), the spread record
  counters (budget words 3-5) and its tests are left out. The switch does nothing in the kit.
- Combined with ours:
  - #1312 (a dispatch waits for its compute pipeline until it is made, `VICTORY_PIPELINE_COMPUTE_WAIT`, on) beside
    our first-draw wait (`VICTORY_PIPELINE_WAIT_FIRST_MS`, 0035/0036): a compute pipeline not made yet is made at
    once; a draw's first use waits up to WAIT_FIRST_MS; otherwise the frame's budget as before.
  - #1353 (a panicking pipeline build finishes its queue entry) around our diagnostics' slow-pipeline note (0015).
  - #1367 (a small first scratch chunk may take a kept 4 MiB one) on our chunks with #995's card-memory field; our
    `VICTORY_SCRATCH_SPARE_MB` reader kept (same name and meaning as fork main's, 128 MiB unless set).
  - #1336: our alias read of a placed view takes the pinned source.
- Taken as they are: #1320, #1321, #1366, #1376, #1380, #1392, the translator changes and the new defaults.
- New patch 0038 (`VICTORY_DT_MAX`, own, off by default), squashed from the play tree's dtmax commits.

Tests: `cargo check --tests` (Windows target) for victory, victory-gpu, victory-hle, victory-shader: no errors (also
victory-gpu/victory-hle with `diagnostics`). Native `cargo test -p victory-shader --lib`: 210 passed, 3 ignored.
