from fastapi import APIRouter, UploadFile, File, HTTPException
import shutil
import os
from pathlib import Path
from ultralytics import YOLO
from app.nutrition_db import get_food_nutrition

router = APIRouter()

# Load YOLO model (will download yolov8n.pt on first run if not present)
MODEL_PATH = "yolov8n.pt"
model = YOLO(MODEL_PATH)

# Supported classes we have in our database roughly map to these COCO classes
# COCO classes for food: 46: 'banana', 47: 'apple', 48: 'sandwich', 49: 'orange', 50: 'broccoli', 51: 'carrot', 52: 'hot dog', 53: 'pizza', 54: 'donut', 55: 'cake'
# We will match the class name to our nutrition DB

@router.post("/detect")
async def detect_food(file: UploadFile = File(None), image: UploadFile = File(None)):
    upload_file = file or image
    if not upload_file or not upload_file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    # Save the file temporarily
    temp_file = Path(f"temp_{upload_file.filename}")
    try:
        with open(temp_file, "wb") as buffer:
            shutil.copyfileobj(upload_file.file, buffer)
        
        # Run YOLOv8 inference
        results = model(str(temp_file))
        
        if not results or len(results) == 0:
            return {"error": "No objects detected"}
            
        result = results[0]
        
        # Find the object with the highest confidence
        best_box = None
        best_conf = 0.0
        
        if len(result.boxes) > 0:
            for box in result.boxes:
                conf = float(box.conf[0])
                if conf > best_conf:
                    best_conf = conf
                    best_box = box
                    
        if best_box is None:
            return {"error": "No objects detected with sufficient confidence"}
            
        class_id = int(best_box.cls[0])
        class_name = model.names[class_id].capitalize()
        
        # We manually map some classes to our DB just in case
        # YOLOv8 returns 'Pizza', 'Apple', 'Banana', etc.
        
        nutrition_data = get_food_nutrition(class_name)
        
        if not nutrition_data:
            return {
                "food": class_name,
                "confidence": best_conf,
                "error": f"Nutrition data not found for {class_name}"
            }
            
        return {
            "food": class_name,
            "confidence": best_conf,
            "nutrition": {
                "carbs": nutrition_data["carbs"],
                "protein": nutrition_data["protein"],
                "fat": nutrition_data["fat"],
                "fiber": nutrition_data["fiber"],
                "serving_size": nutrition_data["serving_size"],
                "calories": nutrition_data["calories"]
            }
        }
            
    finally:
        # Cleanup
        if temp_file.exists():
            os.remove(temp_file)
