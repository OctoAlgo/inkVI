# inkVI

A source-only patch stack on top of [victory-fork](https://github.com/fxceless/victory-fork) for running the title
on Linux (Proton + vkd3d-proton) on NVIDIA cards. No binaries, game data, saves or frames are in this repository:
a pinned public base commit, an ordered patch series, a build script, a launch preset and notes.
It is a living base: we build on it, and anyone may take single patches from it (GPL-3.0, like the base).

**We work on the Series X profile** (`--console series-x`): the aim is the full picture on a fast card, and our
measurements and picture checks are made there. The Series S profile is faster and needs less memory; for work focused
on it, and for an opt-in ray-tracing preview on Linux, see ThomasHFWright's
[LinVxtory](https://github.com/ThomasHFWright/LinVxtory) (its earlier builds used this kit's v0.1).

## What's in it

- `BASE`: the pinned base (victory-fork `main` at `4c6046614`).
- `patches/`: the series, numbered, one concern per patch, applied in the order of `patches/series`.
  `patches/README.md` lists every patch with its source (fork PR, upstream VIctory PR, other forks, or "own")
  and licence; each patch also carries `Kit-Source:` / `Kit-Licence:` trailers.
  v0.1 gave the tree we measure as `--pr9b` (minus four default-off experiments); v0.2 is that stack on fork main
  `e4245f3c1`; v0.2.1 moves it to fork main `4c6046614` and adds `VICTORY_DT_MAX` (CHANGELOG.md).
- `build.sh`: fetch the base, check the inputs, apply the series, build release + diagnostics.
- `launch/`: `speed.env` (the speed preset) and the launch flags (`launch/README.md`).
- `docs/`: the scene we measure on (`scene.md`), where in the game we can check things for you (`test-scenes.md`),
  known issues (`known-issues.md`), how to move to a newer base
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
  #854/#993 and 0027 striped lock, against fork main's #927, #646, clamp windows, #3198, page writes, #1312 and
  #1352) are collected in `0037-own-resolution-4c6046614.patch`. Taken alone onto `4c6046614` a patch applies with
  `-3`, but you may need the matching hunks of 0037 to compile.
- Every new switch is off unless set; read the patch's commit message for its switch and default.

## Not in this repository
- `brighten.cso`, the compiled compute shader of #995 (`VICTORY_BRIGHTEN`): `build.sh` compiles it from the
  patched `brighten.hlsl` when `DXC=<dxc binary>` is set (`dxc -T cs_6_0 -E main`), otherwise it fetches the blob
  from #995's head commit (pinned in `BASE`) and checks its sha256.

## inkVI-ultrawide
A separate kit for 32:9 / 21:9 on top of this one: the title's own output size, the camera's field of view, a borderless
window, cutscenes without bars. Work in progress: [inkVI-ultrawide](https://github.com/OctoAlgo/inkVI-ultrawide).

## Roadmap

**In v0.2.1**
- The base moved to the fork's main of 2026-11-26 23:15 UTC (`4c6046614`); why not its newest commit: CHANGELOG.md
- `VICTORY_DT_MAX`: the game at real speed below 15 fps (off unless set)
- From v0.2: the prison cell lit, faces and skin fixed from v0.1
- Native 32:9 with a correct field of view (inkVI-ultrawide, work in progress)

**Next**
- The fork's newest base: its own wave64 shader code, the ray-tracing structure builder, the water fix
- Ultrawide: the loading screens and the intro video at 32:9
- Frame rate in the prison and Chapter 1

**Later**
- Ray tracing, building on ThomasHFWright's [LinVxtory](https://github.com/ThomasHFWright/LinVxtory) preview and the
  fork's structure builder
- Picture fixes: eyes and glasses, the black phone screen
- Tools: the ultrawide fix on its own, and the test tooling we use
- Quicker test scenes

Updated with each release. Issues and test requests are welcome (`docs/test-scenes.md`).

## Licence

GPL-3.0 (`LICENSE`), the licence of the base and of every patch source. Authors are kept in each patch.
