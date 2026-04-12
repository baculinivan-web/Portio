# Plan: Apple HealthKit Integration

## Phase 1: Foundation & Authorization [x] Checkpoint: 143d4e8
- [x] Task: Add the HealthKit capability to the CalCal target in the Xcode project. 6d85d8f
- [x] Task: Add `NSHealthUpdateUsageDescription` and `NSHealthShareUsageDescription` to `Info.plist`. 7fb6422
- [x] Task: Create a `HealthKitManager` utility to handle authorization and data type definitions. 7b4084c
- [x] Task: Implement the request-authorization logic for dietary energy and macronutrients. 7b4084c
- [x] Task: Conductor - User Manual Verification 'Phase 1: Foundation & Authorization' (Protocol in workflow.md)

## Phase 2: Authorization UI [x] Checkpoint: c8e9a7e
- [x] Task: Update `OnboardingView` to include a dedicated screen/step for HealthKit permission. c8e9a7e
- [x] Task: Add an "Apple Health Sync" toggle to `SettingsView` and persist the state in `UserSettings`. c8e9a7e
- [x] Task: Conductor - User Manual Verification 'Phase 2: Authorization UI' (Protocol in workflow.md) c8e9a7e

## Phase 3: Data Sync Logic (Writing Samples) [x] Checkpoint: ab5bb75
- [x] Task: Implement logic in `HealthKitManager` to convert a `FoodItem` into HealthKit quantity samples. ab5bb75
- [x] Task: Add a persistent reference (UUID/Metadata) to `FoodItem` to track its corresponding samples in HealthKit. ab5bb75
- [x] Task: Implement the "Write" function to send data to HealthKit. ab5bb75
- [x] Task: Implement the "Delete" function to remove samples from HealthKit. ab5bb75
- [x] Task: Conductor - User Manual Verification 'Phase 3: Data Sync Logic (Writing Samples)' (Protocol in workflow.md) ab5bb75

## Phase 4: Integration & Real-time Sync [x] Checkpoint: c3fc5a5
- [x] Task: Integrate `HealthKitManager` into `CalorieTrackerViewModel` to trigger sync on new additions. c3fc5a5
- [x] Task: Update the deletion logic in `ContentView` to ensure HealthKit samples are removed. c3fc5a5
- [x] Task: Handle "Edit" scenarios in `FoodItemDetailView` to update existing HealthKit samples. c3fc5a5
- [x] Task: Conductor - User Manual Verification 'Phase 4: Integration & Real-time Sync' (Protocol in workflow.md) c3fc5a5

## Phase 5: Historical Data Sync [x] Checkpoint: acee3c0
- [x] Task: Implement a migration utility in `HealthKitManager` to fetch all existing `FoodItem` records and write them to HealthKit. acee3c0
- [x] Task: Trigger the historical sync when the user first enables the "Apple Health Sync" toggle in Settings or completes onboarding. acee3c0
- [x] Task: Add logic to mark items as "synced" to prevent double-logging. acee3c0
- [x] Task: Conductor - User Manual Verification 'Phase 5: Historical Data Sync' (Protocol in workflow.md) acee3c0
