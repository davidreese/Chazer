//
//  8-9.swift
//  Chazer
//
//  Created by David Reese on 1/24/25.
//

import Foundation
import CoreData

class RuleMigrationPolicy: NSEntityMigrationPolicy {
    
    @objc
    func ruleFor(_ isDynamic: NSNumber, _ delayedFromId: CID?, _ delay: NSNumber, _ fixedDueDate: NSDate?, _ daysToComplete: NSNumber?) -> NSString {
//        fatalError("Success! \(delayedFromId ?? "nil"), \(delay), \(fixedDueDate?.description ?? "nil"), \(daysToComplete ?? -1)")
        /*
        if let delayedFrom = delayedFrom {
            let rule = NSString(string: "H:DF\(delayedFrom.scId ?? "nil"):DL\(delay):DTC\(daysToComplete!)")
            print("Attempting to migrate into: \(rule)")
            return rule
        } else if let fixedDueDate = fixedDueDate {
            let rule = NSString(string: "F:FD\(fixedDueDate.timeIntervalSince1970)")
            print("Attempting to migrate into: \(rule)")
            return rule
        } else {
            return "NORULE"
        }*/
        let isDynamic = isDynamic.boolValue
        if isDynamic {
            if let delayedFromId = delayedFromId {
                let rule = NSString(string: "H:DF\(delayedFromId):DL\(delay):DTC\(daysToComplete!)")
                print("Attempting to migrate into: \(rule)")
                
                return rule
            } else {
                let rule = NSString(string: "H:DFINITIAL:DL\(delay):DTC\(daysToComplete!)")
                print("Attempting to migrate into: \(rule)")
                
                return rule
            }
        } else if let fixedDueDate = fixedDueDate {
            let rule = NSString(string: "F:FD\(fixedDueDate.timeIntervalSince1970)")
            print("Attempting to migrate into: \(rule)")
            return rule
        } else {
            return "NORULE"
        }
     }
    
    
//    used this function to test for what I need. the only thing which seemingly doesnt work is the delayedFrom situation. the old migration policy is:
        //FUNCTION($entityPolicy, "ruleFor:::::" , $source.isDynamic, $source.delayedFrom.scId, $source.delay, $source.fixedDueDate, $source.daysToComplete)
    @objc func fakeRuleFor(_ bool: NSNumber/*, _ daysToComplete: NSNumber?*/) -> NSString {
        fatalError("I survived: \(bool)")
    }
}
