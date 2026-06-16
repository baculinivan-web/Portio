import SwiftUI
import SwiftData
import UIKit

struct OnboardingView: View {
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var step = 0
    @State private var ageValue = Int(UserSettings.onboardingAge) ?? 28
    @State private var heightValue = Int(UserSettings.onboardingHeightCm) ?? 175
    @State private var weightValue = Int(Double(UserSettings.onboardingWeightKg) ?? 70)
    @State private var gender = UserSettings.onboardingGender
    @State private var activityLevel = UserSettings.onboardingActivityLevel
    @State private var weightGoalMode = UserSettings.weightGoalMode
    @State private var customGoal = UserSettings.onboardingCustomGoal
    @State private var isHealthSyncEnabled = UserSettings.isAppleHealthSyncEnabled
    @State private var commentaryLevel = UserSettings.calorieCommentaryLevel

    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var openRouterApiKey = UserSettings.openRouterApiKey
    @State private var serperApiKey = UserSettings.serperApiKey
    @State private var modelName = UserSettings.modelName
    @State private var customApiBaseUrl = UserSettings.customApiBaseUrl
    @State private var blockRunWalletId = UserSettings.blockRunWalletId
    @State private var blockRunProxyUrl = UserSettings.blockRunProxyUrl
    @State private var llmProvider = UserSettings.llmProvider

    @State private var isOpenRouterKeyVisible = false
    @State private var isSerperKeyVisible = false
    @State private var isWalletIdVisible = false
    @State private var helpTopic: HelpTopic?
    @FocusState private var focusedField: OnboardingFocusField?

    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let totalSteps = 9

    private var nutritionService: NutritionService {
        let apiKey = openRouterApiKey.isEmpty ? (APIKeyManager.getOpenRouterAPIKey() ?? "") : openRouterApiKey
        let serperKey = serperApiKey.isEmpty ? (APIKeyManager.getSerperAPIKey() ?? "") : serperApiKey

        let model: String
        let customBaseURL: String?

        if llmProvider == .blockRun {
            model = modelName.isEmpty ? "nvidia/mistral-small-4-119b" : modelName
            customBaseURL = nil
        } else {
            model = modelName.isEmpty ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free") : modelName
            customBaseURL = customApiBaseUrl.isEmpty ? UserSettings.customApiBaseUrl : customApiBaseUrl
        }

        return NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey, customBaseURL: customBaseURL, provider: llmProvider)
    }

    private var canContinue: Bool {
        switch step {
        case 8:
            if llmProvider == .blockRun { return true }
            return !openRouterApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    private var buttonTitle: String {
        step == totalSteps - 1 ? "Calculate my goals" : "Next"
    }

    private var accentColors: [Color] {
        switch commentaryLevel {
        case .professional:
            return [Color(red: 0.18, green: 0.42, blue: 1.0), Color(red: 0.04, green: 0.9, blue: 0.78)]
        case .sassy:
            return [Color(red: 1.0, green: 0.76, blue: 0.15), Color(red: 0.99, green: 0.34, blue: 0.36)]
        case .crazy:
            return [Color(red: 1.0, green: 0.12, blue: 0.18), Color(red: 0.56, green: 0.0, blue: 0.96)]
        }
    }

    var body: some View {
        ZStack {
            OnboardingBackdrop(step: step, accentColors: accentColors)

            VStack(spacing: 0) {
                header

                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    wheelStep(title: "Enter your age", subtitle: "This helps Portio estimate your daily energy baseline.", value: $ageValue, range: 13...90, unit: "years").tag(1)
                    wheelStep(title: "How tall are you?", subtitle: "Centimeters keep the goal math precise.", value: $heightValue, range: 120...230, unit: "cm").tag(2)
                    wheelStep(title: "Current weight", subtitle: "Use today's best estimate. You can change it later.", value: $weightValue, range: 35...220, unit: "kg").tag(3)
                    genderStep.tag(4)
                    activityStep.tag(5)
                    goalsStep.tag(6)
                    personalityStep.tag(7)
                    apiStep.tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.55, dampingFraction: 0.86), value: step)

                footer
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
        .simultaneousGesture(
            DragGesture().onEnded { value in
                if value.translation.height > 18 {
                    dismissKeyboard()
                }
            }
        )
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $isLoading) { LoadingView() }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
        .sheet(item: $helpTopic) { topic in
            HelpSheet(topic: topic)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            impact.prepare()
        }
        .onChange(of: ageValue) { _, _ in saveDraft() }
        .onChange(of: heightValue) { _, _ in saveDraft() }
        .onChange(of: weightValue) { _, _ in saveDraft() }
        .onChange(of: gender) { _, _ in saveDraft() }
        .onChange(of: activityLevel) { _, _ in saveDraft() }
        .onChange(of: customGoal) { _, _ in saveDraft() }
        .onChange(of: commentaryLevel) { _, newValue in UserSettings.calorieCommentaryLevel = newValue }
        .onChange(of: step) { _, _ in dismissKeyboard() }
    }

    private var header: some View {
        HStack {
            Text("\(step + 1)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.11), in: Capsule())

            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .tint(.white)
                .scaleEffect(y: 1.6)
                .clipShape(Capsule())

            if UserSettings.hasCompletedOnboarding || UserSettings.isReplayingOnboarding {
                Button("Skip") {
                    tap()
                    saveAllSettings()
                    onComplete()
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))
            }
        }
        .frame(height: 44)
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 210)

            (
                Text("Portio is a new way of tracking your ")
                + Text(Image(systemName: "fork.knife"))
                + Text(" intake. Let's go through a small setup.")
            )
                .font(.system(size: 43, weight: .black, design: .rounded))
                .lineSpacing(2)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 120)
        }
    }

    private func wheelStep(title: String, subtitle: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle(title, subtitle: subtitle)

            Spacer()

            VStack(spacing: 8) {
                Text("\(value.wrappedValue)")
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(.white)
                Text(unit.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .frame(maxWidth: .infinity)

            Picker(title, selection: value) {
                ForEach(Array(range), id: \.self) { item in
                    Text("\(item)").tag(item)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 190)
            .padding(.horizontal, 18)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )

            Spacer()
        }
    }

    private var activityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle("Activity level", subtitle: "Pick the rhythm that feels most like a normal week.")

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(CalorieCalculator.ActivityLevel.allCases) { level in
                        ChoiceButton(
                            title: shortActivityTitle(level),
                            subtitle: activitySubtitle(level),
                            isSelected: activityLevel == level
                        ) {
                            tap()
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                activityLevel = level
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var genderStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle("A quick body metric", subtitle: "This is only used for the first calorie estimate.")

            VStack(spacing: 12) {
                ForEach(CalorieCalculator.Gender.allCases) { item in
                    ChoiceButton(
                        title: item.rawValue,
                        subtitle: item == .male ? "Uses the male Mifflin-St Jeor baseline" : "Uses the female Mifflin-St Jeor baseline",
                        isSelected: gender == item
                    ) {
                        tap()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            gender = item
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle("Your goal", subtitle: "Tell Portio what you want the recommendations to optimize for.")

            Picker("Goal", selection: $weightGoalMode) {
                ForEach(UserSettings.WeightGoalMode.allCases) { mode in
                    Text(mode.rawValue.replacingOccurrences(of: " Weight", with: "")).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $isHealthSyncEnabled) {
                Label("Apple Health Sync", systemImage: "heart.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .tint(accentColors.first ?? .blue)
            .padding(16)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            TextEditor(text: $customGoal)
                .scrollContentBackground(.hidden)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .focused($focusedField, equals: .goalNotes)
                .frame(minHeight: 180)
                .padding(16)
                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if customGoal.isEmpty {
                        Text("Example: lose fat slowly, keep workouts strong, avoid aggressive deficits.")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.38))
                            .padding(.top, 24)
                            .padding(.leading, 21)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var personalityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle("Pick Portio's personality", subtitle: "This affects the remarks Portio makes about your progress.")

            VStack(spacing: 12) {
                ForEach(UserSettings.CalorieCommentaryLevel.allCases) { level in
                    ChoiceButton(
                        title: personalityTitle(level),
                        subtitle: personalitySubtitle(level),
                        isSelected: commentaryLevel == level
                    ) {
                        tap()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            commentaryLevel = level
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private var apiStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StepTitle("Connect your AI", subtitle: "Choose the API mode, add keys, and Portio will use these for food analysis.")

                Picker("API Mode", selection: $llmProvider) {
                    ForEach(UserSettings.LLMProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if llmProvider == .custom {
                    APIField(title: "Base URL", text: $customApiBaseUrl, placeholder: "https://api.openai.com/v1", help: .baseUrl, focus: .customBaseURL)
                    secretField(title: "API Key", text: $openRouterApiKey, placeholder: "API Key", isVisible: $isOpenRouterKeyVisible, help: .apiKey, focus: .apiKey)
                    APIField(title: "Model", text: $modelName, placeholder: "gpt-4o", help: .modelName, focus: .modelName)
                } else if llmProvider == .blockRun {
                    APIField(title: "Endpoint", text: $blockRunProxyUrl, placeholder: "https://blockrun.ai/api/v1", help: .blockRun, focus: .blockRunEndpoint)
                    secretField(title: "Wallet Key / ID", text: $blockRunWalletId, placeholder: "0x...", isVisible: $isWalletIdVisible, help: .blockRun, focus: .blockRunWallet)
                    blockRunModelPicker
                } else {
                    secretField(title: "OpenRouter API Key", text: $openRouterApiKey, placeholder: "sk-or-...", isVisible: $isOpenRouterKeyVisible, help: .openRouterKey, focus: .apiKey)
                    APIField(title: "Model", text: $modelName, placeholder: "openai/gpt-oss-120b:free", help: .modelName, focus: .modelName)
                }

                secretField(title: "Serper API Key", text: $serperApiKey, placeholder: "Optional search key", isVisible: $isSerperKeyVisible, help: .serperKey, focus: .serperKey)
            }
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }

    private var blockRunModelPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldHeader("Model", help: .modelName)
            Picker("Model", selection: $modelName) {
                Text("GPT OSS 120B").tag("nvidia/gpt-oss-120b")
                Text("GPT OSS 20B").tag("nvidia/gpt-oss-20b")
                Text("DeepSeek V3.2").tag("nvidia/deepseek-v3.2")
                Text("Qwen3 Coder 480B").tag("nvidia/qwen3-coder-480b")
                Text("GLM 4.7").tag("nvidia/glm-4.7")
                Text("Llama 4 Maverick").tag("nvidia/llama-4-maverick")
                Text("Qwen3 Thinking").tag("nvidia/qwen3-next-80b-a3b-thinking")
                Text("Mistral Small 4").tag("nvidia/mistral-small-4-119b")
            }
            .pickerStyle(.menu)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var footer: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                if step > 0 {
                    Button {
                        tap()
                        dismissKeyboard()
                        withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                            step -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .liquidGlassControl(isProminent: false)
                    }
                    .buttonStyle(.plain)
                }

            Button {
                tap()
                continueTapped()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .liquidGlassControl(isProminent: true)
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.48)
            }
            .frame(height: 62)
            }
    }

    private func secretField(title: String, text: Binding<String>, placeholder: String, isVisible: Binding<Bool>, help: HelpTopic, focus: OnboardingFocusField) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldHeader(title, help: help)
            HStack(spacing: 10) {
                Group {
                    if isVisible.wrappedValue {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: focus)

                Button {
                    tap()
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(width: 34, height: 34)
                }
            }
            .fieldChrome()
        }
    }

    private func APIField(title: String, text: Binding<String>, placeholder: String, help: HelpTopic, focus: OnboardingFocusField) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldHeader(title, help: help)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: focus)
                .fieldChrome()
        }
    }

    private func fieldHeader(_ title: String, help: HelpTopic) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            Button {
                tap()
                helpTopic = help
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
    }

    private func continueTapped() {
        dismissKeyboard()
        saveDraft()
        if step < totalSteps - 1 {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.86)) {
                step += 1
            }
        } else {
            calculateGoals()
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func tap() {
        impact.impactOccurred(intensity: 0.65)
        impact.prepare()
    }

    private func saveDraft() {
        UserSettings.onboardingAge = "\(ageValue)"
        UserSettings.onboardingHeightCm = "\(heightValue)"
        UserSettings.onboardingWeightKg = "\(weightValue)"
        UserSettings.onboardingGender = gender
        UserSettings.onboardingActivityLevel = activityLevel
        UserSettings.onboardingCustomGoal = customGoal
    }

    private func saveAllSettings() {
        saveDraft()
        UserSettings.weightGoalMode = weightGoalMode
        UserSettings.isAppleHealthSyncEnabled = isHealthSyncEnabled
        UserSettings.calorieCommentaryLevel = commentaryLevel
        UserSettings.openRouterApiKey = openRouterApiKey
        UserSettings.serperApiKey = serperApiKey
        UserSettings.modelName = modelName
        UserSettings.customApiBaseUrl = customApiBaseUrl
        UserSettings.blockRunWalletId = blockRunWalletId
        UserSettings.blockRunProxyUrl = blockRunProxyUrl
        UserSettings.llmProvider = llmProvider
        UserSettings.isReplayingOnboarding = false
    }

    private func calculateGoals() {
        isLoading = true
        saveAllSettings()

        let tdee = CalorieCalculator.calculateTDEE(weightKg: Double(weightValue), heightCm: Double(heightValue), age: ageValue, gender: gender, activityLevel: activityLevel)
        let userStats = "Age: \(ageValue), Height: \(heightValue)cm, Weight: \(weightValue)kg, Gender: \(gender.rawValue), Activity: \(activityLevel.rawValue)"

        Task {
            do {
                if isHealthSyncEnabled {
                    try? await HealthKitManager.shared.requestAuthorization()
                    await syncExistingData()
                }

                let goals = try await nutritionService.fetchAIGoals(userStats: userStats, userGoals: customGoal, baselineTdee: tdee)

                UserSettings.calorieGoal = goals.calories
                UserSettings.proteinGoal = goals.protein
                UserSettings.carbsGoal = goals.carbs
                UserSettings.fatGoal = goals.fat
                UserSettings.goalExplanation = goals.explanation

                isLoading = false
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func syncExistingData() async {
        let descriptor = FetchDescriptor<FoodItem>()
        if let items = try? modelContext.fetch(descriptor) {
            await HealthKitManager.shared.syncAllData(items: items)
            try? modelContext.save()
        }
    }

    private func shortActivityTitle(_ level: CalorieCalculator.ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Mostly still"
        case .lightlyActive: return "Lightly active"
        case .moderatelyActive: return "Steady movement"
        case .veryActive: return "Very active"
        case .extraActive: return "Athlete mode"
        }
    }

    private func activitySubtitle(_ level: CalorieCalculator.ActivityLevel) -> String {
        switch level {
        case .sedentary: return "Desk days, little planned exercise"
        case .lightlyActive: return "A few walks or workouts per week"
        case .moderatelyActive: return "Training or active work most days"
        case .veryActive: return "Hard sessions nearly every day"
        case .extraActive: return "Demanding training plus physical work"
        }
    }

    private func personalityTitle(_ level: UserSettings.CalorieCommentaryLevel) -> String {
        switch level {
        case .professional: return "Normal"
        case .sassy: return "Sassy"
        case .crazy: return "Crazy"
        }
    }

    private func personalitySubtitle(_ level: UserSettings.CalorieCommentaryLevel) -> String {
        switch level {
        case .professional: return "Clear, calm, useful feedback"
        case .sassy: return "Playful nudges with a little attitude"
        case .crazy: return "Unhinged roast energy, by choice"
        }
    }
}

private struct StepTitle: View {
    let title: String
    let subtitle: String

    init(_ title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 39, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.78)
            Text(subtitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .lineSpacing(3)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 26)
    }
}

private struct ChoiceButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.38))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(.white.opacity(isSelected ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(isSelected ? 0.28 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingBackdrop: View {
    let step: Int
    let accentColors: [Color]

    private var pageTint: Color {
        switch step {
        case 0: return Color(red: 0.72, green: 0.12, blue: 0.55)
        case 1: return Color(red: 0.18, green: 0.42, blue: 1.0)
        case 2: return Color(red: 0.05, green: 0.78, blue: 0.68)
        case 3: return Color(red: 0.92, green: 0.42, blue: 0.16)
        case 4: return Color(red: 0.45, green: 0.34, blue: 1.0)
        case 5: return Color(red: 0.12, green: 0.68, blue: 0.28)
        case 6: return Color(red: 0.93, green: 0.62, blue: 0.18)
        case 7: return accentColors.first ?? Color.blue
        default: return Color(red: 0.38, green: 0.32, blue: 1.0)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            LinearGradient(
                colors: [
                    .clear,
                    pageTint.opacity(0.24),
                    (accentColors.first ?? pageTint).opacity(0.72),
                    (accentColors.last ?? pageTint).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
            .blur(radius: 10)
            .offset(y: 18)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.65), value: step)
        }
    }
}

private enum OnboardingFocusField: Hashable {
    case goalNotes
    case customBaseURL
    case apiKey
    case modelName
    case blockRunEndpoint
    case blockRunWallet
    case serperKey
}

private enum HelpTopic: String, Identifiable {
    case openRouterKey
    case serperKey
    case baseUrl
    case apiKey
    case modelName
    case blockRun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openRouterKey: return "OpenRouter API Key"
        case .serperKey: return "Serper API Key"
        case .baseUrl: return "Base URL"
        case .apiKey: return "API Key"
        case .modelName: return "Model name"
        case .blockRun: return "BlockRun"
        }
    }

    var message: String {
        switch self {
        case .openRouterKey:
            return "Create or copy a key at openrouter.ai/keys. It usually starts with sk-or-."
        case .serperKey:
            return "Optional. Get it from serper.dev if you want web search grounding for harder food lookups."
        case .baseUrl:
            return "Use the OpenAI-compatible endpoint from your provider docs, usually ending in /v1."
        case .apiKey:
            return "Paste the secret key from your provider dashboard. Portio stores it in Keychain."
        case .modelName:
            return "Use the exact model id from your provider, like openai/gpt-oss-120b:free or gpt-4o."
        case .blockRun:
            return "BlockRun can use the built-in gateway defaults. Add your wallet key only if you have one."
        }
    }
}

private struct HelpSheet: View {
    let topic: HelpTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.blue)
            Text(topic.title)
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text(topic.message)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
            Spacer()
        }
        .padding(24)
    }
}

private extension View {
    @ViewBuilder
    func liquidGlassControl(isProminent: Bool) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                self
                    .background(.white.opacity(0.08), in: Capsule())
                    .glassEffect(.regular.tint(.white.opacity(0.20)).interactive(), in: Capsule())
            } else {
                self
                    .background(.white.opacity(0.06), in: Capsule())
                    .glassEffect(.regular.tint(.white.opacity(0.12)).interactive(), in: Capsule())
            }
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(isProminent ? 0.22 : 0.14), lineWidth: 1)
                )
        }
    }

    func fieldChrome() -> some View {
        self
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .tint(.white)
            .padding(16)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.11), lineWidth: 1)
            )
    }
}
