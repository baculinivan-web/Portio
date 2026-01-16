# Plan: Streak & Monthly Contribution System

## Phase 1: Data Model & State Management [x] Checkpoint: 6ec0239
- [x] Task: Update `UserSettings` to include `WeightGoalMode` enum and storage. e49443e
- [x] Task: Update `OnboardingView` and `SettingsView` to allow users to select their weight goal mode. 5762ca7
- [x] Task: Implement a utility function/manager to fetch calorie totals for a specific date from SwiftData. 8da86c4
- [x] Task: Conductor - User Manual Verification 'Phase 1: Data Model & State Management' (Protocol in workflow.md)

## Phase 2: Toolbar Streak Indicator [x] Checkpoint: c17c6e1
- [x] Task: Implement today's logging check logic in a ViewModel or Manager. ff9df21
- [x] Task: Add the "fire" icon (`flame.fill`) to `ContentView` toolbar. a7f222c
- [x] Task: Style the icon based on today's logging status (orange if logged, gray otherwise). a7f222c
- [x] Task: Conductor - User Manual Verification 'Phase 2: Toolbar Streak Indicator' (Protocol in workflow.md)

## Phase 3: Streak History UI (The "TikTok" Grid) [x] Checkpoint: 8100394
- [x] Task: Create `ContributionGridView` for a single month based on the reference design. 2989ec2
- [x] Task: Implement the "TikTok-style" vertical paging `ScrollView` in `StreakHistoryView`. 2989ec2
- [x] Task: Write unit tests for the dot coloring logic (Losing vs Gaining vs Maintaining modes). 7bf62cf
- [x] Task: Implement the dot coloring logic in `ContributionGridView`. 7bf62cf
- [x] Task: Conductor - User Manual Verification 'Phase 3: Streak History UI (The "TikTok" Grid)' (Protocol in workflow.md)

## Phase 4: Day Interaction & Summary [x] Checkpoint: 07d408f
- [x] Task: Create a `DaySummaryView` to display food items and totals for a selected date. df6f615
- [x] Task: Add tap interaction to dots in `ContributionGridView` to present `DaySummaryView`. df6f615
- [x] Task: Conductor - User Manual Verification 'Phase 4: Day Interaction & Summary' (Protocol in workflow.md)

## Phase 5: Polishing & Liquid Glass Aesthetics
- [x] Task: Apply translucency and "Liquid Glass" styling to the `StreakHistoryView`. 194aa85
- [x] Task: Optimize SwiftData queries for smoother scrolling (e.g., pre-fetching month data). 194aa85
- [~] Task: Conductor - User Manual Verification 'Phase 5: Polishing & Liquid Glass Aesthetics' (Protocol in workflow.md)
