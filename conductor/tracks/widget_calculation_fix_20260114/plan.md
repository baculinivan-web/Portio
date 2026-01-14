# Plan: Fix Incorrect Calorie 'Over' Calculation in Small Widget

## Phase 1: Data Consistency and Model Unification [DONE] Checkpoint: 40466ca
- [x] Task: Synchronize `FoodItem` model between App and Widget. d0e22d2
- [x] Task: Fix `TodayView` goal synchronization. d606b76
- [x] Task: Conductor - User Manual Verification 'Data Consistency and Model Unification' (Protocol in workflow.md) 40466ca

## Phase 2: Calculation Logic Verification and Debugging
- [ ] Task: Audit `SharedDataManager.fetchTodaysStats()` in both app and widget to ensure `FoodItem`s are fetched correctly and not duplicated.
- [ ] Task: Add a defensive check in `NutrientBaseView` to ensure `over` and `remaining` logic is robust against floating point issues (though current logic seems fine).
- [ ] Task: Verify the fix by comparing the main app's "over" status with the small widget's status.
- [ ] Task: Conductor - User Manual Verification 'Calculation Logic Verification and Debugging' (Protocol in workflow.md)
