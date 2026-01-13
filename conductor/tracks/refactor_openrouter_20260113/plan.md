# Plan: Refactor Nutrition Service for OpenRouter

## Phase 1: Foundation and OpenRouter Integration

- [x] Task: Update APIKeyManager to support OpenRouter API Key b009a70
- [x] Task: Create OpenRouter client models for request and response handling 14d42fe
- [ ] Task: Conductor - User Manual Verification 'Foundation' (Protocol in workflow.md)

## Phase 2: Service Refactoring

- [ ] Task: Refactor `NutritionService.swift` to use OpenRouter for text-based queries
- [ ] Task: Update `NutritionService.swift` to handle image-based queries via OpenRouter
- [ ] Task: Implement error handling and logging for OpenRouter responses
- [ ] Task: Conductor - User Manual Verification 'Service Refactoring' (Protocol in workflow.md)

## Phase 3: Integration and Verification

- [ ] Task: Update `CalorieTrackerViewModel` to work with the refactored service
- [ ] Task: Run manual verification tests for food identification (text and image)
- [ ] Task: Conductor - User Manual Verification 'Integration and Verification' (Protocol in workflow.md)
