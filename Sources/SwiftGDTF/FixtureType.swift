//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/3/24.
//

import Foundation
import XMLCoder

/// Rename property wrappers to not conflict with Attribute struct
public typealias XMLAttribute = XMLCoder.Attribute
public typealias XMLElement = XMLCoder.Element

public struct GDTF: Codable {
    @XMLElement public var fixtureType: FixtureType
    @XMLAttribute public var dataVersion: String
    
    enum CodingKeys: String, CodingKey {
        case fixtureType = "FixtureType"
        case dataVersion = "DataVersion"
    }
}

public struct FixtureType: Codable {
    @XMLAttribute public var name: String
    @XMLAttribute public var shortName: String
    @XMLAttribute public var longName: String
    @XMLAttribute public var manufacturer: String
    @XMLAttribute public var description: String
    @XMLAttribute public var fixtureTypeID: String
    @XMLAttribute public var thumbnail: String
    @XMLAttribute public var refFT: String
    
    @XMLElement public var attributeDefinitions: AttributeDefinitions
    @XMLCollection public var wheels: [Wheel]
    @XMLElement public var physicalDescriptions: PhysicalDesctiptions
    
    enum CodingKeys: String, CodingKey {
        // Attributes
        case name = "Name"
        case shortName = "ShortName"
        case longName = "LongName"
        case manufacturer = "Manufacturer"
        case description = "Description"
        case fixtureTypeID = "FixtureTypeID"
        case thumbnail = "Thumbnail"
        case refFT = "RefFT"
        
        // Elements
        case attributeDefinitions = "AttributeDefinitions"
        case wheels = "Wheels"
        case physicalDescriptions = "PhysicalDescriptions"
    }
}


///
/// ATTRIBUTE DEFINITIONS
///
public struct AttributeDefinitions: Codable {
    @XMLCollection public var activationGroups: [ActivationGroup]
    @XMLCollection public var featureGroups: [FeatureGroup]
    @XMLCollection public var attributes: [Attribute]

    enum CodingKeys: String, CodingKey {
        case activationGroups = "ActivationGroups"
        case featureGroups = "FeatureGroups"
        case attributes = "Attributes"
    }
}

public struct ActivationGroup: Codable, XMLCollectionElement {
    public static var tagName: String = "ActivationGroup"
    
    @XMLAttribute public var name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
    }
}

public struct FeatureGroup: Codable, XMLCollectionElement {
    public static var tagName: String = "FeatureGroup"

    @XMLAttribute public var name: String
    @XMLAttribute public var pretty: String
    
    public var features: [Feature]
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case pretty = "Pretty"
        case features = "Feature"
    }
}

public struct Feature: Codable {
    
    @XMLAttribute public var name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
    }
}

public struct Attribute: Codable, XMLCollectionElement {
    public static var tagName: String = "Attribute"

    @XMLAttribute public var name: String
    @XMLAttribute public var pretty: String
    @XMLAttribute public var activationGroup: String?
    @XMLAttribute public var feature: String
    @XMLAttribute public var mainAttribute: String?
    @XMLAttribute public var physicalUnit: PhysicalUnit
    @XMLAttribute public var color: ColorCIE?
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case pretty = "Pretty"
        case activationGroup = "ActivationGroup"
        case feature = "Feature"
        case mainAttribute = "MainAttribute"
        case physicalUnit = "PhysicalUnit"
        case color = "Color"
    }
}

///
/// WHEELS
///

public struct Wheel: Codable, XMLCollectionElement {
    public static var tagName: String = "Wheel"
    
    @XMLAttribute public var name: String
    public var slots: [WheelSlot]
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case slots = "Slot"
    }
}

public struct WheelSlot: Codable {
    @XMLAttribute public var name: String
    @XMLAttribute public var color: ColorCIE
    @XMLAttribute public var wheelFilter: String?
    @XMLAttribute public var mediaFilename: String?
    public var facets: [PrismFacet]
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case color = "Color"
        case wheelFilter = "Filter"
        case mediaFilename = "MediaFileName"
        case facets = "Facet"
    }
}

public struct PrismFacet: Codable {    
    @XMLAttribute public var color: ColorCIE
    @XMLAttribute public var rotation: String

    enum CodingKeys: String, CodingKey {
        case color = "Color"
        case rotation = "Rotation"
    }
}

///
/// PHYSICAL DESCRIPTIONS
///

public struct PhysicalDesctiptions: Codable {
    @XMLElement public var colorSpace: ColorSpace?
    @XMLCollection public var additionalColorSpaces: [ColorSpace]
    @XMLCollection public var gamuts: [Gamut]
    
    enum CodingKeys: String, CodingKey {
        case colorSpace = "ColorSpace"
        case additionalColorSpaces = "AdditionalColorSpaces"
        case gamuts = "Gamuts"
    }
}

public struct ColorSpace: Codable, XMLCollectionElement {
    public static var tagName: String = "ColorSpace"
    
    @XMLAttribute public var mode: ColorSpaceMode
    @XMLAttribute public var name: String
    
    @XMLAttribute public var red: ColorCIE?
    @XMLAttribute public var green: ColorCIE?
    @XMLAttribute public var blue: ColorCIE?
    @XMLAttribute public var whitePoint: ColorCIE?
    
    enum CodingKeys: String, CodingKey {
        case mode = "Mode"
        case name = "Name"
        
        case red = "Red"
        case green = "Green"
        case blue = "Blue"
        case whitePoint = "WhitePoint"
    }
}

public struct Gamut: Codable, XMLCollectionElement {
    public static var tagName: String = "Gamut"
    
    @XMLAttribute public var name: String
    public var points: [ColorCIE]

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case points = "Rotation"
    }
}

