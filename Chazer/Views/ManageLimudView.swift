//
//  ManageLimudView.swift
//  Chazer
//
//  Created by David Reese on 1/20/24.
//

import SwiftUI

struct ManageLimudView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    private var limud: Limud
    private var onUpdate: (() -> Void)?
    
    @State var limudName: String = ""
    
    init(_ limud: Limud, onUpdate: (() -> Void)? = nil) {
        self.limud = limud
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationView {
                Form {
                TextField("Limud Name", text: $limudName)
//                    .textFieldStyle(PlainTextFieldStyle())
                }
            .navigationTitle("New Limud")
//            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: {
                        do {
                            try updateLimud()
                            onUpdate?()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            
                    //            TODO: Make the failure known to the user
                            print("Failed to update limud: \(error)")
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
            if limudName.isEmpty {
                self.limudName = self.limud.name
            }
        }
    }
    
    private func updateLimud() throws {
        let fetchRequest = CDLimud.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", limud.id)
        
        guard let results = try? viewContext.fetch(fetchRequest), let cdLimud = results.first else {
            throw UpdateError.unknownError
        }

        cdLimud.name = self.limudName
        
        try viewContext.save()
    }
}
