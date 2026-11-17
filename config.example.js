/* 用法：把本文件复制成 config.js，填入你自己的云服务参数。
   config.js 已被 .gitignore 忽略，永远不会进入代码仓库。

   参数从哪里来：在 WorkBuddy 里为项目开通「云服务」后会得到一组
   endpoint + publishableKey（见 README「准备云服务」一节）。
   换成自建后端也可以，只要实现同名接口即可。 */

window.APP_CONFIG = {
  // 你的应用域名，形如 https://xxxxxxxx.app.workbuddy.host
  endpoint: 'https://YOUR-APP-ID.app.workbuddy.host',

  // 账号服务的转接地址，一般保持默认
  oauthRelayBaseUrl: 'https://www.workbuddy.cn/v2/as/genie-baas/oauth',

  // 前端调用用的公开密钥，形如 wbpk_xxxxxxxx
  publishableKey: 'wbpk_YOUR_KEY'
};
