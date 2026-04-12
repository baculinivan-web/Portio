import Foundation

// Implements the Mifflin-St Jeor equation for BMR and TDEE calculation.
struct CalorieCalculator {
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        var id: Self { self }
    }

    enum ActivityLevel: String, CaseIterable, Identifiable {
        case sedentary = "Sedentary (little or no exercise)"
        case lightlyActive = "Lightly Active (1-3 days/week)"
        case moderatelyActive = "Moderately Active (3-5 days/week)"
        case veryActive = "Very Active (6-7 days/week)"
        case extraActive = "Extra Active (very hard exercise & physical job)"
        
        var id: Self { self }

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extraActive: return 1.9
            }
        }
    }

    static func calculateTDEE(weightKg: Double, heightCm: Double, age: Int, gender: Gender, activityLevel: ActivityLevel) -> Double {
        let bmr: Double
        if gender == .male {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
        return bmr * activityLevel.multiplier
    }
}
