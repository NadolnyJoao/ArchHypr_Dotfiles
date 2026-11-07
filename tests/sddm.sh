#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source lib/sddm.sh
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
theme="$temp/theme"
mkdir -p "$theme/Themes" "$theme/Fonts"
touch "$theme/Main.qml"
printf '[SddmGreeterTheme]\nConfigFile=Themes/astronaut.conf\n' > "$theme/metadata.desktop"
printf '[General]\nBackground="Backgrounds/old.jpg"\nOther=keep\n' > "$theme/Themes/japanese_aesthetic.conf"
if prepare_astronaut "$theme" "$temp/missing.png"; then exit 1; fi
grep -q 'ConfigFile=Themes/astronaut.conf' "$theme/metadata.desktop"
printf 'wallpaper\n' > "$temp/arch-nord-dark.png"
prepare_astronaut "$theme" "$temp/arch-nord-dark.png"
cmp "$temp/arch-nord-dark.png" "$theme/Backgrounds/arch-nord-dark.png"
grep -Fx 'ConfigFile=Themes/japanese_aesthetic.conf' "$theme/metadata.desktop"
grep -Fx 'Background="Backgrounds/arch-nord-dark.png"' "$theme/Themes/japanese_aesthetic.conf"
grep -Fx 'Other=keep' "$theme/Themes/japanese_aesthetic.conf"
