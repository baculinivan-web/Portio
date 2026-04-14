import SwiftUI
import SwiftData

@main
struct PortioApp: App {
    var sharedModelContainer: ModelContainer = SharedDataManager.shared.container

    init() {
        BackgroundTaskManager.shared.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .defaultAppStorage(UserSettings.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
