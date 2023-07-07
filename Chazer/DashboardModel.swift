//
//  DashboardModel.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation

class DashboardModel: ObservableObject {
    @Published var activeChazaraPoints: Set<ChazaraPoint>?
    @Published var lateChazaraPoints: Set<ChazaraPoint>?
    
    init() {
        Task {
            await load()
        }
    }
    
    private func load() async {
        guard let data = Storage.shared.getActiveAndLateChazaraPoints() else {
            return
        }
        activeChazaraPoints = data.active
        lateChazaraPoints = data.late
        
        if let activeChazaraPoints = activeChazaraPoints {
            for point in activeChazaraPoints {
                await point.getDueDate()
            }
        }
        
        if let lateChazaraPoints = lateChazaraPoints {
            for point in lateChazaraPoints {
                await point.getDueDate()
            }
        }
    }
}
