"""
Tests for tracks endpoints.
"""
import io
import pytest
from httpx import AsyncClient


class TestTracks:
    """Test tracks endpoints."""
    
    async def test_get_tracks_empty(self, authenticated_client):
        """Test getting tracks when database is empty."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/tracks",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["items"] == []
        assert data["total"] == 0
    
    async def test_upload_track(self, authenticated_client):
        """Test uploading a track."""
        client, auth = authenticated_client
        
        # Create a small fake MP3 file
        fake_mp3 = io.BytesIO(b"ID3" + b"\x00" * 100)
        
        response = await client.post(
            "/api/tracks/upload",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            files={
                "file": ("test.mp3", fake_mp3, "audio/mpeg"),
            },
            data={
                "title": "Test Song",
                "artist": "Test Artist",
                "album": "Test Album",
            },
        )
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Test Song"
        assert data["artist"] == "Test Artist"
        assert data["album"] == "Test Album"
        assert data["source"] == "manual"
        assert "id" in data
    
    async def test_upload_track_invalid_extension(self, authenticated_client):
        """Test uploading a track with invalid extension."""
        client, auth = authenticated_client
        
        fake_file = io.BytesIO(b"fake content")
        
        response = await client.post(
            "/api/tracks/upload",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            files={
                "file": ("test.txt", fake_file, "text/plain"),
            },
            data={
                "title": "Test Song",
                "artist": "Test Artist",
            },
        )
        assert response.status_code == 400
        assert "Invalid file type" in response.json()["detail"]
    
    async def test_get_track(self, authenticated_client, sample_track):
        """Test getting a specific track."""
        client, auth = authenticated_client
        response = await client.get(
            f"/api/tracks/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_track.id
        assert data["title"] == sample_track.title
        assert data["artist"] == sample_track.artist
    
    async def test_get_track_not_found(self, authenticated_client):
        """Test getting a non-existent track."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/tracks/99999",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
    
    async def test_get_tracks_with_search(self, authenticated_client, test_db):
        """Test searching tracks."""
        client, auth = authenticated_client
        
        # Create test tracks
        track1 = Track(title="Song One", artist="Artist A", source="manual", status="ready")
        track2 = Track(title="Song Two", artist="Artist B", source="import", status="ready")
        test_db.add_all([track1, track2])
        await test_db.commit()
        
        # Search by title
        response = await client.get(
            "/api/tracks?search=One",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["title"] == "Song One"
        
        # Search by artist
        response = await client.get(
            "/api/tracks?search=Artist B",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
    
    async def test_get_tracks_filter_by_source(self, authenticated_client, test_db):
        """Test filtering tracks by source."""
        client, auth = authenticated_client
        
        # Create test tracks
        track1 = Track(title="Song One", artist="Artist A", source="manual", status="ready")
        track2 = Track(title="Song Two", artist="Artist B", source="import", status="ready")
        test_db.add_all([track1, track2])
        await test_db.commit()
        
        # Filter by import
        response = await client.get(
            "/api/tracks?source=import",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["source"] == "import"
    
    async def test_stream_track(self, authenticated_client, sample_track, tmp_path):
        """Test streaming a track."""
        client, auth = authenticated_client
        
        # Create a fake audio file
        fake_audio = b"fake audio content" * 1000
        sample_track.file_path = str(tmp_path / "test.mp3")
        
        with open(sample_track.file_path, "wb") as f:
            f.write(fake_audio)
        
        await test_db.commit()
        
        response = await client.get(
            f"/api/tracks/{sample_track.id}/stream",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        assert response.headers["Accept-Ranges"] == "bytes"
        assert "audio/mpeg" in response.headers["Content-Type"]
    
    async def test_stream_track_not_found(self, authenticated_client):
        """Test streaming a non-existent track."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/tracks/99999/stream",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
    
    async def test_download_track(self, authenticated_client, sample_track, tmp_path):
        """Test downloading a track."""
        client, auth = authenticated_client
        
        # Create a fake audio file
        fake_audio = b"fake audio content" * 1000
        sample_track.file_path = str(tmp_path / "test.mp3")
        
        with open(sample_track.file_path, "wb") as f:
            f.write(fake_audio)
        
        await test_db.commit()
        
        response = await client.get(
            f"/api/tracks/{sample_track.id}/download",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        assert "attachment" in response.headers["Content-Disposition"]
    
    async def test_update_track(self, authenticated_client, sample_track):
        """Test updating a track."""
        client, auth = authenticated_client
        response = await client.put(
            f"/api/tracks/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            json={"title": "Updated Title"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["artist"] == sample_track.artist
    
    async def test_delete_track_admin(self, client: AsyncClient, test_db, sample_track, test_user_data):
        """Test deleting a track (admin only)."""
        # Create admin user
        from app.auth import get_password_hash
        admin = User(
            username="admin",
            email="admin@example.com",
            hashed_password=get_password_hash("adminpass"),
            is_active=True,
            is_superuser=True,
        )
        test_db.add(admin)
        await test_db.commit()
        
        # Login as admin
        response = await client.post(
            "/api/auth/login",
            data={"username": "admin", "password": "adminpass"},
        )
        token = response.json()["access_token"]
        
        # Delete track
        response = await client.delete(
            f"/api/tracks/{sample_track.id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 204


# Import Track model for tests
from app.models import Track
