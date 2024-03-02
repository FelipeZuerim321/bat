@echo off
setlocal EnableDelayedExpansion

:: Define script title and set initial variables
title "Knight's Script v3.0"
set "mode=0"

:: Set mode based on arguments
if "%~1"=="run" (
    echo.
) else if "%~1"=="run_radar" (
    set "mode=1"
    title "Knight's Script v3.0 Radar Version ;)"
    mode 95, 40
    echo.
) else (
    mode 85, 30
    echo   Please use run.bat.
    echo   Downloading run.bat...
    curl -s -L -o "run.bat" "https://github.com/valthrunner/Valthrun/releases/latest/download/run.bat"
    call run.bat
    exit
)

:: Display ASCII art header
echo.
call :displayHeader

:: Fetch the newest release using PowerShell
set "tagsUrl=https://api.github.com/repos/Valthrun/Valthrun/tags"
for /f "delims=" %%i in ('powershell -Command "$response = Invoke-WebRequest -Uri '%tagsUrl%' -UseBasicParsing; $tags = $response.Content | ConvertFrom-Json; if ($tags.Count -gt 0) { $tags[0].name } else { 'No tags found' }"') do set "newestTag=%%i"

:: Construct the download URLs based on the newest tag
set "baseDownloadUrl=https://github.com/Valthrun/Valthrun/releases/download/%newestTag%/"
set "baseRunnerDownloadUrl=https://github.com/valthrunner/Valthrun/releases/latest/download/"

:: Download
echo.
echo   Downloading necessary files...
call :downloadFileWithFallback "%baseDownloadUrl%controller.exe" "%baseRunnerDownloadUrl%controller.exe" "controller.exe"
call :downloadFile "%baseDownloadUrl%valthrun-driver.sys" "valthrun-driver.sys"
call :downloadFile "%baseRunnerDownloadUrl%kdmapper.exe" "kdmapper.exe"
:: Handle radar version
if "%mode%" == "1" (
    call :downloadFile "%baseDownloadUrl%radar-client.exe" "radar-client.exe"
)

:cleanup
if exist "latest.json" del "latest.json"

SET /A XCOUNT=0

:mapdriver
set "file=kdmapper_log.txt"

:: Exclude kdmapper.exe from Windows Defender
powershell.exe Add-MpPreference -ExclusionPath "$((Get-Location).Path + '\kdmapper.exe')" > nul 2>nul

:: Run knight-driver.sys with kdmapper
kdmapper.exe knight-driver.sys > %file%

:: Error handling based on kdmapper output
call :handleKdmapperErrors

:continue

:: Copy vulkan-1.dll if not exists
if not exist "vulkan-1.dll" call :copyVulkanDLL

powershell -Command ^
    "$trigger = New-ScheduledTaskTrigger -Once -At 00:00;" ^
    "$action = New-ScheduledTaskAction -Execute '%taskPath%' -WorkingDirectory '%startIn%';" ^
    "Register-ScheduledTask -TaskName '%taskName%' -Trigger $trigger -Action $action -User '%userName%' -Force" > nul 2>nul
schtasks /Run /TN "%taskName%" > nul 2>nul
schtasks /Delete /TN "%taskName%" /F > nul 2>nul

pause
exit

:displayHeader
:: Display ASCII art header
echo.

:: Output ASCII art here
echo   Replace this line with your ASCII art for Knight's Script
echo.

for /f "delims=: tokens=*" %%A in ('findstr /b ":::" "%~f0"') do @echo(%%A
exit /b

:downloadFile
curl -s -L -o "%~2" "%~1"

if %errorlevel% equ 0 (
    echo   Download complete: %~2
) else (
    echo   Failed to download: %~2
)
exit /b

:downloadFileWithFallback
curl -s -L -o "%~3" "%~1"
if %errorlevel% equ 0 (
    echo   Download complete: %~3
) else (
    echo   Failed to download: %~3 using primary URL. Trying fallback URL...
    call :downloadFile "%~2" "%~3"
)
exit /b

:handleKdmapperErrors
:: Error handling logic here
exit /b

:copyVulkanDLL
:: Logic to copy vulkan-1.dll
exit /b
