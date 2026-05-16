#!/bin/bash
# CentOS 打包脚本
# 使用方法: chmod +x build-centos.sh && ./build-centos.sh

echo "========================================"
echo "  CentOS 打包脚本"
echo "========================================"

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "正在安装Node.js 18..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
fi

echo "Node版本: $(node -v)"

# 步骤1: 安装依赖
echo "[1/4] 安装依赖..."
npm install

# 步骤2: 生成 crypto_bundle.js
echo "[2/4] 生成 crypto_bundle.js..."
node extract_bundle.js

# 步骤3: 打包程序
echo "[3/4] 打包程序..."
npx esbuild server.js --bundle --platform=node --outfile=dist/bundle.js

# 步骤4: 编译二进制
echo "[4/4] 编译二进制文件..."

# 创建SEA配置
cat > dist/sea-config.json << 'EOF'
{
  "main": "dist/bundle.js",
  "output": "dist/sea-prep.blob",
  "disableExperimentalSEAWarning": true
}
EOF

# 生成blob
node --experimental-sea-config dist/sea-config.json

# 复制node可执行文件
cp $(which node) dist/sgcc-crypto-api

# 安装postject
npm install -g postject

# 注入blob
postject dist/sgcc-crypto-api NODE_SEA_BLOB dist/sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2

# 设置执行权限
chmod +x dist/sgcc-crypto-api

echo ""
echo "========================================"
echo "  打包完成!"
echo "========================================"
echo ""
echo "输出文件: dist/sgcc-crypto-api"
echo ""
echo "部署到信创系统:"
echo "  1. 复制 dist/sgcc-crypto-api 到目标机器"
echo "  2. 运行: chmod +x sgcc-crypto-api"
echo "  3. 运行: ./sgcc-crypto-api"
echo ""
