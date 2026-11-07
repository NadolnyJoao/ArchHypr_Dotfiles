hl.on("hyprland.start", function()
    hl.exec_cmd([[config="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
        if [ -r "$config/current-theme" ] && [ -r "$config/scripts/gtk-theme.sh" ]; then
            bash "$config/scripts/gtk-theme.sh" "$(cat "$config/current-theme")"
        fi]])
    hl.exec_cmd([[script="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/wallpaper.sh"
        if [ -r "$script" ]; then
            hyprpaper &
            exec bash "$script" loop
        fi]])
    hl.exec_cmd("command -v swaync >/dev/null && exec swaync")
    hl.exec_cmd("command -v waybar >/dev/null && exec waybar")
    hl.exec_cmd("command -v hypridle >/dev/null && exec hypridle")
    hl.exec_cmd("command -v hyprsunset >/dev/null && exec hyprsunset")
end)
