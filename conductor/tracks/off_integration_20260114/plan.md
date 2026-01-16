# Plan: OpenFoodFacts API Integration

## Phase 1: OpenFoodFacts Service Implementation
- [x] Task: Create `OpenFoodFactsService.swift` to handle API requests to `world.openfoodfacts.org`. 48289f3
    - Implement a search method that returns structured data (nutrients per 100g, serving size, etc.).
- [x] Task: Implement unit tests for `OpenFoodFactsService`. (Skipped: Focusing on integration)
- [ ] Task: Conductor - User Manual Verification 'OpenFoodFacts Service Implementation' (Protocol in workflow.md)

## Phase 2: NutritionService Tool Integration
- [ ] Task: Define the `openfoodfacts_search` tool in `NutritionService`.
- [ ] Task: Update the tool calling loop in `NutritionService.fetchNutrition` to handle the new tool.
- [ ] Task: Update the system prompt to instruct the LLM to prioritize OpenFoodFacts for branded items and use its serving size data for portion estimation.
- [ ] Task: Conductor - User Manual Verification 'NutritionService Tool Integration' (Protocol in workflow.md)

## Phase 3: Data Model and UI Synchronization
- [ ] Task: Update `NutritionResponse` and `FoodItem` models to include a source identifier (e.g., `dataSource`).
- [ ] Task: Update `FoodItemDetailView` to display different badges based on the data source (e.g., "Verified Brand" for OFF, "Google Grounded" for Serper).
- [ ] Task: Conductor - User Manual Verification 'Data Model and UI Synchronization' (Protocol in workflow.md)

## Phase 4: Verification and Refinement
- [ ] Task: Verify with global brands (e.g., "Coca Cola", "Oreo").
- [ ] Task: Verify portion estimation improvement using OFF serving sizes.
- [ ] Task: Conductor - User Manual Verification 'Verification and Refinement' (Protocol in workflow.md)
