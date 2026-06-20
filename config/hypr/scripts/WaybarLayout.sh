#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for waybar layout or configs

IFS=$'\n\t'

# Define directories
waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
# shellcheck source=/dev/null
source "$SCRIPTSDIR/RofiCommon.sh"
rofi_config="$HOME/.config/rofi/config-waybar-layout.rasi"
msg=' 🎌 NOTE: Some waybar LAYOUT NOT fully compatible with some STYLES'

# Apply selected configuration
apply_config() {
    ln -sf "$waybar_layouts/$1" "$waybar_config"
    "${SCRIPTSDIR}/Refresh.sh" &
}

main() {
    # Resolve current symlink target and basename
    current_target=$(readlink -f "$waybar_config")
    current_name=$(basename "$current_target")

    # Build sorted list of available layouts
    mapfile -t options < <(
        find -L "$waybar_layouts" -maxdepth 1 -type f -printf '%f\n' | sort
    )

    # Mark and locate the active layout
    default_row=0
    MARKER="👉"
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "$current_name" ]]; then
            options[i]="$MARKER ${options[i]}"
            default_row=$i
            break
        fi
    done

    choice=$(printf '%s\n' "${options[@]}" \
        | rofi_menu_pick "$msg" "$rofi_config" "$default_row"
    )

    # Exit if nothing chosen
    [[ -z "$choice" ]] && { echo "No option selected. Exiting."; exit 0; }

    # Strip marker before applying
    choice=${choice#"$MARKER "}

    case "$choice" in
        "no panel")
            pgrep -x "waybar" && pkill waybar || true
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

rofi_prepare

main
