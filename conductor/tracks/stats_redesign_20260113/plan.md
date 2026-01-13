# Plan: Creative Stats View Redesign

## Phase 1: Foundation and Data Aggregation

- [x] Task: Implement SwiftData helper methods for aggregating nutritional data (Calories, Macros) by Day, Week, and Month b698d0f
- [ ] Task: Write unit tests for the data aggregation and comparison logic
- [ ] Task: Update `StatisticsView` skeleton to include a Segmented Picker for "Today" and "All Time"
- [ ] Task: Conductor - User Manual Verification 'Foundation and Data Aggregation' (Protocol in workflow.md)

## Phase 2: Redesigned "Today" View (Interactive Cards)

- [ ] Task: Create `InteractiveMacroCard` component with "Liquid Glass" styling and haptic feedback integration
- [ ] Task: Implement expansion logic for cards to reveal a detailed breakdown (e.g., contributing food items)
- [ ] Task: Integrate `InteractiveMacroCard` into the "Today" tab of `StatisticsView`
- [ ] Task: Conductor - User Manual Verification 'Redesigned Today View' (Protocol in workflow.md)

## Phase 3: "All Time" Trends View (SwiftCharts)

- [ ] Task: Implement `CalorieTrendChart` using SwiftCharts with support for Week/Month/Year views
- [ ] Task: Implement `MacroDistributionChart` using SwiftCharts to show macro trends
- [ ] Task: Add goal lines and comparison metrics (e.g., "% change vs previous period") to the trends view
- [ ] Task: Integrate charts and timeframe selection UI into the "All Time" tab
- [ ] Task: Conductor - User Manual Verification 'All Time Trends View' (Protocol in workflow.md)

## Phase 4: Final Polish and Integration

- [ ] Task: Ensure consistent "Liquid Glass" aesthetic (translucency, blur) across all new components
- [ ] Task: Refine animations for tab switching and card interactions
- [ ] Task: Conduct a final end-to-end verification of data accuracy and UI responsiveness
- [ ] Task: Conductor - User Manual Verification 'Final Polish and Integration' (Protocol in workflow.md)
