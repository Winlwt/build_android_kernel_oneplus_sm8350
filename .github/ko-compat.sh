#!/bin/bash
# KO_COMPAT 注入：在 build 仓库根目录运行，给 scripts/build_kernel.sh 插入"第三方 .ko 兼容"配置
# 注意：绝不改 LOCALVERSION / LOCALVERSION_AUTO ——
#   内核串由 CONFIG_LOCALVERSION="-qgki" + .scmversion(-g1d4b7dfb7510) + LOCALVERSION_AUTO=y 生成，
#   一旦改成固定串并关掉 AUTO，setlocalversion 会在源码树有补丁时追加 '+'，
#   导致没有 __versions 的第三方 .ko 因整串比较被拒载。
set -euo pipefail

TARGET="scripts/build_kernel.sh"
if [ ! -f "$TARGET" ]; then
    echo "找不到 $TARGET —— 必须在 build 仓库根目录运行" >&2
    ls -la >&2
    exit 1
fi

python3 - "$TARGET" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()

# 清掉上一版可能注入过的块（含错误的 LOCALVERSION 行）
s = re.sub(r'\n *    # --- KO_COMPAT.*?olddefconfig\n', '\n', s, flags=re.S)

anchor = '    make "${MAKEFLAGS[@]}" $DEFCONFIG\n'
if s.count(anchor) != 1:
    print('[ko-compat] 锚点不唯一/不存在，count=%d' % s.count(anchor))
    raise SystemExit(1)

block = anchor + '''    # --- KO_COMPAT: 第三方 .ko 兼容（不改 LOCALVERSION，版本串由 .scmversion 决定）---
    ./scripts/config --file out/.config -e CONFIG_MODULE_FORCE_LOAD
    ./scripts/config --file out/.config -e CONFIG_MODULE_UNLOAD
    ./scripts/config --file out/.config -d CONFIG_MODULE_SIG
    ./scripts/config --file out/.config -d CONFIG_MODULE_SIG_FORCE
    make "${MAKEFLAGS[@]}" olddefconfig
'''
open(p, 'w').write(s.replace(anchor, block, 1))
print('[ko-compat] 注入完成')
PY

echo '--- 注入结果 ---'
grep -n 'KO_COMPAT' -A 7 "$TARGET"

# 硬校验：LOCALVERSION 必须还是 -qgki，AUTO 必须还是 y
echo '--- LOCALVERSION 校验 ---'
grep -E '^(CONFIG_LOCALVERSION=|# CONFIG_LOCALVERSION_AUTO)' scripts/build_kernel.sh || true
