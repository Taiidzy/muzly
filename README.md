# Muzly - Self-hosted Media Platform

A FastAPI-based self-hosted music streaming and management platform with track import capabilities from JSON files.

## Features

- **Track Import from JSON**: Upload JSON files with track metadata and automatically download tracks and covers
- **Manual Track Upload**: Upload audio files (MP3, M4A, FLAC, WAV, OGG) with metadata
- **Streaming**: Stream music with Range header support (206 Partial Content)
- **Playlists**: Create, edit, and manage playlists with track ordering
- **Favorites**: Mark and manage favorite tracks
- **Single-User Authentication**: JWT-based authentication with credentials from `.env`
- **Search & Filter**: Search tracks by title, artist, album; filter by source
- **Admin Features**: Track management, import task monitoring
- **Docker Ready**: Full Docker Compose setup for easy deployment
- **Auto SSL**: Built-in Let's Encrypt certificate management

## Quick Deploy (Production)

### One-Command Deployment

```bash
# Clone and deploy (requires Docker, Certbot)
sudo ./deploy.sh
```

This script will:
- Prompt for your domain, username, and password
- Generate secure `.env` with JWT secret
- Start all Docker containers
- Obtain SSL certificate via Let's Encrypt
- Configure nginx automatically

After deployment:
- **Admin panel**: `https://your-domain/admin`
- **API**: `https://your-domain/api`

### Manual Setup

```bash
# Quick setup if repo is already cloned
./setup.sh
```

## Quick Start (Development)

- **Backend**: FastAPI, Uvicorn (Python 3.11+)
- **Database**: SQLite (default) or PostgreSQL
- **ORM**: SQLModel (SQLAlchemy + Pydantic)
- **Authentication**: JWT (python-jose)
- **HTTP Client**: httpx (async)
- **Parsing**: BeautifulSoup4, lxml
- **Testing**: pytest, pytest-asyncio, httpx

## Project Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI application entry point
│   ├── config.py            # Configuration and environment variables
│   ├── database.py          # Database connection and session management
│   ├── models.py            # SQLModel database models
│   ├── schemas.py           # Pydantic schemas for API
│   ├── auth.py              # Authentication utilities
│   ├── routers/
│   │   ├── auth.py          # Authentication endpoints
│   │   ├── tracks.py        # Track CRUD and streaming
│   │   ├── playlists.py     # Playlist management
│   │   ├── favorites.py     # Favorites management
│   │   ├── import.py        # JSON import endpoints
│   │   └── admin.py         # Admin endpoints
│   ├── services/
│   │   ├── downloader_service.py  # Adapted downloader logic
│   │   └── import_service.py      # Import task management
│   └── utils/
│       └── streaming.py     # File streaming utilities
├── tests/
│   ├── conftest.py          # Test fixtures
│   ├── test_auth.py         # Auth tests
│   ├── test_tracks.py       # Tracks tests
│   ├── test_playlists.py    # Playlists tests
│   └── test_favorites.py    # Favorites tests
├── alembic/                 # Database migrations
├── requirements.txt
├── Dockerfile
└── pytest.ini
```

## Quick Start

### 1. Clone and Setup

```bash
cd backend
cp ../.env.example .env
```

### 2. Run with Docker Compose (Recommended)

```bash
# From project root
docker-compose up --build
```

The API will be available at `http://localhost:8080`

### 3. Run Locally (Development)

```bash
# Install dependencies
pip install -r requirements.txt

# Run with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

## API Documentation

Once running, access the interactive API documentation:
- **Swagger UI**: http://localhost:8080/docs
- **ReDoc**: http://localhost:8080/redoc

## Default Credentials

- **Username**: `admin`
- **Password**: `admin`

⚠️ **Change these in production!** Set `ADMIN_USERNAME` and `ADMIN_PASSWORD` in `.env`

## Admin Panel

After deployment, open:

- `https://your-domain/admin`

Use the admin credentials from `.env` to upload or import tracks.

## Mobile App

On the login screen, set **Server URL** to your domain (e.g., `https://muzly.example.com`) and log in with the admin credentials.

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with credentials from `.env` |
| GET | `/api/auth/me` | Get current user info |

**Login Example:**
```bash
curl -X POST "http://localhost:8080/api/auth/login" \
  -d "username=admin" -d "password=your-password"
```

### Tracks
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tracks` | List tracks (paginated, searchable) |
| GET | `/api/tracks/{id}` | Get track by ID |
| POST | `/api/tracks/upload` | Upload audio file |
| GET | `/api/tracks/{id}/stream` | Stream track |
| GET | `/api/tracks/{id}/download` | Download track |
| PUT | `/api/tracks/{id}` | Update track metadata |
| DELETE | `/api/tracks/{id}` | Delete track (admin) |

### Playlists
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/playlists` | List playlists |
| POST | `/api/playlists` | Create playlist |
| GET | `/api/playlists/{id}` | Get playlist with tracks |
| PUT | `/api/playlists/{id}` | Update playlist |
| DELETE | `/api/playlists/{id}` | Delete playlist |
| POST | `/api/playlists/{id}/tracks` | Add tracks to playlist |
| DELETE | `/api/playlists/{id}/tracks/{track_id}` | Remove track from playlist |

### Favorites
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/me/favorites` | Get favorite tracks |
| POST | `/api/me/favorites/{track_id}` | Add to favorites |
| DELETE | `/api/me/favorites/{track_id}` | Remove from favorites |

### Import
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/import/json` | Import tracks from JSON |
| GET | `/api/import/status/{task_id}` | Get import task status |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/import/status/{task_id}` | Get any import status |
| GET | `/api/admin/stats` | Get system statistics |

## Usage Examples

### 1. Import Tracks from JSON

```bash
# Login to get token
TOKEN=$(curl -X POST "http://localhost:8080/api/auth/login" \
  -d "username=admin" -d "password=admin" | jq -r '.access_token')

# Import JSON file
curl -X POST "http://localhost:8080/api/import/json" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@exemple.json"
```

### 2. Upload a Track

```bash
curl -X POST "http://localhost:8080/api/tracks/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@song.mp3" \
  -F "title=My Song" \
  -F "artist=My Artist" \
  -F "album=My Album"
```

### 3. Stream a Track

```bash
# Browser or media player
http://localhost:8080/api/tracks/1/stream

# Or with curl (with Range header)
curl -H "Range: bytes=0-" "http://localhost:8080/api/tracks/1/stream"
```

### 4. Create a Playlist

```bash
curl -X POST "http://localhost:8080/api/playlists" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "My Playlist", "description": "Cool songs"}'
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Database (SQLite default)
DATABASE_URL=sqlite+aiosqlite:///./muzly.db

# Or PostgreSQL
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/muzly

# JWT (CHANGE IN PRODUCTION!)
JWT_SECRET=your-secret-key-here

# Admin credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin

# CORS origins
CORS_ORIGINS=http://localhost,http://localhost:3000
```

## Database Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Downgrade
alembic downgrade -1
```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py -v
```

## Production Deployment

### Using Docker Compose with PostgreSQL

```bash
# Create .env file with production settings
cp .env.example .env
# Edit .env with your production values

# Start with PostgreSQL profile
docker-compose --profile postgres up -d --build
```

### Nginx Reverse Proxy

The included docker-compose has an nginx service (profile: nginx):

```bash
docker-compose --profile nginx up -d
```

Configure your domain in `.env`:
```bash
CORS_ORIGINS=https://your-domain.com
```

### SSL with Let's Encrypt

The nginx service includes certbot for automatic SSL renewal.

**Manual renewal:**
```bash
./renew-cert.sh
```

**Auto-renewal (cron):**
```bash
# Add to crontab (runs daily)
0 0 * * * /path/to/muzly/renew-cert.sh >> /var/log/muzly-cert-renewal.log 2>&1
```

## Health Check

```bash
curl http://localhost:8080/health
# {"status":"healthy","version":"1.0.0","database":"connected"}
```

## Known Limitations & Future Improvements

### Current Limitations
1. **Background Tasks**: Uses FastAPI BackgroundTasks (simple, no broker). For high load, consider Celery integration.
2. **No Transcoding**: Files are stored as-is. FFmpeg integration planned for format normalization.
3. **Single User Import**: Import tasks are user-specific; no shared imports.
4. **Basic Search**: Uses SQL LIKE; consider full-text search (Elasticsearch) for large libraries.

### Planned Improvements
- [ ] Celery integration for robust background job processing
- [ ] FFmpeg transcoding for format normalization
- [ ] Duration extraction from audio files
- [ ] Rate limiting for streaming/downloads
- [ ] Playlist export (M3U/JSON)
- [ ] Frontend web application
- [ ] Album view with grouped tracks
- [ ] Artist pages with discography
- [ ] Lyrics integration
- [ ] Last.fm scrobbling

## Troubleshooting

### Database Issues
```bash
# Reset SQLite database
rm muzly.db
# Restart the application
```

### Import Fails
- Check network connectivity (downloader needs internet)
- Verify JSON format matches expected structure
- Check logs for specific errors

### Port Conflicts
Change `PORT` in `.env` or docker-compose.yml

## License

MIT

## Support

For issues and feature requests, please open an issue on the repository.
