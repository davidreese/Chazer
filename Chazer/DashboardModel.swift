//
//  DashboardModel.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation
import SwiftUI

import PDFKit

class DashboardModel: ObservableObject {
    @Published var activeChazaraPoints: [ChazaraPoint]?
    @Published var lateChazaraPoints: [ChazaraPoint]?
    
    @Published private(set) var pdf: PDFDocument?
    
    init() {
        Task {
            await updateDashboard()
        }
    }
    
    /// Updates local storage to match current chazara statuses and other data
    func updateData() async {
        await Storage.shared.loadChazaraPoints()
    }
    
    /// Updates the dashboard to reflect the latest updated data saved in the database.
    func updateDashboard() async {
        guard let data = Storage.shared.getActiveAndLateChazaraPoints() else {
            return
        }
        for point in data.active {
            await point.getDueDate()
        }
        
        for point in data.late {
            await point.getDueDate()
        }
        
        await MainActor.run {
            self.activeChazaraPoints = data.active.sorted(by: { lhs, rhs in
                if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                    return lhsDate < rhsDate
                } else {
                    //                                    this isn't really supposed to occur
                    return true
                }
            })
            
            self.lateChazaraPoints = data.late.sorted(by: { lhs, rhs in
                if let lhsDate = lhs.dueDate, let rhsDate = rhs.dueDate {
                    return lhsDate < rhsDate
                } else {
                    // this isn't really supposed to occur
                    return true
                }
            })
            
            generatePDF()
        }
    }
    
    /// Generates a PDF file representing the information on the dashboard and saves it in the model.
    private func generatePDF(/*date: Date = Date.now*/) {
        let pdfMetaData = [
            kCGPDFContextCreator: "Upcoming Chazara",
            kCGPDFContextAuthor: "Chazer App"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: -20, y: 20, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            
            context.beginPage()
            
            let largeTitleFont = UIFont.boldSystemFont(ofSize: 24)
            let smallerTitleFont = UIFont.boldSystemFont(ofSize: 18)
            let cellFont = UIFont.systemFont(ofSize: 12)
            
            let largeTitle = "Upcoming Chazara at \(Date.now.formatted())"
            let largeTitleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 40)
            largeTitle.draw(in: largeTitleRect, withAttributes: [NSAttributedString.Key.font: largeTitleFont])
            
            //            currentY += 20
            
            if !(self.lateChazaraPoints?.isEmpty ?? true) {
                let lateTitle = "Late"
                
                let lateTitleRect = CGRect(x: 50, y: 120, width: pageRect.width - 100, height: 30)
                lateTitle.draw(in: lateTitleRect, withAttributes: [NSAttributedString.Key.font: smallerTitleFont])
                
                drawTable(context: context, startY: 160, numRows: 6, numCols: 4, cellFont: cellFont)
            }
            
            if !(self.activeChazaraPoints?.isEmpty ?? true) {
                let activeTitle = "Active"
                let activeTitleAttributes = [
                    NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title2, compatibleWith: .current)
                ]
                activeTitle.draw(at: CGPoint(x: 0, y: !(self.lateChazaraPoints?.isEmpty ?? true) ? 80 : 40), withAttributes: activeTitleAttributes)
                
                //                currentY +=
            }
            
            // Draw Second Smaller Title
            let smallerTitle2 = "Smaller Title 2"
            let smallerTitleRect2 = CGRect(x: 50, y: pageRect.height - 220, width: pageRect.width - 100, height: 30)
            smallerTitle2.draw(in: smallerTitleRect2, withAttributes: [NSAttributedString.Key.font: smallerTitleFont])
            
            // Draw Second Table
            drawTable(context: context, startY: pageRect.height - 180, numRows: 6, numCols: 4, cellFont: cellFont)
        }
        
        //        self.pdf = PDFDocument(data: data)
        self.pdf = PDFDocument(data: data)
    }
            
    func drawTable(context: UIGraphicsPDFRendererContext, startY: CGFloat, numRows: Int, numCols: Int, cellFont: UIFont) {
        let cellWidth = (context.format.bounds.width - 100) / CGFloat(numCols)
        let cellHeight: CGFloat = 20
        
        for row in 0..<numRows {
            for col in 0..<numCols {
                let cellText = randomWord()
                let cellRect = CGRect(x: 50 + CGFloat(col) * cellWidth, y: startY + CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
                
                context.cgContext.setFillColor(UIColor.black.cgColor)
                cellText.draw(in: cellRect, withAttributes: [NSAttributedString.Key.font: cellFont])
            }
        }
    }

    func randomWord() -> String {
        let words = ["Apple", "Banana", "Orange", "Grapes", "Strawberry", "Blueberry", "Pineapple", "Mango", "Watermelon", "Cherry"]
        return words.randomElement() ?? ""
    }
}
