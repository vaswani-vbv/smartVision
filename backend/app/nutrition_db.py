import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "nutrition.db")

def init_nutrition_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS food_nutrition (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_name TEXT UNIQUE NOT NULL,
        serving_size TEXT NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL,
        calories REAL NOT NULL
    )
    """)

    # Initial data
    initial_foods = [
        ("Apple", "100g", 14.0, 0.3, 0.2, 2.4, 52.0),
        ("Banana", "100g", 23.0, 1.1, 0.3, 2.6, 89.0),
        ("Rice", "100g", 28.0, 2.7, 0.3, 0.4, 130.0),
        ("Bread", "100g", 49.0, 9.0, 3.2, 2.7, 265.0),
        ("Pizza", "1 slice", 36.0, 12.0, 10.0, 2.0, 285.0),
    ]

    for food in initial_foods:
        cursor.execute("""
        INSERT OR IGNORE INTO food_nutrition 
        (food_name, serving_size, carbs, protein, fat, fiber, calories)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """, food)

    conn.commit()
    conn.close()

def get_food_nutrition(food_name: str):
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # Simple case-insensitive match
    cursor.execute("""
    SELECT * FROM food_nutrition 
    WHERE LOWER(food_name) = LOWER(?)
    """, (food_name,))
    
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return dict(row)
    return None

# Initialize on import
init_nutrition_db()
