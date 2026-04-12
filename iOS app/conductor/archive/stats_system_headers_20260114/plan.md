# Plan: System Collapsing Headers for Statistics

## Phase 1: Header Refactoring
- [x] Task: Update `StatisticsView.swift` to set the navigation title display mode to `.inline` (or verify behavior with `.large`). 05b8f53
- [x] Task: Ensure the `Picker` controls in `StatisticsView` are placed in a fixed `VStack` above the `ScrollView` to achieve the "Sticky" effect. 05b8f53
- [x] Task: Remove hardcoded header text like "Performance Overview" from `TodayView.swift` and `TrendsView.swift`. 05b8f53
- [x] Task: Conductor - User Manual Verification 'Phase 1: Header Refactoring' (Protocol in workflow.md)

## Phase 2: Navigation Refinement
- [x] Task: Adjust `ScrollView` in `StatisticsView` to ensure it extends to the full height of the view for correct navigation bar backdrop rendering. c5bcac6
- [x] Task: (Optional) Move segmented pickers into the `toolbar` if standard sticky behavior feels cluttered. 9c29213
- [x] Task: Conductor - User Manual Verification 'Phase 2: Navigation Refinement' (Protocol in workflow.md)