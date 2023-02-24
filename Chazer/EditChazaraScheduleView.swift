//
//  EditChazaraScheduleView.swift
//  Chazer
//
//  Created by David Reese on 9/29/22.
//

import SwiftUI

struct EditChazaraScheduleView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    var onUpdate: ((_ limud: Limud) -> Void)?
    
    var limudId: ID
    var scheduledChazara: ScheduledChazara
    
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
    
    @State private var cdScheduledChazaras: [CDScheduledChazara] = []

    @State var scName: String = ""
    @State var delay = 1
    @State var delayedFromId: ID?
    
    init(limudId: ID, scheduledChazara: ScheduledChazara, onUpdate: ((_ limud: Limud) -> Void)? = nil) {
        self.limudId = limudId
        self.scheduledChazara = scheduledChazara
        self.scName = scheduledChazara.name
        self.delay = scheduledChazara.delay ?? 1
        self.delayedFromId = scheduledChazara.delayedFrom?.id
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
//                        TextField("", value: $delay, formatter: NumberFormatter())
                        
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
            self.delay = scheduledChazara.delay ?? 1
            self.delayedFromId = scheduledChazara.delayedFrom?.id
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
    
    
    private func updateScheduledChazara() throws -> Limud {
//        fatalError()
        guard let cdSC = Storage.shared.getCDScheduledChazara(cdSCId: self.scheduledChazara.id) else {
            throw UpdateError.unknownError
        }
        
        cdSC.scName = self.scName
//        if let delayedFromId = self.delayedFromId, self.delayedFromId != result.scId && self.delayedFromId != result.delayedFrom?.scId {
//            let dfFr: NSFetchRequest<CDScheduledChazara> = CDScheduledChazara.fetchRequest()
//            dfFr.predicate = NSPredicate(format: "scId == %@", delayedFromId)
//
//            let dfResults = try viewContext.fetch(dfFr)
//
//            guard let dfResult = dfResults.first else {
//                throw UpdateError.unknownError
//            }
//
//            result.delayedFrom = dfResult
//        }
        cdSC.delay = Int16(self.delay)
        
        try withAnimation {
            try cdSC.managedObjectContext!.save()
        }
        
        guard let limud = limudim.first(where: { limud in
            limud.id == limudId
        }) else {
            throw CreationError.missingData
        }
        
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

struct EditChazaraScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        EditChazaraScheduleView(limudId: "", scheduledChazara: ScheduledChazara(id: "", delay: 0, since: nil))
    }
}
