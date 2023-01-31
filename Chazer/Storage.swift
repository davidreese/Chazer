//
//  Storage.swift
//  Chazer
//
//  Created by David Reese on 1/25/23.
//

import Foundation
import CoreData

class Storage {
    static let shared = Storage(container: PersistenceController.shared.container)
    
    private var container: NSPersistentContainer
    
    private(set) var sections: [Section]?
    private(set) var cdSections: [CDSection]?
    private(set) var scheduledChazaras: [ScheduledChazara]?
    private(set) var cdScheduledChazaras: [CDScheduledChazara]?
//    private(set) var cdChazaraPoints: [CDChazaraPoint]?
//    private(set) var chazaraPoints: [ChazaraPoint]?
    
    init(container: NSPersistentContainer) {
        self.container = container
        
        update()
    }
    
    func update() {
        print("Loading storage...")
        
        loadScheduledChazaras()
        loadSections()
    }
    
    func loadScheduledChazaras() {
            do {
                let scFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
                let scResults = try self.container.newBackgroundContext().fetch(scFetchRequest) as! [CDScheduledChazara]
                
                self.cdScheduledChazaras = scResults
                
                self.scheduledChazaras = nil
                
                for scResult in scResults {
                    if let sc = ScheduledChazara(scResult) {
                        if self.scheduledChazaras == nil {
                            self.scheduledChazaras = [sc]
                        } else {
                            self.scheduledChazaras?.append(sc)
                        }
                    }
                }
            } catch {
                print(error)
            }
    }
    
    func loadSections() {
            do {
                let scFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
                let secResults = try self.container.newBackgroundContext().fetch(scFetchRequest) as! [CDSection]
                
                self.cdSections = secResults
                
                self.sections = nil
                
                for secResult in secResults {
                    if let sec = Section(secResult) {
                        if self.sections == nil {
                            self.sections = [sec]
                        } else {
                            self.sections?.append(sec)
                        }
                    }
                }
            } catch {
                print(error)
            }
    }
    
    func getCDSection(cdSectionId: ID, reloadIfNeeded: Bool = true) -> CDSection? {
        if let cdSection = self.cdSections?.first(where: { cdSection in
            cdSection.sectionId == cdSectionId
        }) {
            return cdSection
        } else if reloadIfNeeded {
            loadSections()
            return getCDSection(cdSectionId: cdSectionId, reloadIfNeeded: false)
        } else {
            return nil
        }
    }
    
    func getSection(sectionId: ID, reloadIfNeeded: Bool = true) -> Section? {
        if let section = self.sections?.first(where: { section in
            section.id == sectionId
        }) {
            return section
        } else if reloadIfNeeded {
            loadSections()
            return getSection(sectionId: sectionId, reloadIfNeeded: false)
        } else {
            return nil
        }
    }
    
    /*
    func getSection(sectionId: ID, reloadIfNeeded: Bool = true) async -> Section? {
        if let section = self.sections?.first(where: { sec in
            sec.id == sectionId
        }) {
            return section
        } else if reloadIfNeeded {
            await loadSections()
            return await getSection(sectionId: sectionId, reloadIfNeeded: false)
        } else {
            return nil
        }
    }
     */
    
    func getCDScheduledChazara(cdSCId: ID, reloadIfNeeded: Bool = true) -> CDScheduledChazara? {
        if let cdSC = self.cdScheduledChazaras?.first(where: { cdsc in
            cdsc.scId == cdSCId
        }) {
            return cdSC
        } else if reloadIfNeeded {
            loadScheduledChazaras()
            return getCDScheduledChazara(cdSCId: cdSCId, reloadIfNeeded: false)
        } else {
            return nil
        }
    }
    
    /*
    func getCDChazaraPoint(id: ID) async -> ChazaraPoint {
        do {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
            let results = try self.container.newBackgroundContext().fetch(fetchRequest) as! [CDChazaraPoint]
            
        } catch {
            print("Failed to update sections: \(error)")
        }
    }*/
    
    func getCDChazaraPoint(sectionId: ID, scId: ID) -> CDChazaraPoint? {
        let fr: NSFetchRequest<CDChazaraPoint> = CDChazaraPoint.fetchRequest()
        
        let sectionPredicate = NSPredicate(format: "scId = %@", scId)
        let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", sectionId)
        let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
        
        fr.predicate = compound
        
        let chazaraPoints: [CDChazaraPoint] = try! container.newBackgroundContext().fetch(fr)
        
        if chazaraPoints.count == 1 {
            guard let result = chazaraPoints.first else {
                print("Error: Could not get chazara point. (SECID=\(sectionId) SCID=\(scId))")
                return nil
            }
            return result
        } else if chazaraPoints.count > 1 {
            print("Error: More than one chazara point (\(chazaraPoints.count)) found. (SECID=\(sectionId) SCID=\(scId))")
            return nil
        } else {
            print("Error: Could not find chazara point. (SECID=\(sectionId) SCID=\(scId))")
            return nil
        }
    }
}
