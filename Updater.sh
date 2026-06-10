#!/usr/bin/env bash
set -euo pipefail

# ---------- НАСТРОЙКИ ----------
MOD_REPO="Krokosha666/cas-unk-krokosha-multiplayer-coop"
# ------------------------------

GAME_DIR="$(pwd)"
VER_BEP="$GAME_DIR/.version_bepinex"
VER_MOD="$GAME_DIR/.version_mod"

http_get() { wget -qO- "$1"; }
http_download() { wget -q -O "$2" "$1"; }

fetch_latest_release() {
    local repo="$1"; local filter="${2:-}"
    local api="https://api.github.com/repos/${repo}/releases/latest"
    local json; json=$(http_get "$api")

    if command -v jq >/dev/null 2>&1; then
        TAG=$(echo "$json" | jq -r '.tag_name')
        if [ -n "$filter" ]; then
            URL=$(echo "$json" | jq -r --arg f "$filter" '.assets[] | select(.name|test($f;"i")) | .browser_download_url' | head -1)
        else
            URL=$(echo "$json" | jq -r '.assets[0].browser_download_url')
        fi
    else
        TAG=$(echo "$json" | grep -oP '"tag_name":\s*"\K[^"]+')
        if [ -n "$filter" ]; then
            URL=$(echo "$json" | grep -i "$filter" -A5 | grep -oP '"browser_download_url":\s*"\K[^"]+' | head -1)
            [ -z "$URL" ] && URL=$(echo "$json" | grep -oP '"browser_download_url":\s*"\K[^"]*'"$filter"'.*\.zip' | head -1)
        else
            URL=$(echo "$json" | grep -oP '"browser_download_url":\s*"\K[^"]+' | head -1)
        fi
    fi

    if [ -z "$URL" ]; then
        echo "ОШИБКА: не найден ассет по фильтру '$filter' в $repo" >&2
        exit 1
    fi
}

# 1. BepInEx
echo "==> Проверка BepInEx..."
fetch_latest_release "BepInEx/BepInEx" "BepInEx_win_x64"   # твой рабочий фильтр
STORED_TAG_BEP=$(cat "$VER_BEP" 2>/dev/null || true)
if [ "$TAG" != "$STORED_TAG_BEP" ] || [ ! -d "$GAME_DIR/BepInEx" ]; then
    echo "Обновляю BepInEx до $TAG..."
    http_download "$URL" "$GAME_DIR/bepinex.zip"
    unzip -o "$GAME_DIR/bepinex.zip" -d "$GAME_DIR"
    rm "$GAME_DIR/bepinex.zip"
    echo "$TAG" > "$VER_BEP"
else
    echo "BepInEx актуален ($TAG)"
fi

# 2. Мод
echo "==> Проверка мода ($MOD_REPO)..."
fetch_latest_release "$MOD_REPO" ""   # берём первый ассет (zip)
STORED_TAG_MOD=$(cat "$VER_MOD" 2>/dev/null || true)
if [ "$TAG" != "$STORED_TAG_MOD" ] || [ ! -d "$GAME_DIR/BepInEx/plugins" ]; then
    echo "Обновляю мод до $TAG..."
    http_download "$URL" "$GAME_DIR/mod.zip"
    TMPD=$(mktemp -d -p "$GAME_DIR")
    unzip -o "$GAME_DIR/mod.zip" -d "$TMPD"
    if [ -d "$TMPD/mod" ]; then
        cp -r "$TMPD/mod/"* "$GAME_DIR/"
    else
        cp -r "$TMPD/"* "$GAME_DIR/"
    fi
    rm -rf "$TMPD" "$GAME_DIR/mod.zip"
    echo "$TAG" > "$VER_MOD"
else
    echo "Мод актуален ($TAG)"
fi

export WINEDLLOVERRIDES="winhttp=n,b"
echo "==> Запуск игры..."
exec "$@"