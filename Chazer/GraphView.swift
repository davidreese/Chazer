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
                List {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    
                                    Text("Section")
                                        .bold()
                                        .frame(width: nameWidth)
                                    
                                    Text("Date")
                                        .frame(width: dateWidth)
                                    //                                    LazyHStack {
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
                                .cornerRadius(6)
                                .shadow(radius: 2)
                                .frame(height: headerCellHeight)
                                
                                let sortedSections = model.limud.sections.sorted(by: { lhs, rhs in
                                    lhs.initialDate > rhs.initialDate
                                })
                                
                                //                            LazyVStack {
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
                                .padding(.leading, 3)
                            }
                            Spacer()
                        }
                        //                        .padding(.horizontal)
                    }
                    //                        .ignoresSafeArea([.container], edges: [.horizontal])
                }
                .listStyle(PlainListStyle())
                .scrollIndicators(.hidden)
                .ignoresSafeArea([.container], edges: [.horizontal])
                //                .listSectionSeparator(.hidden)
                
                //                .ignoresSafeArea([.container], edges: [.trailing])
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
        .ignoresSafeArea([.container], edges: [.horizontal])
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
        
        var text: String? {
            switch status {
            case .early:
                return getActiveDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? ""
            case .active:
                return getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            case .late:
                return getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            case .completed:
                return getCompletionDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            case .unknown:
                return nil
            case .exempt:
                return nil
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
                            try removeChazaras()
                        } catch {
                            print("Couldn't remove chazaras: \(error)")
                        }
                    })
                    Button("Change Chazara Date", action: showCompletionDateEditor)
                } else if status == .exempt {
                    Button("Unexempt", action: {
                        do {
                            try removeExemptions()
                        } catch {
                            print("Couldn't remove exemptions: \(error)")
                        }
                    })
                } else {
                    Button("Mark as Chazered", action: {
                        do {
                            try markAsChazered()
                        } catch {
                            print("Couldn't mark as chazered: \(error)")
                        }
                    })
                    Button("Exempt", action: {
                        do {
                            try markExempt()
                        } catch {
                            print("Couldn't mark as exempt: \(error)")
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
                        Text(text ?? "")
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
        
        /// Removes `CDChazara` objects for this chazara point.
        private func removeChazaras() throws {
            let chazaras = getCDChazaras()
            for chazara in chazaras {
                viewContext.delete(chazara)
                try viewContext.save()
            }
            update()
        }
        
        /// Removes `CDExemption` objects for this chazara point.
        private func removeExemptions() throws {
            let exemptions = getCDExemptions()
            for exemption in exemptions {
                viewContext.delete(exemption)
                try viewContext.save()
            }
            update()
        }
        
        func showCompletionDateEditor() {
            self.showingDateChanger = true
        }
        
        func markAsChazered(date: Date? = nil) throws {
            let chazara = CDChazara(context: viewContext)
            chazara.id = IDGenerator.generate(withPrefix: "C")
            chazara.scId = scheduledChazara.id
            chazara.sectionId = section.id
            chazara.date = date ?? Date()
            
            try viewContext.save()
            
            update()
        }
        
        func markExempt() throws {
            let exemption = CDExemption(context: viewContext)
            exemption.id = IDGenerator.generate(withPrefix: "E")
            exemption.scId = scheduledChazara.id
            exemption.sectionId = section.id
            
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
            case exempt
            
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
                case .exempt:
                    return .blue
                }
            }
        }
        
        private static func wasChazaraDone(context: NSManagedObjectContext, on section: Section, for scheduledChazara: ScheduledChazara) -> Bool {
            let chazaras = getCDChazaras(context: context, section: section, scheduledChazara: scheduledChazara)
            
            if chazaras.count == 1 {
                return true
            } else if chazaras.count > 1 {
                print("Something is wrong, but at least you chazered \(chazaras.count) times.")
                return true
            } else {
                return false
            }
        }
        
        private func wasChazaraDone(on section: Section, for scheduledChazara: ScheduledChazara) -> Bool {
            return StatusBox.wasChazaraDone(context: viewContext, on: section, for: scheduledChazara)
        }
        
        /// Default caller for `wasChazaraDone`.
        private func wasChazaraDone() -> Bool {
            return wasChazaraDone(on: section, for: scheduledChazara)
        }
        
        private static func getCDChazaras(context: NSManagedObjectContext, section: Section, scheduledChazara: ScheduledChazara) -> [CDChazara] {
            let fr: NSFetchRequest<CDChazara> = CDChazara.fetchRequest()
            
            let sectionPredicate = NSPredicate(format: "scId = %@", scheduledChazara.id)
            let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", section.id)
            let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
            
            fr.predicate = compound
            
            let results: [CDChazara] = try! context.fetch(fr)
            
            return results
        }
        
        private func getCDChazaras(section: Section, scheduledChazara: ScheduledChazara) -> [CDChazara] {
            return StatusBox.getCDChazaras(context: viewContext, section: section, scheduledChazara: scheduledChazara)
        }
        
        /// Default caller for ``getCDChazaras(section:scheduledChazara:)``.
        private func getCDChazaras() -> [CDChazara] {
            return getCDChazaras(section: section, scheduledChazara: scheduledChazara)
        }
        
        /// Retreive exemptions from a given data context.
        /// - Parameters:
        ///   - context: The `NSManagedObjectContext` to search.
        ///   - section: The `Section` to search at.
        ///   - scheduledChazara: The `ScheduledChazara` to search at.
        /// - Returns: An array of `CDExemption` objects that are assigned to these paramaters.
        private static func getCDExemptions(context: NSManagedObjectContext, section: Section, scheduledChazara: ScheduledChazara) -> [CDExemption] {
            let fr: NSFetchRequest<CDExemption> = CDExemption.fetchRequest()
            
            let sectionPredicate = NSPredicate(format: "scId = %@", scheduledChazara.id)
            let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", section.id)
            let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
            
            fr.predicate = compound
            
            let results: [CDExemption] = try! context.fetch(fr)
            
            return results
        }
        
        /// Local caller of ``StatusBox/getCDExemptions(context:section:scheduledChazara:)`` used to retreive exemptions from CoreData.
        /// - Parameters:
        ///   - section: The `Section` to search at.
        ///   - scheduledChazara: The `ScheduledChazara` to search at.
        /// - Returns: An array of `CDExemption` objects that are assigned to these paramaters.
        private func getCDExemptions(section: Section, scheduledChazara: ScheduledChazara) -> [CDExemption] {
            return StatusBox.getCDExemptions(context: viewContext, section: section, scheduledChazara: scheduledChazara)
        }
        
        /// Default caller of ``getCDExemptions(section:scheduledChazara:)`` used to get all the exemptions at this chazara point.
        /// - Returns: An array of `CDExemption` objects that are assigned to this chazara point.
        private func getCDExemptions() -> [CDExemption] {
            return getCDExemptions(section: section, scheduledChazara: scheduledChazara)
        }
        
        /// Checks for an exemption at a given data point.
        /// - Parameters:
        ///   - context: The `NSManagedObjectContext` to search.
        ///   - section: The `Section` to search at.
        ///   - scheduledChazara: The `ScheduledChazara` to search at.
        /// - Returns: `true` if there is at least one exemption found.
        /// - Note: A warning will be printed to the console if more than one exemption is found.
        private static func wasExempted(context: NSManagedObjectContext, on section: Section, for scheduledChazara: ScheduledChazara) -> Bool {
            let exemptions = getCDExemptions(context: context, section: section, scheduledChazara: scheduledChazara)
            
            if exemptions.count == 1 {
                return true
            } else if exemptions.count > 1 {
                print("Warning: More than one exemption (\(exemptions.count)) found. (SEC=\(section.id):SCH=\(scheduledChazara.id))")
                return true
            } else {
                return false
            }
        }
        
        /// Local caller of ``StatusBox/wasExempted(context:section:scheduledChazara:)`` used to check for an exemption at a given data point.
        /// - Parameters:
        ///   - section: The `Section` to search at.
        ///   - scheduledChazara: The `ScheduledChazara` to search at.
        /// - Returns: `true` if there is at least one exemption found.
        /// - Note: A warning will be printed to the console if more than one exemption is found.
        private func wasExempted(on section: Section, for scheduledChazara: ScheduledChazara) -> Bool {
            return StatusBox.wasExempted(context: viewContext, on: section, for: scheduledChazara)
        }
        
        /// Default caller of ``wasExempted(section:scheduledChazara:)`` used to check for an exemption at this chazara point.
        /// - Returns: `true` if there is at least one exemption found.
        /// - Note: A warning will be printed to the console if more than one exemption is found.
        private func wasExempted() -> Bool {
            return wasExempted(on: section, for: scheduledChazara)
        }
        
        /// Gets the chazara status that should be assigned to this `StatusBox` based on its section and scheduled chazara.
        /// - Returns: The correct `ChazaraStatus` that should be applied, based on the data in storage.
        func getChazaraStatus() -> ChazaraStatus {
            //            check first to see if chazara has been completed
            if wasChazaraDone() {
                return .completed
            } else {
                if wasExempted() {
                    return .exempt
                }
                
                if let delay = scheduledChazara.delay {
                    if let delayedFrom = scheduledChazara.delayedFrom {
                        if wasChazaraDone(on: section, for: delayedFrom) {
                            let chazaras = getCDChazaras(section: section, scheduledChazara: delayedFrom)
                            
                            if let date = chazaras.first?.date {
                                return StatusBox.dateStatus(from: date, delayed: delay)
                            } else {
                                print("Something went wrong getting last date for scheduled chazara timing")
                                return .unknown
                            }
                        } else {
                            return .early
                        }
                    } else {
                        return StatusBox.dateStatus(from: section.initialDate, delayed: delay)
                    }
                } else if scheduledChazara.fixedDueDate != nil {
                    return .active
                } else {
                    print("Unexpected error: scheduledChazara has no valid due rule")
                    return .unknown
                }
            }
        }
        
        private func getActiveDate() -> Date? {
            if wasChazaraDone() {
                return nil
            } else {
                if let delay = scheduledChazara.delay {
                    if let delayedFrom = scheduledChazara.delayedFrom {
                        if wasChazaraDone(on: section, for: delayedFrom) {
                            let chazaras = getCDChazaras(section: section, scheduledChazara: delayedFrom)
                            
                            if let date = chazaras.first?.date {
                                return StatusBox.getActiveDate(date, delay: delay)
                            } else {
                                print("Something went wrong getting last date for scheduled chazara timing")
                                return nil
                            }
                        } else {
                            return nil
                        }
                    } else {
                        return StatusBox.getActiveDate(section.initialDate, delay: delay)
                    }
                } else if let fixedDueDate = scheduledChazara.fixedDueDate {
                    return fixedDueDate
                } else {
                    print("Unexpected Error: ScheduledChazara has no valid due rule.")
                    return nil
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
                if let delay = scheduledChazara.delay {
                    if let delayedFrom = scheduledChazara.delayedFrom {
                        if wasChazaraDone(on: section, for: delayedFrom) {
                            let fr = CDChazara.fetchRequest()
                            
                            let sectionPredicate = NSPredicate(format: "scId = %@", delayedFrom.id)
                            let scheduledChazaraPredicate = NSPredicate(format: "sectionId = %@", section.id)
                            let compound = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scheduledChazaraPredicate])
                            
                            fr.predicate = compound
                            
                            let result: [CDChazara] = try! viewContext.fetch(fr)
                            
                            if let date = result.first?.date {
                                return StatusBox.getDueDate(date, delay: delay)
                            } else {
                                print("Something went wrong getting last date for scheduled chazara timing")
                                return nil
                            }
                        } else {
                            return nil
                        }
                    } else {
                        return StatusBox.getDueDate(section.initialDate, delay: delay)
                    }
                } else if let fixedDueDate = scheduledChazara.fixedDueDate {
                    return fixedDueDate
                } else {
                    print("Unexpected Error: ScheduledChazara has no valid due rule.")
                    return nil
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
            
            private var cdChazara: CDChazara
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


