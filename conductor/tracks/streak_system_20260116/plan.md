# Plan: Streak & Monthly Contribution System

## Phase 1: Data Model & State Management
- [x] Task: Update `UserSettings` to include `WeightGoalMode` enum and storage. e49443e
- [x] Task: Update `OnboardingView` and `SettingsView` to allow users to select their weight goal mode. 5762ca7
- [x] Task: Implement a utility function/manager to fetch calorie totals for a specific date from SwiftData. 8da86c4
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Data Model & State Management' (Protocol in workflow.md)

## Phase 2: Toolbar Streak Indicator
- [ ] Task: Implement today's logging check logic in a ViewModel or Manager.
- [ ] Task: Add the "fire" icon (`flame.fill`) to `ContentView` toolbar.
- [ ] Task: Style the icon based on today's logging status (orange if logged, gray otherwise).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Toolbar Streak Indicator' (Protocol in workflow.md)

## Phase 3: Streak History UI (The "TikTok" Grid)
- [ ] Task: Create `ContributionGridView` for a single month based on the reference design.
- [ ] Task: Implement the "TikTok-style" vertical paging `ScrollView` in `StreakHistoryView`.
- [ ] Task: Write unit tests for the dot coloring logic (Losing vs Gaining vs Maintaining modes).
- [ ] Task: Implement the dot coloring logic in `ContributionGridView`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Streak History UI (The "TikTok" Grid)' (Protocol in workflow.md)

## Phase 4: Day Interaction & Summary
- [ ] Task: Create a `DaySummaryView` to display food items and totals for a selected date.
- [ ] Task: Add tap interaction to dots in `ContributionGridView` to present `DaySummaryView`.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Day Interaction & Summary' (Protocol in workflow.md)

## Phase 5: Polishing & Liquid Glass Aesthetics
- [ ] Task: Apply translucency and "Liquid Glass" styling to the `StreakHistoryView`.
- [ ] Task: Optimize SwiftData queries for smoother scrolling (e.g., pre-fetching month data).
- [ ] Task: Conductor - User Manual Verification 'Phase 5: Polishing & Liquid Glass Aesthetics' (Protocol in workflow.md)
