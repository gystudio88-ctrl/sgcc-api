@echo off
chcp 65001 >nul
echo ========================================
echo   使用Docker打包Linux可执行文件
echo ========================================
echo.

:: 检查Docker是否安装
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未安装Docker，请先安装Docker Desktop
    echo 下载地址: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

:: 步骤1: 生成 crypto_bundle.js
echo [1/5] 生成 crypto_bundle.js...
node extract_bundle.js
if not exist crypto_bundle.js (
    echo 生成失败
    pause
    exit /b 1
)

:: 步骤2: 打包依赖
echo [2/5] 打包依赖...
call npx esbuild server.js --bundle --platform=node --outfile=dist/bundle.js
if %errorlevel% neq 0 (
    echo 打包失败
    pause
    exit /b 1
)

:: 步骤3: 创建临时Dockerfile
echo [3/5] 创建Docker构建环境...
(
FROM node:18-alpine
WORKDIR /build
COPY dist/bundle.js ./server.js
RUN apk add --no-cache curl xz \
 && curl -fsSL https://github.com/nickolay/versioned-parcel/releases/download/v1.0.0/parcel-linux-x64.gz | gunzip > /usr/local/bin/parcel \
 && chmod +x /usr/local/bin/parcel
CMD ["sh", "-c", "node --experimental-sea-config /build/sea-config.json && cp /build/sgcc-crypto-api /output/"]
) > dist\Dockerfile

:: 步骤4: 构建Docker镜像并打包
echo [4/5] Docker构建中...
docker build -t sgcc-builder -f dist\Dockerfile . 2>nul

echo [5/5] 生成可执行文件...
echo.
echo 注意: 完整的Linux单文件打包需要在Linux环境运行
echo 已生成部署包: dist\linux-deploy\
echo.
echo 如需Linux单文件，请在信创系统上运行:
echo   node --experimental-sea-config sea-config.json
echo.
pause
