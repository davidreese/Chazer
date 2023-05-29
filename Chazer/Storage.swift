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
    
    private(set) var sections: Set<Section>?
    private(set) var cdSections: Set<CDSection>?
    private(set) var scheduledChazaras: [ScheduledChazara]?
    private(set) var cdScheduledChazaras: [CDScheduledChazara]?
    private(set) var cdChazaraPointsDictionary: [ID: CDChazaraPoint]?
    private(set) var chazaraPointsDictionary: [ID: ChazaraPoint]?
    
    init(container: NSPersistentContainer) {
        self.container = container
        
        update()
    }
    
    func update() {
        print("Loading storage...")
        
        loadScheduledChazaras()
        loadSections()
        loadChazaraPoints()
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
        print("Loading sections...")
            do {
                let scFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
                let secResults = try self.container.newBackgroundContext().fetch(scFetchRequest) as! [CDSection]
                
                self.cdSections = Set<CDSection>(secResults)
                
                self.sections = nil
                
                for secResult in secResults {
                    if let sec = Section(secResult) {
                        if self.sections == nil {
                            self.sections = [sec]
                        } else {
                            self.sections?.insert(sec)
                        }
                    }
                }
            } catch {
                print(error)
            }
    }
    
    func loadChazaraPoints() {
            do {
                let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
                let cpResults = try self.container.newBackgroundContext().fetch(cpFetchRequest) as! [CDChazaraPoint]
                
                for cpResult in cpResults {
                    guard let pointId = cpResult.pointId else {
                        continue
                    }
                    if self.cdChazaraPointsDictionary == nil {
                        self.cdChazaraPointsDictionary = [pointId : cpResult]
                    } else {
                        self.cdChazaraPointsDictionary![pointId] = cpResult
                    }
                }
                
                self.chazaraPointsDictionary = nil
                
                for cpResult in cpResults {
                    if let cp = ChazaraPoint(cpResult) {
                        if self.chazaraPointsDictionary == nil {
                            self.chazaraPointsDictionary = [cp.id : cp]
                        } else {
                            self.chazaraPointsDictionary![cp.id] = cp
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
    
    /// Wipes CoreData for entities ``CDLimud``, ``CDSection``, ``CDScheduledChazara``, ``CDChazaraPoint``, and ``CDChazaraState``.
     func wipe() throws {
        print("Wiping data...")
        let entities = ["CDLimud", "CDSection", "CDScheduledChazara", "CDChazaraPoint", "CDChazaraState"]
            
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                let context = container.newBackgroundContext()
                try context.execute(batchDeleteRequest)
                try context.save()
                
                update()
            } catch let error as NSError {
                print("Could not wipe Core Data, failed on run for \(entityName). \(error), \(error.userInfo)")
                throw StorageError.wipeFailure
            }
        }
    }
}

enum StorageError: Error {
    case wipeFailure
}
