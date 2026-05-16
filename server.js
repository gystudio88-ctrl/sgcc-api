const express = require('express');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const QRCode = require('qrcode');
const { decrypt } = require('./decrypt');
const { encrypt } = require('./encrypt');
const { getRandomCode, verifyPassword } = require('./auth');

// 读取同目录 .env 文件
const envPath = path.join(path.dirname(process.execPath), '.env');
if (fs.existsSync(envPath)) {
  fs.readFileSync(envPath, 'utf-8').split('\n').forEach(line => {
    const [key, val] = line.trim().split('=');
    if (key && val) process.env[key.trim()] = val.trim();
  });
}

const PORT = process.env.PORT || 3000;

// 设置终端编码
if (process.stdout.isTTY) {
  process.stdout.setDefaultEncoding('utf8');
}

/**
 * 启动验证
 */
async function startAuth() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  const randomCode = getRandomCode();
  
  // 生成ASCII二维码（兼容Windows CMD）
  const qrTerminal = await QRCode.toString(randomCode, { 
    type: 'terminal',
    errorCorrectLevel: 'M'
  });
  
  console.log('');
  console.log('========================================');
  console.log('         启动验证');
  console.log('========================================');
  console.log(`随机码: ${randomCode}`);
  console.log('========================================');
  console.log('');
  console.log(qrTerminal);

  return new Promise((resolve) => {
    rl.question('验证密码: ', (answer) => {
      rl.close();
      if (verifyPassword(answer.trim())) {
        // 清屏
        console.log('验证通过！');
        console.clear();
        
        console.log('');
        resolve(true);
      } else {
        console.log('');
        console.log('验证失败！程序将退出。');
        resolve(false);
      }
    });
  });
}

/**
 * 主函数
 */
async function main() {
  // 启动验证
  const authPassed = await startAuth();
  if (!authPassed) {
    process.exit(1);
    return;
  }

  const app = express();
  app.use(express.json());

  /**
   * POST /encrypt
   * Body: { "data": "原文字符串" }
   * Response: { "success": true, "result": { "privateParam": "...", "data": "..." } }
   */
  app.post('/encrypt', (req, res) => {
    const body = req.body;
    if (!body || Object.keys(body).length === 0) {
      return res.status(400).json({ success: false, error: '请求体不能为空' });
    }

    const result = encrypt(JSON.stringify(body));
    res.status(result.success ? 200 : 500).json(result);
  });

  /**
   * POST /decrypt
   * Body: { "privateParam": "...", "data": "..." }
   * Response: { "success": true, "data": "原文字符串" }
   */
  app.post('/decrypt', (req, res) => {
    const body = req.body;
    if (!body || !body.privateParam || !body.data) {
      return res.status(400).json({ success: false, error: '缺少 privateParam 或 data 字段' });
    }
    const { privateParam, data } = body;

    const result = decrypt(privateParam, data);
    res.status(result.success ? 200 : 422).json(result);
  });

  app.listen(PORT, '127.0.0.1', () => {
    console.log(`服务已启动`);
    //console.log(`服务已启动: http://localhost:${PORT}`);
    //console.log('  POST /encrypt  - 加密');
    //console.log('  POST /decrypt  - 解密');
  });
}

main();
