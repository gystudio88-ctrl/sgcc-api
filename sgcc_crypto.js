/**
 * 加载原始加密模块
 * esbuild 打包时会将 crypto_bundle 内联，无需外部文件
 */
const { createRequire } = require('module');
let _mod = null;

function getCryptoModule() {
  if (_mod) return _mod;

  const { require: req, window: bundleWindow } = require('./crypto_bundle');

  if (bundleWindow.SM2CipherMode) {
    global.SM2CipherMode = bundleWindow.SM2CipherMode;
  }

  _mod = req(4798);
  return _mod;
}

module.exports = { getCryptoModule };
