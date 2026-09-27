from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.database import get_db
from app.models.models import MedicalProfile, GlucoseReading, User
from app.dependencies import get_current_user
from app.services.meal_planner_service import get_meal_recommendations

router = APIRouter()

class MealPlanRequest(BaseModel):
    current_glucose:       float
    hours_since_last_meal: Optional[float] = None  # auto-calculated if None

@router.post("/recommend")
async def recommend_meals(
    data: MealPlanRequest,
    db:   AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Get medical profile
    profile_result = await db.execute(
        select(MedicalProfile)
        .where(MedicalProfile.user_id == current_user.id)
    )
    profile = profile_result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=400,
            detail="Please complete your medical profile first")

    profile_dict = {
        "diabetes_type":  profile.diabetes_type,
        "age":            profile.age,
        "weight_kg":      profile.weight_kg,
        "height_cm":      profile.height_cm,
        "activity_level": profile.activity_level,
    }

    # Auto-calculate hours since last meal from glucose history if not provided
    hours_since = data.hours_since_last_meal
    if hours_since is None:
        readings_result = await db.execute(
            select(GlucoseReading)
            .where(GlucoseReading.user_id == current_user.id)
            .order_by(desc(GlucoseReading.measured_at))
            .limit(1)
        )
        last_reading = readings_result.scalar_one_or_none()
        if last_reading and last_reading.measured_at:
            delta = datetime.utcnow() - last_reading.measured_at.replace(tzinfo=None)
            hours_since = round(max(0.5, delta.total_seconds() / 3600), 1)
        else:
            hours_since = 4.0  # default assumption

    # Get recent readings for trend analysis
    recent_result = await db.execute(
        select(GlucoseReading)
        .where(GlucoseReading.user_id == current_user.id)
        .order_by(desc(GlucoseReading.measured_at))
        .limit(5)
    )
    recent_readings = [
        {"value": r.value_mgdl, "type": r.reading_type}
        for r in recent_result.scalars().all()
    ]

    time_of_day = datetime.utcnow().hour

    recommendations = get_meal_recommendations(
        profile               = profile_dict,
        current_glucose       = data.current_glucose,
        hours_since_last_meal = hours_since,
        time_of_day           = time_of_day,
        recent_readings       = recent_readings,
    )

    return recommendations


@router.get("/quick")
async def quick_recommendation(
    db:           AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Quick recommendation using the user's latest logged glucose reading.
    No input needed — just call this endpoint and get recommendations.
    """
    # Get latest glucose reading
    reading_result = await db.execute(
        select(GlucoseReading)
        .where(GlucoseReading.user_id == current_user.id)
        .order_by(desc(GlucoseReading.measured_at))
        .limit(1)
    )
    latest = reading_result.scalar_one_or_none()
    if not latest:
        raise HTTPException(status_code=400,
            detail="No glucose readings found. Log a reading first.")

    # Get profile
    profile_result = await db.execute(
        select(MedicalProfile)
        .where(MedicalProfile.user_id == current_user.id)
    )
    profile = profile_result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=400,
            detail="Please complete your medical profile first.")

    delta       = datetime.utcnow() - latest.measured_at.replace(tzinfo=None)
    hours_since = round(max(0.5, delta.total_seconds() / 3600), 1)

    profile_dict = {
        "diabetes_type":  profile.diabetes_type,
        "age":            profile.age,
        "weight_kg":      profile.weight_kg,
        "height_cm":      profile.height_cm,
        "activity_level": profile.activity_level,
    }

    return get_meal_recommendations(
        profile               = profile_dict,
        current_glucose       = latest.value_mgdl,
        hours_since_last_meal = hours_since,
        time_of_day           = datetime.utcnow().hour,
        recent_readings       = [],
    )
