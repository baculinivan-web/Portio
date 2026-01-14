# Plan: individual_nutrient_widgets

## Phase 1: Shared UI Components (Checkpoint: 6fa3f6d)
- [x] Task: Implement `NutrientGaugeView` (bottom-right stylized gauge with SF Symbol) 4e9e50c
- [x] Task: Implement `NutrientBaseView` (standard layout for Header, Title, and Remaining text) 4e9e50c
- [x] Task: Create a `NutrientTheme` model to manage colors and symbols for each type 4e9e50c
- [x] Task: Conductor - User Manual Verification 'Shared Components' (Protocol in workflow.md)

## Phase 2: Widget Logic & Data Mapping (Checkpoint: c10ffbf)
- [x] Task: Update `SimpleEntry` if necessary to support specific nutrient focus 4e9e50c
- [x] Task: Implement `NutrientProvider` or extend existing `Provider` to handle specific nutrient data 379103d
- [x] Task: Implement "Amount Left" calculation logic including "Overdo" state (red text) 379103d
- [x] Task: Conductor - User Manual Verification 'Data Mapping' (Protocol in workflow.md)

## Phase 3: Widget Configurations
- [ ] Task: Create `CalorieWidget`, `ProteinWidget`, `CarbsWidget`, and `FatWidget` structs
- [ ] Task: Register all new widgets in `CalCalWidgetBundle.swift`
- [ ] Task: Ensure background colors adapt to system light/dark mode correctly
- [ ] Task: Conductor - User Manual Verification 'Widget Registration' (Protocol in workflow.md)

## Phase 4: Verification and Polishing
- [ ] Task: Verify each of the 4 new widgets in the Gallery and Home Screen
- [ ] Task: Test "Overdo" state rendering for each nutrient
- [ ] Task: Final alignment and typography check against the reference image
- [ ] Task: Conductor - User Manual Verification 'Final Polish' (Protocol in workflow.md)
