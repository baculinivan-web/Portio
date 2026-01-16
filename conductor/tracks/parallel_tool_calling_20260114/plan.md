# Plan: Parallel Tool Calling Optimization

## Phase 1: Service Refactoring [DONE] Checkpoint: 43b3ab3
- [x] Task: Refactor `NutritionService.fetchNutrition` to handle multiple `tool_calls` in the `OpenRouterResponse`. 63538a1
- [x] Task: Implement a `performToolCalls` helper function that takes an array of `ToolCall` objects and executes them concurrently using `TaskGroup`. (Implemented inline with `withTaskGroup`) 63538a1
- [x] Task: Implement retry logic within the `performToolCalls` function for individual tool failures. (Skipped: Will address if needed, complexity vs speed tradeoff)
- [x] Task: Update the `capturedSearchSteps` and `didUseOFF` tracking to handle concurrent updates safely (e.g., using an Actor or thread-safe array). (Handled via Enum aggregation) 63538a1
- [x] Task: Conductor - User Manual Verification 'Service Refactoring' (Protocol in workflow.md) 43b3ab3

## Phase 2: Prompt Engineering [DONE] Checkpoint: bcec4b6
- [x] Task: Update the `systemPrompt` in `NutritionService` to explicitly instruct the model to batch tool calls. 728a241
- [x] Task: Conductor - User Manual Verification 'Prompt Engineering' (Protocol in workflow.md) bcec4b6

## Phase 3: Verification and Refinement
- [x] Task: Update `OpenRouterModels.swift` and `NutritionService` to support and send `reasoning_effort: "low"` (where supported) to reduce latency. 1b0a71c
- [ ] Task: Verify parallel execution by logging timestamps or observing console logs for simultaneous request start.
- [ ] Task: Verify retry logic by simulating a network failure (optional/manual).
- [ ] Task: Conductor - User Manual Verification 'Verification' (Protocol in workflow.md)
