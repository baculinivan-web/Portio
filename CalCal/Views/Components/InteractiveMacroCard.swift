import SwiftUI

struct InteractiveMacroCard: View {
    let title: String
    let value: Double
    let goal: Double
    let unit: String
    let color: Color
    
    @State private var isExpanded = false
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(value))")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("/ \(Int(goal)) \(unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                CircularProgressView(progress: progress, color: color)
                    .frame(width: 50, height: 50)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("Details Placeholder") // Will be replaced with real breakdown later
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Example breakdown bar
                    Capsule()
                        .fill(color.opacity(0.3))
                        .frame(height: 8)
                        .overlay(
                            GeometryReader { geometry in
                                Capsule()
                                    .fill(color)
                                    .frame(width: geometry.size.width * progress)
                            }
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
        InteractiveMacroCard(title: "Protein", value: 85, goal: 150, unit: "g", color: .purple)
            .padding()
    }
}
