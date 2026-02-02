//
//  Attributes.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 10/4/25.
//

import Foundation
import OrderedCollections

private struct AttributeDescriptions: Decodable, Sendable {
    let attributes: [AttributeDescription]

    private enum CodingKeys: String, CodingKey {
        case attributes = "Attribute"
    }
}

public struct AttributeDescription: Decodable, Identifiable, Sendable, Equatable {
    /// TODO: we should be able to optimize this to just an array and add some kind of integer value to AttributeType
    /// potentially the better solution is to just have this in memory anyway
    public static let attributes: OrderedDictionary<AttributeType.Canonical, AttributeDescription> = {
        let attributesURL = Bundle.module.url(forResource: "gdtf_attributes_with_description", withExtension: "json")!
        let attributesData = try! Data(contentsOf: attributesURL)
        let decoder = JSONDecoder()
        let attributes = try! decoder.decode(AttributeDescriptions.self, from: attributesData)
        let attributesDict = OrderedDictionary(uniqueKeysWithValues: attributes.attributes.lazy.map { ($0.name, $0) })
        print("attributesDict.count", attributesDict.count)
        return attributesDict
    }()

    public var id: AttributeType.Canonical { name }

    public struct SubPhysicalUnit: Decodable, Sendable, Equatable {
        public var `default`: Bool
        public var type: SubPhysicalType
        public var physicalUnit: PhysicalUnit
        private var _physicalFrom: LosslessDouble
        public var physicalFrom: Double {
            get { _physicalFrom.value }
            set { _physicalFrom.value = newValue }
        }
        private var _physicalTo: LosslessDouble
        public var physicalTo: Double {
            get { _physicalTo.value }
            set { _physicalTo.value = newValue }
        }

        private enum CodingKeys: String, CodingKey {
            case `default` = "_default"
            case type = "_type"
            case physicalUnit = "_physicalUnit"
            case _physicalFrom
            case _physicalTo
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name = "_name"
        case prettyName = "_prettyName"
        case feature = "_feature"
        case physicalUnit = "_physicalUnit"
        case mainAttribute = "_MainAttribute"
        case activationGroup = "_ActivationGroup"
        case _subPhysicalUnits
        case definition
        case explanation
        case visual
        case label = "_label"
    }

    public var name: AttributeType.Canonical
    public var prettyName: String
    public struct Feature: Decodable, Sendable, Hashable {
        public var group: CanonicalFeatureGroup
        public var feature: CanonicalFeature

        public init(from decoder: any Decoder) throws {
            let decoder = try decoder.singleValueContainer()
            let string = try decoder.decode(String.self)
            let split = string.split(separator: ".")
            guard split.count == 2 else {
                throw DecodingError.dataCorruptedError(
                    in: decoder,
                    debugDescription: "Couldn't split string into group and feature: \(string)"
                )
            }
            let groupString = split[0]
            guard let group = CanonicalFeatureGroup(rawValue: String(groupString)) else {
                throw DecodingError.dataCorruptedError(
                    in: decoder,
                    debugDescription: "Couldn't create CanonicalFeatureGroup from \(groupString)"
                )
            }
            let featureString = split[1]
            guard let feature = CanonicalFeature(rawValue: String(featureString)) else {
                throw DecodingError.dataCorruptedError(
                    in: decoder,
                    debugDescription: "Couldn't create CanonicalFeature from \(featureString)"
                )
            }
            self.group = group
            self.feature = feature
        }
    }
    public var feature: Feature
    public var physicalUnit: PhysicalUnit?
    public var mainAttribute: String?
    public var activationGroup: CanonicalActivationGroup?
    private var _subPhysicalUnits: [SubPhysicalUnit]?
    public var subPhysicalUnits: [SubPhysicalUnit] {
        get { _subPhysicalUnits ?? [] }
        set { _subPhysicalUnits = newValue }
    }
    public var definition: String?
    public var explanation: String
    public var visual: String
    public var label: String
}

extension AttributeType {
    public var attributeDescription: AttributeDescription? {
        canonical.attributeDescription
    }
}

extension AttributeType.Canonical {
    public var attributeDescription: AttributeDescription? {
        AttributeDescription.attributes[self]
    }
}

// Seems like the json includes a string e.g. "0.025" but we need to treat that as a double
struct LosslessDouble: Decodable, Sendable, Equatable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self),
                  let doubleFromString = Double(stringValue) {
            value = doubleFromString
        } else {
            throw DecodingError.typeMismatch(
                Double.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a Double or String convertible to Double"
                )
            )
        }
    }
}

/// Represents individual activation group names as used in GDTF / fixture profiles
public enum CanonicalActivationGroup: String, CaseIterable, Codable, Hashable, Sendable {
    case panTilt       = "PanTilt"
    case xyz           = "XYZ"
    case rotXYZ        = "Rot_XYZ"
    case scaleXYZ      = "Scale_XYZ"
    case colorRGB      = "ColorRGB"
    case colorHSB      = "ColorHSB"
    case colorCIE      = "ColorCIE"
    case colorIndirect = "ColorIndirect"
    case goboN         = "Gobo(n)"
    case goboNPos      = "Gobo(n)Pos"
    case animationWheelN         = "AnimationWheel(n)"
    case animationWheelNPos      = "AnimationWheel(n)Pos"
    case animationSystemN        = "AnimationSystem(n)"
    case animationSystemNPos     = "AnimationSystem(n)Pos"
    case prism         = "Prism"
    case beamShaper    = "BeamShaper"
    case shaper        = "Shaper"

    // Helper to support indexed versions (Gobo(n), AnimationWheel(n), etc.)
    public func withIndex(_ index: Int) -> String {
        switch self {
        case .goboN:                return "Gobo\(index)"
        case .goboNPos:             return "Gobo\(index)Pos"
        case .animationWheelN:      return "AnimationWheel\(index)"
        case .animationWheelNPos:   return "AnimationWheel\(index)Pos"
        case .animationSystemN:     return "AnimationSystem\(index)"
        case .animationSystemNPos:  return "AnimationSystem\(index)Pos"
        default:
            return self.rawValue
        }
    }

    // Reverse lookup – tries to detect indexed pattern and return base case + index
    public static func from(name: String) -> (CanonicalActivationGroup, index: Int?) {
        // Check exact matches first
        if let exact = CanonicalActivationGroup(rawValue: name) {
            return (exact, nil)
        }

        // Check indexed patterns
        if name.hasPrefix("Gobo") {
            if name.hasSuffix("Pos"), let idx = Int(name.dropFirst(4).dropLast(3)) {
                return (.goboNPos, idx)
            }
            if let idx = Int(name.dropFirst(4)) {
                return (.goboN, idx)
            }
        }

        if name.hasPrefix("AnimationWheel") {
            if name.hasSuffix("Pos"), let idx = Int(name.dropFirst(14).dropLast(3)) {
                return (.animationWheelNPos, idx)
            }
            if let idx = Int(name.dropFirst(14)) {
                return (.animationWheelN, idx)
            }
        }

        if name.hasPrefix("AnimationSystem") {
            if name.hasSuffix("Pos"), let idx = Int(name.dropFirst(15).dropLast(3)) {
                return (.animationSystemNPos, idx)
            }
            if let idx = Int(name.dropFirst(15)) {
                return (.animationSystemN, idx)
            }
        }

        // Fallback – unknown
        return (.panTilt, nil) // or throw / return optional
    }
}

// ────────────────────────────────────────────────

/// High-level feature categories (mostly match GDTF FeatureGroup)
public enum CanonicalFeatureGroup: String, CaseIterable, Codable, Hashable, Sendable, Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.integerValue < rhs.integerValue
    }
    case dimmer    = "Dimmer"
    case position  = "Position"
    case gobo      = "Gobo"
    case color     = "Color"
    case beam      = "Beam"
    case focus     = "Focus"
    case control   = "Control"
    case shapers   = "Shapers"
    case video     = "Video"

    var integerValue: Int {
        switch self {
        case .dimmer: 0
        case .position: 1
        case .gobo: 2
        case .color: 3
        case .beam: 4
        case .focus: 5
        case .control: 6
        case .shapers: 7
        case .video: 8
        }
    }
}

// ────────────────────────────────────────────────

/// Individual feature names inside FeatureGroups
public enum CanonicalFeature: String, CaseIterable, Codable, Hashable, Sendable {
    // Dimmer
    case dimmer    = "Dimmer"

    // Position
    case panTilt   = "PanTilt"
    case xyz       = "XYZ"
    case rotation  = "Rotation"
    case scale     = "Scale"

    // Gobo
    case gobo      = "Gobo"
    case media     = "Media"

    // Color
    case color           = "Color"
    case rgb             = "RGB"
    case hsb             = "HSB"
    case cie             = "CIE"
    case indirect        = "Indirect"
    case colorCorrection = "ColorCorrection"
    case hsbcShift       = "HSBC_Shift"
    case colorKey        = "ColorKey"

    // Beam
    case beam      = "Beam"

    // Focus
    case focus     = "Focus"

    // Control
    case control   = "Control"

    // Shapers
    case shapers   = "Shapers"

    // Video
    case video     = "Video"
}

// ────────────────────────────────────────────────
// Optional: static collections / lookup helpers

extension ActivationGroup {
    public static let allNonIndexed: [CanonicalActivationGroup] = [
        .panTilt, .xyz, .rotXYZ, .scaleXYZ,
        .colorRGB, .colorHSB, .colorCIE, .colorIndirect,
        .prism, .beamShaper, .shaper
    ]

    public static let indexedOnes: [CanonicalActivationGroup] = [
        .goboN, .goboNPos,
        .animationWheelN, .animationWheelNPos,
        .animationSystemN, .animationSystemNPos
    ]
}

extension CanonicalFeatureGroup {
    // You can add relationships if needed, e.g.:
    public var typicalFeatures: [CanonicalFeature] {
        switch self {
        case .dimmer:    return [.dimmer]
        case .position:  return [.panTilt, .xyz, .rotation, .scale]
        case .gobo:      return [.gobo, .media]
        case .color:     return [.color, .rgb, .hsb, .cie, .indirect, .colorCorrection, .hsbcShift, .colorKey]
        case .beam:      return [.beam]
        case .focus:     return [.focus]
        case .control:   return [.control]
        case .shapers:   return [.shapers]
        case .video:     return [.video]
        }
    }
}



public struct AttributeIcon: Codable, Sendable {
    public static let attributes: [AttributeType.Canonical: AttributeIcon] = {
        let attributesURL = Bundle.module.url(forResource: "gdtf_attributes_symbols", withExtension: "json")!
        let attributesData = try! Data(contentsOf: attributesURL)
        let decoder = JSONDecoder()
        return try! decoder.decode([AttributeType.Canonical: AttributeIcon].self, from: attributesData)
    }()
    public var symbol: String
    //public var category: String
    //public var style: String?
    public var r: Double?
    public var g: Double?
    public var b: Double?
}

#if canImport(SwiftUI)
import SwiftUI
extension AttributeIcon {
    public var swiftUIColor: Color? {
        guard let r, let g, let b else { return nil }
        return switch (r, g, b) {
        case (1, 0, 0): .red
        case (0, 1, 0): .green
        case (0, 0, 1): .blue
        default: Color(.sRGB, red: r, green: g, blue: b)
        }
    }
}
#endif

extension AttributeType.Canonical {
    public var iconDescription: AttributeIcon? {
        AttributeIcon.attributes[self]
    }
}

extension AttributeType {
    public var iconDescription: AttributeIcon? {
        canonical.iconDescription
    }
}

extension AttributeDescription {
    internal static let attributeTemplateNames: [AttributeType.Canonical: String] = {
        let attributesURL = Bundle.module.url(forResource: "gdtf_attributes_with_template_name", withExtension: "json")!
        let attributesData = try! Data(contentsOf: attributesURL)
        let decoder = JSONDecoder()
        let attributes = try! decoder.decode([AttributeType.Canonical: String].self, from: attributesData)
        print("attributeTemplateNames.count:", attributes.count)
        return attributes
    }()
}

extension AttributeType {
    public var displayName: String {
        if let attributeTemplateName = AttributeDescription.attributeTemplateNames[self.canonical] {
            if let nm = getNM() {
                let n = nm.n
                if let m = nm.m {
                    return attributeTemplateName
                        .replacing("(n)", with: n.description)
                        .replacing("(m)", with: m.description)
                } else {
                    return attributeTemplateName
                        .replacing("(n)", with: n.description)
                }
            } else {
                return attributeTemplateName
            }
        } else {
            return self.description
        }
    }
    public func displayName(showNM: Bool) -> String {
        if showNM {
            displayName
        } else {
            attributeDescription?.label ?? description
        }
    }
    public var explanation: String? {
        self.attributeDescription?.explanation
    }
    public var definition: String? {
        self.attributeDescription?.definition
    }
}

extension AttributeType.Canonical {
    public var displayName: String {
        if let label = self.attributeDescription?.label {
            return label
        } else {
            if case let .custom(name) = self {
                return name
            } else {
                return String(describing: self)
            }
        }
    }
    public var explanation: String? {
        self.attributeDescription?.explanation
    }
    public var definition: String? {
        self.attributeDescription?.definition
    }
}
