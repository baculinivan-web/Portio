# Plan: Serper.dev Integration for Enhanced Nutrient Accuracy

## Phase 1: Infrastructure and Configuration
- [x] Task: Add `SERPER_API_KEY` placeholder to `Gemini-Info.plist` and update `APIKeyManager` 525fbe0
- [x] Task: Update `OpenRouterModels.swift` to support tool calling (tools, tool_calls, tool_outputs) 468f29e
- [ ] Task: Conductor - User Manual Verification 'Infrastructure and Configuration' (Protocol in workflow.md)

## Phase 2: Serper.dev Service Implementation
- [ ] Task: Create `SerperService.swift` to handle web search requests
- [ ] Task: Implement unit tests for `SerperService`
- [ ] Task: Conductor - User Manual Verification 'Serper.dev Service Implementation' (Protocol in workflow.md)

## Phase 3: NutritionService Tool Calling Integration
- [ ] Task: Define the `google_search` tool in `NutritionService`
- [ ] Task: Implement the tool calling loop in `NutritionService.fetchNutrition`
- [ ] Task: Update the system prompt to instruct the LLM on when to use the search tool
- [ ] Task: Conductor - User Manual Verification 'NutritionService Tool Calling Integration' (Protocol in workflow.md)

## Phase 4: Verification and Refinement
- [ ] Task: Verify with branded food items (e.g., "Chobani Greek Yogurt")
- [ ] Task: Verify with restaurant menu items (e.g., "McDonald's Big Mac")
- [ ] Task: Handle edge cases (search failure, no results)
- [ ] Task: Conductor - User Manual Verification 'Verification and Refinement' (Protocol in workflow.md)
