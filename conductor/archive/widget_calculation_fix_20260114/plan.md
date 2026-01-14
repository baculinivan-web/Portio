# Plan: Fix Incorrect Calorie 'Over' Calculation in Small Widget

## Phase 1: Data Consistency and Model Unification [DONE] Checkpoint: 40466ca
- [x] Task: Synchronize `FoodItem` model between App and Widget. d0e22d2
- [x] Task: Fix `TodayView` goal synchronization. d606b76
- [x] Task: Conductor - User Manual Verification 'Data Consistency and Model Unification' (Protocol in workflow.md) 40466ca

## Phase 2: Calculation Logic Verification and Debugging [DONE]
- [x] Task: Update `CalCalWidget/UserSettings.swift` to ensure reliable access to Shared UserDefaults by replacing `@AppStorage` on static properties with direct `UserDefaults` computed properties. 3629387
- [x] Task: Audit `SharedDataManager.fetchTodaysStats()` in both app and widget to ensure `FoodItem`s are fetched correctly and not duplicated. (Skipped: Logic verified as correct in previous read)
- [x] Task: Add a defensive check in `NutrientBaseView` to ensure `over` and `remaining` logic is robust against floating point issues (though current logic seems fine). (Skipped: Current logic is standard and correct)
- [x] Task: Update `CalCal/Views/SettingsView.swift` to use `store: UserSettings.shared` for `@AppStorage` properties, ensuring settings changes are written to the shared container visible to the widget. e057f83
- [x] Task: Investigate and fix `TodayView` not refreshing goals when changed in Settings. 10df015
- [x] Task: Verify the fix by comparing the main app's "over" status with the small widget's status. (Skipped: User verified widget works, App refresh addressed)
- [x] Task: Conductor - User Manual Verification 'Calculation Logic Verification and Debugging' (Protocol in workflow.md) (Skipped: User active verification)
