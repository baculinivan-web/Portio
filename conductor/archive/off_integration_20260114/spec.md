# Specification: OpenFoodFacts API Integration

## Overview
This track integrates the OpenFoodFacts API as a primary source for branded food item data. This complements the existing Google Search (Serper) integration by providing highly structured, verifiable nutritional data. The AI will prioritize searching OpenFoodFacts for branded items and use its data for both per-100g values and portion estimation (serving sizes).

## Functional Requirements
- **OFF Tool Calling:** Implement a `openfoodfacts_search` tool for the LLM via OpenRouter.
- **Priority Logic:** The LLM will be instructed to prioritize OpenFoodFacts for branded products and fall back to Google Search (Serper) only if OFF returns no results or insufficient data.
- **Structured Data Extraction:** Parse OFF's response to extract:
    - Calories, protein, carbs, fat (per 100g).
    - Serving size/unit weight (to improve portion estimation).
    - Product brand and name.
- **Language Support:** Use OFF's search parameters to search in the user's primary language if possible.
- **Barcode Foundation:** Design the implementation to allow future barcode scanning integration by supporting ID-based lookups in the internal service.

## Non-Functional Requirements
- **Reliability:** Handle OFF API downtimes or rate limits gracefully.
- **Accuracy:** Ensure data mapping from OFF's JSON structure to our `NutritionResponse` model is precise.

## Acceptance Criteria
- Queries for common brands (e.g., "Nutella", "Chobani") successfully trigger an OFF tool call.
- The app correctly uses the serving size from OFF if available and no weight is specified by the user.
- The "Google Search grounded" tag logic is extended or updated to distinguish between sources (e.g., "Verified Brand Data").

## Out of Scope
- Implementing the Barcode Scanner UI (just the backend service support).
- Real-time nutrition label OCR.
