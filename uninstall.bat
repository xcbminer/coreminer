@echo off
setlocal

set "SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\mine.lnk"

:: Check if the shortcut exists
if not exist "%SHORTCUT_PATH%" (
    echo Shortcut "%SHORTCUT_PATH%" does not exist.
    goto end
)

:: Prompt user for confirmation
echo Do you want to delete the shortcut of mine.bat in the Startup folder? [yes/no] 
set /p USER_CONFIRM=
if /i not "%USER_CONFIRM%"=="yes" (
    echo Deletion cancelled by user.
    goto end
)

:: Delete shortcut
del "%SHORTCUT_PATH%"
if %ERRORLEVEL% neq 0 (
    echo Failed to delete the shortcut.
) else (
    echo Shortcut deleted successfully.
)

:end
pause
