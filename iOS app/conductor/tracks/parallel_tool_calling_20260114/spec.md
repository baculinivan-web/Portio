# Specification: Parallel Tool Calling Optimization

## Overview
The current `NutritionService` implementation handles tool calls sequentially, leading to slow response times for queries involving multiple items or multiple data sources. This track aims to refactor the architecture to support parallel tool calling, where the LLM is instructed to request all necessary information upfront, and the app executes these requests concurrently.

## Functional Requirements
- **Parallel Execution:** When the LLM returns multiple tool calls in a single response, execute them concurrently using Swift's `TaskGroup` or `async let`.
- **Prompt Engineering:** Update the system prompt to explicitly instruct the model to "Identify ALL distinct food items and necessary searches immediately" and emit all tool calls in the first turn.
- **Robustness:** Implement retry logic (1 retry) for individual tool failures within the batch. If a tool fails after retry, proceed with available data.
- **Model Support:** Verify and adjust `OpenRouterModels` if necessary to ensure it correctly decodes multiple `tool_calls` in a single message.

## Non-Functional Requirements
- **Latency Reduction:** The total time from user query to final JSON should be significantly reduced for multi-item queries.
- **Concurrency Safety:** Ensure shared resources (like the `capturedSearchSteps` array) are accessed safely.

## Acceptance Criteria
- A query like "Apple and Coke Zero" triggers parallel execution of tool calls (if tools are needed for both).
- The system prompt effectively convinces the model to batch its requests.
- Failed tool calls are retried once before proceeding.

## Out of Scope
- Changing the underlying model provider (unless the current one fundamentally doesn't support parallel calling).
