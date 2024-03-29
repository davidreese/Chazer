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

    init(container: NSPersistentContainer) {
        self.container = container
    }
    
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
    
    private func getArchivedLimudimIDs() throws -> Set<CID> {
        let limudFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDLimud.fetchRequest()
        
        limudFetchRequest.predicate = NSPredicate(format: "archived == %@", NSNumber(value: true))
        
        let context = self.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        
        return try context.performAndWait {
            let limudResults = try context.fetch(limudFetchRequest) as! [CDLimud]
            
            var ids = Set<CID>()
            
            for cdLimud in limudResults {
                if let id = cdLimud.id {
                    ids.insert(id)
                }
            }
            
            return ids
        }
    }
    
    private func getArchivedSectionIDs() throws -> Set<CID> {
        let archivedLimudIds = try getArchivedLimudimIDs()
        
        let sectionFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
        
        sectionFetchRequest.predicate = NSPredicate(format: "limud.id IN %@", archivedLimudIds)
        
        let context = self.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        
        return try context.performAndWait {
            let sectionResults = try context.fetch(sectionFetchRequest) as! [CDSection]
            
            var ids = Set<CID>()
            
            for cdSection in sectionResults {
                if let id = cdSection.sectionId {
                    ids.insert(id)
                }
            }
            
            return ids
        }
    }
    
    /// Updates the statuses of the ``CDChazaraPoint`` objects in storage.
    private func updateCDChazaraPointStatuses() async {
        do {
            let cpFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()

            let archivedSectionIds = try getArchivedSectionIDs()
            
            let noArchivePredicate = NSPredicate(format: "NOT (sectionId IN %@)", archivedSectionIds)
            cpFetchRequest.predicate = noArchivePredicate
            
            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            try await context.perform {
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
    private func getActiveAndLateCDChazaraPoints() throws -> (activePoints: Set<CDChazaraPoint>, latePoints: Set<CDChazaraPoint>, context: NSManagedObjectContext?)? {
            let context = container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            
            return try context.performAndWait {
                let archivedSectionIds = try getArchivedSectionIDs()
                let noArchivePredicate = NSPredicate(format: "NOT (sectionId IN %@)", archivedSectionIds)
                
                let activeRequest = CDChazaraPoint.fetchRequest()
                let activePredicate = NSPredicate(format: "chazaraState.status == %i AND NOT (sectionId IN %@)", 2, archivedSectionIds)
                
                activeRequest.predicate = activePredicate
                
                let activeCDPoints = try context.fetch(activeRequest)
                
                let lateRequest = CDChazaraPoint.fetchRequest()
                let latePredicate = NSPredicate(format: "chazaraState.status == %i AND NOT (sectionId IN %@)", 3, archivedSectionIds)
                lateRequest.predicate = latePredicate
                
                let lateCDPoints = try context.fetch(lateRequest)
                
                return (Set(activeCDPoints), Set(lateCDPoints), context)
            }
    }
    
    func getActiveAndLateChazaraPoints() async throws -> (active: Set<ChazaraPoint>, late: Set<ChazaraPoint>)? {
        await self.updateCDChazaraPointStatuses()
        
        guard let data = try self.getActiveAndLateCDChazaraPoints(), let context = data.context else {
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
