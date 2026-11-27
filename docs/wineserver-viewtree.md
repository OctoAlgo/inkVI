# A view-tree wineserver for your Proton (build it yourself)

**What:** wineserver keeps each process's mapped memory views in a list and walks the whole list on every map/unmap
request ([Wine bug 60868](https://bugs.winehq.org/show_bug.cgi?id=60868), "wineserver: map/unmap view requests are
linear in the number of mapped views"). A D3D12 title translated through vkd3d-proton maps a very large number of views,
so those requests get slower as the game runs. [CachyOS/wine-cachyos PR #50](https://github.com/CachyOS/wine-cachyos/pull/50)
("server: Keep memory views in a tree by base address") keeps the views in a red-black tree as well. In our tests with a
VIctory-based layer, loading into the game world was about twice as fast with it.

**Status, check first:** the Wine bug is marked RESOLVED FIXED and the PR was still open when this was written. If the
Wine in your Proton already contains the fix, you don't need any of this.

This repo ships **no binaries and no copy of the patch**: Wine is LGPL-2.1-or-later, and these steps build it from the
original sources on your machine. If you ever distribute a modified wineserver, the LGPL's source obligations apply to you.

## Rule: match your Proton's wine commit exactly

wineserver and the Wine client libraries talk a private protocol. A server built from a different Wine tree than the
rest of your Proton fails with "version mismatch" or, worse, misbehaves. So build from the exact commit your Proton
was built from, and change nothing else.

## Steps

1. **Find the commit.** `cat "<Proton>/version"` gives the build name (e.g. `proton-11.0-2e`). In a clone of
   [ValveSoftware/Proton](https://github.com/ValveSoftware/Proton), `git ls-tree <that tag> wine` prints the commit the
   `wine` submodule is pinned to (it can differ from the head of Valve's wine branch).
2. **Get that tree:**
   ```
   git init wine && cd wine
   git remote add valve https://github.com/ValveSoftware/wine
   git fetch --depth 1 valve <commit> && git checkout FETCH_HEAD
   ```
3. **Get the PR's commit and read it.** `git fetch https://github.com/CachyOS/wine-cachyos pull/50/head`, then find the
   one commit that changes `server/` (the PR targets a CachyOS branch, so it lists many unrelated commits; the view tree is
   one commit touching `server/file.h`, `server/mapping.c`, `server/process.c`, `server/process.h`). Read the diff before
   you build it: it should not touch `protocol.def` or the protocol version. Apply it with
   `git cherry-pick -n <commit>` (or `git show <commit> | git apply`). If it does not apply cleanly, stop: your tree differs.
4. **Generate what Proton's build generates**, so the protocol matches the shipped binaries:
   ```
   autoreconf -fi
   perl tools/make_requests          # protocol headers; the committed ones can be stale
   perl tools/make_specfiles
   python3 dlls/winevulkan/make_vulkan -x dlls/winevulkan/vk.xml -X dlls/winevulkan/video.xml   # if configure needs it
   ```
5. **Build only the server** in a separate folder. wineserver needs few dependencies, so disable the rest
   (`--without-x --without-wayland --without-vulkan --without-gstreamer ...`; keep inotify, the server uses it):
   ```
   mkdir ../build64 && cd ../build64
   ../wine/configure --enable-win64 --without-mingw --disable-tests --without-x --without-wayland --without-vulkan
   make -j"$(nproc)" server/wineserver
   ```
6. **A control build:** repeat 5 on the same tree without the patch. If the patched server is faster, swap the control in
   once to show the gain comes from the patch and not from your compiler.
7. **Install into a copy of Proton**, never into Steam's: `cp -a "<Proton>" ~/proton-viewtree`, keep the original as
   `files/bin/wineserver.orig`, copy yours to `files/bin/wineserver`.
8. **Verify:** `WINEPREFIX=/tmp/vt-test ~/proton-viewtree/files/bin/wine cmd /c ver` creates a prefix and prints a
   Windows version without "version mismatch". Point your launcher at the copy.

## Caveat when switching

Wine reuses a wineserver that is already running for the same prefix. Before a run with the other server, make sure the
old one has exited (`<that Proton>/files/bin/wineserver -k` with the same `WINEPREFIX`), and during the run check that
`readlink /proc/$(pgrep -x wineserver)/exe` points into the Proton copy you meant.
