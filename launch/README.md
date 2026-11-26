# Launch

Proton 11.0 (any recent Proton should do), vkd3d-proton master built from source in the prefix
(`d3d12.dll`, `d3d12core.dll`), an NVIDIA card (measured on an RTX 5090, driver 580+), DXC from Microsoft's
DirectXShaderCompiler release (for the runtime HLSL fallback, patch 0002).

    export WINEPREFIX=<your prefix>
    export WINEDEBUG=-all WINEDLLOVERRIDES="d3d12=n;d3d12core=n;dxgi=n"
    export VKD3D_DISABLE_EXTENSIONS=VK_NV_raw_access_chains
    export VKD3D_FILTER_DEVICE_NAME="<card name>" DXVK_FILTER_DEVICE_NAME="<card name>"   # with more than one GPU
    export VICTORY_DXC='Z:\path\to\dxc\bin\x64'
    export VICTORY_GAME_DIR='Z:\path\to\the\game' VICTORY_CACHE_DIR='Z:\path\to\cache' VICTORY_DATA_DIR='Z:\path\to\saves'
    export VICTORY_NO_WATCHDOG=1           # slow first world frames under Proton otherwise end the process (~30 s stall)
    export VICTORY_SHADER_LOOP_LIMIT=32    # with patch 0009 compute keeps its own limit (hair strands)
    export VICTORY_LOG=info
    set -a; . ./speed.env; set +a          # the speed preset; command-line exports after this win
    "<proton>/proton" run victory.exe      # or: wine victory.exe with Proton's wine

Optional: `VICTORY_BORDERLESS=1`, `VICTORY_DISPLAY_MODE=WxH` (preset: 1920x1080),
`__GL_SHADER_DISK_CACHE_PATH=<dir>` + `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` (own NVIDIA cache; keep it warm,
a cold one means the long first start of `docs/known-issues.md`).
To reproduce our `--pr9b` numbers exactly, add `VICTORY_DYNAMIC_SLOTS=524288` (read docs/known-issues.md first).
