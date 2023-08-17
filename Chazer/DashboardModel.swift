//
//  DashboardModel.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation
import SwiftUI

class DashboardModel: ObservableObject {
    @Published var activeChazaraPoints: [ChazaraPoint]?
    @Published var lateChazaraPoints: [ChazaraPoint]?
    
    init() {
        Task {
            await Storage.shared.loadChazaraPoints()
            await update()
        }
        
        Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
            Task {
                await self.update()
            }
        }
    }
    
    /// Updates the dashboard to reflect the latest updated data saved in the database.
    func update() async {
        guard let data = Storage.shared.getActiveAndLateChazaraPoints() else {
            return
        }
        for point in data.active {
                await point.getDueDate()
            }
        
        
        for point in data.late {
                await point.getDueDate()
            }
        
                    await MainActor.run {
                        
                        
                        
                        self.activeChazaraPoints = data.active.sorted(by: { lhs, rhs in
                            if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                                return lhsDate < rhsDate
                            } else {
                                //                                    this isn't really supposed to occur
                                return true
                            }
                        })
            self.lateChazaraPoints = data.late.sorted(by: { lhs, rhs in
                if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                    return lhsDate < rhsDate
                } else {
                    //                                    this isn't really supposed to occur
                    return true
                }
            })
            
/*
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
        }*/
        }
    }
}
