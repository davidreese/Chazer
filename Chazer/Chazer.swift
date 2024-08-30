//
//  Chazer.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import Foundation
import CoreData

class Limud: Identifiable, Hashable {
    final var id: CID!
    var name: String!
    var sections: Set<Section>!
    var scheduledChazaras: [ScheduledChazara]!
    var isArchived: Bool!
    
    init(_ cdLimud: CDLimud, context: NSManagedObjectContext) throws {
        try context.performAndWait {
            guard let id = cdLimud.id, let name = cdLimud.name, let cdSections = cdLimud.sections?.allObjects as? [CDSection], let cdScheduledChazaras = cdLimud.scheduledChazaras?.array as? [CDScheduledChazara] else {
                //            print("Failed to initalize CDLimud")
                throw RetrievalError.missingData
            }
            
            self.id = id
            self.name = name
            self.isArchived = cdLimud.archived
            
            var sections: Set<Section> = Set()
            for cdSection in cdSections {
                if let section = try? Section(cdSection, context: context) {
                    sections.insert(section)
                } else {
                    print("Failed to append section: \(cdSection)")
                }
            }
            
            var scheduledChazaras: [ScheduledChazara] = []
            for cdScheduledChazara in cdScheduledChazaras {
                if let scheduledChazara = try? ScheduledChazara(cdScheduledChazara, context: context) {
                    scheduledChazaras.append(scheduledChazara)
                } else {
                    print("Failed to append scheduled chazara: \(cdScheduledChazara)")
                }
            }
            
            self.sections = sections
            self.scheduledChazaras = scheduledChazaras
            
            //        print("Initialized CDLimud")
        }
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
    final var id: CID!
    private(set) var name: String!
    private(set) var initialDate: Date!
    private(set) var limudId: String!
    
    init(_ cdSection: CDSection, context: NSManagedObjectContext) throws {
        
        try context.performAndWait {
            guard let id = cdSection.sectionId, let name = cdSection.sectionName, let initalDate = cdSection.initialDate, let cdLimud = cdSection.limud, let limudId = cdLimud.id else {
                throw RetrievalError.missingData
            }
            
            self.id = id
            self.name = name
            self.initialDate = initalDate
            self.limudId = limudId
        }
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
    final var id: CID!
    private(set) var name: String!
    private(set) var fixedDueDate: Date?
    
    /// The number of days after the initial learning date or the last chazara that the chazara is scheduled to occur
    private(set) var delay: Int?
    private(set) var delayedFrom: ScheduledChazara?
    
    /// The number of days after the dynamic start date that the chazara point should be marked active.
    private(set) var daysActive: Int?
//    var window: Int
    
    private(set) var hiddenFromDashboard: Bool = false
    
    private(set) var isDynamic: Bool!
    
    init(id: CID, name: String, due dueDate: Date) {
        self.id = id
        self.name = name
        self.fixedDueDate = dueDate
        self.isDynamic = false
    }
    
    init(id: CID, name: String, delaySinceInitial: Int) {
        self.id = id
        self.name = name
        self.delay = delaySinceInitial
        self.isDynamic = true
    }
    
    init(id: CID, name: String, delay: Int, since delayedFrom: ScheduledChazara) {
        self.id = id
        self.name = name
        self.delay = delay
        self.delayedFrom = delayedFrom
        self.isDynamic = true
    }
    
    init(id: CID, delaySinceInitial: Int) {
        self.id = id
        self.name = "\(delayFormatted(delaySinceInitial)) Day Chazara"
        self.delay = delaySinceInitial
        self.isDynamic = true
    }
    
    init(id: CID, delay: Int, since delayedFrom: ScheduledChazara?) {
        self.id = id
        self.name = "\(delayFormatted(delay)) Day Chazara"
        self.delay = delay
        self.delayedFrom = delayedFrom
        self.isDynamic = true
    }
    
    init(_ cdScheduledChazara: CDScheduledChazara, context: NSManagedObjectContext) throws {
        
        try context.performAndWait {
            guard let id = cdScheduledChazara.scId, let name = cdScheduledChazara.scName else {
                throw RetrievalError.missingData
            }
            
            self.id = id
            self.name = name
            
            if let fixedDueDate = cdScheduledChazara.fixedDueDate {
                self.fixedDueDate = fixedDueDate
                self.isDynamic = false
            } else {
                self.delay = Int(cdScheduledChazara.delay)
                
                if let cdDelayedFrom = cdScheduledChazara.delayedFrom {
                    self.delayedFrom = try ScheduledChazara(cdDelayedFrom, context: context)
                }
                
                self.daysActive = Int(cdScheduledChazara.daysToComplete)
                
                
                self.isDynamic = true
            }
            
            self.hiddenFromDashboard = cdScheduledChazara.hiddenFromDashboard
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

enum RetrievalError: Error {
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
