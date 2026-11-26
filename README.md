# inkVI

A source-only patch stack on top of [victory-fork](https://github.com/fxceless/victory-fork) for running the title
on Linux (Proton + vkd3d-proton) on NVIDIA cards. No binaries, game data, saves or frames are in this repository:
a pinned public base commit, an ordered patch series, a build script, a launch preset and notes.
It is a living base: we build on it, and anyone may take single patches from it (GPL-3.0, like the base).

## What's in it

- `BASE`: the pinned base (victory-fork `main` at `e4245f3c1`).
- `patches/`: the series, numbered, one concern per patch, applied in the order of `patches/series`.
  `patches/README.md` lists every patch with its source (fork PR, upstream VIctory PR, other forks, or "own")
  and licence; each patch also carries `Kit-Source:` / `Kit-Licence:` trailers.
  v0.1 gave the tree we measure as `--pr9b` (minus four default-off experiments); v0.2 is that stack on fork main
  `e4245f3c1` (CHANGELOG.md).
- `build.sh`: fetch the base, check the inputs, apply the series, build release + diagnostics.
- `launch/`: `speed.env` (the speed preset) and the launch flags (`launch/README.md`).
- `docs/`: the scene we measure on (`scene.md`), known issues (`known-issues.md`), how to move to a newer base
  (`rebase.md`).
- `CHANGELOG.md`: measured results per round and per patch.

Highlights: fork #995 frame-rate work, #854/#993 wave64 programs paired on 32-lane GPUs, an ambient stand-in for the missing ray-traced indirect light (#917 +
Belobug's refinements), small title buffers resident on the card (`VICTORY_CARD_BUFFERS_MIN_KB=64`, +33 %), and the
dark-cell fix (`VICTORY_PIPELINE_WAIT_FIRST_MS`). From the base: #927 faces, #1002 cascade shadows and the black-face
streaming fix (`VICTORY_PAGE_WRITES` 1|2|8), all in fork main since v0.2.

## How to build

Needs git, a Rust toolchain (the base's `rust-toolchain.toml`), and for a Linux cross build clang-cl, lld-link,
llvm-lib and an MSVC SDK (e.g. from xwin).

    XWIN=/path/to/xwin-sdk sh build.sh /path/to/empty-dir          # add --no-diag for release only

The script refuses a work dir that is not at the pinned base or has local changes. Output:
`<dir>/target/x86_64-pc-windows-msvc/{release,diag}/victory.exe`. Then see `launch/README.md`.

## How to take a single patch into your own tree

Patches are plain `git format-patch` mails; paths in this README are relative to the kit root.

    git am -3 /path/to/inkvi-kit/patches/0013-vpr1489-ascilch-gather4-c.patch

- Patches marked "own (build fix ...)" or "resolution" only make sense together with the patch they fix.
- The series was resolved against fork main as one merge; its merge-time resolutions (mostly in 0005 #995, 0012
  #854/#993 and 0027 striped lock, against fork main's #927, #646, clamp windows, #3198 and page writes) are
  collected in `0037-own-resolution-e4245f3c1.patch`. Taken alone onto `e4245f3c1` a patch applies with `-3`, but
  you may need the matching hunks of 0037 to compile.
- Every new switch is off unless set; read the patch's commit message for its switch and default.

## Not in this repository
- `brighten.cso`, the compiled compute shader of #995 (`VICTORY_BRIGHTEN`): `build.sh` compiles it from the
  patched `brighten.hlsl` when `DXC=<dxc binary>` is set (`dxc -T cs_6_0 -E main`), otherwise it fetches the blob
  from #995's head commit (pinned in `BASE`) and checks its sha256.

## inkVI-ultrawide
A separate kit for 32:9 / 21:9 output (render size, camera, HUD) on top of this one. Coming.

## Licence

GPL-3.0 (`LICENSE`), the licence of the base and of every patch source. Authors are kept in each patch.
