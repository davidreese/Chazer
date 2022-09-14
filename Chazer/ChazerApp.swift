//
//  ChazerApp.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import SwiftUI

@main
struct ChazerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
