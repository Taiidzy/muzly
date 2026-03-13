"""
Favorites router - handles user favorite tracks.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.database import get_db
from app.models import Favorite, Track, User, PlaylistVisibility
from app.schemas import FavoriteResponse, FavoriteListResponse, TrackResponse, PlaylistResponse, PlaylistTrackResponse
from app.auth import get_current_user

router = APIRouter(prefix="/api/me/favorites", tags=["Favorites"])


@router.get("", response_model=FavoriteListResponse)
async def get_favorites(
    page: int = 1,
    page_size: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get current user's favorite tracks.
    """
    # Build query
    query = (
        select(Favorite, Track)
        .join(Track, Favorite.track_id == Track.id)
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )

    # Apply pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)

    # Execute query
    result = await db.exec(query)
    favorites_data = result.all()

    favorites_response = []
    for fav, track in favorites_data:
        favorites_response.append(
            FavoriteResponse(
                id=fav.id,
                track_id=fav.track_id,
                created_at=fav.created_at,
                track=TrackResponse.model_validate(track),
            )
        )

    # Get total count
    count_query = select(func.count(Favorite.id)).where(Favorite.user_id == current_user.id)
    total_result = await db.exec(count_query)
    total = total_result.one()

    return FavoriteListResponse(items=favorites_response, total=total)


@router.get("/playlist", response_model=PlaylistResponse)
async def get_favorites_playlist(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get favorites as a playlist (for system favorites playlist).
    This endpoint returns favorites in playlist format for easy integration.
    """
    # Get all favorite tracks
    query = (
        select(Favorite, Track)
        .join(Track, Favorite.track_id == Track.id)
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )

    result = await db.exec(query)
    favorites_data = result.all()

    # Build track list
    tracks_response = []
    for idx, (fav, track) in enumerate(favorites_data):
        tracks_response.append(
            PlaylistTrackResponse(
                id=fav.id,
                position=idx,
                added_at=fav.created_at,
                track=TrackResponse.model_validate(track),
            )
        )

    # Return as playlist format
    return PlaylistResponse(
        id=-1,  # Virtual ID for favorites
        name="Избранное",
        description="Liked tracks",
        visibility=PlaylistVisibility.PRIVATE,
        owner_id=current_user.id,
        created_at=result.first()[0].created_at if favorites_data else None,
        updated_at=None,
        tracks=tracks_response,
    )


@router.post("/{track_id}", response_model=FavoriteResponse, status_code=status.HTTP_201_CREATED)
async def add_to_favorites(
    track_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Add a track to favorites.
    """
    # Check if track exists
    track_result = await db.exec(select(Track).where(Track.id == track_id))
    track = track_result.first()

    if not track:
        raise HTTPException(status_code=404, detail="Track not found")

    # Check if already in favorites
    existing_query = select(Favorite).where(
        (Favorite.user_id == current_user.id) &
        (Favorite.track_id == track_id)
    )
    existing_result = await db.exec(existing_query)

    if existing_result.first():
        raise HTTPException(status_code=400, detail="Track already in favorites")

    # Add to favorites
    favorite = Favorite(
        user_id=current_user.id,
        track_id=track_id,
    )

    db.add(favorite)
    await db.commit()
    await db.refresh(favorite)

    return FavoriteResponse(
        id=favorite.id,
        track_id=favorite.track_id,
        created_at=favorite.created_at,
        track=TrackResponse.model_validate(track),
    )


@router.delete("/{track_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_favorites(
    track_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Remove a track from favorites.
    """
    # Find favorite
    result = await db.exec(
        select(Favorite).where(
            (Favorite.user_id == current_user.id) &
            (Favorite.track_id == track_id)
        )
    )
    favorite = result.first()

    if not favorite:
        raise HTTPException(status_code=404, detail="Favorite not found")

    await db.delete(favorite)
    await db.commit()

    return None
