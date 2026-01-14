# Specification: Serper.dev Integration for Enhanced Nutrient Accuracy

## Overview
This track aims to integrate the Serper.dev Search API into the nutritional analysis workflow. By leveraging real-time web search, the app will provide more accurate calorie and macronutrient data, especially for specific food items, brands, and restaurant menu items where the LLM's internal knowledge might be outdated or incomplete.

## Functional Requirements
- **Transparent Search:** The search process should be invisible to the user. It should be triggered automatically as part of the nutritional analysis.
- **Enhanced Accuracy:** Use Serper.dev to find specific nutritional information for:
    - Specific food items and brands.
    - Restaurant-specific menu items.
- **OpenRouter Tool Calling:** Integrate Serper.dev via OpenRouter's tool calling (function calling) mechanism. The LLM will decide when a search is necessary to fulfill a nutritional query.
- **Fallback Mechanism:** If a search fails or returns no useful data, the LLM should fallback to its internal knowledge.
- **Language Support:** Ensure that search queries are relevant to the language of the user's input.

## Non-Functional Requirements
- **Performance:** Tool calling and searching should not significantly delay the response time.
- **Security:** The Serper.dev API key must be managed securely using the existing `APIKeyManager` and stored in `Gemini-Info.plist`.

## Acceptance Criteria
- Queries for specific restaurant items (e.g., "Big Mac calories") return data that matches or closely approximates official nutritional info.
- Queries for branded items (e.g., "Chobani Greek Yogurt nutrition") return accurate data.
- The `NutritionService` successfully handles the tool calling loop (request -> tool call -> tool result -> final response).
- API keys are correctly loaded from `Gemini-Info.plist`.

## Out of Scope
- User-facing search interface.
- Searching for non-nutritional information.
- Integration with other search engines besides Serper.dev.
