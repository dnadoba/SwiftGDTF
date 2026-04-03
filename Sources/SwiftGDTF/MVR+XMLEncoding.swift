//
//  MVR+XMLEncoding.swift
//  SwiftGDTF
//
//  XML generation for all MVR model types.
//  Uses Foundation.XMLElement (not SWXMLHash which is read-only).
//

import Foundation

// MARK: - Root Types

extension MVRScene {
    func xmlElement() -> XMLElement {
        let root = XMLElement(name: "GeneralSceneDescription")
        root.addAttribute(XMLNode.attribute(withName: "verMajor", stringValue: "\(verMajor)") as! XMLNode)
        root.addAttribute(XMLNode.attribute(withName: "verMinor", stringValue: "\(verMinor)") as! XMLNode)
        if !provider.isEmpty {
            root.addAttribute(XMLNode.attribute(withName: "provider", stringValue: provider) as! XMLNode)
        }
        if !providerVersion.isEmpty {
            root.addAttribute(XMLNode.attribute(withName: "providerVersion", stringValue: providerVersion) as! XMLNode)
        }

        if !userData.isEmpty {
            let userDataNode = XMLElement(name: "UserData")
            for ud in userData {
                userDataNode.addChild(ud.xmlElement())
            }
            root.addChild(userDataNode)
        }

        root.addChild(scene.xmlElement())
        return root
    }
}

extension MVRUserData {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Data", stringValue: content)
        node.addAttribute(XMLNode.attribute(withName: "provider", stringValue: provider) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "ver", stringValue: ver) as! XMLNode)
        return node
    }
}

extension MVRSceneNode {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Scene")

        let auxNode = auxData.xmlElement()
        node.addChild(auxNode)

        let layersNode = XMLElement(name: "Layers")
        for layer in layers {
            layersNode.addChild(layer.xmlElement())
        }
        node.addChild(layersNode)

        return node
    }
}

// MARK: - AUXData

extension MVRAUXData {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "AUXData")
        for s in symdefs { node.addChild(s.xmlElement()) }
        for p in positions { node.addChild(p.xmlElement()) }
        for m in mappingDefinitions { node.addChild(m.xmlElement()) }
        for c in classes { node.addChild(c.xmlElement()) }
        return node
    }
}

extension MVRSymdef {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Symdef")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if !children.isEmpty {
            let childList = XMLElement(name: "ChildList")
            for child in children {
                childList.addChild(child.xmlElement())
            }
            node.addChild(childList)
        }
        return node
    }
}

extension MVRPosition {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Position")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        return node
    }
}

extension MVRMappingDefinition {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "MappingDefinition")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        node.addChild(XMLElement(name: "SizeX", stringValue: "\(sizeX)"))
        node.addChild(XMLElement(name: "SizeY", stringValue: "\(sizeY)"))
        if let source { node.addChild(source.xmlElement()) }
        if let sh = scaleHandling {
            // MVR spec typo: "ScaleHandeling" (missing 'd')
            node.addChild(XMLElement(name: "ScaleHandeling", stringValue: sh.rawValue))
        }
        return node
    }
}

extension MVRClass {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Class")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        return node
    }
}

// MARK: - Layer

extension MVRLayer {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Layer")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let matrix {
            node.addChild(XMLElement(name: "Matrix", stringValue: matrix.mvrString))
        }
        if !childList.isEmpty {
            let cl = XMLElement(name: "ChildList")
            for child in childList {
                cl.addChild(child.xmlElement())
            }
            node.addChild(cl)
        }
        return node
    }
}

// MARK: - MVRChildObject

extension MVRChildObject {
    func xmlElement() -> XMLElement {
        switch self {
        case .sceneObject(let o): o.xmlElement()
        case .groupObject(let o): o.xmlElement()
        case .focusPoint(let o): o.xmlElement()
        case .fixture(let o): o.xmlElement()
        case .truss(let o): o.xmlElement()
        case .support(let o): o.xmlElement()
        case .videoScreen(let o): o.xmlElement()
        case .projector(let o): o.xmlElement()
        }
    }
}

// MARK: - Geometry Nodes

extension MVRGeometryNode {
    func xmlElement() -> XMLElement {
        switch self {
        case .geometry3D(let g): g.xmlElement()
        case .symbol(let s): s.xmlElement()
        }
    }
}

extension MVRGeometry3D {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Geometry3D")
        node.addAttribute(XMLNode.attribute(withName: "fileName", stringValue: fileName) as! XMLNode)
        if let matrix {
            node.addChild(XMLElement(name: "Matrix", stringValue: matrix.mvrString))
        }
        return node
    }
}

extension MVRSymbol {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Symbol")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "symdef", stringValue: symdef.uuidString) as! XMLNode)
        if let matrix {
            node.addChild(XMLElement(name: "Matrix", stringValue: matrix.mvrString))
        }
        return node
    }
}

// MARK: - Address Entries

extension MVRAddressEntry {
    func xmlElement() -> XMLElement {
        switch self {
        case .address(let a): a.xmlElement()
        case .network(let n): n.xmlElement()
        }
    }
}

extension MVRAddress {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Address", stringValue: dmxAddress.mvrString)
        node.addAttribute(XMLNode.attribute(withName: "break", stringValue: "\(self.break)") as! XMLNode)
        return node
    }
}

extension MVRNetwork {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Network")
        node.addAttribute(XMLNode.attribute(withName: "geometry", stringValue: geometry) as! XMLNode)
        if let ipv4 { node.addAttribute(XMLNode.attribute(withName: "IPv4", stringValue: ipv4) as! XMLNode) }
        if let subnetMask { node.addAttribute(XMLNode.attribute(withName: "SubnetMask", stringValue: subnetMask) as! XMLNode) }
        if let ipv6 { node.addAttribute(XMLNode.attribute(withName: "IPv6", stringValue: ipv6) as! XMLNode) }
        node.addAttribute(XMLNode.attribute(withName: "DHCP", stringValue: dhcp ? "true" : "false") as! XMLNode)
        if let hostname { node.addAttribute(XMLNode.attribute(withName: "hostname", stringValue: hostname) as! XMLNode) }
        return node
    }
}

// MARK: - Sub-Nodes

extension MVRAlignment {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Alignment")
        node.addAttribute(XMLNode.attribute(withName: "geometry", stringValue: geometry) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "up", stringValue: up.mvrString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "direction", stringValue: direction.mvrString) as! XMLNode)
        return node
    }
}

extension MVROverwrite {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Overwrite")
        node.addAttribute(XMLNode.attribute(withName: "universal", stringValue: universal) as! XMLNode)
        if let target {
            node.addAttribute(XMLNode.attribute(withName: "target", stringValue: target) as! XMLNode)
        }
        return node
    }
}

extension MVRConnection {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Connection")
        node.addAttribute(XMLNode.attribute(withName: "own", stringValue: own) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "toObject", stringValue: toObject.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "other", stringValue: other) as! XMLNode)
        return node
    }
}

extension MVRProtocol {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Protocol")
        node.addAttribute(XMLNode.attribute(withName: "geometry", stringValue: geometry) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "type", stringValue: type) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "version", stringValue: version) as! XMLNode)
        if let transmission {
            node.addAttribute(XMLNode.attribute(withName: "transmission", stringValue: transmission.rawValue) as! XMLNode)
        }
        return node
    }
}

extension MVRMapping {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Mapping")
        node.addAttribute(XMLNode.attribute(withName: "linkedDef", stringValue: linkedDef.uuidString) as! XMLNode)
        if let ux { node.addChild(XMLElement(name: "ux", stringValue: "\(ux)")) }
        if let uy { node.addChild(XMLElement(name: "uy", stringValue: "\(uy)")) }
        if let ox { node.addChild(XMLElement(name: "ox", stringValue: "\(ox)")) }
        if let oy { node.addChild(XMLElement(name: "oy", stringValue: "\(oy)")) }
        if let rz { node.addChild(XMLElement(name: "rz", stringValue: "\(rz)")) }
        return node
    }
}

extension MVRGobo {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Gobo", stringValue: fileName)
        node.addAttribute(XMLNode.attribute(withName: "rotation", stringValue: "\(rotation)") as! XMLNode)
        return node
    }
}

extension MVRSource {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Source", stringValue: value)
        node.addAttribute(XMLNode.attribute(withName: "linkedGeometry", stringValue: linkedGeometry) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "type", stringValue: type.rawValue) as! XMLNode)
        return node
    }
}

extension MVRProjection {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Projection")
        for source in sources {
            node.addChild(source.xmlElement())
        }
        if let sh = scaleHandling {
            // MVR spec typo: "ScaleHandeling" (missing 'd')
            node.addChild(XMLElement(name: "ScaleHandeling", stringValue: sh.rawValue))
        }
        return node
    }
}

// MARK: - Parametric Object Encoding Helpers

/// Adds common parametric object children to an XMLElement.
/// Mirrors the `ParametricObjectChildren` struct from MVR+XML.swift.
private func addParametricObjectChildren(
    to node: XMLElement,
    matrix: Matrix?,
    classing: UUID?,
    geometries: [MVRGeometryNode],
    gdtfSpec: String?,
    gdtfMode: String?,
    castShadow: Bool?,
    addresses: [MVRAddressEntry],
    alignments: [MVRAlignment],
    customCommands: [String],
    overwrites: [MVROverwrite],
    connections: [MVRConnection],
    fixtureID: String,
    fixtureIDNumeric: Int,
    unitNumber: Int?,
    customId: Int?,
    customIdType: Int?,
    childList: [MVRChildObject],
    // Fixture-specific
    focus: UUID? = nil,
    dmxInvertPan: Bool? = nil,
    dmxInvertTilt: Bool? = nil,
    position: UUID? = nil,
    function: String? = nil,
    childPosition: String? = nil,
    color: ColorCIE? = nil,
    protocols: [MVRProtocol] = [],
    mappings: [MVRMapping] = [],
    gobo: MVRGobo? = nil,
    // VideoScreen-specific
    sources: [MVRSource] = [],
    // Projector-specific
    projections: [MVRProjection] = [],
    // Support-specific
    chainLength: Double? = nil
) {
    if let matrix {
        node.addChild(XMLElement(name: "Matrix", stringValue: matrix.mvrString))
    }
    if let classing {
        node.addChild(XMLElement(name: "Classing", stringValue: classing.uuidString))
    }
    if !geometries.isEmpty {
        let geoNode = XMLElement(name: "Geometries")
        for geo in geometries {
            geoNode.addChild(geo.xmlElement())
        }
        node.addChild(geoNode)
    }
    if let gdtfSpec {
        node.addChild(XMLElement(name: "GDTFSpec", stringValue: gdtfSpec))
    }
    if let gdtfMode {
        node.addChild(XMLElement(name: "GDTFMode", stringValue: gdtfMode))
    }
    if let castShadow {
        node.addChild(XMLElement(name: "CastShadow", stringValue: castShadow ? "true" : "false"))
    }
    if let focus {
        node.addChild(XMLElement(name: "Focus", stringValue: focus.uuidString))
    }
    if let dmxInvertPan {
        node.addChild(XMLElement(name: "DMXInvertPan", stringValue: dmxInvertPan ? "true" : "false"))
    }
    if let dmxInvertTilt {
        node.addChild(XMLElement(name: "DMXInvertTilt", stringValue: dmxInvertTilt ? "true" : "false"))
    }
    if let position {
        node.addChild(XMLElement(name: "Position", stringValue: position.uuidString))
    }
    if let function {
        node.addChild(XMLElement(name: "Function", stringValue: function))
    }
    if let childPosition {
        node.addChild(XMLElement(name: "ChildPosition", stringValue: childPosition))
    }
    if let chainLength {
        node.addChild(XMLElement(name: "ChainLength", stringValue: "\(chainLength)"))
    }
    if !addresses.isEmpty {
        let addrNode = XMLElement(name: "Addresses")
        for addr in addresses {
            addrNode.addChild(addr.xmlElement())
        }
        node.addChild(addrNode)
    }
    if !protocols.isEmpty {
        let protNode = XMLElement(name: "Protocols")
        for p in protocols {
            protNode.addChild(p.xmlElement())
        }
        node.addChild(protNode)
    }
    if !alignments.isEmpty {
        let alignNode = XMLElement(name: "Alignments")
        for a in alignments {
            alignNode.addChild(a.xmlElement())
        }
        node.addChild(alignNode)
    }
    if !customCommands.isEmpty {
        let ccNode = XMLElement(name: "CustomCommands")
        for cmd in customCommands {
            ccNode.addChild(XMLElement(name: "CustomCommand", stringValue: cmd))
        }
        node.addChild(ccNode)
    }
    if !overwrites.isEmpty {
        let owNode = XMLElement(name: "Overwrites")
        for ow in overwrites {
            owNode.addChild(ow.xmlElement())
        }
        node.addChild(owNode)
    }
    if !connections.isEmpty {
        let connNode = XMLElement(name: "Connections")
        for c in connections {
            connNode.addChild(c.xmlElement())
        }
        node.addChild(connNode)
    }
    if let color {
        node.addChild(XMLElement(name: "Color", stringValue: color.mvrString))
    }
    if let gobo {
        node.addChild(gobo.xmlElement())
    }
    if !mappings.isEmpty {
        let mapNode = XMLElement(name: "Mappings")
        for m in mappings {
            mapNode.addChild(m.xmlElement())
        }
        node.addChild(mapNode)
    }
    if !sources.isEmpty {
        let srcNode = XMLElement(name: "Sources")
        for s in sources {
            srcNode.addChild(s.xmlElement())
        }
        node.addChild(srcNode)
    }
    if !projections.isEmpty {
        let projNode = XMLElement(name: "Projections")
        for p in projections {
            projNode.addChild(p.xmlElement())
        }
        node.addChild(projNode)
    }
    node.addChild(XMLElement(name: "FixtureID", stringValue: fixtureID))
    node.addChild(XMLElement(name: "FixtureIDNumeric", stringValue: "\(fixtureIDNumeric)"))
    if let unitNumber {
        node.addChild(XMLElement(name: "UnitNumber", stringValue: "\(unitNumber)"))
    }
    if let customIdType {
        node.addChild(XMLElement(name: "CustomIdType", stringValue: "\(customIdType)"))
    }
    if let customId {
        node.addChild(XMLElement(name: "CustomId", stringValue: "\(customId)"))
    }
    if !childList.isEmpty {
        let cl = XMLElement(name: "ChildList")
        for child in childList {
            cl.addChild(child.xmlElement())
        }
        node.addChild(cl)
    }
}

// MARK: - Parametric Object Encoding

extension MVRSceneObject {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "SceneObject")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let multipatch {
            node.addAttribute(XMLNode.attribute(withName: "multipatch", stringValue: multipatch.uuidString) as! XMLNode)
        }
        addParametricObjectChildren(
            to: node, matrix: matrix, classing: classing,
            geometries: geometries, gdtfSpec: gdtfSpec, gdtfMode: gdtfMode,
            castShadow: castShadow, addresses: addresses, alignments: alignments,
            customCommands: customCommands, overwrites: overwrites, connections: connections,
            fixtureID: fixtureID, fixtureIDNumeric: fixtureIDNumeric,
            unitNumber: unitNumber, customId: customId, customIdType: customIdType,
            childList: childList
        )
        return node
    }
}

extension MVRGroupObject {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "GroupObject")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let matrix {
            node.addChild(XMLElement(name: "Matrix", stringValue: matrix.mvrString))
        }
        if let classing {
            node.addChild(XMLElement(name: "Classing", stringValue: classing.uuidString))
        }
        if !childList.isEmpty {
            let cl = XMLElement(name: "ChildList")
            for child in childList {
                cl.addChild(child.xmlElement())
            }
            node.addChild(cl)
        }
        return node
    }
}

extension MVRFocusPoint {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "FocusPoint")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let matrix {
            node.addChild(XMLElement(name: "Matrix", stringValue: matrix.mvrString))
        }
        if let classing {
            node.addChild(XMLElement(name: "Classing", stringValue: classing.uuidString))
        }
        if !geometries.isEmpty {
            let geoNode = XMLElement(name: "Geometries")
            for geo in geometries {
                geoNode.addChild(geo.xmlElement())
            }
            node.addChild(geoNode)
        }
        return node
    }
}

extension MVRFixture {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Fixture")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let multipatch {
            node.addAttribute(XMLNode.attribute(withName: "multipatch", stringValue: multipatch.uuidString) as! XMLNode)
        }
        addParametricObjectChildren(
            to: node, matrix: matrix, classing: classing,
            geometries: [], gdtfSpec: gdtfSpec, gdtfMode: gdtfMode,
            castShadow: castShadow, addresses: addresses, alignments: alignments,
            customCommands: customCommands, overwrites: overwrites, connections: connections,
            fixtureID: fixtureID, fixtureIDNumeric: fixtureIDNumeric,
            unitNumber: unitNumber, customId: customId, customIdType: customIdType,
            childList: childList,
            focus: focus, dmxInvertPan: dmxInvertPan, dmxInvertTilt: dmxInvertTilt,
            position: position, function: function, childPosition: childPosition,
            color: color, protocols: protocols, mappings: mappings, gobo: gobo
        )
        return node
    }
}

extension MVRTruss {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Truss")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let multipatch {
            node.addAttribute(XMLNode.attribute(withName: "multipatch", stringValue: multipatch.uuidString) as! XMLNode)
        }
        addParametricObjectChildren(
            to: node, matrix: matrix, classing: classing,
            geometries: geometries, gdtfSpec: gdtfSpec, gdtfMode: gdtfMode,
            castShadow: castShadow, addresses: addresses, alignments: alignments,
            customCommands: customCommands, overwrites: overwrites, connections: connections,
            fixtureID: fixtureID, fixtureIDNumeric: fixtureIDNumeric,
            unitNumber: unitNumber, customId: customId, customIdType: customIdType,
            childList: childList,
            position: position, function: function, childPosition: childPosition
        )
        return node
    }
}

extension MVRSupport {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Support")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let multipatch {
            node.addAttribute(XMLNode.attribute(withName: "multipatch", stringValue: multipatch.uuidString) as! XMLNode)
        }
        addParametricObjectChildren(
            to: node, matrix: matrix, classing: classing,
            geometries: geometries, gdtfSpec: gdtfSpec, gdtfMode: gdtfMode,
            castShadow: castShadow, addresses: addresses, alignments: alignments,
            customCommands: customCommands, overwrites: overwrites, connections: connections,
            fixtureID: fixtureID, fixtureIDNumeric: fixtureIDNumeric,
            unitNumber: unitNumber, customId: customId, customIdType: customIdType,
            childList: childList,
            position: position, function: function,
            chainLength: chainLength
        )
        return node
    }
}

extension MVRVideoScreen {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "VideoScreen")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let multipatch {
            node.addAttribute(XMLNode.attribute(withName: "multipatch", stringValue: multipatch.uuidString) as! XMLNode)
        }
        addParametricObjectChildren(
            to: node, matrix: matrix, classing: classing,
            geometries: geometries, gdtfSpec: gdtfSpec, gdtfMode: gdtfMode,
            castShadow: castShadow, addresses: addresses, alignments: alignments,
            customCommands: customCommands, overwrites: overwrites, connections: connections,
            fixtureID: fixtureID, fixtureIDNumeric: fixtureIDNumeric,
            unitNumber: unitNumber, customId: customId, customIdType: customIdType,
            childList: childList,
            function: function, sources: sources
        )
        return node
    }
}

extension MVRProjector {
    func xmlElement() -> XMLElement {
        let node = XMLElement(name: "Projector")
        node.addAttribute(XMLNode.attribute(withName: "uuid", stringValue: uuid.uuidString) as! XMLNode)
        node.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
        if let multipatch {
            node.addAttribute(XMLNode.attribute(withName: "multipatch", stringValue: multipatch.uuidString) as! XMLNode)
        }
        addParametricObjectChildren(
            to: node, matrix: matrix, classing: classing,
            geometries: geometries, gdtfSpec: gdtfSpec, gdtfMode: gdtfMode,
            castShadow: castShadow, addresses: addresses, alignments: alignments,
            customCommands: customCommands, overwrites: overwrites, connections: connections,
            fixtureID: fixtureID, fixtureIDNumeric: fixtureIDNumeric,
            unitNumber: unitNumber, customId: customId, customIdType: customIdType,
            childList: childList,
            projections: projections
        )
        return node
    }
}
