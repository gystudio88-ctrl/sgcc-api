@echo off
chcp 65001 >nul
echo ========================================
echo   编译Linux二进制文件 (使用Docker)
echo ========================================
echo.

:: 检查Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未安装Docker
    echo 请安装 Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

:: 步骤1: 生成 crypto_bundle.js
echo [1/4] 生成 crypto_bundle.js...
node extract_bundle.js
if not exist crypto_bundle.js (
    echo 生成失败
    pause
    exit /b 1
)

:: 步骤2: 打包程序
echo [2/4] 打包程序...
call npx esbuild server.js --bundle --platform=node --outfile=dist/bundle.js
if %errorlevel% neq 0 (
    echo 打包失败
    pause
    exit /b 1
)

:: 步骤3: 创建SEA配置
echo [3/4] 创建SEA配置...
(
{
  "main": "/build/bundle.js",
  "output": "/build/sea-prep.blob",
  "disableExperimentalSEAWarning": true
}
) > dist\sea-config.json

:: 步骤4: 使用Docker编译
echo [4/4] Docker编译中...
echo.

docker run --rm -v "%cd%\dist:/build" node:18 bash -c "cd /build && npm install -g postject && node --experimental-sea-config sea-config.json && cp $(which node) sgcc-crypto-api && postject sgcc-crypto-api NODE_SEA_BLOB sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2 && chmod +x sgcc-crypto-api"

if %errorlevel% neq 0 (
    echo.
    echo Docker编译失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo   编译完成!
echo ========================================
echo.
echo 输出文件: dist\sgcc-crypto-api
echo.
echo 部署到信创系统:
echo   1. 复制 dist\sgcc-crypto-api 到目标机器
echo   2. 运行: chmod +x sgcc-crypto-api
echo   3. 运行: ./sgcc-crypto-api
echo.
pause
