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
printf 'wallpaper\n' > "$temp/613342.jpg"
printf 'HeaderTextColor="#222222"\nHighlightTextColor="#111111"\n' >> "$theme/Themes/japanese_aesthetic.conf"
prepare_astronaut "$theme" "$temp/613342.jpg"
cmp "$temp/613342.jpg" "$theme/Backgrounds/613342.jpg"
grep -Fx 'ConfigFile=Themes/japanese_aesthetic.conf' "$theme/metadata.desktop"
grep -Fx 'Background="Backgrounds/613342.jpg"' "$theme/Themes/japanese_aesthetic.conf"
grep -Fx 'Other=keep' "$theme/Themes/japanese_aesthetic.conf"
grep -Fx 'HeaderTextColor="#ffffff"' "$theme/Themes/japanese_aesthetic.conf"
grep -Fx 'HighlightTextColor="#ffffff"' "$theme/Themes/japanese_aesthetic.conf"

# Precedência real: vendor < drop-ins locais < arquivo legado.
mkdir -p "$temp/vendor" "$temp/local"
printf '[Theme]\nCurrent=vendor\n' > "$temp/vendor/00-default.conf"
printf '[Theme]\nCurrent=rice-arch-astronaut\n' > "$temp/local/90-rice.conf"
checker=(python3 lib/check-sddm.py "$temp/vendor" "$temp/local" "$temp/legacy.conf" /usr/share/sddm/themes)
"${checker[@]}"
printf '[Theme]\nCurrent=outro\n' > "$temp/local/99-override.conf"
if "${checker[@]}"; then exit 1; fi
printf '[Theme]\nCurrent=rice-arch-astronaut\n' > "$temp/legacy.conf"
"${checker[@]}"
printf 'ThemeDir=/outro/diretorio\n' >> "$temp/legacy.conf"
if "${checker[@]}"; then exit 1; fi
printf 'config inválida\n' > "$temp/legacy.conf"
if "${checker[@]}"; then exit 1; fi
