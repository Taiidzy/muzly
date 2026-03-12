# Muzly Backend - Implementation Summary

## Project Overview

A complete FastAPI-based backend for a self-hosted music streaming platform with JSON track import capabilities.

## File Structure

```
backend/
├── app/
│   ├── __init__.py                 # Package initialization
│   ├── main.py                     # FastAPI application entry point
│   ├── config.py                   # Configuration and environment variables
│   ├── database.py                 # Async database connection (SQLModel)
│   ├── models.py                   # Database models (User, Track, Playlist, etc.)
│   ├── schemas.py                  # Pydantic schemas for API validation
│   ├── auth.py                     # JWT authentication utilities
│   ├── downloader.py               # Original downloader (preserved)
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── auth.py                 # /api/auth/* endpoints
│   │   ├── tracks.py               # /api/tracks/* endpoints
│   │   ├── playlists.py            # /api/playlists/* endpoints
│   │   ├── favorites.py            # /api/me/favorites/* endpoints
│   │   ├── import.py               # /api/import/* endpoints
│   │   └── admin.py                # /api/admin/* endpoints
│   ├── services/
│   │   ├── __init__.py
│   │   ├── downloader_service.py   # Async downloader (adapted from downloader.py)
│   │   └── import_service.py       # Import task management
│   └── utils/
│       ├── __init__.py
│       └── streaming.py            # Range-request streaming support
├── tests/
│   ├── __init__.py
│   ├── conftest.py                 # Test fixtures and setup
│   ├── test_auth.py                # Authentication tests
│   ├── test_tracks.py              # Tracks CRUD tests
│   ├── test_playlists.py           # Playlists tests
│   ├── test_favorites.py           # Favorites tests
│   └── test_import.py              # Import tests
├── alembic/
│   ├── env.py                      # Alembic environment config
│   ├── script.py.mako              # Migration template
│   └── versions/
│       └── initial.py              # Initial migration (all tables)
├── .env                            # Local environment (gitignored)
├── .env.example                    # Environment template
├── .gitignore
├── Dockerfile
├── docker-compose.yml              # (root level)
├── requirements.txt
├── pytest.ini
├── Makefile
└── alembic.ini
```

## Key Features Implemented

### 1. Authentication System
- JWT-based authentication with configurable expiration
- User registration and login
- Password hashing with bcrypt
- OAuth2 password bearer flow
- Current user endpoint

### 2. Track Management
- Manual upload with metadata (title, artist, album)
- File validation (extensions: mp3, m4a, flac, wav, ogg)
- Streaming with Range header support (206 Partial Content)
- Download endpoint
- Search and filter (by title, artist, album, source)
- Pagination and sorting
- Admin-only deletion

### 3. JSON Import
- Upload JSON files with track metadata
- Background task processing (FastAPI BackgroundTasks)
- Task status tracking
- Automatic track and cover download
- Integration with adapted downloader.py logic

### 4. Playlists
- CRUD operations
- Visibility settings (private/public)
- Add/remove tracks
- Track ordering (position)
- Owner-only modification

### 5. Favorites
- Add/remove favorite tracks
- List favorites with pagination
- Duplicate prevention

### 6. Admin Features
- System statistics endpoint
- Import task monitoring
- Track deletion (physical + database)

## Technical Decisions

### Background Tasks
**Choice**: FastAPI BackgroundTasks with asyncio.to_thread

**Rationale**:
- Simple setup (no external broker required)
- Suitable for self-hosted deployment
- Synchronous downloader.py calls wrapped in asyncio.to_thread
- Can be upgraded to Celery later if needed

### Database
**Default**: SQLite with aiosqlite (async)
**Option**: PostgreSQL with asyncpg

**Rationale**:
- SQLite for quick self-hosted setup (no external dependencies)
- PostgreSQL option for production scalability
- SQLModel provides clean SQLAlchemy + Pydantic integration

### Streaming
**Implementation**: Custom async generator with aiofiles

**Features**:
- Range header parsing and validation
- 206 Partial Content responses
- Proper Accept-Ranges headers
- Content-Type based on file extension

### Security
- JWT secret from environment variable
- Password hashing with bcrypt
- CORS configuration from environment
- File type validation
- File size limits
- Path traversal prevention (using Pathlib)

## API Endpoints Summary

| Category | Endpoints |
|----------|-----------|
| Auth | POST /api/auth/register, POST /api/auth/login, GET /api/auth/me |
| Tracks | GET/POST /api/tracks, GET/PUT/DELETE /api/tracks/{id}, POST /api/tracks/upload, GET /api/tracks/{id}/stream, GET /api/tracks/{id}/download |
| Playlists | GET/POST /api/playlists, GET/PUT/DELETE /api/playlists/{id}, POST/DELETE /api/playlists/{id}/tracks |
| Favorites | GET /api/me/favorites, POST/DELETE /api/me/favorites/{track_id} |
| Import | POST /api/import/json, GET /api/import/status/{task_id} |
| Admin | GET /api/admin/import/status/{task_id}, GET /api/admin/stats |

## Testing

**Coverage**:
- Authentication (register, login, get current user)
- Tracks (upload, list, search, stream, download, update, delete)
- Playlists (CRUD, add/remove tracks, permissions)
- Favorites (add, remove, list)
- Import (JSON upload, status check, permissions)

**Run Tests**:
```bash
pytest                          # Run all tests
pytest --cov=app               # With coverage
pytest tests/test_auth.py -v   # Specific file
```

## Deployment

### Local Development
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Docker Compose
```bash
# From project root
docker-compose up --build
```

### With PostgreSQL
```bash
docker-compose --profile postgres up -d
```

### Production Considerations
1. Change JWT_SECRET to a long random string
2. Change admin credentials
3. Use PostgreSQL instead of SQLite
4. Configure CORS for your domain
5. Set up nginx reverse proxy
6. Enable SSL with certbot (included in compose)

## Known Limitations

1. **Background Tasks**: No retry mechanism, no task persistence (fixed by using Celery)
2. **No Transcoding**: Files stored as-is (FFmpeg planned)
3. **No Duration Extraction**: Duration must be in metadata (planned)
4. **Basic Search**: SQL LIKE queries (consider full-text search for large libraries)
5. **No Rate Limiting**: Consider adding for production

## Next Steps

1. **Immediate**: Test with real JSON files and track downloads
2. **Short-term**: Add FFmpeg integration for duration extraction
3. **Medium-term**: Celery integration for robust background processing
4. **Long-term**: Frontend web application

## Verification Checklist

- [x] Project runs with `docker-compose up --build`
- [x] SQLite works by default
- [x] PostgreSQL option available
- [x] JSON import endpoint works
- [x] Manual track upload works
- [x] Streaming with Range header works
- [x] Playlists CRUD works
- [x] Favorites work
- [x] Authentication works
- [x] Tests pass
- [x] Documentation complete
- [x] CI workflow configured
- [x] Makefile with common commands
