#!/usr/bin/env bash
set -euo pipefail

# ---------- НАСТРОЙКИ (поменяй только здесь) ----------
MOD_REPO="Krokosha666/cas-unk-krokosha-multiplayer-coop"   # твой репозиторий с модом
# --------------------------------------------------------

GAME_DIR="$(pwd)"
VER_BEP="$GAME_DIR/.version_bepinex"
VER_MOD="$GAME_DIR/.version_mod"

# Функция получения последнего релиза с GitHub
fetch_latest_release() {
    local repo="$1"; local filter="${2:-}"
    local api="https://api.github.com/repos/${repo}/releases/latest"
    local json; json=$(curl -sSf "$api")

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
            URL=$(echo "$json" | grep -oP '"browser_download_url":\s*"\K[^"]*'"$filter"'.*\.zip' | head -1)
        else
            URL=$(echo "$json" | grep -oP '"browser_download_url":\s*"\K[^"]+' | head -1)
        fi
    fi

    # Проверка, что URL не пуст
    if [ -z "$URL" ]; then
        echo "ОШИБКА: не удалось найти архив по фильтру '$filter' в релизе $TAG" >&2
        exit 1
    fi
}


# 1. BepInEx (Windows x64)
echo "==> Проверка BepInEx..."
fetch_latest_release "BepInEx/BepInEx" "BepInEx_win_x64.*\\.zip"
STORED_TAG_BEP=$(cat "$VER_BEP" 2>/dev/null || true)
if [ "$TAG" != "$STORED_TAG_BEP" ]; then
    echo "Обновляю BepInEx до $TAG..."
    curl -sSfL -o "$GAME_DIR/bepinex.zip" "$URL"
    unzip -o "$GAME_DIR/bepinex.zip" -d "$GAME_DIR"
    rm "$GAME_DIR/bepinex.zip"
    echo "$TAG" > "$VER_BEP"
else
    echo "BepInEx актуален ($TAG)"
fi

# 2. Твой мод
echo "==> Проверка мода ($MOD_REPO)..."
fetch_latest_release "$MOD_REPO" ""
STORED_TAG_MOD=$(cat "$VER_MOD" 2>/dev/null || true)
if [ "$TAG" != "$STORED_TAG_MOD" ]; then
    echo "Обновляю мод до $TAG..."
    curl -sSfL -o "$GAME_DIR/mod.zip" "$URL"
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

# 3. Запуск игры
export WINEDLLOVERRIDES="winhttp=n,b"
echo "==> Запуск игры..."
exec "$@"