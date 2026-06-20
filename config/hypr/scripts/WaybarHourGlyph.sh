#!/usr/bin/env bash
# Emoji hieroglífico da hora — waybar, à direita da data.

hour="$(date +%H)"

case "$hour" in
  00) printf '%s\n' '𓀐' ;;
  01) printf '%s\n' '𓀏' ;;
  02|03|04|05) printf '%s\n' '𓀒' ;;
  06) printf '%s\n' '𓀓' ;;
  07) printf '%s\n' '𓀔' ;;
  08) printf '%s\n' '𓀕' ;;
  09) printf '%s\n' '𓀊' ;;
  10) printf '%s\n' '𓀃' ;;
  11) printf '%s\n' '𓀗' ;;
  12) printf '%s\n' '𓀁' ;;
  13) printf '%s\n' '𓀆' ;;
  14) printf '%s\n' '𓀎' ;;
  15) printf '%s\n' '𓀍' ;;
  16) printf '%s\n' '𓀌' ;;
  17) printf '%s\n' '𓀑' ;;
  18) printf '%s\n' '𓀘' ;;
  19) printf '%s\n' '𓀙' ;;
  20) printf '%s\n' '𓀋' ;;
  21) printf '%s\n' '𓀅' ;;
  22) printf '%s\n' '𓀄' ;;
  23) printf '%s\n' '𓀜' ;;
  *) printf '%s\n' '𓀐' ;;
esac
