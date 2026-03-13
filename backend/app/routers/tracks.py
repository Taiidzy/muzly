"""
Tracks router - handles track CRUD, streaming, and search.
"""
import os
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Request
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func
from pathlib import Path

from app.database import get_db
from app.models import Track, TrackSource, TrackStatus
from app.schemas import TrackResponse, TrackListResponse, TrackUpdate
from app.auth import get_current_user, get_current_active_superuser
from app.utils.streaming import create_streaming_response, create_download_response
from app.config import MEDIA_ROOT, ALLOWED_AUDIO_EXTENSIONS, ALLOWED_AUDIO_TYPES, MAX_UPLOAD_SIZE
from app.models import User

router = APIRouter(prefix="/api/tracks", tags=["Tracks"])


@router.get("", response_model=TrackListResponse)
async def get_tracks(
    page: int = 1,
    page_size: int = 20,
    search: Optional[str] = None,
    source: Optional[TrackSource] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of tracks with pagination, search, and filtering.
    """
    # Build query
    query = select(Track)
    
    # Apply search filter
    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            (Track.title.ilike(search_pattern)) |
            (Track.artist.ilike(search_pattern)) |
            (Track.album.ilike(search_pattern))
        )
    
    # Apply source filter
    if source:
        query = query.where(Track.source == source)
    
    # Apply sorting
    valid_sort_fields = ["title", "artist", "album", "created_at", "updated_at"]
    if sort_by not in valid_sort_fields:
        sort_by = "created_at"
    
    sort_column = getattr(Track, sort_by)
    if sort_order.lower() == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())
    
    # Apply pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    
    # Execute query
    result = await db.exec(query)
    tracks = result.all()
    
    # Get total count
    count_query = select(func.count(Track.id))
    if search:
        search_pattern = f"%{search}%"
        count_query = count_query.where(
            (Track.title.ilike(search_pattern)) |
            (Track.artist.ilike(search_pattern)) |
            (Track.album.ilike(search_pattern))
        )
    if source:
        count_query = count_query.where(Track.source == source)
    
    total_result = await db.exec(count_query)
    total = total_result.one()
    
    return TrackListResponse(
        items=tracks,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{track_id}", response_model=TrackResponse)
async def get_track(
    track_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Get a specific track by ID.
    """
    result = await db.exec(select(Track).where(Track.id == track_id))
    track = result.first()
    
    if not track:
        raise HTTPException(status_code=404, detail="Track not found")
    
    return track


@router.post("/upload", response_model=TrackResponse, status_code=status.HTTP_201_CREATED)
async def upload_track(
    file: UploadFile = File(...),
    title: str = Form(...),
    artist: str = Form(...),
    album: Optional[str] = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Upload a track manually.
    Accepts audio files (mp3, m4a, flac, wav, ogg).
    """
    # Validate file extension
    file_ext = Path(file.filename).suffix.lower()
    if file_ext not in ALLOWED_AUDIO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_AUDIO_EXTENSIONS)}"
        )
    
    # Validate content type if available
    if file.content_type and file.content_type not in ALLOWED_AUDIO_TYPES:
        # Allow upload even if content type is not exactly matched (some clients send generic types)
        pass
    
    # Generate unique filename
    unique_id = str(uuid.uuid4())
    safe_title = "".join(c for c in title if c.isalnum() or c in " -_").strip()
    safe_artist = "".join(c for c in artist if c.isalnum() or c in " -_").strip()
    filename = f"{unique_id}_{safe_artist}_{safe_title}{file_ext}"
    
    # Save file
    file_path = MEDIA_ROOT / filename
    MEDIA_ROOT.mkdir(parents=True, exist_ok=True)
    
    try:
        # Read file content and check size
        content = await file.read()
        if len(content) > MAX_UPLOAD_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Max size: {MAX_UPLOAD_SIZE // (1024 * 1024)}MB"
            )
        
        # Write file
        with open(file_path, "wb") as f:
            f.write(content)
        
        file_size = len(content)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save file: {str(e)}"
        )
    
    # Create track record
    track = Track(
        title=title,
        artist=artist,
        album=album,
        file_path=str(file_path),
        source=TrackSource.MANUAL,
        status=TrackStatus.READY,
        file_size=file_size,
    )
    
    db.add(track)
    await db.commit()
    await db.refresh(track)
    
    return track


@router.get("/{track_id}/stream")
async def stream_track(
    track_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Stream a track with Range header support.
    Returns 206 Partial Content for range requests.
    """
    result = await db.exec(select(Track).where(Track.id == track_id))
    track = result.first()
    
    if not track:
        raise HTTPException(status_code=404, detail="Track not found")
    
    if not track.file_path or not os.path.exists(track.file_path):
        raise HTTPException(status_code=404, detail="Track file not found")
    
    return await create_streaming_response(track.file_path, request)


@router.get("/{track_id}/download")
async def download_track(
    track_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Download a track file.
    """
    result = await db.exec(select(Track).where(Track.id == track_id))
    track = result.first()
    
    if not track:
        raise HTTPException(status_code=404, detail="Track not found")
    
    if not track.file_path or not os.path.exists(track.file_path):
        raise HTTPException(status_code=404, detail="Track file not found")
    
    filename = f"{track.artist} - {track.title}.mp3"
    return await create_download_response(track.file_path, filename)


@router.put("/{track_id}", response_model=TrackResponse)
async def update_track(
    track_id: int,
    track_data: TrackUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update track metadata.
    """
    result = await db.exec(select(Track).where(Track.id == track_id))
    track = result.first()

    if not track:
        raise HTTPException(status_code=404, detail="Track not found")

    # Update fields
    update_data = track_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(track, field, value)

    track.updated_at = datetime.utcnow()

    db.add(track)
    await db.commit()
    await db.refresh(track)

    return track


@router.post("/{track_id}/reupload", response_model=TrackResponse)
async def reupload_track_file(
    track_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Re-upload audio file for a failed track.
    This allows fixing tracks that failed due to missing or corrupted audio files.
    """
    result = await db.exec(select(Track).where(Track.id == track_id))
    track = result.first()

    if not track:
        raise HTTPException(status_code=404, detail="Track not found")

    # Validate file extension
    file_ext = Path(file.filename).suffix.lower()
    if file_ext not in ALLOWED_AUDIO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_AUDIO_EXTENSIONS)}"
        )

    # Generate unique filename
    unique_id = str(uuid.uuid4())
    safe_title = "".join(c for c in track.title if c.isalnum() or c in " -_").strip()
    safe_artist = "".join(c for c in track.artist if c.isalnum() or c in " -_").strip()
    filename = f"{unique_id}_{safe_artist}_{safe_title}{file_ext}"

    # Save file
    file_path = MEDIA_ROOT / filename
    MEDIA_ROOT.mkdir(parents=True, exist_ok=True)

    try:
        # Read file content and check size
        content = await file.read()
        if len(content) > MAX_UPLOAD_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Max size: {MAX_UPLOAD_SIZE // (1024 * 1024)}MB"
            )

        # Write file
        with open(file_path, "wb") as f:
            f.write(content)

        file_size = len(content)

        # Delete old file if exists
        if track.file_path and os.path.exists(track.file_path):
            try:
                os.remove(track.file_path)
            except Exception:
                pass

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save file: {str(e)}"
        )

    # Update track record
    track.file_path = str(file_path)
    track.file_size = file_size
    track.status = TrackStatus.READY
    track.error_message = None
    track.updated_at = datetime.utcnow()

    db.add(track)
    await db.commit()
    await db.refresh(track)

    return track


@router.delete("/{track_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_track(
    track_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """
    Delete a track (admin only).
    Removes both database record and file.
    """
    result = await db.exec(select(Track).where(Track.id == track_id))
    track = result.first()
    
    if not track:
        raise HTTPException(status_code=404, detail="Track not found")
    
    # Delete file if exists
    if track.file_path and os.path.exists(track.file_path):
        try:
            os.remove(track.file_path)
        except Exception as e:
            # Log error but continue with database deletion
            pass
    
    # Delete database record
    await db.delete(track)
    await db.commit()
    
    return None
