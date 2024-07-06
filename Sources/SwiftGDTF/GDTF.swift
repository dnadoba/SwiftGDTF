//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash

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
    public var activationGroup: String?
    public var feature: String
    public var mainAttribute: String?
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
    public var filter: String?
    public var mediaFileName: FileResource?
    
    public var facets: [PrismFacet]
}

public struct PrismFacet {
    public var color: ColorCIE
    public var rotation: Rotation
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




