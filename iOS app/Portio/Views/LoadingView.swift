import SwiftUI
import Combine

struct LoadingView: View {
    private let messages = [
        "Calculating calories...",
        "Analyzing activity levels...",
        "Consulting with digital nutritionists...",
        "Counting macros...",
        "Reticulating splines...",
        "Almost there..."
    ]
    
    @State private var currentMessageIndex = 0
    @State private var displayedText: String = ""

    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                Text(displayedText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.animation(.easeInOut))
            }
            .onAppear {
                displayedText = messages[0]
            }
            .onReceive(timer) { _ in
                withAnimation {
                    currentMessageIndex = (currentMessageIndex + 1) % messages.count
                    displayedText = messages[currentMessageIndex]
                }
            }
        }
    }
}

#Preview {
    LoadingView()
}