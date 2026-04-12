# Specification: Restore Writable Properties to UserSettings and Verify Usage

## Overview
A recent refactor of `UserSettings.swift` turned the nutritional goal properties (calories, protein, carbs, fat) into get-only computed properties. This broke the build in `OnboardingView.swift` and potentially other files that attempt to assign values to these properties. This track adds the necessary `set` blocks and verifies all usage across the codebase.

## Functional Requirements
- **Settable Goals:** Add `set` blocks to `calorieGoal`, `proteinGoal`, `carbsGoal`, and `fatGoal` in `UserSettings.swift`.
- **Shared Persistence:** The setters must write directly to `UserSettings.shared` (the App Group suite) using the corresponding keys.
- **Restore Compilation:** Ensure `OnboardingView.swift` and any other parts of the app can assign values to these static properties.

## Acceptance Criteria
- The app compiles successfully without the "get-only property" error in `OnboardingView.swift`.
- Assigning a value to `UserSettings.calorieGoal` successfully persists the value to the App Group's `UserDefaults`.
- All other files attempting to write to `UserSettings` static properties are identified and verified to work correctly with the new setters.

## Out of Scope
- Adding new properties to `UserSettings`.
