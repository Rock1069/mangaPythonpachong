# 漫画柜阅读器 (Manga Reader)

基于 Python 的漫画柜 (`manhuagui.com`) 爬虫 + Web API 服务。支持：
- 📱 手机版页面爬取（列表、详情、章节、图片解密）
- 🔍 漫画搜索
- 🖼️ 图片代理（绕过 CDN Referer 限制）
- 🌐 内置 Web 阅读器（Vue3 单页应用）
- 🐧 Debian VPS 一键部署

## 目录结构

```
mangaPythonpachong/
├── config.py              # 全局配置（支持环境变量）
├── requirements.txt       # Python 依赖
├── deploy.sh              # Debian 一键部署脚本
├── nginx-example.conf     # Nginx 反向代理配置示例
├── src/
│   ├── __init__.py
│   ├── decrypt.py         # 章节图片URL解密（LZString + 字典替换）
│   ├── client.py          # HTTP 客户端（重试、限速、UA伪装）
│   └── spider.py          # 爬虫（列表/详情/章节/搜索 + 缓存）
├── app/
│   ├── __init__.py
│   └── main.py            # FastAPI 服务入口
└── static/
    └── index.html         # Web 阅读器
```

## 快速开始（本地开发）

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 启动服务
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 3. 访问
# API:  http://localhost:8000/
# 阅读器: http://localhost:8000/
# 文档:  http://localhost:8000/docs  (FastAPI 自动生成)
```

## Debian VPS 部署

### 一键部署

```bash
# 克隆项目到 VPS
git clone <your-repo> /tmp/manga-reader
cd /tmp/manga-reader

# 运行部署脚本
sudo bash deploy.sh
```

### 手动部署

```bash
# 1. 安装系统依赖
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx

# 2. 创建专用用户
sudo useradd -r -s /bin/false -m manga

# 3. 部署代码
sudo mkdir -p /opt/manga-reader
sudo cp -r . /opt/manga-reader/
sudo chown -R manga:manga /opt/manga-reader

# 4. 创建虚拟环境并安装依赖
cd /opt/manga-reader
sudo -u manga python3 -m venv venv
sudo -u manga venv/bin/pip install -r requirements.txt

# 5. 创建 systemd 服务
sudo cp manga-reader.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now manga-reader

# 6. （可选）配置 Nginx 反向代理
sudo cp nginx-example.conf /etc/nginx/sites-available/manga-reader
sudo ln -s /etc/nginx/sites-available/manga-reader /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### 服务管理

```bash
# 查看状态
sudo systemctl status manga-reader

# 查看日志
sudo journalctl -u manga-reader -f

# 重启
sudo systemctl restart manga-reader

# 停止
sudo systemctl stop manga-reader
```

## API 文档

### `GET /api/list` — 漫画列表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `category` | string | `lianzai` | 分类：lianzai / wanjie / japan / korea / china / rexue / ... |
| `sort` | string | `""` | 排序：空=添加时间, `update`=更新时间, `view`=浏览次数 |
| `page` | int | `1` | 页码 |

```json
{
  "items": [
    {
      "id": 60523,
      "title": "事业狂JK萌音学姐",
      "cover": "https://...",
      "author": "椋木ななつ",
      "status": "连载",
      "latest_chapter": "第01话",
      "url": "https://m.manhuagui.com/comic/60523/"
    }
  ],
  "has_next": true,
  "page": 1
}
```

### `GET /api/comic/{comic_id}` — 漫画详情 + 章节列表

```json
{
  "id": 60523,
  "title": "事业狂JK萌音学姐",
  "cover": "https://...",
  "authors": ["椋木ななつ"],
  "categories": ["搞笑", "百合"],
  "status": "连载",
  "description": "...",
  "chapters": [
    { "id": 12345, "name": "第01话", "url": "/comic/60523/12345.html" }
  ]
}
```

### `GET /api/comic/{comic_id}/{chapter_id}` — 章节图片列表

```json
{
  "comic_id": 60523,
  "chapter_id": 12345,
  "chapter_name": "第01话",
  "total": 20,
  "pages": [
    {
      "index": 0,
      "filename": "001.jpg.webp",
      "raw_url": "https://i.hamreus.com/ps3/s/.../001.jpg.webp?e=...&m=...",
      "proxy_url": "/api/proxy/image?url=...&e=...&m=..."
    }
  ]
}
```

### `GET /api/search?q={keyword}` — 搜索

```json
{
  "items": [...],
  "has_next": false,
  "page": 1,
  "keyword": "keyword"
}
```

### `GET /api/proxy/image?url={url}&e={e}&m={m}` — 图片代理

直接返回图片二进制流。APP/网页通过此接口加载图片，避免 CDN 的 Referer 限制。

## APP 接入指南

将你的漫画阅读APP的**服务器地址**配置为 VPS 的 API 地址即可：

```
http://your-vps-ip:8000
# 或配置了 Nginx + 域名后：
https://your-domain.com
```

### Android APP 集成示例（WebView）

```java
// 直接将 WebView 指向阅读器地址
webView.loadUrl("http://your-vps-ip:8000/");
```

### 自定义 APP 集成（JSON API）

按上述 API 文档调用接口，图片通过 `proxy_url` 加载。

## 环境变量配置

启动服务时可设置以下环境变量覆盖默认值：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MANGA_HOST` | `0.0.0.0` | 监听地址 |
| `MANGA_PORT` | `8000` | 监听端口 |
| `MANGA_PAGE_DELAY` | `1.0` | 请求间隔（秒） |
| `MANGA_TIMEOUT` | `30` | 请求超时（秒） |
| `MANGA_MAX_RETRIES` | `3` | 最大重试次数 |
| `MANGA_CACHE_LIST_TTL` | `3600` | 列表缓存（秒） |
| `MANGA_CACHE_CHAPTER_TTL` | `86400` | 章节缓存（秒） |
| `MANGA_IMG_CHANNEL` | `i` | 图片CDN通道（i/us/eu） |

```bash
# systemd 中修改环境变量
sudo systemctl edit manga-reader
```

## 注意事项

⚠️ **仅供个人学习研究使用，请勿用于商业用途。**
- 请求间隔默认 1 秒，过短可能被源站封 IP
- 图片通过代理服务转发，会消耗 VPS 带宽
- 如遇到 403 错误，说明 IP 被暂时限制，等待一段时间后自动恢复
- 网站结构可能随时变化，如解密失败请检查是否需要更新正则匹配

## 技术要点

漫画柜使用 **LZString + 字典替换** 混淆方案保护图片URL：

1. 章节HTML中包含混淆JS：`}('SMG.reader(...)', 62, 123, 'base64...')`
2. LZString解压 `data` → `|` 分割得到字符串数组
3. 进制转换构建字典 → 替换混淆token
4. 提取JSON → 得到 `{files, path, sl: {e, m}}`
5. 完整图片URL：`https://i.hamreus.com{path}{file}?e={e}&m={m}`

参考开源实现：[HSSLC/manhuagui-dlr](https://github.com/HSSLC/manhuagui-dlr)、[hayeah/manhuagui](https://github.com/hayeah/manhuagui)
