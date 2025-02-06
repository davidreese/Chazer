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
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.openWindow) var openWindow
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDLimud .name, ascending: true)], predicate: NSPredicate(format: "archived == %@", NSNumber(value: false)),
        animation: .default)
    private var cdLimudim: FetchedResults<CDLimud>
    
    var limudim: [Limud] {
        var temp: [Limud] = []
        for cdLimud in cdLimudim {
            if let limud = try? Limud(cdLimud, context: viewContext) {
                temp.append(limud)
            }
        }
        return temp
    }
    
    @State var showingNewLimudView = false
    @State private var showingDeleteAlert = false
    @State private var limudToDelete: CDLimud? = nil
    
    @State private var isUpdating = false
    
    let updateTimer = Timer.publish(every: 3, on: .current, in: .common).autoconnect()
    @State var lastScenePhase: ScenePhase? = nil
    
    @State var dashboard = Dashboard()
    @State var settingsView = SettingsView()
    
//    @State private var selectedLimud: Limud?
    
    init() {
        //        viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var body: some View {
        /*
        NavigationSplitView {
            NavigationLink(destination: dashboard, label: {
                Text("Dashboard")
            })
            List(limudim, selection: $selectedLimud) { limud in
                Text(limud.name)
                    .tag(limud)
            }
        } detail: {
            
            if let selectedLimud = selectedLimud {
                Text(selectedLimud.name)
                GraphView(limud: selectedLimud, onUpdate: model.objectWillChange.send)
                    .environment(\.managedObjectContext, self.viewContext)
            }
        }*/

        NavigationView {
            List {
                //                adding horizontal padding to the dashboard seems to help fix the horizontal line issue
                NavigationLink(destination: dashboard, label: {
                    Text("Dashboard")
                })
                ForEach(cdLimudim.filter({ cdl in
                    cdl.id != nil && cdl != limudToDelete
                })) { cdl in
                    if let limud = try? Limud(cdl, context: viewContext) {
                        let gv = GraphView(limud: limud, onUpdate: model.objectWillChange.send)
                            .environment(\.managedObjectContext, self.viewContext)
                        NavigationLink(destination: gv, label: {
                                Text(limud.name)
                            })
                        .swipeActions(allowsFullSwipe: false) {
                            Button {
                                self.archiveLimud(cdLimud: cdl)
                                self.reload()
                            } label: {
                                Text("Archive")
                            }
                            .tint(.indigo)
                            
                            Button(role: .destructive) {
                                self.limudToDelete = cdl
                                showingDeleteAlert = true
                            } label: {
                                Text("Delete")
                            }
                        }
                    }
                }
                .alert(isPresented: self.$showingDeleteAlert) {
                    Alert(title: Text("Delete Limud?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Delete")) {
                        withAnimation {
                            executeLimudDeletion()
                        }
                        self.limudToDelete = nil
                    }, secondaryButton: .cancel() {
                        self.limudToDelete = nil
                    }
                    )
                }
                NavigationLink(destination: settingsView, label: {
                    Text("Settings")
                })
            }
            .navigationTitle("Chazer")
            .toolbar {
                ToolbarItem {
                    if self.isUpdating {
                        ProgressView()
                    }
                }
#if DEBUG
                ToolbarItem {
                    Button(action: {
                        reload()
                    }) {
                        Label("Reload", systemImage: "arrow.trianglehead.clockwise.rotate.90")
                    }
                }
#endif
                ToolbarItem {
                    
                    Button(action: {
                        self.showingNewLimudView = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
        .frame(minWidth: 1060, minHeight: 800)
        .sheet(isPresented: $showingNewLimudView) {
            NewLimudView().environment(\.managedObjectContext, self.viewContext)
        }
        .onReceive(updateTimer) { _ in
            if scenePhase == .active {
                if let lastUpdate = lastUpdate, lastUpdate.timeIntervalSince(.now) > -(60*10) && !ChazerApp.DEBUGGING_DATA {
                    if lastScenePhase == .active {
                        print("Skipping chazara points load.")
                        return
                    }
                }
                
                reload()
            } else {
                // will never update when the screen is out of view
                print("Skipping chazara points load.")
                lastScenePhase = scenePhase
            }
        }
    }
    
    @State var lastUpdate: Date? = nil
    
    /// Runs a full update on the app data and on the views that enable updates.
    private func reload() {
        print("Loading chazara points...")
        self.isUpdating = true
        
        lastScenePhase = .active
        
        Task {
            self.lastUpdate = Date.now
            await dashboard.model.updateDashboard()
            
            self.isUpdating = false
        }
    }
    
    private func executeLimudDeletion()  {
        try? withAnimation {
            try viewContext.performAndWait {
                guard let limudToDelete = limudToDelete else {
                    return
                }
                
                viewContext.delete(limudToDelete)
                
                try viewContext.save()
            }
        }
    }
    
    private func archiveLimud(cdLimud: CDLimud) {
        try? withAnimation {
            try viewContext.performAndWait {
                cdLimud.archived = true
                
                try viewContext.save()
            }
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
