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
    final let id: ID
    final let sectionId: ID
    private var section: Section?
    
    final let scheduledChazaraId: ID
    private var scheduledChazara: ScheduledChazara?
    
    final var limudId: ID?
    private var limud: Limud?
    
    @Published private(set) var status: ChazaraStatus!
    /// The date this point was marked to have been chazered
    /// - Note: This value should be `nil` if it has not been marked as chazered
    @Published private(set) var date: Date?
    
    /// The date that this point's chazara is due
    /// - Note: This value is only supposed to exist if the status is active.
    @Published private(set) var dueDate: Date?
    
    
    /// The list of saved notes associated with this ``ChazaraPoint``
    @Published private(set) var notes: [PointNote]?
    
    private final let container = PersistenceController.shared.container
    
    /// Attempts to intansiate a ``ChazaraPoint`` from its CoreData counterpart.
    init?(_ cdChazaraPoint: CDChazaraPoint) {
        guard let id = cdChazaraPoint.pointId, let sectionId = cdChazaraPoint.sectionId, let scheduledChazaraId = cdChazaraPoint.scId, let chazaraState = cdChazaraPoint.chazaraState else {
            print("Error: Invalid CDChazaraPoint. Deleting...")
            return nil
            
            //            deletion code temporarily disabled
            do {
                let context = container.newBackgroundContext()
                context.delete(cdChazaraPoint)
                try context.save()
                print("Deleted invalid CDChazaraPoint.")
            } catch {
                print("Failed to delete invalid CDChazaraPoint")
            }
            
            return nil
        }
        
        let chazaraStateStatus = chazaraState.status
        
        self.id = id
        self.sectionId = sectionId
        self.scheduledChazaraId = scheduledChazaraId
        
        if chazaraStateStatus == -2 {
            //                The chazara status has not yet been set.
            print("Mesg: Chazara status has not yet been set. SECID=\(sectionId) SCID=\(scheduledChazaraId)")
            return nil
        } else {
            guard let status = ChazaraStatus(rawValue: chazaraStateStatus) else {
                print("Error: Invalid status for chazara point. STAT=\(chazaraStateStatus)")
                return nil
            }
            
            self.status = status
            self.date = chazaraState.date
        }
        
        //        moving saved notes array into this object
        if let objects = cdChazaraPoint.notes?.array {
            for obj in objects {
                if let cdNote = obj as? CDPointNote, let note = PointNote(cdNote) {
                    if self.notes == nil {
                        self.notes = [note]
                    } else {
                        self.notes?.append(note)
                    }
                }
            }
        }
        
        Task {
            await updateAllData()
        }
        
        defer {
            print("Instansiated ChazaraPoint (PID=\(id))")
        }
    }
    
    /// Fetches the ``CDChazaraPoint`` associated with this point.
    func fetchCDEntity() -> CDChazaraPoint? {
        return Storage.shared.pinCDChazaraPoint(id: self.id)
    }
    
    /// Updates the data that is only tied to the CDChazaraPoint saved in CoreData.
    /// - Note: To update all data, use ``updateData()``
    @MainActor
    func updatePointData() {
        guard let cdChazaraPoint = Storage.shared.pinCDChazaraPoint(id: self.id) else {
            return
        }
        
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
                if let cdNote = obj as? CDPointNote, let note = PointNote(cdNote) {
                    if self.notes == nil {
                        self.notes = [note]
                    } else {
                        self.notes?.append(note)
                    }
                }
            }
        }
    }
    
    /// Fetches the ``Section`` associated with this point's `sectionId` and saves it.
    /// - Returns: The assosiated  ``Section``, unless it wasn't found.
    @MainActor
    func fetchSection() -> Section? {
        self.section = Storage.shared.updateSection(sectionId: self.sectionId)
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
        self.scheduledChazara = Storage.shared.updateScheduledChazara(scId: self.scheduledChazaraId)
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
            self.limud = Storage.shared.fetchLimud(id: limudId)
        } else {
            guard let limudId = getSection()?.limudId else {
                return nil
            }
            self.limudId = limudId
            self.limud = Storage.shared.fetchLimud(id: limudId)
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
    ///   - sectionId: The ``ID`` of the ``Section`` coordinate to search for.
    ///   - scheduledChazaraId: The ``ID`` of the  ``ScheduledChazara`` coordinate to search for.
    /// - Returns: A ``CDChazaraPoint`` if only one is found for the given coordinates.
    private static func getCDChazaraPoint(sectionId: ID, scheduledChazaraId: ID) -> CDChazaraPoint? {
        return Storage.shared.pinCDChazaraPoint(sectionId: sectionId, scId: scheduledChazaraId)
    }
    
    /// Gets the ``CDChazaraPoint`` for a given position.
    /// - Parameters:
    ///   - context: The context of data in which to search.
    ///   - section: The ``Section`` coordinate to search for.
    ///   - scheduledChazara: The ``ScheduledChazara`` coordinate to search for.
    /// - Returns: A ``CDChazaraPoint`` if only one is found for the given coordinates.
    private static func getCDChazaraPoint(section: Section, scheduledChazara: ScheduledChazara) -> CDChazaraPoint? {
        return getCDChazaraPoint(sectionId: section.id, scheduledChazaraId: scheduledChazara.id)
    }
    
    /// Default caller for ``getCDChazaraPoint(context:section:scheduledChazara:)``.
    private func getCDChazaraPoint() -> CDChazaraPoint? {
        guard let section = section, let scheduledChazara = scheduledChazara else {
            return nil
        }
        
        return ChazaraPoint.getCDChazaraPoint(section: section, scheduledChazara: scheduledChazara)
    }
    
    private static func getChazaraPoint(section: Section, scheduledChazara: ScheduledChazara) -> ChazaraPoint? {
        guard let cdChazaraPoint = getCDChazaraPoint(section: section, scheduledChazara: scheduledChazara) else {
            return nil
        }
        
        return ChazaraPoint(cdChazaraPoint)
    }
    
    private var isUpdating = false
    private var lastUpdate: Date?
    
    //    TODO: Check that this isn't being called too much
    /// Updates all data on this ``ChazaraPoint`` to be consistent with data in the database.
    @MainActor
    func updateAllData() async {
        if !isUpdating {
            if (lastUpdate?.timeIntervalSinceNow ?? 100) > 15 {
                isUpdating = true
                print("Updating all data on point... (PID=\(self.id))")
                
                //            Update the relevant section and scheduled chazara objects\
//            TODO: try and figure these next four lines, what is making this function stop the UI for so long. maybe kill the @MainActor requirements of these functions and figure out a way for them to all run on one thread, like if you create the coredata thread here maybe.
                    self.fetchSection()
                    self.fetchSC()
                    self.updatePointData()
                do {
                    try await self.updateCorrectChazaraStatus()
                } catch {
                    print("Failed to update correct chazara status for (PID=\(self.id)): \(error)")
                }

                isUpdating = false
                lastUpdate = Date.now
            } else {
                print("Not updating data on point because it was updated too recently: (PID=\(self.id))")
            }
        } else {
            print("Not updating data on point because it is updating now: (PID=\(self.id))")
        }
    }
    
    /// Sets the `dueDate` attribute for this object.
    /// - Note: The `dueDate` attribute has no corresponding value in storage.
    @MainActor
    func setDueDate(_ dueDate: Date?) {
        self.dueDate = dueDate
    }
    
    /// Sets the `date` attribute for this object, and also saves it as such in storage.
    @MainActor
    func setDate(_ date: Date?) {
        do {
            guard let entity = self.fetchCDEntity() else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            entity.chazaraState?.date = date
            try entity.managedObjectContext?.save()
            
            //            DispatchQueue.main.async {
            self.date = date
            //            }
        } catch {
            print("Error: Could not set the chazara date: \(error)")
        }
    }
    
    @MainActor
    func setStatus(_ status: ChazaraStatus) throws {
        do {
            guard let entity = self.fetchCDEntity() else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            entity.chazaraState?.status = status.rawValue
            try entity.managedObjectContext?.save()
            
            //            DispatchQueue.main.async {
            self.status = status
            
            //            print("Set status of \(status.rawValue) for ChazaraPoint (\(self.id))")
            //            }
        } catch {
            print("Error: Could not set chazara status: \(error)")
            throw error
        }
    }
    
    @MainActor
    func setState(status: ChazaraStatus, date: Date?) throws {
        do {
            guard let entity = self.fetchCDEntity() else {
                print("Error: Couldn't set state, CDEntity is nil.")
                return
            }
            
            entity.chazaraState?.status = status.rawValue
            entity.chazaraState?.date = date
            
            try entity.managedObjectContext!.save()
            
            self.status = status
            self.date = date
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
            //            no date available
            return nil
        } else {
            if let section = self.section, let scheduledChazara = self.scheduledChazara {
                //                will now try to calculate the right date
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
                print("Error: Cannot find information for this ChazaraPoint to getActiveDate. (PID=\(self.id))")
                return nil
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
            if let section = section, let scheduledChazara = scheduledChazara {
                if let delay = scheduledChazara.delay {
                    if let delayedFrom = scheduledChazara.delayedFrom {
                        let delayedFromPoint = ChazaraPoint.getChazaraPoint(section: section, scheduledChazara: delayedFrom)
                        if delayedFromPoint?.status == .completed {
                            if let date = delayedFromPoint?.date {
                                let dueDate: Date? = ChazaraPoint.getDueDate(date, delay: delay)
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
                    } else {
                        let dueDate: Date? = ChazaraPoint.getDueDate(section.initialDate, delay: delay)
                            setDueDate(dueDate)
                        
                        return dueDate
                    }
                } else if let fixedDueDate = scheduledChazara.fixedDueDate {
                    setDueDate(fixedDueDate)
                    
                    return fixedDueDate
                } else {
                    print("Error: Scheduled chazara has no valid due rule.")
                    let dueDate: Date? = nil
                    setDueDate(dueDate)
                    
                    return dueDate
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
            guard let dateActive = await getActiveDate(retryOnFail: false),
                  let dueDate = await getDueDate(retryOnFail: false) else {
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
    
    /// Assigns the corect computed ``ChazaraStatus`` based on the variables available.
    @MainActor
    func updateCorrectChazaraStatus() async throws {
        let status = await getCorrectChazaraStatus()
        try self.setStatus(status)
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
    
    static func == (lhs: ChazaraPoint, rhs: ChazaraPoint) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
