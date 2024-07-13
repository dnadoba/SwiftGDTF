//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/6/24.
//

import Foundation

extension FixtureType {
    public func getDMXMode(mode: String) -> DMXMode? {
        return self.dmxModes.first(where: {$0.name == mode})
    }
}

extension DMXMode {
    public var dmxFootprint: Int {
        var total = 0
        
        for channel in self.channels {
            total += channel.initialFunction.dmxFrom.byteCount
        }
        
        return total
    }
}
