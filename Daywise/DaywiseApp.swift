//
//  DaywiseApp.swift
//  Daywise
//
//  Created by kok-s0s on 2026/5/26.
//

import SwiftUI
import SwiftData

@main
struct DaywiseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])

        // Try iCloud-backed store first; fall back to local if CloudKit is unavailable
        if let cloudConfig = try? ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        ), let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }

        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
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
