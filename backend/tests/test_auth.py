"""
Tests for authentication endpoints.
"""
import pytest
from httpx import AsyncClient


class TestAuth:
    """Test authentication endpoints."""
    
    async def test_register_user(self, client: AsyncClient):
        """Test user registration."""
        response = await client.post(
            "/api/auth/register",
            json={
                "username": "newuser",
                "email": "newuser@example.com",
                "password": "password123",
            },
        )
        assert response.status_code == 201
        data = response.json()
        assert data["username"] == "newuser"
        assert data["email"] == "newuser@example.com"
        assert "id" in data
        assert "hashed_password" not in data
    
    async def test_register_duplicate_username(self, client: AsyncClient, test_user_data):
        """Test registration with duplicate username."""
        # First registration
        await client.post(
            "/api/auth/register",
            json=test_user_data,
        )
        
        # Second registration with same username
        response = await client.post(
            "/api/auth/register",
            json={
                "username": test_user_data["username"],
                "email": "different@example.com",
                "password": "password123",
            },
        )
        assert response.status_code == 400
        assert "Username already registered" in response.json()["detail"]
    
    async def test_login_success(self, client: AsyncClient, test_user_data):
        """Test successful login."""
        # Register user first
        await client.post(
            "/api/auth/register",
            json=test_user_data,
        )
        
        # Login
        response = await client.post(
            "/api/auth/login",
            data={
                "username": test_user_data["username"],
                "password": test_user_data["password"],
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    async def test_login_invalid_credentials(self, client: AsyncClient, test_user_data):
        """Test login with invalid credentials."""
        # Register user first
        await client.post(
            "/api/auth/register",
            json=test_user_data,
        )
        
        # Login with wrong password
        response = await client.post(
            "/api/auth/login",
            data={
                "username": test_user_data["username"],
                "password": "wrongpassword",
            },
        )
        assert response.status_code == 401
        assert "Incorrect username or password" in response.json()["detail"]
    
    async def test_get_me(self, authenticated_client):
        """Test get current user."""
        client, auth = authenticated_client
        response = await client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {auth['access_token']}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "testuser"
        assert "email" in data
    
    async def test_get_me_unauthorized(self, client: AsyncClient):
        """Test get current user without authentication."""
        response = await client.get("/api/auth/me")
        assert response.status_code == 401
