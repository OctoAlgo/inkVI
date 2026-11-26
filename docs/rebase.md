# Moving to a newer fork main

    git clone https://github.com/fxceless/victory-fork src && cd src
    git checkout -b inkvi <BASE_COMMIT from ../BASE>
    git am ../patches/*.patch                               # the current series
    git -c rerere.enabled=true rebase <new fork main>      # resolve conflicts patch by patch
    # drop patches whose change is now in fork main (git rebase says "dropping ... already upstream";
    # squashed PR patches like 0005/0012/0013/0014 must be dropped by hand: check `git log <new main> --grep '#NNN'`)
    cargo build ... (see build.sh) && run the scene of docs/scene.md
    rm ../patches/*.patch && git format-patch --zero-commit --no-signature -o ../patches <new fork main>..HEAD
    # rename to NNNN-<source>-<topic>.patch, keep the Kit-Source/Kit-Licence trailers,
    # then: cd ../patches && ls *.patch > series && sha256sum *.patch > SHA256SUMS; update BASE and CHANGELOG.md.

Fold the resolution patch (0039) into the patches it fixes when you resolve them on the new base; it exists only
because the stack was first built as merges.
Known now (fork main 93db653ad): 58de9bf4c merged #927 (so 0012 goes), but that commit also brings the clamp
window (`VICTORY_CLAMP_WINDOW`, `lean` clamps) into indirect.rs, which collides with #995's rewritten clamp
(`record_clamp_as`, `scratch_bytes`, `rec_*` fields), plus wave64 diagnostics and loop-limit modules overlapping
#854/#993. A trial merge left 25 conflict hunks in 8 files (descriptor.rs, draw.rs, host.rs, indirect.rs, xmem.rs,
lower.rs, emit/mod.rs, valu_tests.rs). Resolve those by hand, build, and do one run of docs/scene.md before moving BASE.
