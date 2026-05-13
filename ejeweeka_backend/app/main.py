"""
ejeweeka Core API — Main Application Entry Point.

Production-hardened configuration:
- CORS whitelist (configurable via env)
- Rate limiting (slowapi) per endpoint
- Sentry error monitoring
- Structured logging
- Request/response middleware
- Health check with DB + Gemini status
- Auto-create tables on startup
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
import os
import time
import logging

# ============================================================
# LOGGING
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("ejeweeka")


# ============================================================
# SENTRY (Error Monitoring)
# ============================================================

SENTRY_DSN = os.getenv("SENTRY_DSN")
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.fastapi import FastApiIntegration
    from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[FastApiIntegration(), SqlalchemyIntegration()],
        traces_sample_rate=0.1,  # 10% of requests traced (performance)
        environment=os.getenv("ENVIRONMENT", "development"),
        release="ejeweeka@2.2.0",
    )
    logger.info("🛡️  Sentry initialized")
else:
    logger.info("⚠️  SENTRY_DSN not set — error monitoring disabled")


# ============================================================
# APP
# ============================================================

app = FastAPI(
    title="ejeweeka Core API",
    description="Backend for ejeweeka: RAG Engine, PostgreSQL, LLM integrations, Hybrid Monetization",
    version="3.0.0",
)


# ============================================================
# RATE LIMITING
# ============================================================

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address, default_limits=["60/minute"])
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# ============================================================
# CORS
# ============================================================

# Production whitelist — can be overridden via CORS_ORIGINS env
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "").split(",") if os.getenv("CORS_ORIGINS") else [
    "https://main-screens.vercel.app",
    "https://ejeweeka-docs.vercel.app",
    "capacitor://localhost",       # iOS Capacitor
    "http://localhost",            # Android Capacitor
    "http://localhost:3000",       # Local dev
    "http://localhost:8080",       # Local dev
    "http://127.0.0.1:8001",      # Local FastAPI
]

# In development, allow all origins for testing
IS_DEV = os.getenv("ENVIRONMENT", "development") == "development"

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if IS_DEV else CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# MIDDLEWARE
# ============================================================

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests with timing + unified error format."""
    start = time.time()
    
    try:
        response = await call_next(request)
    except Exception as e:
        logger.error(f"❌ {request.method} {request.url.path} — Unhandled error: {e}")
        # Report to Sentry if enabled
        if SENTRY_DSN:
            import sentry_sdk
            sentry_sdk.capture_exception(e)
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "detail": "Internal server error",
                "error_code": "INTERNAL_ERROR",
                "path": str(request.url.path),
            }
        )
    
    duration_ms = round((time.time() - start) * 1000)
    
    # Only log non-health-check requests to reduce noise
    if request.url.path not in ("/", "/api/v1/health"):
        logger.info(
            f"{'✅' if response.status_code < 400 else '⚠️'} "
            f"{request.method} {request.url.path} → {response.status_code} ({duration_ms}ms)"
        )
    
    # Add standard headers
    response.headers["X-Request-Time-Ms"] = str(duration_ms)
    response.headers["X-API-Version"] = "2.2.0"
    
    return response


# ============================================================
# STATIC FILES
# ============================================================

images_dir = os.path.join(os.path.dirname(__file__), '../data/images')
os.makedirs(images_dir, exist_ok=True)
app.mount("/images", StaticFiles(directory=images_dir), name="images")


# ============================================================
# ROUTERS
# ============================================================

from app.api.plan import router as plan_router
from app.api.photo import router as photo_router
from app.api.recipes import router as recipes_router
from app.api.auth import router as auth_router
from app.api.chat import router as chat_router
from app.api.report import router as report_router
from app.api.billing import router as billing_router
from app.api.push import router as push_router
from app.api.subscription import router as subscription_router
from app.api.config import router as config_router
from app.api.drinks import router as drinks_router
from app.api.entitlement import router as entitlement_router
from app.api.web_billing import router as web_billing_router

app.include_router(plan_router, prefix="/api/v1/plan", tags=["Meal Plan"])
app.include_router(photo_router, prefix="/api/v1/photo", tags=["Photo Analysis"])
app.include_router(recipes_router, prefix="/api/v1/recipes", tags=["Recipes"])
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(chat_router, prefix="/api/v1/chat", tags=["AI Chat"])
app.include_router(report_router, prefix="/api/v1/report", tags=["Reports"])
app.include_router(billing_router, prefix="/api/v1/billing", tags=["Billing"])
app.include_router(push_router, prefix="/api/v1/push", tags=["Push Notifications"])
app.include_router(subscription_router, prefix="/api/v1/subscription", tags=["Subscription"])
app.include_router(config_router, prefix="/api/v1/config", tags=["Config"])
app.include_router(drinks_router, prefix="/api/v1")
# Hybrid Monetization (v3.0)
app.include_router(entitlement_router, tags=["Entitlements"])
app.include_router(web_billing_router, tags=["Web Billing (RU)"])


# ============================================================
# STARTUP
# ============================================================

@app.on_event("startup")
async def startup_event():
    """Auto-create tables that might not exist yet (push_devices, etc.)."""
    try:
        from app.db import engine, Base
        import app.models  # Ensure all models are registered
        
        # Only create tables that don't exist — safe for production
        Base.metadata.create_all(bind=engine, checkfirst=True)
        logger.info("🗄️  Database tables verified/created")
    except Exception as e:
        logger.warning(f"⚠️  Database table creation skipped: {e}")

    logger.info(f"🚀 ejeweeka API v2.2.0 started (env: {'DEV' if IS_DEV else 'PROD'})")
    logger.info(f"   CORS origins: {'*' if IS_DEV else ', '.join(CORS_ORIGINS)}")
    logger.info(f"   Gemini key: {'✅ set' if os.getenv('GEMINI_API_KEY') else '❌ missing'}")
    logger.info(f"   Sentry: {'✅ active' if SENTRY_DSN else '⚠️ disabled'}")
    logger.info(f"   Rate limit: 60/min default, 10/min for /plan/generate")


# ============================================================
# HEALTH CHECKS
# ============================================================

@app.get("/")
def health_check():
    return {
        "status": "ok",
        "message": "ejeweeka Core API is running",
        "version": "2.2.0",
    }


@app.get("/api/v1/health")
def detailed_health():
    """Детальная проверка: сервер + БД + Gemini API key."""
    from app.db import SessionLocal
    checks = {"api": True, "database": False, "gemini_key": False}
    
    try:
        from sqlalchemy import text
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        checks["database"] = True
    except Exception as e:
        checks["db_error"] = str(e)[:100]
    
    checks["gemini_key"] = bool(os.getenv("GEMINI_API_KEY"))
    checks["sentry"] = bool(os.getenv("SENTRY_DSN"))
    
    all_ok = all(v for k, v in checks.items() if not k.endswith("_error"))
    return {
        "status": "ok" if all_ok else "degraded",
        "version": "2.2.0",
        "environment": "development" if IS_DEV else "production",
        "checks": checks,
        "endpoints": [
            "/api/v1/auth/init",
            "/api/v1/auth/verify",
            "/api/v1/plan/generate",
            "/api/v1/photo/analyze",
            "/api/v1/chat/message",
            "/api/v1/report/weekly",
            "/api/v1/billing/status",
            "/api/v1/billing/restore",
            "/api/v1/push/register",
            "/api/v1/push/settings",
        ]
    }
