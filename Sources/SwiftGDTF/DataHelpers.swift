//
//  DataHelpers.swift
//  
//
//  Created by Brandon Wees on 7/6/24.
//

import Foundation
import OrderedCollections

extension FixtureType {
    public func getDMXMode(mode: String) -> DMXMode? {
        return self.dmxModes.first(where: {$0.name == mode})
    }
}

extension DMXMode {
    public var dmxFootprint: Int {
        dmxFootprintForBreak.values.reduce(0, +)
    }
    public var dmxFootprintForBreak: OrderedDictionary<DMXChannel.Break, Int> {
        OrderedDictionary(
            self.channels.lazy.compactMap { channel in
                channel.offset.max().map {
                    (channel.dmxBreak, $0)
                }
            },
            uniquingKeysWith: { max($0, $1) }
        )
    }

}

extension DMXChannel {
    public var byteCount: Int {
        return self.initialFunction?.dmxDefault.byteCount ?? 1
    }
}
