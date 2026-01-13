# Plan: Fix Stats Scroll Effect and Breakdown ID Bug

## Phase 1: Fixing Breakdown Identification [checkpoint: e7d2a82]

- [x] Task: Update `filteredItems` in `InteractiveMacroCard.swift` to include `UUID` e7d2a82
- [x] Task: Update breakdown list `ForEach` to use `id` for unique identification e7d2a82
- [x] Task: Verify that duplicate names are handled correctly in the UI e7d2a82
- [x] Task: Conductor - User Manual Verification 'Breakdown Identification' (Protocol in workflow.md) e7d2a82

## Phase 2: Applying Global Scroll Effects

- [ ] Task: Refactor `TodayView.swift` to apply the soft scroll edge effect to the main ScrollView
- [ ] Task: Refactor `TrendsView.swift` to apply the soft scroll edge effect to the main ScrollView
- [ ] Task: Conductor - User Manual Verification 'Global Scroll Effects' (Protocol in workflow.md)

## Phase 3: Final Verification and documentation update

- [ ] Task: Ensure animations and transitions between tabs are smooth with the new effects
- [ ] Task: Final project synchronization
- [ ] Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)
