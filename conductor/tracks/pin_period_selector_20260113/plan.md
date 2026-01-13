# Plan: Pin Period Selector to Header

## Phase 1: State and Interface Refactor

- [ ] Task: Move `selectedTimeframe` state from `TrendsView.swift` to `StatisticsView.swift`
- [ ] Task: Update `TrendsView.swift` to accept `selectedTimeframe` as a parameter
- [ ] Task: Update `StatisticsView.swift` to include the timeframe `Picker` in the fixed top section
- [ ] Task: Apply conditional visibility to the timeframe `Picker` (only show when `selectedTab == .allTime`)
- [ ] Task: Conductor - User Manual Verification 'Interface Refactor' (Protocol in workflow.md)

## Phase 2: Data Flow and Verification

- [ ] Task: Ensure `TrendsView` correctly triggers data fetching when the passed `selectedTimeframe` changes
- [ ] Task: Conduct a final visual check to ensure the pinned layout looks "masterpiece" quality
- [ ] Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)
