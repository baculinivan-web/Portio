# Specification: Fix Calorie Truncation on Small iPhone Medium Widget

## Overview
On smaller iPhone models (like iPhone SE or mini), the medium-sized widget fails to display 3 or 4-digit calorie amounts correctly. The text is truncated (e.g., "2 8..." instead of "2800"), which is confusing for the user. This track aims to fix this by implementing dynamic font scaling for the calorie count.

## Functional Requirements
- **Dynamic Font Scaling:** The main calorie count in the medium widget should automatically shrink its font size if the value exceeds the available horizontal space.
- **Maintain Readability:** Set a reasonable minimum scale factor so the text remains legible even when shrunk.
- **Specific to Medium Widget:** Ensure the fix is applied to the medium widget variant where the issue was reported.

## Non-Functional Requirements
- **Visual Consistency:** The scaling should feel natural and maintain the "Liquid Glass" aesthetic.
- **Performance:** Dynamic scaling should not impact widget rendering performance.

## Acceptance Criteria
- 4-digit calorie amounts (e.g., "2800") are fully visible on a small iPhone (SE/mini) medium widget.
- The text does not show ellipsis ("...") or truncation.
- The font size returns to normal for smaller values (e.g., "500").

## Out of Scope
- Redesigning the entire widget layout.
- Changing the font family or primary styling.
- Addressing truncation in other widget sizes (unless a similar issue is identified).
