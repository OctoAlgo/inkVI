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
