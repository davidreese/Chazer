//
//  ChazaraPoint.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation
import CoreData

/// A point at which chazara is scheduled to be done.
class ChazaraPoint: ObservableObject, Hashable, Identifiable {
    final var id: CID!
    final var sectionId: CID!
    private var section: Section?
    
    final var scheduledChazaraId: CID!
    private var scheduledChazara: ScheduledChazara?
    
    final var limudId: CID?
    private var limud: Limud?
    
    @Published private(set) var status: ChazaraStatus!
    
    /// The date this point was marked to have been chazered
    /// - Note: This value should be `nil` if it has not been marked as chazered
    @Published private(set) var date: Date?
    
    /// The date that this point's chazara is due
    /// - Note: This value is only supposed to exist if the status is active.
    @Published private(set) var dueDate: Date?
    
    /// The date that this point's chazara becomes/became active
    ///  - Note: If the chazara was completed, this value is nil
    @Published private(set) var activeDate: Date?
    
    /// The list of saved notes associated with this ``ChazaraPoint``
    @Published private(set) var notes: [PointNote]?
    
    private final let container = PersistenceController.shared.container
    
    /// Attempts to intansiate a ``ChazaraPoint`` from its CoreData counterpart.
    init(_ cdChazaraPoint: CDChazaraPoint, context: NSManagedObjectContext) throws {
        
        try context.performAndWait {
            guard let id = cdChazaraPoint.pointId, let sectionId = cdChazaraPoint.sectionId, let scheduledChazaraId = cdChazaraPoint.scId, let chazaraState = cdChazaraPoint.chazaraState else {
                print("Error: Invalid CDChazaraPoint (PID=\(cdChazaraPoint.pointId)). Deleting...")
                
                throw RetrievalError.missingData
                //                return
                //                defer { print("Automatic deletion temporary disabled.") }
                //                throw InstansiationError.missingData
                
                //            deletion code temporarily disabled
                /*
                 do {
                 context.delete(cdChazaraPoint)
                 try context.save()
                 print("Deleted invalid CDChazaraPoint.")
                 } catch {
                 print("Failed to delete invalid CDChazaraPoint")
                 }
                 
                 throw InstansiationError.missingData
                 //                return nil
                 */
            }
            
            self.id = id
            self.sectionId = sectionId
            self.scheduledChazaraId = scheduledChazaraId
            
            let chazaraStateStatus = chazaraState.status
            
            if chazaraStateStatus == -2 {
                //                The chazara status has not yet been set.
                print("Mesg: Chazara status has not yet been set. SECID=\(sectionId) SCID=\(scheduledChazaraId)")
                self.status = .unknown
            } else {
                if let status = ChazaraStatus(rawValue: chazaraStateStatus) {
                    self.status = status
                    self.date = chazaraState.date
                } else {
                    print("Error: Invalid status for chazara point. STAT=\(chazaraStateStatus)")
                    self.status = .unknown
                    self.date = chazaraState.date
                }
            }
            
            
            //        moving saved notes array into this object
            if let objects = cdChazaraPoint.notes?.array {
                for obj in objects {
                    if let cdNote = obj as? CDPointNote, let note = try? PointNote(cdNote, context: context) {
                        if self.notes == nil {
                            self.notes = [note]
                        } else {
                            self.notes?.append(note)
                        }
                    }
                }
            }
            
        }
        
        Task {
            try await updateAllData()
        }
    }
    
    /// Fetches the ``CDChazaraPoint`` associated with this point.
    func fetchCDEntity() -> (point: CDChazaraPoint?, context: NSManagedObjectContext?) {
        return Storage.shared.pinCDChazaraPoint(id: self.id)
    }
    
    /// Updates the data that is only tied to the CDChazaraPoint saved in CoreData.
    /// - Note: To update all data, use ``updateData()``
    @MainActor
    func updatePointData() throws {
        let result = Storage.shared.pinCDChazaraPoint(id: self.id)
        
        guard let cdChazaraPoint = result.point, let context = result.context else {
            return
        }
        
        context.performAndWait {
            self.date = cdChazaraPoint.chazaraState?.date
            
            if let status = cdChazaraPoint.chazaraState?.status {
                self.status = ChazaraStatus(rawValue: status)
            } else {
                self.status = nil
            }
            
            self.notes = nil
            //        moving saved notes array into this object
            if let objects = cdChazaraPoint.notes?.array {
                for obj in objects {
                    if let cdNote = obj as? CDPointNote, let note = try? PointNote(cdNote, context: context) {
                        if self.notes == nil {
                            self.notes = [note]
                        } else {
                            self.notes?.append(note)
                        }
                    }
                }
            }
        }
    }
    
    /// Fetches the ``Section`` associated with this point's `sectionId` and saves it.
    /// - Returns: The assosiated  ``Section``, unless it wasn't found.
    @MainActor
    func fetchSection() -> Section? {
        self.section = Storage.shared.getSection(sectionId: self.sectionId)
        return self.section
    }
    
    /// Gets the ``Section`` associated with this point if it is saved, or if not, fetches it from storage and saves it.
    /// - Returns: The assosiated  ``Section``, unless it wasn't found.
    @MainActor
    func getSection() -> Section? {
        if let section = self.section {
            return section
        } else {
            return fetchSection()
        }
    }
    
    /// Fetches the ``ScheduledChazara`` assosiated with this point's `scId` and saves it.
    /// - Returns: The associated  ``ScheduledChazara``, unless it wasn't found.
    @MainActor
    func fetchSC() -> ScheduledChazara? {
        self.scheduledChazara = Storage.shared.getScheduledChazara(scId: self.scheduledChazaraId)
        return self.scheduledChazara
    }
    
    /// Gets the ``ScheduledChazara`` associated with this point if it is saved, or if not, fetches it from storage and saves it.
    /// - Returns: The associated  ``ScheduledChazara``, unless it wasn't found.
    @MainActor
    func getSC() -> ScheduledChazara? {
        if let sc = self.scheduledChazara {
            return sc
        } else {
            return fetchSC()
        }
    }
    
    /// Fetches the ``Limud`` assosiated with this point's `limudId` and saves it.
    /// - Returns: The associated  ``Limud``, unless it wasn't found.
    @MainActor
    func fetchLimud() -> Limud? {
        if let limudId = self.limudId {
            self.limud = try? Storage.shared.fetchLimud(id: limudId)
        } else {
            guard let limudId = getSection()?.limudId else {
                return nil
            }
            self.limudId = limudId
            self.limud = try? Storage.shared.fetchLimud(id: limudId)
        }
        
        return self.limud
    }
    
    /// Gets the ``Limud`` associated with this point if it is saved, or if not, fetches it from storage and saves it.
    /// - Returns: The associated  ``Limud``, unless it wasn't found.
    @MainActor
    func getLimud() -> Limud? {
        if let limud = self.limud {
            return limud
        } else {
            return fetchLimud()
        }
    }
    
    /// Gets the ``CDChazaraPoint`` for a given position.
    /// - Parameters:
    ///   - sectionId: The ``CID`` of the ``Section`` coordinate to search for.
    ///   - scheduledChazaraId: The ``CID`` of the  ``ScheduledChazara`` coordinate to search for.
    /// - Returns: A ``CDChazaraPoint`` if only one is found for the given coordinates.
    private static func getCDChazaraPoint(sectionId: CID, scheduledChazaraId: CID) -> (point: CDChazaraPoint?, context: NSManagedObjectContext?) {
        return Storage.shared.pinCDChazaraPoint(sectionId: sectionId, scId: scheduledChazaraId)
    }
    
    /// Gets the ``CDChazaraPoint`` for a given position.
    /// - Parameters:
    ///   - context: The context of data in which to search.
    ///   - section: The ``Section`` coordinate to search for.
    ///   - scheduledChazara: The ``ScheduledChazara`` coordinate to search for.
    /// - Returns: A ``CDChazaraPoint`` if only one is found for the given coordinates.
    private static func getCDChazaraPoint(section: Section, scheduledChazara: ScheduledChazara) -> (point: CDChazaraPoint?, context: NSManagedObjectContext?) {
        return getCDChazaraPoint(sectionId: section.id, scheduledChazaraId: scheduledChazara.id)
    }
    
    /// Default caller for ``getCDChazaraPoint(context:section:scheduledChazara:)``.
    private func getCDChazaraPoint() -> (point: CDChazaraPoint?, context: NSManagedObjectContext?) {
        guard let section = section, let scheduledChazara = scheduledChazara else {
            return (nil, nil)
        }
        
        return ChazaraPoint.getCDChazaraPoint(section: section, scheduledChazara: scheduledChazara)
    }
    
    private static func getChazaraPoint(section: Section, scheduledChazara: ScheduledChazara) -> ChazaraPoint? {
        let result = getCDChazaraPoint(section: section, scheduledChazara: scheduledChazara)
        guard let cdChazaraPoint = result.point, let context = result.context else {
            return nil
        }
        
        return try? ChazaraPoint(cdChazaraPoint, context: context)
    }
    
    private var isUpdating = false
    private var lastUpdate: Date?
    
    //    TODO: Check that this isn't being called too much
    /// Updates all data on this ``ChazaraPoint`` to be consistent with data in the database.
    @MainActor
    func updateAllData() async throws {
        if isUpdating {
            print("Not updating data on point because it is updating now: (PID=\(self.id))")
            return
        }
        
        if (lastUpdate?.timeIntervalSinceNow ?? 100) < 15 {
            print("Not updating data on point because it was updated too recently: (PID=\(self.id))")
            return
        }
        
        isUpdating = true
        //        print("Updating all data on point... (PID=\(self.id))")
        
        //            Update the relevant section and scheduled chazara objects\
        //            TODO: try and figure these next four lines, what is making this function stop the UI for so long. maybe kill the @MainActor requirements of these functions and figure out a way for them to all run on one thread, like if you create the coredata thread here maybe.
        self.fetchSection()
        self.fetchSC()
        try self.updatePointData()
        
        do {
            try await self.updateCorrectChazaraStatus()
        } catch {
            print("Failed to update correct chazara status for (PID=\(self.id)): \(error)")
        }
        
        isUpdating = false
        lastUpdate = Date.now
    }
    
    /// Sets the `dueDate` attribute for this object.
    /// - Note: The `dueDate` attribute has no corresponding value in storage.
    @MainActor
    func setDueDate(_ dueDate: Date?) {
        self.dueDate = dueDate
    }
    
    /// Sets the `activeDate` attribute for this object.
    /// - Note: The `activeDate` attribute has no corresponding value in storage.
    @MainActor
    func setActiveDate(_ activeDate: Date?) {
        self.activeDate = activeDate
    }
    
    /// Sets the `date` attribute for this object, and also saves it as such in storage.
    @MainActor
    func setDate(_ date: Date?) {
        let standardizedDate = date != nil ? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date!) : nil
        do {
            let result = self.fetchCDEntity()
            guard let entity = result.point, let context = result.context else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            try context.performAndWait {
                entity.chazaraState?.date = standardizedDate
                
                try context.save()
                
                self.date = standardizedDate
            }
        } catch {
            print("Error: Could not set the chazara date: \(error)")
        }
    }
    
    @MainActor
    func setStatus(_ status: ChazaraStatus) throws {
        do {
            let result = self.fetchCDEntity()
            guard let entity = result.point, let context = result.context else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            try context.performAndWait {
                entity.chazaraState?.status = status.rawValue
                try context.save()
                
                self.status = status
            }
        } catch {
            print("Error: Could not set chazara status: \(error)")
            throw error
        }
    }
    
    @MainActor
    func setState(status: ChazaraStatus, date: Date?) throws {
        let standardizedDate = date != nil ? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date!) : nil
        do {
            let result = self.fetchCDEntity()
            guard let entity = result.point, let context = result.context else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            try context.performAndWait {
                entity.chazaraState?.status = status.rawValue
                entity.chazaraState?.date = standardizedDate
                
                try context.save()
                
                self.status = status
                self.date = standardizedDate
            }
        } catch {
            print("Error: Could not set the chazara status/date: \(error)")
            throw error
        }
    }
    
    @MainActor
    func markAsChazered(date: Date) async throws {
        try self.setState(status: .completed, date: date)
        try await self.updateCorrectChazaraStatus()
    }
    
    @MainActor
    func markAsExempt() async throws {
        try setState(status: .exempt, date: nil)
        try await self.updateCorrectChazaraStatus()
    }
    
    @MainActor
    func removeChazara() async throws {
        try self.setState(status: .unknown, date: nil)
        try await self.updateCorrectChazaraStatus()
    }
    
    @MainActor
    func removeExemption() async throws {
        try self.setState(status: .unknown, date: nil)
        try await self.updateCorrectChazaraStatus()
    }
    
    /// Gets the ``Date`` that this ``ChazaraPoint`` becomes active, if there is one available.
    @MainActor
    func getActiveDate(retryOnFail: Bool = true) async -> Date? {
        if status == .completed || status == .exempt {
            //  no date available
            let activeDate: Date? = nil
            setActiveDate(activeDate)
            return activeDate
        } else {
            if let section = self.section, let scheduledChazara = self.scheduledChazara, let scheduleRule = scheduledChazara.scheduleRule {
                
                switch scheduleRule {
                case .fixedDueDate(_):
                    // assumes current functionality, that fixed due date chazara schedules do not allow start dates. could change in the future
                    return nil
                case .horizontalDelay(let delayedFrom, let daysDelayed, _):
                    // will now try to calculate the right date

                    guard let delayedFrom = delayedFrom else {
                        let activeDate: Date? = ChazaraPoint.getActiveDate(section.initialDate, delay: daysDelayed)
                        setActiveDate(activeDate)
                        return activeDate
                    }
                    
                    let delayedFromResult = ChazaraPoint.getCDChazaraPoint(section: section, scheduledChazara: delayedFrom)
                    guard let delayedFromPoint = delayedFromResult.point, let delayedFromPointContext = delayedFromResult.context else {
                        print("Error: delayedFrom could not be found.")
                        
                        let activeDate: Date? = nil
                        setActiveDate(activeDate)
                        
                        return activeDate
                    }
                    
                    return delayedFromPointContext.performAndWait {
                        guard let statusRaw = delayedFromPoint.chazaraState?.status, let status = ChazaraStatus(rawValue: statusRaw) else {
                            print("Error: delayedFrom could not be found.")
                            
                            let activeDate: Date? = nil
                            setActiveDate(activeDate)
                            
                            return activeDate
                        }
                        
                        if status == .completed {
                            if let date = delayedFromPoint.chazaraState?.date {
                                
                                let activeDate: Date? = ChazaraPoint.getActiveDate(date, delay: daysDelayed)
                                
                                setActiveDate(activeDate)
                                return activeDate
                            } else {
                                print("Error: Couldn't get active date.")
                                
                                let activeDate: Date? = nil
                                setActiveDate(activeDate)
                                return activeDate
                            }
                        } else {
                            let activeDate: Date? = nil
                            setActiveDate(activeDate)
                            return activeDate
                        }
                    }
                case .verticalDelay(let sectionsDelay, let daysActive, let maxDaysDelayed):
                    return nil
                }
            } else if retryOnFail {
                try? await updateAllData()
                return await getActiveDate(retryOnFail: false)
            } else {
                print("Error: Cannot find information for this ChazaraPoint to getActiveDate. (PID=\(self.id))")
                
                let activeDate: Date? = nil
                setActiveDate(activeDate)
                return activeDate
            }
        }
    }
    
    private static func getActiveDate(_ date: Date, delay: Int) -> Date {
        return date.advanced(by: TimeInterval(delay * 60 * 60 * 24))
    }
    
    /// Gets the date that this ``ChazaraPoint`` is due, if there is one.
    @MainActor
    func getDueDate(retryOnFail: Bool = true) async -> Date? {
        if status == .completed || status == .exempt {
            return nil
        } else {
            if let section = section, let scheduledChazara = scheduledChazara, let scheduleRule = scheduledChazara.scheduleRule {
                
                switch scheduleRule {
                case .fixedDueDate(let dueDate):
                    self.setDueDate(dueDate)
                    return dueDate
                case .horizontalDelay(delayedFrom: let delayedFrom, daysDelayed: let daysDelayed, daysActive: let daysActive):
                    guard let delayedFrom = delayedFrom else {
                        let dueDate: Date? = self.getDueDate(section.initialDate, delay: daysDelayed, daysActive: daysActive)
                        setDueDate(dueDate)
                        
                        return dueDate
                    }
                    
                    let delayedFromPoint = ChazaraPoint.getChazaraPoint(section: section, scheduledChazara: delayedFrom)
                    
                    if delayedFromPoint?.status == .completed {
                        if let date = delayedFromPoint?.date {
                            let dueDate: Date? = self.getDueDate(date, delay: daysDelayed, daysActive: daysActive)
                            setDueDate(dueDate)
                            
                            return dueDate
                        } else {
                            print("Error: Couldn't get due date.")
                            let dueDate: Date? = nil
                            setDueDate(dueDate)
                            
                            return dueDate
                        }
                    } else {
                        let dueDate: Date? = nil
                        setDueDate(dueDate)
                        
                        return dueDate
                    }
                case .verticalDelay(sectionsDelay: let sectionsDelay, daysActive: let daysActive, maxDaysActive: let maxDaysActive):
                    return nil
                }
            } else if retryOnFail {
                try? await updateAllData()
                return await self.getDueDate(retryOnFail: false)
            } else {
                print("Error: Cannot find information for this ChazaraPoint to getDueDate.")
                return nil
            }
        }
    }
    
    @MainActor
    private func getDueDate(_ date: Date, delay: Int, daysActive: Int) -> Date {
        return ChazaraPoint.getActiveDate(date, delay: delay).advanced(by: TimeInterval(daysActive * 60 * 60 * 24))
        /*
        var scheduledChazara = self.scheduledChazara
        if scheduledChazara == nil {
            scheduledChazara = self.getSC()
        }
        
        guard scheduledChazara != nil else {
            print("Missing ScheduledChazara object [SCID=\(self.scheduledChazaraId)]")
            return ChazaraPoint.getActiveDate(date, delay: delay).advanced(by: 2 * 60 * 60 * 24)
            
        }
        if let daysActive = scheduledChazara!.daysActive {
            return ChazaraPoint.getActiveDate(date, delay: delay).advanced(by: TimeInterval(daysActive * 60 * 60 * 24))
        } else {
            print("Missing daysActive value from ScheduledChazara [SCID=\(self.scheduledChazaraId)]")
            return ChazaraPoint.getActiveDate(date, delay: delay).advanced(by: 2 * 60 * 60 * 24)
            
        }*/
    }
    
    
    /// Gets the chazara status that should be assigned to this ``ChazaraPoint`` based on its section and scheduled chazara.
    /// - Returns: The correct ``ChazaraStatus`` that should be applied, based on the local variables.
    func getCorrectChazaraStatus() async -> ChazaraStatus {
        //        await updateAllData()
        //            check first to see if chazara has been completed
        if self.status == .completed {
            return .completed
        } else if status == .exempt {
            return .exempt
        } else {
            guard let scheduleRule = self.scheduledChazara?.scheduleRule else {
                return .unknown
            }
            
            guard let dueDate = await getDueDate(retryOnFail: false) else {
                
                guard case .horizontalDelay(let delayedFrom, _, _) = scheduleRule else {
                    return .unknown
                }
                
                guard let delayedFromId = delayedFrom?.id else {
                    return .unknown
                }
                
                if (try? ChazaraPoint.getCompletionDate(sectionId: sectionId, scheduledChazaraId: delayedFromId)) == nil {
                    return .early
                } else {
                    return .unknown
                }
            }
            
            
            let now = Date.now
            
            if let dateActive = await getActiveDate(retryOnFail: false) {
                if now < dateActive {
                    return .early
                } else if now >= dateActive && now < dueDate {
                    return .active
                } else {
                    return .late
                }
            } else {
                //                assuming that the dateActive is nil because this chazara schedule is based on a fixed rule
                
                if case ScheduleRule.fixedDueDate = scheduleRule {
                } else {
                   assertionFailure("Error: dateActive unexpectedly found nil")
                }
                
                if now < dueDate {
                    return .active
                } else {
                    return .late
                }
            }
        }
    }
    
    /// Assigns the correct computed ``ChazaraStatus`` based on the variables available.
    @MainActor
    func updateCorrectChazaraStatus() async throws {
        let status = await getCorrectChazaraStatus()
        try self.setStatus(status)
    }
    
    static func getCompletionDate(sectionId: CID, scheduledChazaraId: CID) throws -> Date? {
        let result = getCDChazaraPoint(sectionId: sectionId, scheduledChazaraId: scheduledChazaraId)
        guard let point = result.point, let context = result.context else {
            throw RetrievalError.unknownError
        }
        
        return try context.performAndWait {
            guard let statusVal = point.chazaraState?.status, let status = ChazaraStatus(rawValue: statusVal) else {
                throw RetrievalError.missingData
            }
            
            if status == .completed {
                return point.chazaraState?.date
            } else {
                return nil
            }
        }
    }
    
    func getCompletionDate() -> Date? {
        if status == .completed {
            return date
        } else {
            return nil
        }
    }
    
    static func == (lhs: ChazaraPoint, rhs: ChazaraPoint) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
