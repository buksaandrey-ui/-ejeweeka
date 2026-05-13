import os
import sys

# Настраиваем пути для импорта из папки app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db import SessionLocal
from sqlalchemy import text

def run_migration():
    db = SessionLocal()
    try:
        print("Migrating workouts_library table...")
        
        # Add target_goal and alter if exists
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS target_goal VARCHAR(255);"))
        db.execute(text("ALTER TABLE workouts_library ALTER COLUMN target_goal TYPE VARCHAR(255);"))
        db.execute(text("CREATE INDEX IF NOT EXISTS ix_workouts_library_target_goal ON workouts_library (target_goal);"))
        
        # Add difficulty_level and alter if exists
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS difficulty_level VARCHAR(100);"))
        db.execute(text("ALTER TABLE workouts_library ALTER COLUMN difficulty_level TYPE VARCHAR(100);"))
        db.execute(text("CREATE INDEX IF NOT EXISTS ix_workouts_library_difficulty_level ON workouts_library (difficulty_level);"))
        
        # Add location and alter if exists
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS location VARCHAR(100);"))
        db.execute(text("ALTER TABLE workouts_library ALTER COLUMN location TYPE VARCHAR(100);"))
        db.execute(text("CREATE INDEX IF NOT EXISTS ix_workouts_library_location ON workouts_library (location);"))
        
        # Add description
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS description TEXT;"))
        
        # Add JSON arrays
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS muscle_groups JSONB DEFAULT '[]'::jsonb;"))
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS equipment_required JSONB DEFAULT '[]'::jsonb;"))
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS contraindications JSONB DEFAULT '[]'::jsonb;"))
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS safety_tags JSONB DEFAULT '[]'::jsonb;"))
        
        # Add integer fields
        db.execute(text("ALTER TABLE workouts_library ADD COLUMN IF NOT EXISTS estimated_minutes INTEGER DEFAULT 45;"))
        
        db.commit()
        print("✅ Migration completed successfully!")
    except Exception as e:
        db.rollback()
        print(f"❌ Migration failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_migration()
