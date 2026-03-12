"""
Admin router - administrative endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.database import get_db
from app.models import ImportTask, Track, User
from app.schemas import ImportTaskResponse
from app.auth import get_current_active_superuser

router = APIRouter(prefix="/api/admin", tags=["Admin"])


@router.get("/import/status/{task_id}", response_model=ImportTaskResponse)
async def get_import_status_admin(
    task_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """
    Get the status of any import task (admin only).
    """
    result = await db.exec(select(ImportTask).where(ImportTask.task_id == task_id))
    task = result.first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Import task not found")
    
    return ImportTaskResponse.model_validate(task)


@router.get("/stats")
async def get_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """
    Get system statistics (admin only).
    """
    from app.models import Playlist, Favorite
    
    # Count tracks
    tracks_result = await db.exec(select(Track))
    all_tracks = tracks_result.all()
    total_tracks = len(all_tracks)
    ready_tracks = sum(1 for t in all_tracks if t.status.value == "ready")
    failed_tracks = sum(1 for t in all_tracks if t.status.value == "failed")
    
    # Count users
    users_result = await db.exec(select(User))
    total_users = len(users_result.all())
    
    # Count playlists
    playlists_result = await db.exec(select(Playlist))
    total_playlists = len(playlists_result.all())
    
    # Count favorites
    favorites_result = await db.exec(select(Favorite))
    total_favorites = len(favorites_result.all())
    
    return {
        "tracks": {
            "total": total_tracks,
            "ready": ready_tracks,
            "failed": failed_tracks,
        },
        "users": total_users,
        "playlists": total_playlists,
        "favorites": total_favorites,
    }
