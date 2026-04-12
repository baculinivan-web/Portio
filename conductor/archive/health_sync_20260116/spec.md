# Specification: Apple HealthKit Integration

## Overview
Integrate Apple HealthKit to allow CalCal to sync nutritional data. When a user logs food items, the corresponding dietary energy, protein, carbohydrates, and fat will be written to the Apple Health app in real-time.

## Functional Requirements

### 1. HealthKit Authorization
- **Permissions:** Request "Write" access for:
    - Dietary Energy
    - Dietary Protein
    - Dietary Carbohydrates
    - Dietary Total Fat
- **UI Interaction:**
    - **Onboarding:** Add a dedicated screen/step to explain the benefits and request permission.
    - **Settings:** Add an "Apple Health Sync" toggle to enable/disable integration at any time.

### 2. Real-Time Data Sync (Write Only)
- **Granularity:** Each `FoodItem` logged in CalCal will be written as an individual sample in HealthKit.
- **Timestamping:** Use the `dateEaten` property of the `FoodItem` for the HealthKit sample timestamp.
- **Updates & Deletions:**
    - If a `FoodItem` is edited in CalCal, update the corresponding sample in HealthKit.
    - If a `FoodItem` is deleted in CalCal, remove the corresponding sample from HealthKit.

### 3. Historical Data Sync
- **One-time Sync:** When the user first enables Apple Health Sync, perform a one-time migration of all existing `FoodItem` records in SwiftData to HealthKit.
- **Safety:** Ensure duplicate samples are not created in HealthKit if the sync is interrupted and restarted.

### 4. Metadata
- Include metadata with HealthKit samples (e.g., "Food Name") to provide context within the Health app.

## Non-Functional Requirements
- **Error Handling:** Gracefully handle cases where HealthKit is unavailable (e.g., iPad or restricted access) or if the user denies permissions.
- **Privacy:** Adhere strictly to Apple's HealthKit privacy guidelines.

## Acceptance Criteria
- User is prompted for HealthKit permissions during onboarding or via Settings.
- Adding a food item in CalCal (e.g., "Chicken Salad, 400 kcal") creates corresponding samples in the Apple Health app.
- Deleting an item in CalCal removes it from the Apple Health app.
- Settings toggle correctly enables/disables the sync logic.
- Enabling sync for the first time successfully migrates all historical food logs to the Health app.

## Out of Scope
- Reading data from HealthKit (e.g., step counts or active energy).
- Syncing micronutrients (Vitamins, Minerals) or Water.
