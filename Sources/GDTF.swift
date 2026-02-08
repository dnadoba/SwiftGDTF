//
//  GDTF.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash
import OrderedCollections

/// This is used to show a String that maps to a node that we cannot currently process
/// (usually because it results in a recursive type)
public typealias Node = String

public struct GDTF: Codable {
    public struct ID: Hashable, Codable, Sendable, Comparable, CustomStringConvertible, RawRepresentable {
        public static func <(lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public init(from decoder: any Decoder) throws {
            rawValue = try decoder.singleValueContainer().decode(Int.self)
        }
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
        public var rawValue: Int
        public var description: String {
            rawValue.description
        }
    }
    public var dataVersion: String
    public var fixtureType: FixtureType
}

public struct FixtureType: Codable {
    public var name: String
    public var shortName: String
    public var longName: String
    public var longNameOrFallback: String {
        if longName.isEmpty {
            if name.isEmpty {
                return shortName
            } else {
                return name
            }
        } else {
            return longName
        }
    }
    public var manufacturer: String
    public var description: String
    public var fixtureTypeID: UUID
    public var refFT: String?
    public var thumbnail: FileResource?
    public var thumbnailVector: FileResource?

    public var attributeDefinitions: AttributeDefinitions
    public var wheels: [Wheel]
    public var physicalDescriptions: PhysicalDescriptions
    public var dmxModes: [DMXMode]
    public var geometries: [Geometry]
    public var protocols: [FixtureProtocol]
    public var revisions: [Revision]
}

// this is an identical copy to FixtureType but only includes top level attributes
public struct FixtureInfo: Codable {
    public var name: String
    public var shortName: String
    public var longName: String
    public var manufacturer: String
    public var description: String
    public var fixtureTypeID: String
    public var refFT: String?
    public var thumbnail: FileResource?
    public var thumbnailVector: FileResource?
}

///
/// AttributeDefinitions Schema
///

public struct AttributeDefinitions: Codable {
    public var activationGroups: [ActivationGroup]?
    public var featureGroups: [FeatureGroup]
    public var attributes: [FixtureAttribute]
}

public struct ActivationGroup: Codable {
    public var name: String
}

public struct FeatureGroup: Codable {
    public var name: String
    public var pretty: String
    
    public var features: [Feature]
}

public struct Feature: Codable {
    public var name: String
}

public struct FixtureAttribute: Codable {
    public var name: String
    public var type: AttributeType
    public var pretty: String
    public var activationGroup: ActivationGroup?
    public var feature: Feature?
    
    // This is a node but results in recursive type
    public var mainAttribute: Node?
    
    public var physicalUnit: PhysicalUnit = .none
    public var color: ColorCIE?
    
    public var subPhysicalUnits: OrderedDictionary<SubPhysicalType, SubPhysicalUnit> = [:]
}

public struct SubPhysicalUnit: Codable {
    public var type: SubPhysicalType
    public var physicalUnit: PhysicalUnit = .none
    public var physicalFrom: Double = 0
    public var physicalTo: Double = 1
}

///
/// Wheels Schema
///

public struct Wheel: Codable {
    public var name: String
    public var slots: [Slot]
}

public struct Slot: Codable {
    public var name: String
    public var color: ColorCIE
    public var filter: Filter?
    public var mediaFileName: FileResource?
    public var slotIndex: Int
    
    public var facets: [PrismFacet]
    public var animationSystem: AnimationSystem?
}

public struct PrismFacet: Codable {
    public var color: ColorCIE
    public var rotation: Rotation
}

public struct AnimationSystem: Codable {
    public var p1: [Double]
    public var p2: [Double]
    public var p3: [Double]
    
    public var radius: Double
}

///
/// Physical Description Schema
///

public struct PhysicalDescriptions: Codable {
    public var emitters: [Emitter]
    public var filters: [Filter]
    public var colorSpace: ColorSpace?
    public var additionalColorSpaces: [ColorSpace]
    public var dmxProfiles: [DMXProfile]
    public var properties: Properties?
}

public struct Emitter: Codable {
    public var name: String
    public var color: ColorCIE?
    public var dominantWavelength: Double?
    public var diodePart: String?
    
    public var measurements: [GDTFMeasurement]
}

public struct GDTFMeasurement: Codable {
    public var physical: Double
    public var luminousIntensity: Double?
    public var transmission: Double?
    public var interpolationTo: InterpolationTo
    
    public var measurements: [MeasurementPoint]
}

public struct MeasurementPoint: Codable {
    public var wavelength: Double
    public var energy: Double
}

public struct Filter: Codable {
    public var name: String
    public var color: ColorCIE
    
    public var measurements: [GDTFMeasurement]
}

public struct ColorSpace: Codable {
    public var name: String
    public var mode: ColorSpaceMode
    
    // Only used when mode is .custom
    public var red: ColorCIE?
    public var green: ColorCIE?
    public var blue: ColorCIE?
    public var whitePoint: ColorCIE?
}

public struct DMXProfile: Codable {
    public var name: String
    public var points: [Point]
}

public struct Point: Codable {
    public var dmxPercentage: Double
    public var cfc0: Double
    public var cfc1: Double
    public var cfc2: Double
    public var cfc3: Double
}

public struct Properties: Codable {
    public var operatingTemp: OperatingTemp
    public var weight: Double
    public var legHeight: Double
}

public struct OperatingTemp: Codable {
    public var low: Double
    public var high: Double
}

///
/// DMX Mode Schema
///

public struct DMXMode: Codable {
    /// The unique name of the DMX mode
    public var name: String
    /// Description of the DMX mode
    public var description: String
    /// Name of the first geometry in the device; Only top level geometries are allowed to be linked.
    ///
    /// In theory requred but ~50 fixtures don't have it. GDTF Share Editor already complains about it.
    /// We might want to revisit and make this required but for now I have opted to just handle this case (by complaining in the UI about is as well)
    public var geometry: String?
    /// Description of all DMX channels used in the mode
    public var channels: [DMXChannel]
    /// Description of relations between channels
    public var relations: [Relation]
    /// Is used to describe macros of the manufacturer.
    public var macros: [Macro]
    public init(name: String, description: String, geometry: String, channels: [DMXChannel], relations: [Relation], macros: [Macro]) {
        self.name = name
        self.description = description
        self.geometry = geometry
        self.channels = channels
        self.relations = relations
        self.macros = macros
    }

    public func maxOffset() -> Int? {
        channels.lazy.map { $0.offset.max() ?? 0 }.max()
    }
}

public struct DMXChannel: Codable {
    public enum Break: Codable, Comparable, Hashable {
        case id(Int)
        case overwrite
        init?(rawValue: String) {
            if rawValue == "Overwrite" {
                self = .overwrite
            } else if let id = Int(rawValue) {
                self = .id(id)
            } else {
                return nil
            }
        }
    }
    public var name: String?
    public var dmxBreak: Break
    public var offset: [Int]
    public var initialFunction: ChannelFunction?
    public var highlight: DMXValue?
    
    public var logicalChannels: [LogicalChannel]
    public var geometry: String
}

public struct LogicalChannel: Codable {
    public var attribute: FixtureAttribute
    public var snap: Snap
    public var master: Master
    public var mibFade: Double
    public var dmxChangeTimeLimit: Double
    
    public var channelFunctions: [ChannelFunction]
}

public struct ChannelFunction: Codable {
    public var name: String
    public var attribute: FixtureAttribute?
    public var originalAttribute: String
    public var dmxFrom: DMXValue
    public var dmxDefault: DMXValue
    public var physicalFrom: Double
    public var physicalTo: Double
    public var realFade: Double
    public var realAcceleration: Double
    
    public var wheel: Wheel?
    public var emitter: Emitter?
    public var filter: Filter?
    public var colorSpace: ColorSpace?
    
    // modeMaster is a node but can have multiple types
    // wil revisit this later
    public var modeMaster: Node?
    public var modeFrom: DMXValue?
    public var modeTo: DMXValue?
    
    public var dmxProfile: DMXProfile?
    
    public var minimum: Double
    public var maximum: Double
    public var customName: String?
    
    public var channelSets: [ChannelSet]
    public var subChannelSets: [SubChannelSet]
}

public struct ChannelSet: Codable {
    public var name: String
    public var dmxFrom: DMXValue
    public var physicalFrom: Double
    public var physicalTo: Double
    /// If the channel function has a link to a wheel, a corresponding slot index shall be specified. The wheel slot index results from the order of slots of the wheel which is linked in the channel function. The wheel slot index is normalized to 1.
    var _wheelSlotIndex: Int?
    /// The wheel slot index starting from zero so you can use it directly to index into the whell slot.
    public var wheelSlotIndex: Int? {
        get { _wheelSlotIndex.map { $0 - 1 } }
        set { _wheelSlotIndex = newValue.map { $0 + 1 } }
    }
}

public struct SubChannelSet: Codable {
    public var name: String
    public var physicalFrom: Double
    public var physicalTo: Double
    public var subPhysicalUnit: SubPhysicalUnit
    public var wheelSlotIndex: Int?
    public var dmxProfile: DMXProfile?
}

public struct Relation: Codable {
    public var name: String
    public var master: String
    public var follower: String
    public var type: RelationType
}

public struct Macro: Codable {
    public var name: String
    public var channelFunction: String?
    
    public var steps: [MacroStep]
}

public struct MacroStep: Codable {
    public var duration: Double
    public var values: [MacroValue]
}

public struct MacroValue: Codable {
    public var value: DMXValue
    public var dmxChannel: String
}

/// If the device supports one or several additional protocols, these protocol specific information have to be specified.
///
/// There are more protoclls in the spec but they don't really contain usefull information yet.
/// I don't really understand what the sACN/ArtNet mappings are for either so leaving them out for now.
/// I also check on 18/01/26 that no GDTF file on the share contains anything but RDM.
public enum FixtureProtocol: Codable {
    public enum Kind: String {
        case rdm = "FTRDM"
        case artNet = "Art-Net"
        case sACN = "sACN"
        case posiStageNet = "PosiStageNet"
        case openSoundControl = "OpenSoundControl"
    }
    case rdm(RDM)
}

public struct RDM: Codable {
    /// Manufacturer ESTA ID
    public var manufacturerID: UInt16
    /// Unique device model ID
    public var deviceModelID: UInt32
    /// all software versions and their supported DMX modes
    public var softwareVersions: [SofwareVersion]
    
    /// mmmm:dddddddd, where mmmm is the Manufacturer ID in hexadecimal and dddddddd is the Device ID in hexadecimal.
    public var uid: String {
        String(format: "%04X:%08X", manufacturerID, deviceModelID)
    }
}

extension RDM {
    public struct SofwareVersion: Codable {
        /// Software version ID
        public var id: UInt32
        /// supported DMX modes
        public var personalties: [DMXPersonality]
    }
    public struct DMXPersonality: Codable {
        /// Hex Value of the DMXPersonality
        public var id: UInt16
        /// Link to the DMX Mode that can be used with this software version.
        public var dmxMode: String
    }
}

public struct Revision: Codable {
    /// User-defined text for this revision; Default value: empty
    public var text: String
    /// Revision date and time
    public var date: Date
    /// UserID of the user that has uploaded the GDTF file to the database; Default value: 0
    public var userID: Int
    /// Name of the software that modified this revision; Default value: empty
    public var modifiedBy: String
}
