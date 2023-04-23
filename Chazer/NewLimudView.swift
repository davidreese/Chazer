//
//  NewLimudView.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import SwiftUI

struct NewLimudView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var limudName: String = ""
    
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
                    Button("Create", action: {
                        do {
                            try addLimud()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Error saving limud: \(error)")
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
    }
    
    private func addLimud() throws {
        if limudName.isEmpty || limudName.count > 80 {
            throw CreationError.invalidName
        }
        
        let newItem = CDLimud(context: viewContext)
        newItem.id = IDGenerator.generate(withPrefix: "L")
        newItem.name = limudName
        
        try withAnimation {
            try viewContext.save()
        }
    }
}

struct NewLimudView_Previews: PreviewProvider {
    static var previews: some View {
        NewLimudView()
    }
}
