import os
import sys

# Настраиваем пути для импорта из папки app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db import SessionLocal
from sqlalchemy import text

def run_migration():
    db = SessionLocal()
    try:
        print("Migrating meals_library table for Geo and Budget...")
        
        # 1. Add region
        db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS region VARCHAR(50);"))
        db.execute(text("CREATE INDEX IF NOT EXISTS ix_meals_library_region ON meals_library (region);"))
        
        # 2. Add budget_level
        db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS budget_level VARCHAR(50);"))
        db.execute(text("CREATE INDEX IF NOT EXISTS ix_meals_library_budget_level ON meals_library (budget_level);"))
        
        # 3. Add cooking_time_minutes
        db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS cooking_time_minutes INTEGER DEFAULT 30;"))
        
        # 4. Soft Update existing records (Set region='Global', budget_level='Средний')
        db.execute(text("UPDATE meals_library SET region = 'Global' WHERE region IS NULL;"))
        db.execute(text("UPDATE meals_library SET budget_level = 'Средний' WHERE budget_level IS NULL;"))
        db.execute(text("UPDATE meals_library SET cooking_time_minutes = 30 WHERE cooking_time_minutes IS NULL;"))
        
        db.commit()
        print("✅ Migration completed successfully!")
    except Exception as e:
        db.rollback()
        print(f"❌ Migration failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_migration()
