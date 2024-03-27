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
    
    var limudId: CID
    var section: Section
    
    @State private var cdSections: [CDSection] = []

    @State var secName: String = ""
    @State var initialDate: Date = Date.now
    
    init(limudId: CID, section: Section, onUpdate: ((_ limud: Limud) -> Void)? = nil) {
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
    
    
    /// Updates the ``Section`` being considered by this view
    /// - Returns: The updated ``Limud`` object holding the updated ``Section``
    @MainActor
    private func updateSection() throws -> Limud {
//        fatalError()
        let cdSectionResult = Storage.shared.pinCDSection(id: self.section.id)
        guard let cdSection = cdSectionResult.section, let context = cdSectionResult.context else {
            throw UpdateError.unknownError
        }
        
        try context.performAndWait {
            
            cdSection.sectionName = self.secName
            cdSection.initialDate = self.initialDate
            
            try withAnimation {
                try context.save()
            }
        }
        
        guard let cdLimud = cdSection.limud, let limud = try? Limud(cdLimud, context: viewContext) else {
            throw UpdateError.unknownError
        }
        
//        if let sectionId = cdSection.sectionId {
//            Storage.shared.updateSection(sectionId: sectionId)
//        }

        
//        Task {
//            Storage.shared.loadScheduledChazaras()
//        }
        
        return limud
    }
}

