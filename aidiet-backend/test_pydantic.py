from pydantic import BaseModel
from typing import Optional, List
class UserProfilePayload(BaseModel):
    womens_health: Optional[List[str]] = None

try:
    p = UserProfilePayload(womens_health="Беременность, СПКЯ")
    print("Success:", p.womens_health)
except Exception as e:
    print("Error:", e)
