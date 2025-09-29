//
//  DataHelpers.swift
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
        self.channels.lazy.flatMap {
            $0.offset
        }.max() ?? 0
    }

}

extension DMXChannel {
    public var byteCount: Int {
        return self.initialFunction?.dmxDefault.byteCount ?? 1
    }
}
