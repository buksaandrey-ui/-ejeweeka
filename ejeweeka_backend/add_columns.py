import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '.'))

from app.db import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    print("Adding meal_type...")
    db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS meal_type VARCHAR(50);"))
    db.execute(text("CREATE INDEX IF NOT EXISTS ix_meals_library_meal_type ON meals_library (meal_type);"))
    
    print("Adding allergens_present...")
    db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS allergens_present JSONB DEFAULT '[]'::jsonb;"))
    
    print("Adding safe_for_diseases...")
    db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS safe_for_diseases JSONB DEFAULT '[]'::jsonb;"))
    
    print("Adding wellness_rationale...")
    db.execute(text("ALTER TABLE meals_library ADD COLUMN IF NOT EXISTS wellness_rationale VARCHAR(500);"))
    
    db.commit()
    print("Migration completed successfully.")
except Exception as e:
    db.rollback()
    print("Migration failed:", e)
finally:
    db.close()
