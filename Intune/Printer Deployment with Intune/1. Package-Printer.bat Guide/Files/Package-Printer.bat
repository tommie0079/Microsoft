@echo off
setlocal EnableExtensions

title Microsoft Intune Printer Packaging Helper
color 1F

set "ROOT=%~dp0"
set "TOOL_PATH=%ROOT%IntuneWinAppUtil.exe"
set "DOWNLOAD_URL=https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/IntuneWinAppUtil.exe"
set "PACKAGE_SOURCE=%ROOT%PackageSource"
set "OUTPUT_DIR=%ROOT%Output"

:menu
cls
call :print_header
echo.
echo 1. Update driver config
echo 2. Set printer IP
echo 3. Set printer name
echo 4. Install IntuneWinAppUtil.exe
echo 5. Create .intunewin
echo 6. Open Output folder
echo 0. Exit
echo.
echo credits: Tommie ^& Vegard
echo.
set /p "choice=Choose an option: "

if "%choice%"=="1" goto update_driver_config
if "%choice%"=="2" goto set_printer_ip
if "%choice%"=="3" goto set_printer_name
if "%choice%"=="4" goto install_tool
if "%choice%"=="5" goto create_intunewin
if "%choice%"=="6" goto open_output
if "%choice%"=="0" goto end

echo.
echo Invalid choice.
pause
goto menu

:update_driver_config
echo.
echo Running Update-DriverConfig.ps1...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%Update-DriverConfig.ps1"
echo.
pause
goto menu

:set_printer_ip
echo.
set /p "printer_ip=Enter printer IP address: "
if "%printer_ip%"=="" (
    echo No IP address entered.
    echo.
    pause
    goto menu
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%Set-PrinterIP.ps1" -PrinterIP "%printer_ip%"
if errorlevel 1 (
    echo.
    echo Failed to update PrinterIP.
    echo.
    pause
    goto menu
)

echo.
echo PrinterIP updated to %printer_ip%
echo.
pause
goto menu

:set_printer_name
echo.
set /p "printer_name=Enter printer name: "
if "%printer_name%"=="" (
    echo No printer name entered.
    echo.
    pause
    goto menu
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%Set-PrinterName.ps1" -PrinterName "%printer_name%"
if errorlevel 1 (
    echo.
    echo Failed to update PrinterName.
    echo.
    pause
    goto menu
)

echo.
echo PrinterName updated to %printer_name%
echo.
pause
goto menu

:install_tool
echo.
if exist "%TOOL_PATH%" (
    echo IntuneWinAppUtil.exe already exists:
    echo %TOOL_PATH%
    echo.
    pause
    goto menu
)

echo Downloading IntuneWinAppUtil.exe from Microsoft...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TOOL_PATH%'"
if errorlevel 1 (
    echo.
    echo Failed to download IntuneWinAppUtil.exe.
    echo Download it manually from:
    echo https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
    echo.
    pause
    goto menu
)

echo.
echo IntuneWinAppUtil.exe saved to:
echo %TOOL_PATH%
echo.
pause
goto menu

:create_intunewin
echo.
if not exist "%TOOL_PATH%" (
    echo IntuneWinAppUtil.exe was not found.
    echo Run option 4 first.
    echo.
    pause
    goto menu
)

if not exist "%ROOT%install.ps1" (
    echo install.ps1 was not found in the project root.
    echo.
    pause
    goto menu
)

if not exist "%ROOT%uninstall.ps1" (
    echo uninstall.ps1 was not found in the project root.
    echo.
    pause
    goto menu
)

if not exist "%ROOT%detection.ps1" (
    echo detection.ps1 was not found in the project root.
    echo.
    pause
    goto menu
)

if not exist "%ROOT%UPD" (
    echo UPD folder was not found in the project root.
    echo.
    pause
    goto menu
)

echo Preparing PackageSource...
if exist "%PACKAGE_SOURCE%" rmdir /s /q "%PACKAGE_SOURCE%"
mkdir "%PACKAGE_SOURCE%"
mkdir "%PACKAGE_SOURCE%\UPD"

copy /y "%ROOT%install.ps1" "%PACKAGE_SOURCE%\install.ps1" >nul
copy /y "%ROOT%uninstall.ps1" "%PACKAGE_SOURCE%\uninstall.ps1" >nul
copy /y "%ROOT%detection.ps1" "%PACKAGE_SOURCE%\detection.ps1" >nul
xcopy "%ROOT%UPD\*" "%PACKAGE_SOURCE%\UPD\" /e /i /y >nul

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo Creating .intunewin package...
"%TOOL_PATH%" -c "%PACKAGE_SOURCE%" -s "install.ps1" -o "%OUTPUT_DIR%"
if errorlevel 1 (
    echo.
    echo Failed to create .intunewin.
    echo.
    pause
    goto menu
)

echo.
echo Package created in:
echo %OUTPUT_DIR%
echo.
pause
goto menu

:open_output
echo.
if not exist "%OUTPUT_DIR%" (
    echo Output folder does not exist yet. Creating it now...
    mkdir "%OUTPUT_DIR%"
)

echo Opening Output folder...
start "" explorer.exe "%OUTPUT_DIR%"
echo.
pause
goto menu

:print_header
echo ============================================================
echo                 MICROSOFT INTUNE PACKAGING
echo                   Printer Deployment Helper
echo ============================================================
exit /b

:end
endlocal
