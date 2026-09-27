import os
import re
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.database import get_db
from app.models.models import MedicalProfile, User, GovtIdVerification, GlucoseReading, Prediction
from app.dependencies import get_current_user


router = APIRouter()

ID_REGEX_PATTERNS = {
    "aadhaar": r"^\d{12}$",
    "pan": r"^[A-Z]{5}[0-9]{4}[A-Z]$",
    "passport": r"^[A-Z][0-9]{7}$",
    "voter_id": r"^[A-Z]{3}[0-9]{7}$",
}

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

@router.post("/upload-avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    filename = f"avatar_{current_user.id}_{uuid.uuid4().hex[:8]}.{extension}"
    filepath = os.path.join("uploads", "avatars", filename)
    
    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)

    relative_url = f"/uploads/avatars/{filename}"
    current_user.profile_picture_url = relative_url
    await db.commit()
    await db.refresh(current_user)

    return {
        "message": "Avatar uploaded successfully",
        "profile_picture_url": relative_url
    }

@router.post("/govt-id")
async def submit_govt_id(
    id_type: str = Form(...),
    id_number: str = Form(...),
    document_image: Optional[UploadFile] = File(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    id_type_clean = id_type.strip().lower()
    id_num_clean = id_number.strip().upper()

    if id_type_clean not in ID_REGEX_PATTERNS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid ID type. Allowed: {list(ID_REGEX_PATTERNS.keys())}"
        )
    
    pattern = ID_REGEX_PATTERNS[id_type_clean]
    if not re.match(pattern, id_num_clean):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid format for {id_type_clean.upper()} number."
        )
    
    doc_url = None
    if document_image:
        if not document_image.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Document file must be an image")
        
        ext = document_image.filename.split(".")[-1] if "." in document_image.filename else "jpg"
        doc_filename = f"id_{current_user.id}_{uuid.uuid4().hex[:8]}.{ext}"
        doc_filepath = os.path.join("uploads", "govt_ids", doc_filename)
        
        contents = await document_image.read()
        with open(doc_filepath, "wb") as f:
            f.write(contents)
        doc_url = f"/uploads/govt_ids/{doc_filename}"

    # Check existing verification record
    result = await db.execute(
        select(GovtIdVerification).where(GovtIdVerification.user_id == current_user.id)
    )
    govt_id = result.scalar_one_or_none()

    if govt_id:
        govt_id.id_type = id_type_clean
        govt_id.id_number = id_num_clean
        if doc_url:
            govt_id.document_image_url = doc_url
        govt_id.status = "pending"
        govt_id.rejection_reason = None
    else:
        govt_id = GovtIdVerification(
            user_id=current_user.id,
            id_type=id_type_clean,
            id_number=id_num_clean,
            document_image_url=doc_url,
            status="pending"
        )
        db.add(govt_id)

    await db.commit()
    await db.refresh(govt_id)

    return {
        "message": "Govt ID submitted successfully",
        "id_type": govt_id.id_type,
        "id_number": govt_id.id_number,
        "status": govt_id.status,
        "document_image_url": govt_id.document_image_url
    }

@router.get("/govt-id")
async def get_govt_id(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(GovtIdVerification).where(GovtIdVerification.user_id == current_user.id)
    )
    govt_id = result.scalar_one_or_none()
    if not govt_id:
        return {"status": "unverified", "message": "No Govt ID submitted"}
    return {
        "id_type": govt_id.id_type,
        "id_number": govt_id.id_number,
        "document_image_url": govt_id.document_image_url,
        "status": govt_id.status,
        "rejection_reason": govt_id.rejection_reason,
        "submitted_at": govt_id.submitted_at
    }

class AdminKycVerificationRequest(BaseModel):
    user_email: str
    status: str  # verified / rejected / pending
    rejection_reason: Optional[str] = None

@router.post("/admin/verify-kyc")
async def admin_verify_kyc(
    data: AdminKycVerificationRequest,
    db: AsyncSession = Depends(get_db),
):
    if data.status not in ["verified", "rejected", "pending"]:
        raise HTTPException(
            status_code=400,
            detail="Status must be one of: 'verified', 'rejected', 'pending'"
        )

    # Find user by email
    user_result = await db.execute(select(User).where(User.email == data.user_email.strip()))
    user = user_result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=444 if False else 404, detail="User with this email not found")

    # Find or create Govt ID record
    id_result = await db.execute(
        select(GovtIdVerification).where(GovtIdVerification.user_id == user.id)
    )
    govt_id = id_result.scalar_one_or_none()

    if not govt_id:
        raise HTTPException(
            status_code=400,
            detail="User has not submitted a Govt ID yet"
        )

    govt_id.status = data.status
    if data.status == "rejected":
        govt_id.rejection_reason = data.rejection_reason or "Document verification failed."
    elif data.status == "verified":
        govt_id.rejection_reason = None

    await db.commit()
    await db.refresh(govt_id)

    return {
        "message": f"User KYC status updated to '{govt_id.status}'",
        "user_email": user.email,
        "status": govt_id.status,
        "rejection_reason": govt_id.rejection_reason
    }

@router.get("/admin/verifications")
async def get_all_verifications(
    db: AsyncSession = Depends(get_db)
):
    # Fetch all users
    result = await db.execute(select(User))
    users = result.scalars().all()

    # Fetch all govt id records
    id_result = await db.execute(select(GovtIdVerification))
    verifications = id_result.scalars().all()
    kyc_map = {v.user_id: v for v in verifications}

    items = []
    for user in users:
        kyc = kyc_map.get(user.id)
        items.append({
            "user_id": str(user.id),
            "email": user.email,
            "name": user.name or "Unnamed User",
            "profile_picture_url": user.profile_picture_url,
            "status": kyc.status if kyc else "unverified",
            "id_type": kyc.id_type if kyc else None,
            "id_number": kyc.id_number if kyc else None,
            "document_image_url": kyc.document_image_url if kyc else None,
            "rejection_reason": kyc.rejection_reason if kyc else None,
            "submitted_at": kyc.submitted_at.isoformat() if kyc and kyc.submitted_at else None,
        })

    return items

@router.delete("/admin/patient/{identifier}")
async def delete_patient(
    identifier: str,
    db: AsyncSession = Depends(get_db)
):
    identifier_clean = identifier.strip()
    
    user = None
    # 1. Try lookup by UUID
    try:
        target_uuid = uuid.UUID(identifier_clean)
        result = await db.execute(select(User).where(User.id == target_uuid))
        user = result.scalar_one_or_none()
    except ValueError:
        pass

    # 2. Try lookup by Email if UUID failed or not matched
    if not user:
        result = await db.execute(select(User).where(User.email == identifier_clean))
        user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail=f"Patient '{identifier}' not found")

    user_uuid = user.id

    # Clean up associated records explicitly across all related tables
    await db.execute(delete(GovtIdVerification).where(GovtIdVerification.user_id == user_uuid))
    await db.execute(delete(MedicalProfile).where(MedicalProfile.user_id == user_uuid))
    await db.execute(delete(GlucoseReading).where(GlucoseReading.user_id == user_uuid))
    await db.execute(delete(Prediction).where(Prediction.user_id == user_uuid))

    await db.delete(user)
    await db.commit()

    return {"message": "Patient deleted successfully", "user_id": str(user_uuid), "email": user.email}





@router.get("/me")
async def get_me(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(
        select(GovtIdVerification).where(GovtIdVerification.user_id == current_user.id)
    )
    govt_id = result.scalar_one_or_none()
    kyc_status = govt_id.status if govt_id else "unverified"

    return {
        "id": str(current_user.id),
        "email": current_user.email,
        "name": current_user.name,
        "profile_picture_url": current_user.profile_picture_url,
        "kyc_status": kyc_status
    }
