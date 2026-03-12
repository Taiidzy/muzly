"""Initial migration - create all tables

Revision ID: initial
Revises: 
Create Date: 2024-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel

# revision identifiers, used by Alembic.
revision: str = 'initial'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('email', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('hashed_password', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('is_superuser', sa.Boolean(), nullable=False, default=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    
    # Create tracks table
    op.create_table(
        'tracks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('artist', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('album', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('duration_ms', sa.Integer(), nullable=True),
        sa.Column('file_path', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('cover_path', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('source', sa.Enum('IMPORT', 'MANUAL', name='tracksource'), nullable=False, default='MANUAL'),
        sa.Column('status', sa.Enum('QUEUED', 'DOWNLOADING', 'READY', 'FAILED', name='trackstatus'), nullable=False, default='READY'),
        sa.Column('error_message', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('file_size', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_tracks_title'), 'tracks', ['title'])
    op.create_index(op.f('ix_tracks_artist'), 'tracks', ['artist'])
    
    # Create playlists table
    op.create_table(
        'playlists',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('description', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('visibility', sa.Enum('PRIVATE', 'PUBLIC', name='playlistvisibility'), nullable=False, default='PRIVATE'),
        sa.Column('owner_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_playlists_owner_id'), 'playlists', ['owner_id'])
    
    # Create playlist_tracks table
    op.create_table(
        'playlist_tracks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('playlist_id', sa.Integer(), nullable=False),
        sa.Column('track_id', sa.Integer(), nullable=False),
        sa.Column('position', sa.Integer(), nullable=False, default=0),
        sa.Column('added_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['playlist_id'], ['playlists.id'], ),
        sa.ForeignKeyConstraint(['track_id'], ['tracks.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_playlist_tracks_playlist_id'), 'playlist_tracks', ['playlist_id'])
    op.create_index(op.f('ix_playlist_tracks_track_id'), 'playlist_tracks', ['track_id'])
    
    # Create favorites table
    op.create_table(
        'favorites',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('track_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['track_id'], ['tracks.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_favorites_user_id'), 'favorites', ['user_id'])
    op.create_index(op.f('ix_favorites_track_id'), 'favorites', ['track_id'])
    
    # Create import_tasks table
    op.create_table(
        'import_tasks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('task_id', sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('status', sqlmodel.sql.sqltypes.AutoString(), nullable=False, default='pending'),
        sa.Column('total_tracks', sa.Integer(), nullable=False, default=0),
        sa.Column('processed_tracks', sa.Integer(), nullable=False, default=0),
        sa.Column('failed_tracks', sa.Integer(), nullable=False, default=0),
        sa.Column('error_message', sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_import_tasks_task_id'), 'import_tasks', ['task_id'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_import_tasks_task_id'), table_name='import_tasks')
    op.drop_table('import_tasks')
    op.drop_index(op.f('ix_favorites_track_id'), table_name='favorites')
    op.drop_index(op.f('ix_favorites_user_id'), table_name='favorites')
    op.drop_table('favorites')
    op.drop_index(op.f('ix_playlist_tracks_track_id'), table_name='playlist_tracks')
    op.drop_index(op.f('ix_playlist_tracks_playlist_id'), table_name='playlist_tracks')
    op.drop_table('playlist_tracks')
    op.drop_index(op.f('ix_playlists_owner_id'), table_name='playlists')
    op.drop_table('playlists')
    op.drop_index(op.f('ix_tracks_artist'), table_name='tracks')
    op.drop_index(op.f('ix_tracks_title'), table_name='tracks')
    op.drop_table('tracks')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_index(op.f('ix_users_username'), table_name='users')
    op.drop_table('users')
