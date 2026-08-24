@echo off

chcp 65001 >nul

setlocal EnableDelayedExpansion



echo ====================================

echo       QMI Web V1.0 一键安装程序

echo ====================================

echo.



set "INSTALL_DIR=%LOCALAPPDATA%\QMI-Web"

set "REPO=xuanxuan1125/qmi-web"



echo [1/5] 正在检查系统环境……

if not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (

    echo 错误：目前一键安装脚本仅支持 64 位 Windows 系统。

    exit /b 1

)



echo [2/5] 正在查询最新版本……

for /f "tokens=*" %%a in ('powershell -Command "(Invoke-RestMethod https://api.github.com/repos/%REPO%/releases/latest).tag_name"') do (

    set "LATEST_VERSION=%%a"

)



if "%LATEST_VERSION%"=="" (

    echo 错误：无法获取最新版本。请检查网络。

    exit /b 1

)

echo 发现最新版本: %LATEST_VERSION%



echo [3/5] 正在下载程序……

set "ZIP_NAME=qmi-web-%LATEST_VERSION%-windows-amd64.zip"

set "DOWNLOAD_URL=https://github.com/%REPO%/releases/download/%LATEST_VERSION%/%ZIP_NAME%"

set "TMP_ZIP=%TEMP%\%ZIP_NAME%"



powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TMP_ZIP%'"

if not exist "%TMP_ZIP%" (

    echo 错误：下载失败。

    exit /b 1

)



echo [4/5] 正在安装程序……

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

powershell -Command "Expand-Archive -Path '%TMP_ZIP%' -DestinationPath '%INSTALL_DIR%' -Force"



if exist "%INSTALL_DIR%\config.example.yaml" (

    if not exist "%INSTALL_DIR%\config.yaml" (

        copy "%INSTALL_DIR%\config.example.yaml" "%INSTALL_DIR%\config.yaml" >nul

    )

)



del "%TMP_ZIP%"



echo [5/5] 正在创建快捷方式……

set "SHORTCUT_PATH=%USERPROFILE%\Desktop\QMI Web.lnk"

powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%INSTALL_DIR%\qmi-web.exe'; $s.WorkingDirectory = '%INSTALL_DIR%'; $s.Save()"



echo.

echo ====================================

echo 安装完成！

echo 程序已安装至: %INSTALL_DIR%

echo 桌面快捷方式已创建，请双击运行并访问 http://127.0.0.1:7580

echo ====================================

exit /b 0

