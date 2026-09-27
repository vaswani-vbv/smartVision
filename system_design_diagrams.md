# SmartVision: System Design Diagrams

Below are the Mermaid.js diagrams generated from the Chapter 4 Design specifications. You can copy these directly into your markdown documentation or any Mermaid-compatible viewer.

## 4.1 System Architecture Diagram
Based on sections 4.1.1 and 4.1.2, illustrating the 3-tier architecture and the 5 principal modules.

```mermaid
flowchart TB
    Client((Client Browser))
    
    subgraph "Presentation Tier (React SPA)"
        UI[Dynamic UI Components]
        Viz[Data Visualization]
    end
    
    subgraph "Application Tier (FastAPI)"
        Auth[Auth Module<br>JWT & bcrypt]
        Users[Users Module<br>Profiles CRUD]
        Glucose[Glucose Module<br>Chronological Logging]
        Camera[Camera Module<br>Image Parsing & OpenCV]
        Pred[Predictions Module<br>Analytical Core]
        
        YOLO{{YOLOv8 Model}}
        XGB{{XGBoost + SHAP}}
        
        Camera <--> YOLO
        Pred <--> XGB
    end
    
    subgraph "Data Tier"
        PG[(PostgreSQL<br>Dynamic/Relational)]
        SQL[(SQLite<br>Static Nutrition)]
    end
    
    Client <-->|HTTP/HTTPS| UI
    UI <-->|Async JSON| Auth
    UI <-->|Async JSON| Users
    UI <-->|Async JSON| Glucose
    UI <-->|Multipart/form-data| Camera
    UI <-->|Async JSON| Pred
    
    Auth <--> PG
    Users <--> PG
    Glucose <--> PG
    Pred <--> PG
    
    Camera <--> SQL
    Pred <--> SQL
```

---

## 4.2.1 Class Diagram
Mapping the core SQLAlchemy ORM declarative base representations.

```mermaid
classDiagram
    class Users {
        +UUID id [PK]
        +String email
        +String password_hash
        +String name
        +DateTime created_at
    }
    class MedicalProfiles {
        +UUID id [PK]
        +UUID user_id [FK]
        +String diabetes_type
        +Integer age
        +Float weight_kg
        +Float height_cm
        +String activity_level
        +Text[] medications
        +Text[] conditions
    }
    class GlucoseReadings {
        +UUID id [PK]
        +UUID user_id [FK]
        +Float value_mgdl
        +String reading_type
        +Text notes
        +DateTime measured_at
    }
    class Predictions {
        +UUID id [PK]
        +UUID user_id [FK]
        +Float carbs_g
        +Float protein_g
        +Float fat_g
        +Float pre_meal_glucose
        +Float predicted_spike
        +Text shap_values
    }

    Users "1" -- "1" MedicalProfiles : has
    Users "1" -- "0..*" GlucoseReadings : logs
    Users "1" -- "0..*" Predictions : makes
```

---

## 4.2.2 Activity Diagram
Illustrating the sequence of actions for the "Scan Food & Predict" workflow.

```mermaid
sequenceDiagram
    actor User as Authenticated User
    participant React as React Client UI
    participant CameraAPI as Backend (/api/camera/detect)
    participant YOLO as YOLOv8 Vision Module
    participant SQLite as SQLite Data Store
    participant PredAPI as Backend (/api/predictions/predict)
    participant Postgres as PostgreSQL Data Store
    participant XGB as XGBoost & SHAP

    User->>React: Navigate to /scan & capture image
    React->>CameraAPI: POST binary image (FormData)
    CameraAPI->>YOLO: Invoke .predict()
    YOLO-->>CameraAPI: Return object class (e.g. "Apple")
    CameraAPI->>SQLite: Query macronutrients for object
    SQLite-->>CameraAPI: Return Carbs, Protein, Fat, Fiber
    CameraAPI-->>React: Return object & nutrition data
    User->>React: Review data & append pre-meal glucose
    React->>PredAPI: Submit finalized payload
    PredAPI->>Postgres: Extract user's MedicalProfile
    Postgres-->>PredAPI: Return physiological parameters
    PredAPI->>XGB: Send combined feature vector
    XGB-->>PredAPI: Compute forecasted spike & SHAP values
    PredAPI->>Postgres: Commit record to Predictions table
    PredAPI-->>React: Return synthesized JSON payload
    React->>User: Render SHAP waterfall visualization
```

---

## 4.2.3 Use Case Diagram
Mapping the primary operational actors and their authorized actions.

```mermaid
flowchart LR
    %% Actors
    User([Authenticated User])
    Backend([System Backend])

    %% User Use Cases
    User --> UC1(Register Account)
    User --> UC2(Securely Authenticate)
    User --> UC3(Manage Medical Profile Parameters)
    User --> UC4(View Interactive Health Dashboard)
    User --> UC5(Log Manual Capillary Glucose Readings)
    User --> UC6(Capture/Upload Photographic Dietary Images)
    User --> UC7(Initiate Postprandial Spike Predictions)
    User --> UC8(Review Interpretative SHAP Analytical Graphs)

    %% Backend Use Cases
    Backend --> BC1(Validate JWT Signatures)
    Backend --> BC2(Cryptographically Hash Passwords)
    Backend --> BC3(Execute Asynchronous YOLOv8 Object Classification)
    Backend --> BC4(Perform Rapid Queries against SQLite Database)
    Backend --> BC5(Execute XGBoost Regression Matrix Calculations)
    Backend --> BC6(Compute SHAP Marginal Values)
    Backend --> BC7(Commit Immutable Audit Records to PostgreSQL)
```

---

## 4.2.4 Data Flow Diagram (Level 0)
Illustrating the flow of data payloads through the 3-tier architecture.

```mermaid
flowchart TD
    User((User))
    
    subgraph "Presentation Tier"
        React[React UI]
    end
    
    subgraph "Application Tier"
        API[FastAPI]
        YOLO[YOLOv8 Vision Module]
        XGB[XGBoost Regression Module]
        SHAP[SHAP Interpretability Module]
    end
    
    subgraph "Data Tier"
        SQLite[(SQLite Data Store)]
        Postgres[(PostgreSQL Data Store)]
    end

    User -- Biometric & Image Data --> React
    React -- JSON/FormData Payloads --> API
    
    API -- Image Byte Stream --> YOLO
    YOLO -- Object Class String --> API
    
    API -- Object Class String --> SQLite
    SQLite -- Fixed Macronutrients --> API
    
    API -- Request Profile --> Postgres
    Postgres -- User Profile Data --> API
    
    API -- Feature Vector --> XGB
    XGB -- Scalar Output --> SHAP
    SHAP -- Explainer Matrices --> API
    
    API -- Synthesis Payload --> Postgres
    API -- Predicted Scalar + SHAP Array --> React
    
    React -- Visual DOM Decoding --> User
```
