# Plan: Streak Achievement Notification

## Phase 1: Streak Calculation & Tracking Logic
- [x] Task: Create a `StreakManager` utility to calculate consecutive logging days from SwiftData. d684e83
- [x] Task: Implement "Level 1" and "Level 2" achievement detection logic. d684e83
- [x] Task: Add persistent storage (UserDefaults) to track if Level 1/2 notifications were already shown "today". d684e83
- [~] Task: Conductor - User Manual Verification 'Phase 1: Streak Calculation & Tracking Logic' (Protocol in workflow.md)

## Phase 2: Dynamic Island Notification UI
- [ ] Task: Design the `StreakNotificationPill` view with `ultraThinMaterial` and fire icon.
- [ ] Task: Implement the expansion animation state in `ContentView`.
- [ ] Task: Integrate `matchedGeometryEffect` to animate the icon from the toolbar to the notification pill.
- [ ] Task: Implement the auto-dismiss (Timer) logic for the notification.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Dynamic Island Notification UI' (Protocol in workflow.md)

## Phase 3: Haptic Feedback & Final Integration
- [ ] Task: Implement `HapticManager` to handle Level 1 (success) and Level 2 (impact sequence) feedback.
- [ ] Task: Connect the logging process in `CalorieTrackerViewModel` to trigger the notification state.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Haptic Feedback & Final Integration' (Protocol in workflow.md)

## Phase 4: Polishing & Performance
- [ ] Task: Refine animation curves for a premium "Liquid Glass" feel.
- [ ] Task: Ensure streak calculation is optimized (e.g., query only relevant recent dates).
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Polishing & Performance' (Protocol in workflow.md)
