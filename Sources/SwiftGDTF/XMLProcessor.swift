//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash

protocol XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer)
}

func resolveNode<T: XMLDecodable>(path pathStr: String, base: XMLIndexer, tree fullTree: XMLIndexer) -> T {
    let path = pathStr.components(separatedBy: ".")
    var tree = base
    
    for step in path {
        tree = tree.children.first(where: { child in
            if let name = child.element!.attribute(by: "Name")?.text {
                return name == step
            }
            
            return false
        })!
    }
    
    return T(xml: tree, tree: fullTree)    
}

extension GDTF {
    init(xml: XMLIndexer) {
        self.dataVersion = xml["GDTF"].element!.attribute(by: "DataVersion")!.text
        self.fixtureType = FixtureType(xml: xml["GDTF"]["FixtureType"], tree: xml["GDTF"]["FixtureType"])
    }
}

extension FixtureType: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.shortName = element.attribute(by: "ShortName")!.text
        self.longName = element.attribute(by: "LongName")!.text
        self.manufacturer = element.attribute(by: "Manufacturer")!.text
        self.description = element.attribute(by: "Description")!.text
        self.fixtureTypeID = element.attribute(by: "FixtureTypeID")!.text
        self.refFT = element.attribute(by: "RefFT")?.text
        self.thumbnail = FileResource(name: element.attribute(by: "Thumbnail")?.text, fileExtension: "png")
        
        self.attributeDefinitions = AttributeDefinitions(xml: xml["AttributeDefinitions"], tree: tree)
        
        self.wheels = xml["Wheels"].children.map { wheel in
            Wheel(xml: wheel, tree: tree)
        }
        
        self.physicalDescriptions = PhysicalDescriptions(xml: xml["PhysicalDescriptions"], tree: tree)
    }
}

///
/// AttributeDefinitions Schema
///

extension AttributeDefinitions: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.activationGroups = xml["ActivationGroups"].children.map { group in
            ActivationGroup(xml: group, tree: tree)
        }
        
        self.featureGroups = xml["FeatureGroups"].children.map { group in
            FeatureGroup(xml: group, tree: tree)
        }
        
        self.attributes = xml["Attributes"].children.map { attribute in
            FixtureAttribute(xml: attribute, tree: tree)
        }
    }
}

extension ActivationGroup: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.name = xml.element!.attribute(by: "Name")!.text
    }
}

extension FeatureGroup: XMLDecodable{
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.pretty = element.attribute(by: "Pretty")!.text
        self.features = xml.children.map { feature in
            Feature(xml: feature, tree: tree)
        }
    }
}

extension Feature: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.name = xml.element!.attribute(by: "Name")!.text
    }
}

extension FixtureAttribute: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.pretty = element.attribute(by: "Pretty")!.text
        
        // Resolve ActivationGroup Node
        if let groupPath = element.attribute(by: "ActivationGroup")?.text {
            self.activationGroup = resolveNode(path: groupPath, base: tree["AttributeDefinitions"]["ActivationGroups"], tree: tree)
        }
        
        // Resolve Feature Node
        self.feature = resolveNode(
                path: element.attribute(by: "Feature")!.text, 
                base: tree["AttributeDefinitions"]["FeatureGroups"],
                tree: tree)
        
        // Resolve Feature Node
        self.mainAttribute = element.attribute(by: "MainAttribute")?.text
                
        if let physicalUnitString = element.attribute(by: "PhysicalUnit")?.text {
            self.physicalUnit = PhysicalUnit(rawValue: physicalUnitString)!
        }
        
        if let colorString = element.attribute(by: "Color")?.text {
            self.color = ColorCIE(from: colorString)
        }
        
        self.subPhysicalUnits = xml.children.map { subPhysicalUnit in
            SubPhysicalUnit(xml: subPhysicalUnit, tree: tree)
        }
    }
}

extension SubPhysicalUnit: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
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
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.slots = xml.children.map { slot in
            Slot(xml: slot, tree: tree)
        }
    }
}

extension Slot: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        
        if let filterPath = element.attribute(by: "Filter")?.text {
            self.filter = resolveNode(path: filterPath,
                                      base: tree["PhysicalDescriptions"]["Filters"], 
                                      tree: tree)
        }
        
        self.mediaFileName = FileResource(name: element.attribute(by: "MediaFileName")?.text, fileExtension: "png")
        
        self.facets = []
        
        for child in xml.children {
            switch child.element?.name {
                case "Facet":
                    self.facets.append(PrismFacet(xml: child, tree: tree))
                case "AnimationSystem":
                    self.animationSystem = AnimationSystem(xml: child, tree: tree)
                default:
                    continue
            }
        }
    }
}

extension PrismFacet: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        self.rotation = Rotation(from: element.attribute(by: "Rotation")!.text)
    }
}

extension AnimationSystem: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.p1 = element.attribute(by: "P1")!.text.split(separator: ",").map { Float($0)! }
        self.p2 = element.attribute(by: "P1")!.text.split(separator: ",").map { Float($0)! }
        self.p3 = element.attribute(by: "P1")!.text.split(separator: ",").map { Float($0)! }
        
        self.radius = Float(element.attribute(by: "P1")!.text)!
    }
}

///
/// Physical Description Schema
///

extension PhysicalDescriptions: XMLDecodable {
    // this object can not exist in which case we will be null
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.emitters = xml["Emitters"].children.map { emitter in
            Emitter(xml: emitter, tree: tree)
        }
        
        self.filters = xml["Filters"].children.map { filter in
            Filter(xml: filter, tree: tree)
        }
        
        if let _ = xml["ColorSpace"].element {
            self.colorSpace = ColorSpace(xml: xml["ColorSpace"], tree: tree)
        }
        
        self.additionalColorSpaces = xml["AdditionalColorSpaces"].children.map { space in
            ColorSpace(xml: space, tree: tree)
        }
        
        self.dmxProfiles = xml["DMXProfiles"].children.map { dmx in
            DMXProfile(xml: dmx, tree: tree)
        }
        
        self.properties = Properties(xml: xml["Properties"], tree: tree)
    }
}

extension Emitter: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
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
            GDTFMeasurement(xml: measurement, tree: tree)
        }
    }
}

extension GDTFMeasurement: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
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
            MeasurementPoint(xml: point, tree: tree)
        }
    }
}

extension MeasurementPoint: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.energy = Float(element.attribute(by: "Energy")!.text)!
        self.wavelength = Float(element.attribute(by: "WaveLength")!.text)!
    }
}

extension Filter: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        
        self.measurements = xml.children.map { measurement in
            GDTFMeasurement(xml: measurement, tree: tree)
        }
    }
}

extension ColorSpace: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.mode = ColorSpaceMode(rawValue: element.attribute(by: "Mode")!.text)!
    }
}

extension DMXProfile: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        
        self.points = xml.children.map { point in
            Point(xml: point, tree: tree)
        }
    }
}

extension Point: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.dmxPercentage = Float(element.attribute(by: "DMXPercentage")?.text ?? "0")!
        
        self.cfc0 = Float(element.attribute(by: "CFC0")?.text ?? "0")!
        self.cfc1 = Float(element.attribute(by: "CFC1")?.text ?? "0")!
        self.cfc2 = Float(element.attribute(by: "CFC2")?.text ?? "0")!
        self.cfc3 = Float(element.attribute(by: "CFC3")?.text ?? "0")!
    }
}

extension Properties: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.legHeight = Float(xml["LegHeight"].element?.attribute(by: "Value")?.text ?? "0")!
        self.weight = Float(xml["Weight"].element?.attribute(by: "Value")?.text ?? "0")!
        
        self.operatingTemp = OperatingTemp(xml: xml["OperatingTemperature"], tree: tree)
    }
}

extension OperatingTemp: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.low = Float(element.attribute(by: "Low")!.text)!
        self.high = Float(element.attribute(by: "High")!.text)!
    }
}
