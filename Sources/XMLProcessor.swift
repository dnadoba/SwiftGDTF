//
//  XMLProcessor.swift
//
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash
import OrderedCollections

protocol XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws
}

protocol XMLDecodableWithIndex {
    init(xml: XMLIndexer, index: Int, tree: XMLIndexer) throws
}

protocol XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) throws
}


extension GDTF {
    init(xml: XMLIndexer) throws {
        
        self.dataVersion = xml["GDTF"].element!.attribute(by: "DataVersion")!.text
        self.fixtureType = try xml["GDTF"]["FixtureType"].parse(tree: xml["GDTF"]["FixtureType"])        
    }
}

extension FixtureType: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.shortName = try element.attribute(named: "ShortName").text
        self.longName = try element.attribute(named: "LongName").text
        self.manufacturer = try element.attribute(named: "Manufacturer").text
        self.description = try element.attribute(named: "Description").text
        self.fixtureTypeID = try element.attribute(named: "FixtureTypeID").uuid
        self.refFT = element.attribute(by: "RefFT")?.text
        let thumbnailName = element.attribute(by: "Thumbnail")?.text
        self.thumbnail = FileResource(name: thumbnailName, fileExtension: "png")
        self.thumbnailVector = FileResource(name: thumbnailName, fileExtension: "svg")

        self.attributeDefinitions = try xml["AttributeDefinitions"].parse(tree: tree)
        self.physicalDescriptions = try xml["PhysicalDescriptions"].parse(tree: tree)
        self.wheels = try xml["Wheels"].parseChildrenToArray(tree: tree)
        self.models = try xml["Models"].parseChildrenToArray(tree: tree)
        let dmxModeParseDependencies = DMXMode.ParseDependencies(
            wheels: self.wheels,
            attributeDefinitions: self.attributeDefinitions,
            physicialDescriptions: self.physicalDescriptions
        )
        self.dmxModes = try xml["DMXModes"].children.map {
            try DMXMode(xml: $0, tree: tree, dependencies: dmxModeParseDependencies)
        }
        self.geometries = try xml["Geometries"].parseChildrenToArray(tree: tree)
        self.protocols = try (try? xml.byKey("Protocols"))?.children.compactMap { try FixtureProtocol(xml: $0) } ?? []
        self.revisions = try (try? xml.byKey("Revisions"))?.children.map { try Revision(xml: $0) } ?? []
    }
}

extension FixtureInfo: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }

        self.name = try element.attribute(named: "Name").text
        self.shortName = try element.attribute(named: "ShortName").text
        self.longName = try element.attribute(named: "LongName").text
        self.manufacturer = try element.attribute(named: "Manufacturer").text
        self.description = try element.attribute(named: "Description").text
        self.fixtureTypeID = try element.attribute(named: "FixtureTypeID").text
        self.refFT = element.attribute(by: "RefFT")?.text
        let thumbnailName = element.attribute(by: "Thumbnail")?.text
        self.thumbnail = FileResource(name: thumbnailName, fileExtension: "png")
        self.thumbnailVector = FileResource(name: thumbnailName, fileExtension: "svg")
    }
}

///
/// AttributeDefinitions Schema
///

extension AttributeDefinitions: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        self.activationGroups = try xml["ActivationGroups"].parseChildrenToArray(tree: tree)
        self.featureGroups = try xml["FeatureGroups"].parseChildrenToArray(tree: tree)
        self.attributes = try xml["Attributes"].parseChildrenToArray(tree: tree)
    }
}

extension ActivationGroup: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }

        self.name = try element.attribute(named: "Name").text
    }
}

extension FeatureGroup: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }

        self.name = try element.attribute(named: "Name").text
        self.pretty = try element.attribute(named: "Pretty").text
        self.features = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Feature: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }

        self.name = try element.attribute(named: "Name").text
    }
}

extension FixtureAttribute: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.pretty = try element.attribute(named: "Pretty").text
        
        // Resolve ActivationGroup Node
        self.activationGroup = try element.attribute(by: "ActivationGroup")?.resolveNode(
            base: tree["AttributeDefinitions"]["ActivationGroups"],
            tree: tree)

        // Resolve Feature Node
        self.feature = try element.attribute(by: "Feature")?.resolveNode(
            base: tree["AttributeDefinitions"]["FeatureGroups"],
            tree: tree)
        
        // This is technically a node but results in a recursive type
        self.mainAttribute = element.attribute(by: "MainAttribute")?.text
                
        self.physicalUnit = (try? element.attribute(by: "PhysicalUnit")?.toEnum()) ?? .none
        
        if let colorString = element.attribute(by: "Color")?.text {
            self.color = ColorCIE(from: colorString)
        }
        let subPhysicalUnits: [SubPhysicalUnit] = try xml.parseChildrenToArray(tree: tree)
        self.subPhysicalUnits = try OrderedDictionary(
            subPhysicalUnits.lazy.map { ($0.type, $0) },
            uniquingKeysWith: { old, new in throw XMLParsingError.duplicateSubPhysicalUnit(first: old, second: new) }
        )
        
        self.type = AttributeType(fromString: self.name)
    }
}

extension SubPhysicalUnit: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.double ?? 0
        self.physicalTo = element.attribute(by: "PhysicalTo")?.double ?? 1
        
        self.physicalUnit = (try? element.attribute(by: "PhysicalUnit")?.toEnum()) ?? .none
        
        self.type = try element.attribute(named: "Type").toEnum()
    }
}

///
/// Wheels Schema
///

extension Wheel: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.slots = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Slot: XMLDecodableWithIndex {
    init(xml: XMLIndexer, index: Int, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.color = try ColorCIE(from: element.attribute(named: "Color").text)
        
        self.filter = try element.attribute(by: "Filter")?.resolveNode(base: tree["PhysicalDescriptions"]["Filters"], tree: tree)
        if let name = element.attribute(by: "MediaFileName")?.text {
            self.mediaFileName = FileResource(name: "wheels/\(name)", fileExtension: "png")
        } else {
            self.mediaFileName = nil
        }
        self.facets = try xml.filterChildren({ child, _ in child.name == "Facet"}).parseChildrenToArray(tree: tree)
        self.animationSystem = try xml["AnimationSystem"].optionalParse(tree: tree)

        self.slotIndex = index
    }
}

extension PrismFacet: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.color = try ColorCIE(from: element.attribute(named: "Color").text)
        self.rotation = try Rotation(from: element.attribute(named: "Rotation").text)
    }
}

extension AnimationSystem: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        func parsePoint(named: String) throws -> SIMD2<Double> {
            let points = try element.attribute(named: "P1").text.split(separator: ",").map { Double($0) ?? 0 }
            guard points.count == 2 else { throw XMLParsingError.unexpectedCountOfNumbersForPoint(count: points.count) }
            return .init(points[0], points[1])
        }
        self.p1 = try parsePoint(named: "P1")
        self.p2 = try parsePoint(named: "P2")
        self.p3 = try parsePoint(named: "P3")
        
        self.radius = try Double(element.attribute(named: "Radius").text) ?? 0
    }
}

///
/// Physical Description Schema
///

extension PhysicalDescriptions: XMLDecodable {
    // this object can not exist in which case we will be null
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        self.emitters = try xml["Emitters"].parseChildrenToArray(tree: tree)
        self.filters = try xml["Filters"].parseChildrenToArray(tree: tree)
        

        self.colorSpace = try xml["ColorSpace"].optionalParse(tree: tree)
        
        self.additionalColorSpaces = try xml["AdditionalColorSpaces"].parseChildrenToArray(tree: tree)
        self.dmxProfiles = try xml["DMXProfiles"].parseChildrenToArray(tree: tree)
        
        self.properties =  try xml["Properties"].parse(tree: tree)
    }
}

extension Emitter: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        
        self.color = try ColorCIE(from: element.attribute(named: "Color").text)
        self.dominantWavelength = try element.attribute(named: "DominantWaveLength").double

        
        self.diodePart = element.attribute(by: "DiodePart")?.text
  
        self.measurements = try xml.parseChildrenToArray(tree: tree)
    }
}

extension GDTFMeasurement: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.physical = try Double(element.attribute(named: "Physical").text) ?? 0
        
        self.luminousIntensity = element.attribute(by: "LuminousIntensity")?.double
        
        self.transmission = element.attribute(by: "Transmission")?.double
                
        self.interpolationTo = (try? element.attribute(by: "InterpolationTo")?.toEnum()) ?? .linear
        
        self.measurements = try xml.parseChildrenToArray(tree: tree)
    }
}

extension MeasurementPoint: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.energy = try element.attribute(named: "Energy").double ?? 0
        self.wavelength = try element.attribute(named: "WaveLength").double ?? 0
    }
}

extension Filter: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.color = try ColorCIE(from: element.attribute(named: "Color").text)
        
        self.measurements = try xml.parseChildrenToArray(tree: tree)
    }
}

extension ColorSpace: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = element.attribute(by: "Name")?.text ?? "Default"
        self.mode = try element.attribute(named: "Mode").toEnum()
    }
}

extension DMXProfile: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.points = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Point: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.dmxPercentage = try Double(element.attribute(named: "DMXPercentage").text) ?? 0
        
        self.cfc0 = try element.attribute(named: "CFC0").double ?? 0
        self.cfc1 = try element.attribute(named: "CFC1").double ?? 0
        self.cfc2 = try element.attribute(named: "CFC2").double ?? 0
        self.cfc3 = try element.attribute(named: "CFC3").double ?? 0
    }
}

extension Properties: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        self.legHeight = try xml["LegHeight"].element?.attribute(named: "Value").double ?? 0
        self.weight = try xml["Weight"].element?.attribute(named: "Value").double ?? 0
        
        if xml["OperatingTemperature"].element != nil {
            self.operatingTemp = try xml["OperatingTemperature"].parse(tree: tree)
        } else {
            self.operatingTemp = OperatingTemp(low: 0, high: 40)
        }
    }
}

extension OperatingTemp: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.low = element.attribute(by: "Low")?.double ?? 0
        self.high = element.attribute(by: "High")?.double ?? 40
    }
}

///
/// DMX Mode Schema
///

extension DMXMode {
    struct ParseDependencies {
        struct FeatureKey: Hashable {
            var group: String
            var name: String
        }
        var wheels: [String: Wheel]
        var attributes: [String: FixtureAttribute]
        var activationGroups: [String: ActivationGroup]
        var features: [FeatureKey: Feature]
        var emitters: [String: Emitter]
        var filters: [String: Filter]
        var colorSpaces: [String: ColorSpace]
        var dmxProfiles: [String: DMXProfile]
        init(
            wheels: [Wheel],
            attributeDefinitions: AttributeDefinitions?,
            physicialDescriptions: PhysicalDescriptions?
        ) {
            self.init(
                wheels: wheels,
                attributes: attributeDefinitions?.attributes ?? [],
                activationGroups: attributeDefinitions?.activationGroups ?? [],
                features: attributeDefinitions?.featureGroups.lazy.flatMap { group in
                    group.features.map { feature in
                        (FeatureKey(group: group.name, name: feature.name), feature)
                    }
                } ?? [],
                emitters: physicialDescriptions?.emitters ?? [],
                filters: physicialDescriptions?.filters ?? [],
                colorSpaces: physicialDescriptions?.additionalColorSpaces ?? [],
                dmxProfiles: physicialDescriptions?.dmxProfiles ?? []
            )
        }
        
        init(
            wheels: [Wheel],
            attributes: [FixtureAttribute],
            activationGroups: [ActivationGroup],
            features: [(FeatureKey, Feature)],
            emitters: [Emitter],
            filters: [Filter],
            colorSpaces: [ColorSpace],
            dmxProfiles: [DMXProfile],
        ) {
            self.wheels = Dictionary(wheels.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
            self.attributes = Dictionary(attributes.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
            self.activationGroups = Dictionary(activationGroups.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
            self.features = Dictionary(features, uniquingKeysWith: { old, new in old })
            self.emitters = Dictionary(emitters.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
            self.filters = Dictionary(filters.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
            self.colorSpaces = Dictionary(colorSpaces.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
            self.dmxProfiles = Dictionary(dmxProfiles.lazy.map { ($0.name, $0) }, uniquingKeysWith: { old, new in old })
        }
        
        func getRequiredWheel(name: String) throws -> Wheel {
            guard let wheel = wheels[name] else {
                throw XMLParsingError.missingWheel(name)
            }
            return wheel
        }
        
        func getRequiredEmitter(name: String) throws -> Emitter {
            guard let emitter = emitters[name] else {
                throw XMLParsingError.missingEmitter(name)
            }
            return emitter
        }
        func getRequiredFilter(name: String) throws -> Filter {
            guard let filter = filters[name] else {
                throw XMLParsingError.missingFilter(name)
            }
            return filter
        }
        func getRequiredColorSpace(name: String) throws -> ColorSpace {
            guard let colorSpace = colorSpaces[name] else {
                throw XMLParsingError.missingColorSpace(name)
            }
            return colorSpace
        }
        func getRequiredDMXProfile(name: String) throws -> DMXProfile {
            guard let dmxProfile = dmxProfiles[name] else {
                throw XMLParsingError.missingDMXProfile(name)
            }
            return dmxProfile
        }
        func getRequiredAttribute(name: String) throws -> FixtureAttribute {
            guard let attribute = attributes[name] else {
                throw XMLParsingError.missingAttribute(name)
            }
            return attribute
        }
        func getRequiredSubPhysicalUnit(attributeName: String, subPhysicalTypeName: String) throws -> SubPhysicalUnit {
            guard let attribute = attributes[attributeName] else {
                throw XMLParsingError.missingAttribute(attributeName)
            }
            
            guard let unit = SubPhysicalType(rawValue: subPhysicalTypeName) else {
                throw XMLParsingError.unexpectSubPhysicalUnitType(subPhysicalTypeName)
            }
            guard let subPhysicalUnit = attribute.subPhysicalUnits[unit] else {
                throw XMLParsingError.missingSubPhysicalUnitType(unit, in: attribute)
            }
            return subPhysicalUnit
        }
        func getFeature(group: String, name: String) -> Feature? {
            features[.init(group: group, name: name)]
        }
    }
    init(xml: XMLIndexer, tree: XMLIndexer, dependencies: ParseDependencies) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        self.description = element.attribute(by: "Description")?.text ?? ""
        self.geometry = element.attribute(by: "Geometry")?.text
                
        self.channels = try xml["DMXChannels"].children.map {
            try DMXChannel(xml: $0, dependencies: dependencies)
        }
        self.relations = try xml["Relations"].parseChildrenToArray(parent: xml, tree: tree)
        self.macros = try xml["FTMacros"].parseChildrenToArray(parent: xml, tree: tree)
    }
}

extension DMXChannel {
    init(xml: XMLIndexer, dependencies: DMXMode.ParseDependencies) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }

        self.offset = []
        
        self.dmxBreak = element.attribute(by: "DMXBreak").flatMap { DMXChannel.Break(rawValue: $0.text) } ?? .id(1)
            

        if let offset = element.attribute(by: "Offset"), offset.text != "None" {
            self.offset = offset.text.split(separator: ",").map { Int($0) ?? 0 }
        }

        
        self.logicalChannels = try xml.children.map {
            try LogicalChannel(xml: $0, dependencies: dependencies)
        }
        
        // Initial Function
        //
        // technically we do have a link but it does not follow convention of Node
        // the default is first logical channel function
        // the name of the channel is actually the first element in the Initial Function attribute
        if element.attribute(by: "InitialFunction") != nil {
            let path = try element.attribute(named: "InitialFunction").text
            let initialFunctionParts = path.components(separatedBy: ".")
            
            guard initialFunctionParts.count == 3 else { throw XMLParsingError.initialFunctionPathInvalid(path) }
            
            self.name = initialFunctionParts[0]
            let logicialAttribute = AttributeType(fromString: initialFunctionParts[1])
            let channelName =  initialFunctionParts[2]
            
            let foundInitial = logicalChannels.first { logicalChannel in
                logicalChannel.attribute.type == logicialAttribute
            }?.channelFunctions.first { chanel in
                chanel.name == channelName
            }

            self.initialFunction = foundInitial ?? self.logicalChannels.first?.channelFunctions.first
            
        } else {
            // "Default value is the first channel function of the first logical function of this DMX channel."
                        
            self.initialFunction = logicalChannels.first?.channelFunctions.first
        }
        
        
        if let highlight = element.attribute(by: "Highlight")?.text, highlight != "None" {
            self.highlight = DMXValue(from: highlight)
        }
        
        self.geometry = try element.attribute(named: "Geometry").text
    }
}

extension LogicalChannel {
    init(xml: XMLIndexer, dependencies: DMXMode.ParseDependencies) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }

        self.attribute = try dependencies.getRequiredAttribute(name: try element.attribute(named: "Attribute").text)
        
        self.snap = (try? element.attribute(by: "Snap")?.toEnum()) ?? .no
        self.master = (try? element.attribute(by: "Master")?.toEnum()) ?? .none
        
        self.mibFade = element.attribute(by: "MIBFade")?.double ?? 0
        self.dmxChangeTimeLimit = element.attribute(by: "DMXChangeTimeLimit")?.double ?? 0
        
        self.channelFunctions = try xml.children.enumerated().map { (offset, child) in
            try ChannelFunction(xml: child, index: offset, dependencies: dependencies)
        }
    }
}

extension ChannelFunction {
    init(xml: XMLIndexer, index: Int, dependencies: DMXMode.ParseDependencies) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        let attributeName = element.attribute(by: "Attribute")?.text
        self.name = element.attribute(by: "Name")?.text ?? attributeName.map { $0 + " " + String(index+1) } ?? String(index+1)
        
        if let attributeName, attributeName != "NoFeature" {
            self.attribute = try dependencies.getRequiredAttribute(name: attributeName)
        }
        
        self.originalAttribute = element.attribute(by: "OriginalAttribute")?.text ?? ""
        self.dmxFrom = DMXValue(from: element.attribute(by: "DMXFrom")?.text ?? "0/1")
        self.dmxDefault = DMXValue(from: element.attribute(by: "Default")?.text ?? "0/1")
        
        self.physicalFrom = element.attribute(by: "PhysicalFrom")?.double ?? 0
        self.physicalTo = element.attribute(by: "PhysicalTo")?.double ?? 1
        self.realFade = element.attribute(by: "RealFade")?.double ?? 0
        self.realAcceleration = element.attribute(by: "RealAcceleration")?.double ?? 0
        
        // handle node resolution for each type of function
        

        self.wheel = try element.attribute(by: "Wheel").map { try dependencies.getRequiredWheel(name: $0.text) }
        self.emitter = try element.attribute(by: "Emitter").map { try dependencies.getRequiredEmitter(name: $0.text) }
        self.filter = try element.attribute(by: "Filter").map { try dependencies.getRequiredFilter(name: $0.text) }
        self.colorSpace = try element.attribute(by: "ColorSpace").map { try dependencies.getRequiredColorSpace(name: $0.text) }
        
        // Mode Master
        self.modeMaster = element.attribute(by: "ModeMaster")?.text
        // modeFrom/modeTo are only used when modeMaster is prsent
        if self.modeMaster != nil {
            self.modeFrom = DMXValue(from: element.attribute(by: "ModeFrom")?.text ?? "0/1")
            self.modeTo = DMXValue(from: element.attribute(by: "ModeTo")?.text ?? "0/1")
        }
        
        // DMX Profile
        self.dmxProfile = try? element.attribute(by: "DMXProfile").map { try dependencies.getRequiredDMXProfile(name: $0.text) }
        
        self.minimum = element.attribute(by: "Min")?.double ?? self.physicalFrom
        self.maximum = element.attribute(by: "Max")?.double ?? self.physicalTo
        self.customName = element.attribute(by: "CustomName")?.text
        
        channelSets = []
        subChannelSets = []
        for child in xml.children {
            switch child.element?.name {
            case "ChannelSet":
                channelSets.append(try ChannelSet(xml: child, parentPhysicalFrom: physicalFrom, parentPhysicalTo: physicalTo))
            case "SubChannelSet":
                subChannelSets.append(try SubChannelSet(xml: child, attribute: attribute, dependencies: dependencies))
            default:
                throw XMLParsingError.unexpectedChannelChild(name)
            }
        }
    }
}


extension ChannelSet {
    init(xml: XMLIndexer, parentPhysicalFrom: Double?, parentPhysicalTo: Double?) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = element.attribute(by: "Name")?.text ?? ""
        self.dmxFrom = DMXValue(from: element.attribute(by: "DMXFrom")?.text ?? "0/1")
        let physicalFrom = element.attribute(by: "PhysicalFrom")?.double
        self.physicalFrom = physicalFrom ?? parentPhysicalFrom ?? 0
        let physicalTo = element.attribute(by: "PhysicalTo")?.double
        self.physicalTo = physicalTo ?? parentPhysicalTo ?? 1
        self.hasInhertiedPhysicalValues = physicalFrom == nil || physicalTo == nil
        self._wheelSlotIndex = element.attribute(by: "WheelSlotIndex")?.int
    }
}

extension SubChannelSet {
    init(xml: XMLIndexer, attribute: FixtureAttribute?, dependencies: DMXMode.ParseDependencies) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = element.attribute(by: "Name")?.text ?? ""
        
        self.physicalFrom = (try? element.attribute(named: "PhysicalFrom"))?.double ?? 0
        self.physicalTo = (try? element.attribute(named: "PhysicalTo"))?.double ?? 1
        

        let subPhysicalUnitName = try element.attribute(named: "SubPhysicalUnit").text
        guard let unit = SubPhysicalType(rawValue: subPhysicalUnitName) else {
            throw XMLParsingError.unexpectSubPhysicalUnitType(subPhysicalUnitName)
        }
        guard let attribute else {
            throw XMLParsingError.fixtureAttributeReuqireForSubChannelSet
        }
        guard let subPhysicalUnit = attribute.subPhysicalUnits[unit] else {
            throw XMLParsingError.missingSubPhysicalUnitType(unit, in: attribute)
        }
        
        self.subPhysicalUnit = subPhysicalUnit
        
        self.dmxProfile = try element.attribute(by: "DMXProfile").map { try dependencies.getRequiredDMXProfile(name: $0.text) }
    }
}

extension Relation: XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        
        self.master = try element.attribute(named: "Master").text
        
        self.follower = try element.attribute(named: "Follower").text
        
        self.type = try element.attribute(named: "Type").toEnum()
    }
}

extension Macro: XMLDecodableWithParent {
    init(xml: XMLIndexer, parent: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.name = try element.attribute(named: "Name").text
        
        if element.attribute(by: "ChannelFunction") != nil {
            self.channelFunction = try element.attribute(named: "ChannelFunction").text
        }
        
        self.steps = try xml["MacroDMX"].parseChildrenToArray(parent: parent, tree: tree)
    }
}

extension MacroStep: XMLDecodableWithParent {
    init(xml: SWXMLHash.XMLIndexer, parent: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        
        self.duration = (try? element.attribute(named: "Duration"))?.double ?? 1
        self.values = try xml.parseChildrenToArray(parent: parent, tree: tree)
    }
}

extension MacroValue: XMLDecodableWithParent {
    init(xml: SWXMLHash.XMLIndexer, parent: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.dmxChannel = try element.attribute(named: "DMXChannel").text
        self.value = try DMXValue(from: element.attribute(named: "Value").text)
    }
}

extension Revision {
    private static let dateParseStrategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits)",
        locale: Locale(identifier: "en_US_POSIX"), timeZone: .gmt
    )
    init(xml: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.text = try element.attribute(named: "Text").text
        let dateString = try element.attribute(named: "Date").text
        self.date = try Date(dateString, strategy: Self.dateParseStrategy)
        self.userID = try element.attribute(named: "UserID").requiredInt
        self.modifiedBy = element.attribute(by: "ModifiedBy")?.text ?? ""
    }
}

extension FixtureProtocol {
    init?(xml: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Kind(rawValue: element.name) else {
            throw XMLParsingError.unexpectedProtocolType(element.name)
        }
        // RDM is the only protocol we care at the moment
        guard kind == .rdm else {
            print("Unsupported Protocol Kind", kind)
            return nil
        }
        self = .rdm(try .init(xml: xml))
    }
}

extension RDM {
    init(xml: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.manufacturerID = try element.attribute(named: "ManufacturerID").requiredHexInt()
        self.deviceModelID = try element.attribute(named: "DeviceModelID").requiredHexInt()
        self.softwareVersions = try xml.children.map { try RDM.SofwareVersion(xml: $0) }
    }
}

extension RDM.SofwareVersion {
    init(xml: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.id = try element.attribute(named: "Value").requiredHexInt()
        self.personalties = try xml.children.map { try RDM.DMXPersonality(xml: $0) }
    }
}

extension RDM.DMXPersonality {
    init(xml: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.id = try element.attribute(named: "Value").requiredHexInt()
        self.dmxMode = try element.attribute(named: "DMXMode").text
    }
}

extension GDTFModel: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.length = element.attribute(by: "Length")?.double ?? 0
        self.width = element.attribute(by: "Width")?.double ?? 0
        self.height = element.attribute(by: "Height")?.double ?? 0
        self.primitiveType = element.attribute(by: "PrimitiveType").flatMap { PrimitiveType(rawValue: $0.text) } ?? .undefined
        self.file = element.attribute(by: "File")?.text
        self.svgOffsetX = element.attribute(by: "SVGOffsetX")?.double ?? 0
        self.svgOffsetY = element.attribute(by: "SVGOffsetY")?.double ?? 0
        self.svgSideOffsetX = element.attribute(by: "SVGSideOffsetX")?.double ?? 0
        self.svgSideOffsetY = element.attribute(by: "SVGSideOffsetY")?.double ?? 0
        self.svgFrontOffsetX = element.attribute(by: "SVGFrontOffsetX")?.double ?? 0
        self.svgFrontOffsetY = element.attribute(by: "SVGFrontOffsetY")?.double ?? 0
    }
}


