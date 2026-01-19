//
//  Geometries+XML.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 12/6/25.
//

import SWXMLHash

extension Geometry: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Geometry.Kind(rawValue: element.name) else {
            throw XMLParsingError.unexpectedGeometryType(element.name)
        }
        self = try kind.parse(xml: xml, tree: tree)
    }
}

extension Geometry.Kind {
    func parse(xml: XMLIndexer, tree: XMLIndexer) throws -> Geometry {
        switch self {
        case .general: .general(try .init(xml: xml, tree: tree))
        case .axis: .axis(try .init(xml: xml, tree: tree))
        case .filterBeam: .filterBeam(try .init(xml: xml, tree: tree))
        case .filterColor: .filterColor(try .init(xml: xml, tree: tree))
        case .filterGobo: .filterGobo(try .init(xml: xml, tree: tree))
        case .filterShaper: .filterShaper(try .init(xml: xml, tree: tree))
        case .beam: .beam(try .init(xml: xml, tree: tree))
        case .mediaServerLayer: .mediaServerLayer(try .init(xml: xml, tree: tree))
        case .mediaServerCamera: .mediaServerCamera(try .init(xml: xml, tree: tree))
        case .mediaServerMaster: .mediaServerMaster(try .init(xml: xml, tree: tree))
        case .display: .display(try .init(xml: xml, tree: tree))
        case .reference: .reference(try .init(xml: xml, tree: tree))
        case .laser: .laser(try .init(xml: xml, tree: tree))
        case .wiringObject: .wiringObject(try .init(xml: xml, tree: tree))
        case .inventory: .inventory(try .init(xml: xml, tree: tree))
        case .structure: .structure(try .init(xml: xml, tree: tree))
        case .support: .support(try .init(xml: xml, tree: tree))
        case .magnet: .magnet(try .init(xml: xml, tree: tree))
        }
    }
}

extension GeneralGeometry: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Axis: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension FilterBeam: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension FilterColor: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension FilterGobo: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension FilterShaper: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Beam: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.lampType = try element.attribute(named: "LampType").toEnum()
        self.powerConsumption = element.attribute(by: "PowerConsumption")?.double ?? 1000
        self.luminousFlux = element.attribute(by: "LuminousFlux")?.double ?? 10000
        self.colorTemperature = element.attribute(by: "ColorTemperature")?.double ?? 6000
        self.beamAngle = element.attribute(by: "BeamAngle")?.double ?? 25.0
        self.fieldAngle = element.attribute(by: "FieldAngle")?.double ?? 25.0
        self.throwRatio = element.attribute(by: "ThrowRatio")?.double ?? 1
        self.rectangleRatio = element.attribute(by: "RectangleRatio")?.double ?? 1.7777
        self.beamRadius = element.attribute(by: "BeamRadius")?.double ?? 0.05
        self.beamType = try element.attribute(named: "BeamType").toEnum()
        self.colorRenderingIndex = element.attribute(by: "ColorRenderingIndex")?.int ?? 100
        self.emitterSpectrum = element.attribute(by: "EmitterSpectrum")?.text
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension MediaServerLayer: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension MediaServerCamera: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension MediaServerMaster: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Display: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.texture = FileResource(filename: element.attribute(by: "Texture")?.text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension GeometryReference: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.geometry = element.attribute(by: "Geometry")?.text
        self.dmxBreaks = try xml.parseChildrenToArray(tree: tree)
    }
}

extension DMXBreak: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.offset = element.attribute(by: "DMXOffset").map { DMXAddress(from: $0.text) } ?? DMXAddress(universe: 1, address: 1)
        self.break = element.attribute(by: "DMXBreak")?.int ?? 1
    }
}

extension Laser: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.colorType = try element.attribute(named: "ColorType").toEnum()
        self.emitter = element.attribute(by: "Emitter")?.text
        
        self.color = try element.attribute(named: "Color").requiredDouble
        self.outputStrength = try element.attribute(named: "OutputStrength").requiredDouble
        self.beamDiameter = try element.attribute(named: "BeamDiameter").requiredDouble
        self.beamDivergenceMin = try element.attribute(named: "BeamDivergenceMin").requiredDouble
        self.beamDivergenceMax = try element.attribute(named: "BeamDivergenceMax").requiredDouble
        self.scanAnglePan = try element.attribute(named: "ScanAnglePan").requiredDouble
        self.scanAngleTilt = try element.attribute(named: "ScanAngleTilt").requiredDouble
        self.scanSpeed = try element.attribute(named: "ScanSpeed").requiredDouble
        
        var geometries = [Geometry]()
        var protocols = [LaserProtocol]()
    
        let children: [Child] = try xml.parseChildrenToArray(tree: tree)
        for child in children {
            switch child {
            case .geometry(let geometry):
                geometries.append(geometry)
            case .protocol(let `protocol`):
                protocols.append(`protocol`)
            }
        }
        
        self.children = geometries
        self.protocols = protocols
    }
}

extension Laser.LaserProtocol: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
    }
}

extension Laser.Child: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Kind(rawValue: element.name) else {
            throw XMLParsingError.unexpectedGeometryType(element.name)
        }
        switch kind {
        case .geometry(let kind):
            self = .geometry(try kind.parse(xml: xml, tree: tree))
        case .protocol:
            self = .protocol(try .init(xml: xml, tree: tree))
        }
    }
}



extension WiringObject: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.connectorType = try element.attribute(named: "ConnectorType").text
        self.component = try .init(xml: xml, tree: tree)
        self.signalType = try element.attribute(named: "SignalType").text
        self.pinCount = try element.attribute(named: "PinCount").requiredInt
        self.signalLayer = try element.attribute(named: "SignalLayer").requiredInt
        self.orientation = try element.attribute(named: "Orientation").toEnum()
        self.wireGroup = try element.attribute(named: "WireGroup").text
        
        
        var geometries = [Geometry]()
        var pinPatches = [PinPatch]()
    
        let children: [Child] = try xml.parseChildrenToArray(tree: tree)
        for child in children {
            switch child {
            case .geometry(let geometry):
                geometries.append(geometry)
            case .pinPatch(let pinPatch):
                pinPatches.append(pinPatch)
            }
        }
        self.pinPatches = pinPatches
        self.children = geometries
    }
}

extension WiringObject.PinPatch: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.toWiringObject = try element.attribute(named: "ToWiringObject").text
        self.fromPin = try element.attribute(named: "FromPin").requiredInt
        self.toPin = try element.attribute(named: "ToPin").requiredInt
    }
}


extension WiringObject.Child: XMLDecodable {
    init(xml: SWXMLHash.XMLIndexer, tree: SWXMLHash.XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Kind(rawValue: element.name) else {
            throw XMLParsingError.unexpectedGeometryType(element.name)
        }
        switch kind {
        case .geometry(let kind):
            self = .geometry(try kind.parse(xml: xml, tree: tree))
        case .pinPatch:
            self = .pinPatch(try .init(xml: xml, tree: tree))
        }
    }
}

extension WiringObject.Component: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Kind(rawValue: try element.attribute(named: "ComponentType").text) else {
            throw XMLParsingError.unexpectedGeometryType(element.name)
        }
        switch kind {
        case .input:
            self = .input
        case .output:
            self = .output
        case .powerSource:
            self = .powerSource(try .init(xml: xml, tree: tree))
        case .consumer:
            self = .consumer(try .init(xml: xml, tree: tree))
        case .fuse:
            self = .fuse(try .init(xml: xml, tree: tree))
        case .networkProvider:
            self = .networkProvider
        case .networkInput:
            self = .networkInput
        case .networkOutput:
            self = .networkOutput
        case .networkInOut:
            self = .networkInOut
        }
    }
}


extension WiringObject.Consumer: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.electricalPayLoad = try element.attribute(named: "ElectricalPayLoad").requiredDouble
        self.voltageRangeMax = try element.attribute(named: "VoltageRangeMax").requiredDouble
        self.voltageRangeMin = try element.attribute(named: "VoltageRangeMin").requiredDouble
        self.frequencyRangeMax = try element.attribute(named: "FrequencyRangeMax").requiredDouble
        self.frequencyRangeMin = try element.attribute(named: "FrequencyRangeMin").requiredDouble
        self.cosPhi = try element.attribute(named: "CosPhi").requiredDouble
    }
}

extension WiringObject.PowerSource: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.maxPayLoad = try element.attribute(named: "MaxPayLoad").requiredDouble
        self.voltage = try element.attribute(named: "Voltage").requiredDouble
    }
}

extension WiringObject.Fuse: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.fuseCurrent = try element.attribute(named: "FuseCurrent").requiredDouble
        self.fuseRating = try element.attribute(named: "FuseRating").toEnum()
    }
}


extension Inventory: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.count = try element.attribute(named: "Count").requiredInt
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Structure: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.linkedGeometry = try element.attribute(named: "LinkedGeometry").text
        self.structureType = try element.attribute(named: "StructureType").toEnum()
        self.crossSectionType = try .init(xml: xml, tree: tree)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Structure.CrossSectionType: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Kind(rawValue: try element.attribute(named: "CrossSectionType").text) else {
            throw XMLParsingError.unexpectedGeometryType(element.name)
        }
        switch kind {
        case .trussFramework:
            self = .trussFramework(try .init(xml: xml, tree: tree))
        case .tube:
            self = .tube(try .init(xml: xml, tree: tree))
        }
    }
}

extension Structure.TrussFramework: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.trussCrossSection = try element.attribute(named: "TrussCrossSection").text
    }
}

extension Structure.Tube: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.crossSectionHeight = try element.attribute(named: "CrossSectionHeight").requiredDouble
        self.crossSectionWallThickness = try element.attribute(named: "CrossSectionWallThickness").requiredDouble
    }
}

extension Support: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.supportType = try .init(xml: xml, tree: tree)
        self.capacityX = try element.attribute(named: "CapacityX").requiredDouble
        self.capacityY = try element.attribute(named: "CapacityY").requiredDouble
        self.capacityZ = try element.attribute(named: "CapacityZ").requiredDouble
        self.capacityXX = try element.attribute(named: "CapacityXX").requiredDouble
        self.capacityYY = try element.attribute(named: "CapacityYY").requiredDouble
        self.capacityZZ = try element.attribute(named: "CapacityZZ").requiredDouble
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}

extension Support.SupportType: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        guard let kind = Kind(rawValue: try element.attribute(named: "SupportType").text) else {
            throw XMLParsingError.unexpectedGeometryType(element.name)
        }
        switch kind {
        case .rope:
            self = .rope(try .init(xml: xml, tree: tree))
        case .groundSupport:
            self = .groundSupport(try .init(xml: xml, tree: tree))
        }
    }
}

extension Support.Rope: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.ropeCrossSection = try element.attribute(named: "RopeCrossSection").text
        self.ropeOffset = try .init(from: element.attribute(named: "RopeOffset").text)
    }
}

extension Support.GroundSupport: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.resistanceX = try element.attribute(named: "ResistanceX").requiredDouble
        self.resistanceY = try element.attribute(named: "ResistanceY").requiredDouble
        self.resistanceZ = try element.attribute(named: "ResistanceZ").requiredDouble
        self.resistanceXX = try element.attribute(named: "ResistanceXX").requiredDouble
        self.resistanceYY = try element.attribute(named: "ResistanceYY").requiredDouble
        self.resistanceZZ = try element.attribute(named: "ResistanceZZ").requiredDouble
    }
}

extension Magnet: XMLDecodable {
    init(xml: XMLIndexer, tree: XMLIndexer) throws {
        guard let element = xml.element else { throw XMLParsingError.elementMissing }
        self.name = try element.attribute(named: "Name").text
        self.model = element.attribute(by: "Model")?.text
        self.position = try Matrix(from: try element.attribute(named: "Position").text)
        self.children = try xml.parseChildrenToArray(tree: tree)
    }
}
