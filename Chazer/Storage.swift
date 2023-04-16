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
    private(set) var cdSections: [CDSection]?
    private(set) var scheduledChazaras: Set<ScheduledChazara>?
    private(set) var cdScheduledChazaras: [CDScheduledChazara]?
        private(set) var cdChazaraPoints: [CDChazaraPoint]?
        private(set) var chazaraPoints: Set<ChazaraPoint>?
    
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
            
            var scheduledChazaras = Set<ScheduledChazara>()
            for scResult in scResults {
                if let sc = ScheduledChazara(scResult) {
                    scheduledChazaras.update(with: sc)
                }
            }
            
            self.scheduledChazaras = scheduledChazaras
        } catch {
            print(error)
        }
    }
    
    func loadSections() {
        do {
            let secFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
            let secResults = try self.container.newBackgroundContext().fetch(secFetchRequest) as! [CDSection]
            
            self.cdSections = secResults
            
            var sections = Set<Section>()
            for secResult in secResults {
                if let sec = Section(secResult) {
                    sections.update(with: sec)
                }
            }
            
            self.sections = sections
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
    
    func getScheduledChazara(scId: ID, reloadIfNeeded: Bool = true) -> ScheduledChazara? {
        if let sc = self.scheduledChazaras?.first(where: { sc in
            sc.id == scId
        }) {
            return sc
        } else if reloadIfNeeded {
            loadScheduledChazaras()
            return getScheduledChazara(scId: scId, reloadIfNeeded: false)
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
    
    func getActiveCDChazaraPoints() -> [CDChazaraPoint]? {
        do {
            let fr = CDChazaraState.fetchRequest()
            
            fr.predicate = NSPredicate(format: "status == %i", 2)
            
            let cdStates = try container.newBackgroundContext().fetch(fr)
            
            var points: [CDChazaraPoint] = []
            for cdState in cdStates {
                if let cdPoint = cdState.chazaraPoint {
                    points.append(cdPoint)
                }
            }
            
            return points
        } catch {
            print("Error: Could not fetch active CDChazaraPoints, failed with \(error)")
            return nil
        }
    }
    
    func getActiveChazaraPoints() -> [ChazaraPoint]? {
        do {
            let fr = CDChazaraState.fetchRequest()
            
            fr.predicate = NSPredicate(format: "status == %i", 2)
            
            let cdStates = try container.newBackgroundContext().fetch(fr)
            
            var points: [ChazaraPoint] = []
            for cdState in cdStates {
                if let cdPoint = cdState.chazaraPoint, let point = ChazaraPoint(cdPoint) {
                    points.append(point)
                }
            }
            
            return points
        } catch {
            print("Error: Could not fetch active ChazaraPoints, failed with \(error)")
            return nil
        }
    }
    
    func getActiveAndLateCDChazaraPoints() -> [CDChazaraPoint]? {
        do {
            let fr = CDChazaraState.fetchRequest()
            
            fr.predicate = NSPredicate(format: "status == %i OR status == %i", 2, 3)
            
            let cdStates = try container.newBackgroundContext().fetch(fr)
            
            var points: [CDChazaraPoint] = []
            for cdState in cdStates {
                if let cdPoint = cdState.chazaraPoint {
                    points.append(cdPoint)
                }
            }
            
            return points
        } catch {
            print("Error: Could not fetch active/late CDChazaraPoints, failed with \(error)")
            return nil
        }
    }
    
    func getActiveAndLateChazaraPoints() -> Set<ChazaraPoint>? {
        do {
            let fr = CDChazaraState.fetchRequest()
            
            fr.predicate = NSPredicate(format: "status == %i OR status == %i", 2, 3)
            
            let cdStates = try container.newBackgroundContext().fetch(fr)
            
            var points = Set<ChazaraPoint>()
            for cdState in cdStates {
                if let cdPoint = cdState.chazaraPoint {
                    if let point = ChazaraPoint(cdPoint) {
                        points.update(with: point)
                    } else {
                        print("Warning: For an unknown reason, could not instansiate a ChazaraPoint for CDChazaraPoint (pointId=\(cdPoint.pointId ?? "nil"))")
                    }
                }
            }
            
            return points
        } catch {
            print("Error: Could not fetch active/late ChazaraPoints, failed with \(error)")
            return nil
        }
    }
}
