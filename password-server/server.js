const express = require('express');
const crypto = require('crypto');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 9008;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

/**
 * 软件配置：标识 -> { salt, algorithm }
 */
const appConfigs = {
  '88': {
    salt: 'browser_launcher_2024',
    algorithm: 'sha256_digits'
  },
  '89': {
    salt: 'sgcc_decrypt_2026',
    algorithm: 'md5_digits'
  },
  '90': {
    salt: 'another_salt_value',
    algorithm: 'sha256_hex'
  },
};

/**
 * 算法实现
 */
const algorithms = {
  // SHA256 提取数字
  'sha256_digits': (code, salt) => {
    const hash = crypto.createHash('sha256').update(code + salt).digest('hex');
    let result = '';
    for (let i = 0; i < hash.length && result.length < 8; i++) {
      if (!isNaN(parseInt(hash[i]))) {
        result += hash[i];
      }
    }
    while (result.length < 8) {
      result += '0';
    }
    return result;
  },
  
  // MD5 提取数字
  'md5_digits': (code, salt) => {
    const hash = crypto.createHash('md5').update(code + salt).digest('hex');
    let result = '';
    for (let i = 0; i < hash.length && result.length < 8; i++) {
      if (!isNaN(parseInt(hash[i]))) {
        result += hash[i];
      }
    }
    while (result.length < 8) {
      result += '0';
    }
    return result;
  },
  
  // SHA256 前8位
  'sha256_hex': (code, salt) => {
    const hash = crypto.createHash('sha256').update(code + salt).digest('hex');
    return hash.substring(0, 8).toUpperCase();
  },
};

/**
 * 根据软件标识获取配置
 */
function getAppConfig(appId) {
  return appConfigs[appId] || { salt: 'default_salt', algorithm: 'sha256_digits' };
}

/**
 * 根据随机码计算验证码
 */
function calculatePassword(randomCode) {
  // 提取软件标识（前两位）
  const appId = randomCode.length >= 2 ? randomCode.substring(0, 2) : '88';
  
  // 提取实际随机码（去掉前两位）
  const actualCode = randomCode.length > 2 ? randomCode.slice(2) : randomCode;
  
  // 获取软件配置
  const config = getAppConfig(appId);
  
  // 执行算法
  const algorithm = algorithms[config.algorithm];
  
  return algorithm(actualCode, config.salt);
}

/**
 * API: 根据随机码计算验证码
 */
app.post('/api/calc', (req, res) => {
  const { randomCode } = req.body;
  
  if (!randomCode) {
    return res.status(400).json({ success: false, error: '缺少随机码' });
  }
  
  const password = calculatePassword(randomCode);
  res.json({ success: true, password });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`密码计算服务: http://localhost:${PORT}`);
});
