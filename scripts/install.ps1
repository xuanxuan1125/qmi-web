$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "      QMI Web V1.0 一键安装程序      " -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$INSTALL_DIR = "$env:LOCALAPPDATA\QMI-Web"
$REPO = "xuanxuan1125/qmi-web"

Write-Host "[1/5] 正在检查系统环境……" -ForegroundColor Yellow
if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    Write-Host "错误：目前仅支持 64 位 Windows 系统。" -ForegroundColor Red
    exit 1
}

Write-Host "[2/5] 正在查询最新版本……" -ForegroundColor Yellow
try {
    $latest = Invoke-RestMethod "https://api.github.com/repos/$REPO/releases/latest"
    $version = $latest.tag_name
} catch {
    Write-Host "错误：无法获取最新版本。请检查网络连接。" -ForegroundColor Red
    exit 1
}
Write-Host "发现最新版本: $version" -ForegroundColor Green

Write-Host "[3/5] 正在下载程序……" -ForegroundColor Yellow
$zipName = "qmi-web-$version-windows-amd64.zip"
$downloadUrl = "https://github.com/$REPO/releases/download/$version/$zipName"
$tmpZip = "$env:TEMP\$zipName"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tmpZip
} catch {
    Write-Host "错误：下载失败 $_" -ForegroundColor Red
    exit 1
}

Write-Host "[4/5] 正在安装程序……" -ForegroundColor Yellow
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
}
Expand-Archive -Path $tmpZip -DestinationPath $INSTALL_DIR -Force

if (-not (Test-Path "$INSTALL_DIR\config.yaml")) {
    Copy-Item "$INSTALL_DIR\config.example.yaml" "$INSTALL_DIR\config.yaml"
}

Remove-Item $tmpZip -Force

Write-Host "[5/5] 正在创建快捷方式……" -ForegroundColor Yellow
$shortcutPath = "$env:USERPROFILE\Desktop\QMI Web.lnk"
$wshell = New-Object -ComObject WScript.Shell
$shortcut = $wshell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "$INSTALL_DIR\qmi-web.exe"
$shortcut.WorkingDirectory = $INSTALL_DIR
$shortcut.Save()

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "安装完成！" -ForegroundColor Green
Write-Host "程序已安装至: $INSTALL_DIR"
Write-Host "桌面快捷方式已创建，请双击运行并访问 http://127.0.0.1:7580"
Write-Host "====================================" -ForegroundColor Cyan
