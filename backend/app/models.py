from datetime import datetime
from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship
from enum import Enum


class TrackSource(str, Enum):
    IMPORT = "import"
    MANUAL = "manual"


class TrackStatus(str, Enum):
    QUEUED = "queued"
    DOWNLOADING = "downloading"
    READY = "ready"
    FAILED = "failed"


class PlaylistVisibility(str, Enum):
    PRIVATE = "private"
    PUBLIC = "public"


class User(SQLModel, table=True):
    __tablename__ = "users"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(unique=True, index=True)
    email: Optional[str] = Field(default=None, unique=True, index=True)
    hashed_password: str
    is_active: bool = Field(default=True)
    is_superuser: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    playlists: List["Playlist"] = Relationship(back_populates="owner", sa_relationship_kwargs={"cascade": "all, delete-orphan"})
    favorites: List["Favorite"] = Relationship(back_populates="user", sa_relationship_kwargs={"cascade": "all, delete-orphan"})


class Track(SQLModel, table=True):
    __tablename__ = "tracks"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(index=True)
    artist: str = Field(index=True)
    album: Optional[str] = Field(default=None)
    duration_ms: Optional[int] = Field(default=None)
    file_path: Optional[str] = Field(default=None)
    cover_path: Optional[str] = Field(default=None)
    source: TrackSource = Field(default=TrackSource.MANUAL)
    status: TrackStatus = Field(default=TrackStatus.READY)
    error_message: Optional[str] = Field(default=None)
    file_size: Optional[int] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    playlist_tracks: List["PlaylistTrack"] = Relationship(back_populates="track", sa_relationship_kwargs={"cascade": "all, delete-orphan"})
    favorites: List["Favorite"] = Relationship(back_populates="track", sa_relationship_kwargs={"cascade": "all, delete-orphan"})


class Playlist(SQLModel, table=True):
    __tablename__ = "playlists"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    description: Optional[str] = Field(default=None)
    visibility: PlaylistVisibility = Field(default=PlaylistVisibility.PRIVATE)
    owner_id: int = Field(foreign_key="users.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    owner: User = Relationship(back_populates="playlists")
    playlist_tracks: List["PlaylistTrack"] = Relationship(back_populates="playlist", sa_relationship_kwargs={"cascade": "all, delete-orphan"})


class PlaylistTrack(SQLModel, table=True):
    __tablename__ = "playlist_tracks"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    playlist_id: int = Field(foreign_key="playlists.id", index=True)
    track_id: int = Field(foreign_key="tracks.id", index=True)
    position: int = Field(default=0)
    added_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    playlist: Playlist = Relationship(back_populates="playlist_tracks")
    track: Track = Relationship(back_populates="playlist_tracks")


class Favorite(SQLModel, table=True):
    __tablename__ = "favorites"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    track_id: int = Field(foreign_key="tracks.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    user: User = Relationship(back_populates="favorites")
    track: Track = Relationship(back_populates="favorites")


class ImportTask(SQLModel, table=True):
    __tablename__ = "import_tasks"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    task_id: str = Field(unique=True, index=True)
    user_id: Optional[int] = Field(default=None, foreign_key="users.id")
    status: str = Field(default="pending")  # pending, processing, completed, failed
    total_tracks: int = Field(default=0)
    processed_tracks: int = Field(default=0)
    failed_tracks: int = Field(default=0)
    error_message: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = Field(default=None)
