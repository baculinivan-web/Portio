//
//  PortioApp.swift
//  Portio
//
//  Created by Иван on 12.10.2025.
//

import SwiftUI
import SwiftData

@main
struct PortioApp: App {
    var sharedModelContainer: ModelContainer = SharedDataManager.shared.container

    var body: some Scene {
        WindowGroup {
            ContentView()
                .defaultAppStorage(UserSettings.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
