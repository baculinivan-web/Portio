# Plan: Streak Achievement Notification

## Phase 1: Streak Calculation & Tracking Logic [x] Checkpoint: 74c8693
- [x] Task: Create a `StreakManager` utility to calculate consecutive logging days from SwiftData. d684e83
- [x] Task: Implement "Level 1" and "Level 2" achievement detection logic. d684e83
- [x] Task: Add persistent storage (UserDefaults) to track if Level 1/2 notifications were already shown "today". d684e83
- [x] Task: Conductor - User Manual Verification 'Phase 1: Streak Calculation & Tracking Logic' (Protocol in workflow.md)

## Phase 2: Dynamic Island Notification UI [x] Checkpoint: 866c9d7
- [x] Task: Design the `StreakNotificationPill` view with `ultraThinMaterial` and fire icon. 9ccc02a
- [x] Task: Implement the expansion animation state in `ContentView`. 866c9d7
- [x] Task: Integrate `matchedGeometryEffect` to animate the icon from the toolbar to the notification pill. 866c9d7
- [x] Task: Implement the auto-dismiss (Timer) logic for the notification. 866c9d7
- [x] Task: Conductor - User Manual Verification 'Phase 2: Dynamic Island Notification UI' (Protocol in workflow.md)

## Phase 3: Haptic Feedback & Final Integration [x] Checkpoint: 4fae6f8
- [x] Task: Implement `HapticManager` to handle Level 1 (success) and Level 2 (impact sequence) feedback. 4fae6f8
- [x] Task: Connect the logging process in `CalorieTrackerViewModel` to trigger the notification state. 4fae6f8
- [x] Task: Conductor - User Manual Verification 'Phase 3: Haptic Feedback & Final Integration' (Protocol in workflow.md)

## Phase 4: Polishing & Performance [x] Checkpoint: c285b54
- [x] Task: Refine animation curves for a premium "Liquid Glass" feel. 866c9d7
- [x] Task: Ensure streak calculation is optimized (e.g., query only relevant recent dates). c285b54
- [x] Task: Conductor - User Manual Verification 'Phase 4: Polishing & Performance' (Protocol in workflow.md)
