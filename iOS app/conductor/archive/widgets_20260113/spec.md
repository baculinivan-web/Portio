# Specification: add_widgets_small_and_medium

## Overview
This track involves implementing Home Screen widgets (small and medium sizes) for the CalCal app. These widgets will provide users with a quick glance at their nutritional progress and offer shortcuts to key features, maintaining the app's "Liquid Glass" aesthetic while adhering to Apple's Human Interface Guidelines.

## Functional Requirements
- **Small Widget:**
    - Display daily calorie progress (consumed vs. goal).
    - Visual indicator (e.g., ring or progress bar) of calorie intake.
- **Medium Widget:**
    - Display daily calorie progress.
    - Display macro breakdown (Protein, Carbs, Fats) with values or progress bars.
    - Include quick action buttons: "Add Meal" (opens text input) and "Take Photo" (opens camera).
- **Deep Linking:**
    - Tapping the widget (or specific buttons) will launch the app and navigate to the appropriate view.

## Non-Functional Requirements
- **Visual Style:** Implement the "Liquid Glass" look using translucency, blur effects, and vibrant colors, ensuring high legibility and HIG compliance.
- **Data Synchronization:** Ensure widget data stays up-to-date with the main app's SwiftData store (using App Groups).
- **Performance:** Optimize widget rendering to minimize battery and memory usage.

## Acceptance Criteria
- Small and medium widgets are available in the widget gallery.
- Widgets correctly display data from the user's current day logs.
- Tapping "Add Meal" on the medium widget opens the app's chat/text input view.
- Tapping "Take Photo" on the medium widget opens the app's camera view.
- The visual design matches the app's translucent, modern aesthetic.

## Out of Scope
- Large-sized widgets.
- Interactive background logging (Widget Intents) for this phase (Deep links only).
- Lock screen widgets.
