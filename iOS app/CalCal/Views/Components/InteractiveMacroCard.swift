import SwiftUI

struct InteractiveMacroCard: View {
    let title: String
    let value: Double
    let goal: Double
    let unit: String
    let color: Color
    let items: [FoodItem]
    
    @State private var isExpanded = false
    
    private var filteredItems: [(id: UUID, name: String, value: Double)] {
        items.compactMap { item in
            let val: Double
            switch title.lowercased() {
            case "calories": val = item.calories
            case "protein": val = item.protein
            case "carbs": val = item.carbs
            case "fat": val = item.fat
            default: val = 0
            }
            return val > 0 ? (id: item.id, name: item.cleanFoodName, value: val) : nil
        }.sorted { $0.value > $1.value }
    }
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title.uppercased())
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(color)
                        
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(value))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("/ \(Int(goal)) \(unit)")
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                CircularProgressView(progress: progress, color: color)
                    .frame(width: 60, height: 60)
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(color.opacity(0.3))
                    
                    if filteredItems.isEmpty {
                        Text("No items logged yet")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredItems, id: \.id) { item in
                                    HStack {
                                        Text(item.name)
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(item.value))\(unit)")
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(color)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .frame(maxHeight: 150)
                        .scrollEdgeEffectStyle(.soft, for: .vertical)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.1),
                                    .init(color: .black, location: 0.9),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    
                    // Refined progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(progress * 100))% of daily goal")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Capsule()
                            .fill(color.opacity(0.1))
                            .frame(height: 12)
                            .overlay(
                                GeometryReader { geometry in
                                    Capsule()
                                        .fill(color.gradient)
                                        .frame(width: geometry.size.width * progress)
                                }
                            )
                    }
                }
                .transition(.asymmetric(insertion: .push(from: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                isExpanded.toggle()
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: progress)
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        InteractiveMacroCard(title: "Protein", value: 85, goal: 150, unit: "g", color: .red, items: [])
            .padding()
    }
}
