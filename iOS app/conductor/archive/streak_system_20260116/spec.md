# Specification: Streak & Monthly Contribution System

## Overview
Implement a visual streak and historical tracking system using a GitHub-style contribution grid. The system will provide immediate feedback via a toolbar icon and a dedicated, vertically-paged historical view styled after modern "TikTok" scrolling interfaces.

## Functional Requirements

### 1. Toolbar Streak Indicator
- **UI:** A "fire" (SF Symbol `flame.fill`) icon in the main toolbar.
- **State:** 
    - **Active (Color):** If the user has logged at least one `FoodItem` today.
    - **Inactive (Grayscale/Secondary):** If no items have been logged today.
- **Interaction:** Tapping the icon opens the "Streak History" view.

### 2. Streak History View (Monthly Contribution Grid)
- **UI Layout:** A vertical `ScrollView` with `containerRelativeFrame` and `scrollTargetBehavior(.paging)` to create a "TikTok-style" paged experience.
- **Visual Design:** Each page (or "TikTok vid") must strictly follow the design shown in [this reference image](../../../Images/c381badd1a364470c5b66f8defe8832b.jpg). This includes the Month/Year header, specific typography, day-of-week labels, and the circular contribution grid.
- **Page Content:** Each page represents one month.
- **Dot Coloring Logic:**
    - **No Entry:** Light gray/empty circle.
    - **Partial Success (Logged at least 1 item):** Half-transparency orange.
    - **Full Success (Orange):**
        - **Losing Weight Mode:** Total calories <= Calorie Goal.
        - **Gaining Weight Mode:** Total calories >= Calorie Goal.
        - **Maintaining Mode:** Total calories are within 90% to 110% of the Calorie Goal.

### 3. Day Interaction
- **Interaction:** Tapping a dot in the grid will show a summary of that day's consumption (e.g., a list of food items and total macros).

### 4. Data & Logic
- **Goal Management:** Add `weightGoalMode` (enum: `.lose`, `.gain`, `.maintain`) to `UserSettings` to drive the coloring logic.
- **Querying:** Use dynamic SwiftData queries to fetch items for specific months/days to calculate the dot states.

## Non-Functional Requirements
- **Performance:** Ensure smooth scrolling between months by efficiently fetching and caching daily totals.
- **Aesthetic:** Adhere to the "Liquid Glass" theme with translucency and smooth transitions, matching the reference image.

## Acceptance Criteria
- Fire icon correctly reflects "today's" logging status.
- The history view scrolls vertically month-by-month with "snapping" paging behavior.
- Each month page matches the visual style of [the reference image](../../../Images/c381badd1a364470c5b66f8defe8832b.jpg).
- The contribution dots color themselves accurately according to the user's `weightGoalMode` and daily calorie intake.
- Tapping a dot correctly retrieves and displays the food items for that specific day.

## Out of Scope
- Editing historical entries directly from the calendar (interaction is for viewing only).
- Year-long "full history" grid (view is month-by-month paged).
