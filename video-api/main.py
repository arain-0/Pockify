"""
Pockify Video API - Google Cloud Run
yt-dlp + Custom Instagram/TikTok scraping
"""

import os
import re
import asyncio
import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import yt_dlp

app = FastAPI(
    title="Pockify Video API",
    description="Video download API for social media platforms",
    version="1.5.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class VideoRequest(BaseModel):
    url: str

def detect_platform(url: str) -> str:
    url_lower = url.lower()
    if 'tiktok.com' in url_lower or 'vm.tiktok.com' in url_lower:
        return 'tiktok'
    elif 'instagram.com' in url_lower:
        return 'instagram'
    elif 'facebook.com' in url_lower or 'fb.watch' in url_lower:
        return 'facebook'
    elif 'twitter.com' in url_lower or 'x.com' in url_lower:
        return 'twitter'
    elif 'youtube.com' in url_lower or 'youtu.be' in url_lower:
        return 'youtube'
    elif 'pinterest.com' in url_lower or 'pin.it' in url_lower:
        return 'pinterest'
    elif 'reddit.com' in url_lower:
        return 'reddit'
    elif 'vimeo.com' in url_lower:
        return 'vimeo'
    return 'unknown'

# =============================================
# Instagram - Multiple Methods
# =============================================
async def fetch_instagram_direct(url: str) -> dict:
    """Instagram video URL cek - multiple methods"""
    # Clean URL
    clean_url = url.split('?')[0]
    if not clean_url.endswith('/'):
        clean_url += '/'

    # Extract shortcode
    shortcode = None
    reel_match = re.search(r'/reel/([^/]+)', clean_url)
    p_match = re.search(r'/p/([^/]+)', clean_url)
    shortcode = reel_match.group(1) if reel_match else (p_match.group(1) if p_match else None)

    # Method 1: DDInstagram API
    if shortcode:
        try:
            print(f"Instagram: Trying DDInstagram for {shortcode}")
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(
                    f'https://d.ddinstagram.com/reel/{shortcode}',
                    headers={
                        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
                        'Accept': 'text/html,*/*',
                    },
                    follow_redirects=True
                )
                if response.status_code == 200:
                    html = response.text
                    # Find video source
                    video_match = re.search(r'<source[^>]+src="([^"]+)"[^>]+type="video', html)
                    if video_match:
                        video_url = video_match.group(1)
                        print(f"Instagram: DDInstagram success")
                        return {
                            'success': True,
                            'platform': 'instagram',
                            'title': 'Instagram Reel',
                            'thumbnail': '',
                            'duration': 0,
                            'download_url': video_url,
                            'qualities': [],
                            'author': '',
                        }
        except Exception as e:
            print(f"Instagram DDInstagram error: {e}")

    # Method 2: Direct page scraping
    try:
        print(f"Instagram: Trying direct scraping")
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                clean_url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    'Accept-Language': 'en-US,en;q=0.9',
                    'Sec-Fetch-Mode': 'navigate',
                },
                follow_redirects=True
            )

            if response.status_code == 200:
                html = response.text

                # Pattern 1: video_url in JSON
                video_match = re.search(r'"video_url":"([^"]+)"', html)
                if video_match:
                    video_url = video_match.group(1).replace('\\u0026', '&').replace('\\/', '/')
                    print(f"Instagram: Found video_url in JSON")
                    return {
                        'success': True,
                        'platform': 'instagram',
                        'title': 'Instagram Video',
                        'thumbnail': '',
                        'duration': 0,
                        'download_url': video_url,
                        'qualities': [],
                        'author': '',
                    }

                # Pattern 2: contentUrl in JSON-LD
                content_match = re.search(r'"contentUrl":"([^"]+)"', html)
                if content_match:
                    video_url = content_match.group(1).replace('\\u0026', '&').replace('\\/', '/')
                    print(f"Instagram: Found contentUrl")
                    return {
                        'success': True,
                        'platform': 'instagram',
                        'title': 'Instagram Video',
                        'thumbnail': '',
                        'duration': 0,
                        'download_url': video_url,
                        'qualities': [],
                        'author': '',
                    }

                # Pattern 3: og:video meta tag
                og_video_match = re.search(r'<meta[^>]+property="og:video"[^>]+content="([^"]+)"', html)
                if og_video_match:
                    video_url = og_video_match.group(1)
                    print(f"Instagram: Found og:video")
                    return {
                        'success': True,
                        'platform': 'instagram',
                        'title': 'Instagram Video',
                        'thumbnail': '',
                        'duration': 0,
                        'download_url': video_url,
                        'qualities': [],
                        'author': '',
                    }

    except Exception as e:
        print(f"Instagram direct scraping error: {e}")

    # Method 3: Embed page
    try:
        print(f"Instagram: Trying embed page")
        async with httpx.AsyncClient(timeout=15.0) as client:
            embed_url = clean_url.replace('/reel/', '/p/').rstrip('/') + '/embed/'
            response = await client.get(
                embed_url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'Accept': 'text/html,*/*',
                },
                follow_redirects=True
            )
            if response.status_code == 200:
                html = response.text
                # Find video in embed
                video_match = re.search(r'"video_url":"([^"]+)"', html)
                if video_match:
                    video_url = video_match.group(1).replace('\\u0026', '&').replace('\\/', '/')
                    print(f"Instagram: Found in embed")
                    return {
                        'success': True,
                        'platform': 'instagram',
                        'title': 'Instagram Video',
                        'thumbnail': '',
                        'duration': 0,
                        'download_url': video_url,
                        'qualities': [],
                        'author': '',
                    }
    except Exception as e:
        print(f"Instagram embed error: {e}")

    return None


# =============================================
# Instagram - yt-dlp with better options
# =============================================
def get_instagram_ytdlp(url: str) -> dict:
    """Use yt-dlp for Instagram with optimized settings"""
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'format': 'best[ext=mp4]/best',
        'socket_timeout': 30,
        'retries': 3,
        'http_headers': {
            'User-Agent': 'Instagram 275.0.0.27.98 Android (33/13; 420dpi; 1080x2400; samsung; SM-G991B; o1s; exynos2100; en_US; 458229258)',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
        },
        'extractor_args': {
            'instagram': {
                'skip': ['dash'],
            }
        },
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            if info is None:
                return {'error': 'Video bilgisi alinamadi'}

            download_url = None
            if 'formats' in info and info['formats']:
                for fmt in info['formats']:
                    if fmt.get('url'):
                        download_url = fmt['url']
                        if fmt.get('ext') == 'mp4':
                            break

            if not download_url:
                download_url = info.get('url')

            if not download_url:
                return {'error': 'Indirme URL bulunamadi'}

            return {
                'success': True,
                'platform': 'instagram',
                'title': info.get('title', 'Instagram Video'),
                'thumbnail': info.get('thumbnail', ''),
                'duration': info.get('duration', 0) or 0,
                'download_url': download_url,
                'qualities': [],
                'author': info.get('uploader', ''),
            }

    except Exception as e:
        return {'error': f'Video alinamadi: {str(e)[:100]}'}

# =============================================
# TikTok - TikWM API
# =============================================
async def fetch_tiktok_tikwm(url: str) -> dict:
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                'https://www.tikwm.com/api/',
                data={'url': url, 'hd': 1},
                headers={'Content-Type': 'application/x-www-form-urlencoded'}
            )

            if response.status_code == 200:
                data = response.json()
                if data.get('code') == 0 and data.get('data'):
                    video_data = data['data']
                    download_url = video_data.get('hdplay') or video_data.get('play')
                    if download_url:
                        return {
                            'success': True,
                            'platform': 'tiktok',
                            'title': video_data.get('title', 'TikTok Video'),
                            'thumbnail': video_data.get('cover', ''),
                            'duration': video_data.get('duration', 0),
                            'download_url': download_url,
                            'qualities': [],
                            'author': video_data.get('author', {}).get('nickname', ''),
                        }
    except Exception as e:
        print(f"TikWM error: {e}")
    return None

# =============================================
# yt-dlp for YouTube/Reddit/Vimeo
# =============================================
def get_video_ytdlp(url: str, platform: str) -> dict:
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'extract_flat': False,
        'format': 'best[ext=mp4]/best',
        'socket_timeout': 30,
        'retries': 3,
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
        },
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            if info is None:
                return {'error': 'Video bilgisi alinamadi'}

            download_url = None
            qualities = []

            if 'formats' in info and info['formats']:
                for fmt in info['formats']:
                    if fmt.get('ext') == 'mp4' and fmt.get('url'):
                        height = fmt.get('height', 0)
                        if height:
                            qualities.append({
                                'quality': f"{height}p",
                                'url': fmt['url'],
                                'filesize': fmt.get('filesize', 0)
                            })

                if qualities:
                    qualities.sort(key=lambda x: int(x['quality'].replace('p', '')), reverse=True)
                    download_url = qualities[0]['url']
                else:
                    for fmt in info['formats']:
                        if fmt.get('url'):
                            download_url = fmt['url']
                            break

            if not download_url:
                download_url = info.get('url')

            if not download_url:
                return {'error': 'Indirme URL bulunamadi'}

            return {
                'success': True,
                'platform': platform,
                'title': info.get('title', f'{platform.capitalize()} Video'),
                'thumbnail': info.get('thumbnail', ''),
                'duration': info.get('duration', 0) or 0,
                'download_url': download_url,
                'qualities': qualities[:4],
                'author': info.get('uploader', info.get('channel', '')),
            }

    except Exception as e:
        return {'error': f'Video alinamadi: {str(e)[:100]}'}

# =============================================
# Endpoints
# =============================================
@app.get("/")
async def root():
    return {
        "status": "ok",
        "service": "Pockify Video API",
        "version": "1.4.0",
        "platforms": ["youtube", "instagram", "tiktok", "twitter", "facebook", "reddit", "vimeo"]
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/api/video")
async def get_video(url: str = Query(..., description="Video URL")):
    if not url:
        raise HTTPException(status_code=400, detail="URL gerekli")

    url = url.strip()
    platform = detect_platform(url)

    if platform == 'unknown':
        raise HTTPException(status_code=400, detail="Desteklenmeyen platform")

    result = None

    # Instagram - Multiple fallback methods
    if platform == 'instagram':
        result = await fetch_instagram_direct(url)
        if result is None:
            # Fallback to Instagram-specific yt-dlp
            print("Instagram: Direct scraping failed, trying yt-dlp")
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(None, get_instagram_ytdlp, url)
        if result is None or (isinstance(result, dict) and 'error' in result):
            # Last fallback to generic yt-dlp
            print("Instagram: Specific yt-dlp failed, trying generic")
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(None, get_video_ytdlp, url, platform)

    # TikTok - TikWM API
    elif platform == 'tiktok':
        result = await fetch_tiktok_tikwm(url)

    # YouTube/Reddit/Vimeo - yt-dlp
    elif platform in ['youtube', 'reddit', 'vimeo']:
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(None, get_video_ytdlp, url, platform)

    # Twitter/Facebook - yt-dlp fallback
    else:
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(None, get_video_ytdlp, url, platform)

    if result is None:
        return JSONResponse(
            status_code=200,
            content={
                "success": False,
                "error": f"{platform.capitalize()} videosu alinamadi",
                "platform": platform
            }
        )

    if 'error' in result:
        return JSONResponse(
            status_code=200,
            content={
                "success": False,
                "error": result['error'],
                "platform": platform
            }
        )

    return result

@app.post("/api/video")
async def post_video(request: VideoRequest):
    return await get_video(request.url)

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
