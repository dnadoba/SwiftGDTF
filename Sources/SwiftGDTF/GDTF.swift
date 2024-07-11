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

public struct GDTF {
    public var dataVersion: String
    public var fixtureType: FixtureType
}

public struct FixtureType {
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

///
/// AttributeDefinitions Schema
///

public struct AttributeDefinitions {
    public var activationGroups: [ActivationGroup]?
    public var featureGroups: [FeatureGroup]
    public var attributes: [FixtureAttribute]
}

public struct ActivationGroup {
    public var name: String
}

public struct FeatureGroup {
    public var name: String
    public var pretty: String
    
    public var features: [Feature]
}

public struct Feature {
    public var name: String
}

public struct FixtureAttribute {
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

public struct SubPhysicalUnit {
    public var type: SubPhysicalType
    public var physicalUnit: PhysicalUnit = .none
    public var physicalFrom: Float = 0
    public var physicalTo: Float = 1
}

///
/// Wheels Schema
///

public struct Wheel {
    public var name: String
    public var slots: [Slot]
}

public struct Slot {
    public var name: String
    public var color: ColorCIE
    public var filter: Filter?
    public var mediaFileName: FileResource?
    
    public var facets: [PrismFacet]
    public var animationSystem: AnimationSystem?
}

public struct PrismFacet {
    public var color: ColorCIE
    public var rotation: Rotation
}

public struct AnimationSystem {
    public var p1: [Float]
    public var p2: [Float]
    public var p3: [Float]
    
    public var radius: Float
}

///
/// Physical Description Schema
///

public struct PhysicalDescriptions {
    public var emitters: [Emitter]
    public var filters: [Filter]
    public var colorSpace: ColorSpace?
    public var additionalColorSpaces: [ColorSpace]
    public var dmxProfiles: [DMXProfile]
    public var properties: Properties?
}

public struct Emitter {
    public var name: String
    public var color: ColorCIE?
    public var dominantWavelength: Float?
    public var diodePart: String?
    
    public var measurements: [GDTFMeasurement]
}

public struct GDTFMeasurement {
    public var physical: Float
    public var luminousIntensity: Float?
    public var transmission: Float?
    public var interpolationTo: InterpolationTo
    
    public var measurements: [MeasurementPoint]
}

public struct MeasurementPoint {
    public var wavelength: Float
    public var energy: Float
}

public struct Filter {
    public var name: String
    public var color: ColorCIE
    
    public var measurements: [GDTFMeasurement]
}

public struct ColorSpace {
    public var name: String
    public var mode: ColorSpaceMode
    
    // Only used when mode is .custom
    public var red: ColorCIE?
    public var green: ColorCIE?
    public var blue: ColorCIE?
    public var whitePoint: ColorCIE?
}

public struct DMXProfile {
    public var name: String
    public var points: [Point]
}

public struct Point {
    public var dmxPercentage: Float
    public var cfc0: Float
    public var cfc1: Float
    public var cfc2: Float
    public var cfc3: Float
}

public struct Properties {
    public var operatingTemp: OperatingTemp
    public var weight: Float
    public var legHeight: Float
}

public struct OperatingTemp {
    public var low: Float
    public var high: Float
}

///
/// DMX Mode Schema
///

public struct DMXMode {
    public var name: String
    public var description: String
    
    public var channels: [DMXChannel]
    public var relations: [Relation]
    public var macros: [Macro]
}

public struct DMXChannel {
    public var name: String?
    public var dmxBreak: Int
    public var offset: [Int]?
    public var initialFunction: ChannelFunction
    public var highlight: DMXValue?
    
    public var logicalChannels: [LogicalChannel]
}

public struct LogicalChannel {
    public var attribute: FixtureAttribute
    public var snap: Snap
    public var master: Master
    public var mibFade: Float
    public var dmxChangeTimeLimit: Float
    
    public var channelFunctions: [ChannelFunction]
}

public struct ChannelFunction {
    public var name: String
    public var attribute: FixtureAttribute?
    public var originalAttribute: String
    public var dmxFrom: DMXValue
    public var dmxDefault: DMXValue
    public var physicalFrom: Float
    public var physicalTo: Float
    public var realFade: Float
    public var realAcceleration: Float
    
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
    
    public var minimum: Float
    public var maximum: Float
    public var customName: String?
    
    public var channelSets: [ChannelSet]
    public var subChannelSets: [SubChannelSet]
}

public struct ChannelSet {
    public var name: String
    public var dmxFrom: DMXValue
    public var physicalFrom: Float
    public var physicalTo: Float
    public var wheelSlotIndex: Int?
}

public struct SubChannelSet {
    public var name: String
    public var physicalFrom: Float
    public var physicalTo: Float
    public var subPhysicalUnit: SubPhysicalUnit
    public var wheelSlotIndex: Int?
    public var dmxProfile: DMXProfile?
}

public struct Relation {
    public var name: String
    public var master: DMXChannel
    public var follower: DMXChannel
    public var type: RelationType
}

public struct Macro {
    public var name: String
    public var channelFunction: ChannelFunction?
    
    public var steps: [MacroStep]
}

public struct MacroStep {
    public var duration: Float
    public var values: [MacroValue]
}

public struct MacroValue {
    public var value: DMXValue
    public var dmxChannel: DMXChannel
}
