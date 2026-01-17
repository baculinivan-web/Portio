# Plan: Apple HealthKit Integration

## Phase 1: Foundation & Authorization
- [x] Task: Add the HealthKit capability to the CalCal target in the Xcode project. 6d85d8f
- [x] Task: Add `NSHealthUpdateUsageDescription` and `NSHealthShareUsageDescription` to `Info.plist`. 7fb6422
- [x] Task: Create a `HealthKitManager` utility to handle authorization and data type definitions. 7b4084c
- [x] Task: Implement the request-authorization logic for dietary energy and macronutrients. 7b4084c
- [~] Task: Conductor - User Manual Verification 'Phase 1: Foundation & Authorization' (Protocol in workflow.md)

## Phase 2: Authorization UI
- [ ] Task: Update `OnboardingView` to include a dedicated screen/step for HealthKit permission.
- [ ] Task: Add an "Apple Health Sync" toggle to `SettingsView` and persist the state in `UserSettings`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Authorization UI' (Protocol in workflow.md)

## Phase 3: Data Sync Logic (Writing Samples)
- [ ] Task: Implement logic in `HealthKitManager` to convert a `FoodItem` into HealthKit quantity samples.
- [ ] Task: Add a persistent reference (UUID/Metadata) to `FoodItem` to track its corresponding samples in HealthKit.
- [ ] Task: Implement the "Write" function to send data to HealthKit.
- [ ] Task: Implement the "Delete" function to remove samples from HealthKit.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Data Sync Logic (Writing Samples)' (Protocol in workflow.md)

## Phase 4: Integration & Real-time Sync
- [ ] Task: Integrate `HealthKitManager` into `CalorieTrackerViewModel` to trigger sync on new additions.
- [ ] Task: Update the deletion logic in `ContentView` to ensure HealthKit samples are removed.
- [ ] Task: Handle "Edit" scenarios in `FoodItemDetailView` to update existing HealthKit samples.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Integration & Real-time Sync' (Protocol in workflow.md)

## Phase 5: Historical Data Sync
- [ ] Task: Implement a migration utility in `HealthKitManager` to fetch all existing `FoodItem` records and write them to HealthKit.
- [ ] Task: Trigger the historical sync when the user first enables the "Apple Health Sync" toggle in Settings or completes onboarding.
- [ ] Task: Add logic to mark items as "synced" to prevent double-logging.
- [ ] Task: Conductor - User Manual Verification 'Phase 5: Historical Data Sync' (Protocol in workflow.md)
