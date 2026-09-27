from typing import List, Dict, Any
from app.ml.meal_database import INDIAN_MEALS
from app.ml.predict import predict_spike

def _predict_spike_for_meal(meal: Dict, profile: Dict,
                             current_glucose: float,
                             time_of_day: int) -> float:
    """Run the XGBoost model for a specific meal + user context."""
    res = predict_spike(
        carbs_g=float(meal["carbs_g"]),
        protein_g=float(meal["protein_g"]),
        fat_g=float(meal["fat_g"]),
        fiber_g=float(meal["fiber_g"]),
        pre_meal_glucose=current_glucose,
        time_of_day=time_of_day,
        activity_level=profile.get("activity_level", "moderate"),
        diabetes_type=profile.get("diabetes_type", "type2"),
        age=int(profile.get("age", 35)),
        weight_kg=float(profile.get("weight_kg", 70)),
        insulin_dose=0.0,
        post_meal_activity="none"
    )
    return max(0.0, round(float(res["predicted_spike"]), 1))


def _get_safe_glucose_budget(profile: Dict,
                              current_glucose: float,
                              time_of_day: int,
                              hours_since_last_meal: float) -> Dict:
    """
    Calculate how much glucose spike is safe for this user
    given their current state.
    """
    diabetes_type = profile.get("diabetes_type", "type2")
    age           = profile.get("age", 35)

    # Target post-meal glucose ceilings by diabetes type
    targets = {
        "type1":       150,   # strictest — no endogenous insulin
        "type2":       160,
        "prediabetes": 140,
    }
    ceiling = targets.get(diabetes_type, 160)

    # If already elevated, tighten the budget
    if current_glucose > 140:
        ceiling -= 20
    elif current_glucose > 110:
        ceiling -= 10

    # Morning meals tend to spike more (dawn phenomenon)
    if 5 <= time_of_day <= 9:
        ceiling -= 15

    # Very long gap since last meal → liver dumps glucose → tighten
    if hours_since_last_meal > 6:
        ceiling -= 10

    # Older patients tend to have less insulin sensitivity
    if age > 55:
        ceiling -= 10

    # Safe budget = how much the glucose can rise from current level
    budget = max(20.0, float(ceiling - current_glucose))

    # Macro targets derived from the budget
    # Rule of thumb: 1g carbs ≈ 3-4 mg/dL spike (varies by person)
    # We work backwards: carb_limit ≈ budget / 3.5
    carb_limit = round(budget / 3.5, 0)

    return {
        "ceiling":          ceiling,
        "budget_mgdl":      round(budget, 0),
        "current_glucose":  current_glucose,
        "target_post_meal": ceiling,
        "macro_targets": {
            "carbs_g_max":   int(carb_limit),
            "carbs_g_min":   int(max(15, carb_limit * 0.6)),
            "protein_g_min": 15,
            "fat_g_max":     20,
            "fiber_g_min":   4,
        },
        "reasoning": _build_budget_reasoning(
            diabetes_type, current_glucose, time_of_day,
            hours_since_last_meal, age, budget
        )
    }


def _build_budget_reasoning(diabetes_type, current_glucose,
                             time_of_day, hours_since_last_meal,
                             age, budget) -> List[str]:
    """Build plain English reasons for the macro budget."""
    reasons = []

    if diabetes_type == "type1":
        reasons.append(
            "Type 1 diabetes: your body produces no insulin, "
            "so carb intake needs to be carefully managed.")
    elif diabetes_type == "type2":
        reasons.append(
            "Type 2 diabetes: reduced insulin sensitivity "
            "means carbs should be moderated.")
    else:
        reasons.append(
            "Prediabetes: keeping glucose post-meal under 140 mg/dL "
            "can prevent progression.")

    if current_glucose > 140:
        reasons.append(
            f"Your current glucose is {current_glucose} mg/dL (elevated) — "
            "choosing a low-carb meal now is important.")
    elif current_glucose > 110:
        reasons.append(
            f"Your glucose is {current_glucose} mg/dL (slightly above fasting) — "
            "a moderate carb meal is advised.")
    else:
        reasons.append(
            f"Your glucose is {current_glucose} mg/dL (good) — "
            "you have a reasonable carb budget for this meal.")

    if 5 <= time_of_day <= 9:
        reasons.append(
            "Morning meals cause larger spikes due to the dawn phenomenon — "
            "cortisol raises blood sugar early in the day.")

    if hours_since_last_meal > 6:
        reasons.append(
            f"It has been {hours_since_last_meal:.1f} hours since your last meal — "
            "your liver may have released extra glucose, so eat mindfully.")

    if age > 55:
        reasons.append(
            "Insulin sensitivity typically decreases with age — "
            "a lower carb target is recommended.")

    reasons.append(
        f"Safe glucose budget for this meal: {budget:.0f} mg/dL rise "
        f"(target post-meal: under {current_glucose + budget:.0f} mg/dL).")

    return reasons


def _get_meal_category(time_of_day: int) -> List[str]:
    """Return appropriate meal categories for the time of day."""
    if 5  <= time_of_day <= 10: return ["breakfast", "snack"]
    if 11 <= time_of_day <= 14: return ["lunch", "snack"]
    if 15 <= time_of_day <= 17: return ["snack"]
    if 18 <= time_of_day <= 22: return ["dinner", "snack"]
    return ["snack", "breakfast", "lunch", "dinner"]


def _score_meal(meal: Dict, predicted_spike: float,
                budget: Dict) -> float:
    """
    Score a meal 0-100 based on how well it fits the user's needs.
    Higher = better recommendation.
    """
    score = 100.0
    macro = budget["macro_targets"]

    # Penalise if spike exceeds budget
    spike_room = budget["budget_mgdl"] - predicted_spike
    if spike_room < 0:
        score += spike_room * 3   # heavy penalty for over budget
    else:
        score += min(spike_room, 20)  # reward for being under budget

    # Reward fiber
    if meal["fiber_g"] >= macro["fiber_g_min"]:
        score += 10

    # Reward protein
    if meal["protein_g"] >= macro["protein_g_min"]:
        score += 8

    # Penalise high carbs beyond limit
    carb_over = meal["carbs_g"] - macro["carbs_g_max"]
    if carb_over > 0:
        score -= carb_over * 1.5

    # Penalise avoid-if-elevated tag when glucose is high
    if ("avoid-if-elevated" in meal.get("tags", []) and
            budget["current_glucose"] > 120):
        score -= 30

    return score


def get_meal_recommendations(
    profile:               Dict,
    current_glucose:       float,
    hours_since_last_meal: float,
    time_of_day:           int,
    recent_readings:       List[Dict] = []
) -> Dict[str, Any]:
    """
    Main function — generates personalised meal recommendations.
    Returns macro budget + ranked meal suggestions with predicted spikes.
    """

    # 1. Calculate safe glucose budget
    budget = _get_safe_glucose_budget(
        profile, current_glucose, time_of_day, hours_since_last_meal)

    # 2. Get meals appropriate for this time of day
    categories    = _get_meal_category(time_of_day)
    candidate_meals = [m for m in INDIAN_MEALS
                       if m["category"] in categories]
    if not candidate_meals:
        candidate_meals = INDIAN_MEALS

    # 3. Score and rank each meal
    scored_meals = []
    for meal in candidate_meals:
        spike = _predict_spike_for_meal(
            meal, profile, current_glucose, time_of_day)
        post_meal = round(current_glucose + spike, 1)
        score     = _score_meal(meal, spike, budget)

        # Risk level
        if post_meal < 140:       risk = "low"
        elif post_meal < 180:     risk = "moderate"
        else:                     risk = "high"

        scored_meals.append({
            **meal,
            "predicted_spike":     spike,
            "predicted_post_meal": post_meal,
            "risk_level":          risk,
            "score":               score,
            "fits_budget":         spike <= budget["budget_mgdl"],
            "recommendation_note": _meal_note(meal, spike, budget, profile),
        })

    # 4. Sort by score descending
    scored_meals.sort(key=lambda x: x["score"], reverse=True)

    # 5. Return top 5 — ensure at least 2 are "fits_budget"
    top     = [m for m in scored_meals if m["fits_budget"]][:3]
    caution = [m for m in scored_meals if not m["fits_budget"]][:2]
    recommendations = top + caution
    if not recommendations:
        recommendations = scored_meals[:5]

    # 6. Generate overall advice
    overall_advice = _overall_advice(
        profile, current_glucose, time_of_day,
        hours_since_last_meal, budget)

    return {
        "current_glucose":       current_glucose,
        "time_of_day":           time_of_day,
        "hours_since_last_meal": hours_since_last_meal,
        "glucose_budget":        budget,
        "overall_advice":        overall_advice,
        "recommendations":       recommendations,
        "meal_timing_tip":       _timing_tip(time_of_day, profile),
    }


def _meal_note(meal: Dict, spike: float,
               budget: Dict, profile: Dict) -> str:
    """Generate a one-line personalised note for a specific meal."""
    dtype = profile.get("diabetes_type", "type2")

    if spike <= budget["budget_mgdl"] * 0.6:
        return (f"Excellent choice — predicted spike of only {spike} mg/dL "
                f"is well within your safe range.")
    elif spike <= budget["budget_mgdl"]:
        return (f"Good choice — predicted spike of {spike} mg/dL "
                f"stays within your budget.")
    elif spike <= budget["budget_mgdl"] * 1.3:
        return (f"Eat with caution — {spike} mg/dL spike slightly exceeds "
                f"your budget. Reduce portion by 25% if possible.")
    else:
        return (f"Not recommended right now — {spike} mg/dL spike would "
                f"push your glucose significantly above target. "
                f"Choose a lower carb option instead.")


def _overall_advice(profile, current_glucose, time_of_day,
                    hours_since_last_meal, budget) -> str:
    """Generate top-level personalised advice for this meal moment."""
    dtype = profile.get("diabetes_type", "type2")
    parts = []

    if current_glucose > 140:
        parts.append(
            "Your glucose is currently elevated. Prioritise low-carb, "
            "high-protein options and avoid refined carbs entirely.")
    elif current_glucose > 110:
        parts.append(
            "Your glucose is slightly above ideal fasting levels. "
            "Choose meals with plenty of fiber and protein to blunt the spike.")
    else:
        parts.append(
            "Your glucose is in a good range going into this meal. "
            "You can eat a balanced meal — just stay within the carb targets below.")

    if hours_since_last_meal > 5:
        parts.append(
            "Eat slowly and avoid overeating — a long gap can cause "
            "rebound hunger that leads to overconsumption.")

    if dtype == "type1":
        parts.append(
            "Remember to calculate your insulin dose based on the "
            "carb content of whichever meal you choose.")

    return " ".join(parts)


def _timing_tip(time_of_day: int, profile: Dict) -> str:
    """Return a contextual tip based on time of day."""
    dtype = profile.get("diabetes_type", "type2")

    if 5 <= time_of_day <= 9:
        return ("Morning tip: eat within 30 minutes of waking to prevent "
                "glucose from dropping too low. Avoid sugary breakfasts.")
    elif 11 <= time_of_day <= 14:
        return ("Lunch tip: a 15-minute walk after lunch can reduce your "
                "post-meal spike by 20-30 mg/dL.")
    elif 15 <= time_of_day <= 17:
        return ("Snack tip: pairing carbs with protein or fat at snack time "
                "slows absorption. Avoid eating carbs alone.")
    elif 18 <= time_of_day <= 22:
        if dtype == "type1":
            return ("Dinner tip: Type 1 patients should keep dinner carbs "
                    "lower than lunch — overnight glucose is harder to manage.")
        return ("Dinner tip: keep dinner lighter than lunch. "
                "Your glucose metabolism slows in the evening.")
    return "Stay hydrated between meals — dehydration worsens insulin resistance."
