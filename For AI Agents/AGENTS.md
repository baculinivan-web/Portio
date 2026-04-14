# AGENTS.md — Portio

Portio is a cross-platform AI-powered nutrition tracker. The repository contains two independent apps:
- `iOS app/` — original iOS app (SwiftUI + SwiftData)
- `Android app/` — Android port (Jetpack Compose + Room + Hilt)

Specs and tasks for the Android port: `.kiro/specs/android-port/`

---

## Repository Structure

```
/
├── iOS app/Portio/
│   ├── PortioApp.swift              # app entry point, SwiftData container
│   ├── ContentView.swift            # main screen (TrackerScreen)
│   ├── Models/                      # SearchModels, StatisticsModels
│   ├── ViewModels/                  # CalorieTrackerViewModel etc.
│   ├── Views/                       # SwiftUI screens and components
│   ├── Services/                    # NutritionService, SerperService, OpenFoodFactsService
│   └── Utils/                       # BackgroundTaskManager, HealthKitManager, StreakManager etc.
│
├── Android app/app/src/main/java/com/example/portio/
│   ├── MainActivity.kt              # app entry point, Navigation Compose
│   ├── data/
│   │   ├── local/                   # Room: AppDatabase, FoodItemDao, FoodItemEntity
│   │   ├── remote/                  # NutritionService, OpenFoodFactsService, SerperService
│   │   ├── repository/              # FoodRepository — single data access point
│   │   └── preferences/             # UserSettings (DataStore)
│   ├── domain/
│   │   ├── model/                   # FoodItem, NutritionResponse (domain models)
│   │   └── util/                    # CalorieCalculator, StreakManager, NutrientWarningManager
│   ├── ui/                          # Compose screens: tracker, onboarding, settings, statistics, streak, camera, detail
│   ├── health/                      # HealthConnectManager
│   ├── widget/                      # Glance App Widget
│   ├── worker/                      # NutritionWorker (WorkManager)
│   └── di/                          # Hilt modules: DatabaseModule, NetworkModule
│
└── .kiro/specs/android-port/
    ├── requirements.md
    ├── design.md
    └── tasks.md
```

---

## Build & Run

### iOS
Open `iOS app/Portio.xcodeproj` in Xcode 15+. Requires iOS 17+.

### Android
```bash
# from "Android app/" directory
./gradlew assembleDebug
./gradlew installDebug
```

### Tests
```bash
# Android unit tests
cd "Android app"
./gradlew test

# Android instrumented tests (requires emulator/device)
./gradlew connectedAndroidTest
```

---

## API Keys

API keys (OpenRouter, Serper, model name) are entered by the user at runtime via the Settings screen — there are no hardcoded keys, no `local.properties`, no plist secrets.

On Android, keys are persisted in `UserSettings` (DataStore). On iOS, they are stored in `UserDefaults` via `@AppStorage`. At runtime, `NutritionService` reads the key from `UserSettings`; if blank, it falls back to `BuildConfig` constants (which are empty strings in production builds).

**Never hardcode API keys. Never log their values. Never commit them.**

---

## Architecture & Key Patterns

### Placeholder Pattern (critical)
Both apps use the same food-adding flow:
1. Insert `FoodItem` with `isProcessing = true` immediately → UI shows a skeleton row
2. Enqueue a background task (BGTaskScheduler on iOS, WorkManager on Android)
3. `NutritionService.fetchNutrition()` calls OpenRouter with tool-calling
4. Update the record with AI data (`isProcessing = false`)
5. Sync to HealthKit / Health Connect if enabled
6. Refresh the widget

**Never break this pattern** — the list must not jump; the placeholder must update in place.

### Tool-Calling in NutritionService
The AI uses two tools in parallel (single turn):
- `openfoodfacts_search` — for branded/packaged products (priority)
- `google_search` — for restaurant items and generic queries (via Serper API)

Rules:
- Branded products are **always** searched via tools, even if the AI thinks it knows the answer
- Brand names in any language are searched as-is (e.g. "актимуно" ≠ "Actimel")
- All tool calls must be emitted in one turn (parallel), not sequentially
- `isSearchGrounded = true` when at least one tool was used

### iOS → Android Mapping
| iOS | Android |
|-----|---------|
| SwiftData | Room |
| UserDefaults / AppStorage | DataStore Preferences |
| HealthKit | Health Connect |
| WidgetKit | Glance App Widgets |
| SwiftUI | Jetpack Compose |
| Combine / @Published | StateFlow / Flow |
| BGTaskScheduler | WorkManager |
| Manual DI / singletons | Hilt |
| Swift Charts | Vico |
| AVFoundation (Camera) | CameraX |

---

## Code Conventions

### General
- Business logic must be identical across both platforms (CalorieCalculator, StreakManager, NutrientWarningManager)
- If you change an algorithm on one platform, verify the other
- API keys are never committed to git

### iOS (Swift)
- SwiftUI + SwiftData; minimize UIKit usage
- `@MainActor` for all ViewModel operations that touch UI
- List animations via `.spring()`
- HealthKit operations inside `Task { }` blocks

### Android (Kotlin)
- MVVM + Repository; Hilt for DI
- `StateFlow` for UI state in ViewModels
- `suspend fun` + coroutines for all async work
- WorkManager for background tasks — not coroutine scopes tied to Activity/Fragment
- Room Entity is separate from the domain model — map via `toDomain()` / `toEntity()`
- Declare dependencies in `di/` Hilt modules — never instantiate them manually

### Streak Logic (both platforms)
- Streak is alive if there are entries **today OR yesterday**
- Count backwards from today/yesterday until the first gap
- Use `countForDay(start, end)` from the DAO — do not load all records

---

## Data Models

### FoodItem (domain model, both platforms)
```
id, name, identifiedFood, cleanFoodName
calories, protein, carbs, fat          ← for the portion
caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g
weightGrams, dateEaten
isProcessing, isSearchGrounded, dataSource
healthConnectIds / healthKitSampleUUIDs
searchSteps                            ← captured search results for transparency
```

### UserSettings (user goals & credentials)
```
calorieGoal, proteinGoal, carbsGoal, fatGoal
hasCompletedOnboarding
isHealthSyncEnabled
modelName, openRouterApiKey, serperApiKey, customApiBaseUrl   ← entered by user in Settings
weightGoalMode, weight, height, age, gender, activityLevel
```

---

## Change Log Convention

For every new feature or bug fix, create a plain-text note in the `For AI Agents/` folder at the repo root.

File naming: `YYYY-MM-DD <short task name>.txt`

The note should briefly describe:
- What was added or fixed
- Why it was done
- Any non-obvious decisions or side effects

This gives agents a lightweight history of the project so they can understand the context behind existing code without having to reverse-engineer git history.

Example: `For AI Agents/2026-04-14 Add AGENTS.md.txt`

---

## Do Not Touch Without a Good Reason

- `NutritionService` system prompts — carefully calibrated; changes can break AI accuracy
- `StreakManager` "today OR yesterday" logic — intentional, do not "fix" it
- Room schema (`FoodItemEntity`) — migrations are required for any field changes
- WorkManager retry logic in `NutritionWorker` — 3 attempts with backoff, do not remove

---

## Known Limitations

- Health Connect is commented out in `build.gradle.kts` (requires AGP 8.9.1+) — do not uncomment without upgrading AGP
- `searchSteps` on Android is stored as a JSON string in Room and deserialized in the domain model
- The widget reads data directly from the shared Room database, not via ContentProvider
