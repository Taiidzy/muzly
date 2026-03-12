"""
Playlists router - handles playlist CRUD and track management.
"""
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.database import get_db
from app.models import Playlist, PlaylistTrack, Track, User, PlaylistVisibility
from app.schemas import (
    PlaylistCreate,
    PlaylistResponse,
    PlaylistListResponse,
    PlaylistUpdate,
    PlaylistTrackResponse,
    AddTracksToPlaylist,
)
from app.auth import get_current_user

router = APIRouter(prefix="/api/playlists", tags=["Playlists"])


@router.get("", response_model=PlaylistListResponse)
async def get_playlists(
    page: int = 1,
    page_size: int = 20,
    visibility: Optional[PlaylistVisibility] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get list of playlists for the current user.
    """
    # Build query - show user's playlists and public playlists
    query = select(Playlist).where(
        (Playlist.owner_id == current_user.id) |
        (Playlist.visibility == PlaylistVisibility.PUBLIC)
    )
    
    # Apply visibility filter
    if visibility:
        query = query.where(Playlist.visibility == visibility)
    
    # Apply pagination
    offset = (page - 1) * page_size
    query = query.order_by(Playlist.created_at.desc()).offset(offset).limit(page_size)
    
    # Execute query
    result = await db.exec(query)
    playlists = result.all()
    
    # Get total count
    count_query = select(func.count(Playlist.id)).where(
        (Playlist.owner_id == current_user.id) |
        (Playlist.visibility == PlaylistVisibility.PUBLIC)
    )
    if visibility:
        count_query = count_query.where(Playlist.visibility == visibility)
    
    total_result = await db.exec(count_query)
    total = total_result.one()
    
    return PlaylistListResponse(items=playlists, total=total)


@router.post("", response_model=PlaylistResponse, status_code=status.HTTP_201_CREATED)
async def create_playlist(
    playlist_data: PlaylistCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create a new playlist.
    """
    playlist = Playlist(
        name=playlist_data.name,
        description=playlist_data.description,
        visibility=playlist_data.visibility,
        owner_id=current_user.id,
    )
    
    db.add(playlist)
    await db.commit()
    await db.refresh(playlist)
    
    return PlaylistResponse(
        id=playlist.id,
        name=playlist.name,
        description=playlist.description,
        visibility=playlist.visibility,
        owner_id=playlist.owner_id,
        created_at=playlist.created_at,
        updated_at=playlist.updated_at,
        tracks=[],
    )


@router.get("/{playlist_id}", response_model=PlaylistResponse)
async def get_playlist(
    playlist_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get a specific playlist with its tracks.
    """
    result = await db.exec(select(Playlist).where(Playlist.id == playlist_id))
    playlist = result.first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    
    # Check permissions
    if playlist.owner_id != current_user.id and playlist.visibility != PlaylistVisibility.PUBLIC:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Get playlist tracks
    tracks_query = (
        select(PlaylistTrack, Track)
        .join(Track, PlaylistTrack.track_id == Track.id)
        .where(PlaylistTrack.playlist_id == playlist_id)
        .order_by(PlaylistTrack.position)
    )
    
    tracks_result = await db.exec(tracks_query)
    playlist_tracks = tracks_result.all()
    
    tracks_response = []
    for pt, track in playlist_tracks:
        tracks_response.append(
            PlaylistTrackResponse(
                id=pt.id,
                position=pt.position,
                added_at=pt.added_at,
                track=TrackResponse.model_validate(track),
            )
        )
    
    return PlaylistResponse(
        id=playlist.id,
        name=playlist.name,
        description=playlist.description,
        visibility=playlist.visibility,
        owner_id=playlist.owner_id,
        created_at=playlist.created_at,
        updated_at=playlist.updated_at,
        tracks=tracks_response,
    )


@router.put("/{playlist_id}", response_model=PlaylistResponse)
async def update_playlist(
    playlist_id: int,
    playlist_data: PlaylistUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update a playlist.
    """
    result = await db.exec(select(Playlist).where(Playlist.id == playlist_id))
    playlist = result.first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    
    # Check ownership
    if playlist.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Update fields
    update_data = playlist_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(playlist, field, value)
    
    playlist.updated_at = datetime.utcnow()
    
    db.add(playlist)
    await db.commit()
    await db.refresh(playlist)
    
    # Get tracks
    tracks_query = (
        select(PlaylistTrack, Track)
        .join(Track, PlaylistTrack.track_id == Track.id)
        .where(PlaylistTrack.playlist_id == playlist_id)
        .order_by(PlaylistTrack.position)
    )
    
    tracks_result = await db.exec(tracks_query)
    playlist_tracks = tracks_result.all()
    
    tracks_response = []
    for pt, track in playlist_tracks:
        tracks_response.append(
            PlaylistTrackResponse(
                id=pt.id,
                position=pt.position,
                added_at=pt.added_at,
                track=TrackResponse.model_validate(track),
            )
        )
    
    return PlaylistResponse(
        id=playlist.id,
        name=playlist.name,
        description=playlist.description,
        visibility=playlist.visibility,
        owner_id=playlist.owner_id,
        created_at=playlist.created_at,
        updated_at=playlist.updated_at,
        tracks=tracks_response,
    )


@router.delete("/{playlist_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_playlist(
    playlist_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Delete a playlist.
    """
    result = await db.exec(select(Playlist).where(Playlist.id == playlist_id))
    playlist = result.first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    
    # Check ownership
    if playlist.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    await db.delete(playlist)
    await db.commit()
    
    return None


@router.post("/{playlist_id}/tracks", response_model=PlaylistResponse)
async def add_tracks_to_playlist(
    playlist_id: int,
    tracks_data: AddTracksToPlaylist,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Add tracks to a playlist.
    """
    result = await db.exec(select(Playlist).where(Playlist.id == playlist_id))
    playlist = result.first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    
    # Check ownership
    if playlist.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Get current max position
    max_pos_query = select(func.max(PlaylistTrack.position)).where(
        PlaylistTrack.playlist_id == playlist_id
    )
    max_pos_result = await db.exec(max_pos_query)
    max_position = max_pos_result.one() or 0
    
    # Add tracks
    position = max_position + 1
    for track_id in tracks_data.track_ids:
        # Check if track exists
        track_result = await db.exec(select(Track).where(Track.id == track_id))
        track = track_result.first()
        
        if not track:
            continue
        
        # Check if track is already in playlist
        existing_query = select(PlaylistTrack).where(
            (PlaylistTrack.playlist_id == playlist_id) &
            (PlaylistTrack.track_id == track_id)
        )
        existing_result = await db.exec(existing_query)
        if existing_result.first():
            continue
        
        # Add track to playlist
        playlist_track = PlaylistTrack(
            playlist_id=playlist_id,
            track_id=track_id,
            position=position,
        )
        db.add(playlist_track)
        position += 1
    
    playlist.updated_at = datetime.utcnow()
    db.add(playlist)
    await db.commit()
    
    # Reload playlist with tracks
    return await get_playlist(playlist_id, db, current_user)


@router.delete("/{playlist_id}/tracks/{track_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_track_from_playlist(
    playlist_id: int,
    track_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Remove a track from a playlist.
    """
    result = await db.exec(select(Playlist).where(Playlist.id == playlist_id))
    playlist = result.first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    
    # Check ownership
    if playlist.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Find playlist track
    result = await db.exec(
        select(PlaylistTrack).where(
            (PlaylistTrack.playlist_id == playlist_id) &
            (PlaylistTrack.track_id == track_id)
        )
    )
    playlist_track = result.first()
    
    if not playlist_track:
        raise HTTPException(status_code=404, detail="Track not in playlist")
    
    await db.delete(playlist_track)
    playlist.updated_at = datetime.utcnow()
    db.add(playlist)
    await db.commit()
    
    return None
