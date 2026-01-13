# Plan: Pin Period Selector to Header

## Phase 1: State and Interface Refactor [checkpoint: c4d2200]

- [x] Task: Move `selectedTimeframe` state from `TrendsView.swift` to `StatisticsView.swift` c4d2200
- [x] Task: Update `TrendsView.swift` to accept `selectedTimeframe` as a parameter c4d2200
- [x] Task: Update `StatisticsView.swift` to include the timeframe `Picker` in the fixed top section c4d2200
- [x] Task: Apply conditional visibility to the timeframe `Picker` (only show when `selectedTab == .allTime`) c4d2200
- [x] Task: Conductor - User Manual Verification 'Interface Refactor' (Protocol in workflow.md) c4d2200

## Phase 2: Data Flow and Verification

- [ ] Task: Ensure `TrendsView` correctly triggers data fetching when the passed `selectedTimeframe` changes
- [ ] Task: Conduct a final visual check to ensure the pinned layout looks "masterpiece" quality
- [ ] Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)
