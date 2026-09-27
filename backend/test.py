import asyncio
from app.routers.auth import register, RegisterRequest
from app.database import AsyncSessionLocal

async def main():
    try:
        async with AsyncSessionLocal() as db:
            data = RegisterRequest(email='test6@test.com', password='pwd', name='test')
            res = await register(data, db)
            print("SUCCESS:", res)
    except Exception as e:
        print("ERROR:", str(e))
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
