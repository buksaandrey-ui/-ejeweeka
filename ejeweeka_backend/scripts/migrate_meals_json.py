import os
import sys
import json

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db import SessionLocal
from sqlalchemy import text

def run_migration():
    db = SessionLocal()
    try:
        print("Migrating meals_library to JSON regional_availability...")
        
        # 1. Add regional_availability JSON column
        db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS regional_availability JSONB DEFAULT '{}'::jsonb;"))
        
        # 2. Convert old region/budget into the new JSON format
        # If region='Global', it means it's available everywhere at Средний budget
        update_query = """
        UPDATE meals_library 
        SET regional_availability = jsonb_build_object(
            'СНГ (Россия, Беларусь, Казахстан)', COALESCE(budget_level, 'Средний'),
            'Европа', COALESCE(budget_level, 'Средний'),
            'Азия (Таиланд, Бали)', COALESCE(budget_level, 'Средний')
        )
        WHERE regional_availability = '{}'::jsonb OR regional_availability IS NULL;
        """
        db.execute(text(update_query))
        
        # 3. Drop the old columns
        db.execute(text("ALTER TABLE meals_library DROP COLUMN IF EXISTS region;"))
        db.execute(text("ALTER TABLE meals_library DROP COLUMN IF EXISTS budget_level;"))
        
        db.commit()
        print("✅ Migration to JSON Matrix completed successfully!")
    except Exception as e:
        db.rollback()
        print(f"❌ Migration failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_migration()
