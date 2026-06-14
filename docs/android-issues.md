# Android Issues Handoff

Context: Android app is a Kotlin/Jetpack Compose port of the iOS calorie tracker. It is supposed to support text/photo food logging, OpenRouter-compatible LLM calls, tool use with OpenFoodFacts and Serper, Room persistence, WorkManager background processing, Glance widget, and Health Connect sync.

Do not assume the current Android app builds. Start by running:

```bash
cd "Android app"
./gradlew test
./gradlew assembleDebug
```

The previous review attempted `./gradlew test`, but the Gradle wrapper process hung before useful output. Treat the build as unverified.

## Critical

### 1. Stale `com.example.calcal` package in `src/main` likely breaks compilation

Files:
- `Android app/app/src/main/java/com/example/calcal/data/repository/FoodRepository.kt`
- `Android app/app/src/main/java/com/example/calcal/data/preferences/UserSettings.kt`
- `Android app/app/src/main/java/com/example/calcal/ui/onboarding/OnboardingScreen.kt`
- `Android app/app/src/main/java/com/example/calcal/ui/onboarding/OnboardingViewModel.kt`
- `Android app/app/src/main/java/com/example/calcal/ui/settings/SettingsScreen.kt`

Problem:
- The app namespace/applicationId is `com.example.portio`, but stale `com.example.calcal` sources remain under `src/main`.
- These files import symbols such as `com.example.calcal.data.local.FoodItemDao`, `com.example.calcal.data.remote.NutritionService`, `com.example.calcal.domain.model.FoodItem`, `com.example.calcal.health.HealthConnectManager`, and `com.example.calcal.widget.CalCalWidget`.
- Those packages do not appear to exist in the current source tree.
- Gradle compiles all Kotlin files under `src/main`, even if these screens are not referenced from navigation.

Expected fix:
- Either delete/move the stale `com.example.calcal` tree out of `src/main`, or migrate it fully to `com.example.portio`.
- Prefer removing it if it is dead code. The active app uses `com.example.portio`.
- Re-run `./gradlew test` and `./gradlew assembleDebug`.

### 2. `NutritionService.kt` references missing imports

File:
- `Android app/app/src/main/java/com/example/portio/data/remote/NutritionService.kt`

Problem:
- The file references `UserSettings.LLMProvider` in method signatures and logic, but does not import `com.example.portio.data.preferences.UserSettings`.
- It calls `UUID.randomUUID()` when synthesizing manual tool calls, but does not import `java.util.UUID`.

Expected fix:
- Add missing imports or fully qualify the types.
- Verify compile with unit tests/build.

### 3. Network logging leaks sensitive data

File:
- `Android app/app/src/main/java/com/example/portio/di/NetworkModule.kt`

Problem:
- OkHttp is configured with `HttpLoggingInterceptor.Level.BODY`.
- This can log:
  - `Authorization: Bearer ...` headers unless redacted.
  - Food queries and images metadata.
  - LLM prompts and responses.
  - Serper/OpenFoodFacts results.
  - User profile and goal-generation prompts.
  - API error bodies.

Expected fix:
- Remove BODY logging in production builds.
- If debug logging is kept, use BuildConfig-gated configuration and redact `Authorization` and `X-API-KEY`.
- Prefer `BASIC` or no logging by default.

### 4. Backup and cleartext settings are unsafe for health/nutrition/API-key app

Files:
- `Android app/app/src/main/AndroidManifest.xml`
- `Android app/app/src/main/res/xml/backup_rules.xml`
- `Android app/app/src/main/res/xml/data_extraction_rules.xml`

Problem:
- Manifest has `android:allowBackup="true"`.
- Backup rules are effectively sample/empty.
- The app stores profile data, nutrition history, model/provider settings, and sensitive keys.
- Manifest also has `android:usesCleartextTraffic="true"`, which permits HTTP traffic globally.

Expected fix:
- Set `usesCleartextTraffic=false` unless there is a documented local-dev requirement and a network security config that limits it.
- Either disable backup or explicitly exclude sensitive SharedPreferences/DataStore/Room/EncryptedSharedPreferences files.
- Verify Auto Backup and device-transfer rules for API 31+.

## High

### 5. Android photo logging is non-functional

Files:
- `Android app/app/src/main/java/com/example/portio/MainActivity.kt`
- `Android app/app/src/main/java/com/example/portio/ui/camera/CameraScreen.kt`
- `Android app/app/src/main/java/com/example/portio/ui/tracker/TrackerViewModel.kt`
- `Android app/app/src/main/java/com/example/portio/data/repository/FoodRepository.kt`
- `Android app/app/src/main/java/com/example/portio/worker/NutritionWorker.kt`

Problem:
- `CameraScreen` can produce a `ByteArray`, but `MainActivity` handles `onPhotoTaken` by only calling `navController.popBackStack()`.
- The photo bytes never reach `TrackerViewModel.addItem`.
- `FoodRepository.addItem(images=...)` accepts images but ignores them because WorkManager input only stores `ITEM_ID` and `QUERY`.
- `NutritionWorker` always calls `fetchNutrition(images = emptyList())`.

Expected fix:
- Decide intended UX:
  - Option A: after taking/picking a photo, attach it to tracker input like iOS.
  - Option B: immediately create a placeholder item from the photo.
- Persist images before enqueueing WorkManager. WorkManager `Data` is not appropriate for large image bytes.
- Store image files in app-private storage and pass file URIs/paths to the worker.
- Delete temporary image files after successful processing or final failure.
- Add a test or manual verification that a photo reaches `NutritionService.fetchNutrition` and becomes a multimodal request.

### 6. Health Connect UI exists but implementation is a no-op

Files:
- `Android app/app/src/main/java/com/example/portio/health/HealthConnectManager.kt`
- `Android app/app/src/main/java/com/example/portio/ui/settings/SettingsScreen.kt`
- `Android app/app/src/main/java/com/example/portio/data/repository/FoodRepository.kt`
- `Android app/app/src/main/java/com/example/portio/worker/NutritionWorker.kt`
- `Android app/app/build.gradle.kts`
- `Android app/gradle/libs.versions.toml`

Problem:
- Settings exposes a `Health Connect` toggle.
- `HealthConnectManager` is a stub: `isAvailable=false`, `hasPermissions=false`, `writeNutrition=null`, delete is no-op.
- Dependency is commented out in Gradle.
- README claims Android Health Connect integration.

Expected fix:
- Either implement Health Connect properly or remove/disable the UI and README claim.
- If implementing, add dependency, permissions, availability check, permission request flow, write/delete logic, and error handling.
- Make the toggle reflect actual availability/permission state.

### 7. Onboarding hides API/AI failures

File:
- `Android app/app/src/main/java/com/example/portio/ui/onboarding/OnboardingViewModel.kt`

Problem:
- `complete()` catches all exceptions, computes fallback TDEE goals, sets `hasCompletedOnboarding=true`, and calls `onDone()`.
- This hides missing/invalid OpenRouter key, missing Serper key, custom provider errors, model errors, and network issues.
- User enters the app believing setup succeeded. Later food logging can fail in the background without a visible error.

Expected fix:
- Separate validation/setup failures from optional AI goal-generation failures.
- If provider/key configuration is required for food logging, surface a blocking error before completing onboarding.
- If AI goals are optional, clearly tell the user fallback goals were used and keep API-key validation explicit.
- Persist Serper/API/model/provider settings before calling AI goals if the goal-generation call depends on them.

### 8. Tool-call result state is mutated from parallel coroutines

File:
- `Android app/app/src/main/java/com/example/portio/data/remote/NutritionService.kt`

Problem:
- Inside parallel `async` tasks, `capturedSearchSteps.add(step)` and `didUseOFF = true` mutate shared outer state.
- This creates race/order nondeterminism and makes results harder to reason about.
- Search steps are then attached to all grounded foods, not to the specific food/tool call that produced them.

Expected fix:
- Make each async return a structured immutable result.
- Aggregate `capturedSearchSteps` and `didUseOFF` after `awaitAll()`.
- Preserve mapping from tool call/query to result where possible.
- Consider attaching per-food search evidence only when the final response identifies the matching source.

### 9. WorkManager failures are invisible to the UI

Files:
- `Android app/app/src/main/java/com/example/portio/data/repository/FoodRepository.kt`
- `Android app/app/src/main/java/com/example/portio/worker/NutritionWorker.kt`
- `Android app/app/src/main/java/com/example/portio/ui/tracker/TrackerViewModel.kt`

Problem:
- `FoodRepository.addItem()` accepts `onError`, but after moving work to WorkManager it never uses this callback.
- Worker deletes the placeholder after retries and returns `Result.failure()`.
- The foreground UI has no observable error state for worker failures.

Expected fix:
- Persist processing failure state on the item instead of silently deleting, or expose WorkManager status to UI.
- Show an actionable error with retry/delete options.
- Keep the placeholder pattern but make terminal failure visible.

### 10. User can enable BlockRun prompt without API validation

Files:
- `Android app/app/src/main/java/com/example/portio/MainActivity.kt`
- `Android app/app/src/main/java/com/example/portio/data/remote/NutritionService.kt`
- `Android app/app/src/main/java/com/example/portio/data/preferences/UserSettings.kt`

Problem:
- Startup dialog can switch provider/model to BlockRun immediately.
- `NutritionService` uses `x402` when wallet ID is blank.
- There is no validation that the configured endpoint/model/auth works.

Expected fix:
- Add provider validation/test request or a clear settings state.
- Ensure fallback/default endpoint is consistent across `UserSettings`, `SettingsViewModel`, and `NutritionService`.

## Medium

### 11. Startup performs DataStore reads with `runBlocking` on the UI thread

File:
- `Android app/app/src/main/java/com/example/portio/MainActivity.kt`

Problem:
- `runBlocking` reads `hasCompletedOnboarding` and `hasShownBlockRunPrompt` before `setContent`.
- Usually small, but it can block cold start and is not idiomatic Compose/DataStore.

Expected fix:
- Collect settings in Compose state or show a splash/loading state while reading.

### 12. Room schema export is disabled

File:
- `Android app/app/src/main/java/com/example/portio/data/local/AppDatabase.kt`

Problem:
- `exportSchema=false`.
- The app already has a migration from version 1 to 2.
- Without exported schemas, future migrations are harder to validate and review.

Expected fix:
- Enable schema export and configure `room.schemaLocation`.
- Add migration tests if possible.

### 13. `EncryptedSharedPreferences` uses alpha dependency

Files:
- `Android app/gradle/libs.versions.toml`
- `Android app/app/src/main/java/com/example/portio/data/preferences/SecurePrefs.kt`

Problem:
- `androidx.security:security-crypto` is set to `1.1.0-alpha06`.
- The API has had deprecation/churn concerns; verify current recommendation and migration path.

Expected fix:
- Check current AndroidX guidance and pin a stable or recommended replacement.
- Ensure backup excludes encrypted prefs/key material.

### 14. `UserSettings` sensitive flows are one-shot

File:
- `Android app/app/src/main/java/com/example/portio/data/preferences/UserSettings.kt`

Problem:
- `openRouterApiKey`, `serperApiKey`, and `blockRunWalletId` are implemented as `flow { emit(securePrefs.getString(...)) }`.
- They do not observe preference changes by themselves; consumers using `stateIn` may not update after saves unless the flow is recreated/collected again.

Expected fix:
- Expose sensitive settings as observable state, or make ViewModels explicitly refresh after saves.
- Verify Settings UI updates after saving keys.

## Suggested Fix Order

1. Make Android compile: remove stale `com.example.calcal` sources and fix missing imports.
2. Remove sensitive network/body logging and unsafe manifest backup/cleartext settings.
3. Fix photo logging end-to-end.
4. Make worker failures visible.
5. Decide whether Health Connect is real or hidden.
6. Clean up onboarding/provider validation.
7. Stabilize tool-call aggregation and search evidence mapping.
8. Add tests for repository/worker/tool loop where feasible.
