//
//  GraphView.swift
//  Chazer
//
//  Created by David Reese on 9/19/22.
//

import SwiftUI
import CoreData

// TODO: Update this documentation once ScheduledChazara class changes to not be universal
/// A view that shows the ``ChazaraState`` for every ``ScheduledChazara`` of a ``Limud``.
struct GraphView: View {
    @StateObject private var model: GraphViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var onUpdate: (() -> Void)?
    
    @State var showingNewSectionView = false
    @State var showingAddChazaraScheduleView = false
    @State var showingEditChazaraScheduleView = false
    @State var showingManageSectionView = false
    
    
    //    var columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(limud: Limud, onUpdate: (() -> Void)? = nil) {
        self._model = StateObject(wrappedValue: GraphViewModel(limud: limud))
        self.onUpdate = onUpdate
        
        //        UIScrollView.appearance().bounces = false
    }
    
    var nameWidth = 100.0
    var dateWidth = 130.0
    var chazaraWidth = 140.0
    var cellHeight = 90.0
    var headerCellHeight = 50.0
    
    var body: some View {
        //        VStack {
        if !model.limud.sections.isEmpty {
            List {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        //                            Spacer()
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
                                        Button("Manage", action: {
                                            self.model.scheduledChazaraToUpdate = sc
                                            self.showingEditChazaraScheduleView = true
                                        })
                                        Button("Delete", action: {
                                            try? deleteSC(sc)
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
                                            Button("Manage", action: {
                                                self.model.sectionToUpdate = section
                                                self.showingManageSectionView = true
                                            })
                                            Button("Delete", action: {
                                                withAnimation {
                                                    try? deleteSection(section)
                                                }
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
//                                            model.objectWillChange.send()
                                        })
                                        .frame(width: chazaraWidth)
                                    }
                                }.frame(height: cellHeight)
                            }
                            .padding(.leading, 3)
                        }
                        //                            Spacer()
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                
                //                        .ignoresSafeArea([.container], edges: [.horizontal])
                
            }
            
            .listStyle(PlainListStyle())
            //                .background(Color.clear)
            //                .navigationBarHidden(true)
            .scrollIndicators(.hidden)
            //                .ignoresSafeArea([.container], edges: [.horizontal])
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
            //                .ignoresSafeArea([.container], edges: [.horizontal])
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
                        Storage.shared.update()
                    }
                })
                .environment(\.managedObjectContext, self.viewContext)
            }
            .sheet(isPresented: $showingEditChazaraScheduleView) {
                if let scheduledChazaraToUpdate = self.model.scheduledChazaraToUpdate {
                    EditChazaraScheduleView(limudId: self.model.limud.id, scheduledChazara: scheduledChazaraToUpdate, onUpdate: { limud in
                        /*print("Updating...")
                        withAnimation {
                            self.model.limud = limud
                            self.model.objectWillChange.send()
                            self.onUpdate?()
                            Storage.shared.update()
                        }*/
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
            .sheet(isPresented: $showingManageSectionView) {
                if let sectionToUpdate = self.model.sectionToUpdate {
                    EditSectionView(limudId: self.model.limud.id, section: sectionToUpdate, onUpdate: { limud in
                        /*self.model.limud = limud
                        self.model.objectWillChange.send()
                        self.onUpdate?()*/
                    })
                    .environment(\.managedObjectContext, self.viewContext)
                }
            }
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
    }
    
    private func deleteSection(_ section: Section) throws {
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
    
    private func deleteSC(_ scheduledChazara: ScheduledChazara) throws {
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
    
    /// A view that displays the state of a single ``ChazaraPoint``.
    struct StatusBox: View {
        @Environment(\.managedObjectContext) private var viewContext
        //        private var viewContext: NSManagedObjectContext
        
        @StateObject private var model: StatusBoxModel
        
        private let section: Section
        private let scheduledChazara: ScheduledChazara
        
        @State var showingDateChanger = false
        @State var isShowingNewNotePopover = false
        @State var isShowingNotesPopover = false
        @State var newNoteText = ""
        
        @State var isShowingError = false
        
        var updateParent: (() -> Void)?
        
        init(section: Section, scheduledChazara: ScheduledChazara/*, viewContext: NSManagedObjectContext*/, onUpdate updateParent: (() -> Void)? = nil) {
            self.section = section
            self.scheduledChazara = scheduledChazara
            //            self.viewContext = viewContext
            self.updateParent = updateParent
            //            self.status = getChazaraStatus()
//            self.model = StatusBoxModel(section: section, scheduledChazara: scheduledChazara)
            
            
            self._model = StateObject(wrappedValue: StatusBoxModel(section: section, scheduledChazara: scheduledChazara))
        }
        
        var body: some View {
            let status = model.point?.status ?? .unknown
            let hasNotes = !(model.point?.notes?.isEmpty ?? true)
            Menu {
                if status == .completed {
                    Button("Unmark", action: {
                        //                        get the deleting to work and the editing to work
                        Task {
                            do {
                                try await removeChazara()
                            } catch {
                                print("Couldn't remove chazaras: \(error)")
                            }
                        }
                    })
                    Button("Change chazara date", action: showCompletionDateEditor)
                } else if status == .exempt {
                    Button("Unexempt", action: {
                        Task {
                            do {
                                try await removeExemption()
                            } catch {
                                print("Couldn't remove exemptions: \(error)")
                            }
                        }
                    })
                } else {
                    Button("Mark as chazered", action: {
                        Task {
                            do {
                                try await markAsChazered()
                            } catch {
                                print("Couldn't mark as chazered: \(error)")
                            }
                        }
                    })
                    Button("Mark as exempt", action: {
                        Task {
                            do {
                                try await markExempt()
                            } catch {
                                print("Couldn't mark as exempt: \(error)")
                            }
                        }
                    })
                }
                
                Button("Add a note", action: {
                    isShowingNewNotePopover = true
                })
                
                if hasNotes {
                    Button("Notes", action: {
//                        model.printNotes("E")
//                        print(model.point?.notes)
                        isShowingNotesPopover = true
                    })
                }
            } label: {
                Rectangle()
                    .fill(status.descriptionColor())
                    .cornerRadius(4)
                    .shadow(radius: 2)
                    .overlay(content: {
                        Text(model.text ?? "")
                            .font(.callout)
                            .bold()
                            .foregroundColor(.primary)
                            .onChange(of: model.text) { _ in
                                Task {
                                    await update()
                                }
                            }
                    })
                    .overlay {
                        VStack {
                            if hasNotes {
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(.yellow)
                                        .frame(width: 8, height: 8)
                                        .shadow(radius: 2)
                                }
                                .padding(8)
                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            await update()
                        }
                    }
                    .sheet(isPresented: $showingDateChanger) {
                        if let point = model.point, let date = model.point?.getCompletionDate() {
                            ChazaraDateChanger(chazaraPoint: point, initialDate: date, onUpdate: {
                                //                                self.updateParent?()
                                self.model.point?.updatePointData()
                                //                                print(model.point?.date)
                                self.model.updateText()
                                self.updateParent?()
                            })
                            .environment(\.managedObjectContext, self.viewContext)
                            //                                .presentationDetents([.medium])
                            //                        }
                        }
                    }
            }
            .padding()
            .popover(isPresented: $isShowingNewNotePopover) {
                NavigationStack {
                    TextEditor(text: $newNoteText)
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button("Done") {
                                    if !newNoteText.isEmpty {
                                        do {
                                            try saveNote()
                                        } catch {
                                            isShowingError = true
                                        }
                                    }
                                }
                            }
                        }
                }
                    .frame(width: 300, height: 175)
            }
            .popover(isPresented: $isShowingNotesPopover) {
                
//                Text("Notes")
//                    .font(.title)
                if let notes = model.point?.notes {
//                    NavigationStack {\
                    VStack {
                        HStack {
                            Text("Notes")
                                .font(.headline)
                            Spacer()
                            Button {
                                isShowingNotesPopover = false
                            } label: {
                                Image(systemName: "checkmark")
                            }
                        }
                            .padding([.top, .horizontal])
                        List {
                            ForEach(notes) { note in
                                if let noteText = note.note {
                                    TextField("Note", text: .constant(noteText), axis: .vertical)
                                        .lineLimit(5)
                                }
                            }.onDelete { indexSet in
                                guard let min = indexSet.min(), let max = indexSet.max() else {
                                    return
                                }
                                
                                var elementsToRemove: [PointNote] = []
                                for i in min...max {
                                    elementsToRemove.append(notes[i])
                                }
                                
                                for note in elementsToRemove {
                                    do {
                                        let fetchRequest = CDPointNote.fetchRequest()
                                        fetchRequest.predicate = NSPredicate(format: "noteId == %@", note.id)
                                        
                                        let results = try viewContext.fetch(fetchRequest)
                                        
                                        for result in results {
                                            viewContext.delete(result)
                                        }
                                        
                                        try viewContext.save()
                                    } catch {
                                        print("Error: Failed to delete point note from data store.")
                                    }
                                }
                                
//                                view updates
                                withAnimation {
                                    isShowingNotesPopover = false
                                    model.point?.updatePointData()
                                    model.objectWillChange.send()
                                }
                            }
                        }
                        //                    }
                    }
                        .frame(width: 300, height: 200)
                }
            }
            .alert(isPresented: $isShowingError) {
                Alert(
                    title: Text("Error"),
                    message: Text("The operation could not be completed.")
                )
            }
        }
        
        /// Removes chazara for this point.
        private func removeChazara() async throws {
            await model.point?.removeChazara()
            await update()
        }
        
        /// Removes an exemption for this chazara point.
        private func removeExemption() async throws {
            await model.point?.removeExemption()
            await update()
        }
        
        func showCompletionDateEditor() {
            self.showingDateChanger = true
        }
        
        func markAsChazered(date: Date = Date()) async throws {
            await model.point?.markAsChazered(date: date)
            await update()
        }
        
        func markExempt() async throws {
            await model.point?.markAsExempt()
            await update()
        }
        
        func update() async {
            //            self.model.point?.updateData()
            await self.model.point?.updateCorrectChazaraStatus()
            self.model.updateText()
//            self.model.objectWillChange.send()
            updateParent?()
        }
        
        private func saveNote() throws {
            guard let cdPoint = model.point?.fetchCDEntity(), let context = cdPoint.managedObjectContext, let notesSet = cdPoint.notes?.mutableCopy() as? NSMutableOrderedSet else {
                throw CreationError.unknownError
            }
            
            let newNote = CDPointNote(context: context)
            newNote.creationDate = Date.now
            newNote.note = newNoteText
            newNote.noteId = IDGenerator.generate(withPrefix: "PN")
            
            notesSet.add(newNote)
            cdPoint.notes = notesSet.copy() as? NSOrderedSet
            
            try context.save()
            
            withAnimation {
                self.newNoteText = ""
                isShowingNewNotePopover = false
                model.point?.updatePointData()
                model.objectWillChange.send()
            }
        }
        
        struct ChazaraDateChanger: View {
            @Environment(\.managedObjectContext) private var viewContext
            @Environment(\.presentationMode) var presentationMode
            
            @ObservedObject var chazaraPoint: ChazaraPoint
            @State var date: Date = Date()
            
            var updateParent: (() -> Void)?
            
            init(chazaraPoint: ChazaraPoint, initialDate: Date, onUpdate updateParent: (() -> Void)? = nil) {
                self.chazaraPoint = chazaraPoint
                self.date = initialDate
                self.updateParent = updateParent
            }
            
            init(chazaraPoint: ChazaraPoint, onUpdate updateParent: (() -> Void)? = nil) {
                self.chazaraPoint = chazaraPoint
                self.updateParent = updateParent
            }
            
            var body: some View {
                NavigationView {
                    Form {
                        DatePicker("Chazara Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }.navigationTitle("Change Chazara Date")
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button {
                                    try? updateDate()
                                    updateParent?()
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Text("Done")
                                }
                            }
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(role: .cancel) {
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
                self.chazaraPoint.setDate(Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date))
                self.chazaraPoint.objectWillChange.send()
                updateParent?()
            }
        }
    }
    
    @MainActor
    class StatusBoxModel: ObservableObject {
        @Published var point: ChazaraPoint?
        private let sectionId: ID
        private let scId: ID
        
        init(container: NSPersistentContainer = PersistenceController.shared.container, section: Section, scheduledChazara: ScheduledChazara) {
            self.sectionId = section.id
            self.scId = scheduledChazara.id
            
            self.point = Storage.shared.getChazaraPoint(sectionId: sectionId, scId: scId, createNewIfNeeded: true)
            /*
            let fetchRequest = CDChazaraPoint.fetchRequest()
            
            let sectionPredicate = NSPredicate(format: "sectionId == %@", section.id)
            let scPredicate = NSPredicate(format: "scId == %@", scheduledChazara.id)
            let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [sectionPredicate, scPredicate])
            fetchRequest.predicate = andPredicate
            
            do {
                let results = try container.newBackgroundContext().fetch(fetchRequest)
                
                if results.count == 1, let result = results.first {
                    let newChazaraPoint = ChazaraPoint(result)
                    self.point = newChazaraPoint
                    //                    self.point?.updateCorrectChazaraStatus()//updateCorrectChazaraStatus()
                    //                    print("P \(point?.status.rawValue)")
                    
                } else if results.isEmpty {
                    print("Warning: Couldn't find CDChazaraPoint for StatusBox.")
                    
                    do {
                        print("Creating a CDChazaraPoint for this spot...")
                        let context = PersistenceController.shared.container.viewContext
                        let point = CDChazaraPoint(context: context)
                        
                        point.pointId = IDGenerator.generate(withPrefix: "CP")
                        point.sectionId = self.sectionId
                        point.scId = self.scId
                        
                        let state = CDChazaraState(context: context)
                        state.stateId = IDGenerator.generate(withPrefix: "CS")
                        state.status = -1
                        
                        point.chazaraState = state
                        
                        try context.save()
                        
                        let newChazaraPoint = ChazaraPoint(point)
                        self.point = newChazaraPoint
                        
                        print("Generated and saved a CDChazaraPoint.")
                    } catch {
                        print("Error: Couldn't save new CDChazaraPoint.")
                    }
                } else if results.count > 1 {
                    print("Error: Found multiple CDChazaraPoints for StatusBox.")
                }
            } catch {
                print("Error: Couldn't find CDChazaraPoint for StatusBox.")
                //                return
            }
            
//            self.notes = self.point?.notes?.array as? [CDPointNote]
//            printNotes()
             */
        }
        
        @Published var text: String?
        
        func getText() async -> String? {
            switch point?.status ?? .unknown {
            case .early:
                return await point?.getActiveDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? ""
            case .active:
                return await point?.getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "nil"
            case .late:
                return await point?.getDueDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "nil"
            case .completed:
                return point?.getCompletionDate()?.formatted(.dateTime.month(.abbreviated).day()) ?? "E"
            case .unknown:
                return nil
            case .exempt:
                return ""
            }
        }
        
        func updateText() {
            Task {
                let result = await getText()
                    self.text = result
            }
        }
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(limud: Limud(id: "L", name: "Gittin", sections: [Section(id: "S", name: "Shiur 1", initialDate: Date())], scheduledChazaras: [ScheduledChazara(id: "SC", delaySinceInitial: 1)]))
    }
}
