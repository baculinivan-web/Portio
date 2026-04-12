# Specification: Refactor Nutrition Service for OpenRouter

## Overview
This track involves migrating the existing AI-driven nutrition identification service from the direct Google Gemini SDK to the OpenRouter API. This change is part of the updated technology stack to allow for greater flexibility in choosing LLM models.

## Objectives
- Integrate OpenRouter API for food identification and nutrient analysis.
- Maintain existing functionality for text descriptions and image analysis.
- Update `NutritionService.swift` and related components to work with the new API.
- Ensure proper error handling for network and API-specific issues.

## Requirements
- Use OpenRouter API endpoints.
- Support model selection (e.g., Gemini or Claude) via OpenRouter.
- Handle image data (base64) for visual food recognition.
- Parse JSON responses from OpenRouter into existing `FoodItem` models.
