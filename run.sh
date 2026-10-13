#!/usr/bin/env bash
# 快速启动 / 验证脚本
# 自动配置 brew(GTK 运行时) 与 Flutter 镜像所需环境变量，再运行本项目。
#
# 平台目录约定：
#   Flutter 要求 Linux 平台目录必须位于项目根且命名为 linux，
#   无法改路径。因此真实文件放在 platforms/gnu_linux，
#   本脚本在构建/运行前临时建软链（linux -> platforms/gnu_linux），
#   退出后删除，使根目录平时保持整洁。
#   注意：必须用本脚本跑；IDE 直接 flutter run 会因找不到根目录 linux/ 而失败。
#
# 渲染后端：
#   使用 Flutter 官方 GTK 嵌入器（platforms/gnu_linux）。观感由系统 KDE 的
#   GTK 主题设置决定，本脚本不做任何主题硬编码。
#
# 用法:
#   ./run.sh            # 构建并启动 GTK 版
#   ./run.sh build      # 仅构建
#   ./run.sh analyze    # flutter analyze
#
# 可用环境变量覆盖默认值:
#   BREW_PREFIX    brew 安装前缀（默认 /home/linuxbrew/.linuxbrew）
#   FLUTTER_BIN    flutter/bin 目录（默认 $HOME/flutter/bin）
set -euo pipefail
shopt -s nullglob

# ---- 路径 ----
BREW_PREFIX="${BREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
FLUTTER_BIN="${FLUTTER_BIN:-$HOME/flutter/bin}"

# ---- 环境变量 ----
export PATH="$FLUTTER_BIN:$PATH"
export PKG_CONFIG_PATH="$BREW_PREFIX/lib/pkgconfig:$BREW_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
# GTK 等运行时库走 brew
export DISPLAY="${DISPLAY:-:0}"

# 切到脚本所在目录（项目根），兼容任意调用路径
cd "$(dirname "$0")"

# ---- 平台软链：构建前建、退出时删（保持根目录整洁）----
ensure_platform_links() {
  for d in platforms/*/; do
    local name link
    name="$(basename "$d")"
    link="$name"
    [ "$name" = "gnu_linux" ] && link="linux"
    [ -L "$link" ] || ln -sf "platforms/$name" "$link"
  done
}
cleanup_platform_links() {
  for link in linux android web windows; do
    [ -L "$link" ] && rm -f "$link"
  done
}
trap cleanup_platform_links EXIT
ensure_platform_links

# ---- 构建 / 运行 ----
BUNDLE="build/linux/x64/release/bundle"
EXE="$BUNDLE/book_reader"

cmd="${1:-run}"
shift || true

case "$cmd" in
  analyze)
    flutter --no-version-check analyze
    ;;
  build)
    LD_LIBRARY_PATH="$BREW_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      flutter --no-version-check build linux
    ;;
  run|*)
    LD_LIBRARY_PATH="$BREW_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      flutter --no-version-check build linux
    LD_LIBRARY_PATH="$BREW_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      "$EXE"
    ;;
esac
