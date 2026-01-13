# Plan: Fix OpenRouter Model for Vision Support

## Phase 1: Configuration and API Manager [checkpoint: 42191a1]

- [x] Task: Update `Gemini-Info.plist` to include the `MODEL_NAME` key with value `google/gemma-3-27b-it:free` d518ded
- [x] Task: Update `APIKeyManager.swift` to include a `getModelName()` method df14aa8
- [x] Task: Conductor - User Manual Verification 'Configuration and API Manager' (Protocol in workflow.md) df14aa8

## Phase 2: Service Integration

- [x] Task: Update `OpenRouterConstants` in `OpenRouterModels.swift` to remove the hardcoded model string b0f6bce
- [x] Task: Refactor `NutritionService.swift` to retrieve the model name from `APIKeyManager` 65e0fd7
- [x] Task: Conductor - User Manual Verification 'Service Integration' (Protocol in workflow.md) 65e0fd7

## Phase 3: Final Verification

- [ ] Task: Manually verify that image-based queries are sent to the correct OpenRouter model
- [ ] Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)
