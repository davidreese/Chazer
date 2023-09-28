//
//  Tools.swift
//  Chazer
//
//  Created by David Reese on 8/18/23.
//

import Foundation
import PDFKit
import SwiftUI

// Sourced from https://developer.apple.com/forums/thread/708538
extension PDFDocument: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .pdf) { pdf in
                if let data = pdf.dataRepresentation() {
                    return data
                } else {
                    return Data()
                }
            } importing: { data in
                if let pdf = PDFDocument(data: data) {
                    return pdf
                } else {
                    return PDFDocument()
                }
            }
        DataRepresentation(exportedContentType: .pdf) { pdf in
            if let data = pdf.dataRepresentation() {
                return data
            } else {
                return Data()
            }
        }
     }
}
import UniformTypeIdentifiers
struct PDFDocumentForExport: FileDocument {
    static var readableContentTypes: [UTType] {
        [.pdf]
    }
    
    var pdf: PDFDocument?
    
    init(pdf: PDFDocument) {
        self.pdf = pdf
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents, let pdf = PDFDocument(data: data) {
            self.pdf = pdf
        } else {
            self.pdf = nil
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: (pdf!.dataRepresentation())!)
    }
}
