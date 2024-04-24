@echo off
setlocal

set "BAT_PATH=%~dp0mine.bat"
set "SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\mine.lnk"

:: Check if the shortcut exists
if exist "%SHORTCUT_PATH%" (
    echo Shortcut already exists in Startup folder.
    goto end
)

:: Prompt user for confirmation
echo Do you want to create a shortcut of mine.bat in the Startup folder? [yes/no] 
set /p USER_CONFIRM=
if /i not "%USER_CONFIRM%"=="yes" (
    echo Shortcut creation cancelled by user.
    goto end
)

:: Create shortcuts by using PowerShell
echo Creating shortcut of mine.bat in Startup folder...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%BAT_PATH%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.Save()"

:: Check whether the shortcut is created successfully
if %ERRORLEVEL% equ 0 (
    echo Shortcut created successfully.
) else (
    echo Failed to create shortcut.
)

:end
pause
