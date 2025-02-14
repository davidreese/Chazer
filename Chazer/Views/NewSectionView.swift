//
//  NewSectionView.swift
//  Chazer
//
//  Created by David Reese on 9/18/22.
//

import SwiftUI

struct NewSectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var sectionName: String = ""
//    @State var limud: Limud?
    @State var limudId: CID?
    var initialLimud: Limud?
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\CDLimud.name)],
        animation: .default)
    private var cdLimudim: FetchedResults<CDLimud>
    
    @State var initialLearningDate: Date = Date()
    
    var onUpdate: ((_ limud: Limud) -> Void)?
    
    var limudim: [Limud] {
        var temp: [Limud] = []
        for cdLimud in cdLimudim {
            if let limud = try? Limud(cdLimud, context: viewContext) {
                temp.append(limud)
            }
        }
        return temp
    }
    
    init(initialLimud: Limud?, initialSectionName: String = "", onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        self.initialLimud = initialLimud
//        self.limud = initialLimud// ?? Limud()
        self.sectionName = initialSectionName
        self.onUpdate = onUpdate
    }
    
    init(onUpdate: ((_ limud: Limud) -> Void)? = nil) {
//        self.limud = Limud()
        self.sectionName = ""
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationView {
                Form {
                    Picker("Limud", selection: $limudId) {
                        ForEach(cdLimudim) { cdl in
                            if let limud = try? Limud(cdl, context: viewContext) {
                                Text(limud.name)
                                    .tag(limud.id)
                            }
                        }
                    }

                TextField("Section Name", text: $sectionName)
//                    .textFieldStyle(PlainTextFieldStyle())
                    
                    DatePicker("Initial Learning Date", selection: $initialLearningDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            .navigationTitle("New Section")
//            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: {
                        do {
                            let newLimud = try addSection()
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
            self.limudId = initialLimud?.id
        }
    }
    
    private func addSection() throws -> Limud {
//        guard !limud.id.isEmpty else {
//            throw CreationError.missingData
//        }
        
        
        guard let limud = limudim.first(where: { limud in
            limud.id == limudId
        }) else {
            throw CreationError.missingData
        }

        if sectionName.isEmpty || sectionName.count > 80 {
            throw CreationError.invalidName
        }
        
        let fr = CDLimud.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", limud.id)
        
        
        return try viewContext.performAndWait {
            guard let results = try? viewContext.fetch(fr), let cdLimud = results.first else {
                throw CreationError.invalidData
            }
            
            //        var cdLimud = limud.cdLimud()
            
            let newItem = CDSection(context: viewContext)
            newItem.sectionId = IDGenerator.generate(withPrefix: "S")
            newItem.sectionName = sectionName
            
            /*
            if abs(initialLearningDate.distance(to: Date.now)) < 60 {
                newItem.initialDate = initialLearningDate
            } else {
                newItem.initialDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: initialLearningDate)
            }*/
            newItem.initialDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: initialLearningDate)
            newItem.limud = cdLimud
            //        newItem.
            
            cdLimud.sections = cdLimud.sections?.adding(newItem) as NSSet?
            
            let section = try Section(newItem, context: viewContext)
            
            section.generatePoints()
            
            let newLimud = try Limud(cdLimud, context: viewContext)
            
            try withAnimation {
                try viewContext.save()
            }
            
            return newLimud
        }
    }
}

struct NewSectionView_Previews: PreviewProvider {
    static var previews: some View {
        NewSectionView()
    }
}
