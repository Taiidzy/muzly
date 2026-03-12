import os
from pathlib import Path

# Base directory
BASE_DIR = Path(__file__).resolve().parent

# Media directories
MEDIA_ROOT = os.getenv("MEDIA_ROOT", BASE_DIR / "media")
COVERS_ROOT = os.getenv("COVERS_ROOT", BASE_DIR / "covers")
IMPORT_DROP = os.getenv("IMPORT_DROP", BASE_DIR / "import_drop")

# Create directories
for dir_path in [MEDIA_ROOT, COVERS_ROOT, IMPORT_DROP]:
    dir_path.mkdir(parents=True, exist_ok=True)

# Database
DATABASE_URL = os.getenv("DATABASE_URL", f"sqlite+aiosqlite:///{BASE_DIR}/muzly.db")

# JWT Settings
JWT_SECRET = os.getenv("JWT_SECRET", "super-secret-key-change-in-production")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# CORS
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost,http://localhost:3000,http://localhost:8080").split(",")

# File upload limits
MAX_UPLOAD_SIZE = int(os.getenv("MAX_UPLOAD_SIZE", "104857600"))  # 100MB
ALLOWED_AUDIO_TYPES = ["audio/mpeg", "audio/mp4", "audio/flac", "audio/wav", "audio/ogg"]
ALLOWED_AUDIO_EXTENSIONS = [".mp3", ".m4a", ".flac", ".wav", ".ogg"]

# Admin credentials (for initial setup)
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin")
