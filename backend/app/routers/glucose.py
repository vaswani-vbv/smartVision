from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, timedelta
from app.database import get_db
from app.models.models import GlucoseReading, User
from app.dependencies import get_current_user

router = APIRouter()

class GlucoseLogRequest(BaseModel):
    value_mgdl: float
    reading_type: str      # fasting / post_meal / bedtime / random
    notes: Optional[str] = None
    measured_at: Optional[datetime] = None  # if not provided, uses current time

class GlucoseResponse(BaseModel):
    id: str
    value_mgdl: float
    reading_type: str
    notes: Optional[str]
    measured_at: datetime

    class Config:
        from_attributes = True

@router.post("/log")
async def log_glucose(
    data: GlucoseLogRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reading = GlucoseReading(
        user_id      = current_user.id,
        value_mgdl   = data.value_mgdl,
        reading_type = data.reading_type,
        notes        = data.notes,
        measured_at  = data.measured_at or datetime.utcnow()
    )
    db.add(reading)
    await db.commit()
    await db.refresh(reading)
    return {
        "message":      "Glucose reading logged",
        "reading_id":   str(reading.id),
        "value_mgdl":   reading.value_mgdl,
        "reading_type": reading.reading_type,
        "measured_at":  reading.measured_at.isoformat() + ("Z" if reading.measured_at and not reading.measured_at.tzinfo else "")
    }

@router.get("/history")
async def get_history(
    days: int = 30,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    cutoff = datetime.utcnow() - timedelta(days=days)
    result = await db.execute(
        select(GlucoseReading)
        .where(GlucoseReading.user_id == current_user.id)
        .where(GlucoseReading.measured_at >= cutoff)
        .order_by(desc(GlucoseReading.measured_at))
    )
    readings = result.scalars().all()
    return {
        "total": len(readings),
        "days":  days,
        "readings": [
            {
                "id":           str(r.id),
                "value_mgdl":   r.value_mgdl,
                "reading_type": r.reading_type,
                "notes":        r.notes,
                "measured_at":  r.measured_at.isoformat() + ("Z" if r.measured_at and not r.measured_at.tzinfo else "") if r.measured_at else None
            }
            for r in readings
        ]
    }

@router.get("/stats")
async def get_stats(
    days: int = 30,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    cutoff = datetime.utcnow() - timedelta(days=days)
    result = await db.execute(
        select(GlucoseReading)
        .where(GlucoseReading.user_id == current_user.id)
        .where(GlucoseReading.measured_at >= cutoff)
    )
    readings = result.scalars().all()

    if not readings:
        return {"message": "No readings found for this period"}

    values = [r.value_mgdl for r in readings]
    avg    = sum(values) / len(values)
    high   = max(values)
    low    = min(values)

    # Count readings in each zone
    in_range   = len([v for v in values if 70 <= v <= 140])
    above_range = len([v for v in values if v > 140])
    below_range = len([v for v in values if v < 70])

    return {
        "period_days":   days,
        "total_readings": len(values),
        "average_mgdl":  round(avg, 1),
        "highest_mgdl":  high,
        "lowest_mgdl":   low,
        "in_range":      in_range,
        "above_range":   above_range,
        "below_range":   below_range,
        "in_range_pct":  round((in_range / len(values)) * 100, 1)
    }

@router.delete("/reading/{reading_id}")
async def delete_reading(
    reading_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(GlucoseReading)
        .where(GlucoseReading.id == reading_id)
        .where(GlucoseReading.user_id == current_user.id)
    )
    reading = result.scalar_one_or_none()
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    await db.delete(reading)
    await db.commit()
    return {"message": "Reading deleted"}