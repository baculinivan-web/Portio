# Specification: Nutrient Imbalance Warning

## Overview
This track enhances the proactive warning system by monitoring the balance between macronutrients. If the percentage of the daily goal for Carbohydrates or Fats exceeds the Protein completion percentage by more than 30%, a warning will be triggered. This encourages users to maintain a balanced intake throughout the day.

## Functional Requirements
- **Imbalance Calculation Logic:**
    - Trigger if `(Current Carbs % of Goal) - (Current Protein % of Goal) > 30%`.
    - Trigger if `(Current Fat % of Goal) - (Current Protein % of Goal) > 30%`.
- **UI Integration (Home Screen):**
    - The warning will be integrated into the existing `NutrientWarningCard`.
    - If an imbalance is detected, the card title will dynamically include "Nutrient Imbalance".
- **Analysis Sheet Enhancement:**
    - Add a new section to the `NutrientWarningDetailView` for imbalances.
    - **Imbalance Statistics:** Show the specific percentage gap.
    - **Actionable Advice:** Static templates encouraging more protein and fewer carbs/fats.
    - **Top Imbalance Contributors:** Identify and list 2-3 items from today's log that have the highest content of the over-represented nutrient (Carbs or Fat).

## Non-Functional Requirements
- **Consistency:** Maintain the "standard card" aesthetic.
- **Real-time updates:** Re-calculate on every food entry modification.

## Acceptance Criteria
- [ ] Warning triggers correctly based on the 30% gap logic.
- [ ] Warning card mentions "Nutrient Imbalance".
- [ ] Analysis sheet lists the items contributing most to the Carbs/Fat imbalance.
