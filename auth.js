const crypto = require('crypto');

// 当前随机码
let currentRandomCode = null;

/**
 * 生成随机码
 */
function generateRandomCode() {
  // 89开头标识本软件，后面14位随机字符
  const randomPart = crypto.randomBytes(7).toString('hex').toUpperCase();
  return '89' + randomPart;
}

/**
 * 获取随机码
 */
function getRandomCode() {
  if (!currentRandomCode) {
    currentRandomCode = generateRandomCode();
  }
  return currentRandomCode;
}

/**
 * 生成验证码
 */
function generatePassword() {
  const randomCode = getRandomCode();
  
  // 提取软件标识（前两位）
  const appId = randomCode.substring(0, 2);
  const actualCode = randomCode.slice(2);
  
  // 89标识使用 md5_digits 算法
  const salt = 'sgcc_decrypt_2026';
  const hash = crypto.createHash('md5').update(actualCode + salt).digest('hex');
  
  let code = '';
  for (let i = 0; i < hash.length && code.length < 8; i++) {
    if (!isNaN(parseInt(hash[i]))) {
      code += hash[i];
    }
  }
  
  while (code.length < 8) {
    code += '0';
  }
  
  return code;
}

/**
 * 验证密码
 */
function verifyPassword(inputPassword) {
  const correctPassword = generatePassword();
  return inputPassword === correctPassword;
}

module.exports = {
  getRandomCode,
  verifyPassword
};
