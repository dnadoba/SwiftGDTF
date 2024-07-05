//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash

protocol XMLDecodable {
    init(xml: XMLIndexer)
}

extension GDTF: XMLDecodable {
    init(xml: XMLIndexer) {
        self.dataVersion = xml["GDTF"].element!.attribute(by: "DataVersion")!.text
        self.fixtureType = FixtureType(xml: xml["GDTF"]["FixtureType"])
    }
}

extension FixtureType: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.shortName = element.attribute(by: "ShortName")!.text
        self.longName = element.attribute(by: "LongName")!.text
        self.manufacturer = element.attribute(by: "Manufacturer")!.text
        self.description = element.attribute(by: "Description")!.text
        self.fixtureTypeID = element.attribute(by: "FixtureTypeID")!.text
        self.refFT = element.attribute(by: "RefFT")?.text
        self.thumbnail = FileResource(name: element.attribute(by: "Thumbnail")?.text, fileExtension: "png")
        
        self.attributeDefinitions = AttributeDefinitions(xml: xml["AttributeDefinitions"])
    }
}

extension AttributeDefinitions: XMLDecodable {
    init(xml: XMLIndexer) {
        self.activationGroups = xml["ActivationGroups"].children.map { group in
            ActivationGroup(xml: group)
        }
        
        self.featureGroups = xml["FeatureGroups"].children.map { group in
            FeatureGroup(xml: group)
        }
        
        self.attributes = xml["Attributes"].children.map { attribute in
            FixtureAttribute(xml: attribute)
        }
    }
}

extension ActivationGroup: XMLDecodable {
    init(xml: XMLIndexer) {
        self.name = xml.element!.attribute(by: "Name")!.text
    }
}

extension FeatureGroup: XMLDecodable{
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.pretty = element.attribute(by: "Pretty")!.text
        self.features = xml.children.map { feature in
            Feature(xml: feature)
        }
    }
}

extension Feature: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        self.name = xml.element!.attribute(by: "Name")!.text
    }
}

extension FixtureAttribute: XMLDecodable {
    init(xml: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.pretty = element.attribute(by: "Pretty")!.text
        self.activationGroup = element.attribute(by: "ActivationGroup")?.text
        self.feature = element.attribute(by: "Feature")!.text
        self.mainAttribute = element.attribute(by: "MainAttribute")?.text
        
        if let physicalUnitString = element.attribute(by: "PhysicalUnit")?.text {
            self.physicalUnit = PhysicalUnit(rawValue: physicalUnitString)!
        }
        
        if let colorString = element.attribute(by: "Color")?.text {
            self.color = ColorCIE(from: colorString)
        }
        
        self.subPhysicalUnits = xml.children.map { subPhysicalUnit in
            SubPhysicalUnit(xml: subPhysicalUnit)
        }
    }
}

extension SubPhysicalUnit: XMLDecodable {
    init(xml: XMLIndexer) {
        let element = xml.element!
        
        self.physicalFrom = Float(element.attribute(by: "PhysicalTo")!.text)!
        self.physicalTo = Float(element.attribute(by: "PhysicalTo")!.text)!
        
        self.physicalUnit = PhysicalUnit(rawValue: element.attribute(by: "PhysicalUnit")!.text)!
        
        self.type = SubPhysicalType(rawValue: element.attribute(by: "Type")!.text)!
    }
}
