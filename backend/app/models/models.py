from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Integer, Text, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declarative_base
from sqlalchemy.sql import func
import uuid

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id            = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email         = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    name          = Column(String(100))
    created_at    = Column(DateTime(timezone=True), server_default=func.now())

class MedicalProfile(Base):
    __tablename__ = 'medical_profiles'
    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id         = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), unique=True)
    diabetes_type   = Column(String(20))       # type1 / type2 / prediabetes
    age             = Column(Integer)
    weight_kg       = Column(Float)
    height_cm       = Column(Float)
    activity_level  = Column(String(20))       # sedentary / light / moderate / active
    medications     = Column(Text)             # free text list of medications
    conditions      = Column(Text)             # other conditions: hypertension, etc.
    updated_at      = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class GlucoseReading(Base):
    __tablename__ = 'glucose_readings'
    id           = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id      = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'))
    value_mgdl   = Column(Float, nullable=False)
    reading_type = Column(String(20))          # fasting / post_meal / bedtime / random
    notes        = Column(Text)
    measured_at  = Column(DateTime(timezone=True), server_default=func.now())

class Prediction(Base):
    __tablename__ = 'predictions'
    id              = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id         = Column(UUID(as_uuid=True), ForeignKey('users.id'))
    carbs_g         = Column(Float)
    protein_g       = Column(Float)
    fat_g           = Column(Float)
    pre_meal_glucose= Column(Float)
    time_of_day     = Column(Integer)          # hour 0-23
    activity_level  = Column(String(20))
    predicted_spike = Column(Float)
    actual_spike    = Column(Float)            # filled in later when user logs post-meal reading
    shap_values     = Column(Text)             # stored as JSON string
    predicted_at    = Column(DateTime(timezone=True), server_default=func.now())