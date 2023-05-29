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
    @Published var scheduledChazaraToUpdate: ScheduledChazara?
    @Published var sectionToUpdate: Section?
    
    init(limud: Limud) {
        self.limud = limud
    }
}
