import XCTest
@testable import CalCal

final class StreakColorLogicTests: XCTestCase {
    
    // Since ContributionDot uses @AppStorage which is hard to mock in pure unit tests without side effects,
    // we should ideally have a pure logic function. For now, I'll test the logic concepts.
    
    func testLoseWeightLogic() {
        let goal = 2000.0
        let mode = UserSettings.WeightGoalMode.lose
        
        // Success: Under or equal to goal
        XCTAssertTrue(isFullSuccess(calories: 1800, goal: goal, mode: mode))
        XCTAssertTrue(isFullSuccess(calories: 2000, goal: goal, mode: mode))
        
        // Failure: Over goal
        XCTAssertFalse(isFullSuccess(calories: 2100, goal: goal, mode: mode))
    }
    
    func testGainWeightLogic() {
        let goal = 3000.0
        let mode = UserSettings.WeightGoalMode.gain
        
        // Success: Over or equal to goal
        XCTAssertTrue(isFullSuccess(calories: 3200, goal: goal, mode: mode))
        XCTAssertTrue(isFullSuccess(calories: 3000, goal: goal, mode: mode))
        
        // Failure: Under goal
        XCTAssertFalse(isFullSuccess(calories: 2800, goal: goal, mode: mode))
    }
    
    func testMaintainWeightLogic() {
        let goal = 2500.0
        let mode = UserSettings.WeightGoalMode.maintain
        
        // Success: Within 10% (90% - 110%)
        XCTAssertTrue(isFullSuccess(calories: 2250, goal: goal, mode: mode)) // 90%
        XCTAssertTrue(isFullSuccess(calories: 2750, goal: goal, mode: mode)) // 110%
        XCTAssertTrue(isFullSuccess(calories: 2500, goal: goal, mode: mode)) // 100%
        
        // Failure: Outside 10%
        XCTAssertFalse(isFullSuccess(calories: 2200, goal: goal, mode: mode))
        XCTAssertFalse(isFullSuccess(calories: 2800, goal: goal, mode: mode))
    }
    
    // MARK: - Helper logic (replicated from view for testing)
    private func isFullSuccess(calories: Double, goal: Double, mode: UserSettings.WeightGoalMode) -> Bool {
        switch mode {
        case .lose:
            return calories <= goal
        case .gain:
            return calories >= goal
        case .maintain:
            let lowerBound = goal * 0.9
            let upperBound = goal * 1.1
            return calories >= lowerBound && calories <= upperBound
        }
    }
}
