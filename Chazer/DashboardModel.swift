//
//  DashboardModel.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation
import SwiftUI

class DashboardModel: ObservableObject {
    @Published var activeChazaraPoints: Set<ChazaraPoint>?
    @Published var lateChazaraPoints: Set<ChazaraPoint>?
    
    init() {
        Task {
            await update()
        }
    }
    
    func update() async {
        guard let data = Storage.shared.getActiveAndLateChazaraPoints() else {
            return
        }
//        DispatchQueue.main.async {
                    await MainActor.run {
//                        withAnimation {
            self.activeChazaraPoints = data.active
            self.lateChazaraPoints = data.late
            
//        }
        Task {
            if let activeChazaraPoints = self.activeChazaraPoints {
                for point in activeChazaraPoints {
                    await point.getDueDate()
                }
            }
            
            if let lateChazaraPoints = self.lateChazaraPoints {
                for point in lateChazaraPoints {
                    await point.getDueDate()
                }
            }
            self.objectWillChange.send()
        }
        }
                
//            }
//        }
        
        
    }
}
