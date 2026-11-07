#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
project_dir=$PWD
source lib/steps.sh
source lib/dotfiles.sh

temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
report_dir=$temp/report
mkdir -p "$report_dir" "$temp/config/hypr" "$temp/runtime" "$temp/bin"
printf 'original\n' > "$temp/config/hypr/hyprland.lua"
files=(hypr/modules/appearance.lua hypr/modules/bindings.lua hypr/modules/session.lua hypr/modules/input.lua hypr/hyprland.lua)
run_step hyprland '' install_hyprland_dotfiles "$temp/config" "${files[@]}"
[[ ${step_status[hyprland]} == OK ]]
[[ $(cat "$report_dir/backup/hypr/hyprland.lua") == original ]]
for file in "${files[@]}"; do cmp "dotfiles/$file" "$temp/config/$file"; done
run_step reexecucao '' install_hyprland_dotfiles "$temp/config" "${files[@]}"
[[ ${step_status[reexecucao]} == JA_PRONTO ]]

export PATH="$temp/bin:$PATH" XDG_RUNTIME_DIR="$temp/runtime" MOCK_DIR="$temp"
cat > "$temp/bin/brightnessctl" <<'MOCK'
#!/usr/bin/env bash
case "$3" in
    get) cat "$MOCK_DIR/brightness" ;;
    max) printf '1000\n' ;;
    set) printf '%s\n' "$4" >> "$MOCK_DIR/sets" ;;
    *) exit 2 ;;
esac
MOCK
chmod +x "$temp/bin/brightnessctl"
brightness_script=dotfiles/hypr/scripts/idle-brightness.sh
printf '650\n' > "$temp/brightness"
bash "$brightness_script" dim
bash "$brightness_script" dim
bash "$brightness_script" restore
bash "$brightness_script" restore
printf '20%%\n650\n' | cmp - "$temp/sets"
rm -- "$temp/brightness"
bash "$brightness_script" dim
bash "$brightness_script" restore
printf '20%%\n650\n' | cmp - "$temp/sets"
