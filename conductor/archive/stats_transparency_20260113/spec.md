# Specification: Refine Statistics View Transparency

## Overview
This track aims to further polish the "Liquid Glass" aesthetic of the `StatisticsView` by removing non-transparent backgrounds from the header (Navigation Bar) and the timeframe selector (Picker). This will allow the masterpiece gradient background to be fully visible while relying on the existing soft scroll edge effects for visual separation.

## Functional Requirements
- **Transparent Navigation Bar:**
  - Update `StatisticsView` to ensure the navigation bar background is fully transparent (e.g., using `.toolbarBackground(.hidden, for: .navigationBar)`).
- **Transparent Selector Background:**
  - Remove the `.ultraThinMaterial` background from the segmented picker container in `StatisticsView`.
  - Ensure the picker remains functional and visually clear against the background gradient.

## Acceptance Criteria
- [ ] The top navigation bar area has no solid or blurred background.
- [ ] The "Today / All Time" selector has no solid or blurred background.
- [ ] The background gradient is visible across the entire screen including the header area.
- [ ] All controls remain legible and interactive.
