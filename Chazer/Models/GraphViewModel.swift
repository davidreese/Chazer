//
//  GraphViewModel.swift
//  Chazer
//
//  Created by David Reese on 9/19/22.
//

import Foundation

@MainActor
class GraphViewModel: ObservableObject {
    @Published var limud: Limud
    var scheduledChazaraToUpdate: ScheduledChazara?
    var sectionToUpdate: Section?
    
    init(limud: Limud) {
        self.limud = limud
    }
    
    /// Fetches an updated ``Limud`` object from storage and updates  the view using it.
    func updateLimud() {
        guard let newLimud = try? Storage.shared.fetchLimud(id: self.limud.id) else {
            fatalError()
        }
        
        self.limud = newLimud
    }
}
