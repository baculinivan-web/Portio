# Plan: Refactor Nutrition Service for OpenRouter

## Phase 1: Foundation and OpenRouter Integration [checkpoint: ddf00b9]

- [x] Task: Update APIKeyManager to support OpenRouter API Key b009a70
- [x] Task: Create OpenRouter client models for request and response handling 14d42fe
- [x] Task: Conductor - User Manual Verification 'Foundation' (Protocol in workflow.md) ddf00b9

## Phase 2: Service Refactoring

- [x] Task: Refactor `NutritionService.swift` to use OpenRouter for text-based queries 466050c
- [x] Task: Update `NutritionService.swift` to handle image-based queries via OpenRouter 5e4bf5d
- [x] Task: Implement error handling and logging for OpenRouter responses 2c0865a
- [ ] Task: Conductor - User Manual Verification 'Service Refactoring' (Protocol in workflow.md)

## Phase 3: Integration and Verification

- [ ] Task: Update `CalorieTrackerViewModel` to work with the refactored service
- [ ] Task: Run manual verification tests for food identification (text and image)
- [ ] Task: Conductor - User Manual Verification 'Integration and Verification' (Protocol in workflow.md)
