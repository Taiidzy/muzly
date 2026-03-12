"""
Import router - handles JSON track imports.
"""
import os
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.database import get_db, get_db_session
from app.models import ImportTask, User
from app.schemas import ImportTaskResponse, ImportTaskStatus
from app.auth import get_current_user, get_current_active_superuser
from app.services.import_service import ImportService
from app.config import IMPORT_DROP

router = APIRouter(prefix="/api/import", tags=["Import"])


@router.post("/json", response_model=ImportTaskResponse, status_code=status.HTTP_202_ACCEPTED)
async def import_json(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Import tracks from a JSON file.
    The JSON file should contain tracks in the expected format.
    Returns a task ID to track import progress.
    """
    # Validate file type
    if not file.filename.endswith(".json"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only JSON files are accepted"
        )
    
    # Create import task
    import_service = ImportService(db)
    task = await import_service.create_import_task(user_id=current_user.id)
    
    # Save uploaded file temporarily
    IMPORT_DROP.mkdir(parents=True, exist_ok=True)
    temp_path = IMPORT_DROP / f"{task.task_id}.json"
    
    try:
        content = await file.read()
        with open(temp_path, "wb") as f:
            f.write(content)
    except Exception as e:
        await import_service.update_task_status(task, "failed", error_message=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save file: {str(e)}"
        )
    
    # Start background task
    background_tasks.add_task(
        import_service.process_json_import,
        task,
        str(temp_path),
        current_user.id,
    )
    
    return ImportTaskResponse.model_validate(task)


@router.get("/status/{task_id}", response_model=ImportTaskResponse)
async def get_import_status(
    task_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get the status of an import task.
    """
    import_service = ImportService(db)
    task = await import_service.get_import_task(task_id)
    
    if not task:
        raise HTTPException(status_code=404, detail="Import task not found")
    
    # Check ownership
    if task.user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    return ImportTaskResponse.model_validate(task)


@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_import_task(
    task_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_superuser),
):
    """
    Delete an import task record (admin only).
    """
    result = await db.exec(select(ImportTask).where(ImportTask.task_id == task_id))
    task = result.first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Import task not found")
    
    # Clean up temp file
    temp_path = IMPORT_DROP / f"{task_id}.json"
    if temp_path.exists():
        try:
            os.remove(temp_path)
        except Exception:
            pass
    
    await db.delete(task)
    await db.commit()
    
    return None
