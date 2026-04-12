# Specification: Fix OpenRouter "Param Incorrect" Error for Tool Calls

## Overview
The user is experiencing intermittent search failures with the error "The server returned an invalid response". Logs indicate a specific 400 error from the OpenRouter provider (Xiaomi/Nvidia) stating: `{"message":"Param Incorrect","param":"'text' is not present"}`. This typically happens during the multi-turn tool calling sequence, likely when sending the tool's output back to the model. Some providers strictly require a `text` field in the message content, even for tool outputs.

## Functional Requirements
- **Robust Message Formatting:** Ensure that all messages sent to OpenRouter (especially those with `role: "tool"`) strictly adhere to the API requirements of fussy providers.
- **Fix Missing 'text' Parameter:** Modify `NutritionService` or `OpenRouterModels` to ensure that when a tool result is sent, the content structure explicitly includes the necessary text fields that the provider expects.
- **Error Handling:** Improve the error reporting to be more specific than "invalid response" if possible, though the primary goal is to prevent the error.

## Non-Functional Requirements
- **Reliability:** The search function should work consistently without intermittent provider errors.

## Acceptance Criteria
- Performing a food search that triggers a tool call (e.g., "Chicken in sour cream") completes successfully without returning a 400 "Param Incorrect" error.
- The app successfully handles the tool call loop for providers that enforce strict parameter presence.

## Out of Scope
- Changing the model provider (user is happy with Nvidia/current setup, the issue is likely formatting).
- UI changes.
