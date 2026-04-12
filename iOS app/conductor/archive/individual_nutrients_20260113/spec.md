# Specification: individual_nutrient_widgets

## Overview
This track involves creating 4 new individual small widgets (2x2) for Calories, Protein, Carbs, and Fats. Each widget will follow a specific high-contrast layout inspired by modern habit-tracking apps, featuring a top-left aligned header, large nutrient name, "amount left" text, and a stylized bottom-right gauge.

**Reference Image:** `Images/30e8fb7002c178a99ab0dc8ca7f1768f.jpg`

## Functional Requirements
- **Four New Widgets:**
    - **Calories Widget:** Displays today's calories, remaining calories, and a calorie gauge.
    - **Protein Widget:** Displays today's protein, remaining grams, and a protein gauge.
    - **Carbs Widget:** Displays today's carbs, remaining grams, and a carbs gauge.
    - **Fats Widget:** Displays today's fats, remaining grams, and a fats gauge.
- **Visual Layout (Per Widget):**
    - **Precise Layout Copy:** The visual structure MUST strictly follow the reference image `Images/30e8fb7002c178a99ab0dc8ca7f1768f.jpg`.
    - **Top Row (Header):** "TODAY" (all caps, small, secondary color). Replaces "HABITS" from image.
    - **Second Row (Title):** Nutrient Name (e.g., "Calories", "Protein", large bold white/black text). Replaces "Daily Writing" from image.
    - **Third Row (Status):** Remaining Amount (e.g., "1200 kcal left", "45g left", nutrient-specific color). Replaces "10m left" from image.
    - **Overdo State:** If amount > goal, display "X over" in red text.
    - **Bottom-Right (Gauge):** Stylized circular Gauge/Ring with an integrated SF Symbol representing the nutrient. Must match the offset and design of the gauge in the reference image.
- **Styling & Color:**
    - **Background:** Respects system dark/light mode (Black/White).
    - **Accent Color:** Gauge and remaining text use nutrient-specific colors:
        - Calories: Orange (`flame.fill`)
        - Protein: Red (`bolt.fill`)
        - Carbs: Blue (`leaf.fill`)
        - Fats: Green (`drop.fill`)

## Non-Functional Requirements
- **Consistency:** Ensure the widgets look uniform as a set.
- **Shared Data:** Use the existing `SharedDataManager` and App Groups logic.

## Acceptance Criteria
- 4 new widget types are available in the widget gallery.
- Each widget accurately reflects current day data from the app.
- Layout perfectly matches the reference image provided by the user.
- Colors and symbols are correctly mapped to each nutrient.

## Out of Scope
- Interactive controls within these widgets.
