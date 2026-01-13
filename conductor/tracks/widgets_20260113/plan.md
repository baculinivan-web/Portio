# Plan: add_widgets_small_and_medium

## Phase 1: Infrastructure and Setup (Checkpoint: 432b806)
- [x] Task: Enable App Groups for shared data between main app and Widget Extension 27dc20b
- [x] Task: Create Widget Extension target in Xcode 4a90e56
- [x] Task: Create shared Data Manager or use App Group container for SwiftData access in widgets 7047e25
- [x] Task: Conductor - User Manual Verification 'Infrastructure and Setup' (Protocol in workflow.md)

## Phase 2: Widget UI & "Liquid Glass" Styling
- [ ] Task: Implement common widget background view with translucency and blur (HIG compliant)
- [ ] Task: Create `CalorieProgressView` for Small and Medium widgets
- [ ] Task: Create `MacroBreakdownView` for Medium widget
- [ ] Task: Create `QuickActionButtonsView` for Medium widget
- [ ] Task: Conductor - User Manual Verification 'Widget UI & Styling' (Protocol in workflow.md)

## Phase 3: Data Integration and Logic
- [ ] Task: Implement `TimelineProvider` to fetch data from shared SwiftData store
- [ ] Task: Handle deep linking URLs in `CalCalApp.swift` for widget interactions
- [ ] Task: Implement logic to refresh widget timeline when app data changes
- [ ] Task: Conductor - User Manual Verification 'Data Integration' (Protocol in workflow.md)

## Phase 4: Verification and Polishing
- [ ] Task: Verify small and medium widget rendering in Simulator/Device
- [ ] Task: Test deep links for "Add Meal" and "Take Photo"
- [ ] Task: Final HIG and accessibility check (contrast, dynamic type)
- [ ] Task: Conductor - User Manual Verification 'Final Polish' (Protocol in workflow.md)
