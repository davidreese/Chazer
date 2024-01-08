//
//  NewChazaraScheduleView.swift
//  Chazer
//
//  Created by David Reese on 9/20/22.
//

import SwiftUI
import CoreData

struct NewChazaraScheduleView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    var onUpdate: ((_ limud: Limud) -> Void)?
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\CDLimud.name)],
        animation: .default)
    private var cdLimudim: FetchedResults<CDLimud>
    
    @State var limudId: ID?
    var initialLimud: Limud?
    
    @State private var cdScheduledChazaras: [CDScheduledChazara] = []
    @State private var fixedDueMode = false
    
    @State var scId: ID = ""
    @State var scName: String = ""
    @State var fixedDueDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 10)
    @State var delay = 1
    @State var daysActive = 2
    @State var delayedFromId: ID = "init"
    
    var limudim: [Limud] {
        var temp: [Limud] = []
        for cdLimud in cdLimudim {
            if let limud = Limud(cdLimud) {
                temp.append(limud)
            }
        }
        return temp
    }
    
    init(initialLimud: Limud?, initialSCName: String = "", onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        self.initialLimud = initialLimud
        //        self.limud = initialLimud// ?? Limud()
        self.scName = initialSCName
        self.onUpdate = onUpdate
    }
    
    init(onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        //        self.limud = Limud()
        self.scName = ""
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationView {
            Form {
                SwiftUI.Section {
                    TextField("ID (Optional)", text: $scId)
                }
                
                SwiftUI.Section {
                    Picker("Limud", selection: $limudId) {
                        ForEach(cdLimudim) { cdl in
                            if let limud = Limud(cdl) {
                                Text(limud.name)
                                    .tag(limud.id)
                            }
                        }
                    }
                    
                    TextField("Schedule Name", text: $scName)
                    //                    .textFieldStyle(PlainTextFieldStyle())
                    
                }
                SwiftUI.Section {
                    Toggle("Fixed Due Date", isOn: self.$fixedDueMode.animation())
//                        TextField("", value: $delay, formatter: NumberFormatter())
                    if fixedDueMode {
                        DatePicker("Due Date", selection: $fixedDueDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    } else {
                        Picker("Delayed From", selection: $delayedFromId) {
                            Text("Initial Learning")
                                .tag("init")
                            ForEach(cdScheduledChazaras.filter({ cdsc in
                                cdsc.scId != nil
                            }), id: \.scId) { cdsc in
                                if let sc = ScheduledChazara(cdsc) {
                                    Text(sc.name)
                                        .tag(sc.id)
                                }
                            }
                            .onAppear {
                                print(self.cdScheduledChazaras)
                            }
                            
                        }
                        Stepper("\(delay) Day Delay", value: $delay, in: 0...1500)
                        
                        Stepper("\(daysActive) Days Active", value: $daysActive, in: 0...1500)
                    }
                }
            }
            .navigationTitle("New Scheduled Chazara")
            //            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: {
                        do {
                            let newLimud = try addScheduledChazara()
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
            updateOtherScheduledChazaras()
        }
    }
    
    func updateOtherScheduledChazaras() {
        if let limudId = limudId {
            let fr: NSFetchRequest<CDScheduledChazara> = CDScheduledChazara.fetchRequest()
            fr.predicate = NSPredicate(format: "limud.id == %@", limudId)
            
            guard let results = try? viewContext.fetch(fr) else {
                print("Failed to update scheduled chazaras list")
                return
            }
            
            withAnimation {
                self.cdScheduledChazaras = results
                print("Updated schedule chazaras list")
            }
        } else {
            withAnimation {
                self.cdScheduledChazaras = []
                print("Updated schedule chazaras list")
            }
        }
    }
    
    private func addScheduledChazara() throws -> Limud {
        guard let limud = limudim.first(where: { limud in
            limud.id == limudId
        }) else {
            throw CreationError.missingData
        }
        
        if scName.isEmpty || scName.count > 80 {
            throw CreationError.invalidName
        }
    
        let fr = CDLimud.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", limud.id)
        
        guard let results = try? viewContext.fetch(fr), let cdLimud = results.first else {
            throw CreationError.invalidData
        }
        
        let newItem = CDScheduledChazara(context: viewContext)
        if self.scId.isEmpty {
            newItem.scId = IDGenerator.generate(withPrefix: "SC")
        } else {
            newItem.scId = self.scId
        }
        newItem.scName = scName
        
        if self.fixedDueMode {
            newItem.fixedDueDate = self.fixedDueDate
            newItem.isDynamic = false
        } else {
            newItem.delay = Int16(delay)
            newItem.daysToComplete = Int16(daysActive)
            
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
            newItem.isDynamic = true
        }
        //        newItem.
        
        //        TODO: what if this is nil
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
    }
}

struct NewChazaraScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NewChazaraScheduleView()
    }
}
