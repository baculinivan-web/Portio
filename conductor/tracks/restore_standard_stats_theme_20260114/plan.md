# Plan: restore_standard_stats_theme

## Phase 1: Background & Container Cleanup
- [x] Task: Remove custom background gradient from `StatisticsView.swift` 2919431
- [x] Task: Update `StatisticsView.swift` scroll view and masking to work with standard background 8c48de6f
- [ ] Task: Conductor - User Manual Verification 'Background & Container Cleanup' (Protocol in workflow.md)

## Phase 2: Card & Component Restyling
- [ ] Task: Update background color in `MacroDistributionChart.swift` to `secondarySystemGroupedBackground`
- [ ] Task: Update background color in `CalorieTrendChart.swift` to `secondarySystemGroupedBackground`
- [ ] Task: Update background color in `TrendComparisonView.swift` to `secondarySystemGroupedBackground`
- [ ] Task: Update background color in `InteractiveMacroCard.swift` to `secondarySystemGroupedBackground`
- [ ] Task: Conductor - User Manual Verification 'Card & Component Restyling' (Protocol in workflow.md)

## Phase 3: Final Verification & Polish
- [ ] Task: Verify contrast and visibility in both Light and Dark modes
- [ ] Task: Ensure scroll edge effects and masks in `StatisticsView` look correct with standard colors
- [ ] Task: Conductor - User Manual Verification 'Final Verification & Polish' (Protocol in workflow.md)
