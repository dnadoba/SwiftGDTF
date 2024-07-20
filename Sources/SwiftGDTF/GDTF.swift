//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash

/// This is used to show a String that maps to a node that we cannot currently process
/// (usually because it results in a recursive type)
public typealias Node = String

public struct GDTF: Codable {
    public var dataVersion: String
    public var fixtureType: FixtureType
}

public struct FixtureType: Codable {
    public var name: String
    public var shortName: String
    public var longName: String
    public var manufacturer: String
    public var description: String
    public var fixtureTypeID: String
    public var refFT: String?
    public var thumbnail: FileResource?
    
    public var attributeDefinitions: AttributeDefinitions
    public var wheels: [Wheel]
    public var physicalDescriptions: PhysicalDescriptions?
    public var dmxModes: [DMXMode]
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
    public var pretty: String
    public var activationGroup: ActivationGroup?
    public var feature: Feature
    
    // This is a node but results in recursive type
    public var mainAttribute: Node?
    
    public var physicalUnit: PhysicalUnit = .none
    public var color: ColorCIE?
    
    public var subPhysicalUnits: [SubPhysicalUnit] = []
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
    public var name: String
    public var description: String
    
    public var channels: [DMXChannel]
    public var relations: [Relation]
    public var macros: [Macro]
}

public struct DMXChannel: Codable {
    public var name: String?
    public var dmxBreak: Int
    public var offset: [Int]
    public var initialFunction: ChannelFunction
    public var highlight: DMXValue?
    
    public var logicalChannel: LogicalChannel
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
    public var wheelSlotIndex: Int?
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
    public var master: DMXChannel
    public var follower: DMXChannel
    public var type: RelationType
}

public struct Macro: Codable {
    public var name: String
    public var channelFunction: ChannelFunction?
    
    public var steps: [MacroStep]
}

public struct MacroStep: Codable {
    public var duration: Double
    public var values: [MacroValue]
}

public struct MacroValue: Codable {
    public var value: DMXValue
    public var dmxChannel: DMXChannel
}
