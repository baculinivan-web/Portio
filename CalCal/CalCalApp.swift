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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodItem.self,
        ])
        
        let modelConfiguration: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ivan.CalCal") {
            let sqliteURL = groupURL.appendingPathComponent("default.store")
            modelConfiguration = ModelConfiguration(schema: schema, url: sqliteURL)
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
