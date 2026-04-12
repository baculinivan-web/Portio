import XCTest
@testable import Portio

final class NutrientImbalanceTests: XCTestCase {

    func testImbalanceTriggered() {
        // Protein at 10%
        let proteinIntake: Double = 10
        let proteinGoal: Double = 100
        
        // Carbs at 41%
        let carbIntake: Double = 41
        let carbGoal: Double = 100
        
        let gap = NutrientWarningManager.getImbalanceGap(
            intake: carbIntake,
            goal: carbGoal,
            proteinIntake: proteinIntake,
            proteinGoal: proteinGoal
        )
        
        XCTAssertNotNil(gap)
        XCTAssertEqual(gap, 31)
    }
    
    func testImbalanceNotTriggered() {
        // Protein at 10%
        let proteinIntake: Double = 10
        let proteinGoal: Double = 100
        
        // Carbs at 39%
        let carbIntake: Double = 39
        let carbGoal: Double = 100
        
        let gap = NutrientWarningManager.getImbalanceGap(
            intake: carbIntake,
            goal: carbGoal,
            proteinIntake: proteinIntake,
            proteinGoal: proteinGoal
        )
        
        XCTAssertNil(gap, "Gap of 29% should NOT trigger imbalance warning")
    }
    
    func testImbalanceTriggeredWithDifferentGoals() {
        // Protein: 20g / 200g goal = 10%
        let proteinIntake: Double = 20
        let proteinGoal: Double = 200
        
        // Fat: 15g / 30g goal = 50%
        let fatIntake: Double = 15
        let fatGoal: Double = 30
        
        let gap = NutrientWarningManager.getImbalanceGap(
            intake: fatIntake,
            goal: fatGoal,
            proteinIntake: proteinIntake,
            proteinGoal: proteinGoal
        )
        
        XCTAssertNotNil(gap)
        XCTAssertEqual(gap, 40)
    }
}
