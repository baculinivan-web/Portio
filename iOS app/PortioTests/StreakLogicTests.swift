import XCTest
@testable import Portio

final class StreakLogicTests: XCTestCase {
    
    func testGoalMetLogic() {
        // Mock UserSettings.WeightGoalMode logic (copied for pure test)
        func isGoalMet(intake: Double, goal: Double, mode: UserSettings.WeightGoalMode) -> Bool {
            guard goal > 0 else { return false }
            switch mode {
            case .lose: return intake > 0 && intake <= goal
            case .gain: return intake >= goal
            case .maintain:
                let lowerBound = goal * 0.9
                let upperBound = goal * 1.1
                return intake >= lowerBound && intake <= upperBound
            }
        }
        
        let goal = 2000.0
        
        // Lose mode
        XCTAssertTrue(isGoalMet(intake: 1500, goal: goal, mode: .lose))
        XCTAssertTrue(isGoalMet(intake: 2000, goal: goal, mode: .lose))
        XCTAssertFalse(isGoalMet(intake: 2500, goal: goal, mode: .lose))
        XCTAssertFalse(isGoalMet(intake: 0, goal: goal, mode: .lose))
        
        // Gain mode
        XCTAssertTrue(isGoalMet(intake: 2500, goal: goal, mode: .gain))
        XCTAssertTrue(isGoalMet(intake: 2000, goal: goal, mode: .gain))
        XCTAssertFalse(isGoalMet(intake: 1500, goal: goal, mode: .gain))
        
        // Maintain mode (90% - 110%)
        XCTAssertTrue(isGoalMet(intake: 1800, goal: goal, mode: .maintain)) // 90%
        XCTAssertTrue(isGoalMet(intake: 2200, goal: goal, mode: .maintain)) // 110%
        XCTAssertTrue(isGoalMet(intake: 2000, goal: goal, mode: .maintain))
        XCTAssertFalse(isGoalMet(intake: 1700, goal: goal, mode: .maintain))
        XCTAssertFalse(isGoalMet(intake: 2300, goal: goal, mode: .maintain))
    }
}
