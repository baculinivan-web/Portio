# Specification: restore_standard_stats_theme

## Overview
This track aims to restore the standard system background and card styling in the `StatisticsView` to ensure visual consistency with the rest of the application (primarily the main `ContentView`). Currently, the Statistics view uses a custom pinkish gradient background and grayish cards that deviate from the app's core design language.

## Functional Requirements
- **Background Restoration:**
    - Remove the custom `LinearGradient` background in `StatisticsView`.
    - Replace it with the standard system background (white in light mode, black/dark in dark mode), matching `ContentView`.
- **Card Styling Update:**
    - Update the background of cards/containers in the Statistics subviews (e.g., `MacroDistributionChart`, `CalorieTrendChart`, `TrendComparisonView`, `InteractiveMacroCard`) to use `Color(uiColor: .secondarySystemGroupedBackground)`.
- **Consistency:**
    - Ensure all elements within the Statistics tab (Today, All Time) adhere to these standard styles.

## Non-Functional Requirements
- **HIG Compliance:** Adhere to Apple's Human Interface Guidelines regarding standard system backgrounds and grouped content.
- **Maintain Accessibility:** Ensure that the transition to standard backgrounds preserves high contrast and legibility.

## Acceptance Criteria
- `StatisticsView` no longer displays the pink/orange/blue gradient background.
- `StatisticsView` background matches the standard list/navigation background of the main app.
- All summary and chart cards in the Statistics tab use the standard secondary system grouped background color.
- UI elements (text, charts) remain clearly visible and functional on the updated backgrounds.

## Out of Scope
- Changing the layout or logic of the statistics calculations.
- Modifying the "Liquid Glass" effects where they are used intentionally for specific interactive components (unless they conflict with the background restoration).
