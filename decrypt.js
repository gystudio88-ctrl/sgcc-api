const { getCryptoModule } = require('./sgcc_crypto');

/**
 * 解密数据（使用原始 JS 的 SM2/SM3/SM4 实现，与对方服务器完全兼容）
 * @param {string} privateParam - SM2加密的SM4密钥
 * @param {string} data - SM4加密的密文
 * @returns {{ success: boolean, data?: string, error?: string }}
 */
function decrypt(privateParam, data) {
  try {
    const m = getCryptoModule();
    const cipherJson = JSON.stringify({ privateParam, data });
    const result = m.dataDecrypt(cipherJson);
    if (!result) throw new Error('解密失败，数据可能被篡改');
    return { success: true, data: result };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

module.exports = { decrypt };
