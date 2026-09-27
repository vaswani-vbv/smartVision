# SmartVision: Comprehensive Project Handoff Document

## 1. Project Purpose & Importance
**SmartVision** is a full-stack, AI-powered web application designed to help users manage diabetes effectively. Diabetes management requires constant monitoring of glucose levels and careful dietary planning. SmartVision simplifies this by allowing users to log glucose readings, visualize their health trends, and, most importantly, use Artificial Intelligence (XGBoost & YOLOv8) to predict how specific meals will impact their blood sugar. The project bridges the gap between raw data tracking and actionable, personalized medical insights.

---

## 2. Technology Stack & Architecture
The application follows a modern, decoupled client-server architecture:

### Frontend (The User Interface)
*   **Framework:** React (18.x) with TypeScript.
*   **Routing:** `react-router-dom` for Single Page Application (SPA) navigation.
*   **Data Visualization:** `recharts` for interactive glucose history line charts.
*   **Network:** `axios` (configured with a global interceptor to attach JWTs and handle 401s).
*   **Key Pages:** Login, Register, Profile, Dashboard, Glucose Log, Prediction, Scan Food.

### Backend (The Brain)
*   **Framework:** FastAPI (Python 3.x), providing automatic Swagger/OpenAPI documentation.
*   **Authentication:** JWT (JSON Web Tokens) via `python-jose` and password hashing via direct `bcrypt` (recently fixed to avoid a `passlib` crash bug).
*   **ORM:** SQLAlchemy (Async) `AsyncSession`.
*   **API Routing:** Modularized routers (`auth`, `users`, `glucose`, `predictions`, `camera`).

### Databases (Dual Architecture)
1.  **PostgreSQL (Dynamic Data):** Runs via Docker Compose. Stores user accounts, medical profiles, glucose logs, and prediction history.
2.  **SQLite (Static Data):** A local `nutrition.db` file. Stores a dictionary of foods and their base macronutrients (Carbs, Protein, Fat, Fiber) per serving size.

### Artificial Intelligence & Machine Learning
*   **Computer Vision (YOLOv8):** Used in the `Scan Food` page. Users capture an image via webcam or upload a file. The backend runs the YOLOv8 object detection model to identify the food and maps it to the SQLite database to retrieve nutritional info.
*   **Glucose Prediction (XGBoost):** A regression model trained on synthetic, physiology-based medical data. It predicts the expected glucose spike based on macronutrients, user profile (diabetes type, weight, age, activity level), and pre-meal glucose.
*   **Explainable AI (SHAP):** Integrates with XGBoost to mathematically explain *why* a spike is predicted, breaking down the impact of each feature (e.g., "Carbohydrates increases spike by 45 mg/dL").

---

## 3. Current State: Phase 1 (100% Complete)
The foundation and core features of the application are fully built, integrated, and functioning.

### Working Features:
1.  **Authentication Flow:** Secure Registration & Login directly routing to the Dashboard.
2.  **Medical Profiles:** Users can specify diabetes type, weight, age, and activity level.
3.  **Dashboard with Stats:** Summary cards showing average glucose, time-in-range (70-140 mg/dL), highest/lowest readings, and zone breakdown bars.
4.  **Glucose History Chart:** Interactive `recharts` line chart visualizing readings over time.
5.  **YOLOv8 Food Scanner:** Camera/image upload detects food, returns confidence scores, and auto-populates the nutrition form.
6.  **XGBoost Prediction & SHAP Explanations:** Predicts spikes and explains the top factors driving the prediction. Recently **rebalanced** so Carbs and Fiber correctly dominate the prediction weights.
7.  **Network Stability:** All frontend API calls strictly use `127.0.0.1:8000` to prevent IPv6/IPv4 resolution conflicts on Windows.

---

## 4. Database Schema Overview (PostgreSQL)

*   **Users:** `id` (UUID), `email`, `password_hash`, `name`, `created_at`.
*   **MedicalProfiles:** `id`, `user_id` (FK), `diabetes_type`, `age`, `weight_kg`, `height_cm`, `activity_level`, `medications`, `conditions`.
*   **GlucoseReadings:** `id`, `user_id` (FK), `value_mgdl`, `reading_type` (fasting/post_meal/etc), `notes`, `measured_at`.
*   **Predictions:** `id`, `user_id` (FK), `carbs_g`, `protein_g`, `fat_g`, `pre_meal_glucose`, `predicted_spike`, `shap_values` (JSON text), `predicted_at`.

---

## 5. Core Workflow Example: "Scan & Predict"
To understand the system's flow, here is the lifecycle of a food scan:
1.  **React:** User captures a webcam photo on `/scan` and POSTs FormData to `/api/camera/detect`.
2.  **FastAPI:** Receives image, passes to YOLOv8. YOLO returns class name (e.g., "Apple").
3.  **SQLite:** Backend queries `nutrition.db` for "Apple" and gets Carbs (14g), Protein (0.3g), Fiber (2.4g).
4.  **React:** Receives nutrition data and auto-fills the prediction form. User enters pre-meal glucose and clicks "Predict".
5.  **FastAPI:** POST to `/api/predictions/predict`. Fetches user's `MedicalProfile` from Postgres.
6.  **XGBoost & SHAP:** Predicts spike based on macros + profile. Generates SHAP explanation array.
7.  **Postgres:** Saves the prediction to the database.
8.  **React:** Displays risk level (Normal/Elevated/High), predicted spike, and the SHAP visual breakdown.

---

## 6. What Needs to be Built Next: Phase 2 Roadmap
With Phase 1 complete, the project moves to advanced personalization and multi-platform expansion.

### A. Adaptive Learning (Personalized ML)
*   **Goal:** Retrain the XGBoost model specifically for individual users over time.
*   **Mechanism:** When a user logs a *real* post-meal glucose reading that correlates to a past prediction, the backend should use that ground-truth data to fine-tune their personal model weights.

### B. Recommendations Engine
*   **Goal:** Move from "predictive" to "prescriptive" AI.
*   **Mechanism:** After predicting a spike, the backend should generate actionable advice (e.g., "Reduce portion size by 20%", "Take a 15-minute walk post-meal", "Swap white rice for brown rice").

### C. Flutter Mobile App
*   **Goal:** Native iOS and Android application.
*   **Mechanism:** Build a Flutter app that consumes the exact same FastAPI endpoints. This allows native camera access for smoother YOLO scanning and native push notifications for post-meal logging reminders.

### D. Report Export
*   **Goal:** Doctor-patient data sharing.
*   **Mechanism:** Allow users to download a formatted PDF containing their glucose history, time-in-range stats, and AI prediction history to share during medical consultations.
