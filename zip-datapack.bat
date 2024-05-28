@echo off
setlocal enabledelayedexpansion

set "propertiesFile=versioning.properties"
set "base="
set "minecraft_version="
set "version="

rem #############################################################

for /f "tokens=1,2 delims==" %%A in (%propertiesFile%) do (
    set "key=%%A"
    set "value=%%B"
    if "!key!"=="base" set "base=!value!"
    if "!key!"=="minecraft-version" set "minecraft_version=!value!"
    if "!key!"=="version" set "version=!value!"
)

rem #############################################################

if "%base%"=="" (
    echo Error: base value is not set in %propertiesFile%
    exit /b 1
)
if "%minecraft_version%"=="" (
    echo Error: minecraft-version value is not set in %propertiesFile%
    exit /b 1
)
if "%version%"=="" (
    echo Error: version value is not set in %propertiesFile%
    exit /b 1
)

rem #############################################################

set "filename=%base%-%minecraft_version%-%version%.zip"
set "outputDir=releases"
if not exist "%outputDir%" mkdir "%outputDir%"
set "outputPath=%outputDir%\%filename%"

if exist "%outputPath%" del "%outputPath%"
cd "data-pack-files"
"C:\Program Files\WinRAR\WinRAR.exe" a -r "%~dp0%outputPath%" *
cd ..

if errorlevel 1 (
    echo Error: Failed to create the ZIP file
    exit /b 1
)

rem #############################################################

echo Successfully created %outputPath%
endlocal
pause
