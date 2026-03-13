from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from enum import Enum

from app.models import TrackSource, TrackStatus, PlaylistVisibility


# ============ Authentication Schemas ============

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    username: Optional[str] = None


class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: Optional[str] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    is_active: bool
    created_at: datetime


# ============ Track Schemas ============

class TrackBase(BaseModel):
    title: str
    artist: str
    album: Optional[str] = None


class TrackCreate(TrackBase):
    pass


class TrackUpdate(BaseModel):
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    replace_audio: bool = False
    replace_cover: bool = False


class TrackResponse(TrackBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    duration_ms: Optional[int] = None
    file_path: Optional[str] = None
    cover_path: Optional[str] = None
    source: TrackSource
    status: TrackStatus
    file_size: Optional[int] = None
    created_at: datetime
    updated_at: datetime


class TrackListResponse(BaseModel):
    items: List[TrackResponse]
    total: int
    page: int
    page_size: int


# ============ Playlist Schemas ============

class PlaylistBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None


class PlaylistCreate(PlaylistBase):
    visibility: PlaylistVisibility = PlaylistVisibility.PRIVATE


class PlaylistUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    visibility: Optional[PlaylistVisibility] = None


class PlaylistTrackResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    position: int
    added_at: datetime
    track: TrackResponse


class PlaylistResponse(PlaylistBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    visibility: PlaylistVisibility
    owner_id: int
    created_at: datetime
    updated_at: datetime
    tracks: List[PlaylistTrackResponse] = []


class PlaylistListResponse(BaseModel):
    items: List[PlaylistResponse]
    total: int


class AddTracksToPlaylist(BaseModel):
    track_ids: List[int]


# ============ Import Schemas ============

class ImportTaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class ImportTaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: Optional[int] = None
    task_id: str
    status: str
    total_tracks: int
    processed_tracks: int
    failed_tracks: int
    error_message: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None


# ============ Favorite Schemas ============

class FavoriteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    track_id: int
    created_at: datetime
    track: TrackResponse


class FavoriteListResponse(BaseModel):
    items: List[FavoriteResponse]
    total: int


# ============ Health Check ============

class HealthResponse(BaseModel):
    status: str
    version: str = "1.0.0"
    database: str = "connected"
