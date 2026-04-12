import SwiftUI

struct NutritionFactsTable: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String? // e.g. "100g" or "1 bar (50g)"
    
    var body: some View {
        VStack(spacing: 0) {
            Text("NUTRITION INFORMATION")
                .font(.system(size: 20, weight: .black))
                .kerning(0.5)
                .padding(.top, 8)
            
            Rectangle()
                .frame(height: 8)
                .padding(.vertical, 4)
            
            HStack {
                Text("(Per Serving)")
                    .font(.system(size: 18, weight: .heavy))
                Spacer()
                if let serving = servingSize {
                    Text(serving)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .padding(.bottom, 4)
            
            Rectangle()
                .frame(height: 4)
            
            // Header
            HStack {
                Text("Nutrient")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("Amount per Serving")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.vertical, 4)
            
            Rectangle()
                .frame(height: 1)
            
            // Rows
            NutritionRow(label: "Energy", value: "\(Int(calories)) kcal")
            NutritionRow(label: "Total Fat", value: String(format: "%.1f g", fat))
            NutritionRow(label: "Carbohydrates", value: String(format: "%.1f g", carbs))
            NutritionRow(label: "Protein", value: String(format: "%.1f g", protein))
            
            Rectangle()
                .frame(height: 4)
        }
        .padding(12)
        .background(Color.white)
        .border(Color.black, width: 2)
        .foregroundColor(.black) // Force black text for the label look
        .cornerRadius(2)
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text(value)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.vertical, 4)
            
            Rectangle()
                .frame(height: 1)
                .opacity(0.5)
        }
    }
}

#Preview {
    NutritionFactsTable(calories: 250, protein: 12, carbs: 30, fat: 9, servingSize: "1 bar (60g)")
        .padding()
        .background(Color.gray)
}
