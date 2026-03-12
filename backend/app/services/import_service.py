"""
Import service for handling JSON track imports.
Manages background tasks for downloading tracks.
"""
import asyncio
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, update

from app.models import ImportTask, Track, TrackSource, TrackStatus
from app.services.downloader_service import search_tracks_in_json, process_track_download
from app.config import MEDIA_ROOT, COVERS_ROOT

logger = logging.getLogger(__name__)


class ImportService:
    """Service for handling track imports from JSON files."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_import_task(self, user_id: Optional[int] = None) -> ImportTask:
        """Create a new import task."""
        task_id = str(uuid4())
        task = ImportTask(
            task_id=task_id,
            user_id=user_id,
            status="pending",
            total_tracks=0,
            processed_tracks=0,
            failed_tracks=0,
        )
        self.db.add(task)
        await self.db.commit()
        await self.db.refresh(task)
        return task
    
    async def get_import_task(self, task_id: str) -> Optional[ImportTask]:
        """Get import task by task_id."""
        result = await self.db.exec(select(ImportTask).where(ImportTask.task_id == task_id))
        return result.first()
    
    async def update_task_status(
        self,
        task: ImportTask,
        status: str,
        total_tracks: Optional[int] = None,
        processed_tracks: Optional[int] = None,
        failed_tracks: Optional[int] = None,
        error_message: Optional[str] = None,
    ):
        """Update import task status."""
        task.status = status
        if total_tracks is not None:
            task.total_tracks = total_tracks
        if processed_tracks is not None:
            task.processed_tracks = processed_tracks
        if failed_tracks is not None:
            task.failed_tracks = failed_tracks
        if error_message is not None:
            task.error_message = error_message
        if status in ("completed", "failed"):
            task.completed_at = datetime.utcnow()
        
        await self.db.commit()
    
    async def process_json_import(
        self,
        task: ImportTask,
        json_path: str,
        user_id: Optional[int] = None,
    ):
        """
        Process JSON file import in background.
        Downloads tracks and creates database records.
        """
        try:
            # Update task status to processing
            await self.update_task_status(task, "processing")
            
            # Parse JSON file
            tracks_data = await search_tracks_in_json(json_path)
            total_tracks = len(tracks_data)
            
            if total_tracks == 0:
                await self.update_task_status(
                    task, "failed",
                    total_tracks=0,
                    error_message="No tracks found in JSON file"
                )
                return
            
            await self.update_task_status(task, "processing", total_tracks=total_tracks)
            
            processed = 0
            failed = 0
            
            for track_data in tracks_data:
                try:
                    # Download track and covers
                    result = await process_track_download(
                        track_data,
                        media_dir=MEDIA_ROOT,
                        covers_dir=COVERS_ROOT,
                    )
                    
                    if result.get("file_path"):
                        # Create track record
                        track = Track(
                            title=result.get("title", "Unknown"),
                            artist=result.get("artist", "Unknown"),
                            album=result.get("album"),
                            duration_ms=result.get("duration_ms"),
                            file_path=result["file_path"],
                            cover_path=result.get("cover_path"),
                            source=TrackSource.IMPORT,
                            status=TrackStatus.READY,
                        )
                        self.db.add(track)
                        processed += 1
                    else:
                        # Create failed track record
                        track = Track(
                            title=result.get("title", "Unknown"),
                            artist=result.get("artist", "Unknown"),
                            album=result.get("album"),
                            source=TrackSource.IMPORT,
                            status=TrackStatus.FAILED,
                            error_message=result.get("error", "Download failed"),
                        )
                        self.db.add(track)
                        failed += 1
                    
                    await self.db.commit()
                    
                    # Update task progress
                    await self.update_task_status(
                        task, "processing",
                        processed_tracks=processed,
                        failed_tracks=failed,
                    )
                    
                    # Rate limiting - wait between downloads
                    await asyncio.sleep(1)
                    
                except Exception as e:
                    logger.error("Error processing track %s: %s", track_data.get("title"), e)
                    failed += 1
                    await self.update_task_status(
                        task, "processing",
                        processed_tracks=processed,
                        failed_tracks=failed,
                    )
            
            # Final status
            if failed == 0:
                await self.update_task_status(
                    task, "completed",
                    processed_tracks=processed,
                    failed_tracks=failed,
                )
            elif processed > 0:
                await self.update_task_status(
                    task, "completed",
                    processed_tracks=processed,
                    failed_tracks=failed,
                    error_message=f"Completed with {failed} failed tracks",
                )
            else:
                await self.update_task_status(
                    task, "failed",
                    processed_tracks=processed,
                    failed_tracks=failed,
                    error_message="All tracks failed to download",
                )
            
        except Exception as e:
            logger.error("Import task failed: %s", e)
            await self.update_task_status(
                task, "failed",
                error_message=str(e),
            )
