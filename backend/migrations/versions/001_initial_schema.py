"""Initial database schema for RAYS backend.

Revision ID: 001_initial_schema
Revises: None
Create Date: 2026-05-25 00:00:00.000000

This migration creates the initial schema with:
- user_telemetry table for storing user behavioral and health data
- user_feedback table for user-reported stress levels
"""
from alembic import op
import sqlalchemy as sa

revision = '001_initial_schema'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create initial tables."""
    # Create user_telemetry table
    op.create_table(
        'user_telemetry',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('device_id', sa.String(255), nullable=False),
        sa.Column('timestamp', sa.DateTime(), nullable=True),
        sa.Column('sleep_minutes', sa.Integer(), nullable=True),
        sa.Column('total_screen_minutes', sa.Integer(), nullable=True),
        sa.Column('social_minutes', sa.Integer(), nullable=True),
        sa.Column('exercise_minutes', sa.Integer(), nullable=True),
        sa.Column('pickup_count', sa.Integer(), nullable=True),
        sa.Column('resting_heart_rate', sa.Integer(), nullable=True),
        sa.Column('hrv_score', sa.Float(), nullable=True),
        sa.Column('doom_scroll_flag', sa.Boolean(), nullable=True),
        sa.Column('late_night_usage', sa.Boolean(), nullable=True),
        sa.Column('predicted_stress_score', sa.Integer(), nullable=True),
        sa.Column('predicted_risk_level', sa.String(50), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.Index('ix_user_telemetry_device_id', 'device_id'),
        sa.Index('ix_user_telemetry_timestamp', 'timestamp'),
    )

    # Create user_feedback table
    op.create_table(
        'user_feedback',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('device_id', sa.String(255), nullable=False),
        sa.Column('timestamp', sa.DateTime(), nullable=True),
        sa.Column('reported_stress_level', sa.Integer(), nullable=False),
        sa.Column('context', sa.String(500), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.Index('ix_user_feedback_device_id', 'device_id'),
        sa.Index('ix_user_feedback_timestamp', 'timestamp'),
    )


def downgrade() -> None:
    """Drop initial tables."""
    op.drop_table('user_feedback')
    op.drop_table('user_telemetry')
