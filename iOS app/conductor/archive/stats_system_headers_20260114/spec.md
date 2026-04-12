# Specification: System Collapsing Headers for Statistics

## Overview
This track involves updating the headers in the Statistics module to use native iOS system navigation behaviors. The goal is to replace custom, static header labels with a standard `navigationTitle` that collapses on scroll, improving consistency with iOS design patterns while maintaining accessibility to filtering controls.

## Functional Requirements
- **System Navigation Title:** Update `StatisticsView` to use an `inline` navigation title style as the primary mode (collapsing from Large if applicable, but defaulting to centered inline for consistency).
- **Sticky Controls:** Maintain the "View Mode" (Today/All Time) and "Timeframe" segmented pickers as a sticky header above the scrollable content.
- **Header Replacement:** Remove manual "Performance Overview" and similar text labels within `TodayView` and `TrendsView` in favor of the system navigation title.
- **Scroll Behavior:** Ensure the `ScrollView` correctly triggers the navigation bar transitions when scrolling through charts and data.

## Non-Functional Requirements
- **HIG Adherence:** Ensure the transition between large and inline titles (if used) follows Apple's Human Interface Guidelines.
- **Smooth Transitions:** Animated switches between "Today" and "All Time" should remain fluid without causing jitter in the navigation bar.

## Acceptance Criteria
- [ ] `StatisticsView` displays "Your Statistics" in the system navigation bar.
- [ ] Scrolling down in the Statistics view causes the navigation bar to transition smoothly (standard iOS behavior).
- [ ] The segmented pickers for Tab and Timeframe remain visible and functional at the top of the screen during scrolling.
- [ ] Redundant custom header labels inside `TodayView` and `TrendsView` are removed.

## Out of Scope
- Redesigning the charts or macro breakdown logic.
- Adding new filtering options beyond the current segmented pickers.
