#!/bin/bash
# KO_COMPAT 注入：在 build 仓库根目录运行，给 scripts/build_kernel.sh 插入"第三方 .ko 兼容"配置
# 用法: bash .github/ko-compat.sh
set -euo pipefail

TARGET="scripts/build_kernel.sh"
if [ ! -f "$TARGET" ]; then
    echo "找不到 $TARGET —— 必须在 build 仓库根目录运行" >&2
    ls -la >&2
    exit 1
fi

python3 - "$TARGET" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()

if 'KO_COMPAT' in s:
    print('[ko-compat] 已注入过，跳过')
    raise SystemExit(0)

anchor = '    make "${MAKEFLAGS[@]}" $DEFCONFIG\n'
if s.count(anchor) != 1:
    print('[ko-compat] 锚点不唯一/不存在，count=%d' % s.count(anchor))
    for i, ln in enumerate(s.splitlines(), 1):
        if 'DEFCONFIG' in ln:
            print('  %4d| %s' % (i, ln))
    raise SystemExit(1)

block = anchor + '''    # --- KO_COMPAT: 第三方 .ko 兼容 ---
    ./scripts/config --file out/.config -e CONFIG_MODULE_FORCE_LOAD
    ./scripts/config --file out/.config -e CONFIG_MODULE_UNLOAD
    ./scripts/config --file out/.config -d CONFIG_MODULE_SIG
    ./scripts/config --file out/.config -d CONFIG_MODULE_SIG_FORCE
    ./scripts/config --file out/.config -d LOCALVERSION_AUTO
    ./scripts/config --file out/.config --set-str LOCALVERSION "-qgki-g1d4b7dfb7510"
    make "${MAKEFLAGS[@]}" olddefconfig
'''
open(p, 'w').write(s.replace(anchor, block, 1))
print('[ko-compat] 注入完成')
PY

echo '--- 注入结果 ---'
grep -n 'KO_COMPAT' -A 8 "$TARGET"
