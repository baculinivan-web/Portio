# Plan: LLM Query Console Logging

## Phase 1: Request and Response Logging in NutritionService
- [x] Task: Implement request logging in `NutritionService.fetchNutrition`. (Done) e20c3b6
- [x] Task: Implement raw response logging in `NutritionService.fetchNutrition`. (Done) e20c3b6
- [x] Task: Implement similar request/response logging in `NutritionService.fetchAIGoals`. (Done) e20c3b6
- [ ] Task: Conductor - User Manual Verification 'Request and Response Logging in NutritionService' (Protocol in workflow.md)

## Phase 2: Formatting and Safety
- [ ] Task: Wrap all new logging statements in `#if DEBUG` blocks to prevent logs in production.
- [ ] Task: Refine log formatting with clear headers (e.g., `--- OPENROUTER REQUEST ---`) and separators for readability.
- [ ] Task: Conductor - User Manual Verification 'Formatting and Safety' (Protocol in workflow.md)
