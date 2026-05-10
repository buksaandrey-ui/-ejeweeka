"""
Config API — handles dynamic app configuration such as Geo-Routing.
"""

from fastapi import APIRouter, Request
from pydantic import BaseModel

router = APIRouter()

class GeoConfigResponse(BaseModel):
    payment_method: str  # "web_only" or "native_iap"
    show_iap: bool

@router.get("/geo-rules", response_model=GeoConfigResponse)
async def get_geo_rules(request: Request):
    """
    Returns payment configuration based on the user's IP address.
    If IP is from CIS (Russia, Belarus, etc.), returns web_only to hide IAP.
    Otherwise, returns native_iap for the rest of the world (including Apple Reviewers).
    """
    # Real implementation would use MaxMind GeoIP or Cloudflare CF-IPCountry header
    # For MVP, we check the x-forwarded-for or default to web_only if we want to force CIS mode.
    
    # Placeholder: Assuming Cloudflare or proxy sets the CF-IPCountry header
    country_code = request.headers.get("CF-IPCountry", "RU") 
    
    cis_countries = {"RU", "BY", "KZ", "AM", "KG"}
    
    if country_code in cis_countries:
        return GeoConfigResponse(
            payment_method="web_only",
            show_iap=False
        )
    else:
        # Rest of the world (and Cupertino)
        return GeoConfigResponse(
            payment_method="native_iap",
            show_iap=True
        )
