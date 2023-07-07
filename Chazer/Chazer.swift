//
//  Chazer.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import Foundation

class Limud: Identifiable, Hashable {
    var id: ID
    var name: String
    var sections: Set<Section>
    var scheduledChazaras: [ScheduledChazara]
    
    
    init?(_ cdLimud: CDLimud) {
        guard let id = cdLimud.id, let name = cdLimud.name, let cdSections = cdLimud.sections?.allObjects as? [CDSection], let cdScheduledChazaras = cdLimud.scheduledChazaras?.array as? [CDScheduledChazara] else {
//            print("Failed to initalize CDLimud")
            return nil
        }
        
        self.id = id
        self.name = name
        
        var sections: Set<Section> = Set()
        for cdSection in cdSections {
            if let section = Section(cdSection) {
                sections.insert(section)
            } else {
                print("Failed to append section: \(cdSection)")
            }
        }
        
        var scheduledChazaras: [ScheduledChazara] = []
        for cdScheduledChazara in cdScheduledChazaras {
            if let scheduledChazara = ScheduledChazara(cdScheduledChazara) {
                scheduledChazaras.append(scheduledChazara)
            } else {
                print("Failed to append scheduled chazara: \(cdScheduledChazara)")
            }
        }
        
        self.sections = sections
        self.scheduledChazaras = scheduledChazaras
        
//        print("Initialized CDLimud")
    }
    
    static func == (lhs: Limud, rhs: Limud) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

class Section: Identifiable, Hashable {
    final let id: ID
    private(set) var name: String
    private(set) var initialDate: Date
    private(set) var limudId: ID
    
    init?(_ cdSection: CDSection) {
        guard let id = cdSection.sectionId, let name = cdSection.sectionName, let initalDate = cdSection.initialDate, let cdLimud = cdSection.limud, let limudId = cdLimud.id else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.initialDate = initalDate
        self.limudId = limudId
    }
    
    init?(_ nsSetSection: NSSet) {
        fatalError(nsSetSection.description)
    }
    
    func generatePoints() {
        print("This function has not yet been implemented.")
    }
    
    static func == (lhs: Section, rhs: Section) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(initialDate)
    }
}

class ScheduledChazara: Identifiable, Hashable {
    var id: ID
    var name: String
    var fixedDueDate: Date?
    
    /// The number of days after the initial learning date or the last chazara that the chazara is scheduled to occur
    var delay: Int?
    var delayedFrom: ScheduledChazara?
    
    /// The number of days after the dynamic start date that the chazara point should be marked active.
    var daysActive: Int?
//    var window: Int
    
    init(id: ID, name: String, due dueDate: Date) {
        self.id = id
        self.name = name
        self.fixedDueDate = dueDate
    }
    
    init(id: ID, name: String, delaySinceInitial: Int) {
        self.id = id
        self.name = name
        self.delay = delaySinceInitial
    }
    
    init(id: ID, name: String, delay: Int, since delayedFrom: ScheduledChazara) {
        self.id = id
        self.name = name
        self.delay = delay
        self.delayedFrom = delayedFrom
    }
    
    init(id: ID, delaySinceInitial: Int) {
        self.id = id
        self.name = "\(delayFormatted(delaySinceInitial)) Day Chazara"
        self.delay = delaySinceInitial
    }
    
    init(id: ID, delay: Int, since delayedFrom: ScheduledChazara?) {
        self.id = id
        self.name = "\(delayFormatted(delay)) Day Chazara"
        self.delay = delay
        self.delayedFrom = delayedFrom
    }
    
    init?(_ cdScheduledChazara: CDScheduledChazara) {
        guard let id = cdScheduledChazara.scId, let name = cdScheduledChazara.scName else {
            return nil
        }
        
        self.id = id
        self.name = name
        if let fixedDueDate = cdScheduledChazara.fixedDueDate {
            self.fixedDueDate = fixedDueDate
        } else {
            self.delay = Int(cdScheduledChazara.delay)
            if let cdDelayedFrom = cdScheduledChazara.delayedFrom {
                self.delayedFrom = ScheduledChazara(cdDelayedFrom)
            }
        }
    }
    
    static func == (lhs: ScheduledChazara, rhs: ScheduledChazara) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

func delayFormatted(_ delay: Int) -> String {
    return "\(delay)"
}

enum CreationError: Error {
    case invalidName
    case missingData
    case invalidData
    case unknownError
}

enum UpdateError: Error {
    /// Thrown when the submitted name is invalid.
    case invalidName
    
    /// Thrown when not all required data is submitted.
    case missingData
    
    /// Thrown when some of the data submitted is invalid.
    case invalidData
    
    case unknownError
}

enum DeletionError: Error {
    case unknownError
}
