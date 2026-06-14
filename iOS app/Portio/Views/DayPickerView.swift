import SwiftUI

struct DayPickerView: View {
    @Binding var selectedDate: Date
    let datesWithEntries: Set<Date>

    @Environment(\.dismiss) private var dismiss

    init(selectedDate: Binding<Date>, datesWithEntries: Set<Date>) {
        _selectedDate = selectedDate
        self.datesWithEntries = datesWithEntries
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "Selected date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal)
            .navigationTitle("Choose Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if !FoodItemDaySelection.isToday(selectedDate) {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Today") {
                            selectedDate = .now
                        }
                    }
                }
            }
        }
    }
}
