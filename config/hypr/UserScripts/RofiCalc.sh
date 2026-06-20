#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Calculadora via qalculate + Rofi

scripts_dir="$HOME/.config/hypr/scripts"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

calc_result=""

rofi_prepare

while true; do
  prompt="Calculadora"
  if [[ -n "$calc_result" ]]; then
    prompt="$result = $calc_result"
  fi

  result=$(rofi_prompt_only "$prompt") || exit

  if [[ -n "$result" ]]; then
    calc_result=$(qalc -t "$result")
    echo "$calc_result" | wl-copy
  fi
done
