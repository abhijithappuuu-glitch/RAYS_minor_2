#!/usr/bin/env python
"""
Database Migration Script for RAYS Backend

Usage:
    python manage_migrations.py upgrade     # Apply all pending migrations
    python manage_migrations.py downgrade   # Rollback last migration
    python manage_migrations.py current     # Show current migration version
    python manage_migrations.py history     # Show migration history
"""
import os
import sys
import argparse
from alembic.config import Config
from alembic import command

def get_migration_config():
    """Get Alembic configuration."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config = Config(os.path.join(script_dir, 'migrations', 'alembic.ini'))
    config.set_main_option('script_location', os.path.join(script_dir, 'migrations'))
    config.set_main_option('sqlalchemy.url', 
                          os.getenv('DATABASE_URL', 'sqlite:///rays.db'))
    return config

def main():
    parser = argparse.ArgumentParser(description='Manage database migrations')
    parser.add_argument('command', choices=['upgrade', 'downgrade', 'current', 'history', 'init'],
                       help='Migration command to execute')
    parser.add_argument('--revision', default='head',
                       help='Target revision (for upgrade/downgrade)')
    args = parser.parse_args()

    config = get_migration_config()

    try:
        if args.command == 'upgrade':
            print(f"Upgrading database to {args.revision}...")
            command.upgrade(config, args.revision)
            print("✅ Database upgrade successful!")
        
        elif args.command == 'downgrade':
            print(f"Downgrading database by 1 revision...")
            command.downgrade(config, '-1')
            print("✅ Database downgrade successful!")
        
        elif args.command == 'current':
            print("Current database revision:")
            command.current(config)
        
        elif args.command == 'history':
            print("Migration history:")
            command.history(config)
        
        elif args.command == 'init':
            print("Initializing migrations...")
            command.stamp(config, 'head')
            print("✅ Migrations initialized!")
    
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
