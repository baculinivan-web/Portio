# Plan: Enhanced Search Grounding Visibility

## Phase 1: Data Model & Networking
- [x] Task: Define `SearchStep` and `SearchResult` structs/models. 29d2635
- [x] Task: Update `FoodItem` model in `Item.swift` to include `[SearchStep]`. 16e8cf2
- [x] Task: Update `NutritionResponse` in `NutritionService.swift` to include search data. eb02783
- [x] Task: Modify the tool-calling loop in `NutritionService.swift` to capture and store Serper.dev responses. eb02783
- [x] Task: Update `CalorieTrackerViewModel.swift` to map search data from the AI response to the `FoodItem`. eb02783
- [x] Task: Conductor - User Manual Verification 'Phase 1: Data Model & Networking' (Protocol in workflow.md)

## Phase 2: UI Implementation
- [x] Task: Create `SearchDetailRow.swift` component to display a single search step (query + 2 results). 7b32823
- [x] Task: Integrate search detail rows into `FoodItemDetailView.swift` under the "Entry Info" section. 3b62b40
- [x] Task: Apply "Liquid Glass" styling to the search detail cards. 8bb0234
- [ ] Task: Conductor - User Manual Verification 'Phase 2: UI Implementation' (Protocol in workflow.md)

## Phase 3: Final Polish
- [ ] Task: Verify that search data is correctly handled for multi-item queries (e.g., "Apple and Big Mac").
- [ ] Task: Final aesthetic review of links and snippets within the edit sheet.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Final Polish' (Protocol in workflow.md)
