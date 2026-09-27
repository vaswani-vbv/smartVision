# SmartVision: Project Overview

SmartVision is a full-stack, AI-powered web application designed to help users manage their diabetes. It allows users to log their glucose levels, track their health over time, and use advanced artificial intelligence to predict how different meals will affect their blood sugar.

Here is an easy-to-understand, in-depth breakdown of how everything is built and how the pieces talk to each other.

---

## 1. The Frontend (The User Interface)
**Technology:** React, TypeScript, Recharts

This is the visual part of the application that runs in your web browser (Chrome, Safari, etc.). It is responsible for making the app look good and responding to your clicks.

*   **Pages & Routing:** We use `react-router` to let you navigate between different screens smoothly without reloading the web page (Dashboard, Profile, Glucose Log, Manual Predict, Scan Food).
*   **Charts & Visuals:** We use a library called `recharts` on the Dashboard and Glucose Log pages to draw the beautiful, color-coded graphs of your blood sugar over time.
*   **Camera Integration:** On the "Scan Food" page, React directly taps into your laptop's webcam using standard HTML5 APIs. When you click "Capture", React grabs that specific frame and sends it over the internet to the backend for analysis.

## 2. The Backend (The Brain)
**Technology:** Python, FastAPI

The backend is a server running continuously in the background. It is the "brain" that processes requests from the frontend, enforces security, and talks to the databases and AI models.

*   **FastAPI:** This is a lightning-fast modern Python framework. It exposes "Endpoints" (like `/api/glucose/log` or `/api/camera/detect`). When React needs to save a reading or scan an image, it makes an HTTP request to these specific URLs.
*   **Security (JWT):** When you log in, the backend gives React a "Token" (JSON Web Token). React attaches this token to every future request so the backend knows exactly who you are and keeps your medical data completely private.

## 3. The Databases (The Memory)
**Technology:** PostgreSQL & SQLite

You are actually running a **Dual-Database architecture**:

1.  **PostgreSQL (The Main Database):** 
    *   Running safely inside a Docker container.
    *   **Purpose:** Stores dynamic, user-generated data. This holds the `Users` table (emails, hashed passwords), the `Profiles` table (age, weight, diabetes type), and the `GlucoseReadings` table (your logged blood sugar numbers and timestamps).
2.  **SQLite (The Nutrition Database):** 
    *   A lightweight file located at `backend/app/nutrition.db`.
    *   **Purpose:** Stores static data. It holds a dictionary of foods (Apple, Banana, Rice, Pizza) and their base nutritional values (Carbs, Protein, Fat, Fiber).

## 4. The Artificial Intelligence (The Magic)
**Technology:** XGBoost (Machine Learning) & YOLOv8 (Computer Vision)

SmartVision has two completely different types of AI running under the hood:

### A. The Glucose Prediction Model (XGBoost)
*   **What it is:** A Machine Learning regression model.
*   **How it works:** We wrote a script (`train_model.py`) that generates thousands of rows of realistic, synthetic medical data based on known diabetes physiology (e.g., Carbs increase spikes, Fiber slows them down, Type 1 diabetics spike higher). We trained an **XGBoost** model on this data.
*   **SHAP Explanations:** We don't just give you a predicted number; we use a library called **SHAP**. SHAP mathematically breaks down the prediction to explain *why* the model made that guess (e.g., "Your glucose will spike by 40mg/dL, mostly because this meal has 60g of carbs").

### B. The Food Scanner (YOLOv8)
*   **What it is:** A state-of-the-art Computer Vision object detection model created by Ultralytics.
*   **How it works:** When React sends an image from your laptop camera to the backend, the backend feeds that image into YOLOv8. YOLO looks at the pixels and says, "I am 92% confident there is an Apple in this image." 

## 5. Putting it all together: The "Scan Food" Workflow
To understand how everything works in harmony, let's trace exactly what happens when you use the Scan Food feature:

1.  **Frontend:** You sit in front of your laptop and click "Capture Photo" on the React website.
2.  **Frontend:** React converts the webcam frame into an image file and sends a `POST` request to the backend at `/api/camera/detect`.
3.  **Backend:** FastAPI receives the image and hands it to the **YOLOv8** model.
4.  **AI (YOLO):** YOLO analyzes the image and returns the word: `"Apple"`.
5.  **Backend & Database:** The backend takes the word "Apple" and queries the **SQLite Nutrition Database**. The database replies: *"An Apple has 14g Carbs, 0.3g Protein, and 2.4g Fiber"*.
6.  **Backend:** FastAPI sends this nutritional data back to React.
7.  **Frontend:** React automatically fills in the Carbs, Protein, and Fiber text boxes on your screen.
8.  **Frontend:** You click "Predict Glucose Spike". React sends those numbers to the backend at `/api/predictions/predict`.
9.  **AI (XGBoost):** The backend feeds those macros (plus your medical profile from **PostgreSQL**) into the **XGBoost** model.
10. **Backend:** XGBoost returns the predicted spike and the SHAP explanation. FastAPI sends it back to React.
11. **Frontend:** React displays the beautiful color-coded prediction cards telling you how your body will react to the apple!
