# Specification: Remove Widget Border

## Overview
This track aims to refine the visual appearance of the primary CalCal widgets (Medium and Small variants featuring the large calorie ring/text) by removing the subtle light border. This change aligns with design goals to simplify the "Liquid Glass" aesthetic and remove unnecessary visual noise.

## Functional Requirements
- Remove the `0.5pt` white opacity border (stroke) from the `CalCalWidgetEntryView`.
- Ensure that the individual nutrient widgets (Calories, Protein, Carbs, Fat) which feature the small bottom-right gauge are **not** modified, as they currently do not utilize the `CalCalWidgetEntryView` overlay.

## Non-Functional Requirements
- **Consistency:** Maintain the existing `.thinMaterial` container background and corner radius for all widgets.
- **Performance:** No impact on widget performance or refresh rates.

## Acceptance Criteria
- [ ] The Medium CalCal widget displays without any visible light outline/border.
- [ ] The Small CalCal widget (with the large center ring) displays without any visible light outline/border.
- [ ] Individual nutrient widgets (Protein, Carbs, etc.) remain visually unchanged (no border, as per current design).

## Out of Scope
- Changing widget background materials or transparency levels.
- Adjusting corner radius.
- Modifying the layout or logic of the calorie gauges.
