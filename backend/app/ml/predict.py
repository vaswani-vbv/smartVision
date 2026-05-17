import pickle
import pandas as pd
import numpy as np
import shap
import os

MODEL_PATH = os.path.join(os.path.dirname(__file__), "model.pkl")

_model_cache = None
_explainer_cache = None

DIABETES_TYPE_MAP = {
    "type1":       0,
    "type2":       1,
    "prediabetes": 2
}

ACTIVITY_LEVEL_MAP = {
    "sedentary": 0,
    "light":     1,
    "moderate":  2,
    "active":    3
}

# Human readable feature names for the frontend
FEATURE_LABELS = {
    "carbs_g":          "Carbohydrates",
    "protein_g":        "Protein",
    "fat_g":            "Fat",
    "fiber_g":          "Fiber",
    "calories":         "Total Calories",
    "pre_meal_glucose": "Pre-meal Glucose",
    "time_of_day":      "Time of Day",
    "activity_level":   "Activity Level",
    "diabetes_type":    "Diabetes Type",
    "age":              "Age",
    "weight_kg":        "Weight"
}

def load_model():
    global _model_cache
    if _model_cache is None:
        with open(MODEL_PATH, "rb") as f:
            _model_cache = pickle.load(f)
    return _model_cache

def load_explainer():
    global _explainer_cache
    if _explainer_cache is None:
        data = load_model()
        _explainer_cache = shap.TreeExplainer(data["model"])
    return _explainer_cache

def predict_spike(
    carbs_g:          float,
    protein_g:        float,
    fat_g:            float,
    fiber_g:          float,
    pre_meal_glucose: float,
    time_of_day:      int,
    activity_level:   str,
    diabetes_type:    str,
    age:              int,
    weight_kg:        float
) -> dict:

    data     = load_model()
    model    = data["model"]
    features = data["features"]

    calories = carbs_g * 4 + protein_g * 4 + fat_g * 9

    input_df = pd.DataFrame([{
        "carbs_g":          carbs_g,
        "protein_g":        protein_g,
        "fat_g":            fat_g,
        "fiber_g":          fiber_g,
        "calories":         calories,
        "pre_meal_glucose": pre_meal_glucose,
        "time_of_day":      time_of_day,
        "activity_level":   ACTIVITY_LEVEL_MAP.get(activity_level, 1),
        "diabetes_type":    DIABETES_TYPE_MAP.get(diabetes_type, 1),
        "age":              age,
        "weight_kg":        weight_kg
    }])[features]

    # ── Prediction ────────────────────────────────────────────────────────
    predicted_spike     = float(model.predict(input_df)[0])
    predicted_spike     = max(0, round(predicted_spike, 1))
    predicted_post_meal = round(pre_meal_glucose + predicted_spike, 1)

    # ── Risk level ────────────────────────────────────────────────────────
    if predicted_post_meal < 140:
        risk_level = "normal"
        risk_color = "green"
    elif predicted_post_meal < 180:
        risk_level = "elevated"
        risk_color = "orange"
    else:
        risk_level = "high"
        risk_color = "red"

    # ── SHAP explanation ──────────────────────────────────────────────────
    explainer   = load_explainer()
    shap_values = explainer.shap_values(input_df)

    # Build per-feature impact dict
    shap_dict = {}
    for i, feature in enumerate(features):
        shap_dict[feature] = round(float(shap_values[0][i]), 2)

    # Sort by absolute impact — biggest drivers first
    sorted_shap = sorted(
        shap_dict.items(),
        key=lambda x: abs(x[1]),
        reverse=True
    )

    # Top 5 factors with human readable labels
    top_factors = []
    for feature, value in sorted_shap[:5]:
        direction = "increases" if value > 0 else "decreases"
        label     = FEATURE_LABELS.get(feature, feature)
        top_factors.append({
            "feature":   feature,
            "label":     label,
            "shap_value": value,
            "direction": direction,
            "impact_text": f"{label} {direction} spike by {abs(value):.1f} mg/dL"
        })

    # Plain english summary
    biggest = top_factors[0]
    second  = top_factors[1] if len(top_factors) > 1 else None

    summary = f"The biggest driver is {biggest['label']} ({'+' if biggest['shap_value'] > 0 else ''}{biggest['shap_value']:.1f} mg/dL)."
    if second:
        summary += f" {second['label']} also plays a role ({'+' if second['shap_value'] > 0 else ''}{second['shap_value']:.1f} mg/dL)."

    return {
        "predicted_spike":     predicted_spike,
        "predicted_post_meal": predicted_post_meal,
        "pre_meal_glucose":    pre_meal_glucose,
        "risk_level":          risk_level,
        "risk_color":          risk_color,
        "calories":            round(calories, 1),
        "shap": {
            "values":      shap_dict,
            "top_factors": top_factors,
            "base_value":  round(float(explainer.expected_value), 2),
            "summary":     summary
        }
    }