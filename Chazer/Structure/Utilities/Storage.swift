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
    
//    private(set) var sections: Set<Section>?
//    private(set) var cdSections: Set<CDSection>?
//    private(set) var scheduledChazaras: [ScheduledChazara]?
//    private(set) var cdScheduledChazaras: [CDScheduledChazara]?
//    private(set) var cdChazaraPointsDictionary: [ID: CDChazaraPoint]?
//    private(set) var chazaraPointsDictionary: [ID: ChazaraPoint?]?
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    /*
    /// Used to request an update of the entire local storage system to match what is in CoreData.
    /// - Warning: This function does not update ``ChazaraPoint`` objects right now.
    @available(*, unavailable)
    func update() {
        print("Loading storage...")
        
//        loadScheduledChazarasSynchronously()
//        loadSectionsSynchronously()
        //        loadChazaraPointsSy/nchronously()
    }
     */
    
    /*
    func loadScheduledChazarasSynchronously() {
        print("Loading scheduled chazaras synchronously...")
        do {
            let scFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
            let scResults = try self.container.newBackgroundContext().fetch(scFetchRequest) as! [CDScheduledChazara]
            
//            self.cdScheduledChazaras = scResults
            
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
//                self.cdScheduledChazaras = scResults
                
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
//                self.cdSections = Set<CDSection>(secResults)
                
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
            
//            self.cdSections = Set<CDSection>(secResults)
            
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
     */
    
    /// Find and return the ``CDLimud`` corresponding to the given `id` from the database.
    private func pinCDLimud(id: CID) -> (limud: CDLimud?, context: NSManagedObjectContext?) {
        do {
            let request = CDLimud.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                let results = try context.fetch(request)
                
                if results.count == 1 {
                    return (results.first, context)
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDLimud, there is more than one match. Returning nil")
                    return (nil, context)
                } else {
                    return (nil, context)
                }
            }
        } catch {
            print("Error: Failed to query to pin down a CDLimud: (id=\(id))")
            return (nil, nil)
        }
    }
    
    func fetchLimud(id: CID) throws -> Limud? {
        let result = pinCDLimud(id: id)
        guard let cdLimud = result.limud, let context = result.context else {
            return nil
        }
        
        return try Limud(cdLimud, context: context)
    }
    
    //    var isLoadingChazaraPoints = false
    
    /// Updates the statuses of the ``CDChazaraPoint`` objects in storage.
    private func updateCDChazaraPointStatuses() async {
        do {
            let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            try context.performAndWait {
                let cpResults = try context.fetch(cpFetchRequest) as! [CDChazaraPoint]
                
                for cpResult in cpResults {
                    if let cp = try? ChazaraPoint(cpResult, context: context) {
                        Task {
                            let status = await cp.getCorrectChazaraStatus()
                            
                            context.performAndWait {
                                cpResult.chazaraState?.status = status.rawValue
                            }
                        }
                    } else {
                        print("\(cpResult.pointId ?? "nil") \(cpResult.sectionId ?? "nil")")
                    }
                }
                
                try context.save()
                
            }
            
        } catch {
            print(error)
        }
    }
    /*
    func aloadChazaraPoints() {
        print("Loading chazara points..")
        
        do {
            let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
            let cpResults = try self.container.newBackgroundContext().fetch(cpFetchRequest) as! [CDChazaraPoint]
            
            
        } catch {
            print(error)
        }
    }
    
    func loadChazaraPoints() async {
        print("Loading chazara points asynchronously...")
        
        await MainActor.run {
            do {
                let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
                let cpResults = try  self.container.newBackgroundContext().fetch(cpFetchRequest) as! [CDChazaraPoint]
                
                /*
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
                 */
                
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
            } catch {
                print(error)
            }
            
        }
        
        //        isLoadingChazaraPoints = false
    }
     
    
    func loadChazaraPointsSynchronously() {
        fatalError("This function has not yet been implemented.")
        
        print("Loading chazara points synchronously...")
        
        do {
            let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
            let cpResults = try self.container.newBackgroundContext().fetch(cpFetchRequest) as! [CDChazaraPoint]
            
            /*
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
             */
            
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
    */
    
    /*
    /// Fetches this ``ChazaraPoint`` data from the database and updates it here, or adds it if it has not been found in storage yet.
    func updateChazaraPoint(pointId: ID) -> ChazaraPoint? {
        guard let cdChazaraPoint = pinCDChazaraPoint(id: pointId) else {
            print("Couldn't update chazara point, not found in database (POINTID=\(pointId))")
            
            //            removing from local storage if it exists
//            cdChazaraPointsDictionary?.removeValue(forKey: pointId)
            chazaraPointsDictionary?.removeValue(forKey: pointId)
            
            return nil
        }
        
//        cdChazaraPointsDictionary?.updateValue(cdChazaraPoint, forKey: pointId)
        
        let chazaraPoint = ChazaraPoint(cdChazaraPoint)
        chazaraPointsDictionary?.updateValue(chazaraPoint, forKey: pointId)
        
        return chazaraPoint
    }
     */
    
    /*
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
    */
    
    /// Returns the requested ``Section`` from local storage.
    /// - Note: This function will search the database for this section if it cannot be found here. In such a case, it will also asynchronously update the entire sections storage to match the database.
    func getSection(sectionId: CID) -> Section? {
            //TODO: Make all the functions here work like this
        let result = pinCDSection(id: sectionId)
        if let cdSection = result.section, let context = result.context {
//                defer {
//                    Task {
//                        await loadSections()
//                    }
//                }
                
                return try? Section(cdSection, context: context)
            } else {
                return nil
            }
    }
    
    /// Returns the requested ``ScheduledChazara`` from local storage.
    /// - Note: This function will search the database for this section if it cannot be found here. In such a case, it will also asynchronously update the entire sections storage to match the database.
    func getScheduledChazara(scId: CID) -> ScheduledChazara? {
        let cdSCResult = pinCDScheduledChazara(id: scId)
        if let cdSC = cdSCResult.scheduledChazara, let context = cdSCResult.context {
                return try? ScheduledChazara(cdSC, context: context)
            } else {
                return nil
            }
    }
    
    /*
    /// Fetches this ``Section`` data from the database and updates it here, or adds it if it has not been found in storage yet.
    @MainActor
    func updateSection(sectionId: ID) -> Section? {
        guard let cdSection = pinCDSection(id: sectionId) else {
            print("Couldn't update section, not found in database (SECID=\(sectionId))")
            
            /*
            //            removing from local storage if it exists
            if let cdSection = self.cdSections?.first(where: { cdSection in
                cdSection.sectionId == sectionId
            }) {
                cdSections?.remove(cdSection)
            }
             */
            
            if let section = self.sections?.first(where: { section in
                section.id == sectionId
            }) {
                sections?.remove(section)
            }
            
            return nil
        }
        
        /*
        if let cdSections = self.cdSections, let cdSection = cdSections.first(where: { cdSection in
            cdSection.sectionId == sectionId
        }) {
            self.cdSections?.remove(cdSection)
        }
         */
        
        if let section = self.sections?.first(where: { section in
            section.id == sectionId
        }) {
            self.sections?.remove(section)
        }
        
//        cdSections?.update(with: cdSection)
        
        guard let section = Section(cdSection) else {
            print("Couldn't return section (SECID=\(sectionId)), not valid")
            return nil
        }
        
        self.sections?.update(with: section)
        
        return section
    }
     */
    
    /// Find and return this exact ``CDSection`` in the data store without doing a full load.
    func pinCDSection(id: CID) -> (section: CDSection?, context: NSManagedObjectContext?) {
        do {
            let request = CDSection.fetchRequest()
            request.predicate = NSPredicate(format: "sectionId == %@", id)
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                let results = try context.fetch(request)
                
                if results.count == 1 {
                    return (results.first, context)
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDSection, there is more than one match. Returning nil")
                    return (nil, context)
                } else {
                    return (nil, context)
                }
            }
        } catch {
            print("Error: Failed to query to pin down a CDSection: (sectionId=\(id))")
            return (nil, nil)
        }
    }
    
    /*
    /// Fetches this ``ScheduledChazara`` data from the database and updates it here, or adds it if it has not been found in storage yet.
    func updateScheduledChazara(scId: ID) -> ScheduledChazara? {
        guard let cdScheduledChazara = pinCDScheduledChazara(id: scId) else {
            print("Couldn't update CDScheduledChazara, not found in database (SCID=\(scId))")
            
            //            removing from local storage if it exists
            self.scheduledChazaras?.removeAll(where: { cdSC in
                cdSC.id == scId
            })
            
            return nil
        }
        
        //            removing from local storage if it exists
        self.scheduledChazaras?.removeAll(where: { sc in
            sc.id == scId
        })
        
        guard let scheduledChazara = ScheduledChazara(cdScheduledChazara) else {
            print("Couldn't return scheduled chazara (SCID=\(scId)), not valid")
            return nil
        }
        
        scheduledChazaras?.append(scheduledChazara)
        
        return scheduledChazara
    }
     */
    
    /// Find and return this exact ``CDScheduledChazara`` in the data store without doing a full load.
    func pinCDScheduledChazara(id: CID) -> (scheduledChazara: CDScheduledChazara?, context: NSManagedObjectContext?) {
        do {
            let request = CDScheduledChazara.fetchRequest()
            request.predicate = NSPredicate(format: "scId == %@", id)
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                let results = try context.fetch(request)
                
                if results.count == 1 {
                    return (results.first, context)
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDScheduledChazara, there is more than one match. Returning nil")
                    return (nil, context)
                } else {
                    return (nil, context)
                }
            }
        } catch {
            print("Error: Failed to query to pin down a CDScheduledChazara: (scId=\(id))")
            return (nil, nil)
        }
    }
    
    
    /// Gets the requested ``ChazaraPoint`` from the database.
    /// - Parameter pointId: The `id` of the ``ChazaraPoint`` being requested.
    /// - Returns: The ``ChazaraPoint``, if it was found.
    /// - Note: This function will not neccesarily update the ``ChazaraPoint``.
    func getChazaraPoint(pointId: CID) -> ChazaraPoint? {
        let cdCPResult = pinCDChazaraPoint(id: pointId)
        if let cdCP = cdCPResult.point, let context = cdCPResult.context, let chazaraPoint = try? ChazaraPoint(cdCP, context: context)  {
                
                return chazaraPoint
            } else {
                return nil
            }
    }
    
    
    /// Gets the requested ``ChazaraPoint`` from the local cache if it exists, and if not, searches the database.
    /// - Parameters:
    ///   - sectionId: The `sectionId` of the requested ``ChazaraPoint``
    ///   - scId: The `scheduledChazaraId`, or `scId`,  of the requested ``ChazaraPoint``
    ///   - createNewIfNeeded: If set to `true`, if the ``ChazaraPoint`` is not found, it will be created for the given coordinate `sectionId` and `scheduledChazaraId`
    /// - Returns: The requested ``ChazaraPoint``.
    /// - Note: This function will not neccesarily update the ``ChazaraPoint``.
    func getChazaraPoint(sectionId: CID, scId: CID, createNewIfNeeded: Bool = false) -> ChazaraPoint? {
        let result = pinCDChazaraPoint(sectionId: sectionId, scId: scId, createNewIfNeeded: createNewIfNeeded)
        if let cdChazaraPoint = result.point, let context = result.context, let chazaraPoint = try? ChazaraPoint(cdChazaraPoint, context: context) {
            return chazaraPoint
        } else {
            return nil
        }
    }
    
    /// Find and return this exact ``CDChazaraPoint`` in the data store without doing a full load.
    func pinCDChazaraPoint(id: CID) -> (point: CDChazaraPoint?, context: NSManagedObjectContext?) {
        do {
            let request = CDChazaraPoint.fetchRequest()
            request.predicate = NSPredicate(format: "pointId == %@", id)
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                
                let results = try context.fetch(request)
                
                if results.count == 1 {
                    return (results.first, context)
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDChazaraPoint, there is more than one match. Returning nil")
                    return (nil, context)
                } else {
                    return (nil, context)
                }
            }
        } catch {
            print("Error: Failed to query to pin down a CDChazaraPoint: (pointId=\(id))")
            return (nil, nil)
        }
    }
    
    /// Find and return this exact ``CDChazaraPoint`` in the data store without doing a full load.
    func pinCDChazaraPoint(sectionId: CID, scId: CID, createNewIfNeeded: Bool = false) -> (point: CDChazaraPoint?, context: NSManagedObjectContext?) {
        do {
            let request = CDChazaraPoint.fetchRequest()
            let sectionPredicate = NSPredicate(format: "sectionId == %@", sectionId)
            let scPredicate = NSPredicate(format: "scId == %@", scId)
            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scPredicate])
            request.predicate = andPredicate
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                let results = try context.fetch(request)
                
                if results.count == 1 {
                    return (results.first, context)
                } else if results.count > 1 {
                    print("Error: Something went wrong in pinning down the CDChazaraPoint, there is more than one match. Returning nil")
                    return (nil, context)
                } else if results.count == 0 && createNewIfNeeded {
                    do {
                        print("Creating a CDChazaraPoint for spot: (SECID=\(sectionId),SCID=\(scId)) (CALLB)")
//                        let context = PersistenceController.shared.container.viewContext
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
                        
                        return (point, context)
                    } catch {
                        print("Error: Couldn't save new CDChazaraPoint.")
                        return (nil, context)
                    }
                } else {
                    return (nil, context)
                }
            }
        } catch {
            print("Error: Failed to query to pin down a CDChazaraPoint: (SECID=\(sectionId),SCID=\(scId)")
            return (nil, nil)
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
                context.automaticallyMergesChangesFromParent = true
                
                try context.execute(batchDeleteRequest)
                try context.save()
                
//                update()
            } catch let error as NSError {
                print("Could not wipe Core Data, failed on run for \(entityName). \(error), \(error.userInfo)")
                throw StorageError.wipeFailure
            }
        }
    }
    
    // MARK: Dashboard Functions
    /// Fetches CDChazaraPoints with active and late status
    private func getActiveAndLateCDChazaraPoints() -> (activePoints: Set<CDChazaraPoint>, latePoints: Set<CDChazaraPoint>, context: NSManagedObjectContext?)? {
        do {
            let context = container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                let activeRequest = CDChazaraPoint.fetchRequest()
                let activePredicate = NSPredicate(format: "chazaraState.status == %i", 2)
                activeRequest.predicate = activePredicate
                
                let activeCDPoints = try context.fetch(activeRequest)
                
                let lateRequest = CDChazaraPoint.fetchRequest()
                let latePredicate = NSPredicate(format: "chazaraState.status == %i", 3)
                lateRequest.predicate = latePredicate
                
                let lateCDPoints = try context.fetch(lateRequest)
                
                return (Set(activeCDPoints), Set(lateCDPoints), context)
            }
        } catch {
            print("Error fetching data: \(error)")
            return nil
        }
    }
    
    func getActiveAndLateChazaraPoints() async -> (active: Set<ChazaraPoint>, late: Set<ChazaraPoint>)? {
        await self.updateCDChazaraPointStatuses()
        
        guard let data = self.getActiveAndLateCDChazaraPoints(), let context = data.context else {
            return nil
        }
        
        var activePoints = Set<ChazaraPoint>()
        for cdPointActive in data.activePoints {
            guard let chazaraPoint = try? ChazaraPoint(cdPointActive, context: context) else {
                continue
            }
            activePoints.update(with: chazaraPoint)
        }
        
        
        var latePoints = Set<ChazaraPoint>()
        for cdPointLate in data.latePoints {
            guard let chazaraPoint = try? ChazaraPoint(cdPointLate, context: context) else {
                continue
            }
            latePoints.update(with: chazaraPoint)
        }
        
        return (activePoints, latePoints)
    }
}

enum StorageError: Error {
    case wipeFailure
}
