#!/usr/bin/env python3
"""Launcher Super+D — renomear e ocultar apps (modo script Rofi)."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from configparser import ConfigParser
from functools import lru_cache
from pathlib import Path

STATE_PATH = Path.home() / ".config/rofi/launcher-state.json"
ACTION_FILE = Path(
    os.environ.get("XDG_RUNTIME_DIR", "/tmp")
) / "rofi-launcher.action"
ICON_CACHE_DIR = Path(
    os.environ.get("XDG_RUNTIME_DIR", "/tmp")
) / "rofi-launcher-icons"
MOAI_EMOJI = "🗿"
MOAI_ICON_FILE = ICON_CACHE_DIR / "_moai_fallback.png"
TRANSPARENT_ICON_FILE = ICON_CACHE_DIR / "_transparent.png"
# Igual ao element-icon do config-launcher.rasi (52px).
ICON_TARGET_SIZE = 52
# Grid do launcher (config-launcher.rasi): 7 colunas × 4 linhas.
GRID_COLUMNS = 7
GRID_LINES = 4
SLOTS_PER_PAGE = GRID_COLUMNS * GRID_LINES
# Cantos vazios por página: 1ª/última coluna da 1ª e da última linha.
_PAGE_LAST_ROW = (GRID_LINES - 1) * GRID_COLUMNS
PAGE_CORNER_SLOTS = frozenset({0, GRID_COLUMNS - 1, _PAGE_LAST_ROW, SLOTS_PER_PAGE - 1})


def load_state() -> dict:
    if not STATE_PATH.exists():
        return default_state()
    try:
        data = json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return default_state()
    base = default_state()
    base.update({k: data.get(k, base[k]) for k in base})
    sanitize_state(base)
    return base


def sanitize_state(state: dict) -> None:
    """Remove chaves legadas e IDs inválidos da lista de ocultos."""
    state.pop("favorites", None)
    state["hidden"] = [
        app_id
        for app_id in state.get("hidden", [])
        if app_id.endswith(".desktop")
    ]


def default_state() -> dict:
    return {"renames": {}, "hidden": []}


def save_state(state: dict) -> None:
    sanitize_state(state)
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(
        json.dumps(state, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def desktop_dirs() -> list[Path]:
    dirs: list[Path] = []
    xdg = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    for base in xdg.split(":"):
        path = Path(base) / "applications"
        if path.is_dir():
            dirs.append(path)
    local = Path.home() / ".local/share/applications"
    if local.is_dir():
        dirs.append(local)
    return dirs


def desktop_allowed(de: dict[str, str]) -> bool:
    if de.get("Type", "") != "Application":
        return False
    if de.get("NoDisplay", "false").lower() == "true":
        return False
    if de.get("Hidden", "false").lower() == "true":
        return False
    only = [x.strip() for x in de.get("OnlyShowIn", "").split(";") if x.strip()]
    if only and "Hyprland" not in only and "Wayland" not in only:
        return False
    deny = [x.strip() for x in de.get("NotShowIn", "").split(";") if x.strip()]
    if "Hyprland" in deny or "Wayland" in deny:
        return False
    return bool(de.get("Name", "").strip())


def parse_desktop(path: Path) -> dict | None:
    parser = ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        parser.read(path, encoding="utf-8")
    except OSError:
        return None
    if not parser.has_section("Desktop Entry"):
        return None
    de = dict(parser["Desktop Entry"])
    if not desktop_allowed(de):
        return None
    return {
        "id": path.name,
        "path": str(path),
        "name": de.get("Name", path.stem),
        "generic": de.get("GenericName", ""),
        "exec": de.get("Exec", ""),
        "icon": de.get("Icon", "application-x-executable"),
        "keywords": de.get("Keywords", ""),
        "categories": de.get("Categories", ""),
    }


def scan_apps() -> dict[str, dict]:
    apps: dict[str, dict] = {}
    for folder in desktop_dirs():
        for path in sorted(folder.glob("*.desktop")):
            app = parse_desktop(path)
            if app:
                apps[app["id"]] = app
    return apps


def display_name(app: dict, state: dict) -> str:
    return state["renames"].get(app["id"], app["name"])


def search_blob(app: dict, state: dict) -> str:
    shown = display_name(app, state)
    parts = [app["name"], shown, app.get("generic", ""), app.get("keywords", "")]
    return " ".join(p for p in parts if p).lower()


def launcher_hidden_mode() -> bool:
    """Modo ocultos: Super+Shift+D (env) ou reload do Rofi (ROFI_DATA)."""
    if os.environ.get("ROFI_LAUNCHER_MODE") == "hidden":
        return True
    return "show_hidden=1" in os.environ.get("ROFI_DATA", "")


def sort_key(app: dict, state: dict) -> str:
    return display_name(app, state).lower()


def encode_data(show_hidden: bool) -> str:
    return f"show_hidden={'1' if show_hidden else '0'}"


@lru_cache(maxsize=1)
def _gtk_icon_theme():
    """Tema GTK para resolver nomes simbólicos em caminhos absolutos."""
    try:
        import gi

        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk  # noqa: PLC0415

        Gtk.init([])
        theme = Gtk.IconTheme.get_default()
        for path in (
            "/usr/share/icons",
            str(Path.home() / ".local/share/icons"),
            str(Path.home() / ".icons"),
        ):
            theme.append_search_path(path)
        return theme
    except Exception:
        return None


def resolve_icon_path(icon: str) -> str:
    """Localiza o arquivo de ícone original do .desktop."""
    icon = (icon or "").strip() or "application-x-executable"
    if icon.startswith("/"):
        return icon if Path(icon).is_file() else "application-x-executable"

    theme = _gtk_icon_theme()
    if theme is None:
        return icon

    found: list[str] = []
    for size in (256, 128, 64, 48, 32):
        info = theme.lookup_icon(icon, size, 0)
        if not info:
            continue
        path = info.get_filename()
        if path and Path(path).is_file():
            found.append(path)

    if not found:
        return icon

    for path in found:
        ext = Path(path).suffix.lower()
        if ext in {".png", ".jpg", ".jpeg", ".webp", ".ico"}:
            return path

    return found[0]


def has_desktop_icon(app: dict) -> bool:
    """True quando o .desktop define Icon= (mesmo que simbólico)."""
    return bool((app.get("icon") or "").strip())


def ensure_moai_icon(size: int = ICON_TARGET_SIZE) -> str:
    """PNG com 🗿 — fallback quando o ícone real não carrega."""
    if validate_png(MOAI_ICON_FILE, size=size):
        return str(MOAI_ICON_FILE)

    ICON_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        import gi

        gi.require_version("Pango", "1.0")
        gi.require_version("PangoCairo", "1.0")
        import cairo  # noqa: PLC0415
        from gi.repository import Pango, PangoCairo  # noqa: PLC0415

        surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
        ctx = cairo.Context(surface)
        ctx.set_source_rgba(0, 0, 0, 0)
        ctx.paint()

        layout = PangoCairo.create_layout(ctx)
        font = Pango.FontDescription()
        font.set_family("Noto Color Emoji")
        font.set_size(int(size * 0.65 * Pango.SCALE))
        layout.set_font_description(font)
        layout.set_text(MOAI_EMOJI, -1)

        width, height = layout.get_pixel_size()
        ctx.move_to((size - width) / 2, (size - height) / 2)
        PangoCairo.show_layout(ctx, layout)
        surface.write_to_png(str(MOAI_ICON_FILE))
        fsync_file(MOAI_ICON_FILE)
    except Exception:
        pass

    return str(MOAI_ICON_FILE)


def ensure_transparent_icon(size: int = ICON_TARGET_SIZE) -> str:
    """PNG transparente 52×52 — ocupa slot 0 e evita bug async do Rofi."""
    if validate_png(TRANSPARENT_ICON_FILE, size=size):
        return str(TRANSPARENT_ICON_FILE)

    ICON_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        import gi

        gi.require_version("GdkPixbuf", "2.0")
        import cairo  # noqa: PLC0415
        from gi.repository import GdkPixbuf  # noqa: PLC0415

        surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
        ctx = cairo.Context(surface)
        ctx.set_source_rgba(0, 0, 0, 0)
        ctx.paint()
        surface.write_to_png(str(TRANSPARENT_ICON_FILE))
        fsync_file(TRANSPARENT_ICON_FILE)
        if validate_png(TRANSPARENT_ICON_FILE, size=size):
            return str(TRANSPARENT_ICON_FILE)
    except Exception:
        pass

    return ensure_moai_icon(size)


def icon_cache_file(app_id: str) -> Path:
    safe = app_id.replace("/", "_")
    return ICON_CACHE_DIR / f"{safe}.png"


def _pixbuf_module():
    """GdkPixbuf com versão fixada — evita PyGIWarning."""
    import gi

    gi.require_version("GdkPixbuf", "2.0")
    from gi.repository import GdkPixbuf  # noqa: PLC0415

    return GdkPixbuf


def validate_png(path: Path, *, size: int | None = None) -> bool:
    """Confirma que o PNG existe, é legível e (opcional) tem o tamanho esperado."""
    if not path.is_file() or path.stat().st_size == 0:
        return False
    try:
        pixbuf = _pixbuf_module().Pixbuf.new_from_file(str(path))
        if size is not None:
            return (
                pixbuf.get_width() == size
                and pixbuf.get_height() == size
            )
        return True
    except Exception:
        return False


def fsync_file(path: Path) -> None:
    with path.open("rb") as handle:
        os.fsync(handle.fileno())


def write_png_from_source(
    src: Path,
    cache: Path,
    size: int = ICON_TARGET_SIZE,
) -> bool:
    """Redimensiona qualquer origem para PNG estável no cache (sempre size×size)."""
    ICON_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        GdkPixbuf = _pixbuf_module()
        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
            str(src),
            size,
            size,
            True,
        )
        pixbuf.savev(str(cache), "png", [], [])
        fsync_file(cache)
        return validate_png(cache, size=size)
    except (OSError, Exception):
        return False


def materialize_icon(
    icon: str,
    app_id: str,
    size: int = ICON_TARGET_SIZE,
    *,
    force: bool = False,
) -> str:
    """Grava PNG estável por app — Rofi carrega sempre o mesmo caminho."""
    if not (icon or "").strip():
        return "image-missing"

    source = resolve_icon_path(icon)
    if not source.startswith("/"):
        return source

    src = Path(source)
    if not src.is_file():
        return "application-x-executable"

    cache = icon_cache_file(app_id)
    src_mtime = int(src.stat().st_mtime)

    if (
        not force
        and cache.is_file()
        and cache.stat().st_mtime >= src_mtime
        and validate_png(cache, size=size)
    ):
        return str(cache)

    if write_png_from_source(src, cache, size):
        return str(cache)

    return "application-x-executable"


def icon_field(icon: str, app_id: str) -> str:
    """Um ícone por linha — tema GTK (como drun) ou PNG 52px cacheado."""
    raw = (icon or "").strip()
    if not raw:
        return ensure_moai_icon()

    source = resolve_icon_path(raw)
    if not source.startswith("/"):
        return source

    cached = materialize_icon(raw, app_id, size=ICON_TARGET_SIZE)
    if cached.startswith("/"):
        candidate = Path(cached)
        if candidate.is_file() and validate_png(candidate, size=ICON_TARGET_SIZE):
            return cached

    return ensure_moai_icon()


def touch_icon_cache() -> None:
    """Pré-carrega PNGs na memória antes do Rofi abrir."""
    ensure_transparent_icon()
    ensure_moai_icon()
    for png in ICON_CACHE_DIR.glob("*.png"):
        try:
            _pixbuf_module().Pixbuf.new_from_file(str(png))
        except Exception:
            pass


def warm_icons(show_hidden: bool) -> None:
    """Pré-gera PNGs 52px antes do Rofi abrir."""
    touch_icon_cache()
    state = load_state()
    apps = scan_apps()
    hidden_ids = set(state["hidden"])
    if show_hidden:
        pool = [a for a in apps.values() if a["id"] in hidden_ids]
    else:
        pool = [a for a in apps.values() if a["id"] not in hidden_ids]
    pool = sorted(pool, key=lambda a: sort_key(a, state))
    for app in pool:
        if has_desktop_icon(app):
            materialize_icon(app["icon"], app["id"], size=ICON_TARGET_SIZE)
    if pool and has_desktop_icon(pool[0]):
        materialize_icon(
            pool[0]["icon"],
            pool[0]["id"],
            size=ICON_TARGET_SIZE,
            force=True,
        )
    touch_icon_cache()


def is_corner_slot(slot: int) -> bool:
    """True nos 4 cantos de cada página do grid."""
    return (slot % SLOTS_PER_PAGE) in PAGE_CORNER_SLOTS


def emit_grid_pad(slot: int) -> None:
    """Célula transparente — absorve bug async do Rofi nos cantos do grid."""
    emit_row(
        f"\x01gridpad-{slot}",
        [
            f"icon\x1f{ensure_transparent_icon()}",
            "display\x1f",
            "meta\x1fgridpad",
            "info\x1f",
            "nonselectable\x1ftrue",
        ],
    )


def emit_apps_in_grid(pool: list[dict], state: dict) -> None:
    """Apps nos slots úteis; cantos de cada página ficam vazios."""
    app_i = 0
    slot = 0

    while app_i < len(pool):
        if is_corner_slot(slot):
            emit_grid_pad(slot)
        else:
            emit_app(pool[app_i], state)
            app_i += 1
        slot += 1

    if not pool or slot % SLOTS_PER_PAGE == 0:
        return

    page_end = (slot // SLOTS_PER_PAGE + 1) * SLOTS_PER_PAGE
    while slot < page_end:
        emit_grid_pad(slot)
        slot += 1


def emit_apps_flat(pool: list[dict], state: dict) -> None:
    """Lista contínua — usada durante a busca (sem cantos reservados)."""
    for app in pool:
        emit_app(app, state)


def emit_header(
    first: bool,
    show_hidden: bool,
    *,
    keep_filter: bool = True,
    keep_selection: bool = False,
) -> None:
    if first:
        sys.stdout.write("\0markup-rows\x1ftrue\n")
        sys.stdout.write("\0no-custom\x1ftrue\n")
        sys.stdout.write("\0use-hot-keys\x1ftrue\n")
    if keep_filter:
        sys.stdout.write("\0keep-filter\x1ftrue\n")
    if keep_selection:
        sys.stdout.write("\0keep-selection\x1ftrue\n")
    sys.stdout.write(f"\0data\x1f{encode_data(show_hidden)}\n")


def emit_row(key: str, options: list[str]) -> None:
    sys.stdout.write(f"{key}\0" + "\x1f".join(options) + "\n")


def emit_app(app: dict, state: dict) -> None:
    shown = display_name(app, state)
    blob = search_blob(app, state)
    icon_path = icon_field(app.get("icon", ""), app["id"])
    emit_row(
        blob,
        [
            f"icon\x1f{icon_path}",
            f"display\x1f{shown}",
            f"meta\x1f{blob}",
            f"info\x1f{app['id']}",
        ],
    )


def emit_list(
    state: dict,
    query: str,
    first: bool,
    show_hidden: bool,
    *,
    keep_filter: bool = True,
    keep_selection: bool = False,
) -> None:
    apps = scan_apps()
    hidden_ids = set(state["hidden"])

    if show_hidden:
        pool = [a for a in apps.values() if a["id"] in hidden_ids]
    else:
        pool = [a for a in apps.values() if a["id"] not in hidden_ids]

    pool = sorted(pool, key=lambda a: sort_key(a, state))
    if not first:
        warm_icons(show_hidden)
    else:
        ensure_moai_icon()

    emit_header(
        first,
        show_hidden,
        keep_filter=keep_filter,
        keep_selection=keep_selection,
    )
    if show_hidden:
        sys.stdout.write(
            "\0theme\x1fentry { placeholder: \"Buscar apps ocultos...\"; "
            "placeholder-color: #e8b86d; }\n"
        )
    if not pool:
        empty_label = (
            "Nenhum app oculto"
            if show_hidden
            else "Nenhum app encontrado"
        )
        emit_row(
            "empty",
            [
                f"display\x1f<span foreground='#bab0bd'>{empty_label}</span>",
                "nonselectable\x1ftrue",
            ],
        )
        return

    if query.strip():
        emit_apps_flat(pool, state)
    else:
        emit_apps_in_grid(pool, state)


def hide_app(state: dict, app_id: str) -> None:
    if app_id and app_id not in state["hidden"]:
        state["hidden"].append(app_id)


def unhide_app(state: dict, app_id: str) -> None:
    if app_id in state["hidden"]:
        state["hidden"].remove(app_id)


def sanitize_rename(name: str) -> str | None:
    """Remove caracteres inválidos e mensagens de erro do Rofi."""
    clean = name.strip().replace("\r", "").replace("\n", " ").strip()
    if not clean:
        return None
    if "do not launch rofi" in clean.lower():
        return None
    return clean


def queue_action(action: str, **extra: str) -> None:
    """Pede ao wrapper do launcher para tratar a ação (renomear, ocultos, etc.)."""
    payload = {"action": action, **extra}
    ACTION_FILE.write_text(
        json.dumps(payload, ensure_ascii=False),
        encoding="utf-8",
    )


def queue_rename(app_id: str, current: str) -> None:
    """Pede ao wrapper do launcher para abrir o diálogo de renomear."""
    queue_action("rename", app_id=app_id, current=current)


def apply_rename(state: dict, app_id: str, new_name: str) -> None:
    clean = sanitize_rename(new_name)
    if not clean:
        return
    default = scan_apps().get(app_id, {}).get("name", "")
    if clean == default:
        state["renames"].pop(app_id, None)
    else:
        state["renames"][app_id] = clean


def clean_exec(raw: str) -> str:
    cmd = re.sub(r"%[fFuUdDnNickvm]", "", raw)
    return re.sub(r"%%", "%", cmd).strip()


def launch_app(app_id: str) -> None:
    app = scan_apps().get(app_id)
    if not app or not app.get("exec"):
        return
    cmd = clean_exec(app["exec"])
    if not cmd:
        return
    subprocess.Popen(
        cmd,
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def handle_custom(
    state: dict,
    retv: int,
    app_id: str,
    query: str,
    show_hidden: bool,
) -> None:
    apps = scan_apps()
    if app_id and app_id not in apps:
        app_id = ""

    if retv == 11 and app_id:
        if show_hidden:
            unhide_app(state, app_id)
        else:
            hide_app(state, app_id)
        save_state(state)
        emit_list(state, query, first=False, show_hidden=show_hidden)
        return

    save_state(state)
    emit_list(state, query, first=False, show_hidden=show_hidden)


def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] == "warm-icons":
        hidden = os.environ.get("ROFI_LAUNCHER_MODE") == "hidden"
        warm_icons(hidden)
        return 0

    if len(sys.argv) >= 4 and sys.argv[1] == "apply-rename":
        state = load_state()
        apply_rename(state, sys.argv[2], sys.argv[3])
        save_state(state)
        return 0

    state = load_state()
    retv = int(os.environ.get("ROFI_RETV", "0"))
    query = os.environ.get("ROFI_INPUT", "")
    app_id = os.environ.get("ROFI_INFO", "")
    first = retv == 0 and not os.environ.get("ROFI_DATA")
    show_hidden = launcher_hidden_mode()

    if retv == 1:
        if app_id:
            launch_app(app_id)
        return 0

    if retv == 2:
        emit_list(state, query, first=False, show_hidden=show_hidden)
        return 0

    if 10 <= retv <= 28:
        apps = scan_apps()
        if retv == 10 and app_id and app_id in apps:
            queue_rename(app_id, display_name(apps[app_id], state))
            return 0
        handle_custom(state, retv, app_id, query, show_hidden)
        return 0

    emit_list(state, query, first, show_hidden)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
