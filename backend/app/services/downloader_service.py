"""
Async downloader service adapted from downloader.py
Uses asyncio.to_thread for synchronous operations to avoid blocking the event loop.
"""
import asyncio
import aiofiles
import httpx
import re
import json
from pathlib import Path
from typing import Optional, List, Dict, Any
from bs4 import BeautifulSoup
from urllib.parse import urlparse
import logging

from app.config import MEDIA_ROOT, COVERS_ROOT

logger = logging.getLogger(__name__)

HITMO_URL = "https://rus.hitmotop.com/search"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
    "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
    "Referer": "https://rus.hitmotop.com/",
    "Connection": "keep-alive"
}


def safe_filename(text: str) -> str:
    """Remove invalid characters from filename."""
    return re.sub(r'[\\/*?:"<>|]', '', text)


def ensure_https(url: str) -> Optional[str]:
    """Ensure URL uses HTTPS and handle Yandex Music image URLs."""
    if not url or url == "-":
        return None
    
    if url.startswith("http://") or url.startswith("https://"):
        full_url = url
    else:
        full_url = f"https://{url.lstrip('/')}"
    
    # Replace %% with image size for Yandex Music URLs
    if "%%" in full_url:
        full_url = full_url.replace("%%", "800x800")
    
    return full_url


def _guess_image_extension(url: str, content_type: str) -> str:
    """Guess image file extension from content-type or URL."""
    if content_type:
        if "image/png" in content_type:
            return ".png"
        if "image/webp" in content_type:
            return ".webp"
        if "image/jpeg" in content_type or "image/jpg" in content_type:
            return ".jpg"
    
    if url:
        path = urlparse(url).path
        suffix = Path(path).suffix
        if suffix:
            return suffix
    
    return ".jpg"


def search_tracks_in_json_sync(path: str) -> List[Dict[str, Any]]:
    """
    Synchronous version of search_tracks_in_json.
    Parse JSON file and extract track information.
    """
    track_list = []
    
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    tracks = data.get("result", {}).get("tracks", [])
    
    for track in tracks:
        track_title = track.get("title", "-")
        
        # First artist
        artists = track.get("artists", [])
        artist = artists[0] if artists else {}
        artist_name = artist.get("name", "-")
        artist_avatar = artist.get("cover", {}).get("uri", "-")
        
        # First album
        albums = track.get("albums", [])
        album = albums[0] if albums else {}
        album_title = album.get("title", "-")
        album_cover = album.get("coverUri", "-")
        
        # Track cover
        track_cover = track.get("coverUri", "-")
        
        track_obj = {
            "title": track_title,
            "artist": artist_name,
            "album": album_title,
            "artist_avatar": artist_avatar,
            "album_cover": album_cover,
            "track_cover": track_cover,
            "duration_ms": track.get("durationMs"),
        }
        
        track_list.append(track_obj)
    
    return track_list


def get_track_hitmo_sync(title: str, artist: str, dest_dir: Optional[str] = None) -> tuple[Optional[str], Optional[str]]:
    """
    Synchronous version of get_track_hitmo.
    Search for track on Hitmo and download it.
    """
    params = {"q": f"{title} - {artist}"}
    
    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.get(HITMO_URL, params=params, headers=HEADERS)
            
            if response.status_code != 200:
                logger.error("Ошибка запроса: %s", response.status_code)
                return None, None
            
            soup = BeautifulSoup(response.text, "html.parser")
            tracks = soup.select("li.track")
            
            for track in tracks:
                site_title_elem = track.select_one(".track__title")
                site_artist_elem = track.select_one(".track__desc")
                
                if not site_title_elem or not site_artist_elem:
                    continue
                
                site_title = site_title_elem.text.strip()
                site_artist = site_artist_elem.text.strip()
                
                # Compare with search query
                if site_title.lower() == title.lower() and site_artist.lower() == artist.lower():
                    download_btn = track.select_one(".track__download-btn")
                    
                    if download_btn and "href" in download_btn.attrs:
                        mp3_url = download_btn["href"]
                        logger.info("Найден трек: %s - %s", title, artist)
                        logger.info("MP3 URL: %s", mp3_url)
                        
                        filename = download_track_sync(mp3_url, title, artist, dest_dir=dest_dir)
                        return mp3_url, filename
            
            logger.warning("Трек не найден: %s - %s", title, artist)
            return None, None
    
    except Exception as e:
        logger.error("Ошибка при поиске трека %s - %s: %s", title, artist, e)
        return None, None


def download_track_sync(url: str, title: str, artist: str, dest_dir: Optional[str] = None) -> Optional[str]:
    """
    Synchronous version of download_track.
    Download track from URL.
    """
    filename = f"{safe_filename(artist)} - {safe_filename(title)}.mp3"
    
    if dest_dir:
        dest_path = Path(dest_dir)
        dest_path.mkdir(parents=True, exist_ok=True)
        filename = str(dest_path / filename)
    else:
        filename = str(MEDIA_ROOT / filename)
    
    try:
        with httpx.Client(timeout=60.0, follow_redirects=True) as client:
            with client.stream("GET", url, headers=HEADERS) as response:
                if response.status_code == 200:
                    with open(filename, "wb") as f:
                        for chunk in response.iter_bytes(chunk_size=8192):
                            f.write(chunk)
                    
                    logger.info("Скачано: %s", filename)
                    return filename
                else:
                    logger.error("Ошибка скачивания: %s", response.status_code)
                    return None
    
    except Exception as e:
        logger.error("Ошибка при скачивании трека: %s", e)
        return None


def download_image_sync(url: str, dest_dir: Path, base_name: str) -> Optional[str]:
    """
    Synchronous version of download_image.
    Download image from URL.
    """
    full_url = ensure_https(url)
    if not full_url:
        return None
    
    dest_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        with httpx.Client(timeout=30.0, follow_redirects=True) as client:
            with client.stream("GET", full_url, headers=HEADERS) as response:
                if response.status_code != 200:
                    logger.error("Ошибка скачивания изображения: %s", response.status_code)
                    logger.debug("URL: %s", full_url)
                    return None
                
                ext = _guess_image_extension(full_url, response.headers.get("Content-Type", ""))
                filename = str(dest_dir / f"{safe_filename(base_name)}{ext}")
                
                with open(filename, "wb") as f:
                    for chunk in response.iter_bytes(chunk_size=8192):
                        f.write(chunk)
                
                logger.info("Скачано изображение: %s", filename)
                return filename
    
    except Exception as e:
        logger.error("Ошибка при скачивании изображения: %s", e)
        return None


# ============ Async wrappers ============

async def search_tracks_in_json(path: str) -> List[Dict[str, Any]]:
    """Async wrapper for search_tracks_in_json."""
    return await asyncio.to_thread(search_tracks_in_json_sync, str(path))


async def get_track_hitmo(title: str, artist: str, dest_dir: Optional[str] = None) -> tuple[Optional[str], Optional[str]]:
    """Async wrapper for get_track_hitmo."""
    return await asyncio.to_thread(get_track_hitmo_sync, title, artist, dest_dir)


async def download_track(url: str, title: str, artist: str, dest_dir: Optional[str] = None) -> Optional[str]:
    """Async wrapper for download_track."""
    return await asyncio.to_thread(download_track_sync, url, title, artist, dest_dir)


async def download_image(url: str, dest_dir: Path, base_name: str) -> Optional[str]:
    """Async wrapper for download_image."""
    return await asyncio.to_thread(download_image_sync, url, dest_dir, base_name)


# ============ High-level async functions ============

async def download_artist_avatar(url: str, artist_name: str, dest_dir: Optional[Path] = None) -> Optional[str]:
    """Download artist avatar."""
    if dest_dir is None:
        dest_dir = COVERS_ROOT
    return await download_image(url, dest_dir, artist_name)


async def download_album_cover(url: str, album_title: str, dest_dir: Optional[Path] = None) -> Optional[str]:
    """Download album cover."""
    if dest_dir is None:
        dest_dir = COVERS_ROOT
    return await download_image(url, dest_dir, album_title)


async def download_track_cover(url: str, track_title: str, dest_dir: Optional[Path] = None) -> Optional[str]:
    """Download track cover."""
    if dest_dir is None:
        dest_dir = COVERS_ROOT
    return await download_image(url, dest_dir, track_title)


async def process_track_download(
    track_data: Dict[str, Any],
    media_dir: Optional[Path] = None,
    covers_dir: Optional[Path] = None
) -> Dict[str, Any]:
    """
    Process a single track download including audio and covers.
    Returns updated track data with file paths.
    """
    title = track_data.get("title", "Unknown")
    artist = track_data.get("artist", "Unknown")
    album = track_data.get("album", "Unknown")
    
    result = {
        **track_data,
        "file_path": None,
        "cover_path": None,
        "error": None
    }
    
    # Download track
    mp3_url, filename = await get_track_hitmo(title, artist, dest_dir=str(media_dir) if media_dir else None)
    
    if filename:
        result["file_path"] = filename
    else:
        result["error"] = f"Failed to download track: {title} - {artist}"
        return result
    
    # Download album cover
    album_cover = track_data.get("album_cover")
    if album_cover and album_cover != "-":
        cover_filename = await download_album_cover(
            album_cover,
            f"{artist} - {album}",
            covers_dir or COVERS_ROOT
        )
        if cover_filename:
            result["cover_path"] = cover_filename
    
    # Download track cover if different from album cover
    track_cover = track_data.get("track_cover")
    if track_cover and track_cover != "-" and track_cover != album_cover:
        await download_track_cover(
            track_cover,
            f"{artist} - {title}",
            covers_dir or COVERS_ROOT
        )
    
    # Download artist avatar
    artist_avatar = track_data.get("artist_avatar")
    if artist_avatar and artist_avatar != "-":
        await download_artist_avatar(
            artist_avatar,
            artist,
            covers_dir or COVERS_ROOT
        )
    
    return result
