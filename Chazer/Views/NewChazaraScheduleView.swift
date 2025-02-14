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
    
    @State var limudId: CID?
    var initialLimud: Limud?
    
    @State private var cdScheduledChazaras: [CDScheduledChazara] = []
//    @State private var fixedDueMode = false
    @State private var ruleType: RuleType = .horizontalDelay
    
    @State var scId: CID = ""
    @State var scName: String = ""
    @State var fixedDueDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 10)
    @State var delay = 1
    @State var daysActive = 2
    @State var delayedFromId: CID = "init"
    @State var sectionDelay = 1
    @State var maxDaysActive: Int = 10
    @State var limitMaxDaysActive = false
    
    @State var hiddenFromDashboard = false
    
    var limudim: [Limud] {
        var temp: [Limud] = []
        for cdLimud in cdLimudim {
            if let limud = try? Limud(cdLimud, context: viewContext) {
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
                            if let limud = try? Limud(cdl, context: viewContext) {
                                Text(limud.name)
                                    .tag(limud.id)
                            }
                        }
                    }
                    
                    TextField("Schedule Name", text: $scName)
                    //                    .textFieldStyle(PlainTextFieldStyle())
                    
                }
                SwiftUI.Section {
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
                    
                    //                        TextField("", value: $delay, formatter: NumberFormatter())
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
                    } else if case .verticalDelay = ruleType {
                        Stepper("\(sectionDelay) Section Delay", value: $sectionDelay, in: 0...100)
                        
                        Stepper("\(daysActive) Days Active", value: $daysActive, in: 0...1500)
                        
                        SwiftUI.Section {
                            Toggle("Max Days Active Limit", isOn: $limitMaxDaysActive)
                            if limitMaxDaysActive {
                                Stepper("\(maxDaysActive) Days Active", value: $maxDaysActive, in: 0...1500)
                            }
                        }
                    }
                }
                
                SwiftUI.Section {
                    Toggle(isOn: $hiddenFromDashboard, label: {
                        Text("Hidden from Dashboard")
                    })
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
        
        return try viewContext.performAndWait {
            guard let results = try? viewContext.fetch(fr), let cdLimud = results.first else {
                throw CreationError.invalidData
            }
            
            let newSC = CDScheduledChazara(context: viewContext)
            if self.scId.isEmpty {
                newSC.scId = IDGenerator.generate(withPrefix: "SC")
            } else {
                newSC.scId = self.scId
            }
            newSC.scName = scName
            
            if case .fixedDate = self.ruleType {
                newSC.isDynamic = false
            } else {
                newSC.isDynamic = true
            }
            
            switch self.ruleType {
            case .fixedDate:
                newSC.fixedDueDate = self.fixedDueDate
                break
            case .horizontalDelay:
                newSC.delay = Int16(delay)
                newSC.daysToComplete = Int16(daysActive)
                
                let delayedFrom: CDScheduledChazara?
                if delayedFromId == nil {
                    delayedFrom = nil
                } else {
                    delayedFrom = cdScheduledChazaras.first(where: { cdsc in
                        cdsc.scId == delayedFromId
                    })
                    
                    if delayedFrom == nil {
                        throw CreationError.invalidData
                    }
                }
                
                newSC.delayedFrom = delayedFrom
                break
            case .verticalDelay:
                break
            }
            
            newSC.hiddenFromDashboard = hiddenFromDashboard
            
            //        TODO: what if this is nil
            guard let ms = cdLimud.scheduledChazaras?.mutableCopy() as? NSMutableOrderedSet else {
                throw CreationError.unknownError
            }
            ms.add(newSC)
            cdLimud.scheduledChazaras = ms.copy() as? NSOrderedSet
            
            guard let limud = try? Limud(cdLimud, context: viewContext) else {
                throw CreationError.unknownError
            }
            
            try withAnimation {
                try viewContext.save()
            }
            
            return limud
        }
    }
}

struct NewChazaraScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NewChazaraScheduleView()
    }
}
