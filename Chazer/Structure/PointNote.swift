//
//  PointNote.swift
//  Chazer
//
//  Created by David Reese on 5/28/23.
//

import Foundation

/// Custom representation of a CoreData model object ``CDPointNote``
class PointNote: ObservableObject, Identifiable {
    final let id: ID
    private(set) var creationDate: Date?
    @Published var note: String?
    
    init?(_ cdPointNote: CDPointNote) {
        guard let noteId = cdPointNote.noteId else {
            print("Error: Could not instansiate PointNote, the CDPointNote id was nil.")
            return nil
        }
        self.id = noteId
         
        self.creationDate = cdPointNote.creationDate
        self.note = cdPointNote.note
//        Leaving out this attribute
//        cdPointNote.point
    }
    
    
    static func ==(lhs: PointNote, rhs: PointNote) -> Bool {
        lhs.id == rhs.id
    }
}
