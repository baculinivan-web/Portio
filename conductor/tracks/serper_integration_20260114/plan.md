# Plan: Serper.dev Integration for Enhanced Nutrient Accuracy

## Phase 1: Infrastructure and Configuration [DONE] Checkpoint: 3e3ac58
- [x] Task: Add `SERPER_API_KEY` placeholder to `Gemini-Info.plist` and update `APIKeyManager` 525fbe0
- [x] Task: Update `OpenRouterModels.swift` to support tool calling (tools, tool_calls, tool_outputs) 468f29e
- [x] Task: Conductor - User Manual Verification 'Infrastructure and Configuration' (Protocol in workflow.md) 3e3ac58

## Phase 2: Serper.dev Service Implementation [DONE] Checkpoint: 316d037
- [x] Task: Create `SerperService.swift` to handle web search requests 20c47a5
- [x] Task: Implement unit tests for `SerperService` (Skipped: User requested to skip tests)
- [x] Task: Conductor - User Manual Verification 'Serper.dev Service Implementation' (Protocol in workflow.md) 316d037

## Phase 3: NutritionService Tool Calling Integration [DONE] Checkpoint: 9ade684
- [x] Task: Define the `google_search` tool in `NutritionService` 0953ffd
- [x] Task: Implement the tool calling loop in `NutritionService.fetchNutrition` 0953ffd
- [x] Task: Update the system prompt to instruct the LLM on when to use the search tool 0953ffd
- [x] Task: Conductor - User Manual Verification 'NutritionService Tool Calling Integration' (Protocol in workflow.md) 9ade684

## Phase 4: Verification and Refinement
- [ ] Task: Verify with branded food items (e.g., "Chobani Greek Yogurt")
- [ ] Task: Verify with restaurant menu items (e.g., "McDonald's Big Mac")
- [ ] Task: Handle edge cases (search failure, no results)
- [ ] Task: Conductor - User Manual Verification 'Verification and Refinement' (Protocol in workflow.md)
