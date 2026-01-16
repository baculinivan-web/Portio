# Specification: refactor_small_widget

## Overview
This track involves refactoring the small widget's UI to improve visual balance, fix text overflow issues for larger calorie counts, and align its header with the "Today" labeling used in the medium widget.

## Functional Requirements
- **Header Update:**
    - Replace the "CalCal" label with "Today".
    - Style the "Today" label with a secondary color and align it to the top-left.
- **Calorie Ring Refinement:**
    - Increase the overall size of the calorie ring to fill more of the widget's available space by reducing surrounding padding.
    - Implement `.minimumScaleFactor()` on the calorie count text to ensure 3-digit and 4-digit numbers fit within the ring without clipping.
- **Layout Adjustments:**
    - Optimize vertical spacing between the "Today" header, the ring, and the goal label at the bottom.

## Non-Functional Requirements
- **Visual Clarity:** Ensure the calorie count remains highly legible even when scaled down.
- **Consistency:** Maintain the "Liquid Glass" aesthetic and rounded design language.

## Acceptance Criteria
- Small widget displays "Today" in the top-left.
- Calorie counts (e.g., "170", "1200") fit perfectly inside the ring without overflow.
- The ring appears larger and more prominent than in the previous version.

## Out of Scope
- Functional changes to data fetching or deep links.
