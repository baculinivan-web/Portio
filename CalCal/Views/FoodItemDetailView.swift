import SwiftUI
import PhotosUI
import WidgetKit

struct FoodItemDetailView: View {
    @Bindable var item: FoodItem
    
    // State for the multi-image picker
    @State private var selectedPhotos: [PhotosPickerItem] = []
    // State for the full-screen image viewer
    @State private var selectedImageDataForViewer: Data?

    var body: some View {
        Form {
            Section("Photos") {
                if !item.imageDatas.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.imageDatas, id: \.self) { data in
                                ImageThumbnailView(imageData: data) {
                                    selectedImageDataForViewer = data
                                } deleteAction: {
                                    withAnimation {
                                        item.imageDatas.removeAll { $0 == data }
                                    }
                                }
                            }
                        }
                    }
                }
                
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    Text(item.imageDatas.isEmpty ? "Add Photos" : "Add More Photos")
                }
            }

            Section("Nutritional Information") {
                NutrientEditor(label: "Weight (g)", value: $item.weightGrams)
                NutrientEditor(label: "Calories (kcal)", value: $item.calories)
                NutrientEditor(label: "Protein (g)", value: $item.protein)
                NutrientEditor(label: "Carbs (g)", value: $item.carbs)
                NutrientEditor(label: "Fat (g)", value: $item.fat)
            }
            
            Section("Entry Info") {
                LabeledContent("Original Query", value: item.name)
                LabeledContent("Identified As", value: item.identifiedFood)
                LabeledContent("Logged At", value: item.dateEaten, format: .dateTime.hour().minute())
            }
        }
        .navigationTitle("Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: item.weightGrams) { _, _ in
            item.recalculateNutrients()
            try? item.modelContext?.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: item.calories) { _, _ in
            try? item.modelContext?.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: item.protein) { _, _ in
            try? item.modelContext?.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: item.carbs) { _, _ in
            try? item.modelContext?.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: item.fat) { _, _ in
            try? item.modelContext?.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: selectedPhotos) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        withAnimation { self.item.imageDatas.append(data) }
                    }
                }
                selectedPhotos = []
            }
        }
        .sheet(item: $selectedImageDataForViewer) { data in
            PhotoViewer(imageData: data)
        }
    }
}

// A view for the tappable thumbnail with a delete button
struct ImageThumbnailView: View {
    let imageData: Data
    var viewAction: () -> Void
    var deleteAction: () -> Void
    
    var body: some View {
        // Only create the view if the image data is valid
        if let uiImage = UIImage(data: imageData) {
            ZStack(alignment: .topTrailing) {
                Button(action: viewAction) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // The delete button is now inside the if-let block
                Button(action: deleteAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 2)
                }
                .offset(x: -6, y: 6)
            }
        }
    }
}

// A simple view to show the image full-screen
struct PhotoViewer: View {
    let imageData: Data
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Button("Done") { dismiss() }
                .padding()
                .background(.thinMaterial, in: Capsule())
                .padding()
        }
    }
}

struct NutrientEditor: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, value: $value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
        }
        .padding(.vertical, 4)
    }
}

// Make Data identifiable for the .sheet modifier
extension Data: Identifiable {
    public var id: Self { self }
}
