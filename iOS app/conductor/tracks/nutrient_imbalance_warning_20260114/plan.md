# Plan: Nutrient Imbalance Warning

## Phase 1: Logic & Data Layer
- [x] Task: Update `NutrientWarningManager.swift` to include logic for calculating completion gaps between nutrients. eb02783
- [x] Task: Extend `WarningNutrient` or create a new `WarningType` enum to distinguish between overshoot and imbalance. eb02783
- [ ] Task: Write unit tests for the 30% gap logic (Critical Logic). (Skipped)
- [x] Task: Conductor - User Manual Verification 'Phase 1: Logic & Data Layer' (Protocol in workflow.md)

## Phase 2: UI Components
- [x] Task: Update `NutrientWarningCard.swift` to handle the "Nutrient Imbalance" title logic and combine it with existing warnings. becee70
- [x] Task: Update `NutrientWarningDetailView.swift` to display a dedicated section for imbalances, including the percentage gap and actionable advice. becee70
- [x] Task: Enhance the "Highest Impact Items" list in the detail view to highlight items contributing to the imbalance. becee70
- [x] Task: Conductor - User Manual Verification 'Phase 2: UI Components' (Protocol in workflow.md)

## Phase 3: Integration & Testing
- [x] Task: Update `ContentView.swift` to calculate triggered imbalances and pass them to the warning card and sheet. 70557b4
- [x] Task: Verify that multiple warnings (e.g., "High Calories" and "Nutrient Imbalance") display correctly in the unified card. 70557b4
- [x] Task: Conductor - User Manual Verification 'Phase 3: Integration & Testing' (Protocol in workflow.md)
