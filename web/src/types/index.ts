export interface User {
    id: string;
    email: string;
    name: string;
  }
  
  export interface MedicalProfile {
    diabetes_type: string;
    age: number;
    weight_kg: number;
    height_cm: number;
    activity_level: string;
    medications: string;
    conditions: string;
  }
  
  export interface GlucoseReading {
    id: string;
    value_mgdl: number;
    reading_type: string;
    notes: string;
    measured_at: string;
  }
  
  export interface ShapFactor {
    feature: string;
    label: string;
    shap_value: number;
    direction: string;
    impact_text: string;
  }
  
  export interface Prediction {
    prediction_id: string;
    predicted_spike: number;
    predicted_post_meal: number;
    pre_meal_glucose: number;
    risk_level: string;
    risk_color: string;
    calories: number;
    input_summary: {
      carbs_g: number;
      protein_g: number;
      fat_g: number;
      fiber_g: number;
    };
    explanation: {
      summary: string;
      base_value: number;
      top_factors: ShapFactor[];
      all_values: Record<string, number>;
    };
  }