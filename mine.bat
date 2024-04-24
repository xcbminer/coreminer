@echo off
setlocal enabledelayedexpansion

goto :main_loop

:units_available
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value') do (
    set /a punits=%%i
)
goto :eof

:add_pool
set "opt1=CTR EU"
set "opt2=CTR EU Backup"
set "opt3=CTR AS"
set "opt4=CTR AS Backup"
set "opt5=CTR US"
set "opt6=CTR US Backup"
set "opt7=Other"
set "opt8=Exit"
if "%1" gtr "1" (
    echo * Please, select the additional mining pool.
) else (
    echo * Please, select the mining pool.
)
echo [1] %opt1%
echo [2] %opt2%
echo [3] %opt3%
echo [4] %opt4%
echo [5] %opt5%
echo [6] %opt6%
echo [7] %opt7%
echo [8] %opt8%
set /p choice=* Pool: 
if "%choice%"=="1" (
    set "server%1=eu.catchthatrabbit.com"
    set "port%1=8008"
) else if "%choice%"=="2" (
    set "server%1=eu1.catchthatrabbit.com"
    set "port%1=8008"
) else if "%choice%"=="3" (
    set "server%1=as.catchthatrabbit.com"
    set "port%1=8008"
) else if "%choice%"=="4" (
    set "server%1=as1.catchthatrabbit.com"
    set "port%1=8008"
) else if "%choice%"=="5" (
    set "server%1=us.catchthatrabbit.com"
    set "port%1=8008"
) else if "%choice%"=="6" (
    set "server%1=us1.catchthatrabbit.com"
    set "port%1=8008"
) else if "%choice%"=="7" (
    set /p "server%1=* Enter server address: "
    set /p "port%1=* Enter server port: "
) else if "%choice%"=="8" (
    exit /b 0
) else (
    echo * Invalid option.
    goto :add_pool
)

if not defined params (
    set /p "wallet=* Enter wallet address: "
    set /p "worker=* Enter worker name: "
    call :units_available
    echo * Available processing units: !punits!
    set /p "threads=* How many units to use? [Enter for all]"
    set params=true
)
goto :eof

:start_mining
set "POOLS=-P!STRATUM!"
set "THREAD="
if not "%~1"=="" (
    set "THREAD=-t %~1"
)
if not exist "coreminer.exe" (
    echo * coreminer not found!
    exit /b 2
)
echo * coreminer --noeval --hard-aes !POOLS! !THREAD!
coreminer --noeval --hard-aes !POOLS! !THREAD!
goto :eof

:compose_stratum
if "%~4"=="" (
    set "stratum_result=stratum1+tcp://%~1@%~2:%~3"
) else (
    set "stratum_result=stratum1+tcp://%~1.%~4@%~2:%~3"
)
goto :eof

:export_config
(
    echo wallet=!wallet!
    echo worker=!worker!
    echo threads=!threads!
    for /L %%i in (1,1,!LOOP!) do (
        if defined server%%i (
            echo server%%i=!server%%i!
            echo port%%i=!port%%i!
        )
    )
) > %1
goto :eof


:import_config
for /f "tokens=1,* delims==" %%i in (%1) do (
    set %%i=%%j
)
goto :eof

@echo off
setlocal

:startup_shortcut
set "BAT_PATH=%~dp0mine.bat"
set "SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\mine.lnk"

:: Check if the shortcut already exists
if exist "%SHORTCUT_PATH%" (
    echo Shortcut already exists in Startup folder.
    goto :eof
)

:: Create shortcuts by using PowerShell
echo Creating shortcut to mine.bat in Startup folder...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%BAT_PATH%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.Save()"

if %ERRORLEVEL% equ 0 (
    echo Shortcut created successfully.
) else (
    echo Failed to create shortcut.
)

goto :eof

:main_loop

set CONFIG=pool.ini
if exist "%CONFIG%" (
    echo * Mine settings file '%CONFIG%' exists.
    echo * Importing settings.
    call :import_config %CONFIG%
    set "ICANWALLET=!wallet: =!"
    set "STRATUM="
    echo * Configuring stratum server.
    set /a "POOL_COUNT=0"
    :pool_count_loop
    set /a "POOL_COUNT+=1"
    call set "SERVER_CHECK=%%server!POOL_COUNT!%%"
    if not "!SERVER_CHECK!"=="" (
        goto :pool_count_loop
    )
    set /a "POOL_COUNT-=1"
    for /L %%i in (1,1,!POOL_COUNT!) do (
        call :compose_stratum "!ICANWALLET!" "!server%%i!" "!port%%i!" "!worker!"
        set "STRATUM=!STRATUM! !stratum_result!"
    )
    echo * Starting mining command.
    call :start_mining "%threads%"
    timeout /t 60
    goto main_loop
) else (
    echo * Mine settings file '%CONFIG%' doesn't exist.
    echo * Proceeding with setup.
    set /a LOOP=1
    call :add_pool !LOOP!
    set "ICANWALLET=!wallet: =!"

    echo.
    :additional_pool
    set /p back=* Do you wish to add additional pool? [yes/no] 
    if /I "!back!"=="yes" (
        set /a LOOP+=1
        call :add_pool !LOOP!
        goto additional_pool
    ) else if /I "!back!"=="no" (
        goto save_settings
    ) else (
        echo * Invalid input. [yes,no]
        goto additional_pool
    )

    :save_settings
    echo.
    echo * Saving the settings.
    call :export_config "%CONFIG%"

    echo.
    :autostart
    set /p autostart=* Add to the Startup folder? [yes/no] 
    if /I "!autostart!"=="yes" (
        call :startup_shortcut
        goto start_mining_prompt
    ) else if /I "!autostart!"=="no" (
        goto start_mining_prompt
    ) else (
        echo * Invalid input. [yes,no]
        goto autostart
    )

    :start_mining_prompt
    echo.
    set /p mine=* Start mining now? [yes/no] 
    if /I "!mine!"=="yes" (
        set "STRATUM="
        for /L %%i in (1,1,!LOOP!) do (
            call :compose_stratum "!ICANWALLET!" "!server%%i!" "!port%%i!" "!worker!"
            set "STRATUM=!STRATUM! !stratum_result!"
        )
        call :start_mining "%threads%"
        timeout /t 60
        goto main_loop
    ) else if /I "!mine!"=="no" (
        exit /b 0
    ) else (
        echo * Invalid input. [yes,no]
        goto start_mining_prompt
    )
)

endlocal
