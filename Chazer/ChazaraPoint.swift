//
//  ChazaraPoint.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation
import CoreData

/// A point on the visual graph with a certain status of chazara.
class ChazaraPoint: ObservableObject {
    final let id: ID
    final let sectionId: ID
    private var section: Section?
    
    final let scheduledChazaraId: ID
    private var scheduledChazara: ScheduledChazara?
    
    @Published private(set) var status: ChazaraStatus!
    @Published private(set) var date: Date?
    
    private final let container = PersistenceController.shared.container
    
    init?(_ cdChazaraPoint: CDChazaraPoint) {
        guard let id = cdChazaraPoint.pointId else {
            print("Error: Invalid CDChazaraPoint.")
            return nil
        }
        
        /*
        if let context = cdChazaraPoint.managedObjectContext.contain {
            self.context = context
        } else {
            print("Data Error: Setting context to shared. Moving forward is not recommended.")
            self.context = PersistenceController.shared.container.viewContext
        }
         */
        
        self.id = id
        self.sectionId = cdChazaraPoint.sectionId!
        self.scheduledChazaraId = cdChazaraPoint.scId!
        
        if let chazaraState = cdChazaraPoint.chazaraState {
            if chazaraState.status == -2 {
//                The chazara status has not yet been set.
                print("Mesg: Chazara status has not yet been set. SECID=\(sectionId) SCID=\(scheduledChazaraId)")
                fatalError()
            } else {
                guard let status = ChazaraStatus(rawValue: chazaraState.status) else {
                    print("Error: Invalid status for chazara point. STAT=\(chazaraState.status)")
                    return nil
                }
                
                self.status = status
                self.date = chazaraState.date
            }
        }
        
        Task {
            await updateAllData()
        }
    }
    
    /*
    /// Creates and saves a new ``CDChazaraPoint`` and returns a corresponding ``ChazaraPoint``.
    init(sectionId: ID, scheduledChazaraId: ID) {
        let cdPoint = CDChazaraPoint(context: <#T##NSManagedObjectContext#>)
    }\
     */
    
    /// Fetches the ``CDChazaraPoint`` assosiated with this point.
    func fetchCDEntity() -> CDChazaraPoint? {
        //MARK: Very helpful code
        let fetchRequest: NSFetchRequest<CDChazaraPoint> = CDChazaraPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pointId == %@", id)
        
        guard let results = try? container.newBackgroundContext().fetch(fetchRequest) else {
            print("Error: Could not fetch the chazara point. ID=\(id)")
            return nil
        }
        
        if results.count == 1 {
            guard let result = results.first else {
                print("Error: Could not fetch the chazara point. ID=\(id)")
                return nil
            }
            if result.sectionId == sectionId && result.scId == scheduledChazaraId {
                return result
            } else {
                print("Error: The found chazara point did not match in critical values. ID=\(id)")
                return nil
            }
        } else if results.isEmpty {
            print("Error: Could not find the chazara point. ID=\(id)")
            return nil
        } else {
            print("Error: There was a data issue finding the chazara point: too many points found. ID=\(id)")
            return nil
        }
    }
    
    /// Updates the data that is only tied to the CDChazaraPoint.
    /// - Note: To update all date, use ``updateData()``
    func updatePointData() {
        guard let cdPoint = fetchCDEntity() else {
            return
        }
        
        self.date = cdPoint.chazaraState?.date
        
        if let status = cdPoint.chazaraState?.status {
            self.status = ChazaraStatus(rawValue: status)
        } else {
            self.status = nil
        }
    }
    
    /// Fetches the `Section` assosiated with this point's `sectionId` and saves it.
    /// - Returns: The assosiated  `Section`, unless it wasn't found.
    func fetchSection() async -> Section? {
        self.section = await Storage.shared.getSection(sectionId: self.sectionId)
        return self.section
        
//        MARK: Very helpful code
        /*
        let persistenceController = PersistenceController.shared
        
        let fetchRequest: NSFetchRequest<CDSection> = CDSection.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sectionId == %@", sectionId)
        
        guard let results = try? persistenceController.container.viewContext.fetch(fetchRequest) else {
            print("Error: Could not fetch the section for chazara point. SECID=\(sectionId)")
            return nil
        }
        
        
        if results.count == 1 {
            guard let result = results.first, let section = Section(result) else {
                print("Error: Could not fetch the section for chazara point. SECID=\(sectionId)")
                return nil
            }
            
            self.section = section
            return section
        } else if results.isEmpty {
            print("Error: Could not find the section for chazara point. SECID=\(sectionId)")
            return nil
        } else {
            print("Error: There was a data issue finding a section for chazara point: too many sections found. SECID=\(sectionId)")
            return nil
        }
        */
    }
    
    /// Fetches the `ScheduledChazara` assosiated with this point's `scId` and saves it.
    /// - Returns: The assosiated  `ScheduledChazara`, unless it wasn't found.
    func fetchSC() -> ScheduledChazara? {
        let persistenceController = PersistenceController.shared
        
        let fetchRequest: NSFetchRequest<CDScheduledChazara> = CDScheduledChazara.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "scId == %@", scheduledChazaraId)
        
        guard let results = try? persistenceController.container.viewContext.fetch(fetchRequest) else {
            print("Error: Could not fetch the scheduled chazara for chazara point. SCID=\(scheduledChazaraId)")
            return nil
        }
        
        
        if results.count == 1 {
            guard let result = results.first, let scheduledChazara = ScheduledChazara(result) else {
                print("Error: Could not fetch the scheduled chazara for chazara point. SCID=\(scheduledChazaraId)")
                return nil
            }
            
            self.scheduledChazara = scheduledChazara
            return scheduledChazara
        } else if results.isEmpty {
            print("Error: Could not find the scheduled chazara for chazara point. SCID=\(scheduledChazaraId)")
            return nil
        } else {
            print("Error: There was a data issue finding a scheduled chazara for chazara point: too many scheduled chazaras found. SCID=\(scheduledChazaraId)")
            return nil
        }
    }
    
    /// Gets the ``CDChazaraPoint`` for a given position.
    /// - Parameters:
    ///   - context: The context of data in which to search.
    ///   - sectionId: The ``ID`` of the ``Section`` coordinate to search for.
    ///   - scheduledChazaraId: The ``ID`` of the  ``ScheduledChazara`` coordinate to search for.
    /// - Returns: A ``CDChazaraPoint`` if only one is found for the given coordinates.
    private static func getCDChazaraPoint(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, sectionId: ID, scheduledChazaraId: ID) -> CDChazaraPoint? {
        return Storage.shared.getCDChazaraPoint(sectionId: sectionId, scId: scheduledChazaraId)
    }
    
    /// Gets the ``CDChazaraPoint`` for a given position.
    /// - Parameters:
    ///   - context: The context of data in which to search.
    ///   - section: The ``Section`` coordinate to search for.
    ///   - scheduledChazara: The ``ScheduledChazara`` coordinate to search for.
    /// - Returns: A ``CDChazaraPoint`` if only one is found for the given coordinates.
    private static func getCDChazaraPoint(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, section: Section, scheduledChazara: ScheduledChazara) -> CDChazaraPoint? {
        return getCDChazaraPoint(context: context, sectionId: section.id, scheduledChazaraId: scheduledChazara.id)
    }
    
    /// Default caller for ``getCDChazaraPoint(context:section:scheduledChazara:)``.
    private func getCDChazaraPoint() -> CDChazaraPoint? {
        guard let section = section, let scheduledChazara = scheduledChazara else {
            return nil
        }
        
        return ChazaraPoint.getCDChazaraPoint(section: section, scheduledChazara: scheduledChazara)
    }
    
    private static func getChazaraPoint(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, section: Section, scheduledChazara: ScheduledChazara) -> ChazaraPoint? {
        guard let cdChazaraPoint = getCDChazaraPoint(context: context, section: section, scheduledChazara: scheduledChazara) else {
            return nil
        }
        
        return ChazaraPoint(cdChazaraPoint)
    }
    
    private func getChazaraPoint() async -> ChazaraPoint? {
        guard let section = section, let scheduledChazara = scheduledChazara else {
            return nil
        }
        
        guard let cdChazaraPoint = ChazaraPoint.getCDChazaraPoint(section: section, scheduledChazara: scheduledChazara) else {
            return nil
        }
        
        return ChazaraPoint(cdChazaraPoint)
    }
    
//    TODO: Check that this isn't being called too much
    func updateAllData() async {
        await self.fetchSection()
        self.fetchSC()
        self.updatePointData()
        await self.updateCorrectChazaraStatus()
    }
    
    func setDate(_ date: Date?) {
        do {
            guard let entity = self.fetchCDEntity() else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            entity.chazaraState?.date = date
            try entity.managedObjectContext?.save()
            
            DispatchQueue.main.async {
                self.date = date
            }
        } catch {
            print("Error: Could not set the chazara date: \(error)")
        }
    }
    
    func setStatus(_ status: ChazaraStatus) {
        do {
            guard let entity = self.fetchCDEntity() else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }

            entity.chazaraState?.status = status.rawValue
            try entity.managedObjectContext?.save()

            DispatchQueue.main.async {
                self.status = status
            }
        } catch {
            print("Error: Could not set the chazara date: \(error)")
        }
    }
    
    func setState(status: ChazaraStatus, date: Date?) {
        do {
            guard let entity = self.fetchCDEntity() else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            entity.chazaraState?.status = status.rawValue
            entity.chazaraState?.date = date
            
            try entity.managedObjectContext?.save()
            
            DispatchQueue.main.async {
                self.status = status
                self.date = date
            }
        } catch {
            print("Error: Could not set the chazara date: \(error)")
        }
    }
    
    func markAsChazered(date: Date) async {
        setState(status: .completed, date: date)
    }
    
    func markAsExempt() async {
        setState(status: .exempt, date: nil)
    }
    
    func removeChazara() async {
        self.setState(status: .unknown, date: nil)
        await self.updateCorrectChazaraStatus()
    }
    
    func removeExemption() async {
        self.setState(status: .unknown, date: nil)
        await self.updateCorrectChazaraStatus()
    }
    
    /// Gets the date that this ``ChazaraPoint``becomes active, if there is one.
    func getActiveDate(retryOnFail: Bool = true) async -> Date? {
//        updateData()
        if status == .completed || status == .exempt {
            return nil
        } else {
            if let section = self.section, let scheduledChazara = self.scheduledChazara {
                
                if let delay = scheduledChazara.delay {
                    if let delayedFrom = scheduledChazara.delayedFrom {
                        guard let delayedFromPoint = ChazaraPoint.getCDChazaraPoint(section: section, scheduledChazara: delayedFrom), let statusRaw = delayedFromPoint.chazaraState?.status, let status = ChazaraStatus(rawValue: statusRaw) else {
                            print("Error: delayedFrom could not be found.")
                            return nil
                        }
                        if status == .completed {
                            if let date = delayedFromPoint.chazaraState?.date {
                                return ChazaraPoint.getActiveDate(date, delay: delay)
                            } else {
                                print("Error: Couldn't get active date.")
                                return nil
                            }
                        } else {
                            return nil
                        }
                    } else {
                        return ChazaraPoint.getActiveDate(section.initialDate, delay: delay)
                    }
                } else if let fixedDueDate = scheduledChazara.fixedDueDate {
                    return fixedDueDate
                } else {
                    print("Error: Scheduled chazara has no valid due rule.")
                    return nil
                }
            } else if retryOnFail {
                await updateAllData()
                return await getActiveDate(retryOnFail: false)
            } else {
                print("Error: Cannot find information for this ChazaraPoint to getActiveDate.")
                return nil
            }
        }
    }
    
    private static func getActiveDate(_ date: Date, delay: Int) -> Date {
        return date.advanced(by: TimeInterval(delay * 60 * 60 * 24))
    }
    
    /// Gets the date that this `ChazaraPoint`is due, if there is one.
    func getDueDate(retryOnFail: Bool = true) async -> Date? {
        if status == .completed || status == .exempt {
            return nil
        } else {
            if let section = section, let scheduledChazara = scheduledChazara {
                
                if let delay = scheduledChazara.delay {
                if let delayedFrom = scheduledChazara.delayedFrom {
                    let delayedFromPoint = ChazaraPoint.getChazaraPoint(section: section, scheduledChazara: delayedFrom)
                    if delayedFromPoint?.status == .completed {
                        if let date = delayedFromPoint?.date {
                            return ChazaraPoint.getDueDate(date, delay: delay)
                        } else {
                            print("Error: Couldn't get due date.")
                            return nil
                        }
                    } else {
                        return nil
                    }
                } else {
                    return ChazaraPoint.getDueDate(section.initialDate, delay: delay)
                }
            } else if let fixedDueDate = scheduledChazara.fixedDueDate {
                return fixedDueDate
            } else {
                print("Error: Scheduled chazara has no valid due rule.")
                return nil
            }
            } else if retryOnFail {
                await updateAllData()
                return await getDueDate(retryOnFail: false)
            } else {
                print("Error: Cannot find information for this ChazaraPoint to getDueDate.")
                return nil
            }
        }
    }
    
    private static func getDueDate(_ date: Date, delay: Int) -> Date {
        return getActiveDate(date, delay: delay).advanced(by: 2 * 60 * 60 * 24)
    }
    
    
    /// Gets the chazara status that should be assigned to this `ChazaraPoint` based on its section and scheduled chazara.
    /// - Returns: The correct ``ChazaraStatus`` that should be applied, based on the local variables.
    private func getCorrectChazaraStatus() async -> ChazaraStatus {
//        await updateAllData()
        //            check first to see if chazara has been completed
        if self.status == .completed {
            return .completed
        } else if status == .exempt {
            return .exempt
        } else {
            guard let dateActive = await getActiveDate(),
                  let dueDate = await getDueDate() else {
                guard let delayedFromId = self.scheduledChazara?.delayedFrom?.id else {
                    return .unknown
                }
                
                if ChazaraPoint.getCompletionDate(sectionId: sectionId, scheduledChazaraId: delayedFromId) == nil {
                    return .early
                } else {
                    return .unknown
                }
            }
            
            let now = Date.now
            
            if now < dateActive {
                return .early
            } else if now >= dateActive && now < dueDate {
                return .active
            } else {
                return .late
            }
        }
    }
    
    func updateCorrectChazaraStatus() async {
//        Task {
        let status = await getCorrectChazaraStatus()
        self.setStatus(status)
//        }
    }
    
    static func getCompletionDate(sectionId: ID, scheduledChazaraId: ID) -> Date? {
        guard let point = getCDChazaraPoint(sectionId: sectionId, scheduledChazaraId: scheduledChazaraId), let statusVal = point.chazaraState?.status, let status = ChazaraStatus(rawValue: statusVal) else {
            print("Error: Couldn't get completion date for coordinates.")
            return nil
        }
        
        if status == .completed {
            return point.chazaraState?.date
        } else {
            return nil
        }
    }
    
    func getCompletionDate() -> Date? {
        if status == .completed {
            return date
        } else {
            return nil
        }
    }
}
