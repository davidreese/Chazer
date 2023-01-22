//
//  DashboardModel.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation

class DashboardModel: ObservableObject {
    @Published var activeChazaraPoints: [ChazaraPoint]?
    @Published var lateChazaraPoints: [ChazaraPoint]?
    
    init() {
//        load()
    }
    
    private func load() {
//        let fetchRequest =
//        PersistenceController.shared.container.viewContext.fetch(<#T##request: NSFetchRequest<NSFetchRequestResult>##NSFetchRequest<NSFetchRequestResult>#>)
    }
}
