import XCTest
@testable import Portio

final class NutrientWarningLogicTests: XCTestCase {

    func testWarningTriggeredBefore1700() {
        let currentIntake: Double = 95
        let goal: Double = 100
        let date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        
        let shouldWarn = NutrientWarningManager.shouldTriggerWarning(intake: currentIntake, goal: goal, date: date)
        
        XCTAssertTrue(shouldWarn, "Should trigger warning if >= 95% and before 17:00")
    }
    
    func testWarningNotTriggeredAfter1700() {
        let currentIntake: Double = 95
        let goal: Double = 100
        let date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        
        let shouldWarn = NutrientWarningManager.shouldTriggerWarning(intake: currentIntake, goal: goal, date: date)
        
        XCTAssertFalse(shouldWarn, "Should NOT trigger warning if >= 95% and after 17:00")
    }

    func testOvershootTriggeredAlways() {
        let currentIntake: Double = 101
        let goal: Double = 100
        let dateAfter1700 = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        
        let shouldWarn = NutrientWarningManager.shouldTriggerWarning(intake: currentIntake, goal: goal, date: dateAfter1700)
        
        XCTAssertTrue(shouldWarn, "Should trigger warning if > 100% regardless of time")
    }
    
    func testWarningNotTriggeredBelowThreshold() {
        let currentIntake: Double = 94
        let goal: Double = 100
        let date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        
        let shouldWarn = NutrientWarningManager.shouldTriggerWarning(intake: currentIntake, goal: goal, date: date)
        
        XCTAssertFalse(shouldWarn, "Should NOT trigger warning if < 95%")
    }
}
