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
    
    init(pdf: PDFDocument?) {
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


extension Collection {
    /// Source: [Stack Overflow](https://stackoverflow.com/a/40226976/1187415)
    func binarySearch(predicate: (Iterator.Element) -> Int) -> Index {
        var high = startIndex
        var low = endIndex
        while high != low {
            let mid = index(high, offsetBy: distance(from: high, to: low)/2)
            let res = predicate(self[mid])
            if res == 0 {
                return mid
            } else if res < 0 {
//                self[mid] was larger than the target
                high = mid
            } else if res > 0 {
//                self[mid] was smaller than the target
                low = mid
            }
        }
        return high
    }
}

