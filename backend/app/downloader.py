import requests
import json
from bs4 import BeautifulSoup
import time
import re
from pathlib import Path
from urllib.parse import urlparse

HITMO_URL = "https://rus.hitmotop.com/search"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9",
    "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
    "Referer": "https://rus.hitmotop.com/",
    "Connection": "keep-alive"
}

def search_tracks_in_json(path):

    track_list = []

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    tracks = data["result"]["tracks"]

    for track in tracks:
        # Название песни
        track_title = track.get("title", "-")

        # Первый артист
        artist = track["artists"][0]
        artist_name = artist.get("name", "-")
        artist_avatar = artist.get("cover", {}).get("uri", "-")

        # Первый альбом
        album = track["albums"][0]
        album_title = album.get("title", "-")
        album_cover = album.get("coverUri", "-")

        # Обложка самого трека
        track_cover = track.get("coverUri", "-")

        print(f"Песня: {track_title}")
        print(f"Исполнитель: {artist_name}")
        print(f"Альбом: {album_title}")
        print(f"Аватар исполнителя: {artist_avatar}")
        print(f"Обложка альбома: {album_cover}")
        print(f"Обложка трека: {track_cover}")
        print("-" * 40)

        track_obj = {
            "title": track_title,
            "artist": artist_name,
            "album": album_title,
            "artist_avatar": artist_avatar,
            "album_cover": album_cover,
            "track_cover": track_cover
        }

        track_list.append(track_obj)

    return track_list

def get_track_hitmo(title, artist, dest_dir=None):

    params = {"q": f"{title} - {artist}"}

    response = requests.get(HITMO_URL, params=params, headers=HEADERS)

    if response.status_code != 200:
        print("Ошибка запроса:", response.status_code)
        return

    soup = BeautifulSoup(response.text, "html.parser")

    tracks = soup.select("li.track")

    for track in tracks:

        site_title = track.select_one(".track__title").text.strip()
        site_artist = track.select_one(".track__desc").text.strip()

        # сравниваем с тем что ищем
        if site_title.lower() == title.lower() and site_artist.lower() == artist.lower():

            download_btn = track.select_one(".track__download-btn")

            if download_btn:
                mp3_url = download_btn["href"]
                print("Найден трек:")
                print(title, "-", artist)
                print("MP3:", mp3_url)
                print("-" * 40)
                filename = download_track(mp3_url, title, artist, dest_dir=dest_dir)
                return mp3_url, filename


    print("Трек не найден:", title, "-", artist)
    return None, None

def download_track(url, title, artist, dest_dir=None):

    filename = f"{safe_filename(artist)} - {safe_filename(title)}.mp3"
    if dest_dir:
        dest_path = Path(dest_dir)
        dest_path.mkdir(parents=True, exist_ok=True)
        filename = str(dest_path / filename)

    response = requests.get(url, stream=True, headers=HEADERS)

    if response.status_code == 200:
        with open(filename, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        print("Скачано:", filename)
        return filename
    else:
        print("Ошибка скачивания:", response.status_code)
        return None

def safe_filename(text):
    return re.sub(r'[\\/*?:"<>|]', "", text)

def ensure_https(url):
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

def _guess_image_extension(url, content_type):
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

def download_image(url, dest_dir, base_name):
    full_url = ensure_https(url)
    if not full_url:
        return None

    dest_path = Path(dest_dir)
    dest_path.mkdir(parents=True, exist_ok=True)

    response = requests.get(full_url, stream=True, headers=HEADERS)
    if response.status_code != 200:
        print("Ошибка скачивания изображения:", response.status_code)
        print(full_url)
        return None

    ext = _guess_image_extension(full_url, response.headers.get("Content-Type", ""))
    filename = str(dest_path / f"{safe_filename(base_name)}{ext}")

    with open(filename, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)

    print("Скачано изображение:", filename)
    return filename

def download_artist_avatar(url, artist_name, dest_dir):
    return download_image(url, dest_dir, artist_name)

def download_album_cover(url, album_title, dest_dir):
    return download_image(url, dest_dir, album_title)

def download_track_cover(url, track_title, dest_dir):
    return download_image(url, dest_dir, track_title)

def main(json_path, dest_dir=None):
    result = search_tracks_in_json(json_path)

    for track in result:
        # Скачиваем трек
        mp3_url, filename = get_track_hitmo(track["title"], track["artist"], dest_dir=dest_dir)

        # Скачиваем аватар исполнителя
        if track["artist_avatar"] and track["artist_avatar"] != "-":
            download_artist_avatar(track["artist_avatar"], track["artist"], dest_dir or "covers")

        # Скачиваем обложку альбома
        if track["album_cover"] and track["album_cover"] != "-":
            download_album_cover(track["album_cover"], f"{track['artist']} - {track['album']}", dest_dir or "covers")

        # Скачиваем обложку трека (если отличается от обложки альбома)
        if track["track_cover"] and track["track_cover"] != "-" and track["track_cover"] != track["album_cover"]:
            download_track_cover(track["track_cover"], f"{track['artist']} - {track['title']}", dest_dir or "covers")

        time.sleep(1)

main("exemple.json")