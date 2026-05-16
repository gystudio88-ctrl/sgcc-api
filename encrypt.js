const { getCryptoModule } = require('./sgcc_crypto');

/**
 * 加密数据（使用原始 JS 的 SM2/SM3/SM4 实现，与对方服务器完全兼容）
 * @param {string} plaintext - 原文字符串
 * @returns {{ success: boolean, result?: object, error?: string }}
 */
function encrypt(plaintext) {
  try {
    const m = getCryptoModule();
    const resultStr = m.dataEncrypt(plaintext);
    return { success: true, result: JSON.parse(resultStr) };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

module.exports = { encrypt };
