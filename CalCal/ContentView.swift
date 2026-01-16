import SwiftUI
import SwiftData
import WidgetKit
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodItem.dateEaten, order: .reverse) private var items: [FoodItem]
    
    @StateObject private var viewModel = CalorieTrackerViewModel()
    @State private var foodQuery: String = ""
    @State private var isShowingSettings = false
    @State private var isShowingStreakHistory = false
    @State private var showGoalSummary = false
    @State private var isShowingCamera = false
    @State private var attachedImages: [UIImage] = []
    @State private var isShowingWarningAnalysis = false
    @State private var currentTime = Date()
    @FocusState private var isInputFocused: Bool
    
    // Streak Achievement State
    @Namespace private var streakAnimation
    @State private var activeAchievement: AchievementLevel? = nil
    @State private var currentStreakCount: Int = 0
    @State private var showStreakNotification = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    @AppStorage("calorieGoal") private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal") private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal") private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal") private var fatGoal: Double = UserSettings.fatGoal
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = UserSettings.hasCompletedOnboarding

    private var todaysItems: [FoodItem] {
        items.filter { Calendar.current.isDateInToday($0.dateEaten) }
    }
    
    private var hasLoggedToday: Bool {
        !todaysItems.isEmpty
    }

    private var totalCalories: Double { todaysItems.filter { !$0.isProcessing }.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { todaysItems.filter { !$0.isProcessing }.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { todaysItems.filter { !$0.isProcessing }.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { todaysItems.filter { !$0.isProcessing }.reduce(0) { $0 + $1.fat } }
    
    private var triggeredWarnings: [WarningType] {
        var warnings: [WarningType] = []
        
        // 1. Overshoot warnings
        if NutrientWarningManager.shouldTriggerWarning(intake: totalCalories, goal: calorieGoal, date: currentTime) { warnings.append(.overshoot(.calories)) }
        if NutrientWarningManager.shouldTriggerWarning(intake: totalCarbs, goal: carbsGoal, date: currentTime) { warnings.append(.overshoot(.carbs)) }
        if NutrientWarningManager.shouldTriggerWarning(intake: totalFat, goal: fatGoal, date: currentTime) { warnings.append(.overshoot(.fat)) }
        
        // 2. Imbalance warnings (Relative to Protein)
        if NutrientWarningManager.getImbalanceGap(intake: totalCarbs, goal: carbsGoal, proteinIntake: totalProtein, proteinGoal: proteinGoal) != nil {
            warnings.append(.imbalance(.carbs))
        }
        if NutrientWarningManager.getImbalanceGap(intake: totalFat, goal: fatGoal, proteinIntake: totalProtein, proteinGoal: proteinGoal) != nil {
            warnings.append(.imbalance(.fat))
        }
        
        return warnings
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        NavigationLink(value: "stats") {
                            TotalsCardView(
                                calories: totalCalories,
                                protein: totalProtein,
                                carbs: totalCarbs,
                                fat: totalFat,
                                calorieGoal: calorieGoal,
                                proteinGoal: proteinGoal,
                                carbsGoal: carbsGoal,
                                fatGoal: fatGoal
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if !triggeredWarnings.isEmpty {
                            Divider()
                            
                            NutrientWarningCard(triggeredWarnings: triggeredWarnings) {
                                isShowingWarningAnalysis = true
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                        }
                    }
                }
                
                Section(header: Text("Today's Entries")) {
                    ForEach(todaysItems) { item in
                        NavigationLink(value: item) {
                            FoodItemRowView(item: item)
                        }
                        .disabled(item.isProcessing)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: triggeredWarnings)
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: FoodItem.self) { item in
                FoodItemDetailView(item: item)
            }
            .navigationDestination(for: String.self) { value in
                if value == "stats" {
                    StatisticsView()
                }
            }
            .navigationTitle("CalCal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { isShowingSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingStreakHistory = true } label: {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(hasLoggedToday ? .orange : .secondary.opacity(0.5))
                            .animation(.spring(), value: hasLoggedToday)
                            .matchedGeometryEffect(id: "streakIcon", in: streakAnimation, isSource: !showStreakNotification)
                    }
                    .opacity(showStreakNotification ? 0 : 1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                ChatInputView(
                    text: $foodQuery,
                    attachedImages: attachedImages,
                    onSend: addItem,
                    onCameraTap: { isShowingCamera = true },
                    onRemoveImage: { index in
                        withAnimation {
                            _ = attachedImages.remove(at: index)
                        }
                    },
                    focusState: $isInputFocused
                )
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            })
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $isShowingStreakHistory) {
                StreakHistoryView()
            }
            .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                OnboardingView() {
                    // This gets called when onboarding is finished.
                    hasCompletedOnboarding = true
                    showGoalSummary = true // Trigger the summary sheet.
                }
            }
            .sheet(isPresented: $showGoalSummary) {
                GoalSummaryView()
            }
            .sheet(isPresented: $isShowingWarningAnalysis) {
                NutrientWarningDetailView(
                    triggeredWarnings: triggeredWarnings,
                    todaysItems: todaysItems,
                    totals: (totalCalories, totalProtein, totalCarbs, totalFat),
                    goals: (calorieGoal, proteinGoal, carbsGoal, fatGoal)
                )
            }
            .onReceive(timer) { input in
                currentTime = input
            }
            .task {
                // Check for achievements on launch (e.g. if logged via widget)
                checkForAchievements()
            }
            .onChange(of: todaysItems) { _, _ in
                checkForAchievements()
            }
            .overlay(alignment: .top) {
                if showStreakNotification, let level = activeAchievement {
                    StreakNotificationPill(level: level, streakCount: currentStreakCount)
                        .matchedGeometryEffect(id: "streakIcon", in: streakAnimation)
                        .padding(.top, 10)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .zIndex(100)
                }
            }
        }
    }

    private func triggerAchievement(_ level: AchievementLevel) {
        let streakManager = StreakManager(modelContext: modelContext)
        currentStreakCount = (try? streakManager.calculateCurrentStreak()) ?? 0
        activeAchievement = level
        
        // Trigger Haptics
        if level == .level1 {
            HapticManager.shared.triggerSuccess()
        } else {
            HapticManager.shared.triggerAchievementSequence()
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showStreakNotification = true
        }
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showStreakNotification = false
            }
        }
    }

    private func checkForAchievements() {
        if let achievement = StreakAchievementManager.checkAchievement(
            totalCalories: totalCalories,
            calorieGoal: calorieGoal,
            weightGoalMode: UserSettings.weightGoalMode,
            hasEntries: !todaysItems.isEmpty
        ) {
            // Delay slightly to ensure UI is ready and icon is in place
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                triggerAchievement(achievement)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        switch url.absoluteString {
        case "calcal://camera":
            isShowingCamera = true
        case "calcal://add":
            isInputFocused = true
        default:
            break
        }
    }

    private func addItem() {
        guard !foodQuery.isEmpty || !attachedImages.isEmpty else { return }
        let query = foodQuery
        let imagesData = attachedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        
        foodQuery = ""
        withAnimation {
            attachedImages = []
        }
        
        viewModel.addItem(query: query, imageDatas: imagesData, context: modelContext)
        
        // Dismiss the keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation(.spring()) {
            for index in offsets {
                let itemToDelete = todaysItems[index]
                modelContext.delete(itemToDelete)
            }
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: FoodItem.self, configurations: config)
            
            let sampleData = [
                FoodItem(name: "Chicken Salad", identifiedFood: "Chicken Salad", cleanFoodName: "Chicken Salad", dateEaten: .now, calories: 350, protein: 30, carbs: 10, fat: 20, weightGrams: 250, caloriesPer100g: 140, proteinPer100g: 12, carbsPer100g: 4, fatPer100g: 8),
                FoodItem(name: "Apple", identifiedFood: "Apple", cleanFoodName: "Apple", dateEaten: .now, calories: 95, protein: 0.5, carbs: 25, fat: 0.3, weightGrams: 180, caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2)
            ]
            sampleData.forEach { container.mainContext.insert($0) }
            
            return AnyView(ContentView().modelContainer(container))
        } catch {
            return AnyView(Text("Failed to create preview: \(error.localizedDescription)"))
        }
    }
}
