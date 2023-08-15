//
//  ChazerApp.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import SwiftUI
import UIKit
import CoreData

@main
struct ChazerApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        Storage.shared.update()
        
        Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
            Task {
                await Storage.shared.loadChazaraPoints()
            }
        }
    }
    
    static func printBackup() {
        print(getBackup())
    }
    
    static func getBackup() -> String {
        return "LIMUDS\n" + getCDLimudimData() + "SECTIONS\n" + getCDSectionData() + "SCHEDULEDCHAZARAS\n" + getCDScheduledChazaraData() + "CHAZARAPOINTS\n" + getCDChazaraPointData() + "POINTNOTES\n" + getCDPointNoteData()
    }
    
    /// Migrates data from original data model to data model 2.0, which uses `CDChazaraPoint` instead of `CDExemption` and `CDChazara`.
    private static func migrateData() {
        let context = PersistenceController.shared.container.viewContext
        
        let cdChazaraPoints = printCDChazaraPoints()
        let cdChazaras = printCDChazaras()
        let cdExemptions = printCDExemptions()
        let cdScheduledChazaras = printCDScheduledChazaras()
        let cdSections = printCDSections()
        
        for cdScheduledChazara in cdScheduledChazaras {
            let matches = cdSections.filter { cdSection in
                cdSection.limud?.id == cdScheduledChazara.limud?.id
            }
            
            for cdSection in matches {
                if cdChazaraPoints.contains(where: { cp in
                    cp.sectionId == cdSection.sectionId && cp.scId == cdScheduledChazara.scId
                }) {
                    print("CDChazaraPoint already exists for coordinates: (\(cdSection.sectionId ?? "nil"):\(cdScheduledChazara.scId ?? "nil"))")
                } else {
                    if let cdChazara = cdChazaras.first(where: { cdEntity in
                        cdEntity.sectionId == cdSection.sectionId && cdEntity.scId == cdScheduledChazara.scId
                    }) {
                        guard let id = cdChazara.id, let sectionId = cdChazara.sectionId, let scId = cdChazara.scId else {
                            print("Skipping CDChazaraPoint for CDChazara (\(cdChazara.id ?? "nil")")
                            continue
                        }
                        
                        print("Creating and saving CDChazaraPoint for CDChazara (\(cdChazara.id ?? "nil")")
                        
                        let state = CDChazaraState(context: context)
                        state.stateId = IDGenerator.generate(withPrefix: "CS")
                        state.date = cdChazara.date
                        state.status = 4
                        
                        let cp = CDChazaraPoint(context: context)
                        cp.pointId = id
                        cp.sectionId = sectionId
                        cp.scId = scId
                        cp.chazaraState = state
                        
                        state.chazaraPoint = cp
                        
                        print("COPIED CDChazara to CDChazaraPoint: ID=\(cp.pointId ?? "nil") SECID=\(cp.sectionId ?? "nil") SCID=\(cp.scId ?? "nil") DATE=\(cp.chazaraState?.date?.description ?? "nil") STATUS=\(cp.chazaraState?.status ?? -3)")
                    } else if let cdExemption = cdExemptions.first(where: { cdEntity in
                        cdEntity.sectionId == cdSection.sectionId && cdEntity.scId == cdScheduledChazara.scId
                    }) {
                        guard let id = cdExemption.id, let sectionId = cdExemption.sectionId, let scId = cdExemption.scId else {
                            print("Skipping CDChazaraPoint for CDExemption (\(cdExemption.id ?? "nil")")
                            continue
                        }
                        
                        print("Creating and saving CDChazaraPoint for CDExemption (\(cdExemption.id ?? "nil")")
                        
                        let state = CDChazaraState(context: context)
                        state.stateId = IDGenerator.generate(withPrefix: "CS")
//                        state.date = cdExemption.date
                        state.status = 0
                        
                        let cp = CDChazaraPoint(context: context)
                        cp.pointId = id
                        cp.sectionId = sectionId
                        cp.scId = scId
                        cp.chazaraState = state
                        
                        state.chazaraPoint = cp
                        
                        print("COPIED CDExemption to CDChazaraPoint: ID=\(cp.pointId ?? "nil") SECID=\(cp.sectionId ?? "nil") SCID=\(cp.scId ?? "nil") STATUS=\(cp.chazaraState?.status ?? -3)")
                    } else {
                        guard let sectionId = cdSection.sectionId, let scId = cdScheduledChazara.scId else {
                            print("Skipping CDChazaraPoint for coordinates: (\(cdSection.sectionId ?? "nil"):\(cdScheduledChazara.scId ?? "nil"))")
                            continue
                        }
                        
                        print("Creating and saving CDChazaraPoint for coordinates: (\(cdSection.sectionId ?? "nil"):\(cdScheduledChazara.scId ?? "nil"))")
                        
                        let state = CDChazaraState(context: context)
                        state.stateId = IDGenerator.generate(withPrefix: "CS")
//                        state.date = cdExemption.date
                        state.status = -1
                        
                        let cp = CDChazaraPoint(context: context)
                        cp.pointId = IDGenerator.generate(withPrefix: "CP")
                        cp.sectionId = sectionId
                        cp.scId = scId
                        cp.chazaraState = state
                        
                        state.chazaraPoint = cp
                        
                        print("CREATED CDChazaraPoint: ID=\(cp.pointId ?? "nil") SECID=\(cp.sectionId ?? "nil") SCID=\(cp.scId ?? "nil") STATUS=\(cp.chazaraState?.status ?? -3)")
                    }
                }
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Couldn't migrate data: \(error)")
        }
    }
    
    private static func changeDelayedFrom(for scId: ID, to delayedFromId: ID) {
        let cdScheduledChazara = getCDScheduledChazara(for: scId)
        let newDelayedFrom = getCDScheduledChazara(for: delayedFromId)
        cdScheduledChazara.delayedFrom = newDelayedFrom
        try! PersistenceController.shared.container.viewContext.save()
    }
    
    private static func printCDChazaras() -> [CDChazara] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazara.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDChazara]
        
        print("Listing CDChazaras:")
        for result in results {
            print("CDCHAZARA: ID=\(result.id ?? "nil") SECID=\(result.sectionId ?? "nil") SCID=\(result.scId ?? "nil") DATE=\(result.date?.description ?? "nil")")
        }
        
        return results
    }
    
    private static func printCDExemptions() -> [CDExemption] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDExemption.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDExemption]
        
        print("Listing CDExemptions:")
        for result in results {
            print("CDExemption: ID=\(result.id ?? "nil") SECID=\(result.sectionId ?? "nil") SCID=\(result.scId ?? "nil")")
        }
        
        return results
    }
    
    static func getCDLimudimData() -> String {
       var text = ""
       
       let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDLimud.fetchRequest()
       let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDLimud]
       
       for result in results {
           text += "CDLimud: ID=\(result.id ?? "nil")|NAME=\(result.name ?? "nil")\n"
       }
       
       return text
   }
    
     static func getCDChazaraPointData() -> String {
        var text = ""
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDChazaraPoint]
        
        for result in results {
            text += "CDChazaraPoint: ID=\(result.pointId ?? "nil")|SECID=\(result.sectionId ?? "nil")|SCID=\(result.scId ?? "nil")|DATE=\(result.chazaraState?.date?.description ?? "nil")|STATUS=\(result.chazaraState?.status ?? -3)\n"
        }
        
        return text
    }
    
    static func getCDPointNoteData() -> String {
       var text = ""
       
       let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDPointNote.fetchRequest()
       let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDPointNote]
       
       for result in results {
           guard let id = result.noteId, let note = result.note, let cpId = result.point?.pointId else {
               print("Not backing up note without expected data.")
               continue
           }
           text += "CDPointNote: ID=\(id)|CREATIONDATE=\(result.creationDate?.description ?? "nil")|NOTE=\(note)|CPID=\(cpId)\n"
       }
       
       return text
   }
    
    static func getCDScheduledChazaraData() -> String {
        var text = ""
        
//        this will only collect CDScheduledChazara objects that are tied to a limud. the point is mainly to preserve ordering
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDLimud.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDLimud]
        
        for result in results {
            guard let cdScheduledChazaras = result.scheduledChazaras?.array as? [CDScheduledChazara] else {
                continue
            }
            for cdSC in cdScheduledChazaras {
                text += "CDScheduledChazara: ID=\(cdSC.scId ?? "nil")|NAME=\(cdSC.scName ?? "nil")|LIMUDID=\(cdSC.limud?.id ?? "nil")|DELAYEDFROM=\(cdSC.delayedFrom?.scId ?? "nil")|DELAY=\(cdSC.delay)|DAYSTOCOMPLETE=\(cdSC.daysToComplete)|FIXEDDUEDATE=\(cdSC.fixedDueDate?.description ?? "nil")|ISDYNAMIC=\(cdSC.isDynamic)\n"
            }
        }
        
        return text
    }
    
    private static func getCDSectionData() -> String {
        var text = ""
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDSection]
        
        for result in results {
            text += "CDSection: ID=\(result.sectionId ?? "nil")|NAME=\(result.sectionName ?? "nil")|LIMUDID=\(result.limud?.id ?? "nil")|INITIALDATE=\(result.initialDate?.description ?? "nil")\n"
        }
        
        return text
    }
    
    private static func printCDChazaraPoints() -> [CDChazaraPoint] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDChazaraPoint]
        
        print("Listing CDChazaraPoints:")
        for result in results {
            print("CDChazaraPoint: ID=\(result.pointId ?? "nil") SECID=\(result.sectionId ?? "nil") SCID=\(result.scId ?? "nil") DATE=\(result.chazaraState?.date?.description ?? "nil") STATUS=\(result.chazaraState?.status ?? -3)")
        }
        
        return results
    }
    
     static func printCDScheduledChazaras() -> [CDScheduledChazara] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDScheduledChazara]
        
        print("Listing CDScheduledChazaras:")
        for result in results {
            print("CDScheduledChazara: ID=\(result.scId ?? "nil")|NAME=\(result.scName ?? "nil")|LIMUDID=\(result.limud?.id ?? "nil")|DELAYEDFROM=\(result.delayedFrom?.scId ?? "nil")|DELAY=\(result.delay)")
        }
        
        return results
    }
    
    private static func printCDSections() -> [CDSection] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDSection.fetchRequest()
        let results = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest) as! [CDSection]
        
        print("Listing CDSections:")
        for result in results {
            print("CDSection: ID=\(result.sectionId ?? "nil")|NAME=\(result.sectionName ?? "nil")")
        }
        
        return results
    }
    
    private static func killCDScheduledChazara(id: ID? = nil) {
        //        MARK: SAVIOR CODE!
        if id == nil {
            print("Deleting all CDScheduledChazaras. Printing a list of all that existed...")
            printCDScheduledChazaras()
            print()
        }
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
        if let id = id {
            fetchRequest.predicate = NSPredicate(format: "scId == %@", id)
        }
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try! PersistenceController.shared.container.viewContext.execute(deleteRequest)
    }
    
    private static func killCDChazaraPoint(id: ID? = nil) {
        //        MARK: SAVIOR CODE!
        if id == nil {
            print("Deleting all CDChazaraPoints. Printing a list of all that existed...")
            printCDChazaraPoints()
            print()
        }
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDChazaraPoint.fetchRequest()
        if let id = id {
            fetchRequest.predicate = NSPredicate(format: "pointId == %@", id)
        }
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try! PersistenceController.shared.container.viewContext.execute(deleteRequest)
    }
    
    /*
    private func changeDelayedFrom(of id: ID, to newDelayedFromId: ID?) {
        //        MARK: SAVIOR CODE!
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "scId == %@", id)
        let result = try! persistenceController.container.viewContext.fetch(fetchRequest).first as! CDScheduledChazara
        
        let dfFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
        if let dfId = newDelayedFromId {
            dfFetchRequest.predicate = NSPredicate(format: "scId == %@", dfId)
            let dfResult = try! persistenceController.container.viewContext.fetch(dfFetchRequest).first as! CDScheduledChazara
            result.delayedFrom = dfResult
        } else {
            result.delayedFrom = nil
        }
        try! persistenceController.container.viewContext.save()
    }
     */
    
    private static func getCDScheduledChazara(for scId: ID) -> CDScheduledChazara {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDScheduledChazara.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "scId == %@", scId)
        let cdScheduledChazara = try! PersistenceController.shared.container.viewContext.fetch(fetchRequest).first as! CDScheduledChazara
        return cdScheduledChazara
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//                .environmentObject(storage)
        }
    }
}
