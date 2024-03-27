//
//  IDGenerator.swift
//  Chazer
//
//  Created by David Reese on 1/10/23.
//

import Foundation

typealias CID = String
struct IDGenerator {
    static func generate(withPrefix prefix: String) -> CID {
        return "\(prefix)\(Date().timeIntervalSince1970)\(Int.random(in: 1000...9999))"
    }
}
