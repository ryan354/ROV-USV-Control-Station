@echo off
REM ─── RovoControl Deploy Script ─────────────────────────────────────────────
REM Copies all required DLLs to build\Release after building.
REM Run: deploy.bat
REM ────────────────────────────────────────────────────────────────────────────

set RELEASE_DIR=%~dp0build\Release
set QT_DIR=C:\Qt\6.8.3\msvc2022_64
set GST_DIR=C:\gstreamer\1.0\msvc_x86_64\bin

echo [1/3] Deploying Qt DLLs...
"%QT_DIR%\bin\windeployqt6.exe" "%RELEASE_DIR%\RovoControl.exe" --qmldir "%~dp0qml"

echo [2/3] Copying GStreamer DLLs...
for %%f in (
    gobject-2.0-0.dll glib-2.0-0.dll gmodule-2.0-0.dll gio-2.0-0.dll
    gstreamer-1.0-0.dll gstbase-1.0-0.dll gstapp-1.0-0.dll gstvideo-1.0-0.dll
    gstpbutils-1.0-0.dll gsttag-1.0-0.dll gstaudio-1.0-0.dll gstgl-1.0-0.dll
    gstrtp-1.0-0.dll gstrtsp-1.0-0.dll gstsdp-1.0-0.dll gstnet-1.0-0.dll
    gstallocators-1.0-0.dll gstcontroller-1.0-0.dll
    orc-0.4-0.dll ffi-7.dll intl-8.dll z-1.dll
) do (
    if exist "%GST_DIR%\%%f" copy /Y "%GST_DIR%\%%f" "%RELEASE_DIR%\" >nul
)

echo [3/4] Copying SDL2...
if exist "%SDL2_DIR%\lib\x64\SDL2.dll" (
    copy /Y "%SDL2_DIR%\lib\x64\SDL2.dll" "%RELEASE_DIR%\" >nul
) else if exist "C:\SDL2\lib\x64\SDL2.dll" (
    copy /Y "C:\SDL2\lib\x64\SDL2.dll" "%RELEASE_DIR%\" >nul
)

echo [4/4] Copying MSVC Runtime...
copy /Y "%SystemRoot%\System32\msvcp140.dll" "%RELEASE_DIR%\" >nul
copy /Y "%SystemRoot%\System32\vcruntime140.dll" "%RELEASE_DIR%\" >nul
copy /Y "%SystemRoot%\System32\vcruntime140_1.dll" "%RELEASE_DIR%\" >nul

echo.
echo Deploy complete! Run: build\Release\RovoControl.exe
