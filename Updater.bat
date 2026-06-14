@echo on
setlocal enabledelayedexpansion

:: ---------- НАСТРОЙКИ ----------
set MOD_REPO=Krokosha666/cas-unk-krokosha-multiplayer-coop
:: -------------------------------

cd /d "%~dp0"
set VER_BEP=.version_bepinex
set VER_MOD=.version_mod

:: 1. BepInEx (Windows x64)
echo ==> Проверка BepInEx...
for /f "delims=" %%U in ('powershell -Command "(Invoke-RestMethod https://api.github.com/repos/BepInEx/BepInEx/releases/latest).assets | Where-Object { $_.name -like '*BepInEx_win_x64*' -and $_.name -like '*.zip' } | Select-Object -ExpandProperty browser_download_url"') do set "BEP_URL=%%U"
for /f "delims=" %%T in ('powershell -Command "(Invoke-RestMethod https://api.github.com/repos/BepInEx/BepInEx/releases/latest).tag_name"') do set "BEP_TAG=%%T"

if exist "%VER_BEP%" set /p STORED_BEP=<"%VER_BEP%"
if not "%BEP_TAG%"=="%STORED_BEP%" (
    echo Обновляю BepInEx до %BEP_TAG%...
    powershell -Command "Invoke-WebRequest -Uri '%BEP_URL%' -OutFile 'bepinex.zip'"
    powershell -Command "Expand-Archive -Path 'bepinex.zip' -DestinationPath '.' -Force"
    del bepinex.zip
    echo %BEP_TAG%>"%VER_BEP%"
) else (
    echo BepInEx актуален (%BEP_TAG%)
)

:: 2. Твой мод
echo ==> Проверка мода...
for /f "delims=" %%U in ('powershell -Command "(Invoke-RestMethod https://api.github.com/repos/%MOD_REPO%/releases/latest).assets[0].browser_download_url"') do set "MOD_URL=%%U"
for /f "delims=" %%T in ('powershell -Command "(Invoke-RestMethod https://api.github.com/repos/%MOD_REPO%/releases/latest).tag_name"') do set "MOD_TAG=%%T"

if exist "%VER_MOD%" set /p STORED_MOD=<"%VER_MOD%"
if not "%MOD_TAG%"=="%STORED_MOD%" (
    echo Обновляю мод до %MOD_TAG%...
    powershell -Command "Invoke-WebRequest -Uri '%MOD_URL%' -OutFile 'mod.zip'"
    powershell -Command "$tmp = New-Item -ItemType Directory -Path (Join-Path $pwd 'tmp_mod'); Expand-Archive -Path 'mod.zip' -DestinationPath $tmp; if (Test-Path (Join-Path $tmp 'mod')) { Copy-Item -Path (Join-Path $tmp 'mod\*') -Destination '.' -Recurse -Force } else { Copy-Item -Path (Join-Path $tmp '*') -Destination '.' -Recurse -Force }; Remove-Item -Recurse -Force $tmp, 'mod.zip'"
    echo %MOD_TAG%>"%VER_MOD%"
) else (
    echo Мод актуален (%MOD_TAG%)
)

:: 3. Запуск игры
echo ==> Запуск игры...
start "" %*
