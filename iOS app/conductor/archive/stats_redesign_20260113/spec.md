# Specification: Creative Stats View Redesign

## Overview
This track focuses on redesigning the existing `StatisticsView` (and potentially `TotalsCardView`) to be more creative, readable, and interactive. The design will be inspired by provided reference images (modern, clean data visualization) while adhering to the app's "Liquid Glass" aesthetic. The new view will feature a segmented interface with two main tabs: "Today" and "All Time".

## Functional Requirements
- **Tabbed Interface:**
  - The view must contain a top-level picker or tab control to switch between "Today" and "All Time" views.
  
- **"Today" Tab (Card-Based Dashboard):**
  - **Metrics:** Display Calories, Protein, Carbs, and Fat.
  - **Card Design:** Each metric gets its own interactive card.
  - **Interactivity:**
    - **Expandable Details:** Tapping a card expands it to reveal more details (e.g., specific food items contributing to that macro, or a progress bar).
    - **Haptics:** Provide haptic feedback on tap.
  - **Visuals:** Use the "Liquid Glass" style (translucency, blur) adapted from the inspiration images.

- **"All Time" Tab (Trends Analysis):**
  - **Technology:** Use Apple's SwiftCharts framework.
  - **Charts:**
    - Line charts for calorie trends over time.
    - Bar charts for macronutrient distribution.
  - **Analysis Features:**
    - **Date Range Selection:** Toggle between Week, Month, and Year views.
    - **Goal Indicators:** Display horizontal lines representing daily goals on the charts.
    - **Comparison:** Show a visual indicator (e.g., "+5% vs last week") comparing the current period to the previous one.

## Non-Functional Requirements
- **Animation:** All transitions (tab switching, card expansion, chart loading) must be smooth and animated.
- **Performance:** Charts must load quickly and handle large datasets efficiently (using SwiftData aggregation).
- **Design:** The aesthetic must be "creative" and "readable," prioritizing clear data visualization over clutter.

## Acceptance Criteria
- [ ] `StatisticsView` is updated to support a tabbed interface ("Today" / "All Time").
- [ ] "Today" view displays interactive cards for each macro.
- [ ] Tapping a "Today" card expands it with animation and haptics.
- [ ] "All Time" view displays trends using SwiftCharts.
- [ ] Users can switch chart timeframes (Week/Month/Year).
- [ ] Charts show goal lines and comparison metrics.
- [ ] The overall design reflects the "Liquid Glass" aesthetic with modern data viz inspiration.
