import SwiftUI
import SwiftData
import WidgetKit
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \FoodItem.dateEaten, order: .reverse) private var items: [FoodItem]

    @StateObject private var viewModel = CalorieTrackerViewModel()
    @State private var foodQuery: String = ""
    @State private var isShowingSettings = false
    @State private var isShowingStreakHistory = false
    @State private var showGoalSummary = false
    @State private var isShowingCamera = false
    @State private var isShowingManualEntry = false
    @State private var manualEntryDetent: PresentationDetent = .medium
    @State private var attachedImages: [UIImage] = []
    @State private var isShowingWarningAnalysis = false
    @State private var isShowingDayPicker = false
    @State private var selectedDate = Date()
    @State private var currentTime = Date()
    @FocusState private var isInputFocused: Bool

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    @AppStorage("calorieGoal", store: UserSettings.shared) private var calorieGoal: Double = UserSettings.calorieGoal
    @AppStorage("proteinGoal", store: UserSettings.shared) private var proteinGoal: Double = UserSettings.proteinGoal
    @AppStorage("carbsGoal", store: UserSettings.shared) private var carbsGoal: Double = UserSettings.carbsGoal
    @AppStorage("fatGoal", store: UserSettings.shared) private var fatGoal: Double = UserSettings.fatGoal
    @AppStorage("hasCompletedOnboarding", store: UserSettings.shared) private var hasCompletedOnboarding: Bool = UserSettings.hasCompletedOnboarding
    @AppStorage("hasShownBlockRunPrompt", store: UserSettings.shared) private var hasShownBlockRunPrompt: Bool = UserSettings.hasShownBlockRunPrompt
    @AppStorage("isBlockRunEnabled", store: UserSettings.shared) private var isBlockRunEnabled: Bool = UserSettings.isBlockRunEnabled
    @AppStorage("modelName", store: UserSettings.shared) private var modelName: String = UserSettings.modelName
    @AppStorage("isCalorieCommentaryEnabled", store: UserSettings.shared) private var isCalorieCommentaryEnabled: Bool = UserSettings.isCalorieCommentaryEnabled
    @AppStorage("calorieCommentaryLevel", store: UserSettings.shared) private var calorieCommentaryLevelRaw: String = UserSettings.calorieCommentaryLevel.rawValue

    @State private var isShowingBlockRunPrompt = false
    @State private var calorieCommentaryRefreshSeed = 0

    private var selectedDayItems: [FoodItem] {
        FoodItemDaySelection.items(from: items, on: selectedDate)
    }

    private var datesWithEntries: Set<Date> {
        Set(items.map { Calendar.current.startOfDay(for: $0.dateEaten) })
    }

    private var hasLoggedToday: Bool {
        !items.filter { Calendar.current.isDateInToday($0.dateEaten) && !$0.isProcessing && !$0.hasFailedProcessing }.isEmpty
    }

    private var completedItems: [FoodItem] {
        selectedDayItems.filter { !$0.isProcessing && !$0.hasFailedProcessing }
    }

    private var isSelectedDateToday: Bool {
        FoodItemDaySelection.isToday(selectedDate, now: currentTime)
    }

    private var selectedDateTitle: String {
        FoodItemDaySelection.title(for: selectedDate, now: currentTime)
    }

    private var totalCalories: Double { completedItems.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { completedItems.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { completedItems.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { completedItems.reduce(0) { $0 + $1.fat } }

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

    private var calorieCommentaryLevel: UserSettings.CalorieCommentaryLevel {
        UserSettings.CalorieCommentaryLevel(rawValue: calorieCommentaryLevelRaw) ?? .sassy
    }

    private var calorieCommentary: CalorieCommentary? {
        guard isCalorieCommentaryEnabled else { return nil }
        return CalorieCommentaryManager.commentary(
            calories: totalCalories,
            goal: calorieGoal,
            level: calorieCommentaryLevel,
            refreshSeed: calorieCommentaryRefreshSeed
        )
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

                        if calorieCommentary != nil || !triggeredWarnings.isEmpty {
                            Divider()

                            VStack(spacing: 12) {
                                if let calorieCommentary {
                                    CalorieCommentaryCard(
                                        commentary: calorieCommentary
                                    )
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .opacity.combined(with: .scale(scale: 0.95))
                                    ))
                                }

                                if calorieCommentary != nil && !triggeredWarnings.isEmpty {
                                    Divider()
                                }

                                if !triggeredWarnings.isEmpty {
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
                    }
                }

                Section(header: Text("Entries")) {
                    if selectedDayItems.isEmpty {
                        Text("No entries for this day")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(selectedDayItems) { item in
                            NavigationLink(value: item) {
                                FoodItemRowView(item: item) {
                                    viewModel.retryItem(item, context: modelContext)
                                }
                            }
                            .disabled(item.isProcessing)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: triggeredWarnings)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: calorieCommentary)
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { isShowingSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        isShowingDayPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedDateTitle)
                                .font(.headline.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .buttonStyle(.plain)
                }
                if !isSelectedDateToday {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Today") {
                            withAnimation(.spring()) {
                                selectedDate = .now
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingStreakHistory = true } label: {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(hasLoggedToday ? .orange : .secondary.opacity(0.5))
                            .animation(.spring(), value: hasLoggedToday)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ChatInputView(
                    text: $foodQuery,
                    attachedImages: attachedImages,
                    onSend: addItem,
                    onCameraTap: { isShowingCamera = true },
                    onManualTap: {
                        manualEntryDetent = .medium
                        isShowingManualEntry = true
                    },
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
            .onAppear {
                refreshCalorieCommentary()

                if hasCompletedOnboarding && !hasShownBlockRunPrompt {
                    isShowingBlockRunPrompt = true
                }
            }
            .alert("Try BlockRun AI?", isPresented: $isShowingBlockRunPrompt) {
                Button("Yes, Enable (Beta)") {
                    UserSettings.llmProvider = .blockRun
                    modelName = "nvidia/mistral-small-4-119b"
                    hasShownBlockRunPrompt = true
                }
                Button("Maybe Later", role: .cancel) {
                    hasShownBlockRunPrompt = true
                }
            } message: {
                Text("BlockRun AI uses free local models via cloud gateway. This is a beta feature for autonomous AI agents. No local proxy required.")
            }
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
            .sheet(isPresented: $isShowingDayPicker) {
                DayPickerView(selectedDate: $selectedDate, datesWithEntries: datesWithEntries)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isShowingManualEntry) {
                ManualFoodEntrySheet { entry in
                    addManualItem(entry)
                }
                .presentationDetents([.medium, .large], selection: $manualEntryDetent)
            }
            .sheet(isPresented: $isShowingWarningAnalysis) {
                NutrientWarningDetailView(
                    triggeredWarnings: triggeredWarnings,
                    todaysItems: completedItems,
                    totals: (totalCalories, totalProtein, totalCarbs, totalFat),
                    goals: (calorieGoal, proteinGoal, carbsGoal, fatGoal)
                )
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraView { image in
                    attachedImages.append(image)
                }
            }
            .onReceive(timer) { input in
                currentTime = input
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshCalorieCommentary()
                }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        switch url.absoluteString {
        case "portio://camera":
            isShowingCamera = true
        case "portio://add":
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

    private func addManualItem(_ entry: ManualFoodEntry) {
        viewModel.addManualItem(entry, context: modelContext)
        refreshCalorieCommentary()
    }

    private func refreshCalorieCommentary() {
        calorieCommentaryRefreshSeed = (calorieCommentaryRefreshSeed + 1) % 10_000
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation(.spring()) {
            for index in offsets {
                let itemToDelete = selectedDayItems[index]

                // Remove from HealthKit if enabled and UUIDs exist
                if UserSettings.isAppleHealthSyncEnabled && !itemToDelete.healthKitSampleUUIDs.isEmpty {
                    let uuids = itemToDelete.healthKitSampleUUIDs
                    Task {
                        try? await HealthKitManager.shared.deleteNutrition(uuids: uuids)
                    }
                }

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
