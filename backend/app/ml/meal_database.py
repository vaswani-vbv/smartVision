# Curated Indian meal database with macros per standard serving
# All values are per typical single serving

INDIAN_MEALS = [
    # Breakfast
    {
        "name":        "Idli (3 pieces) with Sambar",
        "category":    "breakfast",
        "carbs_g":     45,
        "protein_g":   8,
        "fat_g":       2,
        "fiber_g":     4,
        "calories":    230,
        "gi":          "low",
        "description": "Fermented rice cakes — low GI, easy to digest",
        "tags":        ["light", "low-fat", "vegetarian"]
    },
    {
        "name":        "Oats Upma",
        "category":    "breakfast",
        "carbs_g":     32,
        "protein_g":   7,
        "fat_g":       5,
        "fiber_g":     5,
        "calories":    198,
        "gi":          "low",
        "description": "High fiber oats with vegetables — very slow glucose release",
        "tags":        ["high-fiber", "low-gi", "vegetarian"]
    },
    {
        "name":        "Moong Dal Cheela (2 pieces)",
        "category":    "breakfast",
        "carbs_g":     28,
        "protein_g":   12,
        "fat_g":       4,
        "fiber_g":     5,
        "calories":    196,
        "gi":          "low",
        "description": "Protein-rich lentil pancakes — minimal glucose spike",
        "tags":        ["high-protein", "low-gi", "vegetarian"]
    },
    {
        "name":        "Poha with Vegetables",
        "category":    "breakfast",
        "carbs_g":     52,
        "protein_g":   5,
        "fat_g":       6,
        "fiber_g":     3,
        "calories":    280,
        "gi":          "medium",
        "description": "Flattened rice — moderate GI, add peanuts for protein",
        "tags":        ["moderate-gi", "vegetarian"]
    },
    {
        "name":        "Whole Wheat Paratha (1) with Curd",
        "category":    "breakfast",
        "carbs_g":     38,
        "protein_g":   9,
        "fat_g":       8,
        "fiber_g":     4,
        "calories":    260,
        "gi":          "medium",
        "description": "Whole wheat with curd protein — moderate impact",
        "tags":        ["moderate-gi", "vegetarian"]
    },

    # Lunch
    {
        "name":        "Brown Rice + Dal + Sabzi",
        "category":    "lunch",
        "carbs_g":     55,
        "protein_g":   15,
        "fat_g":       6,
        "fiber_g":     8,
        "calories":    335,
        "gi":          "low",
        "description": "Brown rice has higher fiber than white — slower glucose release",
        "tags":        ["balanced", "high-fiber", "vegetarian"]
    },
    {
        "name":        "Rajma Chawal (small portion)",
        "category":    "lunch",
        "carbs_g":     62,
        "protein_g":   14,
        "fat_g":       5,
        "fiber_g":     9,
        "calories":    350,
        "gi":          "low",
        "description": "Kidney beans are very high fiber — despite carbs, spike is moderate",
        "tags":        ["high-fiber", "high-protein", "vegetarian"]
    },
    {
        "name":        "Grilled Chicken + 2 Rotis + Salad",
        "category":    "lunch",
        "carbs_g":     40,
        "protein_g":   28,
        "fat_g":       8,
        "fiber_g":     5,
        "calories":    345,
        "gi":          "low",
        "description": "High protein slows glucose absorption significantly",
        "tags":        ["high-protein", "low-gi", "non-vegetarian"]
    },
    {
        "name":        "Chole with 1 Bhatura",
        "category":    "lunch",
        "carbs_g":     75,
        "protein_g":   12,
        "fat_g":       14,
        "fiber_g":     6,
        "calories":    480,
        "gi":          "high",
        "description": "High carb and fat — not ideal for diabetics, avoid if glucose is elevated",
        "tags":        ["high-gi", "avoid-if-elevated", "vegetarian"]
    },
    {
        "name":        "Paneer Bhurji + 2 Rotis",
        "category":    "lunch",
        "carbs_g":     42,
        "protein_g":   22,
        "fat_g":       16,
        "fiber_g":     4,
        "calories":    400,
        "gi":          "low",
        "description": "High protein cottage cheese significantly blunts glucose spike",
        "tags":        ["high-protein", "low-gi", "vegetarian"]
    },
    {
        "name":        "Dal Khichdi (light)",
        "category":    "lunch",
        "carbs_g":     48,
        "protein_g":   12,
        "fat_g":       5,
        "fiber_g":     6,
        "calories":    285,
        "gi":          "medium",
        "description": "Easy to digest, balanced meal — good recovery option",
        "tags":        ["balanced", "easy-digest", "vegetarian"]
    },
    {
        "name":        "Fish Curry + 1 Cup Rice",
        "category":    "lunch",
        "carbs_g":     50,
        "protein_g":   25,
        "fat_g":       10,
        "fiber_g":     3,
        "calories":    390,
        "gi":          "medium",
        "description": "Omega-3 from fish improves insulin sensitivity",
        "tags":        ["high-protein", "omega-3", "non-vegetarian"]
    },

    # Dinner
    {
        "name":        "Dal + 2 Rotis + Cucumber Salad",
        "category":    "dinner",
        "carbs_g":     45,
        "protein_g":   14,
        "fat_g":       5,
        "fiber_g":     7,
        "calories":    280,
        "gi":          "low",
        "description": "Light, high-fiber dinner — minimal overnight glucose rise",
        "tags":        ["light", "high-fiber", "vegetarian"]
    },
    {
        "name":        "Palak Paneer + 1 Roti",
        "category":    "dinner",
        "carbs_g":     30,
        "protein_g":   18,
        "fat_g":       14,
        "fiber_g":     5,
        "calories":    320,
        "gi":          "low",
        "description": "Spinach + paneer — iron, protein, very low GI impact",
        "tags":        ["high-protein", "low-gi", "vegetarian"]
    },
    {
        "name":        "Egg Bhurji + 2 Rotis",
        "category":    "dinner",
        "carbs_g":     36,
        "protein_g":   20,
        "fat_g":       12,
        "fiber_g":     4,
        "calories":    330,
        "gi":          "low",
        "description": "Eggs have near-zero GI — protein dominant, low spike",
        "tags":        ["high-protein", "low-gi", "non-vegetarian"]
    },
    {
        "name":        "Vegetable Soup + 1 Multigrain Toast",
        "category":    "dinner",
        "carbs_g":     22,
        "protein_g":   5,
        "fat_g":       3,
        "fiber_g":     4,
        "calories":    135,
        "gi":          "low",
        "description": "Very light option — ideal if glucose was elevated during the day",
        "tags":        ["light", "very-low-carb", "vegetarian"]
    },
    {
        "name":        "Chicken Soup + 1 Roti",
        "category":    "dinner",
        "carbs_g":     25,
        "protein_g":   22,
        "fat_g":       6,
        "fiber_g":     3,
        "calories":    240,
        "gi":          "low",
        "description": "High protein, low carb — excellent bedtime glucose control",
        "tags":        ["high-protein", "low-carb", "non-vegetarian"]
    },

    # Snacks
    {
        "name":        "Handful of Mixed Nuts (30g)",
        "category":    "snack",
        "carbs_g":     6,
        "protein_g":   6,
        "fat_g":       16,
        "fiber_g":     2,
        "calories":    190,
        "gi":          "very-low",
        "description": "Almost no glucose impact — ideal between-meal snack",
        "tags":        ["very-low-gi", "healthy-fat", "vegetarian"]
    },
    {
        "name":        "Greek Yogurt (100g) with Berries",
        "category":    "snack",
        "carbs_g":     12,
        "protein_g":   10,
        "fat_g":       3,
        "fiber_g":     1,
        "calories":    115,
        "gi":          "low",
        "description": "Probiotics + protein — minimal glucose impact",
        "tags":        ["high-protein", "low-gi", "vegetarian"]
    },
    {
        "name":        "Sprouts Chaat (1 cup)",
        "category":    "snack",
        "carbs_g":     18,
        "protein_g":   8,
        "fat_g":       2,
        "fiber_g":     6,
        "calories":    125,
        "gi":          "low",
        "description": "High fiber and protein sprouts — very low spike",
        "tags":        ["high-fiber", "high-protein", "vegetarian"]
    },
    {
        "name":        "Roasted Chana (30g)",
        "category":    "snack",
        "carbs_g":     20,
        "protein_g":   7,
        "fat_g":       3,
        "fiber_g":     5,
        "calories":    135,
        "gi":          "low",
        "description": "Chickpeas are low GI despite carbs — fiber slows absorption",
        "tags":        ["high-fiber", "low-gi", "vegetarian"]
    },
]
