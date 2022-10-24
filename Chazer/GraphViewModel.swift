//
//  GraphViewModel.swift
//  Chazer
//
//  Created by David Reese on 9/19/22.
//

import Foundation

class GraphViewModel: ObservableObject {
    @Published var limud: Limud
    @Published var scheduledChazaraToUpdate: ScheduledChazara?
    
    init(limud: Limud) {
        self.limud = limud
    }
}
