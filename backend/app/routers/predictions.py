from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import json
from app.database import get_db
from app.models.models import Prediction, MedicalProfile, User
from app.dependencies import get_current_user
from app.ml.predict import predict_spike

router = APIRouter()

class PredictionRequest(BaseModel):
    food_name:          Optional[str] = "Meal"
    carbs_g:            float
    protein_g:          float
    fat_g:              float
    fiber_g:            float = 0
    pre_meal_glucose:   float
    insulin_dose:       Optional[float] = 0.0
    post_meal_activity: Optional[str] = "none"
    time_of_day:        Optional[int] = None

@router.post("/predict")
async def make_prediction(
    data: PredictionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Get medical profile
    profile_result = await db.execute(
        select(MedicalProfile).where(MedicalProfile.user_id == current_user.id)
    )
    profile = profile_result.scalar_one_or_none()

    if not profile:
        raise HTTPException(
            status_code=400,
            detail="Please complete your medical profile first"
        )

    hour = data.time_of_day if data.time_of_day is not None else datetime.utcnow().hour

    # Run prediction + SHAP
    result = predict_spike(
        carbs_g          = data.carbs_g,
        protein_g        = data.protein_g,
        fat_g            = data.fat_g,
        fiber_g          = data.fiber_g,
        pre_meal_glucose = data.pre_meal_glucose,
        time_of_day      = hour,
        activity_level   = profile.activity_level,
        diabetes_type    = profile.diabetes_type,
        age              = profile.age,
        weight_kg        = profile.weight_kg,
        insulin_dose     = data.insulin_dose or 0.0,
        post_meal_activity = data.post_meal_activity or "none"
    )

    # Save to database — store SHAP values as JSON string
    prediction = Prediction(
        user_id          = current_user.id,
        food_name        = data.food_name or "Meal",
        carbs_g          = data.carbs_g,
        protein_g        = data.protein_g,
        fat_g            = data.fat_g,
        pre_meal_glucose = data.pre_meal_glucose,
        insulin_dose     = data.insulin_dose or 0.0,
        post_meal_activity = data.post_meal_activity or "none",
        time_of_day      = hour,
        activity_level   = profile.activity_level,
        predicted_spike  = result["predicted_spike"],
        shap_values      = json.dumps(result["shap"]["values"])
    )
    db.add(prediction)
    await db.commit()
    await db.refresh(prediction)

    return {
        "prediction_id":       str(prediction.id),
        "predicted_spike":     result["predicted_spike"],
        "predicted_post_meal": result["predicted_post_meal"],
        "pre_meal_glucose":    result["pre_meal_glucose"],
        "risk_level":          result["risk_level"],
        "risk_color":          result["risk_color"],
        "calories":            result["calories"],
        "input_summary": {
            "food_name":          data.food_name or "Meal",
            "carbs_g":            data.carbs_g,
            "protein_g":          data.protein_g,
            "fat_g":              data.fat_g,
            "fiber_g":            data.fiber_g,
            "insulin_dose":       data.insulin_dose or 0.0,
            "post_meal_activity": data.post_meal_activity or "none"
        },
        "explanation": {
            "summary":     result["shap"]["summary"],
            "base_value":  result["shap"]["base_value"],
            "top_factors": result["shap"]["top_factors"],
            "all_values":  result["shap"]["values"]
        }
    }

@router.get("/history")
async def prediction_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(Prediction)
        .where(Prediction.user_id == current_user.id)
        .order_by(Prediction.predicted_at.desc())
    )
    predictions = result.scalars().all()
    return {
        "total": len(predictions),
        "predictions": [
            {
                "id":                 str(p.id),
                "food_name":          p.food_name or "Meal",
                "carbs_g":            p.carbs_g or 0.0,
                "protein_g":          p.protein_g or 0.0,
                "fat_g":              p.fat_g or 0.0,
                "pre_meal_glucose":   p.pre_meal_glucose or 100.0,
                "insulin_dose":       p.insulin_dose or 0.0,
                "post_meal_activity": p.post_meal_activity or "none",
                "predicted_spike":    p.predicted_spike or 0.0,
                "predicted_post_meal":(p.pre_meal_glucose or 100.0) + (p.predicted_spike or 0.0),
                "predicted_at":       (p.predicted_at.isoformat() + ("Z" if p.predicted_at and not p.predicted_at.tzinfo else "")) if p.predicted_at else None,
                "shap_values":        json.loads(p.shap_values) if p.shap_values else None
            }
            for p in predictions
        ]
    }