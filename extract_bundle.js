/**
 * 从 123.js 提取加密模块，生成 crypto_bundle.js
 * 只需运行一次：node extract_bundle.js
 */
const fs = require('fs');

let code = fs.readFileSync('123.js', 'utf-8');

// 截掉末尾的 Vue 挂载入口
const lines = code.split('\n');
const cutIdx = lines.findIndex(l => l.includes('const t = document.currentScript'));
let trimmedCode = code;
if (cutIdx !== -1) {
  let blockStart = cutIdx;
  while (blockStart > 0 && !lines[blockStart].trim().startsWith('(()')) blockStart--;
  trimmedCode = lines.slice(0, blockStart).join('\n') + '\n  })();\n';
}

const shim = `// browser shim
var window = {};
var document = {
  querySelector: () => null,
  createElement: () => ({ style: {}, setAttribute: () => {}, appendChild: () => {} }),
  createElementNS: () => ({ setAttribute: () => {} }),
  head: { appendChild: () => {} },
  baseURI: 'http://localhost/',
  currentScript: { src: 'http://localhost/js/app.js' },
};
var navigator = { userAgent: '' };
var location = { href: 'http://localhost/', hash: '', pathname: '/' };
var history = { pushState: () => {} };
var sessionStorage = { getItem: () => null, setItem: () => {}, removeItem: () => {}, clear: () => {} };
var localStorage = { getItem: () => null, setItem: () => {}, removeItem: () => {}, clear: () => {} };
var self = window;
var XMLHttpRequest = function() { return { open:()=>{}, send:()=>{}, setRequestHeader:()=>{} }; };
`;

// 把外层 IIFE 改成返回 __webpack_require__ 的函数
// 在 return 之前先加载依赖模块（触发 SM2CipherMode 注册到 window）
const footer = `
  // 预加载依赖模块，触发 SM2CipherMode 等全局变量注册
  try { __webpack_require__(5852); } catch(e) {}
  try { __webpack_require__(8475); } catch(e) {}
  try { __webpack_require__(9434); } catch(e) {}
  return { require: __webpack_require__, window: window };
})();
`;

let result = shim;
result += trimmedCode
  .replace(/^\(\(\) => \{/, 'module.exports = (() => {')
  .replace(/\}\)\(\);\s*$/, footer);

fs.writeFileSync('crypto_bundle.js', result, 'utf-8');
console.log('crypto_bundle.js 生成完成');
