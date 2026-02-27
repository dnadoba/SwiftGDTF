//
//  Untitled.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 2/27/26.
//

extension FixtureType {
    public func realAcceleration(for attribute: AttributeType.Canonical) -> ClosedRange<Duration>? {
        collectRange(for: attribute, getFromChannel1: \.realAcceleration).map {
            Duration.seconds($0.lowerBound)...Duration.seconds($0.upperBound)
        }
    }
    public func realFade(for attribute: AttributeType.Canonical) -> ClosedRange<Duration>? {
        collectRange(for: attribute, getFromChannel1: \.realFade).map {
            Duration.seconds($0.lowerBound)...Duration.seconds($0.upperBound)
        }
    }
    public func physicalRange(for attribute: AttributeType.Canonical) -> ClosedRange<Double>? {
        collectRange(for: attribute, getFromChannel1: \.physicalFrom, getFromChannel2: \.physicalTo, getFromChannelSet1: \.physicalFrom, getFromChannelSet2: \.physicalTo)
    }
    @inline(__always)
    func collectRange(
        for attribute: AttributeType.Canonical,
        getFromChannel1: KeyPath<ChannelFunction, Double>,
        getFromChannel2: KeyPath<ChannelFunction, Double>? = nil,
        getFromChannelSet1: KeyPath<ChannelSet, Double>? = nil,
        getFromChannelSet2: KeyPath<ChannelSet, Double>? = nil,
    ) -> ClosedRange<Double>? {
        var range: ClosedRange<Double>?
        for dmxMode in dmxModes {
            if let newRange = dmxMode.collectRange(
                for: attribute,
                getFromChannel1: getFromChannel1,
                getFromChannel2: getFromChannel2,
                getFromChannelSet1: getFromChannelSet1,
                getFromChannelSet2: getFromChannelSet2
            ) {
                if let oldRange = range {
                    range = min(oldRange.lowerBound, newRange.lowerBound)...max(oldRange.upperBound, newRange.upperBound)
                } else {
                    range = newRange
                }
            }
        }
        return range
    }
    public func hasAttribute(_ attribute: AttributeType.Canonical) -> Bool {
        for dmxMode in dmxModes {
            if dmxMode.hasAttribute(attribute) {
                return true
            }
        }
        return false
    }
}

extension DMXMode {
    public func hasAttribute(_ attribute: AttributeType.Canonical) -> Bool {
        for dmxChannel in channels {
            for logicalChannel in dmxChannel.logicalChannels {
                if logicalChannel.attribute.type.canonical == attribute {
                    return true
                }
                for channelFunction in logicalChannel.channelFunctions {
                    if channelFunction.attribute?.type.canonical == attribute {
                        return true
                    }
                }
            }
        }
        return false
    }
    @inline(__always)
    func collectRange(
        for attribute: AttributeType.Canonical,
        getFromChannel1: KeyPath<ChannelFunction, Double>,
        getFromChannel2: KeyPath<ChannelFunction, Double>?,
        getFromChannelSet1: KeyPath<ChannelSet, Double>?,
        getFromChannelSet2: KeyPath<ChannelSet, Double>?,
    ) -> ClosedRange<Double>? {
        var minValue: Double?
        var maxValue: Double?
        func collectPhysicalValue(_ value: Double) {
            if let old = maxValue {
                maxValue = max(value, old)
            } else {
                maxValue = value
            }
            if let old = minValue {
                minValue = min(value, old)
            } else {
                minValue = value
            }
        }
        for dmxChannel in channels {
            for logicalChannel in dmxChannel.logicalChannels {
                for channelFunction in logicalChannel.channelFunctions {
                    guard channelFunction.attribute?.type.canonical == attribute else { continue }
                    collectPhysicalValue(channelFunction[keyPath: getFromChannel1])
                    if let getFromChannel2 {
                        collectPhysicalValue(channelFunction[keyPath: getFromChannel2])
                    }

                    for channelSet in channelFunction.channelSets {
                        if let getFromChannelSet1 {
                            collectPhysicalValue(channelSet[keyPath: getFromChannelSet1])
                        }
                        if let getFromChannelSet2 {
                            collectPhysicalValue(channelSet[keyPath: getFromChannelSet2])
                        }
                    }
                }
            }
        }
        if let minValue, let maxValue {
            return minValue...maxValue
        } else {
            return nil
        }
    }
}
