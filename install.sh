#!/bin/bash
# Install the launcher on Desktop without launching or quitting the app.
set -euo pipefail

if [ "$(uname -s)" != Darwin ]; then
  printf '%s\n' 'This launcher requires macOS.' >&2
  exit 1
fi
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != --local ]; }; then
  printf '%s\n' 'Usage: bash install.sh [--local]' >&2
  exit 1
fi

desktop="${CODEX_SLIDER_DESKTOP:-$HOME/Desktop}"
target="$desktop/三档滑块.command"
mkdir -p "$desktop"
if [ -e "$target" ] || [ -L "$target" ]; then
  printf '%s\n' 'Desktop/三档滑块.command already exists. Move or rename it before installing again.' >&2
  exit 1
fi
staging=$(mktemp -d "$desktop/.codex-model-slider.XXXXXX")
trap 'rm -rf "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
launcher="$staging/launcher.command"

if [ "${1:-}" = --local ]; then
  source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  cp "$source_dir/三档滑块.command" "$launcher"
else
  curl --fail --show-error --silent --location --connect-timeout 15 --max-time 120 \
    'https://raw.githubusercontent.com/cabbagecabbage/codex-model-slider/main/%E4%B8%89%E6%A1%A3%E6%BB%91%E5%9D%97.command' \
    --output "$launcher"
fi

# Reject empty/error responses before placing anything on the desktop.
IFS= read -r first_line < "$launcher"
[ "$first_line" = '#!/bin/bash' ] || { printf '%s\n' 'Invalid launcher download.' >&2; exit 1; }
/bin/bash -n "$launcher"
chmod 755 "$launcher"
# Atomic creation; refuse to replace an existing file, including a symlink.
ln "$launcher" "$target"
printf '%s\n' '已安装到桌面：三档滑块.command' 'Installed on Desktop. Finish active Codex tasks, then double-click 三档滑块.command.'
