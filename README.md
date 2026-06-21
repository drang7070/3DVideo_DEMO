# 3DVideo_DEMO

一个轻量级的 3D 互动视频原型。项目用 Canvas 和原生 DOM 叠加层完成 3D 视差画面、素材层管理、场景流转、语音识别、Kimi 角色回复和讯飞 TTS 朗读。

当前架构已经回到单 Node 服务加静态前端的形态：没有 Vite、Docker 或前端构建步骤。服务端集中在 `server.js`，前端核心逻辑集中在 `src/app.js`，不同页面通过 `body[data-mode]` 复用同一套运行时。

## 当前架构

```text
3DVideo_DEMO/
├─ index.html                  # 普通 3D 视频编辑器，使用 index 数据空间
├─ index_conver.html            # 对话/说服流程编辑器，使用 conver 数据空间
├─ viewer.html                 # 单场景预览页
├─ final.html                  # 最终展示页，可合并普通场景组和对话场景组
├─ intro.html                  # 独立介绍页
├─ intro-demo.html             # intro 嵌入式演示页，复用 src/app.js
├─ src/app.js                  # 前端运行时：editor / conver-editor / viewer / final / intro-demo
├─ server.js                   # Node 原生 HTTP 服务、数据存储、上传、AI 和 TTS 代理
├─ styles.css                  # 页面共用样式
├─ data/scene-layout-db.json   # 场景、场景组、对话配置和多数据空间存储
├─ uploads/                    # 编辑器上传后的素材
├─ mat/                        # 原始或补充素材
├─ public/                     # 兼容保留的静态素材目录
├─ .env.example                # 环境变量模板
└─ ecosystem.config.js         # PM2 部署配置示例
```

## 页面分工

- `index.html` 是普通 3D 视频编辑器，默认数据空间是 `index`。
- `index_conver.html` 是对话流程编辑器，`body[data-mode="conver-editor"]`，默认数据空间是 `conver`。
- `viewer.html` 用于预览指定场景，可通过 `?scene=场景ID&group=场景组ID&space=index|conver` 指定来源。
- `final.html` 是最终观众页。默认会合并 `index` 和 `conver` 两个数据空间中允许展示的场景组，也可用 `?group=场景组ID` 指定进入某个场景组。
- `intro-demo.html` 是介绍页中的嵌入式演示模式，仍然走 `src/app.js` 的渲染和播放逻辑。

## 核心能力

- 支持上传和管理图片、GIF、MOV、MP4、WebM、音频素材。
- 每个画面图层可配置 X/Y、深度、缩放、旋转、倾斜和透明度。
- Canvas 负责透视投影、视差和图层排序；GIF 和视频通过 DOM/Canvas 叠加层保持播放。
- 每个场景可配置背景音频、循环策略、讯飞音色、是否需要年龄输入、是否开启实时回复和 TTS。
- 场景流转支持 `none`、`auto`、`dialog`、`score` 四种模式：
  - `none`：场景结束后停留。
  - `auto`：自动进入下一个场景。
  - `dialog`：根据观众输入关键词跳转。
  - `score`：对话评分后按分数区间跳转。
- 场景组保存最终入口场景、默认结局场景、封面图、是否在最终页展示，以及导演/角色提示词配置。
- 对话场景支持“用户说话场景”和“实时回复场景”的拆分，Kimi 负责生成角色回应和说服度评分，TTS 可将回应转成语音。
- 最终页会读取两个数据空间的可展示场景组，形成观众可选择的体验入口。

## 本地运行

建议使用 Node.js 22 或更高版本。项目没有 npm 依赖，主要依赖 Node 自带的 HTTP、文件系统、`fetch`、`AbortController` 和 `WebSocket` 能力。

```powershell
cd 3DVideo_DEMO
npm start
```

也可以直接运行：

```powershell
node server.js
```

启动后访问：

```text
普通编辑器：http://127.0.0.1:5174/
对话编辑器：http://127.0.0.1:5174/index_conver.html
预览页：http://127.0.0.1:5174/viewer.html
最终页：http://127.0.0.1:5174/final.html
健康检查：http://127.0.0.1:5174/health
```

常用 URL 参数：

```text
?scene=场景ID
?group=场景组ID
?space=index
?space=conver
?intro=1
```

语法检查：

```powershell
npm run check
```

## 环境变量

`server.js` 直接读取进程环境变量，不会自动加载 `.env` 文件。`.env.example` 只是模板，本地运行时可在同一个终端里设置变量，线上部署时建议通过 PM2、系统服务或服务器面板注入。

PowerShell 示例：

```powershell
$env:MOONSHOT_API_KEY="你的 Moonshot API Key"
$env:MOONSHOT_BASE_URL="https://api.moonshot.cn/v1"
$env:KIMI_MODEL="kimi-k2.6"

$env:XFYUN_APP_ID="你的讯飞 AppID"
$env:XFYUN_API_KEY="你的讯飞 APIKey"
$env:XFYUN_API_SECRET="你的讯飞 APISecret"
$env:XFYUN_TTS_URL="wss://cbm01.cn-huabei-1.xf-yun.com/v1/private/mcd9m97e6"
$env:XFYUN_TTS_VOICE="x6_lingfeiyi_pro"

npm start
```

可选变量：

```text
PORT=5174
KIMI_TIMEOUT_MS=12000
KIMI_CONVERSATION_TIMEOUT_MS=30000
KIMI_MAX_TOKENS=160
```

注意：不要把真实密钥写进 README、前端代码或公开仓库。如果密钥已经提交过，建议立即在服务商后台轮换。

## 数据模型

主要数据保存在 `data/scene-layout-db.json`：

- `layouts`：普通编辑器的场景数据，对应 `index` 数据空间。
- `settings`：普通编辑器的全局设置和场景组配置。
- `editorSpaces.conver.layouts`：对话编辑器的场景数据。
- `editorSpaces.conver.settings`：对话编辑器的全局设置和场景组配置。

场景 payload 主要包含：

- `scene.focal`、`scene.parallax`、`scene.showGrid`
- `scene.audioAsset`、`scene.audioLoop`
- `scene.gifLoop`、`scene.webmLoop`
- `scene.flow.mode`、`scene.flow.nextSceneId`、`scene.flow.routes`、`scene.flow.scoreRoutes`
- `scene.xfyunVoice`
- `scene.ageRequired`
- `scene.realtimeReply`
- `scene.ttsEnabled`
- `scene.userSpeechScene`
- `scene.realtimeReplyScene`
- `items[]` 中每个素材的地址、类型、坐标、深度、缩放、旋转、倾斜和透明度

场景组主要包含：

- `id`、`name`
- `finalStartSceneId`
- `defaultEndingSceneId`
- `finalSelectable`
- `coverAsset`
- `directorConfig`

## API

### 场景

```text
GET    /api/layout?list=1&space=index
GET    /api/layout?list=1&details=1&space=conver
GET    /api/layout?id=场景ID&space=index
POST   /api/layout?space=index
DELETE /api/layout?id=场景ID&space=index
```

`space` 只接受 `index` 或 `conver`，未传时默认 `index`。

### 全局设置

```text
GET  /api/settings?space=index
POST /api/settings?space=conver
```

保存 `sceneGroups`、`activeSceneGroupId`、`finalSceneGroupId` 和 `finalStartSceneId`。

### 素材

```text
GET  /api/assets
POST /api/assets?filename=文件名
```

支持扩展名：

```text
.png .jpg .jpeg .webp .gif .mov .mp4 .webm .mp3 .wav .ogg .m4a .aac
```

单文件上传上限为 512 MB。`GET /api/assets` 会扫描 `mat/` 和 `uploads/`。

### AI 和语音

```text
POST /api/director-cue
POST /api/conversation-cue
POST /api/tts
POST /api/tts-stream
GET  /api/script-beats
POST /api/log-error
GET  /health
```

- `/api/director-cue`：代理 Kimi，按场景组导演配置生成短角色回复、舞台提示和特殊流转信息。
- `/api/conversation-cue`：代理 Kimi，生成角色回应、说服度、当前状态和评分原因。
- `/api/tts`：代理讯飞超拟人 TTS，一次性返回 `audio/mpeg`。
- `/api/tts-stream`：代理讯飞超拟人 TTS，以 chunked 方式流式返回 `audio/mpeg`。
- `/api/script-beats`：返回默认 beat 配置。
- `/api/log-error`：前端错误日志写入 `data/errors.log`。
- `/health`：返回数据库、内存、Kimi 和讯飞配置状态。

## 静态资源服务

`server.js` 同时负责静态资源：

- 服务根目录下的 HTML、CSS、JS、JSON、媒体文件。
- 防止路径穿越。
- 对 HTML、JS、CSS、JSON、TXT 提供 gzip。
- 支持 ETag、`If-None-Match` 和 Range 请求。
- 媒体资源使用较长缓存，非媒体资源使用 `no-cache`。

## 部署建议

推荐部署方式是：PM2 在服务器本机运行 Node 服务，Nginx 负责 HTTPS 和反向代理。

原因有两个：

- 服务当前监听 `127.0.0.1`，适合放在 Nginx 后面，不适合直接暴露端口。
- 摄像头和麦克风在现代浏览器中需要安全上下文，生产环境应使用 HTTPS。

### 1. 准备服务器

安装 Node.js 22+、Git、PM2 和 Nginx：

```bash
node -v
npm install -g pm2
```

把项目放到服务器，例如：

```bash
sudo mkdir -p /var/www/3dvideo-demo
sudo chown -R $USER:$USER /var/www/3dvideo-demo
cd /var/www/3dvideo-demo
git clone <你的仓库地址> .
```

如果不通过 Git，也可以把整个项目目录上传到 `/var/www/3dvideo-demo`。迁移时需要保留 `data/`、`uploads/`、`mat/` 中的实际场景和素材文件。

### 2. 配置环境变量

不要把密钥直接写进仓库。可以用服务器环境变量、PM2 的私有配置、系统服务配置或面板密钥管理功能注入。

```bash
export PORT=5174
export MOONSHOT_API_KEY="你的 Moonshot API Key"
export MOONSHOT_BASE_URL="https://api.moonshot.cn/v1"
export KIMI_MODEL="kimi-k2.6"
export XFYUN_APP_ID="你的讯飞 AppID"
export XFYUN_API_KEY="你的讯飞 APIKey"
export XFYUN_API_SECRET="你的讯飞 APISecret"
export XFYUN_TTS_URL="wss://cbm01.cn-huabei-1.xf-yun.com/v1/private/mcd9m97e6"
export XFYUN_TTS_VOICE="x6_lingfeiyi_pro"
```

### 3. 启动 PM2

```bash
cd /var/www/3dvideo-demo
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

查看状态和日志：

```bash
pm2 status
pm2 logs 3dvideo-demo
```

更新代码后重载：

```bash
cd /var/www/3dvideo-demo
git pull
pm2 reload 3dvideo-demo
```

### 4. 配置 Nginx

示例配置：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    client_max_body_size 512m;

    location / {
        proxy_pass http://127.0.0.1:5174;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

启用后再用 Certbot 或服务器面板签发 HTTPS 证书。HTTPS 生效后访问：

```text
https://your-domain.com/final.html
```

### 5. 验证部署

```bash
curl -I https://your-domain.com/
curl https://your-domain.com/health
curl "https://your-domain.com/api/layout?list=1&space=index"
```

浏览器中检查：

- `final.html` 能看到可展示的场景组。
- 普通场景和对话场景都能进入。
- 视频、GIF 和音频素材能正常播放。
- 摄像头和麦克风能弹出授权。
- 文字输入或语音输入可以触发 Kimi 和 TTS。

## 常见问题

### 外网打不开 5174 端口

这是当前设计。`server.js` 监听 `127.0.0.1`，推荐通过 Nginx 反向代理访问。如果确实要直接暴露端口，需要把监听地址改成 `0.0.0.0`，并配置防火墙和 HTTPS。

### 摄像头或麦克风没有授权弹窗

本地请使用 `http://127.0.0.1:5174` 或 `http://localhost:5174`。线上必须使用 HTTPS。

### Kimi 或 TTS 返回 503

通常是服务端缺少 `MOONSHOT_API_KEY`、`XFYUN_APP_ID`、`XFYUN_API_KEY` 或 `XFYUN_API_SECRET`。确认变量是在运行 Node 服务的同一个进程环境中设置的。

### 对话场景没有跳转到预期结局

检查当前场景的 `flow.mode` 是否为 `score`，并确认 `scoreRoutes` 的分数区间覆盖了当前说服度。还要确认场景组配置了 `defaultEndingSceneId`，否则对话结束后可能停留在当前流程。

### MOV 透明通道显示不稳定

透明 MOV 的兼容性取决于浏览器和系统解码器。Chrome/Edge 中更推荐使用 WebM alpha。

### 修改场景后线上没有变化

场景数据写在 `data/scene-layout-db.json`，上传素材写在 `uploads/`。部署或迁移时需要同步这两个目录；如果只更新代码，线上场景数据不会自动变化。

## 维护备注

- 新增场景字段时，需要同时检查 `serializeLayout()`、`applySceneLayout()`、`normalizeLayoutPayload()` 和 viewer/final 播放入口。
- 新增媒体类型时，需要同步更新前端支持列表、后端 `mediaExtensions`/`mimeTypes`，并确认浏览器可直接解码。
- 修改对话逻辑时，需要同时关注 `directorConfig.conversation`、`/api/conversation-cue`、`scoreRoutes` 和最终页的合并场景组逻辑。
- `index` 和 `conver` 是两套数据空间。普通编辑器和对话编辑器可以互相引用场景组，但保存时仍回写各自空间。
- 调试最终页时优先使用 `/api/layout?list=1&details=1&space=index` 和 `/api/layout?list=1&details=1&space=conver` 查看完整场景数据。
