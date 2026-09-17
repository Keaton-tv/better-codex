#!/bin/bash
# Install the launcher on Desktop without launching or quitting the app.
set -euo pipefail
trap 'printf "%s\n" "Installation failed. See the message above. / 安装未完成，请查看上方提示。" >&2' ERR

if [ "$(uname -s)" != Darwin ]; then
  printf '%s\n' 'This launcher requires macOS. / 此启动脚本仅支持 macOS。' >&2
  exit 1
fi
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != --local ]; }; then
  printf '%s\n' 'Usage / 用法: bash install.sh [--local]' >&2
  exit 1
fi

desktop="${CODEX_SLIDER_DESKTOP:-$HOME/Desktop}"
target="$desktop/Codex-Model-Slider.command"
mkdir -p "$desktop"
if [ -e "$target" ] || [ -L "$target" ]; then
  printf '%s\n' 'Desktop/Codex-Model-Slider.command already exists. Move or rename it before installing again. / 桌面已有同名文件，请先移走或重命名后再安装。' >&2
  exit 1
fi
staging=$(mktemp -d "$desktop/.codex-model-slider.XXXXXX")
trap 'rm -rf "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
launcher="$staging/launcher.command"

if [ "${1:-}" = --local ]; then
  source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  cp "$source_dir/Codex-Model-Slider.command" "$launcher"
else
  curl --fail --show-error --silent --location --connect-timeout 15 --max-time 120 \
    'https://raw.githubusercontent.com/cabbagecabbage/codex-model-slider/main/Codex-Model-Slider.command' \
    --output "$launcher"
fi

# Reject empty/error responses before placing anything on the desktop.
IFS= read -r first_line < "$launcher"
[ "$first_line" = '#!/bin/bash' ] || { printf '%s\n' 'Invalid launcher download. / 下载的启动脚本无效。' >&2; exit 1; }
/bin/bash -n "$launcher"
chmod 755 "$launcher"
# Atomic creation; refuse to replace an existing file, including a symlink.
ln "$launcher" "$target"
printf '%s\n' 'Installed on Desktop / 已安装到桌面：Codex-Model-Slider.command' 'Finish active Codex tasks, then double-click the file. / 请先结束 Codex 中正在进行的任务，再双击此文件。'
