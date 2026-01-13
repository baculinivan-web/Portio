# Specification: Pin Period Selector to Header

## Overview
This track refactors the `StatisticsView` layout to move the "Week / Month / Year" timeframe selector from the scrollable `TrendsView` content into the fixed header of `StatisticsView`. This ensures that when the user is in the "All Time" tab, the period selector remains fixed at the top (directly below the "Today / All Time" tab selector) and does not scroll away with the charts.

## Functional Requirements
- **Layout Refactor:**
  - Move the timeframe `Picker` logic out of `TrendsView.swift` and into `StatisticsView.swift`.
  - The `StatisticsView` will now manage the `selectedTimeframe` state.
  - The timeframe selector will only be visible when the "All Time" tab is active.
  - Position the timeframe selector in a fixed `VStack` within the `StatisticsView` header, immediately following the "Today / All Time" selector.
- **State Management:**
  - Pass the `selectedTimeframe` as a parameter from `StatisticsView` down to `TrendsView`.
  - Ensure `TrendsView` correctly updates its data when the timeframe is changed in the fixed header.

## Acceptance Criteria
- [ ] The "Week / Month / Year" selector is no longer part of the scrollable content in the "All Time" tab.
- [ ] The timeframe selector is pinned at the top of the view, below the tab selector.
- [ ] The timeframe selector is only visible when "All Time" is selected.
- [ ] Changing the timeframe correctly updates the charts in `TrendsView`.
- [ ] The layout maintains the "Liquid Glass" masterpiece aesthetic.
