# 饮食管家 · 胰腺炎恢复期饮食助手

给刚出院的胰腺炎患者家属用的手机网页应用：每天照着吃、拿不准的拍个照问一问、不舒服了按住说话问一问，所有记录自动留档，复诊时可以直接给医生看。

界面按老人使用习惯设计：大字、大按钮、四个入口、一个返回键。

## 功能

| 功能 | 说明 |
| --- | --- |
| 🍚 今日菜谱 | 按健康档案里的年龄、体重、饮食阶段估算热量与蛋白，生成 5 餐低脂食谱，**每样食物都标克重**，可随时「换一份」 |
| 📷 这个能吃吗 | 拍照或选图，多模态模型识别食物/商品后给出「可以吃 / 慎吃 / 不能吃」+ 原因和建议量 |
| 🤒 不舒服怎么办 | 按住说话或打字描述症状，模型做分级判断；出现剧痛、呕吐、发烧等危险信号时强制判为「紧急·立即就医」 |
| 📋 健康档案 | 基本信息、饮食阶段、过敏史 + 体重记录与趋势 + 症状记录，一页看全 |
| 🎤 按住说话 | 自己搭的语音识别服务，不依赖手机浏览器能力（见下文「为什么需要自建 ASR」） |

## 技术栈

- 前端：单文件 `index.html`，原生 JS + CSS，无构建步骤；PWA（可添加到手机桌面）
- 后端：`server.py`（Python 标准库 `http.server`）——托管静态文件 + `POST /api/asr` 语音识别
- AI 与数据库：云服务的 LLM 网关（支持图片输入）与 PostgreSQL
- 语音识别：Vosk 中文小模型，纯本地推理，不上传第三方

```
.
├── index.html                 # 整个前端（结构 / 样式 / 逻辑）
├── config.example.js          # 云服务参数模板 → 复制成 config.js 使用
├── server.py                  # 静态托管 + /api/asr 语音识别
├── requirements.txt           # vosk
├── schema.sql                 # 数据库建表 + 行级安全策略
├── manifest.json / icon.png   # PWA
├── workbuddy-cloud-sdk.js     # 云服务浏览器 SDK（第三方，见下方说明）
├── asr/                       # 语音模型目录（模型用脚本下载，不入库）
└── scripts/fetch-asr-model.sh # 下载中文识别模型
```

## 快速开始

前置：Python 3.9+，以及一个可用的云服务（LLM + PostgreSQL）。

```bash
git clone <本仓库>
cd diet-guard

# 1. 配置云服务参数（不会进 git）
cp config.example.js config.js
# 编辑 config.js：填 endpoint 和 publishableKey

# 2. 下载语音识别模型（约 66MB）
bash scripts/fetch-asr-model.sh

# 3. 装依赖并启动
pip install -r requirements.txt
PORT=8000 python server.py
# 浏览器打开 http://127.0.0.1:8000
```

没有 `config.js` 也能打开页面：界面正常显示，首页会提示「还没配置云服务」，
AI 相关功能不可用，其余本地记录功能可正常体验。

### 准备云服务

本项目默认对接 **WorkBuddy 云服务**（免运维的托管后端，提供 LLM 网关 + PostgreSQL + 对象存储）。
在 WorkBuddy 里为项目开通云服务后，会拿到：

- `endpoint`：形如 `https://xxxx.app.workbuddy.host`
- `publishableKey`：形如 `wbpk_xxxx`（前端可公开调用的密钥）

然后：

1. 到后台的 SQL 控制台执行 `schema.sql`
2. 确认可用模型列表里有支持**图片输入**的模型（代码默认优先 `fast-model`，可改 `index.html` 里的 `pref` 数组）

想换成别的后端也可以，只要提供同构的 `llm.chat.completions.create`（流式）与 `database.from().select/insert/update/delete`
接口，改 `workbuddy-cloud-sdk.js` 这一层即可。

### 部署

任何能跑 Python 的环境都行（Railway / Fly.io / 云服务器 / 群晖 Docker 均可），关键两点：

- 安装依赖：`pip install -r requirements.txt`
- 启动命令：`python server.py`，读取环境变量 `PORT`

需要 HTTPS 才能用麦克风（浏览器安全上下文要求）；本地 `127.0.0.1` 例外。

## 为什么需要自建 ASR

一开始用的是浏览器自带的 Web Speech API，在安卓/鸿蒙上表现很差：
华为浏览器的 ArkWeb 内核里 `SpeechRecognition` 对象存在，但背后的识别服务不可用——
能拿到麦克风权限，就是转不出文字；云端 LLM 网关也只接收文字和图片，没有语音转写端点。

所以改成：浏览器只负责录音，音频上传到应用自带的 `/api/asr`，由服务端用 Vosk 识别成文字，
再填回输入框让用户确认。这样「按住说话」才真正可用，也不依赖任何第三方语音 API。

清晰普通话准确率约九成；老人方言或口齿不清会下降，因此交互设计成**先出文字、用户确认后再提问**。

## 隐私与安全

- **本仓库不含任何真实用户数据**：健康档案、体重、症状记录都在使用者自己的云数据库里，
  前端只存 `localStorage` 缓存
- 云服务参数放在 `config.js`，已被 `.gitignore` 忽略；仓库里只有 `config.example.js` 模板
- 语音识别是本地推理，音频不离开你自己的服务器
- 注意：本应用是**免登录家庭版**，`schema.sql` 里的策略允许匿名读写同一 `owner_id` 的数据。
  公开部署前请自行评估风险，多用户场景请改成基于 `auth.uid()` 的策略

## 免责声明

应用内的菜谱与建议由模型生成，仅供日常参考，**不能替代医生的诊断和治疗**。
出现剧烈腹痛、持续呕吐、发热、黄疸等情况请立即就医。

## 第三方

- `workbuddy-cloud-sdk.js` 来自 npm 包 `@tencent-ai/workbuddy-cloud-sdk`，按其自身许可使用；
  更推荐改成从 CDN 引入或自行安装（见 `index.html` 顶部 script 标签）
- 语音模型：[Vosk](https://alphacephei.com/vosk/)（Apache-2.0）

## License

MIT
