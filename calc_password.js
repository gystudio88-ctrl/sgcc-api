/**
 * 密码计算工具
 * 用于计算指定机器码和日期的验证密码
 */

const crypto = require('crypto');

/**
 * 获取当前时间槽（每10分钟一个）
 * @param {string} dateTime - 可选，格式 "YYYY-MM-DD HH:MM"
 */
function getTimeSlot(dateTime) {
  if (dateTime) {
    return dateTime;
  }
  const now = new Date();
  const minutes = Math.floor(now.getMinutes() / 10) * 10;
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
}

/**
 * 计算验证密码
 * @param {string} machineCode - 机器码
 * @returns {string} 8位数字验证码
 */
function calculatePassword(machineCode) {
  const hash = crypto.createHash('sha256').update(machineCode).digest('hex');
  
  // 取前8位数字作为验证码
  let code = '';
  for (let i = 0; i < hash.length && code.length < 8; i++) {
    if (!isNaN(parseInt(hash[i]))) {
      code += hash[i];
    }
  }
  
  // 如果数字不够，补充
  while (code.length < 8) {
    code += '0';
  }
  
  return code;
}

// 命令行参数处理
const args = process.argv.slice(2);

if (args.length === 0) {
  // 无参数时显示帮助
  console.log('');
  console.log('密码计算工具');
  console.log('');
  console.log('用法:');
  console.log('  node calc_password.js <机器码>');
  console.log('  node calc_password.js <硬件ID> <主板ID> [时间槽]');
  console.log('');
  console.log('参数:');
  console.log('  机器码   16位机器码');
  console.log('  硬件ID   CPU ProcessorId');
  console.log('  主板ID   主板序列号');
  console.log('  时间槽   可选，格式 "YYYY-MM-DD HH:MM"，默认当前时间槽');
  console.log('');
  console.log('示例:');
  console.log('  node calc_password.js ABCD1234EFGH5678');
  console.log('  node calc_password.js BFEBFBFF000906E9 Default-string');
  console.log('  node calc_password.js BFEBFBFF000906E9 Default-string "2026-05-05 10:00"');
  console.log('');
} else if (args.length === 1) {
  // 直接使用机器码
  const machineCode = args[0].toUpperCase();
  const password = calculatePassword(machineCode);
  
  console.log('');
  console.log('========================================');
  console.log('         密码计算结果');
  console.log('========================================');
  console.log(`机器码: ${machineCode}`);
  console.log('----------------------------------------');
  console.log(`验证码: ${password}`);
  console.log('========================================');
  console.log('');
} else {
  // 根据硬件信息计算
  const cpuId = args[0];
  const motherboardId = args[1];
  const timeSlot = args[2] ? getTimeSlot(args[2]) : getTimeSlot();
  
  const combined = `${cpuId}-${motherboardId}-${timeSlot}`;
  const machineCode = crypto.createHash('md5').update(combined).digest('hex').substring(0, 16).toUpperCase();
  const password = calculatePassword(machineCode);
  
  console.log('');
  console.log('========================================');
  console.log('         密码计算结果');
  console.log('========================================');
  console.log(`CPU ID: ${cpuId}`);
  console.log(`主板ID: ${motherboardId}`);
  console.log(`时间槽: ${timeSlot}`);
  console.log('----------------------------------------');
  console.log(`机器码: ${machineCode}`);
  console.log(`验证码: ${password}`);
  console.log('========================================');
  console.log('');
}
