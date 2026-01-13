# Specification: Macro Breakdown with Liquid Glass Scroll Effect

## Overview
This track adds a detailed breakdown of food items to the expanded state of each macro card in the `TodayView`. It also applies a "soft scroll edge liquid glass effect" to the breakdown list, ensuring items elegantly fade and blur as they reach the scroll boundaries, matching the project's premium aesthetic.

## Functional Requirements
- **Dynamic Breakdown List:**
  - When an `InteractiveMacroCard` is expanded, it will display a scrollable list of food items logged today that contribute to that specific macro (e.g., Protein).
  - Each list item will show:
    - `cleanFoodName`
    - Contribution amount (e.g., "30g")
- **Liquid Glass Scroll Effect:**
  - The breakdown list will utilize the `.scrollEdgeEffectStyle(.soft, for: .vertical)` modifier (standard in this environment) to create a diffused, rounded, and "liquid" transition at the scroll edges.
  - Additionally, a gradient mask will be applied to ensure a smooth "melting" effect into the glass card background.
- **Data Integration:**
  - The `TodayView` will pass the relevant subset of `FoodItem` objects to each card.
  - Cards will filter these items to show only those with a non-zero contribution to the specific macro.

## Acceptance Criteria
- [ ] Expanded cards display a list of contributing food items.
- [ ] Items show name and macro grams correctly.
- [ ] The scrollable area has "soft" edges that fade out content at the top and bottom.
- [ ] The transition during expansion remains smooth and performant.
- [ ] Visual style is consistent with the "Liquid Glass" design system.
