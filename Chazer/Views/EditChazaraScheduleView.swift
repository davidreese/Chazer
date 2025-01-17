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
    @State var delayedFromId: CID = "init"
    
    @State var fixedDueDate: Date = Date.now.addingTimeInterval(60 * 60 * 24 * 10)
    
//    @State private var isStatic: Bool = false
    @State private var ruleType: RuleType = .horizontalDelay
    
    enum RuleType: String {
        case fixedDate = "Fixed Date"
        case horizontalDelay = "Chazara Delay"
        case verticalDelay = "Section Delay"
        
        init (rawValue: String) {
            switch rawValue {
            case "Fixed Date":
                self = .fixedDate
            case "Chazara Delay":
                self = .horizontalDelay
            case "Section Delay":
                self = .verticalDelay
            default:
                self = .fixedDate
            }
        }
        
        init (_ scheduleRule: ScheduleRule) {
            switch scheduleRule {
                
            case .fixedDueDate(_):
                self = .fixedDate
            case .horizontalDelay(_, _, _):
                self = .horizontalDelay
            case .verticalDelay(_, _, _):
                self = .verticalDelay
            }
        }
        
        static let allCases: [RuleType] = [.fixedDate, .horizontalDelay, .verticalDelay]
    }
    
    @State var hiddenFromDashboard = false
    
    init(limudId: CID, scheduledChazara: ScheduledChazara, onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        // *** NOTE: ANY TIME THIS PART IS EDITED, IT NEEDS TO BE UPDATED IN THE .ONAPPEAR BLOCK ***
        self.limudId = limudId
        self.scheduledChazara = scheduledChazara
        self.scName = scheduledChazara.name
        
        let scheduleRule = scheduledChazara.scheduleRule!
        self.ruleType = RuleType(scheduleRule)
        
        self.hiddenFromDashboard = scheduledChazara.hiddenFromDashboard
        self.onUpdate = onUpdate
        
        switch scheduleRule {
        case .fixedDueDate(let date):
            self.fixedDueDate = date
            return
        case .horizontalDelay(delayedFrom: let delayedFrom, daysDelayed: let daysDelayed, daysActive: let daysActive):
            self.delayedFromId = delayedFrom?.id ?? "init"
            self.delay = daysDelayed
            self.daysActive = daysActive
            return
        case .verticalDelay(sectionsDelay: let sectionsDelay, daysActive: let daysActive, maxDaysDelayed: let maxDaysDelayed):
            return
        }
        // *** NOTE: ANY TIME THIS PART IS EDITED, IT NEEDS TO BE UPDATED IN THE .ONAPPEAR BLOCK ***
        
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
//                    Toggle("Fixed Due Date", isOn: self.$isStatic.animation())
                    HStack {
                        Text("Rule Type")
                        Spacer()
                        Picker("Rule Type", selection: $ruleType) {
                            ForEach(RuleType.allCases, id: \.rawValue) { val in
                                Text(val.rawValue)
                                    .tag(val)
                            }
                        }.pickerStyle(.segmented)
                            .frame(maxWidth: 350)
                    }
                    
                    

                    if case .fixedDate = ruleType {
                        DatePicker("Due Date", selection: $fixedDueDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    } else if case .horizontalDelay = ruleType {
                        let options = cdScheduledChazaras.filter({ cdsc in
                            cdsc.scId != nil
                        })
                        Picker("Delayed From", selection: $delayedFromId) {
                            Text("Initial Learning")
                                .tag("init")
                            ForEach(options, id: \.scId!) { cdsc in
                                if let sc = try? ScheduledChazara(cdsc, context: viewContext) {
                                    Text(sc.name)
                                        .tag(sc.id)
                                }
                            }
                        }
                        
                        Stepper("\(delay) Day Delay", value: $delay, in: 0...1500)
                        
                        Stepper("\(daysActive) Days Active", value: $daysActive, in: 0...1500)
                    } else {
                        
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
            
            let scheduleRule = scheduledChazara.scheduleRule!
            
            self.ruleType = RuleType(scheduleRule)
            
            self.hiddenFromDashboard = scheduledChazara.hiddenFromDashboard
            updateOtherScheduledChazaras()
            
            switch scheduleRule {
            case .fixedDueDate(let date):
                self.fixedDueDate = date
                return
            case .horizontalDelay(delayedFrom: let delayedFrom, daysDelayed: let daysDelayed, daysActive: let daysActive):
                self.delayedFromId = delayedFrom?.id ?? "init"
                self.delay = daysDelayed
                self.daysActive = daysActive
                return
            case .verticalDelay(sectionsDelay: let sectionsDelay, daysActive: let daysActive, maxDaysDelayed: let maxDaysDelayed):
                return
            }
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
            
            if case .fixedDate = self.ruleType {
                cdSC.isDynamic = false
            } else {
                cdSC.isDynamic = true
            }
            
            cdSC.fixedDueDate = self.fixedDueDate
            
            cdSC.delay = Int16(self.delay)
            cdSC.daysToComplete = Int16(self.daysActive)
            
            if delayedFromId != cdSC.delayedFrom?.scId {
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
