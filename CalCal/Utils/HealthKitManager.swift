import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    // Define the data types we want to write
    private let typesToWrite: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
    ]
    
    private init() {}
    
    /// Checks if HealthKit is available on the current device
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Requests authorization from the user to write nutritional data
    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HKError(.errorHealthDataUnavailable)
        }
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: nil)
    }
    
    /// Checks the current authorization status for nutritional types
    func checkAuthorizationStatus() -> HKAuthorizationStatus {
        // We check one of the types as a proxy for the general status
        let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        return healthStore.authorizationStatus(for: energyType)
    }
    
    /// Writes nutritional data from a FoodItem to HealthKit
    func writeNutrition(for item: FoodItem) async throws -> [String] {
        guard isHealthDataAvailable else { return [] }
        
        let date = item.dateEaten
        let metadata: [String: Any] = [
            HKMetadataKeyFoodType: item.cleanFoodName,
            "CalCalItemID": item.id.uuidString
        ]
        
        var samples: [HKQuantitySample] = []
        
        // 1. Energy
        if item.calories > 0 {
            let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: item.calories)
            samples.append(HKQuantitySample(type: energyType, quantity: energyQuantity, start: date, end: date, metadata: metadata))
        }
        
        // 2. Protein
        if item.protein > 0 {
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: item.protein)
            samples.append(HKQuantitySample(type: proteinType, quantity: proteinQuantity, start: date, end: date, metadata: metadata))
        }
        
        // 3. Carbs
        if item.carbs > 0 {
            let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let carbsQuantity = HKQuantity(unit: .gram(), doubleValue: item.carbs)
            samples.append(HKQuantitySample(type: carbsType, quantity: carbsQuantity, start: date, end: date, metadata: metadata))
        }
        
        // 4. Fat
        if item.fat > 0 {
            let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: item.fat)
            samples.append(HKQuantitySample(type: fatType, quantity: fatQuantity, start: date, end: date, metadata: metadata))
        }
        
        guard !samples.isEmpty else { return [] }
        
        try await healthStore.save(samples)
        return samples.map { $0.uuid.uuidString }
    }
    
    /// Deletes specific samples from HealthKit by their UUIDs
    func deleteNutrition(uuids: [String]) async throws {
        guard isHealthDataAvailable, !uuids.isEmpty else { return }
        
        let sampleUUIDs = uuids.compactMap { UUID(uuidString: $0) }
        guard !sampleUUIDs.isEmpty else { return }
        
        // We need to delete from each type potentially
        for type in typesToWrite {
            guard let quantityType = type as? HKQuantityType else { continue }
            let predicate = HKQuery.predicateForObjects(with: Set(sampleUUIDs))
            
            // HealthKit's deleteObjects requires a slightly different approach for quantity samples
            // but we can use the predicate to find and delete.
            try await healthStore.deleteObjects(of: quantityType, predicate: predicate)
        }
    }
    
    /// Synchronizes all provided items that haven't been synced yet
    func syncAllData(items: [FoodItem]) async {
        guard isHealthDataAvailable else { return }
        
        for item in items {
            // Only sync if not already synced
            if item.healthKitSampleUUIDs.isEmpty {
                if let uuids = try? await writeNutrition(for: item) {
                    item.healthKitSampleUUIDs = uuids
                }
            }
        }
    }
}
