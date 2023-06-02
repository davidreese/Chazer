//
//  EditSectionView.swift
//  Chazer
//
//  Created by David Reese on 5/28/23.
//

import SwiftUI
import CoreData

struct EditSectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    var onUpdate: ((_ limud: Limud) -> Void)?
    
    var limudId: ID
    var section: Section
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDLimud .name, ascending: true)],
        animation: .default)
    private var cdLimudim: FetchedResults<CDLimud>
    
    var limudim: [Limud] {
        var temp: [Limud] = []
        for cdLimud in cdLimudim {
            if let limud = Limud(cdLimud) {
                temp.append(limud)
            }
        }
        return temp
    }
    
    @State private var cdSections: [CDSection] = []

    @State var secName: String = ""
    @State var initialDate: Date = Date.now
    
    init(limudId: ID, section: Section, onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        self.limudId = limudId
        self.section = section
        self.secName = section.name
        self.initialDate = section.initialDate
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationView {
            Form {
                SwiftUI.Section {
//                    Picker("Limud", selection: $limudId) {
//                        ForEach(cdLimudim) { cdl in
//                            if let limud = Limud(cdl) {
//                                Text(limud.name)
//                                    .tag(limud.id)
//                            }
//                        }
//                    }
                    
                    TextField("Section Name", text: $secName)
                    //                    .textFieldStyle(PlainTextFieldStyle())
                    
                }
                
                SwiftUI.Section {
//                        TextField("", value: $delay, formatter: NumberFormatter())
                    DatePicker("Initial Date", selection: self.$initialDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Section")
            //            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update", action: {
                        do {
                            let newLimud = try updateSection()
                            onUpdate?(newLimud)
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Error saving section: \(error)")
                        }
                    }).buttonStyle(BorderedProminentButtonStyle())
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Label("", systemImage: "xmark")
                            .labelStyle(IconOnlyLabelStyle())
                    }
                    
                }
            }
        }
        .onAppear {
            self.secName = section.name
            self.initialDate = section.initialDate
            updateOtherSections()
        }
    }
    
    func updateOtherSections() {
        let fr: NSFetchRequest<CDSection> = CDSection.fetchRequest()
        fr.predicate = NSPredicate(format: "limud.id == %@", limudId)
        
        guard let results = try? viewContext.fetch(fr) else {
            print("Failed to update scheduled chazaras list")
            return
        }
        
        withAnimation {
            self.cdSections = results.filter({ cdSection in
                cdSection.sectionId != self.section.id
            })
            print("Updated schedule chazaras list")
        }
    }
    
    
    private func updateSection() throws -> Limud {
//        fatalError()
        guard let cdSection = Storage.shared.getCDSection(cdSectionId: self.section.id) else {
            throw UpdateError.unknownError
        }
        
        cdSection.sectionName = self.secName
        cdSection.initialDate = self.initialDate
        
        try withAnimation {
            try cdSection.managedObjectContext!.save()
        }
        
        guard let limud = limudim.first(where: { limud in
            limud.id == limudId
        }) else {
            throw CreationError.missingData
        }
        
//        Task {
//            Storage.shared.loadScheduledChazaras()
//        }
        
        return limud
        /*
        
        cdLimud.scheduledChazaras?.first(where: { cdSC in
            cdSC.
        })
        
        if scName.isEmpty || scName.count > 80 {
            throw CreationError.invalidName
        }
    
        let fr = CDLimud.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", limud.id)
        
        guard let results = try? viewContext.fetch(fr), let cdLimud = results.first else {
            throw CreationError.invalidData
        }
        
        let newItem = CDScheduledChazara(context: viewContext)
        newItem.scId = "SC\(Date().timeIntervalSince1970)\(Int.random(in: 100...999))"
        newItem.scName = scName
        newItem.delay = Int16(delay)
        
        let delayedFrom: CDScheduledChazara?
        if delayedFromId == "init" {
            delayedFrom = nil
        } else {
            delayedFrom = cdScheduledChazaras.first(where: { cdsc in
                cdsc.scId == delayedFromId
            })
            
            if delayedFrom == nil {
                throw CreationError.invalidData
            }
        }
        
        newItem.delayedFrom = delayedFrom
        //        newItem.
        
        //        fix: what if this is nil
        guard let ms = cdLimud.scheduledChazaras?.mutableCopy() as? NSMutableOrderedSet else {
            throw CreationError.unknownError
        }
        ms.add(newItem)
        cdLimud.scheduledChazaras = ms.copy() as? NSOrderedSet
        
        guard let limud = Limud(cdLimud) else {
            throw CreationError.unknownError
        }
        
        try withAnimation {
            try viewContext.save()
        }
        
        return limud
         */
    }
}

