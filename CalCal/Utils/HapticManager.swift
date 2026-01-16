import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Triggers a standard success haptic
    func triggerSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Triggers a cool impact sequence for major milestones
    func triggerAchievementSequence() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        
        // Sequence: three rapid taps
        impact.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let strongImpact = UIImpactFeedbackGenerator(style: .heavy)
            strongImpact.impactOccurred()
        }
    }
}
