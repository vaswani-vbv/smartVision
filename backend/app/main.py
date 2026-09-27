import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.routers import auth, users, glucose, predictions, camera, meal_planner
from app.database import engine
from app.models.models import Base

import bcrypt
from sqlalchemy.future import select
from app.database import engine, AsyncSessionLocal
from app.models.models import Base, User

# Ensure upload directories exist
os.makedirs("uploads/avatars", exist_ok=True)
os.makedirs("uploads/govt_ids", exist_ok=True)

app = FastAPI(title="SmartVision API", version="1.0.0")

async def seed_default_admin():
    async with AsyncSessionLocal() as db:
        res = await db.execute(select(User).where(User.email == "admin@smartvision.com"))
        if not res.scalar_one_or_none():
            salt = bcrypt.gensalt()
            hashed = bcrypt.hashpw("Admin@123".encode('utf-8'), salt).decode('utf-8')
            admin_user = User(
                email="admin@smartvision.com",
                password_hash=hashed,
                name="Hospital Admin"
            )
            db.add(admin_user)
            await db.commit()

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await seed_default_admin()


app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,         prefix="/api/auth",         tags=["Authentication"])
app.include_router(users.router,        prefix="/api/users",        tags=["Users"])
app.include_router(glucose.router,      prefix="/api/glucose",      tags=["Glucose"])
app.include_router(predictions.router,  prefix="/api/predictions",  tags=["Predictions"])
app.include_router(camera.router,       prefix="/api/camera",       tags=["Camera"])
app.include_router(meal_planner.router, prefix="/api/meal-planner", tags=["Meal Planner"])

@app.get("/")
def root():
    return {"status": "SmartVision API is running"}

@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "SmartVision API is running"}