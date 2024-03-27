//
//  PointNote.swift
//  Chazer
//
//  Created by David Reese on 5/28/23.
//

import Foundation
import CoreData

/// Custom representation of a CoreData model object ``CDPointNote``
class PointNote: ObservableObject, Identifiable {
    final var id: CID!
    private(set) var creationDate: Date?
    @Published var note: String?
    
    init(_ cdPointNote: CDPointNote, context: NSManagedObjectContext) throws {
        
        try context.performAndWait {
            guard let noteId = cdPointNote.noteId else {
                print("Error: Could not instansiate PointNote, the CDPointNote id was nil.")
                throw RetrievalError.missingData
            }
            
            self.id = noteId
            
            self.creationDate = cdPointNote.creationDate
            self.note = cdPointNote.note
            //        Leaving out this attribute
            //        cdPointNote.point
        }
    }
    
    
    static func ==(lhs: PointNote, rhs: PointNote) -> Bool {
        lhs.id == rhs.id
    }
}
