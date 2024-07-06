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
        
        self.wheels = xml["Wheels"].mapChildrenToTypeArray(tree: tree)
        
        self.physicalDescriptions = PhysicalDescriptions(xml: xml["PhysicalDescriptions"], tree: tree)
    }
}

///
/// AttributeDefinitions Schema
///

extension AttributeDefinitions: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.activationGroups = xml["ActivationGroups"].mapChildrenToTypeArray(tree: tree)
        self.featureGroups = xml["FeatureGroups"].mapChildrenToTypeArray(tree: tree)
        self.attributes = xml["Attributes"].mapChildrenToTypeArray(tree: tree)
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
        self.features = xml.mapChildrenToTypeArray(tree: tree)
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
                tree: tree)!
        
        // This is technically a node but results in a recursive type
        self.mainAttribute = element.attribute(by: "MainAttribute")?.text
                
        self.physicalUnit = element.attribute(by: "PhysicalUnit")?.toEnum() ?? .none
        
        if let colorString = element.attribute(by: "Color")?.text {
            self.color = ColorCIE(from: colorString)
        }
        
        self.subPhysicalUnits = xml.mapChildrenToTypeArray(tree: tree)
    }
}

extension SubPhysicalUnit: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.float ?? 0
        self.physicalTo = element.attribute(by: "PhysicalTo")?.float ?? 1
        
        self.physicalUnit = element.attribute(by: "PhysicalUnit")?.toEnum() ?? .none
        
        self.type = element.attribute(by: "Type")!.toEnum()!
    }
}

///
/// Wheels Schema
///

extension Wheel: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.slots = xml.mapChildrenToTypeArray(tree: tree)
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
        self.emitters = xml["Emitters"].mapChildrenToTypeArray(tree: tree)
        self.filters = xml["Filters"].mapChildrenToTypeArray(tree: tree)
        
        if xml["ColorSpace"].element != nil {
            self.colorSpace = ColorSpace(xml: xml["ColorSpace"], tree: tree)
        }
        
        self.additionalColorSpaces = xml["AdditionalColorSpaces"].mapChildrenToTypeArray(tree: tree)
        self.dmxProfiles = xml["DMXProfiles"].mapChildrenToTypeArray(tree: tree)
        
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
        
        self.measurements = xml.mapChildrenToTypeArray(tree: tree)
    }
}

extension GDTFMeasurement: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.physical = Float(element.attribute(by: "Physical")!.text)!
        
        self.luminousIntensity = element.attribute(by: "LuminousIntensity")?.float
        
        if let transmission = element.attribute(by: "Transmission")?.text {
            self.transmission = Float(transmission)!
        }
                
        self.interpolationTo = element.attribute(by: "InterpolationTo")?.toEnum() ?? .linear
        
        self.measurements = xml.mapChildrenToTypeArray(tree: tree)
    }
}

extension MeasurementPoint: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.energy = element.attribute(by: "Energy")!.float!
        self.wavelength = element.attribute(by: "WaveLength")!.float!
    }
}

extension Filter: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        
        self.measurements = xml.mapChildrenToTypeArray(tree: tree)
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
        self.points = xml.mapChildrenToTypeArray(tree: tree)
    }
}

extension Point: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.dmxPercentage = Float(element.attribute(by: "DMXPercentage")?.text ?? "0")!
        
        self.cfc0 = element.attribute(by: "CFC0")?.float ?? 0
        self.cfc1 = element.attribute(by: "CFC1")?.float ?? 0
        self.cfc2 = element.attribute(by: "CFC2")?.float ?? 0
        self.cfc3 = element.attribute(by: "CFC3")?.float ?? 0
    }
}

extension Properties: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.legHeight = xml["LegHeight"].element?.attribute(by: "Value")?.float ?? 0
        self.weight = xml["Weight"].element?.attribute(by: "Value")?.float ?? 0
        
        if xml["OperatingTemperature"].element != nil {
            self.operatingTemp = OperatingTemp(xml: xml["OperatingTemperature"], tree: tree)
        } else {
            self.operatingTemp = OperatingTemp(low: 0, high: 40)
        }
    }
}

extension OperatingTemp: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.low = element.attribute(by: "Low")?.float ?? 0
        self.high = element.attribute(by: "High")?.float ?? 40
    }
}

///
/// DMX Mode Schema
///

extension DMXMode: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.description = element.attribute(by: "Description")!.text
        
        self.channels = xml["DMXChannels"].mapChildrenToTypeArray(tree: tree)
    }
}

extension DMXChannel: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.dmxBreak = Int(element.attribute(by: "DMXBreak")!.text)!
        
        if element.attribute(by: "DMXBreak")!.text != "None" {
            self.offset = element.attribute(by: "DMXBreak")!.text.split(separator: ",").map { Int($0)! }
        }
        
        // compute the channel path without the first element (which seems to define the current node
        var channelPath: String = element.attribute(by: "InitialFunction")!.text
                                    .components(separatedBy: ".")
                                    .dropFirst()
                                    .joined(separator: ".")
        
        self.initialFunction = resolveNode(path: channelPath, base: xml, tree: tree)!
        self.logicalChannels = xml.mapChildrenToTypeArray(tree: tree)
    }
}

extension LogicalChannel: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) {
        let element = tree.element!
        
        self.attribute = resolveNode(
            path: element.attribute(by: "Attribute")!.text,
            base: tree["AttributeDefinitions"]["Attributes"],
            tree: tree)!
        
        self.snap = element.attribute(by: "Attribute")?.toEnum() ?? .no
        self.master = element.attribute(by: "Master")?.toEnum() ?? .none
        
        self.mibFade = element.attribute(by: "MIBFade")?.float ?? 0
        self.dmxChangeTimeLimit = element.attribute(by: "DMXChangeTimeLimit")?.float ?? 0
        
        self.channelFunctions = xml.mapChildrenToTypeArray(tree: tree)
    }
}

extension ChannelFunction: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) {
        let element = tree.element!
        
        self.name = element.attribute(by: "Name")!.text
        
        if element.attribute(by: "Attribute")?.text != "NoFeature" {
            self.attribute = resolveNode(path: element.attribute(by: "Attribute")?.text,
                                         base: tree["AttributeDefinitions"]["Attributes"],
                                         tree: tree)
        }
        
        self.originalAttribute = element.attribute(by: "OriginalAttribute")!.text
        self.dmxFrom = DMXValue(from: element.attribute(by: "DMXFrom")!.text)
        self.dmxDefault = DMXValue(from: element.attribute(by: "Default")!.text)
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.float ?? 0
        self.physicalTo = element.attribute(by: "PhysicalTo")?.float ?? 1
        self.realFade = element.attribute(by: "RealFade")?.float ?? 0
        self.realAcceleration = element.attribute(by: "RealAcceleration")?.float ?? 0
        
        // handle node resolution for each
        
        
    }
    
}
