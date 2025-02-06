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
    @Published private(set) var pdfFilename: String?
    
    init() {
        Task {
            await updateDashboard()
        }
    }
    
    /*
    /// Updates local storage to match current chazara statuses and other data
    func updateData() async {
        await Storage.shared.loadChazaraPoints()
    }
     */
    
    /// Updates the dashboard to reflect the latest updated data saved in the database.
    func updateDashboard() async {
        guard let data = try? await Storage.shared.getActiveAndLateChazaraPoints() else {
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
                if let lhsDate = lhs.activeDate, let rhsDate = rhs.activeDate {
                    return lhsDate < rhsDate
                } else {
                    //                                    this isn't really supposed to occur
                    return true
                }
            })
            
            self.lateChazaraPoints = data.late.sorted(by: { lhs, rhs in
                if let lhsDate = lhs.activeDate, let rhsDate = rhs.activeDate {
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
            kCGPDFContextAuthor: "Chazer App",
            kCGPDFContextTitle: "UC \(Date.now.formatted())"
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
            
            let largeTitle = "Upcoming Chazara"
            let largeTitleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 40)
            largeTitle.draw(in: largeTitleRect, withAttributes: [NSAttributedString.Key.font: largeTitleFont])
            
            let subTitle = Date.now.formatted()
            let subTitleRect = CGRect(x: 50, y: 85, width: pageRect.width - 100, height: 40)
            subTitle.draw(in: subTitleRect, withAttributes: [NSAttributedString.Key.font: smallerTitleFont, NSAttributedString.Key.foregroundColor: UIColor.gray])
            
            var currentY = 130.0
            
            if let lateChazaraPoints = self.lateChazaraPoints, !lateChazaraPoints.isEmpty {
                let lateTitle = "Late"
                
                let lateTitleRect = CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 30)
                lateTitle.draw(in: lateTitleRect, withAttributes: [NSAttributedString.Key.font: smallerTitleFont])
                
                currentY += 30
                
                let tableHeight = drawTable(context: context, startY: currentY, points: lateChazaraPoints)
                
                currentY = currentY + tableHeight + 10
            }
            
            if let activeChazaraPoints = self.activeChazaraPoints, !activeChazaraPoints.isEmpty {
                let activeTitle = "Active"
                
                let activeTitleRect = CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 30)
                activeTitle.draw(in: activeTitleRect, withAttributes: [NSAttributedString.Key.font: smallerTitleFont])
                
                currentY += 30
                
                let tableHeight = drawTable(context: context, startY: currentY, points: activeChazaraPoints)
                
                currentY = currentY + tableHeight + 10
            }
        }
        
        //        self.pdf = PDFDocument(data: data)
        self.pdf = PDFDocument(data: data)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.pdfFilename = "Upcoming Chazara \(dateFormatter.string(from: .now))"
    }
    
    /// Draws a table on the given ``UIGraphicsPDFRendererContext`` based on an array of ``ChazaraPoint`` objects.
    /// - Returns: The height of the table
    func drawTable(context: UIGraphicsPDFRendererContext, startY: CGFloat, points: [ChazaraPoint]) -> CGFloat {
        let COLUMN_COUNT = 4
        
        let cellWidth = (context.format.bounds.width - 100) / CGFloat(COLUMN_COUNT)
        let cellHeight: CGFloat = 20
        
//        var cellsAdded = 0
        
        for i in 0..<points.count {
            for col in 0..<COLUMN_COUNT {
                let point = points[i]
                let text = {
                    let section = Storage.shared.getSection(sectionId: point.sectionId)
                    
                    switch col {
                    case 0:
                        guard let limudId = section?.limudId else {
                            return "?"
                        }
                        return (try? Storage.shared.fetchLimud(id: limudId))?.name ?? "?"
                    case 1:
                        return section?.name ?? "?"
                    case 2:
                        return Storage.shared.getScheduledChazara(scId: point.scheduledChazaraId)?.name ?? "?"
                    case 3:
                        return point.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "?"
                    default:
                        return "?"
                    }
                }()
                
                let cellRect = CGRect(x: 50 + CGFloat(col) * cellWidth, y: startY + CGFloat(i) * cellHeight, width: cellWidth, height: cellHeight)
                
                context.cgContext.setFillColor(UIColor.black.cgColor)
                text.draw(in: cellRect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
                
//                cellsAdded += 1
            }
        }
        
        return cellHeight * CGFloat(points.count)
    }

    func randomWord() -> String {
        let words = ["Apple", "Banana", "Orange", "Grapes", "Strawberry", "Blueberry", "Pineapple", "Mango", "Watermelon", "Cherry"]
        return words.randomElement() ?? ""
    }
}
