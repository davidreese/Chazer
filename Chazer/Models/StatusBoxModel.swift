//
//  StatusBoxModel.swift
//  Chazer
//
//  Created by David Reese on 6/26/23.
//

import Foundation

@MainActor
class StatusBoxModel: ObservableObject {
    @Published var point: ChazaraPoint?
    
    init(section: Section, scheduledChazara: ScheduledChazara) {
        self.point = Storage.shared.getChazaraPoint(sectionId: section.id, scId: scheduledChazara.id, createNewIfNeeded: true)
    }
    
    init(point: ChazaraPoint) {
        self.point = point
    }
    
    /// The updated text that should be displayed on the ``StatusBox``.
    @Published private(set) var text: String?
    
    func getText() async -> String? {
        guard let point = point else {
            return nil
        }
        switch point.status ?? .unknown {
        case .early:
            return await point.getActiveDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? ""
        case .active:
            let dueDate = await point.getDueDate()
            return point.dueDate?.formatted(.dateTime.month(.abbreviated).day()) ?? "nil"
        case .late:
            return await point.getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "nil"
        case .completed:
            return point.getCompletionDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
        case .unknown:
            return nil
        case .exempt:
            return "Exempt"
        }
    }
    
    func updateText() {
        Task {
            let result = await getText()
                self.text = result
        }
    }
}
