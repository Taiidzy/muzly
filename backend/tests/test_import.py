"""
Tests for import endpoints.
"""
import json
import pytest
from httpx import AsyncClient


class TestImport:
    """Test import endpoints."""
    
    async def test_import_json(self, authenticated_client):
        """Test importing tracks from JSON file."""
        client, auth = authenticated_client
        
        # Create a test JSON file
        test_data = {
            "result": {
                "tracks": [
                    {
                        "title": "Test Song",
                        "artists": [{"name": "Test Artist"}],
                        "albums": [{"title": "Test Album"}],
                        "coverUri": "-",
                    }
                ]
            }
        }
        
        response = await client.post(
            "/api/import/json",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            files={
                "file": ("test.json", json.dumps(test_data), "application/json"),
            },
        )
        assert response.status_code == 202
        data = response.json()
        assert "task_id" in data
        assert data["status"] == "pending"
    
    async def test_import_json_invalid_file(self, authenticated_client):
        """Test importing with non-JSON file."""
        client, auth = authenticated_client
        
        response = await client.post(
            "/api/import/json",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            files={
                "file": ("test.txt", b"not a json file", "text/plain"),
            },
        )
        assert response.status_code == 400
        assert "Only JSON files are accepted" in response.json()["detail"]
    
    async def test_get_import_status(self, authenticated_client):
        """Test getting import task status."""
        client, auth = authenticated_client
        
        # Create a test JSON file
        test_data = {
            "result": {
                "tracks": [
                    {
                        "title": "Test Song",
                        "artists": [{"name": "Test Artist"}],
                        "albums": [{"title": "Test Album"}],
                        "coverUri": "-",
                    }
                ]
            }
        }
        
        # Start import
        response = await client.post(
            "/api/import/json",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
            files={
                "file": ("test.json", json.dumps(test_data), "application/json"),
            },
        )
        task_id = response.json()["task_id"]
        
        # Get status
        response = await client.get(
            f"/api/import/status/{task_id}",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["task_id"] == task_id
    
    async def test_get_import_status_not_found(self, authenticated_client):
        """Test getting status of non-existent task."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/import/status/non-existent-id",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 404
    
    async def test_get_import_status_unauthorized(self, client: AsyncClient, test_db, test_user_data):
        """Test getting status of task owned by another user."""
        from app.auth import get_password_hash
        from app.models import ImportTask, User
        
        # Create second user
        user2 = User(
            username="user2",
            email="user2@example.com",
            hashed_password=get_password_hash("password123"),
            is_active=True,
        )
        test_db.add(user2)
        
        # Create import task for user2
        task = ImportTask(
            task_id="test-task-id",
            user_id=user2.id,
            status="pending",
        )
        test_db.add(task)
        await test_db.commit()
        
        # Login as first user
        await client.post(
            "/api/auth/register",
            json=test_user_data,
        )
        response = await client.post(
            "/api/auth/login",
            data={
                "username": test_user_data["username"],
                "password": test_user_data["password"],
            },
        )
        token = response.json()["access_token"]
        
        # Try to get task status
        response = await client.get(
            "/api/import/status/test-task-id",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403
