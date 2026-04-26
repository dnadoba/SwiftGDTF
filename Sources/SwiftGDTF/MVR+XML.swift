//
//  MVR+XML.swift
//  SwiftGDTF
//
//  XML parsing for all MVR model types.
//  Uses .children.map { } — does NOT use parseChildrenToArray or tree parameter.
//

import Foundation
import SWXMLHash

// MARK: - Scalar Parsing Helpers

/// Parses an MVR boolean string. Spec uses "true"/"false" but real-world files
/// use 1/0, on/off, yes/no with mixed casing. Throws on unrecognized values.
func parseMVRBool(_ text: String, field: String) throws -> Bool {
    switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "true", "1", "on", "yes": return true
    case "false", "0", "off", "no": return false
    default: throw MVRParsingError.invalidBool(value: text, field: field)
    }
}

/// Parses an optional bool element. Returns nil if text is absent or empty.
/// Throws if text is non-empty but unparseable.
func parseMVRBoolOptional(_ text: String?, field: String) throws -> Bool? {
    guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        return nil
    }
    return try parseMVRBool(raw, field: field)
}

/// Parses a required integer. Throws on missing/empty/malformed input.
func parseMVRInt(_ text: String?, field: String) throws -> Int {
    guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        throw MVRParsingError.invalidInteger(value: text ?? "", field: field)
    }
    guard let value = Int(raw) else {
        throw MVRParsingError.invalidInteger(value: raw, field: field)
    }
    return value
}

/// Parses an optional integer. Returns nil if text is absent or empty.
/// Throws if text is non-empty but unparseable.
func parseMVRIntOptional(_ text: String?, field: String) throws -> Int? {
    guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        return nil
    }
    guard let value = Int(raw) else {
        throw MVRParsingError.invalidInteger(value: raw, field: field)
    }
    return value
}

/// Parses an optional double. Returns nil if text is absent or empty.
/// Throws if text is non-empty but unparseable.
func parseMVRDoubleOptional(_ text: String?, field: String) throws -> Double? {
    guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        return nil
    }
    guard let value = Double(raw) else {
        throw MVRParsingError.invalidFloat(value: raw, field: field)
    }
    return value
}

/// Parses an optional UUID attribute. Returns nil if attribute absent.
/// Throws if attribute present but malformed.
func parseMVROptionalUUID(_ text: String?, field: String) throws -> UUID? {
    guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        return nil
    }
    guard let uuid = UUID(uuidString: raw) else {
        throw MVRParsingError.invalidUUID(raw)
    }
    return uuid
}

// MARK: - Root Parsing

extension MVRScene {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        guard element.name == "GeneralSceneDescription" else {
            throw MVRError.invalidRootElement(element.name)
        }

        self.verMajor = element.attribute(by: "verMajor")?.int ?? 1
        self.verMinor = element.attribute(by: "verMinor")?.int ?? 0
        self.provider = element.attribute(by: "provider")?.text ?? ""
        self.providerVersion = element.attribute(by: "providerVersion")?.text ?? ""

        // UserData
        var userData: [MVRUserData] = []
        if let userDataNode = xml.children.first(where: { $0.element?.name == "UserData" }) {
            userData = try userDataNode.children.compactMap { child in
                guard child.element?.name == "Data" else { return nil }
                return try MVRUserData(xml: child)
            }
        }
        self.userData = userData

        // Scene (required)
        guard let sceneNode = xml.children.first(where: { $0.element?.name == "Scene" }) else {
            throw MVRParsingError.missingChildElement("Scene")
        }
        self.scene = try MVRSceneNode(xml: sceneNode)
    }
}

extension MVRUserData {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.provider = element.attribute(by: "provider")?.text ?? ""
        self.ver = element.attribute(by: "ver")?.text ?? "1"
        self.content = element.text
    }
}

extension MVRSceneNode {
    init(xml: XMLIndexer) throws {
        // AUXData (optional)
        if let auxNode = xml.children.first(where: { $0.element?.name == "AUXData" }) {
            self.auxData = try MVRAUXData(xml: auxNode)
        } else {
            self.auxData = MVRAUXData(symdefs: [], positions: [], mappingDefinitions: [], classes: [])
        }

        // Layers (required)
        guard let layersNode = xml.children.first(where: { $0.element?.name == "Layers" }) else {
            throw MVRParsingError.missingChildElement("Layers")
        }
        self.layers = try layersNode.children.compactMap { child in
            guard child.element?.name == "Layer" else { return nil }
            return try MVRLayer(xml: child)
        }
    }
}

// MARK: - AUXData Parsing

extension MVRAUXData {
    init(xml: XMLIndexer) throws {
        var symdefs: [MVRSymdef] = []
        var positions: [MVRPosition] = []
        var mappingDefinitions: [MVRMappingDefinition] = []
        var classes: [MVRClass] = []

        for child in xml.children {
            guard let name = child.element?.name else { continue }
            switch name {
            case "Symdef": symdefs.append(try MVRSymdef(xml: child))
            case "Position": positions.append(try MVRPosition(xml: child))
            case "MappingDefinition": mappingDefinitions.append(try MVRMappingDefinition(xml: child))
            case "Class": classes.append(try MVRClass(xml: child))
            default: break
            }
        }

        self.symdefs = symdefs
        self.positions = positions
        self.mappingDefinitions = mappingDefinitions
        self.classes = classes
    }
}

extension MVRSymdef {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""

        // Children are inside a ChildList element containing Geometry3D and Symbol nodes
        if let childListNode = xml.children.first(where: { $0.element?.name == "ChildList" }) {
            self.children = try childListNode.children.compactMap { child in
                guard let elem = child.element,
                      let kind = MVRGeometryNode.Kind(rawValue: elem.name) else { return nil }
                return try kind.parse(xml: child)
            }
        } else {
            // Some files put geometry nodes directly under Symdef without ChildList wrapper
            self.children = try xml.children.compactMap { child in
                guard let elem = child.element,
                      let kind = MVRGeometryNode.Kind(rawValue: elem.name) else { return nil }
                return try kind.parse(xml: child)
            }
        }
    }
}

extension MVRPosition {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
    }
}

extension MVRMappingDefinition {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""

        var sizeX = 0
        var sizeY = 0
        var source: MVRSource?
        var scaleHandling: MVRScaleHandling?

        for child in xml.children {
            guard let name = child.element?.name else { continue }
            switch name {
            case "SizeX": sizeX = try parseMVRInt(child.element?.text, field: "MappingDefinition/SizeX")
            case "SizeY": sizeY = try parseMVRInt(child.element?.text, field: "MappingDefinition/SizeY")
            case "Source": source = try MVRSource(xml: child)
            case "ScaleHandeling": scaleHandling = MVRScaleHandling(rawValue: child.element?.text ?? "")
            default: break
            }
        }

        self.sizeX = sizeX
        self.sizeY = sizeY
        self.source = source
        self.scaleHandling = scaleHandling
    }
}

extension MVRClass {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
    }
}

// MARK: - Layer Parsing

extension MVRLayer {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""

        var matrix: Matrix?
        var childList: [MVRChildObject] = []

        for child in xml.children {
            guard let name = child.element?.name else { continue }
            switch name {
            case "Matrix":
                matrix = try Matrix(fromMVR: child.element?.text ?? "")
            case "ChildList":
                childList = try parseChildList(xml: child)
            default: break
            }
        }

        self.matrix = matrix
        self.childList = childList
    }
}

// MARK: - ChildList Parsing

/// Parses a ChildList element into an array of MVRChildObject.
/// Unknown element names are silently skipped.
func parseChildList(xml: XMLIndexer) throws -> [MVRChildObject] {
    try xml.children.compactMap { child in
        guard let elem = child.element,
              let kind = MVRChildObject.Kind(rawValue: elem.name) else { return nil }
        return try kind.parse(xml: child)
    }
}

extension MVRChildObject.Kind {
    func parse(xml: XMLIndexer) throws -> MVRChildObject {
        switch self {
        case .sceneObject: .sceneObject(try .init(xml: xml))
        case .groupObject: .groupObject(try .init(xml: xml))
        case .focusPoint: .focusPoint(try .init(xml: xml))
        case .fixture: .fixture(try .init(xml: xml))
        case .truss: .truss(try .init(xml: xml))
        case .support: .support(try .init(xml: xml))
        case .videoScreen: .videoScreen(try .init(xml: xml))
        case .projector: .projector(try .init(xml: xml))
        }
    }
}

// MARK: - Geometry Node Parsing

extension MVRGeometryNode.Kind {
    func parse(xml: XMLIndexer) throws -> MVRGeometryNode {
        switch self {
        case .geometry3D: .geometry3D(try .init(xml: xml))
        case .symbol: .symbol(try .init(xml: xml))
        }
    }
}

extension MVRGeometry3D {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.fileName = element.attribute(by: "fileName")?.text ?? element.attribute(by: "FileName")?.text ?? ""
        self.matrix = try xml.children.first(where: { $0.element?.name == "Matrix" }).map {
            try Matrix(fromMVR: $0.element?.text ?? "")
        }
    }
}

extension MVRSymbol {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.symdef = try element.attribute(named: "symdef").uuid
        self.matrix = try xml.children.first(where: { $0.element?.name == "Matrix" }).map {
            try Matrix(fromMVR: $0.element?.text ?? "")
        }
    }
}

// MARK: - Address Entry Parsing

extension MVRAddressEntry.Kind {
    func parse(xml: XMLIndexer) throws -> MVRAddressEntry {
        switch self {
        case .address: .address(try .init(xml: xml))
        case .network: .network(try .init(xml: xml))
        }
    }
}

extension MVRAddress {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.break = element.attribute(by: "break")?.int ?? 0
        let text = element.text
        self.dmxAddress = DMXAddress(from: text)
    }
}

extension MVRNetwork {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        // Attribute names in MVR spec use various casings; try common variants
        self.geometry = element.attribute(by: "geometry")?.text
            ?? element.attribute(by: "Geometry")?.text
            ?? element.attribute(by: "Interface")?.text ?? ""
        self.ipv4 = element.attribute(by: "IPv4")?.text ?? element.attribute(by: "ipv4")?.text
        self.subnetMask = element.attribute(by: "SubnetMask")?.text ?? element.attribute(by: "subnetmask")?.text
        self.ipv6 = element.attribute(by: "IPv6")?.text ?? element.attribute(by: "ipv6")?.text
        let dhcpText = element.attribute(by: "DHCP")?.text ?? element.attribute(by: "dhcp")?.text
        self.dhcp = try parseMVRBoolOptional(dhcpText, field: "Network/DHCP") ?? false
        self.hostname = element.attribute(by: "hostname")?.text ?? element.attribute(by: "Hostname")?.text
    }
}

// MARK: - Sub-Node Parsing

extension MVRAlignment {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.geometry = element.attribute(by: "geometry")?.text ?? ""
        self.up = try Vector3(from: element.attribute(by: "up")?.text ?? "0,0,1")
        self.direction = try Vector3(from: element.attribute(by: "direction")?.text ?? "0,0,-1")
    }
}

extension MVROverwrite {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.universal = element.attribute(by: "universal")?.text ?? ""
        let target = element.attribute(by: "target")?.text
        self.target = target?.isEmpty == true ? nil : target
    }
}

extension MVRConnection {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.own = element.attribute(by: "own")?.text ?? ""
        let uuidText = element.attribute(by: "toObject")?.text ?? ""
        guard let uuid = UUID(uuidString: uuidText) else {
            throw MVRParsingError.invalidUUID(uuidText)
        }
        self.toObject = uuid
        self.other = element.attribute(by: "other")?.text ?? ""
    }
}

extension MVRProtocol {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.geometry = element.attribute(by: "geometry")?.text ?? "NetworkInOut_1"
        self.name = element.attribute(by: "name")?.text ?? ""
        self.type = element.attribute(by: "type")?.text ?? ""
        self.version = element.attribute(by: "version")?.text ?? ""
        self.transmission = element.attribute(by: "transmission").flatMap { MVRTransmission(rawValue: $0.text) }
    }
}

extension MVRMapping {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        let uuidText = element.attribute(by: "linkedDef")?.text ?? ""
        guard let uuid = UUID(uuidString: uuidText) else {
            throw MVRParsingError.invalidUUID(uuidText)
        }
        self.linkedDef = uuid

        var ux: Int?, uy: Int?, ox: Int?, oy: Int?, rz: Double?
        for child in xml.children {
            guard let name = child.element?.name else { continue }
            switch name {
            case "ux": ux = try parseMVRIntOptional(child.element?.text, field: "Mapping/ux")
            case "uy": uy = try parseMVRIntOptional(child.element?.text, field: "Mapping/uy")
            case "ox": ox = try parseMVRIntOptional(child.element?.text, field: "Mapping/ox")
            case "oy": oy = try parseMVRIntOptional(child.element?.text, field: "Mapping/oy")
            case "rz": rz = try parseMVRDoubleOptional(child.element?.text, field: "Mapping/rz")
            default: break
            }
        }
        self.ux = ux; self.uy = uy; self.ox = ox; self.oy = oy; self.rz = rz
    }
}

extension MVRGobo {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.rotation = element.attribute(by: "rotation")?.double ?? 0
        self.fileName = element.text
    }
}

extension MVRSource {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.linkedGeometry = element.attribute(by: "linkedGeometry")?.text ?? ""
        let typeStr = element.attribute(by: "type")?.text ?? "File"
        self.type = MVRSourceType(rawValue: typeStr) ?? .file
        self.value = element.text
    }
}

extension MVRProjection {
    init(xml: XMLIndexer) throws {
        var sources: [MVRSource] = []
        var scaleHandling: MVRScaleHandling?

        for child in xml.children {
            guard let name = child.element?.name else { continue }
            switch name {
            case "Source": sources.append(try MVRSource(xml: child))
            case "ScaleHandeling": scaleHandling = MVRScaleHandling(rawValue: child.element?.text ?? "")
            default: break
            }
        }

        self.sources = sources
        self.scaleHandling = scaleHandling
    }
}

// MARK: - Parametric Object Parsing Helpers

/// Parses the common heterogeneous children of a parametric object.
/// Used by all parametric object types to avoid code duplication.
private struct ParametricObjectChildren {
    var matrix: Matrix?
    var classing: UUID?
    var geometries: [MVRGeometryNode] = []
    var gdtfSpec: String?
    var gdtfMode: String?
    var castShadow: Bool?
    var addresses: [MVRAddressEntry] = []
    var alignments: [MVRAlignment] = []
    var customCommands: [String] = []
    var overwrites: [MVROverwrite] = []
    var connections: [MVRConnection] = []
    var fixtureID: String = ""
    var fixtureIDNumeric: Int = 0
    var unitNumber: Int?
    var customId: Int?
    var customIdType: Int?
    var childList: [MVRChildObject] = []

    // Fixture-specific
    var focus: UUID?
    var dmxInvertPan: Bool?
    var dmxInvertTilt: Bool?
    var position: UUID?
    var function: String?
    var childPosition: String?
    var color: ColorCIE?
    var protocols: [MVRProtocol] = []
    var mappings: [MVRMapping] = []
    var gobo: MVRGobo?

    // VideoScreen-specific
    var sources: [MVRSource] = []

    // Projector-specific
    var projections: [MVRProjection] = []

    // Support-specific
    var chainLength: Double = 0

    init(xml: XMLIndexer) throws {
        for child in xml.children {
            guard let elem = child.element else { continue }
            switch elem.name {
            case "Matrix":
                self.matrix = try Matrix(fromMVR: elem.text)
            case "Classing":
                self.classing = try parseMVROptionalUUID(elem.text, field: "Classing")
            case "Geometries":
                self.geometries = try child.children.compactMap { geoChild in
                    guard let geoElem = geoChild.element,
                          let kind = MVRGeometryNode.Kind(rawValue: geoElem.name) else { return nil }
                    return try kind.parse(xml: geoChild)
                }
            case "GDTFSpec":
                let text = elem.text.trimmingCharacters(in: .whitespacesAndNewlines)
                self.gdtfSpec = text.isEmpty ? nil : text
            case "GDTFMode":
                let text = elem.text.trimmingCharacters(in: .whitespacesAndNewlines)
                self.gdtfMode = text.isEmpty ? nil : text
            case "CastShadow":
                self.castShadow = try parseMVRBoolOptional(elem.text, field: "CastShadow")
            case "Addresses":
                self.addresses = try child.children.compactMap { addrChild in
                    guard let addrElem = addrChild.element,
                          let kind = MVRAddressEntry.Kind(rawValue: addrElem.name) else { return nil }
                    return try kind.parse(xml: addrChild)
                }
            case "Alignments":
                self.alignments = try child.children.compactMap { c in
                    guard c.element?.name == "Alignment" else { return nil }
                    return try MVRAlignment(xml: c)
                }
            case "CustomCommands":
                self.customCommands = child.children.compactMap { c in
                    guard c.element?.name == "CustomCommand" else { return nil }
                    return c.element?.text
                }
            case "Overwrites":
                self.overwrites = try child.children.compactMap { c in
                    guard c.element?.name == "Overwrite" else { return nil }
                    return try MVROverwrite(xml: c)
                }
            case "Connections":
                self.connections = try child.children.compactMap { c in
                    guard c.element?.name == "Connection" else { return nil }
                    return try MVRConnection(xml: c)
                }
            case "FixtureID":
                self.fixtureID = elem.text
            case "FixtureIDNumeric":
                self.fixtureIDNumeric = try parseMVRInt(elem.text, field: "FixtureIDNumeric")
            case "UnitNumber":
                self.unitNumber = try parseMVRInt(elem.text, field: "UnitNumber")
            case "CustomId":
                self.customId = try parseMVRIntOptional(elem.text, field: "CustomId")
            case "CustomIdType":
                self.customIdType = try parseMVRIntOptional(elem.text, field: "CustomIdType")
            case "ChildList":
                self.childList = try parseChildList(xml: child)

            // Fixture-specific
            case "Focus":
                self.focus = try parseMVROptionalUUID(elem.text, field: "Focus")
            case "DMXInvertPan":
                self.dmxInvertPan = try parseMVRBoolOptional(elem.text, field: "DMXInvertPan")
            case "DMXInvertTilt":
                self.dmxInvertTilt = try parseMVRBoolOptional(elem.text, field: "DMXInvertTilt")
            case "Position":
                self.position = try parseMVROptionalUUID(elem.text, field: "Position")
            case "Function":
                self.function = elem.text.isEmpty ? nil : elem.text
            case "ChildPosition":
                self.childPosition = elem.text.isEmpty ? nil : elem.text
            case "Color":
                let text = elem.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { self.color = ColorCIE(from: text) }
            case "Protocols":
                self.protocols = try child.children.compactMap { c in
                    guard c.element?.name == "Protocol" else { return nil }
                    return try MVRProtocol(xml: c)
                }
            case "Mappings":
                self.mappings = try child.children.compactMap { c in
                    guard c.element?.name == "Mapping" else { return nil }
                    return try MVRMapping(xml: c)
                }
            case "Gobo":
                self.gobo = try MVRGobo(xml: child)

            // VideoScreen-specific
            case "Sources":
                self.sources = try child.children.compactMap { c in
                    guard c.element?.name == "Source" else { return nil }
                    return try MVRSource(xml: c)
                }

            // Projector-specific
            case "Projections":
                self.projections = try child.children.compactMap { c in
                    guard c.element?.name == "Projection" else { return nil }
                    return try MVRProjection(xml: c)
                }

            // Support-specific
            case "ChainLength":
                self.chainLength = try parseMVRDoubleOptional(elem.text, field: "ChainLength") ?? 0

            default:
                break
            }
        }
    }

    /// Validates spec rules common to all parametric objects.
    ///
    /// Note: the spec also requires `<GDTFMode>` whenever `<GDTFSpec>` is present
    /// and `<UnitNumber>` on every Fixture, but real-world MVR exports from major
    /// vendors (grandMA3, Vectorworks, Capture) routinely omit both. We accept
    /// those rather than rejecting the file.
    func validate(objectType: String, uuid: UUID, multipatch: UUID?) throws {
        if multipatch != nil && (!fixtureID.isEmpty || customId != nil) {
            throw MVRParsingError.multipatchExcludesFixtureID(objectType: objectType, uuid: uuid)
        }
    }
}

// MARK: - Parametric Object Parsing

extension MVRSceneObject {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
        self.multipatch = try parseMVROptionalUUID(element.attribute(by: "multipatch")?.text, field: "SceneObject/multipatch")

        let c = try ParametricObjectChildren(xml: xml)
        try c.validate(objectType: "SceneObject", uuid: self.uuid, multipatch: self.multipatch)
        self.matrix = c.matrix
        self.classing = c.classing
        self.geometries = c.geometries
        self.gdtfSpec = c.gdtfSpec
        self.gdtfMode = c.gdtfMode
        self.castShadow = c.castShadow
        self.addresses = c.addresses
        self.alignments = c.alignments
        self.customCommands = c.customCommands
        self.overwrites = c.overwrites
        self.connections = c.connections
        self.fixtureID = c.fixtureID
        self.fixtureIDNumeric = c.fixtureIDNumeric
        self.unitNumber = c.unitNumber
        self.customId = c.customId
        self.customIdType = c.customIdType
        self.childList = c.childList
    }
}

extension MVRGroupObject {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""

        var matrix: Matrix?
        var classing: UUID?
        var childList: [MVRChildObject] = []

        for child in xml.children {
            guard let elem = child.element else { continue }
            switch elem.name {
            case "Matrix":
                matrix = try Matrix(fromMVR: elem.text)
            case "Classing":
                classing = try parseMVROptionalUUID(elem.text, field: "GroupObject/Classing")
            case "ChildList":
                childList = try parseChildList(xml: child)
            default: break
            }
        }

        self.matrix = matrix
        self.classing = classing
        self.childList = childList
    }
}

extension MVRFocusPoint {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""

        var matrix: Matrix?
        var classing: UUID?
        var geometries: [MVRGeometryNode] = []

        for child in xml.children {
            guard let elem = child.element else { continue }
            switch elem.name {
            case "Matrix":
                matrix = try Matrix(fromMVR: elem.text)
            case "Classing":
                classing = try parseMVROptionalUUID(elem.text, field: "FocusPoint/Classing")
            case "Geometries":
                geometries = try child.children.compactMap { geoChild in
                    guard let geoElem = geoChild.element,
                          let kind = MVRGeometryNode.Kind(rawValue: geoElem.name) else { return nil }
                    return try kind.parse(xml: geoChild)
                }
            default: break
            }
        }

        self.matrix = matrix
        self.classing = classing
        self.geometries = geometries
    }
}

extension MVRFixture {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
        self.multipatch = try parseMVROptionalUUID(element.attribute(by: "multipatch")?.text, field: "Fixture/multipatch")

        let c = try ParametricObjectChildren(xml: xml)
        try c.validate(objectType: "Fixture", uuid: self.uuid, multipatch: self.multipatch)
        self.matrix = c.matrix
        self.classing = c.classing
        self.gdtfSpec = c.gdtfSpec
        self.gdtfMode = c.gdtfMode
        self.focus = c.focus
        self.castShadow = c.castShadow
        self.dmxInvertPan = c.dmxInvertPan
        self.dmxInvertTilt = c.dmxInvertTilt
        self.position = c.position
        self.function = c.function
        self.fixtureID = c.fixtureID
        self.fixtureIDNumeric = c.fixtureIDNumeric
        self.unitNumber = c.unitNumber
        self.childPosition = c.childPosition
        self.addresses = c.addresses
        self.protocols = c.protocols
        self.alignments = c.alignments
        self.customCommands = c.customCommands
        self.overwrites = c.overwrites
        self.connections = c.connections
        self.color = c.color
        self.customIdType = c.customIdType
        self.customId = c.customId
        self.mappings = c.mappings
        self.gobo = c.gobo
        self.childList = c.childList
    }
}

extension MVRTruss {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
        self.multipatch = try parseMVROptionalUUID(element.attribute(by: "multipatch")?.text, field: "Truss/multipatch")

        let c = try ParametricObjectChildren(xml: xml)
        try c.validate(objectType: "Truss", uuid: self.uuid, multipatch: self.multipatch)
        self.matrix = c.matrix
        self.classing = c.classing
        self.position = c.position
        self.geometries = c.geometries
        self.function = c.function
        self.gdtfSpec = c.gdtfSpec
        self.gdtfMode = c.gdtfMode
        self.castShadow = c.castShadow
        self.addresses = c.addresses
        self.alignments = c.alignments
        self.customCommands = c.customCommands
        self.overwrites = c.overwrites
        self.connections = c.connections
        self.childPosition = c.childPosition
        self.fixtureID = c.fixtureID
        self.fixtureIDNumeric = c.fixtureIDNumeric
        self.unitNumber = c.unitNumber
        self.customIdType = c.customIdType
        self.customId = c.customId
        self.childList = c.childList
    }
}

extension MVRSupport {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
        self.multipatch = try parseMVROptionalUUID(element.attribute(by: "multipatch")?.text, field: "Support/multipatch")

        let c = try ParametricObjectChildren(xml: xml)
        try c.validate(objectType: "Support", uuid: self.uuid, multipatch: self.multipatch)
        self.matrix = c.matrix
        self.classing = c.classing
        self.position = c.position
        self.geometries = c.geometries
        self.function = c.function
        self.chainLength = c.chainLength
        self.gdtfSpec = c.gdtfSpec
        self.gdtfMode = c.gdtfMode
        self.castShadow = c.castShadow
        self.addresses = c.addresses
        self.alignments = c.alignments
        self.customCommands = c.customCommands
        self.overwrites = c.overwrites
        self.connections = c.connections
        self.fixtureID = c.fixtureID
        self.fixtureIDNumeric = c.fixtureIDNumeric
        self.unitNumber = c.unitNumber
        self.customIdType = c.customIdType
        self.customId = c.customId
        self.childList = c.childList
    }
}

extension MVRVideoScreen {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
        self.multipatch = try parseMVROptionalUUID(element.attribute(by: "multipatch")?.text, field: "VideoScreen/multipatch")

        let c = try ParametricObjectChildren(xml: xml)
        try c.validate(objectType: "VideoScreen", uuid: self.uuid, multipatch: self.multipatch)
        self.matrix = c.matrix
        self.classing = c.classing
        self.geometries = c.geometries
        self.sources = c.sources
        self.function = c.function
        self.gdtfSpec = c.gdtfSpec
        self.gdtfMode = c.gdtfMode
        self.castShadow = c.castShadow
        self.addresses = c.addresses
        self.alignments = c.alignments
        self.customCommands = c.customCommands
        self.overwrites = c.overwrites
        self.connections = c.connections
        self.fixtureID = c.fixtureID
        self.fixtureIDNumeric = c.fixtureIDNumeric
        self.unitNumber = c.unitNumber
        self.customIdType = c.customIdType
        self.customId = c.customId
        self.childList = c.childList
    }
}

extension MVRProjector {
    init(xml: XMLIndexer) throws {
        guard let element = xml.element else { throw MVRParsingError.elementMissing }
        self.uuid = try element.attribute(named: "uuid").uuid
        self.name = element.attribute(by: "name")?.text ?? ""
        self.multipatch = try parseMVROptionalUUID(element.attribute(by: "multipatch")?.text, field: "Projector/multipatch")

        let c = try ParametricObjectChildren(xml: xml)
        try c.validate(objectType: "Projector", uuid: self.uuid, multipatch: self.multipatch)
        self.matrix = c.matrix
        self.classing = c.classing
        self.geometries = c.geometries
        self.projections = c.projections
        self.gdtfSpec = c.gdtfSpec
        self.gdtfMode = c.gdtfMode
        self.castShadow = c.castShadow
        self.addresses = c.addresses
        self.alignments = c.alignments
        self.customCommands = c.customCommands
        self.overwrites = c.overwrites
        self.connections = c.connections
        self.fixtureID = c.fixtureID
        self.fixtureIDNumeric = c.fixtureIDNumeric
        self.unitNumber = c.unitNumber
        self.customIdType = c.customIdType
        self.customId = c.customId
        self.childList = c.childList
    }
}
