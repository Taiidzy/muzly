"""
Muzly - Self-hosted Media Platform
Main FastAPI application entry point.
"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from app.config import CORS_ORIGINS
from app.schemas import HealthResponse
from app.database import init_db

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    logger.info("Starting Muzly backend...")

    # Initialize database
    await init_db()
    logger.info("Database initialized")

    logger.info("Muzly backend started successfully")

    yield

    # Shutdown
    logger.info("Shutting down Muzly backend...")


# Create FastAPI app
app = FastAPI(
    title="Muzly API",
    description="Self-hosted media platform for music streaming and management",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Handle HTTP exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors."""
    return JSONResponse(
        status_code=400,
        content={"detail": "Validation error", "errors": exc.errors()},
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions."""
    logger.error("Unhandled exception: %s", exc)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


# Include routers
from app.routers import auth, tracks, playlists, favorites, import as import_router, admin

app.include_router(auth.router)
app.include_router(tracks.router)
app.include_router(playlists.router)
app.include_router(favorites.router)
app.include_router(import_router.router)
app.include_router(admin.router)


# Admin panel (static)
STATIC_DIR = Path(__file__).parent / "static"
ADMIN_DIR = STATIC_DIR / "admin"

if ADMIN_DIR.exists():
    app.mount("/admin/static", StaticFiles(directory=ADMIN_DIR), name="admin-static")


@app.get("/admin", tags=["Admin UI"])
@app.get("/admin/", tags=["Admin UI"])
async def admin_ui():
    """Serve the admin panel."""
    index_file = ADMIN_DIR / "index.html"
    if not index_file.exists():
        raise HTTPException(status_code=404, detail="Admin UI not found")
    return FileResponse(index_file)


# Health check endpoint
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Health check endpoint."""
    return HealthResponse(status="healthy")


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information."""
    return {
        "name": "Muzly API",
        "version": "1.0.0",
        "description": "Self-hosted media platform",
        "docs": "/docs",
        "health": "/health",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
