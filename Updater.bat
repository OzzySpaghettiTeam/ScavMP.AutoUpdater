@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ---------- НАСТРОЙКИ ----------
set "MOD_REPO=Krokosha666/cas-unk-krokosha-multiplayer-coop"
:: ------------------------------

cd /d "%~dp0"
set "VER_BEP=.version_bepinex"
set "VER_MOD=.version_mod"

:: ------------------------------------------------------------
:: Проверка интернета
echo ==^> Проверка соединения с GitHub...
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Нет доступа к github.com. Проверьте интернет.
    pause
    exit /b 1
)
echo   Соединение есть.

:: ------------------------------------------------------------
:: 1. BepInEx
:: ------------------------------------------------------------
echo ==^> Проверка BepInEx...

    :: ---------- блок получения последнего релиза BepInEx ----------
    set "REPO_BEP=BepInEx/BepInEx"
    set "FILTER_BEP=BepInEx_win_x64"
    set "API_URL_BEP=https://api.github.com/repos/!REPO_BEP!/releases/latest"

    echo   Запрашиваю данные из !REPO_BEP!...

    set "tmp_json_bep=%temp%\gh_%random%.json"
    set "tmp_tag_bep=%temp%\gh_tag_%random%.txt"

    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!API_URL_BEP!' -Headers @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'} -OutFile '!tmp_json_bep!' -UseBasicParsing" >nul 2>&1

    if errorlevel 1 (
        echo [ОШИБКА] Не удалось получить JSON от GitHub
        echo   URL: !API_URL_BEP!
        del "!tmp_json_bep!" 2>nul
        pause
        exit /b 1
    )

    for %%A in ("!tmp_json_bep!") do if %%~zA equ 0 (
        echo [ОШИБКА] Получен пустой JSON
        del "!tmp_json_bep!" 2>nul
        pause
        exit /b 1
    )

    powershell -NoProfile -Command "$json = Get-Content '!tmp_json_bep!' -Raw | ConvertFrom-Json; $tag = $json.tag_name; if ('!FILTER_BEP!' -ne '') { $asset = $json.assets | Where-Object { $_.name -like '*!FILTER_BEP!*' -and $_.name -like '*.zip' } | Select-Object -First 1; if (-not $asset) { Write-Error 'Asset not found'; exit 1 }; $url = $asset.browser_download_url } else { $url = $json.assets[0].browser_download_url }; Write-Output $tag; Write-Output $url" > "!tmp_tag_bep!" 2>nul

    if errorlevel 1 (
        echo [ОШИБКА] Ошибка парсинга JSON
        del "!tmp_json_bep!" "!tmp_tag_bep!" 2>nul
        pause
        exit /b 1
    )

    set "REPO_TAG_BEP="
    set "REPO_URL_BEP="
    set /p REPO_TAG_BEP=<"!tmp_tag_bep!"
    for /f "skip=1 delims=" %%L in ('type "!tmp_tag_bep!"') do (
        set "REPO_URL_BEP=%%L"
        goto :done_parse_bep
    )
    :done_parse_bep

    del "!tmp_json_bep!" "!tmp_tag_bep!" 2>nul

    if "!REPO_URL_BEP!"=="" (
        echo [ОШИБКА] Не найден ассет для фильтра '!FILTER_BEP!' в !REPO_BEP!
        pause
        exit /b 1
    )
    if "!REPO_TAG_BEP!"=="" (
        echo [ОШИБКА] Не найден тег в !REPO_BEP!
        pause
        exit /b 1
    )

    echo   Найдена версия: !REPO_TAG_BEP!

    :: присваиваем глобальным переменным для дальнейшего использования
    set "REPO_TAG=!REPO_TAG_BEP!"
    set "REPO_URL=!REPO_URL_BEP!"

    :: ---------- проверка необходимости обновления ----------
    set "STORED_TAG="
    if exist "%VER_BEP%" set /p STORED_TAG=<"%VER_BEP%"
    if not "!REPO_TAG!"=="!STORED_TAG!" (
        echo Обновляю BepInEx до !REPO_TAG!...
        echo   Загружаю !REPO_URL! ...
        powershell -Command "Invoke-WebRequest -Uri '!REPO_URL!' -OutFile 'bepinex.zip' -UseBasicParsing"
        if not exist "bepinex.zip" (
            echo Ошибка загрузки BepInEx
            pause
            exit /b 1
        )
        echo   Распаковываю...
        powershell -Command "Expand-Archive -Path 'bepinex.zip' -DestinationPath '.' -Force"
        del "bepinex.zip"
        echo !REPO_TAG! > "%VER_BEP%"
        echo BepInEx обновлён до !REPO_TAG!
    ) else (
        echo BepInEx актуален ^(!REPO_TAG!^)
    )

:: ------------------------------------------------------------
:: 2. Мод
:: ------------------------------------------------------------
echo ==^> Проверка мода ^(%MOD_REPO%^)...

    :: ---------- блок получения последнего релиза мода ----------
    set "REPO_MOD=%MOD_REPO%"
    set "FILTER_MOD="
    set "API_URL_MOD=https://api.github.com/repos/!REPO_MOD!/releases/latest"

    echo   Запрашиваю данные из !REPO_MOD!...

    set "tmp_json_mod=%temp%\gh_%random%.json"
    set "tmp_tag_mod=%temp%\gh_tag_%random%.txt"

    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!API_URL_MOD!' -Headers @{'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'} -OutFile '!tmp_json_mod!' -UseBasicParsing" >nul 2>&1

    if errorlevel 1 (
        echo [ОШИБКА] Не удалось получить JSON от GitHub
        echo   URL: !API_URL_MOD!
        del "!tmp_json_mod!" 2>nul
        pause
        exit /b 1
    )

    for %%A in ("!tmp_json_mod!") do if %%~zA equ 0 (
        echo [ОШИБКА] Получен пустой JSON
        del "!tmp_json_mod!" 2>nul
        pause
        exit /b 1
    )

    powershell -NoProfile -Command "$json = Get-Content '!tmp_json_mod!' -Raw | ConvertFrom-Json; $tag = $json.tag_name; if ('!FILTER_MOD!' -ne '') { $asset = $json.assets | Where-Object { $_.name -like '*!FILTER_MOD!*' -and $_.name -like '*.zip' } | Select-Object -First 1; if (-not $asset) { Write-Error 'Asset not found'; exit 1 }; $url = $asset.browser_download_url } else { $url = $json.assets[0].browser_download_url }; Write-Output $tag; Write-Output $url" > "!tmp_tag_mod!" 2>nul

    if errorlevel 1 (
        echo [ОШИБКА] Ошибка парсинга JSON
        del "!tmp_json_mod!" "!tmp_tag_mod!" 2>nul
        pause
        exit /b 1
    )

    set "REPO_TAG_MOD="
    set "REPO_URL_MOD="
    set /p REPO_TAG_MOD=<"!tmp_tag_mod!"
    for /f "skip=1 delims=" %%L in ('type "!tmp_tag_mod!"') do (
        set "REPO_URL_MOD=%%L"
        goto :done_parse_mod
    )
    :done_parse_mod

    del "!tmp_json_mod!" "!tmp_tag_mod!" 2>nul

    if "!REPO_URL_MOD!"=="" (
        echo [ОШИБКА] Не найден ассет для фильтра '' в !REPO_MOD!
        pause
        exit /b 1
    )
    if "!REPO_TAG_MOD!"=="" (
        echo [ОШИБКА] Не найден тег в !REPO_MOD!
        pause
        exit /b 1
    )

    echo   Найдена версия: !REPO_TAG_MOD!

    :: присваиваем глобальным переменным
    set "REPO_TAG=!REPO_TAG_MOD!"
    set "REPO_URL=!REPO_URL_MOD!"

    :: ---------- проверка необходимости обновления ----------
    set "STORED_TAG="
    if exist "%VER_MOD%" set /p STORED_TAG=<"%VER_MOD%"
    if not "!REPO_TAG!"=="!STORED_TAG!" (
        echo Обновляю мод до !REPO_TAG!...
        echo   Загружаю !REPO_URL! ...
        powershell -Command "Invoke-WebRequest -Uri '!REPO_URL!' -OutFile 'mod.zip' -UseBasicParsing"
        if not exist "mod.zip" (
            echo Ошибка загрузки мода
            pause
            exit /b 1
        )
        echo   Распаковываю...
        powershell -Command "$tmp = New-Item -ItemType Directory -Path (Join-Path $pwd 'tmp_mod'); Expand-Archive -Path 'mod.zip' -DestinationPath $tmp; if (Test-Path (Join-Path $tmp 'mod')) { Copy-Item -Path \"$((Join-Path $tmp 'mod')\"*\")' -Destination '.' -Recurse -Force } else { Copy-Item -Path \"$tmp\"*\")' -Destination '.' -Recurse -Force }; Remove-Item -Recurse -Force \"$tmp\", 'mod.zip'"
        echo !REPO_TAG! > "%VER_MOD%"
        echo Мод обновлён до !REPO_TAG!
    ) else (
        echo Мод актуален ^(!REPO_TAG!^)
    )

:: ------------------------------------------------------------
:: 3. Запуск игры
:: ------------------------------------------------------------
if "%~1"=="" (
    echo Не указан исполняемый файл игры.
    echo Использование: %~nx0 [путь_к_игре.exe] [аргументы]
    pause
    exit /b 0
)
echo ==^> Запуск игры: %*
start "" %*
