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
    }
    
    func update() {
        print("Loading storage...")
        
        loadScheduledChazarasSynchronously()
        loadSectionsSynchronously()
        loadChazaraPointsSynchronously()
    }
    
    func loadScheduledChazarasSynchronously() {
        print("Loading scheduled chazaras synchronously...")
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
    
    func loadScheduledChazaras() async {
        print("Loading scheduled chazaras asynchronously...")
        do {
            let scFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
            
            let scResults = try self.container.newBackgroundContext().fetch(scFetchRequest) as! [CDScheduledChazara]
            
            await MainActor.run {
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
            }
        } catch {
            print(error)
        }
    }
    
    func loadSections() async {
        print("Loading sections asynchronously...")
        do {
            let scFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
            
            /*
             var secResults: [CDSection]
            try await self.container.performBackgroundTask({ context in
                secResults = try context.fetch(scFetchRequest) as! [CDSection]
            })*/
            let secResults = try self.container.newBackgroundContext().fetch(scFetchRequest) as! [CDSection]
            
            await MainActor.run {
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
            }
        } catch {
            print(error)
        }
    }
    
    func loadSectionsSynchronously() {
        print("Loading sections synchronously...")
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
    
//    var isLoadingChazaraPoints = false
    
    func loadChazaraPoints() async {
//        return
        /*if isLoadingChazaraPoints {
            return
        } else {
            isLoadingChazaraPoints = true
        }*/
        
        print("Loading chazara points asynchronously...")
        
        do {
            let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
             let cpResults = try  self.container.newBackgroundContext().fetch(cpFetchRequest) as! [CDChazaraPoint]
                
            await MainActor.run {
                for cpResult in cpResults {
                    guard let pointId = cpResult.pointId else {
                        print("Error: Couldn't find pointId on CDChazaraPoint.")
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
                    } else {
                        print("\(cpResult.pointId ?? "nil") \(cpResult.sectionId ?? "nil")")
                    }
                }
            }
            
            /*
            try await self.container.performBackgroundTask({ context in
                let cpResults = try context.fetch(cpFetchRequest) as! [CDChazaraPoint]
                
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
            })
             */
        } catch {
            print(error)
        }
        
//        isLoadingChazaraPoints = false
    }
    
    func loadChazaraPointsSynchronously() {
        print("Loading chazara points synchronously...")
        
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
    
    /// Returns the requested ``CDSection`` from local storage without fetching from the database.
    /// - Note: This function will search the database for this section if it cannot be found here. In such a case, it will also asynchronously update the entire sections storage to match the database.
    func getCDSection(cdSectionId: ID) -> CDSection? {
        if let cdSection = self.cdSections?.first(where: { cdSection in
            cdSection.sectionId == cdSectionId
        }) {
            return cdSection
        } else {
            //TODO: Make all the functions here work like this
            if let cdSection = pinCDSection(id: cdSectionId) {
//                Task {
//                    await loadSections()
//                }
                
                return cdSection
            } else {
                return nil
            }
        }
    }
    
    func getSection(sectionId: ID) -> Section? {
        if let section = self.sections?.first(where: { section in
            section.id == sectionId
        }) {
            return section
        } else {
            //TODO: Make all the functions here work like this
            if let cdSection = pinCDSection(id: sectionId) {
                Task {
                    await loadSections()
                }
                if let section = Section(cdSection) {
                    return section
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    /// Fetches this ``Section`` data from the database and updates it here, or adds it if it has not been found in storage yet.
    func updateSection(sectionId: ID) -> Section? {
        guard let cdSection = pinCDSection(id: sectionId) else {
            print("Couldn't update section, not found in database (SECID=\(sectionId))")
            
//            removing from local storage if it exists
            if let cdSection = self.cdSections?.first(where: { cdSection in
                cdSection.sectionId == sectionId
            }) {
                cdSections?.remove(cdSection)
            }
            
            return nil
        }
        
        if let cdSection = self.cdSections?.first(where: { cdSection in
            cdSection.sectionId == sectionId
        }) {
            cdSections?.remove(cdSection)
        }
        
        cdSections?.update(with: cdSection)
        
        guard let section = Section(cdSection) else {
            print("Couldn't return section (SECID=\(sectionId)), not valid")
            return nil
        }
        
        return section
    }
    
    /// Find and return this exact ``CDSection`` in the data store without doing a full load.
    private func pinCDSection(id: ID) -> CDSection? {
        do {
            let request = CDSection.fetchRequest()
            request.predicate = NSPredicate(format: "sectionId == %@", id)
            
            let results = try self.container.newBackgroundContext().fetch(request)
            
            if results.count == 1 {
                return results.first
            } else if results.count > 1 {
                print("Error: Something went wrong in pinning down the CDSection, there is more than one match. Returning nil")
                return nil
            } else {
                return nil
            }
        } catch {
            print("Error: Failed to query to pin down a CDSection: (sectionId=\(id))")
            return nil
        }
    }
    
    /// Returns the requested ``CDScheduledChazara`` from local storage without fetching from the database.
    /// - Note: This function will search the database for this section if it cannot be found here. In such a case, it will also asynchronously update the entire scheduled chazara storage to match the database.
    func getCDScheduledChazara(cdSCId: ID) -> CDScheduledChazara? {
        if let cdSC = self.cdScheduledChazaras?.first(where: { cdSC in
            cdSC.scId == cdSCId
        }) {
            return cdSC
        } else {
            //TODO: Make all the functions here work like this
            if let cdSC = pinCDScheduledChazara(id: cdSCId) {
//                Task {
//                    await loadScheduledChazaras()
//                }
                
                return cdSC
            } else {
                return nil
            }
        }
    }
    
    /// Fetches this ``ScheduledChazara`` data from the database and updates it here, or adds it if it has not been found in storage yet.
    func updateScheduledChazara(scId: ID) -> ScheduledChazara? {
        guard let cdScheduledChazara = pinCDScheduledChazara(id: scId) else {
            print("Couldn't update CDScheduledChazara, not found in database (SCID=\(scId))")
            
//            removing from local storage if it exists
            self.cdScheduledChazaras?.removeAll(where: { cdSC in
                cdSC.scId == scId
            })
            
            return nil
        }
        
        //            removing from local storage if it exists
        self.cdScheduledChazaras?.removeAll(where: { cdSC in
            cdSC.scId == scId
        })
        
        cdScheduledChazaras?.append(cdScheduledChazara)
        
        guard let scheduledChazara = ScheduledChazara(cdScheduledChazara) else {
            print("Couldn't return section (SCID=\(scId)), not valid")
            return nil
        }
        
        return scheduledChazara
    }
    
    /// Find and return this exact ``CDScheduledChazara`` in the data store without doing a full load.
    private func pinCDScheduledChazara(id: ID) -> CDScheduledChazara? {
        do {
            let request = CDScheduledChazara.fetchRequest()
            request.predicate = NSPredicate(format: "scId == %@", id)
            
            let results = try self.container.newBackgroundContext().fetch(request)
            
            if results.count == 1 {
                return results.first
            } else if results.count > 1 {
                print("Error: Something went wrong in pinning down the CDScheduledChazara, there is more than one match. Returning nil")
                return nil
            } else {
                return nil
            }
        } catch {
            print("Error: Failed to query to pin down a CDScheduledChazara: (scId=\(id))")
            return nil
        }
    }
    
    func getCDChazaraPoint(pointId: ID) -> CDChazaraPoint? {
        if let cdCP = cdChazaraPointsDictionary?[pointId] {
            return cdCP
        } else {
            //TODO: Make all the functions here work like this
            if let cdCP = pinCDChazaraPoint(id: pointId) {
//                Task {
//                    await loadChazaraPoints()
//                }
                
                return cdCP
            } else {
                return nil
            }
        }
    }
    
    func getCDChazaraPoint(sectionId: ID, scId: ID, createNewIfNeeded: Bool = false) -> CDChazaraPoint? {
        if let cdCP = cdChazaraPointsDictionary?.values.first(where: { cdCP in
            cdCP.sectionId == sectionId && cdCP.scId == scId
        }) {
            return cdCP
        } else {
            //TODO: Make all the functions here work like this
            if let cdCP = pinCDChazaraPoint(sectionId: sectionId, scId: scId) {
//                Task {
//                    await loadChazaraPoints()
//                }
                
                return cdCP
            } else if createNewIfNeeded {
                do {
                    print("Creating a CDChazaraPoint for spot: (SECID=\(sectionId),SCID=\(scId)) (CALLB)")
                    let context = PersistenceController.shared.container.viewContext
                    let point = CDChazaraPoint(context: context)
                    
                    point.pointId = IDGenerator.generate(withPrefix: "CP")
                    point.sectionId = sectionId
                    point.scId = scId
                    
                    let state = CDChazaraState(context: context)
                    state.stateId = IDGenerator.generate(withPrefix: "CS")
                    state.status = -1
                    
                    point.chazaraState = state
                    
                    try context.save()
                    
                    print("Generated and saved a CDChazaraPoint.")
                    
                    return point
                } catch {
                    print("Error: Couldn't save new CDChazaraPoint.")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
        
        func getChazaraPoint(pointId: ID) -> ChazaraPoint? {
            if let cdCP = cdChazaraPointsDictionary?[pointId], let chazaraPoint = ChazaraPoint(cdCP) {
                    return chazaraPoint
            } else {
                //TODO: Make all the functions here work like this
                if let cdCP = pinCDChazaraPoint(id: pointId), let chazaraPoint = ChazaraPoint(cdCP)  {
//                    Task {
//                        await loadChazaraPoints()
//                    }
                    
                    return chazaraPoint
                } else {
                    return nil
                }
            }
        }
        
    /// Returns the requested ``ChazaraPoint`` from local storage.
        func getChazaraPoint(sectionId: ID, scId: ID, createNewIfNeeded: Bool = false) -> ChazaraPoint? {
            guard let cdChazaraPoint = getCDChazaraPoint(sectionId: sectionId, scId: scId, createNewIfNeeded: createNewIfNeeded) else {
                return nil
            }
            
            if let chazaraPoint = ChazaraPoint(cdChazaraPoint) {
                return chazaraPoint
            } else {
                return nil
            }
        }
        
        /// Find and return this exact ``CDChazaraPoint`` in the data store without doing a full load.
        func pinCDChazaraPoint(id: ID) -> CDChazaraPoint? {
            do {
                let request = CDChazaraPoint.fetchRequest()
                request.predicate = NSPredicate(format: "pointId == %@", id)
                
                let results = try self.container.newBackgroundContext().fetch(request)
                
                if results.count == 1 {
                    return results.first
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDChazaraPoint, there is more than one match. Returning nil")
                    return nil
                } else {
                    return nil
                }
            } catch {
                print("Error: Failed to query to pin down a CDChazaraPoint: (pointId=\(id))")
                return nil
            }
        }
        
        /// Find and return this exact ``CDChazaraPoint`` in the data store without doing a full load.
        func pinCDChazaraPoint(sectionId: ID, scId: ID) -> CDChazaraPoint? {
            do {
                let request = CDChazaraPoint.fetchRequest()
                let sectionPredicate = NSPredicate(format: "sectionId == %@", sectionId)
                let scPredicate = NSPredicate(format: "scId == %@", scId)
                let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scPredicate])
                request.predicate = andPredicate
                
                let results = try self.container.newBackgroundContext().fetch(request)
                
                if results.count == 1 {
                    return results.first
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDChazaraPoint, there is more than one match. Returning nil")
                    return nil
                } else {
                    return nil
                }
            } catch {
                print("Error: Failed to query to pin down a CDChazaraPoint: (SECID=\(sectionId),SCID=\(scId)")
                return nil
            }
        }
        
        /// Wipes CoreData for entities ``CDLimud``, ``CDSection``, ``CDScheduledChazara``, ``CDChazaraPoint``, and ``CDChazaraState``.
        func wipe() throws {
            print("Wiping data...")
            let entities = ["CDLimud", "CDSection", "CDScheduledChazara", "CDChazaraPoint", "CDChazaraState", "CDPointNote"]
            
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
