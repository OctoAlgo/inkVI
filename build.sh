#!/bin/sh
# inkVI: fetch the pinned victory-fork base, apply the patch series, build release + diag.
# Usage: sh build.sh <empty-or-existing-work-dir> [--no-diag]
# Cross build from Linux needs an MSVC SDK (e.g. xwin): set XWIN=<sdk dir>, or set LIB/INCLUDE yourself.
# On Windows, run the same steps in Git Bash without XWIN.
set -eu
kit=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$kit/BASE"                       # BASE_URL, BASE_COMMIT
[ $# -ge 1 ] || { echo "usage: sh build.sh <work-dir> [--no-diag]" >&2; exit 1; }
mkdir -p "$1"; src=$(CDPATH= cd -- "$1" && pwd); diag=1; [ "${2:-}" = --no-diag ] && diag=0

# 1. inputs: every patch listed in series, nothing else, sha256 as recorded
cd "$kit/patches"
sha256sum -c --quiet SHA256SUMS
ls *.patch | cmp -s - series || { echo "patches/ and patches/series differ" >&2; exit 1; }
cd "$kit"

# 2. the pinned base
if [ ! -d "$src/.git" ]; then
    git init -q "$src"
    git -C "$src" fetch -q --depth=1 "$BASE_URL" "$BASE_COMMIT"
    git -C "$src" checkout -q --detach FETCH_HEAD
fi
[ "$(git -C "$src" rev-parse HEAD)" = "$BASE_COMMIT" ] || {
    echo "$src is not at the pinned base $BASE_COMMIT (already patched? use a fresh dir)" >&2; exit 1; }
[ -z "$(git -C "$src" status --porcelain)" ] || { echo "$src has local changes" >&2; exit 1; }

# 3. the series, in order, as commits (git am keeps authors and sources)
git -C "$src" -c user.name=inkvi -c user.email=inkvi@localhost \
    am -q --committer-date-is-author-date $(sed "s|^|$kit/patches/|" patches/series)
echo "series applied: $(git -C "$src" rev-list --count HEAD~$(wc -l < patches/series)..HEAD) patches"

# 4. #995's compiled compute shader (VICTORY_BRIGHTEN), not shipped in this repo:
#    DXC=<dxc binary> compiles it from the patched brighten.hlsl, otherwise the PR's own blob is fetched and checked
cso=crates/victory-gpu/src/brighten.cso
if [ ! -f "$src/$cso" ]; then
    if [ -n "${DXC:-}" ]; then
        "$DXC" -T cs_6_0 -E main -Fo "$src/$cso" "$src/crates/victory-gpu/src/brighten.hlsl"
    else
        git -C "$src" fetch -q --depth=1 "$BASE_URL" "$BRIGHTEN_FROM"
        git -C "$src" show "FETCH_HEAD:$cso" > "$src/$cso"
        echo "$BRIGHTEN_SHA256  $src/$cso" | sha256sum -c --quiet
    fi
fi

# 5. build
if [ -n "${XWIN:-}" ]; then
    vcd=$(ls -d "$XWIN"/VC/Tools/MSVC/* | head -1)
    kl="$XWIN/Windows Kits/10/Lib/10.0.26100"; ki="$XWIN/Windows Kits/10/Include/10.0.26100"
    export LIB="$vcd/lib/x64;$kl/ucrt/x64;$kl/um/x64"
    export INCLUDE="$vcd/include;$ki/ucrt;$ki/um;$ki/shared"
    export CC_x86_64_pc_windows_msvc=clang-cl AR_x86_64_pc_windows_msvc=llvm-lib
    export CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=lld-link
fi
cd "$src"
cargo build --locked --target x86_64-pc-windows-msvc --release -p victory
[ $diag = 1 ] && cargo build --locked --target x86_64-pc-windows-msvc --profile diag --features diagnostics -p victory
echo "built: $src/target/x86_64-pc-windows-msvc/release/victory.exe$( [ $diag = 1 ] && echo ' and .../diag/victory.exe')"
