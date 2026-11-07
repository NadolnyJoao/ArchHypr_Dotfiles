#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
export XDG_DATA_HOME="$temp/data" XDG_RUNTIME_DIR="$temp/runtime" XDG_CONFIG_HOME="$PWD/dotfiles"
export HYPRLAND_INSTANCE_SIGNATURE=test TEST_DIR="$temp" PATH="$temp/bin:$PATH"
pack="$XDG_DATA_HOME/rice-arch/Wallpapers_Pack/wallpapers"
mkdir -p "$pack" "$XDG_RUNTIME_DIR" "$temp/bin"
printf 'imagem simulada\n' > "$pack/teste, cenário.png"
cat > "$temp/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
[[ $1 == hyprpaper && $2 == wallpaper && $3 == ,*,cover ]] || exit 2
[[ ${FAIL_WALLPAPER:-0} == 0 ]] && echo ok || echo erro
MOCK
cat > "$temp/bin/hyprlock" <<'MOCK'
#!/usr/bin/env bash
set -eu
[[ $1 == --config ]]
cp -- "$2" "$TEST_DIR/lock.conf"
image=$(sed -n 's/^    path = //p' "$2")
if [[ -n $image ]]; then cp -- "$image" "$TEST_DIR/lock-image"; fi
MOCK
chmod +x "$temp/bin/"*
runtime="$XDG_RUNTIME_DIR/rice-wallpaper-test"
wallpaper=dotfiles/hypr/scripts/wallpaper.sh
bash "$wallpaper" once
read -r first < "$runtime/current"
cmp "$first" "$pack/teste, cenário.png"
if FAIL_WALLPAPER=1 bash "$wallpaper" once; then exit 1; fi
[[ $(cat "$runtime/current") == "$first" && -f $first ]]
bash dotfiles/hypr/scripts/lock.sh
grep -q 'path = ' "$temp/lock.conf"
cmp "$first" "$temp/lock-image"
bash "$wallpaper" once
[[ ! -e $first ]]
rm -- "$runtime/current"
bash dotfiles/hypr/scripts/lock.sh
! grep -q 'path = ' "$temp/lock.conf"
