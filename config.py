"""
项目配置模块
可通过环境变量覆盖默认值
"""
import os

# --- 服务器配置 ---
HOST = os.getenv("MANGA_HOST", "0.0.0.0")
PORT = int(os.getenv("MANGA_PORT", "8000"))

# --- 爬虫配置 ---
# 请求间隔（秒），避免被封IP
PAGE_DELAY = float(os.getenv("MANGA_PAGE_DELAY", "1.0"))
# 请求超时（秒）
REQUEST_TIMEOUT = int(os.getenv("MANGA_TIMEOUT", "30"))
# 最大重试次数
MAX_RETRIES = int(os.getenv("MANGA_MAX_RETRIES", "3"))
# User-Agent（模拟浏览器）
USER_AGENT = os.getenv(
    "MANGA_USER_AGENT",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
)

# --- 缓存配置 ---
# 列表缓存时间（秒），默认1小时
CACHE_LIST_TTL = int(os.getenv("MANGA_CACHE_LIST_TTL", "3600"))
# 章节缓存时间（秒），默认24小时
CACHE_CHAPTER_TTL = int(os.getenv("MANGA_CACHE_CHAPTER_TTL", "86400"))

# --- 图片代理配置 ---
# 图片CDN通道（i/us/eu）
IMG_CHANNEL = os.getenv("MANGA_IMG_CHANNEL", "i")
IMG_BASE = "hamreus.com"
IMG_CDN = f"https://{IMG_CHANNEL}.{IMG_BASE}"

# --- 站点配置 ---
MANGA_SITE = os.getenv("MANGA_SITE", "https://m.manhuagui.com")
MANGA_SITE_PC = os.getenv("MANGA_SITE_PC", "https://www.manhuagui.com")
