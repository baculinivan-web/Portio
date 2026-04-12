import SwiftUI

struct FoodItemRowView: View {
    let item: FoodItem

    var body: some View {
        HStack {
            // Show the first image as a thumbnail
            if let firstImageData = item.imageDatas.first, let uiImage = UIImage(data: firstImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.isProcessing ? item.name : item.cleanFoodName)
                    .font(.headline)
                
                if !item.isProcessing {
                    HStack(spacing: 8) {
                        Text("\(item.weightGrams, format: .number.precision(.fractionLength(0)))g")
                        Text("•")
                        Text("P: \(item.protein, format: .number.precision(.fractionLength(0)))g, C: \(item.carbs, format: .number.precision(.fractionLength(0)))g, F: \(item.fat, format: .number.precision(.fractionLength(0)))g")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if item.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Text("\(item.calories, format: .number.precision(.fractionLength(0))) kcal")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}