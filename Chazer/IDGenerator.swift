//
//  IDGenerator.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation

typealias ID = String
struct IDGenerator {
    static func generate(withPrefix prefix: String) -> ID {
        return "\(prefix)\(Date().timeIntervalSince1970)\(Int.random(in: 100...999))"
    }
}
