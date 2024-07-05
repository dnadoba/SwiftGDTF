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
    
    public let name: String
    public let shortName: String
    public let longName: String
    public let manufacturer: String
    public let description: String
    public let fixtureTypeID: String
    public let refFT: String?
    public let thumbnail: FileResource?
    
    public let attributeDefinitions: AttributeDefinitions
}

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
