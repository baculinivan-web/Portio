# Implementation Tasks — CalCal Android

## Tasks

- [x] 1. Настройка Android-проекта
  - [x] 1.1 Создать Android-проект в корне репозитория (Empty Activity, Kotlin, minSdk 26)
  - [x] 1.2 Настроить `build.gradle.kts`: добавить все зависимости из design.md
  - [x] 1.3 Настроить `local.properties` + `BuildConfig` для API-ключей (OPENROUTER_API_KEY, SERPER_API_KEY, MODEL_NAME)
  - [x] 1.4 Добавить `local.properties` в `.gitignore`
  - [x] 1.5 Настроить Hilt (Application класс + `@HiltAndroidApp`)

- [x] 2. Data Layer — Room
  - [x] 2.1 Создать `FoodItemEntity.kt` по схеме из design.md
  - [x] 2.2 Создать `FoodItemDao.kt` с методами `getItemsForDay`, `insert`, `update`, `delete`, `countForDay`
  - [x] 2.3 Создать `AppDatabase.kt` (Room singleton)
  - [x] 2.4 Создать доменную модель `FoodItem.kt` и mapper `FoodItemEntity ↔ FoodItem`

- [x] 3. Настройки пользователя — DataStore
  - [x] 3.1 Создать `UserSettings.kt` с ключами из design.md (calorieGoal, proteinGoal, carbsGoal, fatGoal, hasCompletedOnboarding, healthConnectEnabled, weightGoalMode)
  - [x] 3.2 Реализовать методы чтения/записи через DataStore Preferences

- [x] 4. Network Layer
  - [x] 4.1 Создать `NutritionService.kt` — порт iOS NutritionService с tool-calling логикой (OpenRouter API, параллельные tool calls через `async/awaitAll`)
  - [x] 4.2 Создать `OpenFoodFactsService.kt` — порт iOS OpenFoodFactsService
  - [x] 4.3 Создать `SerperService.kt` — порт iOS SerperService
  - [x] 4.4 Создать модели ответов: `NutritionResponse.kt`, `GoalResponse.kt`, `OFFProduct.kt`, `SearchStep.kt`

- [x] 5. Repository
  - [x] 5.1 Создать `FoodRepository.kt` — объединяет Room DAO и NutritionService
  - [x] 5.2 Реализовать `addItem`: вставка placeholder → coroutine → обновление записи

- [x] 6. Domain Utils
  - [x] 6.1 Создать `CalorieCalculator.kt` — порт Mifflin-St Jeor TDEE (Gender, ActivityLevel enums)
  - [x] 6.2 Создать `StreakManager.kt` — порт iOS логики (считаем назад, стрик жив если есть записи сегодня или вчера)
  - [x] 6.3 Создать `NutrientWarningManager.kt` — порт iOS логики предупреждений о нутриентах

- [x] 7. UI — Navigation и основной скаффолд
  - [x] 7.1 Создать `MainActivity.kt` с Hilt + Navigation Compose
  - [x] 7.2 Настроить bottom navigation bar (Tracker, Statistics, Streak, Settings)
  - [x] 7.3 Создать пустые экраны-заглушки для всех разделов

- [x] 8. UI — Onboarding
  - [x] 8.1 Создать `OnboardingScreen.kt` — ввод профиля (пол, возраст, вес, рост, уровень активности, цель)
  - [x] 8.2 Подключить `CalorieCalculator` для расчёта TDEE
  - [x] 8.3 Подключить `NutritionService.fetchAIGoals` для AI-расчёта целей
  - [x] 8.4 Сохранять результаты в `UserSettings`

- [x] 9. UI — Tracker (главный экран)
  - [x] 9.1 Создать `TrackerViewModel.kt` — StateFlow для списка еды за день и errorMessage
  - [x] 9.2 Создать `TrackerScreen.kt` — список FoodItem за сегодня, кнопка добавления
  - [x] 9.3 Реализовать `ChatInputView` (текстовый ввод + кнопка камеры)
  - [x] 9.4 Реализовать `FoodItemRowView` — строка с нутриентами, свайп для удаления
  - [x] 9.5 Реализовать `TotalsCardView` — суммарные калории и макросы за день
  - [x] 9.6 Реализовать `GoalSummaryView` — прогресс к дневной цели

- [x] 10. UI — Camera
  - [x] 10.1 Создать `CameraScreen.kt` с CameraX preview
  - [x] 10.2 Реализовать захват фото и передачу `ByteArray` в `TrackerViewModel.addItem`
  - [x] 10.3 Реализовать `PhotoPreviewView` — предпросмотр перед отправкой

- [x] 11. UI — Food Item Detail
  - [x] 11.1 Создать `FoodItemDetailScreen.kt` — детальный просмотр нутриентов
  - [x] 11.2 Реализовать `NutritionFactsTable` — таблица нутриентов (аналог iOS)
  - [x] 11.3 Реализовать редактирование веса порции с пересчётом нутриентов

- [x] 12. UI — Statistics
  - [x] 12.1 Создать `StatisticsScreen.kt` с вкладками Today / Trends
  - [x] 12.2 Реализовать `TodayView` — макросы за сегодня с круговой диаграммой (Vico)
  - [x] 12.3 Реализовать `TrendsView` — график калорий за 7/30 дней (Vico)
  - [x] 12.4 Реализовать `MacroDistributionChart` и `CalorieTrendChart`

- [x] 13. UI — Streak
  - [x] 13.1 Создать `StreakHistoryScreen.kt` — история стриков
  - [x] 13.2 Реализовать `ContributionGridView` — сетка активности (аналог GitHub contributions)
  - [x] 13.3 Реализовать `StreakNotificationPill` — уведомление о текущем стрике

- [x] 14. UI — Settings
  - [x] 14.1 Создать `SettingsScreen.kt` — редактирование целей, Health Connect toggle, информация о приложении
  - [x] 14.2 Подключить `UserSettings` для чтения/записи

- [x] 15. Health Connect
  - [x] 15.1 Создать `HealthConnectManager.kt` — порт HealthKitManager
  - [x] 15.2 Реализовать `requestPermissions`, `writeNutrition`, `deleteNutrition`
  - [x] 15.3 Подключить к `FoodRepository`: запись при добавлении, удаление при удалении FoodItem
  - [x] 15.4 Добавить разрешения в `AndroidManifest.xml`

- [x] 16. Widget (Glance)
  - [x] 16.1 Создать `CalCalWidget.kt` — Glance App Widget
  - [x] 16.2 Реализовать отображение калорий за день и прогресса макросов
  - [x] 16.3 Настроить обновление виджета при изменении данных (аналог `WidgetCenter.shared.reloadAllTimelines()`)
  - [x] 16.4 Добавить `AppWidgetProvider` в `AndroidManifest.xml`

- [x] 17. Тесты
  - [x] 17.1 Unit-тесты для `CalorieCalculator` (TDEE расчёт)
  - [x] 17.2 Unit-тесты для `StreakManager` (граничные случаи: сегодня/вчера/пропуск дня)
  - [x] 17.3 Unit-тесты для `FoodRepository.addItem` (placeholder → update паттерн)
  - [x] 17.4 Unit-тесты для `NutrientWarningManager`
