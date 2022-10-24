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
    
    init() {
//        killScheduledChazara()
    }
    
    private func killScheduledChazara(id: ID? = nil) {
        //        MARK: SAVIOR CODE!
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
        if let id = id {
            fetchRequest.predicate = NSPredicate(format: "scId == %@", id)
        }
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try! persistenceController.container.viewContext.execute(deleteRequest)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
