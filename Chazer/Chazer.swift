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
    
//    init() {
//        self.id = ""
//        self.name = ""
//        self.sections = []
//        self.scheduledChazaras = []
//    }
    
    init(id: ID, name: String, sections: Set<Section>, scheduledChazaras: [ScheduledChazara]) {
        self.id = id
        self.name = name
        self.sections = sections
        self.scheduledChazaras = scheduledChazaras
    }
    
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
    
//    func save(name: String) {
//      guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
//          return
//      }
//      
//      let managedContext = delegate.persistentContainer.viewContext
//      
////      let entity = 
//      
//      let person = NSManagedObject(entity: entity,
//                                   insertInto: managedContext)
//      
//      // 3
//      person.setValue(name, forKeyPath: "name")
//      
//      // 4
//      do {
//        try managedContext.save()
//        people.append(person)
//      } catch let error as NSError {
//        print("Could not save. \(error), \(error.userInfo)")
//      }
//    }
    
    static func == (lhs: Limud, rhs: Limud) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

class Section: Identifiable, Hashable {
    var id: ID
    var name: String
    var initialDate: Date
    
    init(id: ID, name: String, initialDate: Date) {
        self.id = id
        self.name = name
        self.initialDate = initialDate
    }
    
    init?(_ cdSection: CDSection) {
        guard let id = cdSection.sectionId, let name = cdSection.sectionName, let initalDate = cdSection.initialDate else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.initialDate = initalDate
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

class Shiur: Section {
    init(id: ID, shiurNumber: Int, initialDate: Date) {
        super.init(id: id, name: "Shiur #\(shiurNumber)", initialDate: initialDate)
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
    
//    enum DelayType {
//        case sinceInitial
//        case sinceLast
//    }
}

/*
class Chazara: Identifiable {
    var id: ID
    var date: Date
    var sectionId: ID
    var scId: ID
    
    init(id: ID, date: Date, sectionId: ID, scId: ID) {
        self.id = id
        self.date = date
        self.sectionId = sectionId
        self.scId = scId
    }
    
    init?(_ cdChazara: CDChazara) {
        guard let id = cdChazara.id, let date = cdChazara.date, let sectionId = cdChazara.sectionId, let scId = cdChazara.scId else {
            return nil
        }
        
        self.id = id
        self.date = date
        self.sectionId = sectionId
        self.scId = scId
    }
}
*/

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
    case invalidName
    case missingData
    case invalidData
    case unknownError
}

enum DeletionError: Error {
    case unknownError
}
