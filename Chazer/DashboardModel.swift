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
        load()
    }
    
    private func load() {
        let points = Storage.shared.getActiveAndLateChazaraPoints()
        
        activeChazaraPoints = points?.filter({ point in
            point.status == .active
        })

        lateChazaraPoints = points?.filter({ point in
            point.status == .late
        })
    }
}
