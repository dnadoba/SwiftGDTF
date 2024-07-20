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

protocol XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer)
}


extension GDTF {
    init(xml: XMLIndexer) {
        self.dataVersion = xml["GDTF"].element!.attribute(by: "DataVersion")!.text
        self.fixtureType = xml["GDTF"]["FixtureType"].parse(tree: xml["GDTF"]["FixtureType"])
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
                
        self.attributeDefinitions = xml["AttributeDefinitions"].parse(tree: tree)
        self.physicalDescriptions = xml["PhysicalDescriptions"].parse(tree: tree)
        self.wheels = xml["Wheels"].parseChildrenToArray(tree: tree)
        self.dmxModes = xml["DMXModes"].parseChildrenToArray(tree: tree)
    }
}

extension FixtureInfo: XMLDecodable {
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
    }
}

///
/// AttributeDefinitions Schema
///

extension AttributeDefinitions: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.activationGroups = xml["ActivationGroups"].parseChildrenToArray(tree: tree)
        self.featureGroups = xml["FeatureGroups"].parseChildrenToArray(tree: tree)
        self.attributes = xml["Attributes"].parseChildrenToArray(tree: tree)
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
        self.features = xml.parseChildrenToArray(tree: tree)
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
        
        self.subPhysicalUnits = xml.parseChildrenToArray(tree: tree)
    }
}

extension SubPhysicalUnit: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.double ?? 0
        self.physicalTo = element.attribute(by: "PhysicalTo")?.double ?? 1
        
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
        self.slots = xml.parseChildrenToArray(tree: tree)
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
        
        self.facets = xml.filterChildren({ child, _ in child.name == "Facet"}).parseChildrenToArray(tree: tree)
        
        if let _ = xml["AnimationSystem"].element {
            self.animationSystem = xml["AnimationSystem"].parse(tree: tree)
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
        
        self.p1 = element.attribute(by: "P1")!.text.split(separator: ",").map { Double($0)! }
        self.p2 = element.attribute(by: "P1")!.text.split(separator: ",").map { Double($0)! }
        self.p3 = element.attribute(by: "P1")!.text.split(separator: ",").map { Double($0)! }
        
        self.radius = Double(element.attribute(by: "P1")!.text)!
    }
}

///
/// Physical Description Schema
///

extension PhysicalDescriptions: XMLDecodable {
    // this object can not exist in which case we will be null
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.emitters = xml["Emitters"].parseChildrenToArray(tree: tree)
        self.filters = xml["Filters"].parseChildrenToArray(tree: tree)
        
        if xml["ColorSpace"].element != nil {
            self.colorSpace = xml["ColorSpace"].parse(tree: tree)
        }
        
        self.additionalColorSpaces = xml["AdditionalColorSpaces"].parseChildrenToArray(tree: tree)
        self.dmxProfiles = xml["DMXProfiles"].parseChildrenToArray(tree: tree)
        
        self.properties = xml["Properties"].parse(tree: tree)
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
            self.dominantWavelength = Double(wavelength)
        }
        
        self.diodePart = element.attribute(by: "DiodePart")?.text
  
        /// You can enable this if you would like, however its a lot of unneccessary data
//        self.measurements = xml.parseChildrenToArray(tree: tree)
    }
}

extension GDTFMeasurement: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.physical = Double(element.attribute(by: "Physical")!.text)!
        
        self.luminousIntensity = element.attribute(by: "LuminousIntensity")?.double
        
        if let transmission = element.attribute(by: "Transmission")?.text {
            self.transmission = Double(transmission)!
        }
                
        self.interpolationTo = element.attribute(by: "InterpolationTo")?.toEnum() ?? .linear
        
        self.measurements = xml.parseChildrenToArray(tree: tree)
    }
}

extension MeasurementPoint: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.energy = element.attribute(by: "Energy")!.double!
        self.wavelength = element.attribute(by: "WaveLength")!.double!
    }
}

extension Filter: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.color = ColorCIE(from: element.attribute(by: "Color")!.text)
        
        self.measurements = xml.parseChildrenToArray(tree: tree)
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
        self.points = xml.parseChildrenToArray(tree: tree)
    }
}

extension Point: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.dmxPercentage = Double(element.attribute(by: "DMXPercentage")?.text ?? "0")!
        
        self.cfc0 = element.attribute(by: "CFC0")?.double ?? 0
        self.cfc1 = element.attribute(by: "CFC1")?.double ?? 0
        self.cfc2 = element.attribute(by: "CFC2")?.double ?? 0
        self.cfc3 = element.attribute(by: "CFC3")?.double ?? 0
    }
}

extension Properties: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        self.legHeight = xml["LegHeight"].element?.attribute(by: "Value")?.double ?? 0
        self.weight = xml["Weight"].element?.attribute(by: "Value")?.double ?? 0
        
        if xml["OperatingTemperature"].element != nil {
            self.operatingTemp = xml["OperatingTemperature"].parse(tree: tree)
        } else {
            self.operatingTemp = OperatingTemp(low: 0, high: 40)
        }
    }
}

extension OperatingTemp: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.low = element.attribute(by: "Low")?.double ?? 0
        self.high = element.attribute(by: "High")?.double ?? 40
    }
}

///
/// DMX Mode Schema
///

extension DMXMode: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        self.name = element.attribute(by: "Name")!.text
        self.description = element.attribute(by: "Description")!.text
        
        self.channels = xml["DMXChannels"].parseChildrenToArray(tree: tree)
        self.relations = xml["Relations"].parseChildrenToArray(parent: xml, tree: tree)
        self.macros = xml["FTMacros"].parseChildrenToArray(parent: xml, tree: tree)
    }
}

extension DMXChannel: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        
        self.dmxBreak = Int(element.attribute(by: "DMXBreak")!.text)!
        
        self.offset = []
        if element.attribute(by: "DMXBreak")!.text != "None" {
            self.offset = element.attribute(by: "DMXBreak")!.text.split(separator: ",").map { Int($0)! }
        }
        
        // technically we do have a link but it does not follow convention of Node
        // the default is first logical channel function
        // the name of the channel is actually the first element in the Initial Function attribute
        let initialFunctionParts = element.attribute(by: "InitialFunction")?.text.components(separatedBy: ".")
        assert(initialFunctionParts?.count == 3)
        
        self.name = initialFunctionParts?.first
        
        let foundInitial: ChannelFunction? = xml
            .filterChildren({ child, _ in
                return child.attribute(by: "Attribute")?.text == initialFunctionParts![1]
            }).children.first?
            .filterChildren({child, _ in
                return child.attribute(by: "Name")?.text == initialFunctionParts![2]
            }).children.first?.parse(tree: tree)
        
        self.initialFunction = foundInitial ?? xml["LogicalChannel"].children.first!.parse(tree: tree)
        
        self.logicalChannel = xml.parseChildrenToArray(tree: tree).first!
        
        let highlight = element.attribute(by: "Highlight")?.text
        if highlight != nil && highlight != "None" {
            self.highlight = DMXValue(from: highlight!)
        }
    }
}

extension LogicalChannel: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!

        self.attribute = resolveNode(
            path: element.attribute(by: "Attribute")!.text,
            base: tree["AttributeDefinitions"]["Attributes"],
            tree: tree)!
        
        self.snap = element.attribute(by: "Attribute")?.toEnum() ?? .no
        self.master = element.attribute(by: "Master")?.toEnum() ?? .none
        
        self.mibFade = element.attribute(by: "MIBFade")?.double ?? 0
        self.dmxChangeTimeLimit = element.attribute(by: "DMXChangeTimeLimit")?.double ?? 0
        
        self.channelFunctions = xml.parseChildrenToArray(tree: tree)
    }
}

extension ChannelFunction: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!

        self.name = element.attribute(by: "Name")!.text
        
        if element.attribute(by: "Attribute")?.text != "NoFeature" {
            self.attribute = resolveNode(path: element.attribute(by: "Attribute")?.text,
                                         base: tree["AttributeDefinitions"]["Attributes"],
                                         tree: tree)
        }
        
        self.originalAttribute = element.attribute(by: "OriginalAttribute")?.text ?? ""
        self.dmxFrom = DMXValue(from: element.attribute(by: "DMXFrom")?.text ?? "0/1")
        self.dmxDefault = DMXValue(from: element.attribute(by: "Default")!.text)
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.double ?? 0
        self.physicalTo = element.attribute(by: "PhysicalTo")?.double ?? 1
        self.realFade = element.attribute(by: "RealFade")?.double ?? 0
        self.realAcceleration = element.attribute(by: "RealAcceleration")?.double ?? 0
        
        // handle node resolution for each type of function
        
        // Wheel
        if let wheelName = element.attribute(by: "Wheel")?.text {
            self.wheel = resolveNode(path: wheelName,
                                     base: tree["Wheels"],
                                     tree: tree)
        }
        
        // Emitter
        if let emitterName = element.attribute(by: "Emitter")?.text {
            self.emitter = resolveNode(path: emitterName,
                                     base: tree["PhysicalDescriptions"]["Emitters"],
                                     tree: tree)
        }
        
        // Filter
        if let filterName = element.attribute(by: "Filter")?.text {
            self.filter = resolveNode(path: filterName,
                                     base: tree["PhysicalDescriptions"]["Filters"],
                                     tree: tree)
        }
        
        // ColorSpace
        if let filterName = element.attribute(by: "ColorSpace")?.text {
            self.filter = resolveNode(path: filterName,
                                     base: tree["PhysicalDescriptions"],
                                     tree: tree)
        }
        
        // Mode Master
        self.modeMaster = element.attribute(by: "ModeMaster")?.text
        // modeFrom/modeTo are only used when modeMaster is prsent
        if self.modeMaster != nil {
            self.modeFrom = DMXValue(from: element.attribute(by: "ModeFrom")?.text ?? "0/1")
            self.modeTo = DMXValue(from: element.attribute(by: "ModeTo")?.text ?? "0/1")
        }
        
        // DMX Profile
        if let profilePath = element.attribute(by: "DMXProfile")?.text {
            self.dmxProfile = resolveNode(path: profilePath,
                                     base: tree["DMXProfiles"],
                                     tree: tree)
        }
        
        self.minimum = element.attribute(by: "Min")?.double ?? self.physicalFrom
        self.maximum = element.attribute(by: "Max")?.double ?? self.physicalTo
        self.customName = element.attribute(by: "CustomName")?.text
        
        self.channelSets = xml.filterChildren({ child, _ in child.name == "ChannelSet"}).parseChildrenToArray(parent: xml, tree: tree)
        
        self.subChannelSets = xml.filterChildren({ child, _ in child.name == "SubChannelSet"}).parseChildrenToArray(parent: xml, tree: tree)
    }
}


extension ChannelSet: XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.dmxFrom = DMXValue(from: element.attribute(by: "DMXFrom")?.text ?? "0/1")
        
        // the defaults for these reference parent, they will be nil if not provided
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.double
                                ?? parent.element!.attribute(by: "PhysicalFrom")!.double!
        self.physicalTo = element.attribute(by: "PhysicalTo")?.double
                                ?? parent.element!.attribute(by: "PhysicalTo")!.double!
        
        self.wheelSlotIndex = element.attribute(by: "WheelSlotIndex")?.int
    }
}

extension SubChannelSet: XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")?.text ?? ""
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")!.double!
        self.physicalTo = element.attribute(by: "PhysicalTo")!.double!
        
        // needs the parent's
        self.subPhysicalUnit = resolveNode(path: element.attribute(by: "SubPhysicalUnit")!.text,
                                           base: parent,
                                           tree: tree)!
        
        self.dmxProfile = resolveNode(
            path: element.attribute(by: "DMXProfile")!.text,
            base: tree["DMXProfiles"],
            tree: tree)
        
        self.wheelSlotIndex = element.attribute(by: "PhysicalTo")?.int
    }
}

extension Relation: XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        self.master = resolveNode(path: element.attribute(by: "Master")!.text,
                                  base: parent,
                                  tree: tree)!
        
        self.follower = resolveNode(path: element.attribute(by: "Follower")!.text,
                                  base: parent,
                                  tree: tree)!
        
        self.type = element.attribute(by: "Type")!.toEnum()!
    }
}

extension Macro: XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) {
        let element = xml.element!
        
        self.name = element.attribute(by: "Name")!.text
        
        if let channelFunction = element.attribute(by: "ChannelFunction")?.text {
            print("looking channel")
            self.channelFunction = resolveNode(path: channelFunction,
                                               base: parent,
                                               tree: tree)
            print("found channel")
        }
        
        self.steps = xml["MacroDMX"].parseChildrenToArray(parent: parent, tree: tree)
    }
}

extension MacroStep: XMLDecodableWithParent {
    init(xml: SWXMLHash.XMLIndexer, parent: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) {
        let element = xml.element!
        
        self.duration = element.attribute(by: "Duration")!.double ?? 1
        self.values = xml.parseChildrenToArray(parent: parent, tree: tree)
    }
}

extension MacroValue: XMLDecodableWithParent {
    init(xml: SWXMLHash.XMLIndexer, parent: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) {
        let element = xml.element!
                
        // do our own lookup of the channel since it does not follow normal Node Name schema
        var foundChannel: DMXChannel? = nil
        
        for child in parent["DMXChannels"].children {
            let parts = child.element?.attribute(by: "InitialFunction")?.text.components(separatedBy: ".")
            
            if parts?[0] == element.attribute(by: "DMXChannel")!.text {
                foundChannel = child.parse(tree: tree)
            }
        }
     
        self.dmxChannel = foundChannel ?? parent["DMXChannels"].children.first!.parse(tree: tree)
        self.value = DMXValue(from: element.attribute(by: "Value")!.text)
    }
}
