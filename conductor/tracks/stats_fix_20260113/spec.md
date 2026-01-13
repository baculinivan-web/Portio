# Specification: Fix Stats Scroll Effect and Breakdown ID Bug

## Overview
This track addresses two issues in the redesigned stats view:
1.  The "soft scroll edge liquid glass effect" is missing from the main dashboard lists.
2.  The macro breakdown list in `InteractiveMacroCard` incorrectly identifies items using their names, causing display errors when duplicate food names exist.

## Functional Requirements
- **Global Scroll Effect:**
  - Apply `.scrollEdgeEffectStyle(.soft, for: .vertical)` and the corresponding gradient mask to the main `ScrollView` containers in `TodayView.swift` and `TrendsView.swift`.
- **Unique Item Identification:**
  - Update the `filteredItems` logic in `InteractiveMacroCard.swift` to return the `UUID` of each `FoodItem`.
  - Update the `ForEach` loop in the breakdown list to use the unique `UUID` instead of the item's name as the identifier.

## Acceptance Criteria
- [ ] The main `Today` and `All Time` dashboards exhibit the soft scroll edge effect.
- [ ] Multiple food entries with the same name (e.g., "Cheeseburger") are displayed correctly as distinct entries in the expanded macro cards.
- [ ] End-to-end data flow remains accurate.
