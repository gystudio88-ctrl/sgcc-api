@echo off
chcp 65001 >nul
echo [0/4] 生成 crypto_bundle.js...
node extract_bundle.js
if not exist crypto_bundle.js ( echo 生成 crypto_bundle.js 失败 & pause & exit /b 1 )

echo [1/4] 打包所有依赖为单文件（含 crypto_bundle）...
call npx esbuild server.js --bundle --platform=node --outfile=dist/bundle.js
if %errorlevel% neq 0 ( echo 打包失败 & pause & exit /b 1 )

echo [2/4] 生成 SEA blob...
node --experimental-sea-config sea-config.json
if not exist dist\sea-prep.blob ( echo 生成 blob 失败 & pause & exit /b 1 )

echo [3/4] 复制 node.exe...
powershell -Command "$node = (Get-Command node).Source; Copy-Item $node -Destination 'dist\sgcc-crypto-api.exe' -Force"
if not exist dist\sgcc-crypto-api.exe ( echo 复制 node.exe 失败 & pause & exit /b 1 )

echo [4/4] 注入 blob...
call npx postject dist\sgcc-crypto-api.exe NODE_SEA_BLOB dist\sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2
if %errorlevel% neq 0 ( echo 注入失败 & pause & exit /b 1 )

echo.
echo 打包完成: dist\sgcc-crypto-api.exe （单文件，双击运行）
pause
