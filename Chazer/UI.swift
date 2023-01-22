//
//  UI.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation
import SwiftUI

class UI {
    static let shadowRadius: CGFloat = 3
    static let cornerRadius: CGFloat = 5
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
    }
}
