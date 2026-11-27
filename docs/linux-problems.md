# VIctory on Linux: problems, causes, fixes

Search for what you see. Each entry: what you see, why it happens on Linux / Proton / NVIDIA, the fix or workaround,
where the fix came from, and its status. Most common first. "The title" is the game; no game files or images are here.

Status words: **in v0.2.1** = in the inkVI v0.2.1 patch series; **local only** = works for us, not released;
**open** = a public pull request or issue not merged as far as we know; **lead** = an idea, not tested by us.
Setup of our tests: Proton 11.0, vkd3d-proton built from source, RTX 5090 (and a 5070 Ti), driver 620.73.04, victory-fork
base `4c6046614`, Series X profile unless said. Single runs, not benchmarks.

Contents: 1 Crash at world entry (RTX 5090) / 2 1-2 fps, nothing streams / 3 Long stall or the process ends on a cold
cache / 4 Dark prison cell / 5 Runtime shaders refused / 6 Pipelines not kept between runs / 7 Black or missing faces,
scattered hair / 8 Slow motion below 15 fps / 9 Window on the wrong display / 10 d3d12core must be native /
11 No picture on a second card under a virtual X server / 12 Forced 4K, wrong output size / 13 Right fifth dark above
4096 px / 14 Green face with a larger descriptor ring / 15 Black road or water with ray tracing / 16 Low-poly stand-ins
after a cut / 17 NVIDIA-only picture noise (unverified leads)

---

## 1. The title crashes when the world loads on an RTX 5090 (Xid 13)
- **See:** the process dies at world entry; the kernel log shows NVIDIA Xid 13 (writes to unmapped addresses).
- **Why:** the translated lighting compute programs carry a table of the program's own code that was the whole
  program (16-18 KiB) instead of the part after the instructions. vkd3d-proton turns that constant array into a private
  one. NVIDIA's compiler keeps up to 16 KiB of such arrays in constant memory and copies a larger one into every
  thread's local memory. On the 5090 (GB202) that faults. On other cards the same tables make the driver reserve
  gigabytes of video memory.
- **Fix:** start the table after the instructions.
- **From:** the original fix is Marvisak/VIctory#2143 by desplmfao; victory-fork PR #1006 is our port of it (patch 0001).
  Confirmed on a second RTX 5090 (tylerstraub) and in a synthetic test (ArturoWolff).
- **Status:** in v0.2.1; PR #1006 open (rebased onto fork main, mergeable at last check).

## 2. 1-2 fps and nothing streams in (stock Proton, cold cache)
- **See:** with the stock Proton wineserver and empty caches the title runs at 1-2 fps, scenes stay as empty stand-ins
  and nothing streams in, on both our cards. With the patched wineserver and a warm cache the same scene ran at
  5-6.6 fps (5090) and 7-8 fps (5070 Ti) and drew correctly.
- **Why:** wineserver keeps a process's mapped memory views in a list and walks it on every map and unmap
  request (Wine bug 60868, marked fixed upstream). The title remaps 64 KiB pages one view each, hundreds a frame, with tens
  of thousands of views mapped, so the cost grows as it runs. The cold cache is a second, separate cause (entry 3).
  Not yet separated: how much of the 1-2 fps is the wineserver and how much is the cold cache. Likely both.
- **Fix:** a wineserver that keeps the views in a tree. Build it yourself from the exact wine commit of your Proton,
  read the one commit first, never install into Steam's copy (steps: `docs/wineserver-viewtree.md` in this repository).
  Loading into the world was about twice as fast in our tests. If your Proton already has the Wine fix, skip this.
- **From:** CachyOS/wine-cachyos PR #50 ("server: Keep memory views in a tree by base address"), by ajsem1337, based on a
  version by neonbyte1; we audited it and built it (touches only server/file.h, mapping.c, process.c, process.h).
- **Status:** not part of the kit (no binaries shipped); PR #50 was still open on 2026-11-27. Check your Proton first.
- Check which server runs: `readlink /proc/$(pgrep -x wineserver)/exe`. Wine reuses a server already running for the prefix.

## 3. Long stall at the start, or the process ends about 30 s into a slow first frame
- **See:** the first world frames take minutes; some setups end the process.
- **Why:** the title has a watchdog thread that ends the process when the main thread stalls about 30 s. Under Proton
  the first world frames stall that long while pipelines are made. A cold NVIDIA shader cache (first run of a new build,
  or the cache's cleanup of its roughly 1 GB) makes it worse: the world appears at about 7.5 min instead of 2, in our runs.
- **Fix:** `VICTORY_NO_WATCHDOG=1` disarms the watchdog (checked against the build hash and exact bytes; does nothing
  otherwise). Keep your own NVIDIA cache warm: `__GL_SHADER_DISK_CACHE_PATH=<dir>` and
  `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1`. Fork PR #1450 (cap the per-frame wait for compute pipelines built at
  dispatch, default 8 s) fixed a 30 s frame at the first cutscene for its reporter.
- **From:** the watchdog switch is Marvisak/VIctory PR #454 via the testers integration build, ported by us (0003).
  #1450 is by fork contributors; we have not taken it.
- **Status:** NO_WATCHDOG in v0.2.1. #1450 lead (not taken).

## 4. The prison cell comes up dark
- **See:** the first scene is dark, with few lit surfaces, on a cold driver shader cache.
- **Why:** the host pipelines were missing from NVIDIA's cache, so each took the driver 1-5 s; the list of early
  pipelines took minutes while the world had already started, and its first passes were dropped. An empty pipeline
  cache (no early list) did the same, so it is not only the early list.
- **Fix:** a pipeline's first draw waits up to N ms for it instead of being dropped: `VICTORY_PIPELINE_WAIT_FIRST_MS=5000`
  (in the speed preset). Inert with warm caches. Cost: on a cold start the world appears later but lit.
- **From:** ours (0034-0036; 0034 adds a log line every 2 s naming what the pipeline workers do).
- **Status:** in v0.2.1.

## 5. Runtime shaders refused by Wine's compiler
- **See:** a log line "the system compiler refused one of our shaders: trying DXC"; or, without the fix, dropped draws
  or a missing root signature.
- **Why:** under Wine/Proton the system HLSL compiler (d3dcompiler) refuses some shaders the layer compiles at runtime,
  or drops their root signature. Examples: the batched indirect-argument clamp, the in-flight fetch shader.
- **Fix:** send runtime HLSL to Microsoft's DXC when the system compiler refuses. Download DXC from Microsoft's
  DirectXShaderCompiler release and point `VICTORY_DXC='Z:\path\to\dxc\bin\x64'` at its bin folder.
- **From:** victory-fork PR #20 by errusso (squashed into 0002); our patches 0007, 0011 make later patches use it.
- **Status:** in v0.2.1. Drop it once PR #20 is in fork main.

## 6. Pipelines are not kept between runs ("no host pipeline library")
- **See:** log says "no host pipeline library: pipelines are not kept"; every start makes all pipelines again
  (3,081 made, 391 loaded on a cold run).
- **Why:** the layer asks for an empty library with a dangling non-null pointer (Rust's empty slice). vkd3d-proton refuses a
  non-null pointer with a zero-length blob, so the native cache is lost for the whole run. D3D12's documented
  empty form is a NULL pointer with length 0.
- **Fix:** pass NULL for the empty blob. Warm run: library loaded (589,112 bytes), made=0 loaded=3,468.
  The early-pipeline list should also be saved when there is no library (fork #259: on an RTX 5080 under Wine,
  0 pending at world entry instead of 1,500-2,200 pending and 21k-127k dropped draws in the first minute).
- **From:** fork PR #885 and #259 (same fix, reporters on RTX 5060 Laptop and 5080, Proton); our own one-liner `c-libnull`
  made the same change. Hzaidi's #938 part (patch 0018) persists warm-up keys without an application cache.
- **Status:** 0018 in v0.2.1. The null-blob fix: local only (our tree), not in the kit; #885 and #259 open as far as we know.
- Related lead: fork #1461 makes static samplers in a fixed order every launch; it fixes a picture that depended on who
  filled the library (NVIDIA, tested by Filip722, GE-Proton11-14). Not tested by us.

## 7. Black or missing faces; scattered hair strands
- **See:** black faces in the opening cutscene and in scenes that stream in; hair strands scattered around the head,
  different every frame; missing eyes, teeth.
- **Why:** (a) textures uploaded before their streamed data arrived kept zeros; fork main makes them due again.
  (b) The low loop limit that NVIDIA Turing needs (`VICTORY_SHADER_LOOP_LIMIT=32`) also cut genuine compute loops
  short: the hair simulation's per-vertex pass loops more than 32 times, so its lanes never stored.
  (c) After a merge, the clamp for split dispatches named a variable that no longer existed: the clamp did not compile and every
  indirect call was dropped (our bug, fixed in 0019). Which parts matter was not bisected one by one.
- **Fix:** fork main's `VICTORY_PAGE_WRITES` (on by default since v0.2); `VICTORY_SHADER_LOOP_LIMIT=32` with compute
  keeping its own limit (0009); #927 (16-bit buffers: the face network) and #1002 (cascade shadows on 32-lane cards) from fork main; wave64 paired forms
  (#854/#993) and #1489 gather-compare.
- **From:** Danigamer05 (#683), PiloteCode (#854, #993), tunczzz (#995), AscilCH (Marvisak/VIctory#1489), tippythetaidum (#927), brunofgmag
  (#1002), ours (0019).
- **Status:** in v0.2.1. The cutscene's first shot (world frame 2) can still show dark faces.

## 8. The game runs in slow motion below 15 fps
- **See:** the title is at 0.44x real time at 6.5 fps.
- **Why:** the title's timer does dt = min(1/15, measured): below 15 fps every frame counts 1/15 s. Not a Linux bug;
  Linux layers are usually below 15 fps.
- **Fix:** `VICTORY_DT_MAX=0.2` raises the step ceiling (real time down to 5 fps). Measured in the cell: game speed
  0.87-0.93 instead of 0.42-0.45. Untested under driving, combat, ragdolls, swimming; large steps may let fast objects
  pass thin walls. If something misbehaves, try 0.1 or leave it unset.
- **From:** ours (0038). Testing aid, off by default, a commented line in `speed.env`.
- **Status:** in v0.2.1.

## 9. The window opens on the wrong display, or with a frame, or you are unsure about Wayland vs X11
- **See:** a framed window, or a window not filling your monitor.
- **Why:** under Wine the title's window lives inside the prefix's virtual desktop, which frames it and boxes it in. Where a
  window lands on a multi-monitor setup was not examined by us beyond "the primary monitor". The cause on your
  compositor is unverified. Our desktop numbers were taken in a real Wayland session; a session must be present
  (DISPLAY or WAYLAND_DISPLAY).
- **Fix:** inkVI-ultrawide `VICTORY_BORDERLESS=1`: a borderless popup at the primary monitor's size, which window managers
  take as fullscreen; under Wine the title first restarts itself on a desktop of its own outside the virtual desktop.
  The window goes to the primary monitor (our reading of the patch, untested on other layouts). Separately: in an
  X11 session (a remote desktop, a virtual X server) whose environment still carries `WAYLAND_DISPLAY`, programs that
  prefer Wayland open on the Wayland screen instead; unset it there.
- **From:** ours (inkVI-ultrawide 0001).
- **Status:** inkVI-ultrawide v0.1 (not in inkVI v0.2.1). Needs a report from a multi-monitor user.

## 10. d3d12core must be native on plain Wine
- **See:** on plain Wine with only `d3d12=n,b` the title dies about two seconds in:
  `unimplemented function d3d12core.dll.D3D12GetInterface`, exception `0x80000100`. A warning one line earlier makes it
  look as if the device had come up.
- **Why:** the layer's device query calls `D3D12GetInterface`; Wine's built-in `d3d12core.dll` is a stub without it.
- **Fix:** copy vkd3d-proton's x64 `d3d12.dll` and `d3d12core.dll` into the prefix and make both native:
  `WINEDLLOVERRIDES="d3d12=n,b;d3d12core=n,b"`. inkVI's launch line already sets both (and `dxgi`).
- **From:** found and written up by Headache3318 in victory-fork issue #1332 (Arch, RTX 4090, wine-11.22).
- **Status:** the launch line is in v0.2.1 (`launch/README.md`).

## 11. No picture or no screenshots on a second card under a virtual X server
- **See:** on Xvfb the log says "Surface is not supported for presentation" for the second card and "no swap chain" on
  every present; no frame can be saved (our capture read back only inside the swap-chain present).
- **Why:** vkd3d-proton gets no presentable surface for that card on Xvfb (seen on the RTX 5070 Ti; the 5090 on a real
  desktop and in a 4K run had a swap chain).
- **Fix:** run on a real session for pictures. For headless captures we wrote a capture that copies the title's frame on
  its own command list with no swap chain (diagnostics builds).
- **From:** ours.
- **Status:** in inkVI-dive (patch 0011). Xvfb numbers are lower than desktop ones; compare only with each other.

## 12. The picture is 3840x2160 stretched, or a custom size is ignored
- **See:** `VICTORY_DISPLAY_MODE` alone changes nothing; a 32:9 screen shows a 16:9 picture stretched; garbled back buffers.
- **Why:** the title has its own list of modes (1280x720 to 3840x2160), takes its size from saved settings and ignores the
  system's modes. Its aspect function returns a constant 16:9 or 4:3 on any screen wider than 1.5. The back-buffer pool is
  sized for 3840x2160 and a check stops the title for other sizes.
- **Fix:** inkVI-ultrawide `VICTORY_OUTPUT=WxH` (up to 3840x2160's pixel count, so 5120x1440 works), `VICTORY_ASPECT=auto`,
  `VICTORY_RENDER_SCALE`. Series X profile only; Windows untested.
- **From:** avatarmanz (`resolution.rs`, VIctory-7900XTX) for the output size; ours for the camera and window.
- **Status:** inkVI-ultrawide v0.1.

## 13. The right fifth of the picture is dark when the render width is above 4096 px
- **See:** at 5120x1440 with render scale 1.0 the part from x = 4096 loses a pass and comes out dark. 0.8 (exactly
  4096x1152) is clean.
- **Why:** unknown. Seen in full-size captures of one cutscene. A texture or viewport cap or a tiled pass is a
  guess. **Unverified.**
- **Workaround:** `VICTORY_RENDER_SCALE=0.8` with `VICTORY_GFX_POOL_MB=4095 VICTORY_RT_PAGES_MB=1536`.
- **Status:** open; in inkVI-ultrawide as a known issue.

## 14. A face turns green after raising the descriptor ring
- **See:** with `VICTORY_DYNAMIC_SLOTS=524288` the curly-haired lady's face turned green.
- **Why:** NVIDIA caps the view heap at 1,000,000 for the title's 1,245,184. The ring of dynamic slots sits at the top;
  a title index inside its range reads some other table's descriptor. The default ring already has this for a smaller range.
  Confirmed in play, not bisected further.
- **Fix:** leave it at the default. It measured +11 to +15 % but is not in the preset until title indices are remapped.
- **From:** idea from trustno1-coder/VIctory-NVIDIA a9632bc, our code (0029); the aliasing pointed out by ThomasHFWright.
- **Status:** opt-in switch in v0.2.1.

## 15. Black road or black water with ray tracing on
- **See:** with ray tracing on, the road after a cutscene shot is a black void with orange fireflies; shore water black.
  With ray tracing off the same shot is correct. On the fork tip, water was black with the program refused.
- **Why:** the road is a ray-tracing fault: with RT off it is drawn bright. A ray program probably writes black or NaN
  into the texel (likely; the candidate is FiveNine's R3 "leaves the texel instead of storing NaN", untested). The
  water is only a lead.
- **Fix:** none of ours. Ray tracing is not in inkVI; it is in avatarmanz/VIctory-7900XTX and, packaged for Linux, in
  ThomasHFWright's LinVxtory. Turn it off for that shot.
- **Status:** lead.

## 16. Low-poly stand-in models for a second after a cut
- **See:** people or a building as low-poly stand-ins for about a second after a cutscene cut.
- **Why:** model streaming lags; textures were fine. Likely the title paces itself by the wall clock while uploads
  keep to frames, so a slow frame rate outruns streaming (a hypothesis from the iguana replay).
- **Fix:** none. A warm cache and the view-tree wineserver (entry 2) helped; ~1.5 fps runs showed it most.
- **Status:** open.

## 17. NVIDIA-only picture noise: unverified leads
All of these are things other people reported or we suspect. None is confirmed by us on the 5090.
- **Paired wave64 form.** victory-fork merged versions of it (#854/#993 in our kit; #1397/#1419 in fork main for
  the water programs). FrancescoGelosoEterea/VIscosity's README reports white-noise reflections on NVIDIA after merging a paired form. Cause
  unknown. inkVI v0.2.1 has the paired form on; `VICTORY_WAVE_PAIRS=0` turns it off for a comparison.
- **Sampler order.** The picture depends on who filled the pipeline library (fork #1461, Filip722, RTX 5060 Laptop,
  GE-Proton11-14, vkd3d-proton 3.2.0). Cause: static samplers created in a varying order.
- **Early pipelines and sky banding.** fork #845 (`VICTORY_EARLY_PIPELINES`): a populated learned list showed sky
  banding on a 5070 Ti, cache-state dependent. Unverified.
- **2-D compute group thread ids.** On NVIDIA a compute group larger than one host wave could hand the same console
  thread ids to two waves (victory-fork issue #1243). Fixed in trustno1-coder/VIctory-NVIDIA PR #30 by regiumlepidi, a
  port of Vice-Tay c125c0c (Garu667), tested on an RTX 5070 Ti. Not in inkVI; not tested by us.
- **NaN scrub.** V#3397 `VICTORY_NAN_SCRUB=1` (from trustno1-coder) targets persistent black/white patches through bloom/TAA on NVIDIA; not tested by us.

---

## How to report a new one
Open an issue on the inkVI repository with: your GPU and driver; kernel and distro; Proton or Wine version and
vkd3d-proton version; the base (inkVI version, `BASE` commit) and which switches you set (your `speed.env` and extra
exports); whether the shader caches were cold or warm; the profile (`--console series-x` or series-s); the
display setup (real desktop or virtual X server, Wayland or X11, monitor count); one scene and how to reach it.
Paste the relevant log lines, search them first (`resolution:`, `hook applied`, `no host pipeline library`,
`trying DXC`, `SLOW-PIPELINE`, Xid lines from `dmesg`). **Remove paths** (home folder, game folder, prefix) from logs
before posting. **Do not attach game files, saves, or game images.** Describe a picture problem in words; if a crop
is needed, ask first.
