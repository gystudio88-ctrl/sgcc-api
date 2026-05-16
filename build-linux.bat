@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo   信创系统打包脚本 (含Node运行时)
echo ========================================
echo.

set NODE_VERSION=18.20.4
set OUTPUT_DIR=dist\sgcc-linux-arm64

:: 步骤1: 生成 crypto_bundle.js
echo [1/4] 生成 crypto_bundle.js...
node extract_bundle.js
if not exist crypto_bundle.js (
    echo 生成失败
    pause
    exit /b 1
)

:: 步骤2: 打包所有依赖为单文件
echo [2/4] 打包程序...
call npx esbuild server.js --bundle --platform=node --outfile=dist/bundle.js
if %errorlevel% neq 0 (
    echo 打包失败
    pause
    exit /b 1
)

:: 步骤3: 下载Node.js ARM64
echo [3/4] 下载Node.js ARM64运行时...
if not exist dist\node-v%NODE_VERSION%-linux-arm64.tar.gz (
    curl -L -o dist\node-v%NODE_VERSION%-linux-arm64.tar.gz https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-linux-arm64.tar.gz
    if %errorlevel% neq 0 (
        echo 下载失败，请检查网络连接
        pause
        exit /b 1
    )
)

:: 步骤4: 创建部署包
echo [4/4] 创建部署包...
if exist %OUTPUT_DIR% rmdir /s /q %OUTPUT_DIR%
mkdir %OUTPUT_DIR%

:: 复制程序
copy dist\bundle.js %OUTPUT_DIR%\sgcc-crypto-api.js >nul

:: 创建启动脚本
(
echo #!/bin/bash
echo SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo export PATH="$SCRIPT_DIR/node/bin:$PATH"
echo "$SCRIPT_DIR/node/bin/node" "$SCRIPT_DIR/sgcc-crypto-api.js"
) > %OUTPUT_DIR%\start.sh

:: 创建安装脚本
(
echo #!/bin/bash
echo echo "正在解压Node.js运行时..."
echo tar -xzf node.tar.gz -C .
echo chmod +x start.sh
echo echo "安装完成！运行 ./start.sh 启动服务"
) > %OUTPUT_DIR%\install.sh

:: 复制Node.js压缩包
copy dist\node-v%NODE_VERSION%-linux-arm64.tar.gz %OUTPUT_DIR%\node.tar.gz >nul

:: 创建说明文件
(
echo ========================================
echo   国密加密API服务 - 信创系统版
echo ========================================
echo.
echo 安装步骤:
echo   1. 解压此文件夹到目标目录
echo   2. 运行: chmod +x install.sh ^&^& ./install.sh
echo   3. 运行: ./start.sh
echo.
echo 或者手动安装:
echo   tar -xzf node.tar.gz
echo   ./node/bin/node sgcc-crypto-api.js
echo.
echo 端口: 3000
echo 接口:
echo   POST /encrypt - 加密
echo   POST /decrypt - 解密
echo.
) > %OUTPUT_DIR%\README.txt

echo.
echo ========================================
echo   打包完成!
echo ========================================
echo.
echo 输出目录: %OUTPUT_DIR%\
echo.
echo 部署步骤:
echo   1. 将 sgcc-linux-arm64 文件夹复制到信创系统
echo   2. 运行: chmod +x install.sh ^&^& ./install.sh
echo   3. 运行: ./start.sh
echo.
pause
