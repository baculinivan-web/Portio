import SwiftUI

struct ManualFoodEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var weightGrams = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @FocusState private var focusedField: Field?

    var onAdd: (ManualFoodEntry) -> Void

    private enum Field: Hashable {
        case name
        case weightGrams
        case calories
        case protein
        case carbs
        case fat
    }

    private var parsedEntry: ManualFoodEntry? {
        guard
            let weightGrams = parsedDouble(weightGrams),
            let calories = parsedDouble(calories),
            let protein = parsedDouble(protein),
            let carbs = parsedDouble(carbs),
            let fat = parsedDouble(fat)
        else { return nil }

        return ManualFoodEntry(
            name: name,
            weightGrams: weightGrams,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }

    private var entry: ManualFoodEntry? {
        guard let parsedEntry, parsedEntry.isValid else { return nil }
        return parsedEntry
    }

    private var validationMessage: String? {
        guard let parsedEntry else { return nil }

        if parsedEntry.weightGrams <= 0 {
            return "Weight must be above 0 g."
        }
        if parsedEntry.weightGrams > ManualFoodEntry.maxWeightGrams {
            return "Weight must be 10,000 g or less."
        }
        if parsedEntry.calories < 0 || parsedEntry.protein < 0 || parsedEntry.carbs < 0 || parsedEntry.fat < 0 {
            return "Nutrition values cannot be negative."
        }
        if parsedEntry.calories > ManualFoodEntry.maxCalories {
            return "Calories must be 10,000 kcal or less."
        }
        if parsedEntry.totalMacroGrams > parsedEntry.weightGrams {
            return "Protein, carbs, and fat cannot exceed the food weight."
        }

        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .weightGrams
                        }

                    nutrientField("Weight", value: $weightGrams, unit: "g", field: .weightGrams)
                }

                Section {
                    nutrientField("Calories", value: $calories, unit: "kcal", field: .calories)
                    nutrientField("Protein", value: $protein, unit: "g", field: .protein)
                    nutrientField("Carbs", value: $carbs, unit: "g", field: .carbs)
                    nutrientField("Fat", value: $fat, unit: "g", field: .fat)
                } header: {
                    Text("Nutrition")
                } footer: {
                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Log by Hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let entry else { return }
                        onAdd(entry)
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .disabled(entry == nil)
                }
            }
        }
    }

    private func nutrientField(_ title: String, value: Binding<String>, unit: String, field: Field) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 96)
                .focused($focusedField, equals: field)
                .submitLabel(field == .fat ? .done : .next)
                .onSubmit {
                    focusNextField()
                }
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
        }
    }

    private func parsedDouble(_ value: String) -> Double? {
        Double(value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }

    private func focusNextField() {
        switch focusedField {
        case .name:
            focusedField = .weightGrams
        case .weightGrams:
            focusedField = .calories
        case .calories:
            focusedField = .protein
        case .protein:
            focusedField = .carbs
        case .carbs:
            focusedField = .fat
        case .fat:
            focusedField = nil
        case nil:
            focusedField = .name
        }
    }
}
