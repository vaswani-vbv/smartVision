import pandas as pd
import numpy as np
import pickle
import os
from xgboost import XGBRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

# ── Reproducibility ───────────────────────────────────────────────────────
np.random.seed(42)
N = 2000  # number of synthetic training samples

def generate_synthetic_data(n=N):
    """
    Generate realistic synthetic meal + glucose spike data.
    Rules are based on known diabetes physiology.
    """
    # ── Meal inputs ───────────────────────────────────────────────────────
    carbs_g   = np.random.uniform(5,  120, n)
    protein_g = np.random.uniform(0,  60,  n)
    fat_g     = np.random.uniform(0,  50,  n)
    fiber_g   = np.random.uniform(0,  15,  n)
    calories  = carbs_g * 4 + protein_g * 4 + fat_g * 9

    # ── Context inputs ────────────────────────────────────────────────────
    pre_meal_glucose = np.random.uniform(70, 180, n)
    time_of_day      = np.random.randint(0, 24, n)
    activity_level   = np.random.randint(0, 4,  n)  # 0=sedentary 3=active
    diabetes_type    = np.random.randint(0, 3,  n)  # 0=type1 1=type2 2=prediabetes
    age              = np.random.uniform(18, 75, n)
    weight_kg        = np.random.uniform(45, 120, n)

    # ── Spike calculation (physiology-based rules) ─────────────────────────
    # Carbs are the biggest driver of glucose spike
    spike = carbs_g * 1.2

    # Fiber slows absorption — reduces spike
    spike -= fiber_g * 2.5

    # Protein has a mild effect
    spike += protein_g * 0.2

    # Fat slows digestion — slight reduction
    spike -= fat_g * 0.3

    # Higher starting glucose = higher spike
    spike += (pre_meal_glucose - 100) * 0.3

    # Morning meals spike more (dawn phenomenon)
    morning_mask = (time_of_day >= 6) & (time_of_day <= 9)
    spike[morning_mask] += 15

    # Activity reduces spike
    spike -= activity_level * 8

    # Type 1 diabetics spike more (no insulin production)
    spike[diabetes_type == 0] += 20

    # Older people tend to have higher spikes
    spike += (age - 40) * 0.3

    # Heavier weight slightly increases spike
    spike += (weight_kg - 70) * 0.2

    # Add realistic noise
    spike += np.random.normal(0, 10, n)

    # Clip to realistic range (glucose can't drop below 0 or spike 300+)
    spike = np.clip(spike, 0, 280)

    df = pd.DataFrame({
        "carbs_g":          carbs_g,
        "protein_g":        protein_g,
        "fat_g":            fat_g,
        "fiber_g":          fiber_g,
        "calories":         calories,
        "pre_meal_glucose": pre_meal_glucose,
        "time_of_day":      time_of_day,
        "activity_level":   activity_level,
        "diabetes_type":    diabetes_type,
        "age":              age,
        "weight_kg":        weight_kg,
        "glucose_spike":    spike
    })
    return df

def train():
    print("Generating synthetic training data...")
    df = generate_synthetic_data()
    print(f"Dataset shape: {df.shape}")
    print(f"Average spike: {df['glucose_spike'].mean():.1f} mg/dL")
    print(f"Max spike:     {df['glucose_spike'].max():.1f} mg/dL")
    print(f"Min spike:     {df['glucose_spike'].min():.1f} mg/dL")

    # ── Features and target ───────────────────────────────────────────────
    FEATURES = [
        "carbs_g", "protein_g", "fat_g", "fiber_g", "calories",
        "pre_meal_glucose", "time_of_day", "activity_level",
        "diabetes_type", "age", "weight_kg"
    ]
    X = df[FEATURES]
    y = df["glucose_spike"]

    # ── Train/test split ──────────────────────────────────────────────────
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    print(f"\nTraining on {len(X_train)} samples, testing on {len(X_test)} samples")

    # ── Train XGBoost model ───────────────────────────────────────────────
    print("\nTraining XGBoost model...")
    model = XGBRegressor(
        n_estimators=300,
        learning_rate=0.05,
        max_depth=6,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        verbosity=0
    )
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=False
    )

    # ── Evaluate ──────────────────────────────────────────────────────────
    preds = model.predict(X_test)
    rmse  = np.sqrt(mean_squared_error(y_test, preds))
    mae   = mean_absolute_error(y_test, preds)
    r2    = r2_score(y_test, preds)

    print(f"\n── Model Evaluation ──────────────────")
    print(f"RMSE : {rmse:.2f} mg/dL  (target: < 25)")
    print(f"MAE  : {mae:.2f}  mg/dL  (target: < 18)")
    print(f"R²   : {r2:.3f}          (target: > 0.75)")
    print(f"──────────────────────────────────────")

    # ── Save model ────────────────────────────────────────────────────────
    model_path = os.path.join(os.path.dirname(__file__), "model.pkl")
    with open(model_path, "wb") as f:
        pickle.dump({
            "model":    model,
            "features": FEATURES
        }, f)
    print(f"\nModel saved to {model_path}")
    return model, FEATURES

if __name__ == "__main__":
    train()