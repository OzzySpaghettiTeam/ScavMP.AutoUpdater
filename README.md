## Windows
`C:\Windows\System32\curl.exe -sSfL -o %TEMP%\Updater.bat https://raw.githubusercontent.com/OzzySpaghettiTeam/ScavMP.AutoUpdater/main/Updater.bat && %TEMP%\Updater.bat %command%`
## Linux
`WINEDLLOVERRIDES="winhttp.dll=n,b" wget -qO- https://raw.githubusercontent.com/OzzySpaghettiTeam/ScavMP.AutoUpdater/main/Updater.sh | bash -s -- %command%`
