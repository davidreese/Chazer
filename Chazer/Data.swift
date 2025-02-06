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
    
    /// The rule which defines when points are to be chazered.
    private(set) var scheduleRule: ScheduleRule!
    
    /// The ``ScheduledChazara`` that this schedule is delayed from, if this schedule is using a delay rule.
    /// - Note: Value will be `nil` if the schedule is not using a horizontal delay rule.
    private(set) var delayedFrom: ScheduledChazara?
    
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
        self.scheduleRule = .horizontalDelay(delayedFromID: nil, daysDelayed: delaySinceInitial, daysActive: daysActive)
    }
    
    init(id: CID, name: String, delay: Int, since delayedFrom: ScheduledChazara, daysActive: Int = 2) {
        self.id = id
        self.name = name
        self.delayedFrom = delayedFrom
        self.scheduleRule = .horizontalDelay(delayedFromID: delayedFrom.id, daysDelayed: delay, daysActive: daysActive)
    }
    
    init(id: CID, delaySinceInitial: Int, daysActive: Int = 2) {
        self.id = id
        self.name = "\(delayFormatted(delaySinceInitial)) Day Chazara"
        self.scheduleRule = .horizontalDelay(delayedFromID: nil, daysDelayed: delaySinceInitial, daysActive: daysActive)
    }
    
    init(id: CID, delay: Int, since delayedFrom: ScheduledChazara?, daysActive: Int = 2) {
        self.id = id
        self.name = "\(delayFormatted(delay)) Day Chazara"
        self.delayedFrom = delayedFrom
        self.scheduleRule = .horizontalDelay(delayedFromID: delayedFrom?.id, daysDelayed: delay, daysActive: daysActive)
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
            
            guard let ruleString = cdScheduledChazara.rule else {
                throw RetrievalError.missingData
            }
            
            self.scheduleRule = try ScheduleRule(ruleFromDatabase: ruleString)
            
            if let cdDelayedFrom = cdScheduledChazara.delayedFrom {
                let delayedFrom = try ScheduledChazara(cdDelayedFrom, context: context)
                
                self.delayedFrom = delayedFrom
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
//    case horizontalDelay(delayedFrom: ScheduledChazara?, daysDelayed: Int, daysActive: Int)
    
    /// A rule which sets all points on the schedule to be due a set amount of days after the completion of that point's section on the previous schedule.
    /// - Note: `delayedFromID` should be set to `nil` if the schedule is to be delayed after the initial learning of each section.
    case horizontalDelay(delayedFromID: CID?, daysDelayed: Int, daysActive: Int)
    
    /// A rule which sets all points on the schedule to be due after a set amount of sections have had their initial learning logged afterwards.
    case verticalDelay(sectionsDelay: Int, daysActive: Int, maxDaysActive: Int?)
    
    init(ruleFromDatabase: String) throws {
        if ruleFromDatabase == "NORULE" {
            throw RetrievalError.missingData
        }
        
        guard let first = ruleFromDatabase.first else {
            throw RetrievalError.invalidData
        }
        
        let ruleComponents = ruleFromDatabase.split(separator: ":")
        
        switch first {
        case "H":
            guard ruleComponents.count == 4 else {
                throw RetrievalError.invalidData
            }
            
            let delayedFromIDUncleaned = String(ruleComponents[1])
            assert(delayedFromIDUncleaned.starts(with: "DF"))
            
//            dealing with prefix of DF
            let delayedFromIDIndex = delayedFromIDUncleaned.index(delayedFromIDUncleaned.startIndex, offsetBy: 2)
            let delayedFromIDCleaned = delayedFromIDUncleaned[delayedFromIDIndex...]
            
            var delayedFromID: CID? = String(delayedFromIDCleaned)
            
            if delayedFromID == "INITIAL" {
                delayedFromID = nil
            } else {
//                #if DEBUG
                guard let delayedFromID = delayedFromID else {
                    assertionFailure(#function + ": unexpected delayedFromID \(delayedFromIDUncleaned)")
                    throw RetrievalError.invalidData
                }
                assert(delayedFromID.starts(with: "SC"))
//                #endif
            }
            
            let delayUncleaned = ruleComponents[2]
//            dealing with prefix of DL
            let delayIndex = delayUncleaned.index(delayUncleaned.startIndex, offsetBy: 2)
            let delay = delayUncleaned[delayIndex...]
            
            guard let delay = Int(delay) else {
                throw RetrievalError.invalidData
            }
            
            let daysActiveUncleaned = ruleComponents[3]
            // dealing with prefix of DTC
            let daysActiveIndex = daysActiveUncleaned.index(daysActiveUncleaned.startIndex, offsetBy: 3)
            let daysActive = daysActiveUncleaned[daysActiveIndex...]
            
            guard let daysActive = Int(daysActive) else {
                throw RetrievalError.invalidData
            }
            
            self = .horizontalDelay(delayedFromID: delayedFromID, daysDelayed: delay, daysActive: daysActive)
            return
        case "V":
            guard ruleComponents.count == 4 else {
                throw RetrievalError.invalidData
            }
            
            let delayedFromIDUncleaned = String(ruleComponents[1])
            assert(delayedFromIDUncleaned.starts(with: "SC"))
            
//            dealing with prefix of DF
            let delayedFromIDIndex = delayedFromIDUncleaned.index(delayedFromIDUncleaned.startIndex, offsetBy: 2)
            var delayedFromID: CID? = CID(delayedFromIDUncleaned[delayedFromIDIndex...])
            if delayedFromID == "INITIAL" {
                delayedFromID = nil
            } else {
                assert(!delayedFromID!.starts(with: "SC"))
            }
            
            
            
            let delayUncleaned = ruleComponents[2]
//            dealing with prefix of DL
            let delayIndex = delayUncleaned.index(delayUncleaned.startIndex, offsetBy: 2)
            let delay = delayUncleaned[delayIndex...]
            
            guard let delay = Int(delay) else {
                throw RetrievalError.invalidData
            }
            
            let daysActiveUncleaned = ruleComponents[3]
            // dealing with prefix of DTC
            let daysActiveIndex = daysActiveUncleaned.index(daysActiveUncleaned.startIndex, offsetBy: 3)
            let daysActive = daysActiveUncleaned[daysActiveIndex...]
            
            guard let daysActive = Int(daysActive) else {
                throw RetrievalError.invalidData
            }
            
            self = .horizontalDelay(delayedFromID: delayedFromID, daysDelayed: delay, daysActive: daysActive)
            return
        case "F":
            guard ruleComponents.count == 2 else {
                throw RetrievalError.invalidData
            }
            
            let fixedDateUncleaned = String(ruleComponents[1])
            assert(fixedDateUncleaned.starts(with: "FD"))
//            dealing with prefix of DF
            let fixedDateUncleanedIndex = fixedDateUncleaned.index(fixedDateUncleaned.startIndex, offsetBy: 2)
            let fixedDate = fixedDateUncleaned[fixedDateUncleanedIndex...]
            
            guard let timeIntervalSince1970 = TimeInterval(fixedDate) else {
                throw RetrievalError.invalidData
            }
            
            let date = Date(timeIntervalSince1970: timeIntervalSince1970)
            
            self = .fixedDueDate(date)
            return
        default:
            print("Error: unrecognized schedule rule format: \(ruleFromDatabase)")
            throw RetrievalError.invalidData
        }
    }
    
    func ruleForDatabase() -> String {
        switch self {
        case .horizontalDelay(let delayedFromID, let delay, let daysActive):
            return "H:DF\(delayedFromID ?? "INITIAL"):DL\(delay):DTC\(daysActive)"
        case .verticalDelay(let sectionsDelay, let daysActive, let maxDaysActive):
            return "V:SD\(sectionsDelay):DTC\(daysActive):MAX\(maxDaysActive?.description ?? "NIL")"
        case .fixedDueDate(let date):
            return "F:FD\(date.timeIntervalSince1970)"
        }
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
