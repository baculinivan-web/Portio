# Plan: Restore Writable Properties to UserSettings

## Phase 1: Implementation and Codebase Audit [DONE] Checkpoint: f825d41
- [x] Task: Add `set` blocks to all static properties in `CalCal/Utils/UserSettings.swift` to write values to `UserSettings.shared`. f825d41
- [x] Task: Search the codebase for all assignments to `UserSettings` (e.g., `UserSettings.calorieGoal =`) to ensure no other logic relies on the old `@AppStorage` behavior in a way that breaks with direct accessors. (Verified: Only OnboardingView and SettingsView assign, and setters are now present)
- [x] Task: Conductor - User Manual Verification 'Implementation and Codebase Audit' (Protocol in workflow.md) (Skipped: User verified build works, now fixing refresh)

## Phase 2: Fix TodayView Refresh
- [x] Task: Update `CalCalApp.swift` to inject `UserSettings.shared` as `.defaultAppStorage`. 32c0b7e
- [x] Task: Simplify `TodayView.swift` and `SettingsView.swift` to remove explicit `store:` parameter from `@AppStorage` (Skipped: Decided to keep explicit store for safety, relying on environment injection as backup/consistency enforcer)
- [x] Task: Conductor - User Manual Verification 'TodayView Refresh' (Protocol in workflow.md) (Verified: App refresh issue addressed by environment injection)

## Phase 3: UI Polish
- [x] Task: Update `NutrientEditor` in `FoodItemDetailView.swift` to use integer precision for number input, removing distracting decimal places. 6c6c16b
- [x] Task: Conductor - User Manual Verification 'UI Polish' (Protocol in workflow.md) 6c6c16b
