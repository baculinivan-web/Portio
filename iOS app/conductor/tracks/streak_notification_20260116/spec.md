# Specification: Streak Achievement Notification

## Overview
Enhance the "fire" streak icon with a modern, Dynamic Island-style expansion animation that celebrates milestones. When a user logs their first item of the day or reaches their daily calorie goal, the icon expands into a "Liquid Glass" notification pill at the top of the screen.

## Functional Requirements

### 1. Streak & Milestone Logic
- **Streak Count:** Calculate the number of consecutive calendar days (including today) where at least one `FoodItem` was logged.
- **Level 1 Achievement:** Triggered when the user logs their *first* item of the current calendar day.
- **Level 2 Achievement:** Triggered when the user's total calorie intake meets their `weightGoalMode` criteria for the first time that day (e.g., reaching the target or staying under the limit).

### 2. Dynamic Island Notification UI
- **Expansion Style:** The toolbar fire icon animates and expands into a centered, pill-shaped container at the top of the screen.
- **Visuals:** 
    - Use `ultraThinMaterial` for the container (Liquid Glass aesthetic).
    - Display the fire icon followed by text (e.g., "5 Day Streak!" for Level 1, or "Daily Goal Achieved!" for Level 2).
- **Behavior:** The notification appears, stays visible for 5 seconds, and then automatically shrinks back into the standard toolbar icon.

### 3. Sensory Feedback (Haptics)
- **Haptic Response:** Implement a high-quality haptic sequence using `UIImpactFeedbackGenerator` or `UINotificationFeedbackGenerator`.
    - **Level 1:** A "success" notification haptic.
    - **Level 2:** A multi-tap impact sequence to feel more substantial and rewarding.

### 4. State Management
- Ensure the achievement notifications only trigger once per day for each level to avoid redundant animations.

## Non-Functional Requirements
- **Fluid Animation:** Use SwiftUI's `matchedGeometryEffect` or high-quality spring animations to make the expansion feel integrated with the toolbar icon.
- **Performance:** Ensure streak calculations don't block the main thread during the logging process.

## Acceptance Criteria
- Level 1 notification triggers immediately after the first food item is added for the day.
- Level 2 notification triggers as soon as the nutritional goal is satisfied.
- Notification displays the correct consecutive day count and triggers appropriate haptics.
- UI matches the translucency and rounded aesthetics of the existing app.
- Notification auto-dismisses after the specified duration.

## Out of Scope
- Detailed historical achievement logs (the notification is a "live" celebration).
- Multi-day goal streaks (streak is based on logging activity only).
