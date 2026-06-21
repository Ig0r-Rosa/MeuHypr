#!/usr/bin/env python3
"""Menu de energia — script Rofi (Super+Alt+Delete)."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
ACTION_MARKER = Path(f"/run/user/{os.getuid()}/rofi-power.action")

# key, emoji exibido, comando
POWER_OPTIONS = (
    ("reboot", "🔄", f"{SCRIPTS_DIR}/PowerReboot.sh"),
    ("shutdown", "❎", f"{SCRIPTS_DIR}/PowerShutdown.sh"),
)


def emit_row(key: str, emoji: str) -> None:
    """Emite uma opção — apenas o emoji no display."""
    sys.stdout.write(f"{key}\0display\x1f{emoji}\x1finfo\x1f{key}\n")


def emit_list() -> None:
    """Reiniciar e desligar — duas colunas com emoji grande."""
    for key, emoji, _cmd in POWER_OPTIONS:
        emit_row(key, emoji)


def acquire_action_once() -> bool:
    """Marca atômica persistente — sobrevive ao fim do processo."""
    try:
        ACTION_MARKER.mkdir(mode=0o700, exist_ok=False)
    except FileExistsError:
        return False
    return True


def run_script(script: Path, *, detach: bool = False) -> None:
    """Executa script de energia."""
    env = os.environ.copy()
    env["ROFI_POWER_GUARDED"] = "1"
    kwargs = {
        "stdout": subprocess.DEVNULL,
        "stderr": subprocess.DEVNULL,
        "env": env,
    }

    if detach:
        subprocess.Popen(
            [str(script)],
            start_new_session=True,
            **kwargs,
        )
        return

    subprocess.run([str(script)], check=False, **kwargs)


def run_action(key: str) -> None:
    """Executa reboot ou shutdown uma única vez."""
    if not acquire_action_once():
        return

    for opt_key, _emoji, cmd in POWER_OPTIONS:
        if opt_key != key:
            continue
        # Reiniciar/desligar — executa na sessão ativa (sem detach).
        run_script(Path(cmd), detach=False)
        return


def main() -> int:
    retv = int(os.environ.get("ROFI_RETV", "0"))
    action_key = os.environ.get("ROFI_INFO", "") or os.environ.get("ROFI_INPUT", "")

    # Só confirma com Enter ou clique (retv 1). Ignora outros retv duplicados.
    if retv == 1 and action_key in {opt[0] for opt in POWER_OPTIONS}:
        run_action(action_key)
        return 0

    emit_list()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
