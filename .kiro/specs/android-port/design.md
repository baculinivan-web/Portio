# Design Document — CalCal Android

## Overview

CalCal Android — прямой порт iOS-приложения на Android. Архитектура следует MVVM + Repository pattern с Jetpack Compose UI. Все iOS-специфичные фреймворки заменяются Android-эквивалентами с сохранением бизнес-логики.

## iOS → Android Mapping

| iOS | Android |
|-----|---------|
| SwiftData | Room |
| UserDefaults / AppGroup | DataStore Preferences + SharedPreferences |
| HealthKit | Health Connect |
| WidgetKit | Glance App Widgets |
| SwiftUI | Jetpack Compose |
| Combine / @Published | StateFlow / Flow |
| App Groups (widget data sharing) | ContentProvider или shared Room DB |

---

## Architecture

```
app/
├── data/
│   ├── local/
│   │   ├── FoodItemDao.kt          # Room DAO
│   │   ├── FoodItemEntity.kt       # Room Entity
│   │   └── AppDatabase.kt          # Room Database
│   ├── remote/
│   │   ├── NutritionService.kt     # OpenRouter/Gemini API
│   │   ├── OpenFoodFactsService.kt # OFF API
│   │   └── SerperService.kt        # Google Search API
│   ├── repository/
│   │   └── FoodRepository.kt       # единая точка доступа к данным
│   └── preferences/
│       └── UserSettings.kt         # DataStore Preferences
├── domain/
│   ├── model/
│   │   ├── FoodItem.kt             # доменная модель
│   │   └── NutritionResponse.kt    # ответ AI
│   └── util/
│       ├── CalorieCalculator.kt    # Mifflin-St Jeor TDEE
│       ├── StreakManager.kt        # подсчёт стриков
│       └── NutrientWarningManager.kt
├── ui/
│   ├── tracker/
│   │   ├── TrackerScreen.kt        # главный экран (аналог ContentView)
│   │   └── TrackerViewModel.kt     # аналог CalorieTrackerViewModel
│   ├── onboarding/
│   │   └── OnboardingScreen.kt
│   ├── statistics/
│   │   └── StatisticsScreen.kt
│   ├── settings/
│   │   └── SettingsScreen.kt
│   ├── camera/
│   │   └── CameraScreen.kt         # CameraX
│   └── components/                 # переиспользуемые Composable
├── health/
│   └── HealthConnectManager.kt     # аналог HealthKitManager
├── widget/
│   └── CalCalWidget.kt             # Glance App Widget
└── MainActivity.kt
```

---

## Data Layer

### Room — FoodItemEntity

```kotlin
@Entity(tableName = "food_items")
data class FoodItemEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val identifiedFood: String = "",
    val cleanFoodName: String = "",
    val calories: Double = 0.0,
    val protein: Double = 0.0,
    val carbs: Double = 0.0,
    val fat: Double = 0.0,
    val weightGrams: Double = 0.0,
    val caloriesPer100g: Double = 0.0,
    val proteinPer100g: Double = 0.0,
    val carbsPer100g: Double = 0.0,
    val fatPer100g: Double = 0.0,
    val dateEaten: Long = System.currentTimeMillis(), // epoch ms
    val isProcessing: Boolean = false,
    val isSearchGrounded: Boolean = false,
    val dataSource: String? = null,
    val healthConnectIds: String = "" // JSON array of UUIDs
)
```

### FoodItemDao

```kotlin
@Dao
interface FoodItemDao {
    @Query("SELECT * FROM food_items WHERE dateEaten >= :start AND dateEaten < :end ORDER BY dateEaten DESC")
    fun getItemsForDay(start: Long, end: Long): Flow<List<FoodItemEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: FoodItemEntity)

    @Update
    suspend fun update(item: FoodItemEntity)

    @Delete
    suspend fun delete(item: FoodItemEntity)

    @Query("SELECT COUNT(*) FROM food_items WHERE dateEaten >= :start AND dateEaten < :end")
    suspend fun countForDay(start: Long, end: Long): Int
}
```

### UserSettings (DataStore)

Аналог iOS `UserSettings` через Jetpack DataStore Preferences:

```kotlin
object UserSettingsKeys {
    val CALORIE_GOAL = doublePreferencesKey("calorieGoal")
    val PROTEIN_GOAL = doublePreferencesKey("proteinGoal")
    val CARBS_GOAL = doublePreferencesKey("carbsGoal")
    val FAT_GOAL = doublePreferencesKey("fatGoal")
    val HAS_COMPLETED_ONBOARDING = booleanPreferencesKey("hasCompletedOnboarding")
    val HEALTH_CONNECT_ENABLED = booleanPreferencesKey("healthConnectEnabled")
    val WEIGHT_GOAL_MODE = stringPreferencesKey("weightGoalMode")
}
```

---

## Network Layer

### NutritionService

Прямой порт iOS `NutritionService`. Логика tool-calling (OpenRouter → google_search / openfoodfacts_search) сохраняется полностью.

- HTTP-клиент: **OkHttp + Retrofit** (или `ktor-client`)
- JSON: **kotlinx.serialization** или **Gson**
- Параллельные tool calls: `async/await` через Kotlin coroutines (`async { }` + `awaitAll()`)

```kotlin
class NutritionService(private val apiKey: String, private val modelName: String) {
    suspend fun fetchNutrition(query: String, images: List<ByteArray> = emptyList()): List<NutritionResponse>
    suspend fun fetchAIGoals(userStats: String, userGoals: String, baselineTdee: Double): GoalResponse
}
```

### OpenFoodFactsService / SerperService

Прямой порт — те же endpoints, те же модели данных.

---

## ViewModel Layer

### TrackerViewModel

```kotlin
@HiltViewModel
class TrackerViewModel @Inject constructor(
    private val foodRepository: FoodRepository,
    private val userSettings: UserSettings
) : ViewModel() {

    val todayItems: StateFlow<List<FoodItem>>  // аналог @Query в SwiftData
    val errorMessage: StateFlow<String?>

    fun addItem(query: String, images: List<ByteArray> = emptyList())
    fun deleteItem(item: FoodItem)
    fun updateItem(item: FoodItem)
}
```

Паттерн тот же что в iOS: вставляем placeholder → запускаем coroutine → обновляем запись по завершении.

---

## Health Connect

Аналог `HealthKitManager`:

```kotlin
class HealthConnectManager(private val context: Context) {
    suspend fun requestPermissions(): Boolean
    suspend fun writeNutrition(item: FoodItem): List<String> // возвращает record IDs
    suspend fun deleteNutrition(ids: List<String>)
}
```

Типы записей Health Connect:
- `NutritionRecord` — содержит energy, protein, carbohydrates, totalFat

---

## Streak Logic

`StreakManager` — прямой порт iOS-логики:
- Считаем назад от сегодня
- Стрик жив если есть записи сегодня ИЛИ вчера
- Используем Room DAO `countForDay()`

---

## Widget (Glance)

```kotlin
class CalCalWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // читает данные из Room напрямую или через ContentProvider
        // отображает: калории за день, прогресс макросов
    }
}
```

Данные виджету передаются через общую Room БД (аналог App Group в iOS).

---

## Navigation

Используем **Navigation Compose** с bottom navigation bar:

```
TrackerScreen (home)
StatisticsScreen
StreakScreen
SettingsScreen
```

Модальные экраны: `OnboardingScreen`, `CameraScreen`, `FoodItemDetailScreen`

---

## API Keys

Аналог `Gemini-Info.plist` → `local.properties` (не коммитится в git) + `BuildConfig`:

```
# local.properties
OPENROUTER_API_KEY=...
SERPER_API_KEY=...
MODEL_NAME=...
```

```kotlin
// build.gradle.kts
buildConfigField("String", "OPENROUTER_API_KEY", "\"${localProperties["OPENROUTER_API_KEY"]}\"")
```

---

## Dependencies (build.gradle.kts)

```kotlin
// UI
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.material3:material3")
implementation("androidx.navigation:navigation-compose:2.7.x")

// Architecture
implementation("androidx.lifecycle:lifecycle-viewmodel-compose")
implementation("com.google.dagger:hilt-android:2.x")

// Data
implementation("androidx.room:room-runtime:2.6.x")
implementation("androidx.room:room-ktx:2.6.x")
implementation("androidx.datastore:datastore-preferences:1.0.x")

// Network
implementation("com.squareup.retrofit2:retrofit:2.x")
implementation("com.squareup.okhttp3:okhttp:4.x")
implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.x")

// Camera
implementation("androidx.camera:camera-camera2:1.x")
implementation("androidx.camera:camera-lifecycle:1.x")
implementation("androidx.camera:camera-view:1.x")

// Health Connect
implementation("androidx.health.connect:connect-client:1.x")

// Widget
implementation("androidx.glance:glance-appwidget:1.x")

// Charts (аналог Swift Charts)
implementation("com.patrykandpatrick.vico:compose-m3:x.x")
```

---

## Correctness Properties

1. `addItem` вставляет placeholder немедленно, обновляет его после ответа AI — список никогда не "прыгает"
2. Удаление FoodItem из Room также удаляет соответствующие записи из Health Connect
3. Стрик не обнуляется если пользователь открыл приложение до полуночи и залогировал еду
4. Данные виджета всегда соответствуют данным основного приложения (одна БД)
5. API-ключи никогда не попадают в git (только через `local.properties` / `BuildConfig`)
