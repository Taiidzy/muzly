"""
Tests for playlists endpoints.
"""
import pytest
from httpx import AsyncClient


class TestPlaylists:
    """Test playlists endpoints."""
    
    async def test_create_playlist(self, authenticated_client):
        """Test creating a playlist."""
        client, auth = authenticated_client
        response = await client.post(
            "/api/playlists",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            json={
                "name": "My Playlist",
                "description": "Test playlist",
                "visibility": "private",
            },
        )
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "My Playlist"
        assert data["description"] == "Test playlist"
        assert data["visibility"] == "private"
        assert "id" in data
    
    async def test_get_playlists(self, authenticated_client):
        """Test getting playlists."""
        client, auth = authenticated_client
        
        # Create a playlist first
        await client.post(
            "/api/playlists",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            json={"name": "Test Playlist"},
        )
        
        # Get playlists
        response = await client.get(
            "/api/playlists",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert any(p["name"] == "Test Playlist" for p in data["items"])
    
    async def test_get_playlist(self, authenticated_client, sample_playlist):
        """Test getting a specific playlist."""
        client, auth = authenticated_client
        response = await client.get(
            f"/api/playlists/{sample_playlist.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_playlist.id
        assert data["name"] == "Test Playlist"
    
    async def test_get_playlist_not_found(self, authenticated_client):
        """Test getting a non-existent playlist."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/playlists/99999",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
    
    async def test_update_playlist(self, authenticated_client, sample_playlist):
        """Test updating a playlist."""
        client, auth = authenticated_client
        response = await client.put(
            f"/api/playlists/{sample_playlist.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            json={
                "name": "Updated Playlist",
                "description": "Updated description",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Playlist"
        assert data["description"] == "Updated description"
    
    async def test_update_playlist_not_owner(self, client: AsyncClient, test_db, test_user_data):
        """Test updating a playlist that doesn't belong to user."""
        # Create second user
        from app.auth import get_password_hash
        user2 = User(
            username="user2",
            email="user2@example.com",
            hashed_password=get_password_hash("password123"),
            is_active=True,
        )
        test_db.add(user2)
        await test_db.commit()
        
        # Login as user2
        response = await client.post(
            "/api/auth/login",
            data={"username": "user2", "password": "password123"},
        )
        token = response.json()["access_token"]
        
        # Try to update another user's playlist (sample_playlist created by testuser)
        response = await client.put(
            f"/api/playlists/{sample_playlist.id}",
            headers={"Authorization": f"Bearer {token}"},
            json={"name": "Hacked Playlist"},
        )
        assert response.status_code == 403
    
    async def test_delete_playlist(self, authenticated_client, sample_playlist):
        """Test deleting a playlist."""
        client, auth = authenticated_client
        response = await client.delete(
            f"/api/playlists/{sample_playlist.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 204
        
        # Verify deletion
        response = await client.get(
            f"/api/playlists/{sample_playlist.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
    
    async def test_add_tracks_to_playlist(
        self,
        authenticated_client,
        sample_playlist,
        sample_track,
    ):
        """Test adding tracks to a playlist."""
        client, auth = authenticated_client
        response = await client.post(
            f"/api/playlists/{sample_playlist.id}/tracks",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            json={"track_ids": [sample_track.id]},
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["tracks"]) == 1
        assert data["tracks"][0]["track"]["id"] == sample_track.id
    
    async def test_remove_track_from_playlist(
        self,
        authenticated_client,
        sample_playlist,
        sample_track,
        test_db,
    ):
        """Test removing a track from a playlist."""
        client, auth = authenticated_client
        
        # Add track first
        from app.models import PlaylistTrack
        playlist_track = PlaylistTrack(
            playlist_id=sample_playlist.id,
            track_id=sample_track.id,
            position=0,
        )
        test_db.add(playlist_track)
        await test_db.commit()
        
        # Remove track
        response = await client.delete(
            f"/api/playlists/{sample_playlist.id}/tracks/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 204
        
        # Verify removal
        response = await client.get(
            f"/api/playlists/{sample_playlist.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        data = response.json()
        assert len(data["tracks"]) == 0


# Import models for tests
from app.models import User, PlaylistTrack
