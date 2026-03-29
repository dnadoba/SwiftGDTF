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

    /// Builds a per-geometry map of pan/tilt axis info from the DMX channels.
    ///
    /// Single pass over all channels. Call on a resolved DMX mode (via
    /// `resolved(with:)`) so that geometry references are already expanded.
    public func geometryAxisInfoMap() -> [String: GeometryAxisInfo] {
        var map: [String: GeometryAxisInfo] = [:]

        for dmxChannel in channels {
            let geomName = dmxChannel.geometry
            for logicalChannel in dmxChannel.logicalChannels {
                for channelFunction in logicalChannel.channelFunctions {
                    guard let canonical = channelFunction.attribute?.type.canonical else { continue }
                    switch canonical {
                    case .pan:
                        var info = map[geomName, default: GeometryAxisInfo()]
                        info.panRange = Self.extendRange(info.panRange, from: channelFunction)
                        map[geomName] = info
                    case .tilt:
                        var info = map[geomName, default: GeometryAxisInfo()]
                        info.tiltRange = Self.extendRange(info.tiltRange, from: channelFunction)
                        map[geomName] = info
                    case .panRotate:
                        map[geomName, default: GeometryAxisInfo()].panInfinite = true
                    case .tiltRotate:
                        map[geomName, default: GeometryAxisInfo()].tiltInfinite = true
                    default:
                        break
                    }
                }
            }
        }
        return map
    }

    /// Extends a range with the physical values from a channel function and its channel sets.
    private static func extendRange(_ existing: ClosedRange<Double>?, from cf: ChannelFunction) -> ClosedRange<Double> {
        var lo = cf.physicalFrom
        var hi = cf.physicalTo
        if lo > hi { swap(&lo, &hi) }

        for cs in cf.channelSets {
            var csLo = cs.physicalFrom
            var csHi = cs.physicalTo
            if csLo > csHi { swap(&csLo, &csHi) }
            lo = min(lo, csLo)
            hi = max(hi, csHi)
        }

        if let existing {
            return min(existing.lowerBound, lo)...max(existing.upperBound, hi)
        }
        return lo...hi
    }
}
