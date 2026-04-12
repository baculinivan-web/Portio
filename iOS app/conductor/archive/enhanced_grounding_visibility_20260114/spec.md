# Specification: Enhanced Search Grounding Visibility

## Overview
This track enhances the transparency of AI nutritional analysis by displaying the specific Google Search details used to ground the data. When the AI performs a web search (via Serper.dev) to identify or verify nutritional information, the queries and top results will be stored and presented to the user in the food item's detail view.

## Functional Requirements
- **Data Persistence:**
    - Update the `FoodItem` model to store an array of `SearchStep` objects.
    - Each `SearchStep` will contain:
        - `query`: The string sent to Google Search.
        - `results`: An array of objects containing `title`, `link`, and `snippet` for the top 2 sites.
- **AI Service Integration:**
    - Modify `NutritionService` to capture the search queries and results during the tool-calling loop.
    - Update the `NutritionResponse` and `FoodItem` creation logic to propagate this data.
- **UI Enhancement (`FoodItemDetailView`):**
    - Within the "Entry Info" section, if search data exists:
        - Display each search query used.
        - Under each query, show the top 2 search results.
        - Each result should include the site title, a clickable link (opens in Safari), and the text snippet provided by the search API.
        - Use "Liquid Glass" styling for these sub-elements to maintain visual consistency.

## Non-Functional Requirements
- **Data Integrity:** Ensure that manual edits to nutritional data do not accidentally wipe the search history.
- **UX:** The search details should be informative but not overwhelm the edit sheet; use subtle typography and spacing.

## Acceptance Criteria
- [ ] `FoodItem` successfully stores multiple search steps.
- [ ] `NutritionService` correctly captures and passes Serper.dev results back to the ViewModel.
- [ ] `FoodItemDetailView` displays the queries and top 2 site snippets/links when "Google Search Grounded" is true.
- [ ] Links in the search results are functional and open the browser.

## Out of Scope
- Displaying more than the top 2 results.
- Storing full HTML content of the pages (only snippets from Serper.dev).
