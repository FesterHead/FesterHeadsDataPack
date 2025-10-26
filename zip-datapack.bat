@echo off
setlocal enabledelayedexpansion

rem Usage: zip-datapack.bat [--with-optional] [version]
rem
rem If 'version' is provided it will be used. If omitted, the script will try to derive
rem the latest tag from git (requires git in PATH). Pass --with-optional to include
rem optional/no-short-grass and optional/no-tall-grass contents merged into the datapack data/ folder.

set "propertiesFile=versioning.properties"
set "base="
set "minecraft_version="
set "version="

rem If user passed a version as the first argument, use it
if not "%~1"=="" (
    set "version=%~1"
)

rem #############################################################

for /f "tokens=1,2 delims==" %%A in (%propertiesFile%) do (
    set "key=%%A"
    set "value=%%B"
    if "!key!"=="base" set "base=!value!"
    if "!key!"=="minecraft-version" set "minecraft_version=!value!"
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

rem If no version provided, try to get the latest tag from git
if "%version%"=="" (
    for /f "delims=" %%T in ('git describe --tags --abbrev=0 2^>nul') do set "version=%%T"
    if "!version!"=="" (
        echo Warning: No version argument and git tag not found.
        echo Please provide the version as an argument, e.g. zip-datapack.bat 1.0.17
        exit /b 1
    )
    rem strip leading v or V
    rem If tag looks like 'vdraft-1.0.17', remove the 'vdraft-' prefix; otherwise remove leading 'v' if present
    if /i "!version:~0,7!"=="vdraft-" set "version=!version:~7!"
    if /i "!version:~0,1!"=="v" set "version=!version:~1!"
)

rem #############################################################

set "filename=%base%-%minecraft_version%-%version%.zip"
set "outputDir=releases"
if not exist "%outputDir%" mkdir "%outputDir%"
set "outputPath=%outputDir%\%filename%"

if exist "%outputPath%" del "%outputPath%"
rem Create staging area so we can include docs at the top-level of the zip without modifying source
set "staging=%cd%\pack_build"
if exist "%staging%" rmdir /s /q "%staging%"
mkdir "%staging%"
rem copy datapack contents
xcopy "data-pack-files\*" "%staging%\" /E /I /Y >nul
rem copy optional docs if present
if exist "changelog.md" copy /Y "changelog.md" "%staging%\" >nul
if exist "LICENSE" copy /Y "LICENSE" "%staging%\" >nul
if exist "README.md" copy /Y "README.md" "%staging%\" >nul

rem (No optional merging - optional content has been moved into the main datapack)

rem Prefer WinRAR, then 7-Zip, then try the built-in .NET Zip fallback via PowerShell.
if exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    pushd "%staging%"
    "%ProgramFiles%\WinRAR\WinRAR.exe" a -r "%~dp0%outputPath%" *
    popd
    goto :AFTER_COMPRESSION
)

if exist "%ProgramFiles%\7-Zip\7z.exe" (
    pushd "%staging%"
    "%ProgramFiles%\7-Zip\7z.exe" a -tzip "%~dp0%outputPath%" *
    popd
    goto :AFTER_COMPRESSION
)

rem Last resort: use .NET zip via PowerShell (avoids Import-Module execution policy issues).
powershell -NoProfile -Command "try { Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop; [System.IO.Compression.ZipFile]::CreateFromDirectory('%staging%','%~dp0%outputPath%'); exit 0 } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
    echo Error: No compressor available or all compressors failed. Install WinRAR or 7-Zip, or enable PowerShell .NET support.
    if exist "%staging%" rmdir /s /q "%staging%"
    exit /b 1
)

:AFTER_COMPRESSION

if exist "%staging%" rmdir /s /q "%staging%"

if errorlevel 1 (
    echo Error: Failed to create the ZIP file
    exit /b 1
)

echo Successfully created %outputPath%
endlocal
