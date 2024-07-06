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
        
        self.wheels = xml["Wheels"].children.map { wheel in
            Wheel(xml: wheel)
        }
        
        self.physicalDescriptions = PhysicalDescriptions(xml: xml["PhysicalDescriptions"])
    }
}

///
/// AttributeDefinitions Schema
///

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

///
/// Wheels Schema
///

extension Wheel: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.slots = xml.children.map { slot in
            Slot(xml: slot)
        }
    }
}

extension Slot: XMLDecodable {
    init(xml: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        self.filter = element.attribute(by: "Filter")?.text
        self.mediaFileName = FileResource(name: element.attribute(by: "MediaFileName")?.text, fileExtension: "png")
        
        self.facets = xml.children.map { facet in
            PrismFacet(xml: facet)
        }
    }
}

extension PrismFacet: XMLDecodable {
    init(xml: XMLIndexer) {
        let element = xml.element!
        
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        self.rotation = Rotation(from: element.attribute(by: "Rotation")!.text)
    }
}

///
/// Physical Description Schema
///
extension PhysicalDescriptions: XMLDecodable {
    // this object can not exist in which case we will be null
    init(xml: XMLIndexer) {
        self.emitters = xml["Emitters"].children.map { emitter in
            Emitter(xml: emitter)
        }
        
        self.filters = xml["Filters"].children.map { filter in
            Filter(xml: filter)
        }
        
        if let _ = xml["ColorSpace"].element {
            self.colorSpace = ColorSpace(xml: xml["ColorSpace"])
        }
        
        self.additionalColorSpaces = xml["AdditionalColorSpaces"].children.map { space in
            ColorSpace(xml: space)
        }
        
        self.dmxProfiles = xml["DMXProfiles"].children.map { dmx in
            DMXProfile(xml: dmx)
        }
        
        self.properties = Properties(xml: xml["Properties"])
    }
}

extension Emitter: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        self.name = element.attribute(by: "Name")!.text
        
        if let color = element.attribute(by: "Color")?.text {
            self.color = ColorCIE(from: color)
        }
        
        if let wavelength = element.attribute(by: "DominantWaveLength")?.text {
            self.dominantWavelength = Float(wavelength)
        }
        
        self.diodePart = element.attribute(by: "DiodePart")?.text
        
        self.measurements = xml.children.map { measurement in
            GDTFMeasurement(xml: measurement)
        }
    }
}

extension GDTFMeasurement: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.physical = Float(element.attribute(by: "Physical")!.text)!
        
        if let luminousIntensity = element.attribute(by: "LuminousIntensity")?.text {
            self.luminousIntensity = Float(luminousIntensity)!
        }
        
        if let transmission = element.attribute(by: "Transmission")?.text {
            self.transmission = Float(transmission)!
        }
                
        self.interpolationTo = InterpolationTo(rawValue: element.attribute(by: "InterpolationTo")!.text)!
        
        self.measurements = xml.children.map { point in
            MeasurementPoint(xml: point)
        }
    }
}

extension MeasurementPoint: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.energy = Float(element.attribute(by: "Energy")!.text)!
        self.wavelength = Float(element.attribute(by: "WaveLength")!.text)!
    }
}

extension Filter: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        
        self.measurements = xml.children.map { measurement in
            GDTFMeasurement(xml: measurement)
        }
    }
}

extension ColorSpace: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.mode = ColorSpaceMode(rawValue: element.attribute(by: "Mode")!.text)!
    }
}

extension DMXProfile: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        
        self.points = xml.children.map { point in
            Point(xml: point)
        }
    }
}

extension Point: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.dmxPercentage = Float(element.attribute(by: "DMXPercentage")?.text ?? "0")!
        
        self.cfc0 = Float(element.attribute(by: "CFC0")?.text ?? "0")!
        self.cfc1 = Float(element.attribute(by: "CFC1")?.text ?? "0")!
        self.cfc2 = Float(element.attribute(by: "CFC2")?.text ?? "0")!
        self.cfc3 = Float(element.attribute(by: "CFC3")?.text ?? "0")!
    }
}

extension Properties: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        self.legHeight = Float(xml["LegHeight"].element?.attribute(by: "Value")?.text ?? "0")!
        self.weight = Float(xml["Weight"].element?.attribute(by: "Value")?.text ?? "0")!
        
        self.operatingTemp = OperatingTemp(xml: xml["OperatingTemperature"])
    }
}

extension OperatingTemp: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.low = Float(element.attribute(by: "Low")!.text)!
        self.high = Float(element.attribute(by: "High")!.text)!
    }
}
