from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.database import get_db
from app.models.models import MedicalProfile, User
from app.dependencies import get_current_user

router = APIRouter()

class MedicalProfileRequest(BaseModel):
    diabetes_type: str        # type1 / type2 / prediabetes
    age: int
    weight_kg: float
    height_cm: float
    activity_level: str       # sedentary / light / moderate / active
    medications: Optional[str] = None
    conditions: Optional[str] = None

@router.post("/profile")
async def save_profile(
    data: MedicalProfileRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if profile already exists
    result = await db.execute(
        select(MedicalProfile).where(MedicalProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()

    if profile:
        # Update existing profile
        profile.diabetes_type  = data.diabetes_type
        profile.age            = data.age
        profile.weight_kg      = data.weight_kg
        profile.height_cm      = data.height_cm
        profile.activity_level = data.activity_level
        profile.medications    = data.medications
        profile.conditions     = data.conditions
    else:
        # Create new profile
        profile = MedicalProfile(
            user_id        = current_user.id,
            diabetes_type  = data.diabetes_type,
            age            = data.age,
            weight_kg      = data.weight_kg,
            height_cm      = data.height_cm,
            activity_level = data.activity_level,
            medications    = data.medications,
            conditions     = data.conditions
        )
        db.add(profile)

    await db.commit()
    await db.refresh(profile)
    return {"message": "Profile saved", "profile_id": str(profile.id)}

@router.get("/profile")
async def get_profile(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(MedicalProfile).where(MedicalProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        return {"message": "No profile found"}
    return {
        "diabetes_type":  profile.diabetes_type,
        "age":            profile.age,
        "weight_kg":      profile.weight_kg,
        "height_cm":      profile.height_cm,
        "activity_level": profile.activity_level,
        "medications":    profile.medications,
        "conditions":     profile.conditions
    }

@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id":    str(current_user.id),
        "email": current_user.email,
        "name":  current_user.name
    }