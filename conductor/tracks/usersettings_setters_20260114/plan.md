# Plan: Restore Writable Properties to UserSettings

## Phase 1: Implementation and Codebase Audit [DONE] Checkpoint: f825d41
- [x] Task: Add `set` blocks to all static properties in `CalCal/Utils/UserSettings.swift` to write values to `UserSettings.shared`. f825d41
- [x] Task: Search the codebase for all assignments to `UserSettings` (e.g., `UserSettings.calorieGoal =`) to ensure no other logic relies on the old `@AppStorage` behavior in a way that breaks with direct accessors. (Verified: Only OnboardingView and SettingsView assign, and setters are now present)
- [x] Task: Conductor - User Manual Verification 'Implementation and Codebase Audit' (Protocol in workflow.md) (Skipped: User verified build works, now fixing refresh)

## Phase 2: Fix TodayView Refresh
- [ ] Task: Update `CalCalApp.swift` to inject `UserSettings.shared` as `.defaultAppStorage`.
- [ ] Task: Simplify `TodayView.swift` and `SettingsView.swift` to remove explicit `store:` parameter from `@AppStorage` (optional, but good for consistency, or keep it to be explicit). Let's keep it explicit for now but the environment injection often helps SwiftUI propagation.
- [ ] Task: Conductor - User Manual Verification 'TodayView Refresh' (Protocol in workflow.md)
