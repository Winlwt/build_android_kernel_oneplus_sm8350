#!/bin/bash
# KO_COMPAT 注入：把"允许第三方 .ko"的内核配置插进 build_kernel.sh
# 用法（在 build 仓库根目录）: bash .github/ko-compat.sh android_kernel_oneplus_sm8350
set -euo pipefail

K="${1:-android_kernel_oneplus_sm8350}"
cd "$K"

python3 - <<'PY'
p = 'scripts/build_kernel.sh'
s = open(p).read()
anchor = '    make "${MAKEFLAGS[@]}" $DEFCONFIG\n'
block = anchor + '''    # --- KO_COMPAT: 第三方 .ko 兼容 ---
    ./scripts/config --file out/.config -e CONFIG_MODULE_FORCE_LOAD
    ./scripts/config --file out/.config -e CONFIG_MODULE_UNLOAD
    ./scripts/config --file out/.config -d CONFIG_MODULE_SIG
    ./scripts/config --file out/.config -d CONFIG_MODULE_SIG_FORCE
    ./scripts/config --file out/.config -d LOCALVERSION_AUTO
    ./scripts/config --file out/.config --set-str LOCALVERSION "-qgki-g1d4b7dfb7510"
    make "${MAKEFLAGS[@]}" olddefconfig
'''
if 'KO_COMPAT' in s:
    print('[ko-compat] already injected, skip')
else:
    assert s.count(anchor) == 1, 'anchor not unique'
    open(p, 'w').write(s.replace(anchor, block, 1))
    print('[ko-compat] injected')
PY

echo '--- 注入结果 ---'
grep -n 'KO_COMPAT' -A 8 scripts/build_kernel.sh
