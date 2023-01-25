//
//  ChazaraStatus.swift
//  Chazer
//
//  Created by David Reese on 1/20/23.
//

import Foundation
import SwiftUI

/// A general status that describes whether or not chazara was done, or when it should be.
@objc enum ChazaraStatus: Int16 {
    case unknown = -1
    case exempt = 0
    case early = 1
    case active = 2
    case late = 3
    case completed = 4
    
    func descriptionColor() -> Color {
        switch self {
        case .early:
            return .gray
        case .active:
            return .orange
        case .late:
            return .red
        case .completed:
            return .green
        case .unknown:
            return .white
        case .exempt:
            return .blue
        }
    }
}
