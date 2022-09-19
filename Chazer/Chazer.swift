//
//  Chazer.swift
//  Chazer
//
//  Created by David Reese on 9/14/22.
//

import Foundation

class Limud {
    var name: String
    var sections: [Section]
    var scheduledChazaras: [ScheduledChazara]
    
    init(name: String, sections: [Section], scheduledChazaras: [ScheduledChazara]) {
        self.name = name
        self.sections = sections
        self.scheduledChazaras = scheduledChazaras
    }
}

class Section {
    var name: String
    var initialDate: Date
    
    init(name: String, initialDate: Date) {
        self.name = name
        self.initialDate = initialDate
    }
}

class Shiur: Section {
    init(shiurNumber: Int, initialDate: Date) {
        super.init(name: "Shiur #\(shiurNumber)", initialDate: initialDate)
    }
}

class ScheduledChazara {
    var name: String
    /// The number of days after the initial learning date that the chazara is scheduled to occur
    var delay: Int
    
    init(name: String, delay: Int) {
        self.name = name
        self.delay = delay
    }
    
    init(delay: Int) {
        self.name = "\(delayFormatted(delay)) Day Chazara"
        self.delay = delay
    }
}

func delayFormatted(_ delay: Int) -> String {
    return "\(delay)"
}
