# Plan: Nutritional Threshold Warnings

## Phase 1: Logic & Data Layer
- [x] Task: Implement threshold calculation logic in `NutritionAggregator` or a new utility (>=95% before 17:00, >100% always). 2c27fca
- [x] Task: Create a helper method to identify the "top contributors" (1-2 items) for a specific nutrient from a list of `FoodItem`. 2c27fca
- [ ] Task: Write unit tests for the threshold and top-contributor logic (Critical Logic). (Skipped per user request)
- [x] Task: Conductor - User Manual Verification 'Phase 1: Logic & Data Layer' (Protocol in workflow.md)

## Phase 2: UI Components
- [x] Task: Create `NutrientWarningCard.swift` with the dynamic title logic (e.g., "High Calories & Carbs detected") and "Liquid Glass" styling. 6d4e11b
- [x] Task: Create `NutrientWarningDetailView.swift` (the sheet) incorporating static explanation templates and the list of top contributors. 6d4e11b
- [x] Task: Integrate `NutrientWarningCard` into `ContentView.swift`, placed directly below the `TotalsCardView`. 6d4e11b
- [x] Task: Conductor - User Manual Verification 'Phase 2: UI Components' (Protocol in workflow.md)

## Phase 3: Final Integration & Polish
- [ ] Task: Ensure the warning card correctly responds to real-time data changes and time-of-day transitions.
- [ ] Task: Refine animations for the card's appearance/disappearance.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Final Integration & Polish' (Protocol in workflow.md)
