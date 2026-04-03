//
//  MVR.swift
//  SwiftGDTF
//
//  MVR (My Virtual Rig, DIN SPEC 15801) model types.
//  File format only — not the MVR-xchange protocol.
//

import Foundation
import simd

// MARK: - Errors

/// Errors from loading an MVR archive.
public enum MVRError: Error, CustomStringConvertible {
    case invalidArchive
    case missingSceneDescription
    case invalidXML(any Error)
    case invalidRootElement(String)
    case resourceNotFound(String)

    public var description: String {
        switch self {
        case .invalidArchive: "MVR data is not a valid ZIP archive"
        case .missingSceneDescription: "MVR archive does not contain GeneralSceneDescription.xml"
        case .invalidXML(let error): "Failed to parse MVR XML: \(error)"
        case .invalidRootElement(let name): "Expected root element 'GeneralSceneDescription', got '\(name)'"
        case .resourceNotFound(let name): "Resource '\(name)' not found in MVR archive"
        }
    }
}

/// Errors from parsing MVR XML content.
public enum MVRParsingError: Error, CustomStringConvertible {
    case elementMissing
    case attributeMissing(named: String, element: String)
    case invalidMatrix(String)
    case invalidUUID(String)
    case unexpectedElement(String)
    case missingChildElement(String)

    public var description: String {
        switch self {
        case .elementMissing: "XML element missing"
        case .attributeMissing(let name, let element): "Required attribute '\(name)' missing on <\(element)>"
        case .invalidMatrix(let value): "Invalid MVR matrix: '\(value)'"
        case .invalidUUID(let value): "Invalid UUID: '\(value)'"
        case .unexpectedElement(let name): "Unexpected element: <\(name)>"
        case .missingChildElement(let name): "Missing required child element <\(name)>"
        }
    }
}

// MARK: - Root Types

/// The root of a parsed MVR file (GeneralSceneDescription node).
///
/// Contains version info, provider metadata, optional user data, and the scene.
public struct MVRScene: Equatable, Sendable {
    /// Major version of the MVR format.
    public var verMajor: Int
    /// Minor version of the MVR format.
    public var verMinor: Int
    /// Name of the application that generated this MVR file.
    public var provider: String
    /// Version of the application that generated this MVR file.
    public var providerVersion: String
    /// Optional user data blocks from provider applications.
    public var userData: [MVRUserData]
    /// The scene described in this file.
    public var scene: MVRSceneNode

    public init(
        verMajor: Int = 1,
        verMinor: Int = 6,
        provider: String = "",
        providerVersion: String = "",
        userData: [MVRUserData] = [],
        scene: MVRSceneNode
    ) {
        self.verMajor = verMajor
        self.verMinor = verMinor
        self.provider = provider
        self.providerVersion = providerVersion
        self.userData = userData
        self.scene = scene
    }
}

/// A block of user data specified by a provider application.
///
/// User data should not be expected to be preserved across applications.
public struct MVRUserData: Equatable, Sendable {
    /// Name of the provider application that created this data.
    public var provider: String
    /// Version information of the data.
    public var ver: String
    /// Raw text content of the Data node.
    public var content: String

    public init(provider: String = "", ver: String = "1", content: String = "") {
        self.provider = provider
        self.ver = ver
        self.content = content
    }
}

/// The scene node containing auxiliary data and layers.
public struct MVRSceneNode: Equatable, Sendable {
    /// Auxiliary data (symdefs, positions, mapping definitions, classes).
    public var auxData: MVRAUXData
    /// Layers in the scene, in document order.
    public var layers: [MVRLayer]

    public init(auxData: MVRAUXData = MVRAUXData(), layers: [MVRLayer] = []) {
        self.auxData = auxData
        self.layers = layers
    }
}

// MARK: - AUXData Types

/// Auxiliary data for the scene: shared definitions referenced by objects.
public struct MVRAUXData: Equatable, Sendable {
    /// Graphical representations that can be instanced via Symbol nodes.
    public var symdefs: [MVRSymdef]
    /// Logical groupings of lighting devices.
    public var positions: [MVRPosition]
    /// Input sources for fixture color mapping.
    public var mappingDefinitions: [MVRMappingDefinition]
    /// Logical groupings for object visibility filtering across layers.
    public var classes: [MVRClass]

    public init(
        symdefs: [MVRSymdef] = [],
        positions: [MVRPosition] = [],
        mappingDefinitions: [MVRMappingDefinition] = [],
        classes: [MVRClass] = []
    ) {
        self.symdefs = symdefs
        self.positions = positions
        self.mappingDefinitions = mappingDefinitions
        self.classes = classes
    }
}

/// A shared graphical definition that can be instanced in the scene via Symbol nodes.
public struct MVRSymdef: Equatable, Sendable {
    /// The unique identifier of this symdef.
    public var uuid: UUID
    /// The name of this symdef.
    public var name: String
    /// Geometry nodes (Geometry3D and Symbol) within this definition.
    public var children: [MVRGeometryNode]

    public init(uuid: UUID, name: String = "", children: [MVRGeometryNode] = []) {
        self.uuid = uuid
        self.name = name
        self.children = children
    }
}

/// A logical grouping of lighting devices and trusses.
public struct MVRPosition: Equatable, Sendable {
    /// The unique identifier of this position.
    public var uuid: UUID
    /// The name of this position.
    public var name: String

    public init(uuid: UUID, name: String = "") {
        self.uuid = uuid
        self.name = name
    }
}

/// An input source definition for fixture color mapping applications.
public struct MVRMappingDefinition: Equatable, Sendable {
    /// The unique identifier of this mapping definition.
    public var uuid: UUID
    /// The name of the source for the mapping.
    public var name: String
    /// Size in x direction in pixels of the source.
    public var sizeX: Int
    /// Size in y direction in pixels of the source.
    public var sizeY: Int
    /// The video source for the mapping.
    public var source: MVRSource?
    /// How the source will be scaled to the mapping.
    public var scaleHandling: MVRScaleHandling?

    public init(
        uuid: UUID,
        name: String = "",
        sizeX: Int = 0,
        sizeY: Int = 0,
        source: MVRSource? = nil,
        scaleHandling: MVRScaleHandling? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.sizeX = sizeX
        self.sizeY = sizeY
        self.source = source
        self.scaleHandling = scaleHandling
    }
}

/// A class for object visibility filtering across layers.
public struct MVRClass: Equatable, Sendable {
    /// The unique identifier of this class.
    public var uuid: UUID
    /// The name of the class.
    public var name: String

    public init(uuid: UUID, name: String = "") {
        self.uuid = uuid
        self.name = name
    }
}

// MARK: - Layer

/// A layer in the scene — a spatial container for graphical objects with a local coordinate system.
public struct MVRLayer: Equatable, Sendable {
    /// The unique identifier of this layer.
    public var uuid: UUID
    /// The name of this layer.
    public var name: String
    /// Transform defining the location/orientation of the layer. Only vertical transform (elevation) is allowed.
    public var matrix: Matrix?
    /// Graphical objects within this layer.
    public var childList: [MVRChildObject]

    public init(uuid: UUID, name: String = "", matrix: Matrix? = nil, childList: [MVRChildObject] = []) {
        self.uuid = uuid
        self.name = name
        self.matrix = matrix
        self.childList = childList
    }
}

// MARK: - MVRChildObject Enum

/// A parametric object in the MVR scene tree.
///
/// Follows the `Geometry` enum pattern: an enum with associated values wrapping
/// typed structs, with a `Kind` enum whose raw values match XML element names.
public enum MVRChildObject: Equatable, Sendable {
    /// The XML element name for each parametric object type.
    public enum Kind: String, Sendable {
        /// A generic graphical object from the scene.
        case sceneObject = "SceneObject"
        /// A grouping object of other graphical objects.
        case groupObject = "GroupObject"
        /// A focus point definition.
        case focusPoint = "FocusPoint"
        /// An entertainment fixture.
        case fixture = "Fixture"
        /// A truss object.
        case truss = "Truss"
        /// A support object (base plate, hoist, etc.).
        case support = "Support"
        /// A video screen.
        case videoScreen = "VideoScreen"
        /// A video projector.
        case projector = "Projector"
    }

    case sceneObject(MVRSceneObject)
    case groupObject(MVRGroupObject)
    case focusPoint(MVRFocusPoint)
    case fixture(MVRFixture)
    case truss(MVRTruss)
    case support(MVRSupport)
    case videoScreen(MVRVideoScreen)
    case projector(MVRProjector)

    public var kind: Kind {
        switch self {
        case .sceneObject: .sceneObject
        case .groupObject: .groupObject
        case .focusPoint: .focusPoint
        case .fixture: .fixture
        case .truss: .truss
        case .support: .support
        case .videoScreen: .videoScreen
        case .projector: .projector
        }
    }

    public var uuid: UUID {
        switch self {
        case .sceneObject(let o): o.uuid
        case .groupObject(let o): o.uuid
        case .focusPoint(let o): o.uuid
        case .fixture(let o): o.uuid
        case .truss(let o): o.uuid
        case .support(let o): o.uuid
        case .videoScreen(let o): o.uuid
        case .projector(let o): o.uuid
        }
    }

    public var name: String {
        switch self {
        case .sceneObject(let o): o.name
        case .groupObject(let o): o.name
        case .focusPoint(let o): o.name
        case .fixture(let o): o.name
        case .truss(let o): o.name
        case .support(let o): o.name
        case .videoScreen(let o): o.name
        case .projector(let o): o.name
        }
    }

    public var matrix: Matrix? {
        switch self {
        case .sceneObject(let o): o.matrix
        case .groupObject(let o): o.matrix
        case .focusPoint(let o): o.matrix
        case .fixture(let o): o.matrix
        case .truss(let o): o.matrix
        case .support(let o): o.matrix
        case .videoScreen(let o): o.matrix
        case .projector(let o): o.matrix
        }
    }

    public var classing: UUID? {
        switch self {
        case .sceneObject(let o): o.classing
        case .groupObject(let o): o.classing
        case .focusPoint(let o): o.classing
        case .fixture(let o): o.classing
        case .truss(let o): o.classing
        case .support(let o): o.classing
        case .videoScreen(let o): o.classing
        case .projector(let o): o.classing
        }
    }

    public var childList: [MVRChildObject] {
        switch self {
        case .sceneObject(let o): o.childList
        case .groupObject(let o): o.childList
        case .focusPoint: []
        case .fixture(let o): o.childList
        case .truss(let o): o.childList
        case .support(let o): o.childList
        case .videoScreen(let o): o.childList
        case .projector(let o): o.childList
        }
    }

    /// Geometry nodes (Geometry3D / Symbol) for objects that carry inline geometry.
    /// Fixtures return empty (their geometry comes from the linked GDTF file).
    public var geometries: [MVRGeometryNode] {
        switch self {
        case .sceneObject(let o): o.geometries
        case .focusPoint(let o): o.geometries
        case .truss(let o): o.geometries
        case .support(let o): o.geometries
        case .videoScreen(let o): o.geometries
        case .projector(let o): o.geometries
        case .groupObject, .fixture: []
        }
    }

    /// GDTF spec string, if the object references a GDTF file.
    public var gdtfSpec: String? {
        switch self {
        case .sceneObject(let o): o.gdtfSpec
        case .fixture(let o): o.gdtfSpec
        case .truss(let o): o.gdtfSpec
        case .support(let o): o.gdtfSpec
        case .videoScreen(let o): o.gdtfSpec
        case .projector(let o): o.gdtfSpec
        case .groupObject, .focusPoint: nil
        }
    }

    // MARK: - Mutable Accessors

    /// Mutable access to the object's name.
    public var mutableName: String {
        get { name }
        set {
            switch self {
            case .sceneObject(var o): o.name = newValue; self = .sceneObject(o)
            case .groupObject(var o): o.name = newValue; self = .groupObject(o)
            case .focusPoint(var o): o.name = newValue; self = .focusPoint(o)
            case .fixture(var o): o.name = newValue; self = .fixture(o)
            case .truss(var o): o.name = newValue; self = .truss(o)
            case .support(var o): o.name = newValue; self = .support(o)
            case .videoScreen(var o): o.name = newValue; self = .videoScreen(o)
            case .projector(var o): o.name = newValue; self = .projector(o)
            }
        }
    }

    /// Mutable access to the object's transform matrix.
    public var mutableMatrix: Matrix? {
        get { matrix }
        set {
            switch self {
            case .sceneObject(var o): o.matrix = newValue; self = .sceneObject(o)
            case .groupObject(var o): o.matrix = newValue; self = .groupObject(o)
            case .focusPoint(var o): o.matrix = newValue; self = .focusPoint(o)
            case .fixture(var o): o.matrix = newValue; self = .fixture(o)
            case .truss(var o): o.matrix = newValue; self = .truss(o)
            case .support(var o): o.matrix = newValue; self = .support(o)
            case .videoScreen(var o): o.matrix = newValue; self = .videoScreen(o)
            case .projector(var o): o.matrix = newValue; self = .projector(o)
            }
        }
    }

    /// Mutable access to the child object list.
    /// Focus points have no children; setting on a focus point is ignored.
    public var mutableChildList: [MVRChildObject] {
        get { childList }
        set {
            switch self {
            case .sceneObject(var o): o.childList = newValue; self = .sceneObject(o)
            case .groupObject(var o): o.childList = newValue; self = .groupObject(o)
            case .focusPoint: break // focus points have no children
            case .fixture(var o): o.childList = newValue; self = .fixture(o)
            case .truss(var o): o.childList = newValue; self = .truss(o)
            case .support(var o): o.childList = newValue; self = .support(o)
            case .videoScreen(var o): o.childList = newValue; self = .videoScreen(o)
            case .projector(var o): o.childList = newValue; self = .projector(o)
            }
        }
    }

    /// Mutable access to the object's UUID.
    public var mutableUUID: UUID {
        get { uuid }
        set {
            switch self {
            case .sceneObject(var o): o.uuid = newValue; self = .sceneObject(o)
            case .groupObject(var o): o.uuid = newValue; self = .groupObject(o)
            case .focusPoint(var o): o.uuid = newValue; self = .focusPoint(o)
            case .fixture(var o): o.uuid = newValue; self = .fixture(o)
            case .truss(var o): o.uuid = newValue; self = .truss(o)
            case .support(var o): o.uuid = newValue; self = .support(o)
            case .videoScreen(var o): o.uuid = newValue; self = .videoScreen(o)
            case .projector(var o): o.uuid = newValue; self = .projector(o)
            }
        }
    }

    /// Mutable access to the GDTF spec string.
    /// Group objects and focus points have no GDTF spec; setting on them is ignored.
    public var mutableGdtfSpec: String? {
        get { gdtfSpec }
        set {
            switch self {
            case .sceneObject(var o): o.gdtfSpec = newValue; self = .sceneObject(o)
            case .fixture(var o): o.gdtfSpec = newValue; self = .fixture(o)
            case .truss(var o): o.gdtfSpec = newValue; self = .truss(o)
            case .support(var o): o.gdtfSpec = newValue; self = .support(o)
            case .videoScreen(var o): o.gdtfSpec = newValue; self = .videoScreen(o)
            case .projector(var o): o.gdtfSpec = newValue; self = .projector(o)
            case .groupObject, .focusPoint: break
            }
        }
    }

    /// Mutable access to the classing UUID.
    public var mutableClassing: UUID? {
        get { classing }
        set {
            switch self {
            case .sceneObject(var o): o.classing = newValue; self = .sceneObject(o)
            case .groupObject(var o): o.classing = newValue; self = .groupObject(o)
            case .focusPoint(var o): o.classing = newValue; self = .focusPoint(o)
            case .fixture(var o): o.classing = newValue; self = .fixture(o)
            case .truss(var o): o.classing = newValue; self = .truss(o)
            case .support(var o): o.classing = newValue; self = .support(o)
            case .videoScreen(var o): o.classing = newValue; self = .videoScreen(o)
            case .projector(var o): o.classing = newValue; self = .projector(o)
            }
        }
    }

    /// Recursively assigns new UUIDs to this object and all nested children.
    /// Returns a mapping from old UUID to new UUID.
    @discardableResult
    public mutating func reassignUUIDs() -> [UUID: UUID] {
        var mapping: [UUID: UUID] = [:]
        reassignUUIDsRecursive(&mapping)
        return mapping
    }

    private mutating func reassignUUIDsRecursive(_ mapping: inout [UUID: UUID]) {
        let oldUUID = uuid
        let newUUID = UUID()
        mapping[oldUUID] = newUUID
        mutableUUID = newUUID
        var children = mutableChildList
        for i in children.indices {
            children[i].reassignUUIDsRecursive(&mapping)
        }
        mutableChildList = children
    }
}

// MARK: - Parametric Object Structs

/// A generic graphical object from the scene.
public struct MVRSceneObject: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var multipatch: UUID?
    public var matrix: Matrix?
    public var classing: UUID?
    /// Geometrical representations (Geometry3D and Symbol nodes).
    public var geometries: [MVRGeometryNode]
    /// GDTF file name for this object.
    public var gdtfSpec: String?
    /// DMX mode name matching a DMXMode in the GDTF file.
    public var gdtfMode: String?
    /// Whether this object casts shadows.
    public var castShadow: Bool?
    /// DMX and network addresses.
    public var addresses: [MVRAddressEntry]
    /// Custom beam alignments.
    public var alignments: [MVRAlignment]
    /// Custom commands to execute on the fixture.
    public var customCommands: [String]
    /// Overwrites for gobos, filters, and emitters.
    public var overwrites: [MVROverwrite]
    /// Object-to-object connections.
    public var connections: [MVRConnection]
    /// Fixture ID for programming activation/selection.
    public var fixtureID: String
    /// Numeric fixture ID.
    public var fixtureIDNumeric: Int
    /// Alternative numbering scheme for the fixture on its position.
    public var unitNumber: Int?
    /// Short name identifier within the CustomID Type.
    public var customId: Int?
    /// Defines the CustomID Type group this object belongs to.
    public var customIdType: Int?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(
        uuid: UUID,
        name: String = "",
        multipatch: UUID? = nil,
        matrix: Matrix? = nil,
        classing: UUID? = nil,
        geometries: [MVRGeometryNode] = [],
        gdtfSpec: String? = nil,
        gdtfMode: String? = nil,
        castShadow: Bool? = nil,
        addresses: [MVRAddressEntry] = [],
        alignments: [MVRAlignment] = [],
        customCommands: [String] = [],
        overwrites: [MVROverwrite] = [],
        connections: [MVRConnection] = [],
        fixtureID: String = "",
        fixtureIDNumeric: Int = 0,
        unitNumber: Int? = nil,
        customId: Int? = nil,
        customIdType: Int? = nil,
        childList: [MVRChildObject] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.multipatch = multipatch
        self.matrix = matrix
        self.classing = classing
        self.geometries = geometries
        self.gdtfSpec = gdtfSpec
        self.gdtfMode = gdtfMode
        self.castShadow = castShadow
        self.addresses = addresses
        self.alignments = alignments
        self.customCommands = customCommands
        self.overwrites = overwrites
        self.connections = connections
        self.fixtureID = fixtureID
        self.fixtureIDNumeric = fixtureIDNumeric
        self.unitNumber = unitNumber
        self.customId = customId
        self.customIdType = customIdType
        self.childList = childList
    }
}

/// A grouping object of other graphical objects inside a local coordinate system.
public struct MVRGroupObject: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var matrix: Matrix?
    public var classing: UUID?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(uuid: UUID, name: String = "", matrix: Matrix? = nil, classing: UUID? = nil, childList: [MVRChildObject] = []) {
        self.uuid = uuid
        self.name = name
        self.matrix = matrix
        self.classing = classing
        self.childList = childList
    }
}

/// A focus point definition.
public struct MVRFocusPoint: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var matrix: Matrix?
    public var classing: UUID?
    /// Geometrical representations.
    public var geometries: [MVRGeometryNode]

    public init(uuid: UUID, name: String = "", matrix: Matrix? = nil, classing: UUID? = nil, geometries: [MVRGeometryNode] = []) {
        self.uuid = uuid
        self.name = name
        self.matrix = matrix
        self.classing = classing
        self.geometries = geometries
    }
}

/// An entertainment fixture object.
///
/// Note: Fixtures have no `Geometries` node — geometry is defined in the linked GDTF file.
public struct MVRFixture: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var multipatch: UUID?
    public var matrix: Matrix?
    public var classing: UUID?
    /// GDTF file name for this fixture.
    public var gdtfSpec: String?
    /// DMX mode name matching a DMXMode in the GDTF file.
    public var gdtfMode: String?
    /// UUID of the focus point this fixture aims at.
    public var focus: UUID?
    /// Whether this fixture casts shadows.
    public var castShadow: Bool?
    /// Whether pan channels should be DMX inverted.
    public var dmxInvertPan: Bool?
    /// Whether tilt channels should be DMX inverted.
    public var dmxInvertTilt: Bool?
    /// UUID of the position this fixture belongs to.
    public var position: UUID?
    /// The name of the purpose this fixture has.
    public var function: String?
    /// Fixture ID for programming activation/selection.
    public var fixtureID: String
    /// Numeric fixture ID.
    public var fixtureIDNumeric: Int
    /// Alternative numbering scheme for the fixture on its position.
    public var unitNumber: Int?
    /// Node link to geometry in the parent GDTF's Geometry Collect.
    public var childPosition: String?
    /// DMX and network addresses.
    public var addresses: [MVRAddressEntry]
    /// Protocol assignments.
    public var protocols: [MVRProtocol]
    /// Custom beam alignments.
    public var alignments: [MVRAlignment]
    /// Custom commands to execute on the fixture.
    public var customCommands: [String]
    /// Overwrites for gobos, filters, and emitters.
    public var overwrites: [MVROverwrite]
    /// Object-to-object connections.
    public var connections: [MVRConnection]
    /// Color assigned to the fixture (CIE xyY).
    public var color: ColorCIE?
    /// Defines the CustomID Type group this fixture belongs to.
    public var customIdType: Int?
    /// Short name identifier within the CustomID Type.
    public var customId: Int?
    /// Fixture-to-mapping-definition mappings.
    public var mappings: [MVRMapping]
    /// Gobo used for the fixture.
    public var gobo: MVRGobo?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(
        uuid: UUID,
        name: String = "",
        multipatch: UUID? = nil,
        matrix: Matrix? = nil,
        classing: UUID? = nil,
        gdtfSpec: String? = nil,
        gdtfMode: String? = nil,
        focus: UUID? = nil,
        castShadow: Bool? = nil,
        dmxInvertPan: Bool? = nil,
        dmxInvertTilt: Bool? = nil,
        position: UUID? = nil,
        function: String? = nil,
        fixtureID: String = "",
        fixtureIDNumeric: Int = 0,
        unitNumber: Int? = nil,
        childPosition: String? = nil,
        addresses: [MVRAddressEntry] = [],
        protocols: [MVRProtocol] = [],
        alignments: [MVRAlignment] = [],
        customCommands: [String] = [],
        overwrites: [MVROverwrite] = [],
        connections: [MVRConnection] = [],
        color: ColorCIE? = nil,
        customIdType: Int? = nil,
        customId: Int? = nil,
        mappings: [MVRMapping] = [],
        gobo: MVRGobo? = nil,
        childList: [MVRChildObject] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.multipatch = multipatch
        self.matrix = matrix
        self.classing = classing
        self.gdtfSpec = gdtfSpec
        self.gdtfMode = gdtfMode
        self.focus = focus
        self.castShadow = castShadow
        self.dmxInvertPan = dmxInvertPan
        self.dmxInvertTilt = dmxInvertTilt
        self.position = position
        self.function = function
        self.fixtureID = fixtureID
        self.fixtureIDNumeric = fixtureIDNumeric
        self.unitNumber = unitNumber
        self.childPosition = childPosition
        self.addresses = addresses
        self.protocols = protocols
        self.alignments = alignments
        self.customCommands = customCommands
        self.overwrites = overwrites
        self.connections = connections
        self.color = color
        self.customIdType = customIdType
        self.customId = customId
        self.mappings = mappings
        self.gobo = gobo
        self.childList = childList
    }
}

/// A truss object.
public struct MVRTruss: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var multipatch: UUID?
    public var matrix: Matrix?
    public var classing: UUID?
    /// UUID of the position this truss belongs to.
    public var position: UUID?
    /// Geometrical representations.
    public var geometries: [MVRGeometryNode]
    /// The name of the function this truss is used for.
    public var function: String?
    /// GDTF file name.
    public var gdtfSpec: String?
    /// DMX mode name.
    public var gdtfMode: String?
    /// Whether this truss casts shadows.
    public var castShadow: Bool?
    /// DMX and network addresses.
    public var addresses: [MVRAddressEntry]
    /// Custom beam alignments.
    public var alignments: [MVRAlignment]
    /// Custom commands.
    public var customCommands: [String]
    /// Overwrites for gobos, filters, and emitters.
    public var overwrites: [MVROverwrite]
    /// Object-to-object connections.
    public var connections: [MVRConnection]
    /// Node link to geometry in the parent GDTF's Geometry Collect.
    public var childPosition: String?
    /// Fixture ID for programming activation/selection.
    public var fixtureID: String
    /// Numeric fixture ID.
    public var fixtureIDNumeric: Int
    /// Alternative numbering scheme.
    public var unitNumber: Int?
    /// Defines the CustomID Type group.
    public var customIdType: Int?
    /// Short name identifier within the CustomID Type.
    public var customId: Int?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(
        uuid: UUID,
        name: String = "",
        multipatch: UUID? = nil,
        matrix: Matrix? = nil,
        classing: UUID? = nil,
        position: UUID? = nil,
        geometries: [MVRGeometryNode] = [],
        function: String? = nil,
        gdtfSpec: String? = nil,
        gdtfMode: String? = nil,
        castShadow: Bool? = nil,
        addresses: [MVRAddressEntry] = [],
        alignments: [MVRAlignment] = [],
        customCommands: [String] = [],
        overwrites: [MVROverwrite] = [],
        connections: [MVRConnection] = [],
        childPosition: String? = nil,
        fixtureID: String = "",
        fixtureIDNumeric: Int = 0,
        unitNumber: Int? = nil,
        customIdType: Int? = nil,
        customId: Int? = nil,
        childList: [MVRChildObject] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.multipatch = multipatch
        self.matrix = matrix
        self.classing = classing
        self.position = position
        self.geometries = geometries
        self.function = function
        self.gdtfSpec = gdtfSpec
        self.gdtfMode = gdtfMode
        self.castShadow = castShadow
        self.addresses = addresses
        self.alignments = alignments
        self.customCommands = customCommands
        self.overwrites = overwrites
        self.connections = connections
        self.childPosition = childPosition
        self.fixtureID = fixtureID
        self.fixtureIDNumeric = fixtureIDNumeric
        self.unitNumber = unitNumber
        self.customIdType = customIdType
        self.customId = customId
        self.childList = childList
    }
}

/// A support object (base plate, hoist, chain motor, etc.).
public struct MVRSupport: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var multipatch: UUID?
    public var matrix: Matrix?
    public var classing: UUID?
    /// UUID of the position this support belongs to.
    public var position: UUID?
    /// Geometrical representations.
    public var geometries: [MVRGeometryNode]
    /// The name of the function this support is used for.
    public var function: String?
    /// Chain length applied to the GDTF.
    public var chainLength: Double
    /// GDTF file name.
    public var gdtfSpec: String?
    /// DMX mode name.
    public var gdtfMode: String?
    /// Whether this support casts shadows.
    public var castShadow: Bool?
    /// DMX and network addresses.
    public var addresses: [MVRAddressEntry]
    /// Custom beam alignments.
    public var alignments: [MVRAlignment]
    /// Custom commands.
    public var customCommands: [String]
    /// Overwrites for gobos, filters, and emitters.
    public var overwrites: [MVROverwrite]
    /// Object-to-object connections.
    public var connections: [MVRConnection]
    /// Fixture ID for programming activation/selection.
    public var fixtureID: String
    /// Numeric fixture ID.
    public var fixtureIDNumeric: Int
    /// Alternative numbering scheme.
    public var unitNumber: Int?
    /// Defines the CustomID Type group.
    public var customIdType: Int?
    /// Short name identifier within the CustomID Type.
    public var customId: Int?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(
        uuid: UUID,
        name: String = "",
        multipatch: UUID? = nil,
        matrix: Matrix? = nil,
        classing: UUID? = nil,
        position: UUID? = nil,
        geometries: [MVRGeometryNode] = [],
        function: String? = nil,
        chainLength: Double = 0,
        gdtfSpec: String? = nil,
        gdtfMode: String? = nil,
        castShadow: Bool? = nil,
        addresses: [MVRAddressEntry] = [],
        alignments: [MVRAlignment] = [],
        customCommands: [String] = [],
        overwrites: [MVROverwrite] = [],
        connections: [MVRConnection] = [],
        fixtureID: String = "",
        fixtureIDNumeric: Int = 0,
        unitNumber: Int? = nil,
        customIdType: Int? = nil,
        customId: Int? = nil,
        childList: [MVRChildObject] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.multipatch = multipatch
        self.matrix = matrix
        self.classing = classing
        self.position = position
        self.geometries = geometries
        self.function = function
        self.chainLength = chainLength
        self.gdtfSpec = gdtfSpec
        self.gdtfMode = gdtfMode
        self.castShadow = castShadow
        self.addresses = addresses
        self.alignments = alignments
        self.customCommands = customCommands
        self.overwrites = overwrites
        self.connections = connections
        self.fixtureID = fixtureID
        self.fixtureIDNumeric = fixtureIDNumeric
        self.unitNumber = unitNumber
        self.customIdType = customIdType
        self.customId = customId
        self.childList = childList
    }
}

/// A video screen object.
public struct MVRVideoScreen: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var multipatch: UUID?
    public var matrix: Matrix?
    public var classing: UUID?
    /// Geometrical representations.
    public var geometries: [MVRGeometryNode]
    /// Video input sources.
    public var sources: [MVRSource]
    /// The name of the function this video screen is used for.
    public var function: String?
    /// GDTF file name.
    public var gdtfSpec: String?
    /// DMX mode name.
    public var gdtfMode: String?
    /// Whether this video screen casts shadows.
    public var castShadow: Bool?
    /// DMX and network addresses.
    public var addresses: [MVRAddressEntry]
    /// Custom beam alignments.
    public var alignments: [MVRAlignment]
    /// Custom commands.
    public var customCommands: [String]
    /// Overwrites for gobos, filters, and emitters.
    public var overwrites: [MVROverwrite]
    /// Object-to-object connections.
    public var connections: [MVRConnection]
    /// Fixture ID for programming activation/selection.
    public var fixtureID: String
    /// Numeric fixture ID.
    public var fixtureIDNumeric: Int
    /// Alternative numbering scheme.
    public var unitNumber: Int?
    /// Defines the CustomID Type group.
    public var customIdType: Int?
    /// Short name identifier within the CustomID Type.
    public var customId: Int?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(
        uuid: UUID,
        name: String = "",
        multipatch: UUID? = nil,
        matrix: Matrix? = nil,
        classing: UUID? = nil,
        geometries: [MVRGeometryNode] = [],
        sources: [MVRSource] = [],
        function: String? = nil,
        gdtfSpec: String? = nil,
        gdtfMode: String? = nil,
        castShadow: Bool? = nil,
        addresses: [MVRAddressEntry] = [],
        alignments: [MVRAlignment] = [],
        customCommands: [String] = [],
        overwrites: [MVROverwrite] = [],
        connections: [MVRConnection] = [],
        fixtureID: String = "",
        fixtureIDNumeric: Int = 0,
        unitNumber: Int? = nil,
        customIdType: Int? = nil,
        customId: Int? = nil,
        childList: [MVRChildObject] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.multipatch = multipatch
        self.matrix = matrix
        self.classing = classing
        self.geometries = geometries
        self.sources = sources
        self.function = function
        self.gdtfSpec = gdtfSpec
        self.gdtfMode = gdtfMode
        self.castShadow = castShadow
        self.addresses = addresses
        self.alignments = alignments
        self.customCommands = customCommands
        self.overwrites = overwrites
        self.connections = connections
        self.fixtureID = fixtureID
        self.fixtureIDNumeric = fixtureIDNumeric
        self.unitNumber = unitNumber
        self.customIdType = customIdType
        self.customId = customId
        self.childList = childList
    }
}

/// A video projector object.
public struct MVRProjector: Equatable, Sendable {
    public var uuid: UUID
    public var name: String
    public var multipatch: UUID?
    public var matrix: Matrix?
    public var classing: UUID?
    /// Geometrical representations.
    public var geometries: [MVRGeometryNode]
    /// Projections (video sources for beam geometries).
    public var projections: [MVRProjection]
    /// GDTF file name.
    public var gdtfSpec: String?
    /// DMX mode name.
    public var gdtfMode: String?
    /// Whether this projector casts shadows.
    public var castShadow: Bool?
    /// DMX and network addresses.
    public var addresses: [MVRAddressEntry]
    /// Custom beam alignments.
    public var alignments: [MVRAlignment]
    /// Custom commands.
    public var customCommands: [String]
    /// Overwrites for gobos, filters, and emitters.
    public var overwrites: [MVROverwrite]
    /// Object-to-object connections.
    public var connections: [MVRConnection]
    /// Fixture ID for programming activation/selection.
    public var fixtureID: String
    /// Numeric fixture ID.
    public var fixtureIDNumeric: Int
    /// Alternative numbering scheme.
    public var unitNumber: Int?
    /// Defines the CustomID Type group.
    public var customIdType: Int?
    /// Short name identifier within the CustomID Type.
    public var customId: Int?
    /// Nested child objects.
    public var childList: [MVRChildObject]

    public init(
        uuid: UUID,
        name: String = "",
        multipatch: UUID? = nil,
        matrix: Matrix? = nil,
        classing: UUID? = nil,
        geometries: [MVRGeometryNode] = [],
        projections: [MVRProjection] = [],
        gdtfSpec: String? = nil,
        gdtfMode: String? = nil,
        castShadow: Bool? = nil,
        addresses: [MVRAddressEntry] = [],
        alignments: [MVRAlignment] = [],
        customCommands: [String] = [],
        overwrites: [MVROverwrite] = [],
        connections: [MVRConnection] = [],
        fixtureID: String = "",
        fixtureIDNumeric: Int = 0,
        unitNumber: Int? = nil,
        customIdType: Int? = nil,
        customId: Int? = nil,
        childList: [MVRChildObject] = []
    ) {
        self.uuid = uuid
        self.name = name
        self.multipatch = multipatch
        self.matrix = matrix
        self.classing = classing
        self.geometries = geometries
        self.projections = projections
        self.gdtfSpec = gdtfSpec
        self.gdtfMode = gdtfMode
        self.castShadow = castShadow
        self.addresses = addresses
        self.alignments = alignments
        self.customCommands = customCommands
        self.overwrites = overwrites
        self.connections = connections
        self.fixtureID = fixtureID
        self.fixtureIDNumeric = fixtureIDNumeric
        self.unitNumber = unitNumber
        self.customIdType = customIdType
        self.customId = customId
        self.childList = childList
    }
}

// MARK: - Geometry Node Types

/// A geometry node within Geometries or Symdef containers.
public enum MVRGeometryNode: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case geometry3D = "Geometry3D"
        case symbol = "Symbol"
    }

    /// A 3D geometry file reference.
    case geometry3D(MVRGeometry3D)
    /// A symbol instance referencing a Symdef.
    case symbol(MVRSymbol)

    public var kind: Kind {
        switch self {
        case .geometry3D: .geometry3D
        case .symbol: .symbol
        }
    }
}

/// A 3D geometry provided by an external file within the archive.
public struct MVRGeometry3D: Equatable, Sendable {
    /// File name including extension of the geometry file in the archive.
    /// If there is no extension, 3ds is assumed.
    public var fileName: String
    /// Transform matrix for location, orientation, and scale within the local coordinate space.
    public var matrix: Matrix?

    public init(fileName: String, matrix: Matrix? = nil) {
        self.fileName = fileName
        self.matrix = matrix
    }
}

/// An instance of a Symdef's geometry, placed via a transform matrix.
public struct MVRSymbol: Equatable, Sendable {
    /// The unique identifier of this symbol instance.
    public var uuid: UUID
    /// UUID of the Symdef that provides the geometry.
    public var symdef: UUID
    /// Transform matrix within the local coordinate space.
    public var matrix: Matrix?

    public init(uuid: UUID, symdef: UUID, matrix: Matrix? = nil) {
        self.uuid = uuid
        self.symdef = symdef
        self.matrix = matrix
    }
}

// MARK: - Address Types

/// An entry in the Addresses container: either a DMX address or a network address.
public enum MVRAddressEntry: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case address = "Address"
        case network = "Network"
    }

    /// A DMX address.
    case address(MVRAddress)
    /// A network IP address.
    case network(MVRNetwork)

    public var kind: Kind {
        switch self {
        case .address: .address
        case .network: .network
        }
    }
}

/// A DMX address for a fixture.
public struct MVRAddress: Equatable, Sendable {
    /// Break identifier for this address (unique per fixture). Default 0.
    public var `break`: Int
    /// The DMX address (universe.address or absolute).
    public var dmxAddress: DMXAddress

    public init(`break`: Int = 0, dmxAddress: DMXAddress) {
        self.break = `break`
        self.dmxAddress = dmxAddress
    }
}

/// A network IP address for a fixture's physical interface.
public struct MVRNetwork: Equatable, Sendable {
    /// Name of the wire geometry in the linked GDTF (e.g. "ethernet_1").
    public var geometry: String
    /// IPv4 address.
    public var ipv4: String?
    /// Subnet mask (only for IPv4).
    public var subnetMask: String?
    /// IPv6 address.
    public var ipv6: String?
    /// Whether DHCP is enabled.
    public var dhcp: Bool
    /// Hostname for automated address assignment.
    public var hostname: String?

    public init(
        geometry: String,
        ipv4: String? = nil,
        subnetMask: String? = nil,
        ipv6: String? = nil,
        dhcp: Bool = false,
        hostname: String? = nil
    ) {
        self.geometry = geometry
        self.ipv4 = ipv4
        self.subnetMask = subnetMask
        self.ipv6 = ipv6
        self.dhcp = dhcp
        self.hostname = hostname
    }
}

// MARK: - Sub-Node Types

/// A custom alignment for a beam geometry inside the linked GDTF.
public struct MVRAlignment: Equatable, Sendable {
    /// Name of the beam geometry that gets aligned.
    public var geometry: String
    /// Up vector of the direction.
    public var up: Vector3
    /// Direction vector of the lamp.
    public var direction: Vector3

    public init(geometry: String, up: Vector3, direction: Vector3) {
        self.geometry = geometry
        self.up = up
        self.direction = direction
    }
}

/// An overwrite using the Universal.gdtt template to replace wheel slots, emitters, or filters.
public struct MVROverwrite: Equatable, Sendable {
    /// Node link to the wheel/emitter/filter in the Universal GDTF.
    public var universal: String
    /// Node link to the target in the fixture's GDTF. Empty means a static gobo/filter in front of all beams.
    public var target: String?

    public init(universal: String, target: String? = nil) {
        self.universal = universal
        self.target = target
    }
}

/// A connection between two scene objects (electrical or data).
public struct MVRConnection: Equatable, Sendable {
    /// Node link to a WiringObject geometry in this object's GDTF.
    public var own: String
    /// UUID of the other object in the scene.
    public var toObject: UUID
    /// Node link to a WiringObject geometry in the other object's GDTF.
    public var other: String

    public init(own: String, toObject: UUID, other: String) {
        self.own = own
        self.toObject = toObject
        self.other = other
    }
}

/// A protocol assignment for a fixture.
public struct MVRProtocol: Equatable, Sendable {
    /// Interface name (e.g. "NetworkInOut_1").
    public var geometry: String
    /// Custom name to identify this protocol instance.
    public var name: String
    /// Protocol type (e.g. "Art-Net", "sACN", "NDI").
    public var type: String
    /// Protocol version, if available.
    public var version: String
    /// Transmission type.
    public var transmission: MVRTransmission?

    public init(geometry: String = "NetworkInOut_1", name: String = "", type: String = "", version: String = "", transmission: MVRTransmission? = nil) {
        self.geometry = geometry
        self.name = name
        self.type = type
        self.version = version
        self.transmission = transmission
    }
}

/// A fixture-to-mapping-definition mapping.
public struct MVRMapping: Equatable, Sendable {
    /// UUID of the MappingDefinition that is the source.
    public var linkedDef: UUID
    /// Offset in pixels in x direction from top left of the source.
    public var ux: Int?
    /// Offset in pixels in y direction from top left of the source.
    public var uy: Int?
    /// Size in pixels in x direction from the starting point.
    public var ox: Int?
    /// Size in pixels in y direction from the starting point.
    public var oy: Int?
    /// Rotation around the middle point in degrees (positive = counter-clockwise).
    public var rz: Double?

    public init(linkedDef: UUID, ux: Int? = nil, uy: Int? = nil, ox: Int? = nil, oy: Int? = nil, rz: Double? = nil) {
        self.linkedDef = linkedDef
        self.ux = ux
        self.uy = uy
        self.ox = ox
        self.oy = oy
        self.rz = rz
    }
}

/// A gobo assigned to a fixture.
public struct MVRGobo: Equatable, Sendable {
    /// Rotation of the gobo in degrees.
    public var rotation: Double
    /// File name of the gobo image resource (must conform to GDTF standard).
    public var fileName: String

    public init(rotation: Double = 0, fileName: String) {
        self.rotation = rotation
        self.fileName = fileName
    }
}

/// A video source for video screens or projections.
public struct MVRSource: Equatable, Sendable {
    /// For Display: the GDTF geometry whose linked texture gets replaced.
    /// For Beam: the source for a Rectangle BeamType.
    public var linkedGeometry: String
    /// Type of the media resource source.
    public var type: MVRSourceType
    /// Source value: stream name (NDI/CITP), filename (File), or device name (CaptureDevice).
    public var value: String

    public init(linkedGeometry: String, type: MVRSourceType = .file, value: String = "") {
        self.linkedGeometry = linkedGeometry
        self.type = type
        self.value = value
    }
}

/// A projection definition for a projector.
public struct MVRProjection: Equatable, Sendable {
    /// Sources for the projection.
    public var sources: [MVRSource]
    /// How the source will be scaled to the projection.
    public var scaleHandling: MVRScaleHandling?

    public init(sources: [MVRSource] = [], scaleHandling: MVRScaleHandling? = nil) {
        self.sources = sources
        self.scaleHandling = scaleHandling
    }
}

// MARK: - Value Enums

/// How a MappingDefinition or Projection scales the source when resolutions differ.
public enum MVRScaleHandling: String, Equatable, Sendable {
    case scaleKeepRatio = "ScaleKeepRatio"
    case scaleIgnoreRatio = "ScaleIgnoreRatio"
    case keepSizeCenter = "KeepSizeCenter"
}

/// Type of media resource source for video screens and projections.
public enum MVRSourceType: String, Equatable, Sendable {
    case ndi = "NDI"
    case file = "File"
    case citp = "CITP"
    case captureDevice = "CaptureDevice"
}

/// Transmission type for a protocol assignment.
public enum MVRTransmission: String, Equatable, Sendable {
    case unicast = "Unicast"
    case multicast = "Multicast"
    case broadcast = "Broadcast"
    case anycast = "Anycast"
}

// MARK: - Matrix Extension for MVR 4×3 Format

extension Matrix {
    /// Parses an MVR 4×3 matrix string.
    ///
    /// MVR uses 12 values in the format `{u1,u2,u3}{v1,v2,v3}{w1,w2,w3}{o1,o2,o3}`:
    /// - Rows 0–2: rotation/scale basis vectors
    /// - Row 3: translation (in mm)
    /// - Right-handed, Z-up, 1 unit = 1 mm
    /// - Same row-vector convention as GDTF (v' = v·M)
    public init(fromMVR rawValue: String) throws {
        var str = rawValue
        str = str.replacingOccurrences(of: "}{", with: ",")
        str = str.replacingOccurrences(of: "{", with: "")
        str = str.replacingOccurrences(of: "}", with: "")

        let values: [Double] = str.split(separator: ",").map { Double($0) ?? 0 }
        guard values.count == 12 else {
            throw MVRParsingError.invalidMatrix(rawValue)
        }

        // Same convention as GDTF: each raw row becomes a SIMD column.
        // Row 0 (u): values[0..2]  → SIMD col 0
        // Row 1 (v): values[3..5]  → SIMD col 1
        // Row 2 (w): values[6..8]  → SIMD col 2
        // Row 3 (o): values[9..11] → SIMD col 3 (translation)
        self.matrix = .init(
            .init(values[0], values[1], values[2], 0),
            .init(values[3], values[4], values[5], 0),
            .init(values[6], values[7], values[8], 0),
            .init(values[9], values[10], values[11], 1)
        )
    }

    /// Serializes this matrix to the MVR 4×3 format: `{u1,u2,u3}{v1,v2,v3}{w1,w2,w3}{o1,o2,o3}`.
    ///
    /// Each SIMD column becomes one `{...}` group (matching the decode convention).
    public var mvrString: String {
        let m = matrix
        func f(_ v: Double) -> String { mvrDoubleToString(v) }
        return "{\(f(m[0][0])),\(f(m[0][1])),\(f(m[0][2]))}{\(f(m[1][0])),\(f(m[1][1])),\(f(m[1][2]))}{\(f(m[2][0])),\(f(m[2][1])),\(f(m[2][2]))}{\(f(m[3][0])),\(f(m[3][1])),\(f(m[3][2]))}"
    }
}

/// Formats a Double for MVR output, preserving enough precision for lossless round-trips
/// while avoiding unnecessary trailing zeros.
func mvrDoubleToString(_ v: Double) -> String {
    if v == 0 { return "0" }
    // Use enough significant digits to round-trip a Double through decimal text.
    // 17 significant digits guarantees exact round-trip for any Double.
    var s = String(v)
    // Swift's String(Double) uses enough precision for exact round-trip and avoids
    // scientific notation for most values, but may produce "1e-08" etc for very
    // small numbers. The MVR parser handles scientific notation via Double($0),
    // so this is fine.
    // However, strip ".0" suffix for clean integers
    if s.hasSuffix(".0") {
        s = String(s.dropLast(2))
    }
    return s
}
