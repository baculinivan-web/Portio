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
}
