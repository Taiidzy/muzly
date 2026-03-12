import asyncio
import os
import tempfile
from typing import AsyncGenerator, Generator
from pathlib import Path

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlmodel import SQLModel, create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.main import app
from app.database import get_db, AsyncSessionLocal
from app.models import User, Track, Playlist, Favorite
from app.auth import get_password_hash

# Test database URL (SQLite in memory)
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def test_engine():
    """Create test database engine."""
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        future=True,
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    
    yield engine
    
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)
    
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def test_db(test_engine) -> AsyncGenerator[AsyncSession, None]:
    """Create test database session."""
    async_session = async_sessionmaker(
        test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )
    
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture(scope="function")
async def client(test_db: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Create test HTTP client."""
    # Override dependency
    async def override_get_db():
        yield test_db
    
    app.dependency_overrides[get_db] = override_get_db
    
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
    
    app.dependency_overrides.clear()


@pytest.fixture
def test_user_data():
    """Test user data."""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpass123",
    }


@pytest_asyncio.fixture
async def authenticated_client(
    client: AsyncClient,
    test_db: AsyncSession,
    test_user_data: dict,
) -> AsyncGenerator[tuple[AsyncClient, dict], None]:
    """Create authenticated test client."""
    # Create user
    user = User(
        username=test_user_data["username"],
        email=test_user_data["email"],
        hashed_password=get_password_hash(test_user_data["password"]),
        is_active=True,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)
    
    # Login
    response = await client.post(
        "/api/auth/login",
        data={
            "username": test_user_data["username"],
            "password": test_user_data["password"],
        },
    )
    
    token = response.json()["access_token"]
    
    yield client, {"access_token": token, "token_type": "bearer"}


@pytest_asyncio.fixture
async def sample_track(test_db: AsyncSession) -> Track:
    """Create a sample track."""
    track = Track(
        title="Test Song",
        artist="Test Artist",
        album="Test Album",
        source="manual",
        status="ready",
        file_path="/tmp/test.mp3",
    )
    test_db.add(track)
    await test_db.commit()
    await test_db.refresh(track)
    return track


@pytest_asyncio.fixture
async def sample_playlist(test_db: AsyncSession, authenticated_client) -> Playlist:
    """Create a sample playlist."""
    client, auth = authenticated_client
    response = await client.post(
        "/api/playlists",
        json={"name": "Test Playlist", "description": "Test Description"},
        headers={"Authorization": f"Bearer {auth['access_token']}"},
    )
    return Playlist(**response.json())
