# Specification: color_code_protein_to_red

## Overview
This track involves updating the color coding for "Protein" from violet/purple to a specific red color (matching the small protein widget) across all UI elements in the app and its widgets. This ensures visual consistency and follows the established color scheme where Calories are Orange, Protein is Red, Carbs are Blue, and Fats are Green.

## Functional Requirements
- **Color Synchronization:**
    - Replace all instances of violet/purple representing Protein with the specific Red color used in the `ProteinWidget`.
- **Affected UI Areas (Main App):**
    - **Statistics View:** Update macro distribution charts, summary cards, and any trend lines.
    - **Today View / Totals Card:** Update the protein progress bar and labels in the `TotalsCardView` and `NutrientView`.
    - **Food Detail View:** Ensure macro editing/display labels use the new color.
- **Affected UI Areas (Widgets):**
    - **Medium Widget:** Update the protein macro mini bar and labels to match the small widget's red.
- **Consistency:** Ensure the exact same shade of red is used everywhere for protein.

## Non-Functional Requirements
- **Visual Clarity:** Maintain high contrast and legibility against both light and dark backgrounds.
- **Design Language:** Adhere to the existing "Liquid Glass" aesthetic.

## Acceptance Criteria
- All protein-related progress bars, icons, and text labels are now red instead of violet.
- The color matches the red used in the `ProteinWidget`.
- No remaining violet/purple macro representation exists in the app.

## Out of Scope
- Changing colors for Calories, Carbs, or Fats.
