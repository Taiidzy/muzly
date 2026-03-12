"""
Streaming utilities for audio files.
Handles Range requests for partial content streaming.
"""
import os
import stat
from typing import Optional
from fastapi import HTTPException, Request
from fastapi.responses import StreamingResponse, Response
import aiofiles


def get_content_type(file_path: str) -> str:
    """Get content type based on file extension."""
    ext = os.path.splitext(file_path)[1].lower()
    content_types = {
        ".mp3": "audio/mpeg",
        ".m4a": "audio/mp4",
        ".flac": "audio/flac",
        ".wav": "audio/wav",
        ".ogg": "audio/ogg",
        ".webm": "audio/webm",
    }
    return content_types.get(ext, "application/octet-stream")


def get_file_size(file_path: str) -> int:
    """Get file size in bytes."""
    return os.path.getsize(file_path)


async def stream_file(
    file_path: str,
    start: int,
    end: int,
    chunk_size: int = 8192,
):
    """
    Async generator for streaming file content.
    Yields chunks from start to end position.
    """
    async with aiofiles.open(file_path, "rb") as f:
        await f.seek(start)
        remaining = end - start + 1
        
        while remaining > 0:
            to_read = min(chunk_size, remaining)
            chunk = await f.read(to_read)
            
            if not chunk:
                break
            
            yield chunk
            remaining -= len(chunk)


async def create_streaming_response(
    file_path: str,
    request: Request,
) -> Response:
    """
    Create a streaming response with Range header support.
    Returns 206 Partial Content for range requests, 200 OK otherwise.
    """
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    file_size = get_file_size(file_path)
    content_type = get_content_type(file_path)
    
    # Check for Range header
    range_header = request.headers.get("range")
    
    if range_header:
        # Parse Range header
        try:
            range_value = range_header.replace("bytes=", "")
            start_str, end_str = range_value.split("-")
            start = int(start_str) if start_str else 0
            end = int(end_str) if end_str else file_size - 1
            
            # Validate range
            if start < 0 or start >= file_size:
                raise HTTPException(
                    status_code=416,
                    detail="Range Not Satisfiable",
                    headers={"Content-Range": f"bytes */{file_size}"}
                )
            
            # Clamp end to file size
            end = min(end, file_size - 1)
            
            # Create partial content response
            content_length = end - start + 1
            
            return StreamingResponse(
                stream_file(file_path, start, end),
                status_code=206,
                headers={
                    "Content-Range": f"bytes {start}-{end}/{file_size}",
                    "Accept-Ranges": "bytes",
                    "Content-Length": str(content_length),
                    "Content-Type": content_type,
                    "Content-Disposition": f"inline; filename={os.path.basename(file_path)}",
                },
                media_type=content_type,
            )
        
        except (ValueError, IndexError):
            # Invalid range header, return full file
            pass
    
    # Return full file
    return StreamingResponse(
        stream_file(file_path, 0, file_size - 1),
        status_code=200,
        headers={
            "Accept-Ranges": "bytes",
            "Content-Length": str(file_size),
            "Content-Type": content_type,
            "Content-Disposition": f"inline; filename={os.path.basename(file_path)}",
        },
        media_type=content_type,
    )


async def create_download_response(
    file_path: str,
    filename: Optional[str] = None,
) -> Response:
    """
    Create a download response for a file.
    Forces download with Content-Disposition: attachment.
    """
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    file_size = get_file_size(file_path)
    content_type = get_content_type(file_path)
    
    if filename is None:
        filename = os.path.basename(file_path)
    
    return StreamingResponse(
        stream_file(file_path, 0, file_size - 1),
        status_code=200,
        headers={
            "Content-Length": str(file_size),
            "Content-Type": content_type,
            "Content-Disposition": f"attachment; filename={filename}",
        },
        media_type=content_type,
    )
