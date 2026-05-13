import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db import SessionLocal
from sqlalchemy import text

def run_migration():
    db = SessionLocal()
    try:
        print("Migrating meals_library to add rich_in_microelements...")
        
        # Add rich_in_microelements column
        db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS rich_in_microelements JSONB DEFAULT '[]'::jsonb;"))
        
        db.commit()
        print("✅ Migration completed successfully!")
    except Exception as e:
        db.rollback()
        print(f"❌ Migration failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_migration()
