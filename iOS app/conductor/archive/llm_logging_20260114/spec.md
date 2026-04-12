# Specification: LLM Query Console Logging

## Overview
To improve developer visibility and facilitate debugging of AI interactions, this track implements comprehensive console logging for all LLM queries sent via the `NutritionService`. This will allow developers to see exactly what prompts are being sent and what raw JSON responses are being received in real-time.

## Functional Requirements
- **Request Logging:** Log the full message history (prompts, images, etc.) sent to OpenRouter.
- **Response Logging:** Log the raw JSON response body received from OpenRouter.
- **Debug Only:** All logging must be wrapped in `#if DEBUG` to ensure sensitive user data and prompts are not logged in production builds.
- **Formatting:** Use a clear and consistent format in the console to distinguish between different request phases (e.g., "[LLM REQUEST]", "[LLM RESPONSE]").

## Non-Functional Requirements
- **Performance:** Logging large payloads (like base64 images) should be handled efficiently or summarized to avoid console lag.
- **Privacy:** Ensure no API keys are printed to the console.

## Acceptance Criteria
- When a food analysis is triggered, the Xcode console shows the prompt sent to the LLM.
- After the API call completes, the console shows the raw JSON response.
- These logs are NOT present when running the app in a non-Debug configuration.

## Out of Scope
- On-screen debug UI.
- Logging to external analytics or file systems.
