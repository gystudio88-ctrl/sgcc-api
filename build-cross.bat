@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   信创系统打包脚本
echo ========================================
echo.

:: 步骤1: 生成 crypto_bundle.js
echo [1/3] 生成 crypto_bundle.js...
node extract_bundle.js
if not exist crypto_bundle.js (
    echo 生成 crypto_bundle.js 失败
    pause
    exit /b 1
)

:: 步骤2: 打包所有依赖为单文件
echo [2/3] 打包所有依赖为单文件...
call npx esbuild server.js --bundle --platform=node --outfile=dist/sgcc-crypto-api.js
if %errorlevel% neq 0 (
    echo 打包失败
    pause
    exit /b 1
)

:: 步骤3: 创建启动脚本
echo [3/3] 创建启动脚本...

:: Linux启动脚本
(
echo #!/bin/bash
echo DIR="$(cd "$(dirname "$0")" && pwd)"
echo "$DIR/node" "$DIR/sgcc-crypto-api.js"
) > dist/start.sh

:: Windows启动脚本
(
echo @echo off
echo "%~dp0node.exe" "%~dp0sgcc-crypto-api.js"
) > dist/start.bat

echo.
echo ========================================
echo   打包完成!
echo ========================================
echo.
echo 输出文件:
echo   dist\sgcc-crypto-api.js  - 主程序(单文件)
echo   dist\start.sh            - Linux启动脚本
echo   dist\start.bat           - Windows启动脚本
echo.
echo 部署到信创系统:
echo   1. 复制 dist 文件夹到目标机器
echo   2. 安装 Node.js 18+ 或复制 node 可执行文件到 dist 目录
echo   3. 运行: ./start.sh 或 node sgcc-crypto-api.js
echo.
pause
