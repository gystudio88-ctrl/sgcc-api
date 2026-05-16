# 信创系统打包脚本 (含Node运行时)
$NODE_VERSION = "18.20.4"
$OUTPUT_DIR = "dist\sgcc-linux-arm64"

Write-Host "========================================"
Write-Host "  信创系统打包脚本 (含Node运行时)"
Write-Host "========================================"
Write-Host ""

# 步骤1: 生成 crypto_bundle.js
Write-Host "[1/4] 生成 crypto_bundle.js..."
node extract_bundle.js
if (-not (Test-Path "crypto_bundle.js")) {
    Write-Host "生成失败"
    Read-Host "按回车退出"
    exit 1
}

# 步骤2: 打包程序
Write-Host "[2/4] 打包程序..."
npx esbuild server.js --bundle --platform=node --outfile="dist\bundle.js"
if ($LASTEXITCODE -ne 0) {
    Write-Host "打包失败"
    Read-Host "按回车退出"
    exit 1
}

# 步骤3: 下载Node.js ARM64
Write-Host "[3/4] 下载Node.js ARM64运行时..."
$nodeUrl = "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-arm64.tar.gz"
$nodeFile = "dist\node-v$NODE_VERSION-linux-arm64.tar.gz"

if (-not (Test-Path $nodeFile)) {
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeFile
}

# 步骤4: 创建部署包
Write-Host "[4/4] 创建部署包..."
if (Test-Path $OUTPUT_DIR) {
    Remove-Item -Recurse -Force $OUTPUT_DIR
}
New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null

# 复制文件
Copy-Item "dist\bundle.js" "$OUTPUT_DIR\sgcc-crypto-api.js"
Copy-Item $nodeFile "$OUTPUT_DIR\node.tar.gz"

# 创建启动脚本
$startSh = @"
#!/bin/bash
SCRIPT_DIR="`$(cd "`$(dirname "`$0")" && pwd)"
if [ ! -d "`$SCRIPT_DIR/node" ]; then
    echo "正在解压Node.js运行时..."
    tar -xzf "`$SCRIPT_DIR/node.tar.gz" -C "`$SCRIPT_DIR"
    mv "`$SCRIPT_DIR/node-v$NODE_VERSION-linux-arm64" "`$SCRIPT_DIR/node"
fi
"`$SCRIPT_DIR/node/bin/node" "`$SCRIPT_DIR/sgcc-crypto-api.js"
"@
$startSh | Out-File -FilePath "$OUTPUT_DIR\start.sh" -Encoding utf8NoBOM

# 创建README
$readme = @"
========================================
  国密加密API服务 - 信创系统版
========================================

使用方法:
  chmod +x start.sh
  ./start.sh

首次运行会自动解压Node.js运行时

端口: 3000
接口:
  POST /encrypt - 加密
  POST /decrypt - 解密
"@
$readme | Out-File -FilePath "$OUTPUT_DIR\README.txt" -Encoding utf8

Write-Host ""
Write-Host "========================================"
Write-Host "  打包完成!"
Write-Host "========================================"
Write-Host ""
Write-Host "输出目录: $OUTPUT_DIR\"
Write-Host ""
Write-Host "部署步骤:"
Write-Host "  1. 将 sgcc-linux-arm64 文件夹复制到信创系统"
Write-Host "  2. 运行: chmod +x start.sh"
Write-Host "  3. 运行: ./start.sh"
Write-Host ""
Read-Host "按回车退出"
