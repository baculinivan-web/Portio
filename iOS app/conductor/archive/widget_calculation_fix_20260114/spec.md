# Specification: Fix Incorrect Calorie 'Over' Calculation in Small Widget

## Overview
The small widget's "calorie status" text (which displays how many calories are left or if the user is over their goal) is showing incorrect values. Specifically, a user reported seeing "723 kcal over" when they were only "57 kcal over". This track aims to identify and fix the calculation logic in the small widget.

## Functional Requirements
- **Correct Calculation:**
    - If `Consumed < Goal`: Display "X kcal left" where `X = Goal - Consumed`.
    - If `Consumed > Goal`: Display "Y kcal over" where `Y = Consumed - Goal`.
- **Consistency:** The value displayed must match the actual data derived from `SharedDataManager`.

## Non-Functional Requirements
- **Reliability:** The widget should update consistently with the main app's data.

## Acceptance Criteria
- When the user's intake exceeds their goal by 57 kcal, the widget displays "57 kcal over" (not 723 or any other incorrect number).
- When the user is under their goal, it correctly displays the remaining calories.

## Out of Scope
- Changes to the main app's UI.
- Changes to other widget sizes (unless they share the exact same flawed logic code).
