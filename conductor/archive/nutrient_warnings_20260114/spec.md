# Specification: Nutritional Threshold Warnings

## Overview
This track introduces a proactive warning system to the Home Screen. If a user approaches or exceeds their daily goals for Calories, Carbohydrates, or Fats, a new "Liquid Glass" warning card will appear under the main summary. This card provides quick feedback and, upon interaction, reveals a detailed sheet explaining the implications and identifying the contributing food items.

## Functional Requirements
- **Threshold Logic:**
    - **Warning:** Trigger if current intake >= 95% of goal AND the current time is before 17:00.
    - **Overshoot:** Trigger if current intake > 100% of goal, regardless of time.
- **Monitored Nutrients:** Calories, Carbohydrates (Carbs), and Fats.
- **UI Component (Home Screen):**
    - A single combined card placed directly below the `TotalsCardView`.
    - The card text should dynamically mention all triggered nutrients (e.g., "High Calories & Carbs detected").
    - The card should only be visible when at least one threshold is met.
- **Detailed Explanation Sheet:**
    - Triggered by tapping the warning card.
    - **Content:**
        - **Overshoot Percentage:** Display how much the user has exceeded the goal for each triggered nutrient.
        - **Educational Context:** Use static templates to explain why excessive intake of that specific nutrient might be detrimental (e.g., "Excessive carb intake can lead to blood sugar spikes...").
        - **Top Contributors:** Identify and list the 1-2 food items from the current day with the highest content of the triggered nutrient.

## Non-Functional Requirements
- **Visual Consistency:** The warning card and sheet must adhere to the "Liquid Glass" aesthetic (translucency, SF Symbols, rounded corners).
- **Efficiency:** Calculations for thresholds should be performed on the main thread but optimized to avoid UI lag.

## Acceptance Criteria
- [ ] Warning card appears when Calories reach 96% at 14:00.
- [ ] Warning card appears when Fats reach 101% at 20:00.
- [ ] Warning card mentions both "Calories & Carbs" if both are triggered.
- [ ] Tapping the card opens a sheet with accurate overshoot percentages and the correct "top contributor" food items.
- [ ] The card is hidden if all nutrients are within safe bounds (e.g., <95% before 17:00).

## Out of Scope
- Monitoring Protein goals.
- AI-generated dynamic advice (using static templates instead).
- Push notifications for these warnings.
