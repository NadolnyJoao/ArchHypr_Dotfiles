#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
export XDG_DATA_HOME="$temp/data" XDG_RUNTIME_DIR="$temp/runtime" XDG_CONFIG_HOME="$temp/config"
export HYPRLAND_INSTANCE_SIGNATURE=test TEST_DIR="$temp" PATH="$temp/bin:$PATH"
pack="$XDG_DATA_HOME/rice-arch/Wallpapers_Pack/wallpapers"
mkdir -p "$pack" "$XDG_RUNTIME_DIR" "$temp/bin" "$XDG_CONFIG_HOME"
cp -r dotfiles/. "$XDG_CONFIG_HOME/"
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

# Cada tema mantém sua posição; nenhum subdiretório de outro tema entra no fallback.
for theme in nord gruvbox catppuccin solitude; do
    mkdir -p "$pack/$theme"
    for index in 1 2 3; do
        printf '%s-%s\n' "$theme" "$index" > "$pack/$theme/$index.jpg"
    done
done
printf 'nord\n' > "$XDG_CONFIG_HOME/hypr/current-theme"
bash "$wallpaper" next
read -r current < "$runtime/current"
cp "$current" "$temp/nord-first"
[[ $(cat "$current") == nord-* ]]
[[ $(tr -cd '\0' < "$runtime/playlist-nord" | wc -c) == 5 ]]
cp "$runtime/playlist-nord" "$temp/nord-queue"
printf 'gruvbox\n' > "$XDG_CONFIG_HOME/hypr/current-theme"
bash "$wallpaper" next
cmp "$runtime/playlist-nord" "$temp/nord-queue"
printf 'nord\n' > "$XDG_CONFIG_HOME/hypr/current-theme"
mapfile -d '' -t expected < "$runtime/playlist-nord"
bash "$wallpaper" next
read -r current < "$runtime/current"
cmp "$current" "${expected[expected[0] + 3]}"
! cmp -s "$current" "$temp/nord-first"
cp "$runtime/playlist-nord" "$temp/before-failure"
if FAIL_WALLPAPER=1 bash "$wallpaper" next; then exit 1; fi
cmp "$runtime/playlist-nord" "$temp/before-failure"

# A troca pelo Rofi aplica e avança a mesma fila (sem efeitos na sessão real).
cat > "$temp/bin/rofi" <<'MOCK'
#!/usr/bin/env bash
cat >/dev/null
printf 'catppuccin\n'
MOCK
cat > "$temp/bin/pgrep" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat > "$XDG_CONFIG_HOME/hypr/scripts/gtk-theme.sh" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
sed -i '/\[\[ $1 == hyprpaper/i [[ $1 == reload ]] && exit 0' "$temp/bin/hyprctl"
chmod +x "$temp/bin/rofi" "$temp/bin/pgrep"
bash "$XDG_CONFIG_HOME/hypr/scripts/theme.sh" menu
read -r current < "$runtime/current"
[[ $(cat "$current") == catppuccin-* ]]
mapfile -d '' -t expected < "$runtime/playlist-catppuccin"
bash "$wallpaper" next
read -r current < "$runtime/current"
cmp "$current" "${expected[expected[0] + 3]}"

# Pasta vazia ou ausente usa somente a raiz, inclusive ao invalidar uma fila antiga.
rm -- "$pack/solitude/"*.jpg
for theme in solitude gruvbox; do
    if [[ $theme == gruvbox ]]; then mv "$pack/gruvbox" "$pack/fora"; fi
    printf '%s\n' "$theme" > "$XDG_CONFIG_HOME/hypr/current-theme"
    bash "$wallpaper" next
    read -r current < "$runtime/current"
    cmp "$current" "$pack/teste, cenário.png"
done
# Uma pasta que passa a ter imagens substitui o fallback imediatamente.
printf 'solitude nova\n' > "$pack/solitude/nova.jpg"
printf 'solitude\n' > "$XDG_CONFIG_HOME/hypr/current-theme"
bash "$wallpaper" next
read -r current < "$runtime/current"
cmp "$current" "$pack/solitude/nova.jpg"

# O processo automático usa a mesma fila e mantém o intervalo padrão de uma hora.
cat > "$temp/bin/sleep" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$1" > "$TEST_DIR/interval"
exit 1
MOCK
chmod +x "$temp/bin/sleep"
printf 'catppuccin\n' > "$XDG_CONFIG_HOME/hypr/current-theme"
mapfile -d '' -t expected < "$runtime/playlist-catppuccin"
env -u RICE_WALLPAPER_INTERVAL bash "$wallpaper" loop
read -r current < "$runtime/current"
cmp "$current" "${expected[expected[0] + 3]}"
[[ $(cat "$temp/interval") == 3600 ]]
mapfile -d '' -t played < "$runtime/playlist-catppuccin"
[[ ${played[0]} == 2 ]]


# O menu usa índices, aceita nomes com vírgula e preserva a fila ao cancelar.
cat > "$temp/bin/rofi" <<'MOCK'
#!/usr/bin/env bash
if [[ $1 == -e ]]; then printf '%s\n' "$2" > "$TEST_DIR/empty-menu"; exit 0; fi
cat > "$TEST_DIR/menu"
[[ ${CANCEL_MENU:-0} == 0 ]] || exit 1
printf '%s\n' "${PICK_INDEX:-0}"
MOCK
target="$pack/catppuccin/teste, cenário.png"
printf 'seleção do tema\n' > "$target"
mapfile -d '' -t menu_images < <(find "$pack/catppuccin" -type f -print0 | sort -z)
for index in "${!menu_images[@]}"; do
    if [[ ${menu_images[index]} == "$target" ]]; then break; fi
done
cp "$runtime/playlist-catppuccin" "$temp/before-cancel"
CANCEL_MENU=1 bash "$wallpaper" menu
cmp "$temp/before-cancel" "$runtime/playlist-catppuccin"
PICK_INDEX=$index bash "$wallpaper" menu
grep -azq 'icon' "$temp/menu"
if grep -aqE '/(nord|solitude|fora)/|wallpapers/teste' "$temp/menu"; then exit 1; fi
cmp "$(cat "$runtime/current")" "$target"
bash "$wallpaper" prev
cmp "$(cat "$runtime/current")" "${expected[expected[0] + 3]}"
bash "$wallpaper" next
cmp "$(cat "$runtime/current")" "$target"

printf 'gruvbox\n' > "$XDG_CONFIG_HOME/hypr/current-theme"
bash "$wallpaper" menu
grep -Fq 'Nenhum wallpaper na pasta do tema gruvbox.' "$temp/empty-menu"
cmp "$(cat "$runtime/current")" "$target"
