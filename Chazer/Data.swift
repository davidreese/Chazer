//
//  Data.swift
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
    
    /// The due date for every point on this schedule, if there is a fixed due date.
    /// - Note: Value will be `nil` if the schedule is not using a fixed due date.
    //private(set) var fixedDueDate: Date?
    
    /// The number of days after the initial learning date or the last chazara that the chazara is scheduled to occur, if this schedule is using a delay rule.
    /// - Note: Value will be `nil` if the schedule is not using a delay rule.
    //private(set) var delay: Int?
    
    /// The ``ScheduledChazara`` that this schedule is delayed from, if this schedule is using a delay rule.
    /// - Note: Value will be `nil` if the schedule is not using a delay rule.
    //private(set) var delayedFrom: ScheduledChazara?
    
    /// The rule which defines when points are to be chazered.
    private(set) var scheduleRule: ScheduleRule!
    
    /// The number of days after the dynamic start date that the chazara point should be marked active.
    /// - Note: Value will be `nil` if there is no dynamic rule in place.
    //private(set) var daysActive: Int?
    
    /// Marks whether points on this schedule should be hidden from the dashboard when they are active/late.
    private(set) var hiddenFromDashboard: Bool = false
    
    //private(set) var isDynamic: Bool!
    
    init(id: CID, name: String, due dueDate: Date) {
        self.id = id
        self.name = name
        self.scheduleRule = .fixedDueDate(dueDate)
    }
    
    init(id: CID, name: String, delaySinceInitial: Int, daysActive: Int = 2) {
        self.id = id
        self.name = name
        self.scheduleRule = .horizontalDelay(delayedFrom: nil, daysDelayed: delaySinceInitial, daysActive: daysActive)
    }
    
    init(id: CID, name: String, delay: Int, since delayedFrom: ScheduledChazara, daysActive: Int = 2) {
        self.id = id
        self.name = name
        self.scheduleRule = .horizontalDelay(delayedFrom: delayedFrom, daysDelayed: delay, daysActive: daysActive)
    }
    
    init(id: CID, delaySinceInitial: Int, daysActive: Int = 2) {
        self.id = id
        self.name = "\(delayFormatted(delaySinceInitial)) Day Chazara"
        self.scheduleRule = .horizontalDelay(delayedFrom: nil, daysDelayed: delaySinceInitial, daysActive: daysActive)
    }
    
    init(id: CID, delay: Int, since delayedFrom: ScheduledChazara?, daysActive: Int = 2) {
        self.id = id
        self.name = "\(delayFormatted(delay)) Day Chazara"
        self.scheduleRule = .horizontalDelay(delayedFrom: delayedFrom, daysDelayed: delay, daysActive: daysActive)
    }
    
    init(id: CID, sectionsDelay: Int, daysActive: Int = 2, maxDaysActive: Int? = 10) {
        self.id = id
        self.name = "\(delayFormatted(sectionsDelay)) Delay Chazara"
        self.scheduleRule = .verticalDelay(sectionsDelay: sectionsDelay, daysActive: daysActive, maxDaysActive: maxDaysActive)
    }
    
    init(_ cdScheduledChazara: CDScheduledChazara, context: NSManagedObjectContext) throws {
        try context.performAndWait {
            guard let id = cdScheduledChazara.scId, let name = cdScheduledChazara.scName else {
                throw RetrievalError.missingData
            }
            
            self.id = id
            self.name = name
            
            if let fixedDueDate = cdScheduledChazara.fixedDueDate, !cdScheduledChazara.isDynamic {
                self.scheduleRule = .fixedDueDate(fixedDueDate)
            } else {
                let daysActive = Int(cdScheduledChazara.daysToComplete)
                
                let delay = Int(cdScheduledChazara.delay)
                
                if let cdDelayedFrom = cdScheduledChazara.delayedFrom {
                    let delayedFrom = try ScheduledChazara(cdDelayedFrom, context: context)
                    
                    self.scheduleRule = .horizontalDelay(delayedFrom: delayedFrom, daysDelayed: delay, daysActive: daysActive)
                } else {
                    self.scheduleRule = .horizontalDelay(delayedFrom: nil, daysDelayed: delay, daysActive: daysActive)
                }
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

enum ScheduleRule: Equatable {
    /// A rule which sets all points on the schedule to be due on a certain date, and active for all dates before it.
    case fixedDueDate(Date)
    
    /// A rule which sets all points on the schedule to be due a set amount of days after the completion of that point's section on the previous schedule.
    /// - Note: `delayedFrom` should be set to `nil` if the schedule is to be delayed after the initial learning of each section.
    case horizontalDelay(delayedFrom: ScheduledChazara?, daysDelayed: Int, daysActive: Int)
    
    /// A rule which sets all points on the schedule to be due after a set amount of sections have had their initial learning logged afterwards.
    case verticalDelay(sectionsDelay: Int, daysActive: Int, maxDaysActive: Int?)
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
