//
//  EditChazaraScheduleView.swift
//  Chazer
//
//  Created by David Reese on 9/29/22.
//

import SwiftUI
import CoreData

struct EditChazaraScheduleView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    var onUpdate: ((_ limud: Limud) -> Void)?
    
    var limudId: CID
    var scheduledChazara: ScheduledChazara
    
    @State private var cdScheduledChazaras: [CDScheduledChazara] = []

    @State var scName: String = ""
    @State var delay = 1
    @State var daysActive = 2
    @State var delayedFromId: CID?
    
    @State var fixedDueDate: Date = Date.now.addingTimeInterval(60 * 60 * 24 * 10)
    
    @State private var fixedDueMode: Bool = false
    
    @State var hiddenFromDashboard = false
    
    init(limudId: CID, scheduledChazara: ScheduledChazara, onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        self.limudId = limudId
        self.scheduledChazara = scheduledChazara
        self.scName = scheduledChazara.name
        self.fixedDueMode = !scheduledChazara.isDynamic
        self.fixedDueDate = scheduledChazara.fixedDueDate ?? Date.now.addingTimeInterval(60 * 60 * 24 * 10)
        self.delay = scheduledChazara.delay ?? 1
        self.daysActive = scheduledChazara.daysActive ?? 2
        self.delayedFromId = scheduledChazara.delayedFrom?.id ?? "init"
        self.hiddenFromDashboard = scheduledChazara.hiddenFromDashboard
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
                    
                    TextField("Schedule Name", text: $scName)
                    //                    .textFieldStyle(PlainTextFieldStyle())
                    
                }
                
                SwiftUI.Section {
                    Toggle("Fixed Due Date", isOn: self.$fixedDueMode.animation())

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
                                if let sc = try? ScheduledChazara(cdsc, context: viewContext) {
                                    Text(sc.name)
                                        .tag(sc.id)
                                }
                            }
                        }
                        
                        Stepper("\(delay) Day Delay", value: $delay, in: 0...1500)
                        
                        Stepper("\(daysActive) Days Active", value: $daysActive, in: 0...1500)
                    }
                }
                
                SwiftUI.Section {
                    Toggle(isOn: $hiddenFromDashboard, label: {
                        Text("Hidden from Dashboard")
                    })
                }
            }
            .navigationTitle("Edit Scheduled Chazara")
            //            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update", action: {
                        do {
                            let newLimud = try updateScheduledChazara()
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
            self.scName = scheduledChazara.name
            
            self.fixedDueMode = !scheduledChazara.isDynamic
            self.fixedDueDate = scheduledChazara.fixedDueDate ?? Date.now.addingTimeInterval(60 * 60 * 24 * 10)
            
            self.delay = scheduledChazara.delay ?? 1
            self.daysActive = scheduledChazara.daysActive ?? 2
            self.delayedFromId = scheduledChazara.delayedFrom?.id
            self.hiddenFromDashboard = scheduledChazara.hiddenFromDashboard
            updateOtherScheduledChazaras()
        }
    }
    
    func updateOtherScheduledChazaras() {
        let fr: NSFetchRequest<CDScheduledChazara> = CDScheduledChazara.fetchRequest()
        fr.predicate = NSPredicate(format: "limud.id == %@", limudId)
        
        guard let results = try? viewContext.fetch(fr) else {
            print("Failed to update scheduled chazaras list")
            return
        }
        
        withAnimation {
            self.cdScheduledChazaras = results.filter({ cdSc in
                cdSc.scId != self.scheduledChazara.id
            })
            print("Updated schedule chazaras list")
        }
    }
    
    /// Applies custom changes to the ``CDScheduledChazara`` object.
    private func updateScheduledChazara() throws -> Limud {
        let cdSCResult = Storage.shared.pinCDScheduledChazara(id: self.scheduledChazara.id)
        
        guard let cdSC = cdSCResult.scheduledChazara, let context = cdSCResult.context else {
            throw UpdateError.unknownError
        }
        
        try context.performAndWait {
            cdSC.scName = self.scName
            cdSC.delay = Int16(self.delay)
            cdSC.daysToComplete = Int16(self.daysActive)
            
            if let delayedFromId = self.delayedFromId, delayedFromId != cdSC.delayedFrom?.scId {
                if delayedFromId == "init" {
                    cdSC.delayedFrom = nil
                } else {
                    let fetchRequest = CDScheduledChazara.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "scId == %@", delayedFromId)
                    let results = try context.fetch(fetchRequest)
                    
                    guard results.count == 1, let result = results.first else {
                        throw UpdateError.unknownError
                    }
                    
                    cdSC.delayedFrom = result
                }
            }
            
            cdSC.hiddenFromDashboard = hiddenFromDashboard
            
            try withAnimation {
                try context.save()
            }
        }
        
        guard let cdLimud = cdSC.limud, let limud = try? Limud(cdLimud, context: viewContext) else {
            throw UpdateError.unknownError
        }
        
//        if let scId = cdSC.scId {
//            Storage.shared.updateScheduledChazara(scId: scId)
//        }
        
        return limud
    }
}

struct EditChazaraScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        EditChazaraScheduleView(limudId: "", scheduledChazara: ScheduledChazara(id: "", delay: 0, since: nil))
    }
}
