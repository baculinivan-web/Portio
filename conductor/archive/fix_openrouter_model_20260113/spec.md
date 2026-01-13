# Specification: Fix OpenRouter Model for Vision Support

## Overview
The current default model (`nvidia/nemotron-3-nano-30b-a3b:free`) is reporting a lack of support for image input through the OpenRouter endpoint. This track updates the application to use `google/gemma-3-27b-it:free` and moves the model selection logic into a configuration file for better maintainability.

## Functional Requirements
- **Model Switch:**
  - Update the default AI model to `google/gemma-3-27b-it:free`.
- **Configuration Management:**
  - Add a `MODEL_NAME` key to `Gemini-Info.plist` (or rename/use a new config file as appropriate, but we'll stick to `Gemini-Info.plist` for consistency with API key storage).
  - Update `APIKeyManager` to retrieve the model name from the configuration file.
  - Update `NutritionService` to use the model name provided by `APIKeyManager`.

## Acceptance Criteria
- [ ] `Gemini-Info.plist` contains the correct model identifier.
- [ ] `APIKeyManager` successfully retrieves the model name.
- [ ] `NutritionService` sends requests using the new model.
- [ ] Image-based food logging no longer returns "no endpoint that supports image input" errors (assuming the model supports it).
