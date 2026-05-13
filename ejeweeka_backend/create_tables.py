from app.db import engine, Base
from app.models.recipe_cache import CheatSheetCache
Base.metadata.create_all(bind=engine)
print("Missing tables created successfully!")
