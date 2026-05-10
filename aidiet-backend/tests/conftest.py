"""
Test configuration — SQLite override for integration tests.

Replaces PostgreSQL dependency with in-memory SQLite so tests
can run without a database server (CI/CD compatible).
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Import Base and get_db from the app
from app.db import Base, get_db
from app.main import app

# Import all models so they register with Base.metadata
from app.models.user import User, PlanGenerationLog
from app.api.push import PushDevice

# ============================================================
# SQLite Test Database
# ============================================================

SQLALCHEMY_TEST_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_TEST_URL,
    connect_args={"check_same_thread": False}
)

TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Create all tables
Base.metadata.create_all(bind=engine)


# ============================================================
# Dependency Override
# ============================================================

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


# Override the get_db dependency globally for all tests
app.dependency_overrides[get_db] = override_get_db


# ============================================================
# Fixtures
# ============================================================

@pytest.fixture(autouse=True)
def clean_tables():
    """Clean all tables before each test for isolation."""
    yield
    # Cleanup after test
    db = TestingSessionLocal()
    try:
        for table in reversed(Base.metadata.sorted_tables):
            db.execute(table.delete())
        db.commit()
    except Exception:
        db.rollback()
    finally:
        db.close()
