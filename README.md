# 👁️ SmartVision

> **AI-Powered Diabetes Management & Glucose Spike Prediction Platform**

SmartVision is a comprehensive, full-stack medical technology application designed to help individuals manage diabetes effectively. Combining **Computer Vision (YOLOv8)** for instant meal scanning, **Machine Learning (XGBoost)** for personalized glucose spike prediction, and **Explainable AI (SHAP)** for actionable health insights, SmartVision empowers users to make informed dietary and lifestyle decisions.

---

## 🌟 Key Features

- **📸 Instant AI Food Scanner (YOLOv8)**: Capture photos of meals via webcam or camera; computer vision detects food items and auto-populates macronutrients (Carbs, Protein, Fat, Fiber) from a built-in nutrition database.
- **⚡ Glucose Spike Prediction (XGBoost)**: Machine learning regression models estimate expected post-meal glucose spikes ($mg/dL$) based on macronutrient intake, pre-meal blood sugar, and individual medical profile (Diabetes Type, weight, age, activity level).
- **🧠 Explainable AI Insights (SHAP)**: Mathematical feature attribution breaks down *why* a spike is predicted (e.g., specifying how many $mg/dL$ were contributed by carbohydrates vs. offset by fiber).
- **📊 Interactive Health Dashboard**: Visualize historical glucose trends, time-in-range metrics ($70\text{--}140\text{ mg/dL}$), average blood sugar, and high/low alert zones using interactive charts.
- **👤 Medical Profile Customization**: Tailor predictions to specific health metrics including Diabetes Type (Type 1, Type 2, Gestational), weight, age, activity levels, and current medications.
- **🌐 Multi-Platform Access**: Cross-platform availability via a responsive **React TypeScript Web Application** and a native **Flutter Mobile Application** (iOS & Android).
- **🔐 Enterprise-Grade Security**: Secure JWT authentication, password hashing with `bcrypt`, and isolated user data access across all API endpoints.

---

## 🏗️ Architecture & Technology Stack

SmartVision follows a decoupled, micro-layered architecture with dedicated services for web, mobile, AI backend, and database storage.

```
                  ┌─────────────────────────────────────────┐
                  │              Clients                    │
                  │   React Web App   │   Flutter Mobile    │
                  └────────────────────┬────────────────────┘
                                       │ HTTP / REST (JWT)
                                       ▼
                  ┌─────────────────────────────────────────┐
                  │            FastAPI Backend              │
                  │         (Python 3.10+ / Async)          │
                  └───────┬─────────────┬─────────────┬─────┘
                          │             │             │
        ┌─────────────────┘             │             └─────────────────┐
        ▼                               ▼                               ▼
┌──────────────┐               ┌─────────────────┐             ┌─────────────────┐
│ PostgreSQL   │               │     SQLite      │             │   AI Engine     │
│ (User Data,  │               │ (Nutrition DB)  │             │ YOLOv8 (Vision) │
│ Glucose Logs)│               │ (Static Foods)  │             │ XGBoost (Spike) │
└──────────────┘               └─────────────────┘             └─────────────────┘
```

### Stack Breakdown

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Backend API** | Python 3.10+, FastAPI, Async SQLAlchemy, Alembic | Async RESTful services with interactive Swagger/OpenAPI docs |
| **Web Frontend** | React 19, TypeScript, Recharts, Axios, React Router v7 | Single-page application with responsive charts & webcam capture |
| **Mobile App** | Flutter 3.x, Dart, FL Chart, Camera, Flutter Secure Storage | Cross-platform mobile app for iOS and Android |
| **Primary Database** | PostgreSQL 15 (Docker) | Stores users, medical profiles, glucose logs, and prediction history |
| **Nutrition Database**| SQLite (`nutrition.db`) | Local database containing food items and standard macronutrients |
| **Computer Vision** | Ultralytics YOLOv8 (`yolov8n.pt`) | Object detection model for instant food identification |
| **Glucose Prediction**| XGBoost Regressor | ML model trained on diabetic physiological data |
| **Explainable AI** | SHAP (SHapley Additive exPlanations) | Generates feature-level mathematical explanations for predictions |

---

## 📁 Repository Directory Structure

```
SmartVision/
├── backend/                    # Python FastAPI Service & AI Models
│   ├── app/
│   │   ├── models/             # SQLAlchemy DB schemas
│   │   ├── routers/            # API endpoints (auth, glucose, camera, predictions)
│   │   ├── services/           # Business logic & AI model callers
│   │   ├── database.py         # Async database connections
│   │   └── main.py             # FastAPI entrypoint & router registration
│   ├── alembic/                # Database migration scripts
│   ├── uploads/                # Uploaded food scans & profile media
│   ├── nutrition.db            # SQLite static food nutrition database
│   ├── yolov8n.pt              # YOLOv8 pre-trained model weights
│   └── requirements.txt        # Python backend dependencies
├── web/                        # React TypeScript Web Frontend
│   ├── public/                 # Static assets
│   ├── src/
│   │   ├── components/         # Reusable UI components & charts
│   │   ├── pages/              # Dashboard, Profile, Scan, Predict, History
│   │   ├── services/           # Axios API client & endpoints
│   │   └── App.tsx             # Main router configuration
│   └── package.json            # Node.js dependencies & scripts
├── mobile/                     # Flutter Cross-Platform Mobile App
│   ├── lib/
│   │   ├── core/               # API constants, theme, network client
│   │   ├── features/           # Auth, dashboard, scanner, predictions screens
│   │   └── main.dart           # Flutter app entry point
│   └── pubspec.yaml            # Dart/Flutter package manifest
├── docker-compose.yml          # PostgreSQL & Redis container setup
├── project_overview.md         # In-depth architectural documentation
├── SmartVision_Project_Context.md # Detailed developer handoff guide
└── system_design_diagrams.md   # Architectural sequence diagrams
```

---

## 🔄 Scan & Predict Workflow

1. **Capture**: User captures a food image via webcam (Web) or native camera (Mobile) and POSTs to `/api/camera/detect`.
2. **Object Detection**: **YOLOv8** analyzes image pixels and identifies the food item (e.g., `"Apple"`).
3. **Nutrition Lookup**: FastAPI queries the local **SQLite Nutrition Database** for `"Apple"` and fetches macronutrients (14g Carbs, 0.3g Protein, 2.4g Fiber).
4. **Auto-Fill**: Macronutrients auto-populate into the prediction form. User enters current pre-meal glucose reading.
5. **Spike Prediction**: FastAPI sends macros + user's **PostgreSQL Medical Profile** into the **XGBoost** regression model.
6. **Feature Attribution**: **SHAP** calculates exact weight contributions for each feature.
7. **Results & Storage**: Prediction and SHAP values are saved to PostgreSQL and returned to the client for interactive visual breakdown.

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your system:
- **Docker & Docker Compose** (for PostgreSQL database)
- **Python 3.10+**
- **Node.js 18+ & npm**
- **Flutter SDK 3.x** (optional, for mobile app development)

---

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/SmartVision.git
cd SmartVision
```

---

### 2️⃣ Start Database Services (PostgreSQL & Redis)

Launch PostgreSQL using Docker Compose:

```bash
docker-compose up -d
```

*PostgreSQL will start on `localhost:5432` with user `smartvision` and database `smartvision_db`.*

---

### 3️⃣ Setup & Run Backend API

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```

2. Create and activate a Python virtual environment:
   ```bash
   # Windows (PowerShell)
   python -m venv venv
   .\venv\Scripts\Activate.ps1

   # macOS / Linux
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

4. Create environment file `.env` in `backend/`:
   ```env
   DATABASE_URL=postgresql+asyncpg://smartvision:secret@localhost:5432/smartvision_db
   SECRET_KEY=your_super_secret_jwt_key
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=1440
   ```

5. Run database migrations:
   ```bash
   alembic upgrade head
   ```

6. Start the FastAPI development server:
   ```bash
   uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   ```

   - **API Base URL**: [http://127.0.0.1:8000](http://127.0.0.1:8000)
   - **Interactive Swagger Docs**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

---

### 4️⃣ Setup & Run Web App (React)

1. Open a new terminal and navigate to the `web` directory:
   ```bash
   cd web
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the React development server:
   ```bash
   npm start
   ```

   - **Web Application**: [http://localhost:3000](http://localhost:3000)

---

### 5️⃣ Setup & Run Mobile App (Flutter)

1. Open a new terminal and navigate to the `mobile` directory:
   ```bash
   cd mobile
   ```

2. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run on connected emulator or physical device:
   ```bash
   flutter run
   ```

---

## 📡 API Endpoint Overview

| Module | Endpoint | Method | Description |
| :--- | :--- | :--- | :--- |
| **Auth** | `/api/auth/register` | `POST` | Register new user account |
| **Auth** | `/api/auth/login` | `POST` | Authenticate user & receive JWT |
| **Users** | `/api/users/profile` | `GET`/`PUT` | Retrieve or update user medical profile |
| **Glucose** | `/api/glucose/log` | `POST` | Add new blood glucose reading |
| **Glucose** | `/api/glucose/history` | `GET` | Retrieve user glucose history & trends |
| **Camera** | `/api/camera/detect` | `POST` | Process image through YOLOv8 & return nutrition |
| **Predictions** | `/api/predictions/predict` | `POST` | Run XGBoost spike prediction & SHAP breakdown |
| **Meal Planner**| `/api/meal-planner/suggest`| `GET` | Get AI-recommended low-glycemic meal options |

Full request/response schemas and manual testing are available via the interactive **Swagger UI** at `http://127.0.0.1:8000/docs`.

---

## 📊 Database Schema Summary

The primary PostgreSQL database contains the following core tables:

- `users`: User identity credentials, emails, and hashed passwords.
- `medical_profiles`: Physiological data (diabetes type, age, weight, activity level).
- `glucose_readings`: Timestamped blood sugar logs with pre/post-meal flags and notes.
- `predictions`: Logged prediction inputs (carbs, protein, fat, fiber, pre-meal glucose), predicted spike values, and serialized SHAP explanations.

---

## 🛣️ Project Roadmap

- [x] **Phase 1 (Core Platform)**: Auth, Medical Profiles, Glucose History Dashboard, YOLOv8 Camera Detection, XGBoost & SHAP Spike Prediction.
- [ ] **Phase 2 (Personalization)**: Adaptive user-specific ML retraining based on logged post-meal ground truth data.
- [ ] **Phase 3 (Prescriptive AI)**: Recommendation engine providing portion adjustments and exercise suggestions.
- [ ] **Phase 4 (Reports & Doctor Export)**: PDF report generation for medical consultation sharing.

---

## 📄 License

This project is released under the **MIT License**.

---

<p align="center">
  Developed with ❤️ for better health management & AI innovation.
</p>
