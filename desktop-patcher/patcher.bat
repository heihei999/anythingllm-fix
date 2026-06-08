@echo off
chcp 65001 >nul 2>nul
title AnythingLLM Desktop Patcher

echo.
echo ========================================
echo   AnythingLLM Desktop Patcher
echo   一键修复补丁 v1.1
echo ========================================
echo.

REM Check Node.js
echo [1/2] 检查环境...
where npx >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo   [错误] 未检测到 Node.js
    echo.
    echo   请先安装 Node.js：
    echo   https://nodejs.org/
    echo.
    echo   下载 LTS 版本，安装后重启电脑，再运行本补丁。
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('npx --version 2^>nul') do set NPM_VER=%%i
echo   Node.js 已就绪 (npx %NPM_VER%)

REM Check AnythingLLM
set "ASAR_PATH=%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar"
if not exist "%ASAR_PATH%" (
    echo.
    echo   [错误] 未找到 AnythingLLM
    echo.
    echo   请确认：
    echo   1. 已安装 AnythingLLM 桌面版（https://anythingllm.com）
    echo   2. 安装路径为默认路径
    echo.
    pause
    exit /b 1
)
echo   AnythingLLM 已就绪

echo.
echo [2/2] 开始修补...
echo.

REM Run PowerShell patcher
powershell -ExecutionPolicy Bypass -File "%~dp0patcher.ps1"
set PATCH_RESULT=%errorlevel%

echo.
if %PATCH_RESULT% equ 0 (
    echo ========================================
    echo   修补完成！请重新打开 AnythingLLM。
    echo ========================================
) else (
    echo ========================================
    echo   修补失败，请查看上方错误信息。
    echo ========================================
)

echo.
echo 按任意键关闭...
pause >nul
