//
//  ContentView.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject var model: ContentViewModel = ContentViewModel()
    
    @Environment(\.managedObjectContext) private var viewContext
    
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
    
    @State private var showingNewLimudView = false
    @State private var showingDeleteAlert = false
    @State private var indicesToDelete: IndexSet?
    
    init() {
//        viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: Dashboard(), label: {
                        Text("Dashboard")
                    })
                ForEach(cdLimudim.filter({ cdl in
                    cdl.id != nil
                })) { cdl in
                    if let limud = Limud(cdl) {
                        NavigationLink(destination: GraphView(limud: limud, onUpdate: model.objectWillChange.send)
                            .environment(\.managedObjectContext, self.viewContext), label: {
                                Text(limud.name)
                            })
                    }
                }
                .onDelete(perform: { ix in
                    self.indicesToDelete = ix
                    showingDeleteAlert = true
                })
                .alert(isPresented: self.$showingDeleteAlert) {
                    Alert(title: Text("Delete Limud?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Delete")) {
                            do {
                                try withAnimation {
                                    try executeLimudDeletion()
                                }
                            } catch {
                                print("Failed to delete with error: \(error)")
                            }
                            self.indicesToDelete = nil
                        }, secondaryButton: .cancel() {
                            self.indicesToDelete = nil
                        }
                    )
                }
                NavigationLink(destination: SettingsView(), label: {
                        Text("Settings")
                    })
            }
            .navigationTitle("Chazer")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        self.showingNewLimudView = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewLimudView) {
            NewLimudView().environment(\.managedObjectContext, self.viewContext)
        }
        //        .alert("New Limud", isPresented: $showingNewLimudAlert, actions: {
        //                    TextField("Name", text: $limudName)
        //
        //            Button("Login", action: {})
        //                        Button("Cancel", role: .cancel, action: {})
        //                }, message: {
        //                    Text("Enter the name of the Limud.")
        //                })
    }
    
    private func executeLimudDeletion() throws {
        do {
            try withAnimation {
                try self.indicesToDelete?.map { cdLimudim.filter({ cdl in
                    cdl.id != nil
                })[$0] }.forEach({ cdl in
                    //                guard let cdl = cdl else {
                    //                    throw DeletionError.unknownError
                    //                }
                    
                    //                for o in cdl.sections as? [NSManagedObject] ?? [] {
                    //                    viewContext.delete(o)
                    //                }
                    //
                    //                for o in cdl.scheduledChazaras as? NSOrderedSet ?? [] {
                    //                    viewContext.rem
                    //                }
                    
                    //                let fr = CDLimud.fetchRequest()
                    //                fr.predicate = NSPredicate(format: "id == %@", cdl.id ?? "")
                    
                    //                let dr = NSBatchDeleteRequest(fetchRequest: fr)
                    
                    guard let id = cdl.id else {
                        print("Deletion failed, id is nil")
                        throw DeletionError.unknownError
                    }
                    
                    let fr = CDLimud.fetchRequest()
                    fr.predicate = NSPredicate(format: "id == %@", id)
                    let results = try viewContext.fetch(fr)
                    
                    for result in results {
                        viewContext.delete(result)
                    }
                    viewContext.delete(cdl)
                    
                    try viewContext.save()
                    
                    //                self.cdLimudim = self.cdLimudim.drop(while: { o in
                    //                    cdl.id == o.id
                    //                })
                })
            }
        } catch {
            print("Error deleting: \(error)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
