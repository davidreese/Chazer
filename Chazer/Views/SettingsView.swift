//
//  SettingsView.swift
//  Chazer
//
//  Created by David Reese on 1/27/23.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @State var showRestoreView = false
    @State var showWipeConfirmation = false
    @State var showWipeFailureAlert = false
    @State var showFileExporter = false
    
    @State var backupDocument: BackupFile = BackupFile()
    @State var defaultFilename = "chazerbackup.txt"
    
    @State var restoreView: RestoreView = RestoreView()
    
    var body: some View {
        List {
            Button {
                showRestoreView = true
            } label: {
                Text("Restore from Backup")
            }
            /*
            Button {
                showUploadBackupView = true
            } label: {
                Text("Restore Backup")
            }*/
            
            Button {
                showFileExporter = true
//                let date = Date.now.formatted(date: .numeric, time: .shortened)
            } label: {
                Text("Download Backup")
            }
            .onAppear {
    //                updates the backup file
                self.backupDocument = BackupFile()
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                let formattedDate = dateFormatter.string(from: Date.now)
                defaultFilename = "chazerbackup-\(formattedDate).txt"
                print(defaultFilename)
            }
            .fileExporter(isPresented: $showFileExporter, document: backupDocument, contentType: .plainText, defaultFilename: defaultFilename, onCompletion: {result in})
            Button(role: .destructive) {
                showWipeConfirmation = true
            } label: {
                Text("Erase Data")
            }
        }
        .navigationTitle("Settings")
            .sheet(isPresented: $showRestoreView) {
                restoreView
            }
            .alert("Confirmation", isPresented: $showWipeConfirmation) {
                Button(role: .cancel) {
                    showWipeConfirmation = false
                } label: {
                    Text("Cancel")
                }
                Button(role: .destructive) {
                    showWipeConfirmation = false
                    do {
                        try Storage.shared.wipe()
                        print("Closing app...")
                        exit(0)
                    } catch {
                        showWipeFailureAlert = true
                    }
                } label: {
                    Text("Erase")
                }
            } message: {
                Text("""
Proceeding will erase all app data and close the app.
                    This action cannot be undone.
""")
            }
            .alert(isPresented: $showWipeFailureAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("The erase operation could not be completed.")
                    )
            }
    }
    
    /// Based on https://www.hackingwithswift.com/quick-start/swiftui/how-to-export-files-using-fileexporter
    struct BackupFile: FileDocument {
        // tell the system we support only plain text
        static var readableContentTypes = [UTType.plainText]

        // by default our document is empty
        var text = ChazerApp.getBackup()
        
        init() {}

        // this initializer loads data that has been saved previously
        init(configuration: ReadConfiguration) throws {
            if let data = configuration.file.regularFileContents {
                text = String(decoding: data, as: UTF8.self)
            }
        }

        // this will be called when the system wants to write our data to disk
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let data = Data(text.utf8)
            return FileWrapper(regularFileWithContents: data)
        }
    }
    
    struct RestoreView: View {
        @Environment(\.managedObjectContext) private var viewContext
        @Environment(\.presentationMode) var presentationMode
        
        @State private var rawRestoreString = ""
        
        @State private var showFailAlert = false
        @State private var errorToShow: LocalizedError?
        
        @State var showUploadBackupView = false
        
        @State private var showConfirmation = false
        
        @State private var babyLimuds: Set<BabyLimud>?
        @State private var babySections: Set<BabySection>?
        @State private var babySCs: [BabySC]?
        @State private var babyChazaraPoints: Set<BabyChazaraPoint>?
        
        var body: some View {
            NavigationView {
                List {
                    Button {
                        showUploadBackupView = true
                    } label: {
                        Text("Restore Backup")
                    }
                    .fileImporter(isPresented: $showUploadBackupView, allowedContentTypes: [.plainText]) { result in
                        switch result {
                        case .success(let file):
                            do {
                                let backupText = try String(contentsOf: file)
                                scan(data: backupText)
                            } catch {
                                print("Failed to convert file to a string: \(error.localizedDescription)")
                            }
                        case .failure(let error):
                            print("Failed to import file: \(error.localizedDescription)")
                        }
                    }
                    .onAppear {
                        showUploadBackupView = true
                    }
                }
                /*
                VStack {
                    Spacer()
//                    Text("Restore Data:")
                    TextEditor(text: $rawRestoreString)
//                        .background(Color.yellow)
                        .scrollContentBackground(.hidden)
                        .background(.regularMaterial)
                        .cornerRadius(10)
                        .padding([.horizontal, .bottom])
                        .shadow(radius: 2)
                    Spacer()
                }
                 */
                .toolbar {
                    /*
                    ToolbarItem(placement: .automatic) {
                        Button("Scan") {
                            scan()
                        }
                    }*/
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Label("", systemImage: "xmark")
                                .labelStyle(IconOnlyLabelStyle())
                        }
                    }
                }
                .navigationTitle("Restore Data")
                .alert(isPresented: $showFailAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorToShow?.localizedDescription ?? "nil"),
                                    dismissButton: .default(Text("OK"))
                        )
                }
                .alert("Confirmation", isPresented: $showConfirmation) {
                    Button(role: .cancel) {
                        showConfirmation = false
                    } label: {
                        Text("Cancel")
                    }
                    Button(role: .destructive) {
                        showConfirmation = false
                        restore()
                        print("Closing app...")
                        exit(0)
                    } label: {
                        Text("Confirm")
                    }
                } message: {
                    Text("""
Valid Results: \(babyLimuds?.count.description ?? "nil") limudim, \(babySections?.count.description ?? "nil") sections, \(babySCs?.count.description ?? "nil") Scheduled Chazaras, \(babyChazaraPoints?.count.description ?? "nil") Chazara Points
This action will wipe all existing data and close the app.
""")
                }

            }
        }
        
        /// Executes the wipe and the adding of new data.
        private func restore() {
            guard let babyLimuds = babyLimuds, let babySections = babySections, let babySCs = babySCs, let babyChazaraPoints = babyChazaraPoints else {
                print("Error: Local baby groups are nil.")
                self.errorToShow = RestoreError.unknownError
                self.showFailAlert = true
                return
            }
            
            do {
                try Storage.shared.wipe()
                
                var cdLimuds: [CDLimud] = []
                
            limuds: for baby in babyLimuds {
                    let newLimud = CDLimud(context: viewContext)
                    newLimud.id = baby.id
                    newLimud.name = baby.name
                    newLimud.sections = NSSet()
                    cdLimuds.append(newLimud)
                }
                
            sections: for baby in babySections {
                    let newSection = CDSection(context: viewContext)
                    newSection.sectionId = baby.id
                    newSection.sectionName = baby.name
                    
                    newSection.initialDate = baby.initialDate
                    guard let cdLimud = cdLimuds.first(where: { cdLimud in
                        cdLimud.id == baby.limudId
                    }) else {
                        print("Warning: Unexpectedly found nil for limud id")
                        continue sections
                    }
                    newSection.limud = cdLimud
                
                cdLimud.sections = cdLimud.sections?.adding(newSection) as? NSSet
                }
                
                var cdSCs: [CDScheduledChazara] = []
                
            scs: for baby in babySCs {
                let newSC = CDScheduledChazara(context: viewContext)
                newSC.scId = baby.id
                newSC.scName = baby.name
                
                newSC.isDynamic = baby.isDynamic
                newSC.fixedDueDate = baby.fixedDueDate
                newSC.delay = baby.delay
//                haven't set delayed from, need to run that afterwards
                
                guard let cdLimud = cdLimuds.first(where: { cdLimud in
                    cdLimud.id == baby.limudId
                }) else {
                    print("Warning: Unexpectedly found nil for limud id")
                    continue scs
                }
                newSC.limud = cdLimud
                
                //        TODO: what if this is nil
                guard let ms = cdLimud.scheduledChazaras?.mutableCopy() as? NSMutableOrderedSet else {
                    throw CreationError.unknownError
                }
                ms.add(newSC)
                cdLimud.scheduledChazaras = ms.copy() as? NSOrderedSet
                
                guard let limud = Limud(cdLimud) else {
                    throw CreationError.unknownError
                }
                
                cdSCs.append(newSC)
            }
                
                for cdSC in cdSCs {
                    guard let baby = babySCs.first(where: { baby in
                        baby.id == cdSC.scId
                    }) else {
                        print("That wasn't supposed to happen...")
                        continue
                    }
                    
                    let delayedFromId = baby.delayedFromId
                    cdSC.delayedFrom = cdSCs.first(where: { match in
                        match.scId == delayedFromId
                    })
                }
                
            cps: for baby in babyChazaraPoints {
                let newPoint = CDChazaraPoint(context: viewContext)
                newPoint.pointId = baby.id
                newPoint.sectionId = baby.sectionId
                newPoint.scId = baby.scId
                
                let state = CDChazaraState(context: viewContext)
                state.stateId = IDGenerator.generate(withPrefix: "CS")
                state.status = baby.status
                state.date = baby.date
                
                newPoint.chazaraState = state
            }
                
                try viewContext.save()
            } catch StorageError.wipeFailure {
                print("Error: Wiping data failed. Cannot restore.")
                self.errorToShow = RestoreError.wipeFailure
                self.showFailAlert = true
                return
            } catch {
                print("Error: Cannot restore.")
                self.errorToShow = error as? LocalizedError
                showFailAlert = true
                return
            }
            
            try! viewContext.save()
        }
        
        
        
        /// Scans the restore data to detect if it is valid, holds onto the data if it is valid, and notifies the user of the results.
        func scan(data: String) {
            let babyLimudim: Set<BabyLimud>
            let babySections: Set<BabySection>
            let babySCs: [BabySC]
            let babyChazaraPoints: Set<BabyChazaraPoint>
            
            let cleanedRestoreString = data.trimmingCharacters(in: .newlines)
            
            do {
                babyLimudim = try parseLimudim(data: cleanedRestoreString)
                babySections = try parseSections(data: cleanedRestoreString)
                babySCs = try parseScheduledChazaras(data: cleanedRestoreString)
                babyChazaraPoints = try parseChazaraPoints(data: cleanedRestoreString)
            } catch ParseError.invalidFormat {
                self.errorToShow = ParseError.invalidFormat
                showFailAlert = true
                return
            } catch {
                self.errorToShow = error as? LocalizedError
                showFailAlert = true
                return
            }
            
            let scsArray = cleanedRestoreString.components(separatedBy: "SCHEDULEDCHAZARAS")
            let pointsArray = cleanedRestoreString.components(separatedBy: "CHAZARAPOINTS")
            
            guard scsArray.count == 2 && pointsArray.count == 2 else {
                self.errorToShow = ParseError.invalidFormat
                showFailAlert = true
                return
            }
            
            guard let scs = scsArray[1].components(separatedBy: "CHAZARAPOINTS").first else {
                self.errorToShow = ParseError.invalidFormat
                showFailAlert = true
                return
            }
            let points = pointsArray[1]
            
            self.babyLimuds = babyLimudim
            self.babySections = babySections
            self.babySCs = babySCs
            self.babyChazaraPoints = babyChazaraPoints
            self.showConfirmation = true
        }
        
        private func parseLimudim(data: String) throws -> Set<BabyLimud> {
            let limudsArray = data.components(separatedBy: "LIMUDS")
            
            guard limudsArray.count == 2 else {
                throw ParseError.invalidFormat
            }
            
            guard let limuds = limudsArray[1].components(separatedBy: "SECTIONS").first else {
                throw ParseError.invalidFormat
            }
            
            var babyLimudim: Set<BabyLimud> = Set()
            let limudData = limuds.components(separatedBy: "CDLimud: ")
        object: for data in limudData {
            var id: ID?
            var name: String?
            
            for pair in data.components(separatedBy: "|") {
                let parts = pair.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0]
                    let value = parts[1]
                    
                    switch key {
                    case "ID":
                        if value == "nil" {
                            continue object
                        } else {
                            id = value.trimmingCharacters(in: .newlines)
                        }
                    case "NAME":
                        name = (value == "nil") ? nil : value.trimmingCharacters(in: .newlines)
                    default:
                        print("Failed to parse data for limud:.")
                        continue object;
                    }
                } else if pair == "" {
                } else {
                    print("Failed to parse data for limud: \(pair)")
                    continue object;
                }
            }
            
            if let id = id {
                babyLimudim.insert(BabyLimud(id: id, name: name))
            }
        }
            
            print("Found \(babyLimudim.count) valid limudim.")
            return babyLimudim
        }
        
        private func parseSections(data: String) throws -> Set<BabySection> {
            let sectionsArray = data.components(separatedBy: "SECTIONS")
            
            guard sectionsArray.count == 2 else {
                throw ParseError.invalidFormat
            }
            
            guard let sections = sectionsArray[1].components(separatedBy: "SCHEDULEDCHAZARAS").first else {
                throw ParseError.invalidFormat
            }
            
            var babySections: Set<BabySection> = Set()
            let sectionData = sections.components(separatedBy: "CDSection: ")
            
            object: for data in sectionData {
                var id: ID?
                var limudId: ID?
                var name: String?
                var initialDate: Date?
                
                for pair in data.components(separatedBy: "|") {
                    let parts = pair.components(separatedBy: "=")
                    if parts.count == 2 {
                        let key = parts[0]
                        let value = parts[1]
                        
                        switch key {
                        case "ID":
                            if value == "nil" {
                                print("Section id is invalid, skipping data point")
                                continue object
                            } else {
                                id = value.trimmingCharacters(in: .newlines)
                            }
                        case "LIMUDID":
                            limudId = (value == "nil") ? nil : value.trimmingCharacters(in: .newlines)
                        case "NAME":
                            name = (value == "nil") ? nil : value.trimmingCharacters(in: .newlines)
                        case "INITIALDATE":
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                                initialDate = dateFormatter.date(from: value.trimmingCharacters(in: .newlines))
                        default:
                            print("Failed to parse data for section: \(pair)")
                            continue object;
                        }
                    } else if pair == "" {
                    } else {
                        print("Failed to parse data for section: \(pair)")
                        continue object;
                    }
                }
                
                if let id = id {
                    babySections.insert(BabySection(id: id, limudId: limudId, name: name, initialDate: initialDate))
                } else {
                    print("Skipping section with nil id")
                }
            }
            
            print("Found \(babySections.count) valid sections.")
            return babySections
        }
        
        private func parseScheduledChazaras(data: String) throws -> [BabySC] {
            let scArray = data.components(separatedBy: "SCHEDULEDCHAZARAS")
            
            guard scArray.count == 2 else {
                throw ParseError.invalidFormat
            }
            
            guard let scs = scArray[1].components(separatedBy: "CHAZARAPOINTS").first else {
                throw ParseError.invalidFormat
            }
            
            var babyScheduledChazaras: [BabySC] = []
            let scheduledChazaraData = scs.components(separatedBy: "CDScheduledChazara: ")
            
        object: for data in scheduledChazaraData {
            var id: ID?
            var limudId: ID?
            var name: String?
            var delayedFrom: ID?
            var delay: Int16!
            var daysToComplete: Int16!
            var fixedDueDate: Date?
            var isDynamic: Bool!
            
            for pair in data.components(separatedBy: "|") {
                let parts = pair.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0]
                    let value = parts[1]
                    
                    switch key {
                    case "ID":
                        if value == "nil" {
                            print("Scheduled chazara id is invalid, skipping data point")
                            continue object
                        } else {
                            id = value.trimmingCharacters(in: .newlines)
                        }
                    case "LIMUDID":
                        limudId = (value == "nil") ? nil : value.trimmingCharacters(in: .newlines)
                    case "NAME":
                        name = (value == "nil") ? nil : value.trimmingCharacters(in: .newlines)
                    case "DELAYEDFROM":
                        delayedFrom = (value == "nil") ? nil : value.trimmingCharacters(in: .newlines)
                    case "DELAY":
                        if let value = Int16(value.trimmingCharacters(in: .newlines)) {
                            delay = value
                        } else {
                            print("Scheduled chazara delay value is invalid, skipping data point")
                            continue object
                        }
                    case "DAYSTOCOMPLETE":
                        if let value = Int16(value.trimmingCharacters(in: .newlines)) {
                            daysToComplete = value
                        } else {
                            print("Scheduled chazara daysToComplete value is invalid, skipping data point")
                            continue object
                        }
                    case "FIXEDDUEDATE":
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                        fixedDueDate = dateFormatter.date(from: value.trimmingCharacters(in: .newlines))
                    case "ISDYNAMIC":
                        if let value = Bool(value.trimmingCharacters(in: .newlines)) {
                            isDynamic = value
                        } else {
                            print("Scheduled chazara isDynamic value is invalid, skipping data point")
                            continue object
                        }
                    default:
                        print("Failed to parse data for scheduled chazara: \(pair)")
                        continue object;
                    }
                } else if pair == "" {
                } else {
                    print("Failed to parse data for scheduled chazara: \(pair)")
                    continue object;
                }
            }
            
            if let id = id {
                babyScheduledChazaras.append(BabySC(id: id, limudId: limudId, delayedFromId: delayedFrom, name: name, isDynamic: isDynamic, fixedDueDate: fixedDueDate, delay: delay, daysToComplete: daysToComplete))
            } else {
                print("Skipping scheduled chazara with nil id")
            }
        }
            
            print("Found \(babyScheduledChazaras.count) valid scheduled chazaras.")
            return babyScheduledChazaras
        }
        
        private func parseChazaraPoints(data: String) throws -> Set<BabyChazaraPoint> {
            let chazaraPointsArray = data.components(separatedBy: "CHAZARAPOINTS")
            
            guard chazaraPointsArray.count == 2 else {
                throw ParseError.invalidFormat
            }
            
            /*
            guard let chazaraPointsData = chazaraPointsArray[1].components(separatedBy: "ENDCHAZARAPOINTS").first else {
                throw ParseError.invalidFormat
            }
             */
            
            let chazaraPointsData = chazaraPointsArray[1]
            
            var babyChazaraPoints: Set<BabyChazaraPoint> = Set()
            let chazaraPointData = chazaraPointsData.components(separatedBy: "CDChazaraPoint: ")
            
            object: for data in chazaraPointData {
                var id: ID!
                var scId: ID!
                var sectionId: ID!
                var status: Int16!
                var date: Date?
                
                for pair in data.components(separatedBy: "|") {
                    let parts = pair.components(separatedBy: "=")
                    if parts.count == 2 {
                        let key = parts[0]
                        let value = parts[1]
                        
                        switch key {
                        case "ID":
                            if value == "nil" {
                                print("Chazara point id is invalid, skipping data point")
                                continue object
                            } else {
                                id = value.trimmingCharacters(in: .newlines)
                            }
                        case "SCID":
                            if value == "nil" {
                                print("Chazara point scId is invalid, skipping data point")
                                continue object
                            } else {
                                scId = value.trimmingCharacters(in: .newlines)
                            }
                        case "SECID":
                            if value == "nil" {
                                print("Chazara point sectionId is invalid, skipping data point")
                                continue object
                            } else {
                                sectionId = value.trimmingCharacters(in: .newlines)
                            }
                        case "STATUS":
                            if let value = Int16(value.trimmingCharacters(in: .newlines)) {
                                status = value
                            } else {
                                print("Chazara point status is invalid, skipping data point")
                                continue object
                            }
                        case "DATE":
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                            date = dateFormatter.date(from: value.trimmingCharacters(in: .newlines))
                        default:
                            print("Failed to parse data for chazara point: \(pair)")
                            continue object;
                        }
                    } else if pair == "" {
                    } else {
                        print("Failed to parse data for chazara point: \(pair)")
                        continue object;
                    }
                }
                
                babyChazaraPoints.insert(BabyChazaraPoint(id: id, scId: scId, sectionId: sectionId, status: status, date: date))
            }
            
            print("Found \(babyChazaraPoints.count) valid chazara points.")
            return babyChazaraPoints
        }

        
        enum ParseError: LocalizedError {
            case invalidFormat
            
            public var errorDescription: String? {
                    switch self {
                    case .invalidFormat:
                        return NSLocalizedString("The restore data is not formatted correctly.", comment: "Parse Error")
                    }
                }
        }
        
        enum RestoreError: LocalizedError {
            case wipeFailure
            case unknownError
            
            public var errorDescription: String? {
                    switch self {
                    case .wipeFailure:
                        return NSLocalizedString("The restore failed because the data wipe did not complete.", comment: "Restore Error")
                    case .unknownError:
                        return NSLocalizedString("An unknown error has occured. The restore could not execute.", comment: "Unknown Error")
                    }
                }
        }
    }
    
    /// Temporary storage structure for limudim when they are waiting to be approved for restore.
    private struct BabyLimud: Hashable {
        let id: ID
        let name: String?
    }
    
    /// Temporary storage strucuret for sections when they are waiting to be approved for restore.
    private struct BabySection: Hashable {
        let id: ID
        let limudId: ID?
        let name: String?
        let initialDate: Date?
    }
    
    /// Temporary storage strucuret for scheudled chazaras when they are waiting to be approved for restore.
    private struct BabySC: Hashable {
        let id: ID
        let limudId: ID?
        let delayedFromId: ID?
        let name: String?
        let isDynamic: Bool
        let fixedDueDate: Date?
        let delay: Int16
        let daysToComplete: Int16
    }
    
    private struct BabyChazaraPoint: Hashable {
        let id: ID
        let scId: ID
        let sectionId: ID
        let status: Int16
        let date: Date?
    }
    
    /*
     func selectFolder() {
     
     let folderChooserPoint = CGPoint(x: 0, y: 0)
     let folderChooserSize = CGSize(width: 500, height: 600)
     let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
     let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
     
     folderPicker.canChooseDirectories = true
     folderPicker.canChooseFiles = true
     folderPicker.allowsMultipleSelection = true
     folderPicker.canDownloadUbiquitousContents = true
     folderPicker.canResolveUbiquitousConflicts = true
     
     folderPicker.begin { response in
     
     if response == .OK {
     let pickedFolders = folderPicker.urls
     
     self.selectedFolder.getFileList(at: pickedFolders)
     }
     }
     }
     */
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
