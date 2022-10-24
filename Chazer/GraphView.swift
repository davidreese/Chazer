//
//  GraphView.swift
//  Chazer
//
//  Created by David Reese on 9/19/22.
//

import SwiftUI

struct GraphView: View {
    @ObservedObject var model: GraphViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var onUpdate: (() -> Void)?
    
    @State var showingNewSectionView = false
    @State var showingAddChazaraScheduleView = false
    @State var showingEditChazaraScheduleView = false
    
    //    var columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(limud: Limud, onUpdate: (() -> Void)? = nil) {
        self.model = GraphViewModel(limud: limud)
        self.onUpdate = onUpdate
        
        UIScrollView.appearance().bounces = false
    }
    
    var nameWidth = 100.0
    var dateWidth = 130.0
    var chazaraWidth = 140.0
    var cellHeight = 90.0
    var headerCellHeight = 50.0
    
    var body: some View {
        VStack {
            if !model.limud.sections.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                Text("Section")
                                    .bold()
                                    .frame(width: nameWidth)
                                
                                Text("Date")
                                    .frame(width: dateWidth)
                                
                                ForEach(model.limud.scheduledChazaras) { sc in
                                    Menu(content: {
                                        Button("Delete Scheduled Chazara", action: {
                                            try? deleteSC(sc)
                                        })
                                        Button("Edit Scheduled Chazara", action: {
                                            self.model.scheduledChazaraToUpdate = sc
                                            self.showingEditChazaraScheduleView = true
                                        })
                                    }) {
                                        Text(sc.name)
                                            .frame(width: chazaraWidth)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(4)
                            .shadow(radius: 2)
                            .frame(height: headerCellHeight)
                            
                            let sortedSections = model.limud.sections.sorted(by: { lhs, rhs in
                                lhs.initialDate > rhs.initialDate
                            })
                            
                            ForEach(sortedSections) { section in
                                HStack {
                                    HStack {
                                        Menu(content: {
                                            Button("Delete Section", action: {
                                                try? deleteSection(section)
                                            })
                                        }) {
                                            Text(section.name)
                                                .bold()
                                                .padding()
                                                .frame(width: nameWidth)
                                                .foregroundColor(.primary)
                                        }
                                        Text(section.initialDate.formatted(date: Date.FormatStyle.DateStyle.numeric, time: .omitted))
                                            .font(.callout)
                                            .frame(width: dateWidth)
                                    }
                                    
                                    ForEach(model.limud.scheduledChazaras) { sc in
                                        StatusBox(section: section, scheduledChazara: sc/*, viewContext: self.viewContext*/, onUpdate: {
                                            model.objectWillChange.send()
                                        })
                                        .frame(width: chazaraWidth)
                                        
                                    }
                                }.frame(height: cellHeight)
                            }
                        }
                        .padding(.leading, 3)
                    }
                }
            } else {
                Text("You don't have any saved sections to chazer yet.")
                    .font(Font.title3)
                    .multilineTextAlignment(.center)
                Button {
                    //                            self.limudShowing = limud
                    self.showingNewSectionView = true
                } label: {
                    Text("New Section")
                }
                .buttonStyle(BorderedProminentButtonStyle())
                
            }
        }
        .padding(.horizontal)
        .onAppear {
            self.model.objectWillChange.send()
        }
        .navigationTitle(model.limud.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu(content: {
                    Button {
                        self.showingNewSectionView = true
                    } label: {
                        Label("Add a Section", systemImage: "note.text")
                    }
                    Button {
                        self.showingAddChazaraScheduleView = true
                    } label: {
                        Label("Add Scheduled Chazara", systemImage: "calendar")
                    }
                    //                        Button {
                    //                            self.showingEditChazaraScheduleView = true
                    //                        } label: {
                    //                            Label("Edit the Chazara Schedule", systemImage: "calendar")
                    //                        }
                }, label: {
                    Label("Add", systemImage: "plus")
                }) {
                    self.showingNewSectionView = true
                }
            }
        }
        .sheet(isPresented: $showingAddChazaraScheduleView) {
            NewChazaraScheduleView(initialLimud: self.model.limud, onUpdate: { limud in
                withAnimation {
                    self.model.limud = limud
                    self.model.objectWillChange.send()
                }
            })
            .environment(\.managedObjectContext, self.viewContext)
        }
        .sheet(isPresented: $showingEditChazaraScheduleView) {
            if let scheduledChazaraToUpdate = self.model.scheduledChazaraToUpdate {
                EditChazaraScheduleView(limudId: self.model.limud.id, scheduledChazara: scheduledChazaraToUpdate, onUpdate: { limud in
                    withAnimation {
                        self.model.limud = limud
                        self.model.objectWillChange.send()
                    }
                })
                .environment(\.managedObjectContext, self.viewContext)
            }
        }
        .sheet(isPresented: $showingNewSectionView) {
            NewSectionView(initialLimud: self.model.limud, onUpdate: { limud in
                withAnimation {
                    self.model.limud = limud
                    self.model.objectWillChange.send()
                }
            })
            .environment(\.managedObjectContext, self.viewContext)
        }
    }
    
    func deleteSection(_ section: Section) throws {
        let fr: NSFetchRequest<CDSection> = CDSection.fetchRequest()
        fr.predicate = NSPredicate(format: "sectionId == %@", section.id)
        
        let results = try viewContext.fetch(fr)
        
        
        
        try withAnimation {
            for result in results {
                viewContext.delete(result)
            }
            
            try viewContext.save()
        }
        
    }
    
    func deleteSC(_ scheduledChazara: ScheduledChazara) throws {
        let fr: NSFetchRequest<CDScheduledChazara> = CDScheduledChazara.fetchRequest()
        fr.predicate = NSPredicate(format: "scId == %@", scheduledChazara.id)
        
        let results = try viewContext.fetch(fr)
        
        
        
        try withAnimation {
            for result in results {
                viewContext.delete(result)
            }
            
            try viewContext.save()
        }
        
    }
    
    
    struct StatusBox: View {
        @Environment(\.managedObjectContext) private var viewContext
        //        private var viewContext: NSManagedObjectContext
        
        @ObservedObject var model = StatusBoxModel()
        
        var section: Section
        var scheduledChazara: ScheduledChazara
        
        @State var showingDateChanger = false
        
        var updateParent: (() -> Void)?
        
        @State var status: ChazaraStatus = .unknown
        
        var text: String {
            switch status {
            case .early:
                return getActiveDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? ""
            case .active:
                return getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            case .late:
                return getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            case .completed:
                return getCompletionDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            default:
                return ""
            }
        }
        
        init(section: Section, scheduledChazara: ScheduledChazara/*, viewContext: NSManagedObjectContext*/, onUpdate updateParent: (() -> Void)? = nil) {
            self.section = section
            self.scheduledChazara = scheduledChazara
            //            self.viewContext = viewContext
            self.updateParent = updateParent
            //            self.status = getChazaraStatus()
        }
        
        var body: some View {
            Menu {
                if status == .completed {
                    Button("Unmark", action: {
//                        get the deleting to work and the editing to work
                        do {
                            try removeCompletions()
                        } catch {
                            print(error)
                        }
                    })
                    Button("Change Chazara Date", action: showCompletionDateEditor)
                } else {
                    Button("Mark as Chazered", action: {
                        do {
                            try markAsChazered()
                        } catch {
                            print("Couldn't mark as chazered: \(error)")
                        }
                    })
                }
            } label: {
                Rectangle()
                    .fill(status.descriptionColor())
                    .cornerRadius(4)
                    .padding()
                    .shadow(radius: 2)
                    .overlay(content: {
                        Text(text)
                            .font(.callout)
                            .bold()
                            .foregroundColor(.primary)
                            .onChange(of: text) { _ in
                                update()
                            }
                    })
                    .onAppear {
                        update()
                    }
                    .sheet(isPresented: $showingDateChanger) {
                        //                        if #available(iOS 16.0, *) {
                        if let chazara = getCDChazaras().first, let date = chazara.date {
                            ChazaraDateChanger(cdChazara: chazara, initialDate: date, onUpdate: updateParent)
                                .environment(\.managedObjectContext, self.viewContext)
                            //                                .presentationDetents([.medium])
                            //                        }
                        }
                    }
            }
        }
        
        func removeCompletions() throws {
            let chazaras = getCDChazaras(section: section, scheduledChazara: scheduledChazara)
            for chazara in chazaras {
                viewContext.delete(chazara)
                try viewContext.save()
            }
            update()
        }
        
        func showCompletionDateEditor() {
            self.showingDateChanger = true
        }
        
        func markAsChazered(date: Date? = nil) throws {
            let chazara = CDChazara(context: viewContext)
            chazara.id = "C\(Date().timeIntervalSince1970)\(Int.random(in: 100...999))"
            chazara.scId = scheduledChazara.id
            chazara.sectionId = section.id
            chazara.date = date ?? Date()
            
            try viewContext.save()
            
            update()
        }
        
        func update() {
            self.status = getChazaraStatus()
            self.model.objectWillChange.send()
            updateParent?()
        }
        
        enum ChazaraStatus {
            case unknown
            case early
            case active
            case late
            case completed
            
            func descriptionColor() -> Color {
                switch self {
                case .early:
                    return .gray
                case .active:
                    return .orange
                case .late:
                    return .red
                case .completed:
                    return .green
                case .unknown:
                    return .white
                }
            }
        }
        
        func wasChazaraDone(for scheduledChazara: ScheduledChazara? = nil) -> Bool {
            let chazaras = getCDChazaras(scheduledChazara: scheduledChazara)
            
            if chazaras.count == 1 {
                return true
            } else if chazaras.count > 1 {
                print("Something is wrong, but at least you chazered \(chazaras.count) times.")
                return true
            } else {
                return false
            }
        }
        
        func getCDChazaras(section: Section? = nil, scheduledChazara: ScheduledChazara? = nil) -> [CDChazara] {
            let fr: NSFetchRequest<CDChazara> = CDChazara.fetchRequest()
            
            let sectionPredicate = NSPredicate(format: "scId = %@", scheduledChazara?.id ?? self.scheduledChazara.id)
            let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", section?.id ?? self.section.id)
            let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
            
            fr.predicate = compound
            
            let results: [CDChazara] = try! viewContext.fetch(fr)
            
            return results
        }
        
        func getChazaraStatus() -> ChazaraStatus {
            //            check first to see if chazara has been completed
            if wasChazaraDone() {
                return .completed
            } else {
                if let delayedFrom = scheduledChazara.delayedFrom {
                    if wasChazaraDone(for: delayedFrom) {
                        let chazaras = getCDChazaras(section: section, scheduledChazara: delayedFrom)
                        
                        if let date = chazaras.first?.date {
                            return StatusBox.dateStatus(from: date, delayed: scheduledChazara.delay)
                        } else {
                            print("Something went wrong getting last date for scheduled chazara timing")
                            return .unknown
                        }
                    } else {
                        return .early
                    }
                } else {
                    return StatusBox.dateStatus(from: section.initialDate, delayed: scheduledChazara.delay)
                }
            }
        }
        
        private func getActiveDate() -> Date? {
            if wasChazaraDone() {
                return nil
            } else {
                if let delayedFrom = scheduledChazara.delayedFrom {
                    if wasChazaraDone(for: delayedFrom) {
                        let chazaras = getCDChazaras(section: section, scheduledChazara: delayedFrom)
                        
                        if let date = chazaras.first?.date {
                            return StatusBox.getActiveDate(date, delay: scheduledChazara.delay)
                        } else {
                            print("Something went wrong getting last date for scheduled chazara timing")
                            return nil
                        }
                    } else {
                        return nil
                    }
                } else {
                    return StatusBox.getActiveDate(section.initialDate, delay: scheduledChazara.delay)
                }
            }
        }
        
        //        func getCDChazara(scheduledChazara: ScheduledChazara? = nil, section: Section? = nil) -> CDChazara {
        //            let fr = CDChazara.fetchRequest()
        //
        //            let sectionPredicate = NSPredicate(format: "scId = %@", delayedFrom.id)
        //            let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", section.id)
        //            let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
        //
        //            fr.predicate = compound
        //
        //            let result: [CDChazara] = try! viewContext.fetch(fr)
        //        }
        
        private func getDueDate() -> Date? {
            if wasChazaraDone() {
                return nil
            } else {
                if let delayedFrom = scheduledChazara.delayedFrom {
                    if wasChazaraDone(for: delayedFrom) {
                        let fr = CDChazara.fetchRequest()
                        
                        let sectionPredicate = NSPredicate(format: "scId = %@", delayedFrom.id)
                        let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", section.id)
                        let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
                        
                        fr.predicate = compound
                        
                        let result: [CDChazara] = try! viewContext.fetch(fr)
                        
                        if let date = result.first?.date {
                            return StatusBox.getDueDate(date, delay: scheduledChazara.delay)
                        } else {
                            print("Something went wrong getting last date for scheduled chazara timing")
                            return nil
                        }
                    } else {
                        return nil
                    }
                } else {
                    return StatusBox.getDueDate(section.initialDate, delay: scheduledChazara.delay)
                }
            }
        }
        
        
        private func getCompletionDate() -> Date? {
            return getCDChazaras().first?.date
        }
        
        private static func dateStatus(from startDate: Date, delayed: Int) -> ChazaraStatus {
            let dateActive = getActiveDate(startDate, delay: delayed)
            let now = Date()
            let dueDate = getDueDate(startDate, delay: delayed)
            
            if now < dateActive {
                return .early
            } else if now >= dateActive && now < dueDate {
                return .active
            } else {
                return .late
            }
        }
        
        private static func getActiveDate(_ date: Date, delay: Int) -> Date {
            return date.advanced(by: TimeInterval(delay * 60 * 60 * 24))
        }
        
        private static func getDueDate(_ date: Date, delay: Int) -> Date {
            return getActiveDate(date, delay: delay).advanced(by: 2 * 60 * 60 * 24)
        }
        
        struct ChazaraDateChanger: View {
            @Environment(\.managedObjectContext) private var viewContext
            @Environment(\.presentationMode) var presentationMode
            
            var cdChazara: CDChazara
            @State var date: Date = Date()
            
            var updateParent: (() -> Void)?
            
            init(cdChazara: CDChazara, initialDate: Date, onUpdate updateParent: (() -> Void)? = nil) {
                self.cdChazara = cdChazara
                self.date = initialDate
                self.updateParent = updateParent
            }
            
            init(cdChazara: CDChazara, onUpdate updateParent: (() -> Void)? = nil) {
                self.cdChazara = cdChazara
                self.updateParent = updateParent
            }
            
            var body: some View {
                NavigationView {
                    Form {
                        DatePicker("Chazara Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }.navigationTitle("Change Chazara Date")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    try? updateDate()
                                    updateParent?()
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Text("Done")
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Label("", systemImage: "xmark")
                                        .labelStyle(IconOnlyLabelStyle())
                                }
                            }
                        }
                }
            }
            
            func updateDate() throws {
                cdChazara.date = self.date
                try viewContext.save()
            }
        }
    }
    
    class StatusBoxModel: ObservableObject {
        
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(limud: Limud(id: "L", name: "Gittin", sections: [Section(id: "S", name: "Shiur 1", initialDate: Date())], scheduledChazaras: [ScheduledChazara(id: "SC", delaySinceInitial: 1)]))
    }
}


