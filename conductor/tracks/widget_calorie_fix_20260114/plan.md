# Plan: Fix Calorie Truncation on Small iPhone Medium Widget

## Phase 1: Implementation of Dynamic Scaling
- [x] Task: Apply dynamic scaling to the calorie count in `MediumWidgetView` in `CalCalWidget/CalCalWidget.swift`. 4734a47
    - Add `.minimumScaleFactor(0.6)` and `.lineLimit(1)` to the calorie value `Text`.
- [ ] Task: Group the calorie value and "kcal" unit to ensure they scale together or handle them consistently to prevent the unit from being pushed out.
- [ ] Task: Conductor - User Manual Verification 'Implementation of Dynamic Scaling' (Protocol in workflow.md)

## Phase 2: Preview and Layout Verification
- [ ] Task: Update `CalCalWidget_Previews` to include a case with a large calorie value (e.g., 2850) to verify the scaling logic.
- [ ] Task: Adjust horizontal spacing or padding if scaling alone is insufficient for 4-digit numbers on the smallest devices.
- [ ] Task: Conductor - User Manual Verification 'Preview and Layout Verification' (Protocol in workflow.md)
