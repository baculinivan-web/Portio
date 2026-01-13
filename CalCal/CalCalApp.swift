//
//  CalCalApp.swift
//  CalCal
//
//  Created by Иван on 12.10.2025.
//

import SwiftUI
import SwiftData

@main
struct CalCalApp: App {
    var sharedModelContainer: ModelContainer = SharedDataManager.shared.container

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
