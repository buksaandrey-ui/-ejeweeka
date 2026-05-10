import sys
from pathlib import Path

sys.path.append(str(Path.cwd() / "aidiet-backend"))
from app.db import engine
from app.models.knowledge_base import ProcessedVideo, KnowledgeChunk

# Only create missing tables
ProcessedVideo.__table__.create(engine, checkfirst=True)
print("ProcessedVideo table created!")
