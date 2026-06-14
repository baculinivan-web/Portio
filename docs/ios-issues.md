# iOS Issues Handoff

Context: iOS app is the original SwiftUI/SwiftData app for AI calorie tracking. It supports text/photo food logging, OpenRouter-compatible LLM calls, tool use with OpenFoodFacts and Serper, widgets via App Groups, HealthKit, and BGTaskScheduler processing.

Start by running the iOS test/build flow in Xcode or with `xcodebuild` from `iOS app/Portio.xcodeproj`. The previous review was static; no iOS build was executed.

## Critical

No definite iOS compile-breaking issue was confirmed in the static review. Most iOS findings are privacy, reliability, and correctness risks.

## High

### 1. Debug logging exposes private food/profile data and LLM traffic

File:
- `iOS app/Portio/Services/NutritionService.swift`

Problem:
- `#if DEBUG` logging prints full OpenRouter request/response details.
- Logged data can include:
  - Food queries.
  - User profile stats and personal goals.
  - Full goal-generation prompt.
  - Tool calls and tool arguments.
  - Serper/OpenFoodFacts search summaries.
  - Full LLM responses.
- Error branches also print API response bodies outside some `#if DEBUG` blocks.

Relevant areas:
- Request logging in `fetchNutrition`.
- Response logging in `fetchNutrition`.
- Error body logging in `fetchNutrition`.
- Prompt/response/error logging in `fetchAIGoals`.

Expected fix:
- Remove full prompt/response logging by default.
- Gate any diagnostic logs behind an explicit local debug flag.
- Redact authorization/API-key-bearing data.
- Avoid logging full user profile/goal/food text unless the user explicitly opts into diagnostics.

### 2. Background task registration uses force-cast

File:
- `iOS app/Portio/Utils/BackgroundTaskManager.swift`

Problem:
- `registerBackgroundTask()` does `task as! BGProcessingTask`.
- If the scheduler gives a different task type or configuration drifts, this crashes.

Expected fix:
- Use `guard let processingTask = task as? BGProcessingTask else { task.setTaskCompleted(success: false); return }`.
- Consider logging a sanitized diagnostic.

### 3. Background processing duplicates foreground work and can race

Files:
- `iOS app/Portio/ViewModels/CalorieTrackerViewModel.swift`
- `iOS app/Portio/Utils/BackgroundTaskManager.swift`

Problem:
- Foreground `addItem()` inserts a processing item and immediately starts a `Task` that calls `nutritionService.fetchNutrition`.
- It also schedules a BGProcessingTask right after insert.
- `BackgroundTaskManager.processAllPendingItems()` fetches all `isProcessing == true` items and can process the same item if the background task runs while the foreground task is still active.
- There is no explicit item-level lock, in-flight marker, attempt ID, or compare-and-swap update.

Expected fix:
- Add a processing ownership mechanism:
  - `processingJobId`, `lastAttemptAt`, or item status enum.
  - Foreground task and BG task should not process the same placeholder concurrently.
- Alternatively schedule background processing only when app is leaving foreground or foreground task is cancelled.
- Add tests/manual verification for fast backgrounding after adding an item.

### 4. HealthKit writes happen in nested tasks and save ordering is fragile

File:
- `iOS app/Portio/ViewModels/CalorieTrackerViewModel.swift`

Problem:
- After nutrition data arrives, the code starts nested `Task` blocks to write HealthKit samples.
- It assigns `healthKitSampleUUIDs` inside those nested tasks, but the surrounding `context.save()` can already have happened.
- UUID assignment may not be persisted, causing later delete to miss HealthKit samples.

Expected fix:
- Await HealthKit writes in a controlled async path before final save, or save again after UUID assignment on the main actor.
- Handle HealthKit write errors explicitly if sync is enabled.
- Verify delete removes HealthKit records after app restart.

## Medium

### 5. Keychain helper ignores status codes and lacks accessibility policy

File:
- `iOS app/Portio/Utils/KeychainHelper.swift`

Problem:
- `save()` deletes existing item and calls `SecItemAdd`, but ignores the returned status.
- `read()` ignores `SecItemCopyMatching` status and returns nil for all failures.
- No `kSecAttrAccessible` is set.
- No access group is set. That is fine if only the app needs keys, but should be a deliberate decision because the app also uses App Groups for shared data/widgets.

Expected fix:
- Return/throw Keychain errors from save/read/delete.
- Set an explicit accessibility class, for example `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or another product-appropriate policy.
- Decide whether widgets/background extensions need access. If not, keep keys app-only and document it.

### 6. `APIKeyManager` fallback still reads bundled plist placeholders

Files:
- `iOS app/Portio/Utils/APIKeyManager.swift`
- `iOS app/Portio/Gemini-Info.plist`
- `iOS app/Portio/ViewModels/CalorieTrackerViewModel.swift`
- `iOS app/Portio/Views/OnboardingView.swift`
- `iOS app/Portio/Utils/BackgroundTaskManager.swift`

Problem:
- Runtime settings use Keychain for keys, but there is still a fallback to bundled `Gemini-Info.plist`.
- Current plist appears to contain placeholders, but this pattern is risky because real keys could accidentally be bundled later.
- Error text still tells users to check `Gemini-Info.plist`, which is not a user-facing runtime setting.

Expected fix:
- Remove plist fallback for production, or make it debug-only.
- Update error messages to point users to Settings/onboarding.
- Ensure real keys are never included in app bundle.

### 7. `@AppStorage` and `UserSettings.shared` are mixed inconsistently

Files:
- `iOS app/Portio/ContentView.swift`
- `iOS app/Portio/Views/SettingsView.swift`
- `iOS app/Portio/Utils/UserSettings.swift`

Problem:
- `UserSettings.shared` is an App Group `UserDefaults`.
- `SettingsView` uses `@AppStorage(..., store: UserSettings.shared)`.
- `ContentView` uses several `@AppStorage` properties without explicitly passing `store`, relying on `.defaultAppStorage(UserSettings.shared)` from `PortioApp`.
- This works only if the view hierarchy keeps the default storage environment intact.

Expected fix:
- Prefer explicit `store: UserSettings.shared` for all shared settings, or centralize settings in an observable model.
- Verify widgets and app read the same values after changes.

### 8. Background task always reschedules itself at start

File:
- `iOS app/Portio/Utils/BackgroundTaskManager.swift`

Problem:
- `handleProcessingTask()` immediately calls `scheduleIfNeeded()` before checking whether pending work remains.
- `processAllPendingItems()` returns early when no pending items exist, but the task was already rescheduled.
- This can create unnecessary BGTask submissions and scheduler noise.

Expected fix:
- Reschedule only if pending items remain or when new pending work is inserted.
- Track pending count after processing.

### 9. Error handling often deletes user-visible placeholders

Files:
- `iOS app/Portio/ViewModels/CalorieTrackerViewModel.swift`
- `iOS app/Portio/Utils/BackgroundTaskManager.swift`

Problem:
- On foreground failure, `addItem()` deletes the placeholder and sets `errorMessage`.
- On background failure, the manager prints and deletes the item.
- This loses the original user query/photo context and makes retry impossible.

Expected fix:
- Replace silent deletion with a terminal failed state.
- Preserve original query/images long enough for retry.
- Add UI affordance to retry/delete failed items.

### 10. Manual parsing of tool calls from message content is brittle

File:
- `iOS app/Portio/Services/NutritionService.swift`

Problem:
- The service tries to recover tool calls when a model returns JSON-like tool instructions inside `content`.
- It extracts the substring between the first `{` and last `}` and tries to parse it as one object.
- This can fail or misparse if the model returns markdown, multiple objects, nested explanatory JSON, or a normal final JSON containing `name` and `parameters`.

Expected fix:
- Prefer providers/models with native tool-call support.
- If fallback parsing is kept, parse a strict expected schema and reject ambiguous content.
- Add fixtures/tests for:
  - Native `tool_calls`.
  - Manual single tool call.
  - Final nutrition JSON that should not be treated as a tool call.
  - Malformed content.

## Low / Cleanup

### 11. Debug/development project clutter

Observed:
- Multiple Xcode projects at repo root: `Portio.xcodeproj`, `CalCal 2.xcodeproj`, and `iOS app/Portio.xcodeproj`.
- User-specific Xcode data is present under `xcuserdata`.

Expected fix:
- Confirm canonical project is `iOS app/Portio.xcodeproj`.
- Remove or archive obsolete projects if not needed.
- Avoid committing user-specific debugger/breakpoint files unless intentional.

### 12. Minor UI debug prints

Files/examples:
- `iOS app/Portio/Views/Components/NutrientWarningCard.swift`
- `iOS app/Portio/Utils/CameraManager.swift`
- `iOS app/Portio/Views/Statistics/TrendsView.swift`

Problem:
- Several `print(...)` calls remain for taps/errors.
- Mostly harmless, but noisy and can leak user context depending on future changes.

Expected fix:
- Remove or replace with structured debug-only logging.

## Suggested Fix Order

1. Remove/redact sensitive LLM/network logging.
2. Fix background task force-cast.
3. Prevent foreground/background duplicate processing.
4. Make HealthKit write/delete persistence reliable.
5. Improve failure state/retry instead of deleting placeholders.
6. Clean up Keychain/API-key fallback behavior.
7. Add tool-call parsing fixtures/tests.
8. Clean project clutter after confirming canonical Xcode project.
