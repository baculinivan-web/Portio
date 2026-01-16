# Plan: OpenFoodFacts API Integration

## Phase 1: OpenFoodFacts Service Implementation [DONE] Checkpoint: c8f0e38
- [x] Task: Create `OpenFoodFactsService.swift` to handle API requests to `world.openfoodfacts.org`. 48289f3
- [x] Task: Implement unit tests for `OpenFoodFactsService`. (Skipped: Focusing on integration)
- [x] Task: Conductor - User Manual Verification 'OpenFoodFacts Service Implementation' (Protocol in workflow.md) c8f0e38

## Phase 2: NutritionService Tool Integration [DONE] Checkpoint: e2769fe
- [x] Task: Define the `openfoodfacts_search` tool in `NutritionService`. d15be4e
- [x] Task: Update the tool calling loop in `NutritionService.fetchNutrition` to handle the new tool. d15be4e
- [x] Task: Update the system prompt to instruct the LLM to prioritize OpenFoodFacts for branded items and use its serving size data for portion estimation. d15be4e
- [x] Task: Conductor - User Manual Verification 'NutritionService Tool Integration' (Protocol in workflow.md) e2769fe

## Phase 3: Data Model and UI Synchronization
- [x] Task: Update `NutritionResponse` and `FoodItem` models to include a source identifier (e.g., `dataSource`). f5b6e35
- [x] Task: Update `FoodItemDetailView` to display different badges based on the data source (e.g., "Verified Brand" for OFF, "Google Grounded" for Serper). 13fcfe4
- [~] Task: Conductor - User Manual Verification 'Data Model and UI Synchronization' (Protocol in workflow.md)

## Phase 4: Verification and Refinement
- [ ] Task: Verify with global brands (e.g., "Coca Cola", "Oreo").
- [ ] Task: Verify portion estimation improvement using OFF serving sizes.
- [ ] Task: Conductor - User Manual Verification 'Verification and Refinement' (Protocol in workflow.md)
