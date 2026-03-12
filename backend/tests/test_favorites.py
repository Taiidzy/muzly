"""
Tests for favorites endpoints.
"""
import pytest
from httpx import AsyncClient


class TestFavorites:
    """Test favorites endpoints."""
    
    async def test_add_to_favorites(self, authenticated_client, sample_track):
        """Test adding a track to favorites."""
        client, auth = authenticated_client
        response = await client.post(
            f"/api/me/favorites/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 201
        data = response.json()
        assert data["track_id"] == sample_track.id
        assert data["track"]["id"] == sample_track.id
    
    async def test_add_to_favorites_track_not_found(self, authenticated_client):
        """Test adding a non-existent track to favorites."""
        client, auth = authenticated_client
        response = await client.post(
            "/api/me/favorites/99999",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
    
    async def test_add_to_favorites_duplicate(self, authenticated_client, sample_track, test_db):
        """Test adding a track that's already in favorites."""
        client, auth = authenticated_client
        
        # Add to favorites first
        from app.models import Favorite
        fav = Favorite(user_id=1, track_id=sample_track.id)
        test_db.add(fav)
        await test_db.commit()
        
        # Try to add again
        response = await client.post(
            f"/api/me/favorites/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 400
        assert "already in favorites" in response.json()["detail"]
    
    async def test_get_favorites(self, authenticated_client, sample_track, test_db):
        """Test getting favorites."""
        client, auth = authenticated_client
        
        # Add track to favorites
        from app.models import Favorite, User
        user = await test_db.get(User, 1)
        fav = Favorite(user_id=user.id, track_id=sample_track.id)
        test_db.add(fav)
        await test_db.commit()
        
        # Get favorites
        response = await client.get(
            "/api/me/favorites",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert any(f["track_id"] == sample_track.id for f in data["items"])
    
    async def test_get_favorites_empty(self, authenticated_client):
        """Test getting favorites when empty."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/me/favorites",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert data["items"] == []
    
    async def test_remove_from_favorites(
        self,
        authenticated_client,
        sample_track,
        test_db,
    ):
        """Test removing a track from favorites."""
        client, auth = authenticated_client
        
        # Add to favorites first
        from app.models import Favorite, User
        user = await test_db.get(User, 1)
        fav = Favorite(user_id=user.id, track_id=sample_track.id)
        test_db.add(fav)
        await test_db.commit()
        
        # Remove from favorites
        response = await client.delete(
            f"/api/me/favorites/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 204
        
        # Verify removal
        response = await client.get(
            "/api/me/favorites",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        data = response.json()
        assert not any(f["track_id"] == sample_track.id for f in data["items"])
    
    async def test_remove_from_favorites_not_found(self, authenticated_client):
        """Test removing a track that's not in favorites."""
        client, auth = authenticated_client
        response = await client.delete(
            f"/api/me/favorites/{sample_track.id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
