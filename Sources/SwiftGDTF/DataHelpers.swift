//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/6/24.
//

import Foundation

extension FixtureType {
    public func getDMXMode(mode: String) -> DMXMode? {
        return self.dmxModes.filter({$0.name == mode}).first
    }
}
