# Requirements Document

## Introduction

CalCal Android — это порт iOS-приложения CalCal на платформу Android. Приложение представляет собой трекер питания и калорий с AI-анализом еды, поиском продуктов, статистикой, стриками и виджетами. Целевая платформа: Android 8.0+ (API 26+), язык разработки — Kotlin, UI-фреймворк — Jetpack Compose. Вместо HealthKit используется Google Health Connect, вместо iOS-виджетов — Glance App Widgets.

## Glossary

- **App**: Android-приложение CalCal
- **Tracker**: Основной экран отслеживания питания за текущий день
- **FoodItem**: Запись о съеденном продукте с нутриентами (калории, белки, углеводы, жиры, вес)
- **NutritionService**: Сервис AI-анализа питания через OpenRouter/Gemini
- **OpenFoodFacts**: Открытая база данных продуктов питания (OFF)
- **SerperService**: Сервис поиска нутриентов через Google Search API
- **StreakManager**: Менеджер подсчёта стриков (серий дней с записями)
- **HealthConnect**: Android Health Connect API — аналог HealthKit для Android
- **Widget**: Виджет главного экрана Android (Glance App Widget)
- **Onboarding**: Экран первоначальной настройки профиля и целей пользователя
- **TDEE**: Total Daily Energy Expenditure — суточная норма калорий
- **BMR**: Basal Metabolic Rate — базальный метаболизм (формула Mifflin-St Jeor)
- **Macro**: Макронутриент (белки, углеводы, жиры)
- **DataStore**: Android Jetpack DataStore — хранилище настроек (аналог UserDefaults)
- **Room**: Android Jetpack Room — локальная база данных (аналог SwiftData)
- **Camera**: Камера устройства для фотографирования еды
