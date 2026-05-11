import asyncio
from app.api.plan import generate_plan_internal, UserProfilePayload
from dotenv import load_dotenv
load_dotenv()

async def main():
    payload = UserProfilePayload(
        age=30,
        gender="female",
        weight=65.0,
        height=165.0,
        goal="Снизить вес",
        activity_level="Умеренная",
        tier="gold"
    )
    result = await generate_plan_internal(payload)
    import json
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    asyncio.run(main())
