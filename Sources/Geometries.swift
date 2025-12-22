//
//  Geometries.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 12/5/25.
//

/// The physical description of the device parts is defined in the geometry collect. Geometry collect can contain a separate geometry or a tree of geometries. The geometry collect currently does not have any XML attributes (XML node <Geometries>).
///
/// Note 1: Position the geometry in it's "Default" position. This is defined by the Default Value from the DMX Channel that controls the position of that geometry.
public enum Geometry: Codable {
    public enum Kind: String {
        /// General Geometry.
        case general = "Geometry"
        /// Geometry with axis.
        case axis = "Axis"
        /// Geometry with a beam filter.
        case filterBeam = "FilterBeam"
        /// Geometry with color filter.
        case filterColor = "FilterColor"
        /// Geometry with gobo.
        case filterGobo = "FilterGobo"
        /// Geometry with shaper.
        case filterShaper = "FilterShaper"
        /// Geometry that describes a light output to project.
        case beam = "Beam"
        /// Geometry that describes a media representation layer of a media device.
        case mediaServerLayer = "MediaServerLayer"
        /// Geometry that describes a camera or output layer of a media device.
        case mediaServerCamera = "MediaServerCamera"
        /// Geometry that describes a master control layer of a media device.
        case mediaServerMaster = "MediaServerMaster"
        /// Geometry that describes a surface to display visual media.
        case display = "Display"
        /// Reference to already described geometries.
        case reference = "GeometryReference"
        /// Geometry with a laser light output.
        case laser = "Laser"
        /// Geometry that describes an internal wiring for power or data.
        case wiringObject = "WiringObject"
        /// Geometry that describes an additional item that can be used for a fixture (like a rain cover).
        case inventory = "Inventory"
        /// Geometry that describes the internal framing of an object (like members).
        case structure = "Structure"
        /// Geometry that describes a support like a base plate or a hoist.
        case support = "Support"
        /// Geometry that describes a point where other geometries should be attached.
        case magnet = "Magnet"
    }
    /// General Geometry.
    case general(GeneralGeometry)
    /// Geometry with axis.
    case axis(Axis)
    /// Geometry with a beam filter.
    case filterBeam(FilterBeam)
    /// Geometry with color filter.
    case filterColor(FilterColor)
    /// Geometry with gobo.
    case filterGobo(FilterGobo)
    /// Geometry with shaper.
    case filterShaper(FilterShaper)
    /// Geometry that describes a light output to project.
    case beam(Beam)
    /// Geometry that describes a media representation layer of a media device.
    case mediaServerLayer(MediaServerLayer)
    /// Geometry that describes a camera or output layer of a media device.
    case mediaServerCamera(MediaServerCamera)
    /// Geometry that describes a master control layer of a media device.
    case mediaServerMaster(MediaServerMaster)
    /// Geometry that describes a surface to display visual media.
    case display(Display)
    /// Reference to already described geometries.
    case reference(GeometryReference)
    /// Geometry with a laser light output.
    case laser(Laser)
    /// Geometry that describes an internal wiring for power or data.
    case wiringObject(WiringObject)
    /// Geometry that describes an additional item that can be used for a fixture (like a rain cover).
    case inventory(Inventory)
    /// Geometry that describes the internal framing of an object (like members).
    case structure(Structure)
    /// Geometry that describes a support like a base plate or a hoist.
    case support(Support)
    /// Geometry that describes a point where other geometries should be attached.
    case magnet(Magnet)
    
    public var kind: Kind {
        switch self {
        case .general: .general
        case .axis: .axis
        case .filterBeam: .filterBeam
        case .filterColor: .filterColor
        case .filterGobo: .filterGobo
        case .filterShaper: .filterShaper
        case .beam: .beam
        case .mediaServerLayer: .mediaServerLayer
        case .mediaServerCamera: .mediaServerCamera
        case .mediaServerMaster: .mediaServerMaster
        case .display: .display
        case .reference: .reference
        case .laser: .laser
        case .wiringObject: .wiringObject
        case .inventory: .inventory
        case .structure: .structure
        case .support: .support
        case .magnet: .magnet
        }
    }
    
    public var children: [Geometry] {
        switch self {
        case .general(let geometry): geometry.children
        case .axis(let geometry): geometry.children
        case .filterBeam(let geometry): geometry.children
        case .filterColor(let geometry): geometry.children
        case .filterGobo(let geometry): geometry.children
        case .filterShaper(let geometry): geometry.children
        case .beam(let geometry): geometry.children
        case .mediaServerLayer(let geometry): geometry.children
        case .mediaServerCamera(let geometry): geometry.children
        case .mediaServerMaster(let geometry): geometry.children
        case .display(let geometry): geometry.children
        case .reference(let geometry): geometry.children
        case .laser(let geometry): geometry.children
        case .wiringObject(let geometry): geometry.children
        case .inventory(let geometry): geometry.children
        case .structure(let geometry): geometry.children
        case .support(let geometry): geometry.children
        case .magnet(let geometry): geometry.children
        }
    }
    
    public var name: String {
        switch self {
        case .general(let geometry): geometry.name
        case .axis(let geometry): geometry.name
        case .filterBeam(let geometry): geometry.name
        case .filterColor(let geometry): geometry.name
        case .filterGobo(let geometry): geometry.name
        case .filterShaper(let geometry): geometry.name
        case .beam(let geometry): geometry.name
        case .mediaServerLayer(let geometry): geometry.name
        case .mediaServerCamera(let geometry): geometry.name
        case .mediaServerMaster(let geometry): geometry.name
        case .display(let geometry): geometry.name
        case .reference(let geometry): geometry.name
        case .laser(let geometry): geometry.name
        case .wiringObject(let geometry): geometry.name
        case .inventory(let geometry): geometry.name
        case .structure(let geometry): geometry.name
        case .support(let geometry): geometry.name
        case .magnet(let geometry): geometry.name
        }
    }
    
    public var model: String? {
        switch self {
        case .general(let geometry): geometry.model
        case .axis(let geometry): geometry.model
        case .filterBeam(let geometry): geometry.model
        case .filterColor(let geometry): geometry.model
        case .filterGobo(let geometry): geometry.model
        case .filterShaper(let geometry): geometry.model
        case .beam(let geometry): geometry.model
        case .mediaServerLayer(let geometry): geometry.model
        case .mediaServerCamera(let geometry): geometry.model
        case .mediaServerMaster(let geometry): geometry.model
        case .display(let geometry): geometry.model
        case .reference(let geometry): geometry.model
        case .laser(let geometry): geometry.model
        case .wiringObject(let geometry): geometry.model
        case .inventory(let geometry): geometry.model
        case .structure(let geometry): geometry.model
        case .support(let geometry): geometry.model
        case .magnet(let geometry): geometry.model
        }
    }
    
    public var position: Matrix {
        switch self {
        case .general(let geometry): geometry.position
        case .axis(let geometry): geometry.position
        case .filterBeam(let geometry): geometry.position
        case .filterColor(let geometry): geometry.position
        case .filterGobo(let geometry): geometry.position
        case .filterShaper(let geometry): geometry.position
        case .beam(let geometry): geometry.position
        case .mediaServerLayer(let geometry): geometry.position
        case .mediaServerCamera(let geometry): geometry.position
        case .mediaServerMaster(let geometry): geometry.position
        case .display(let geometry): geometry.position
        case .reference(let geometry): geometry.position
        case .laser(let geometry): geometry.position
        case .wiringObject(let geometry): geometry.position
        case .inventory(let geometry): geometry.position
        case .structure(let geometry): geometry.position
        case .support(let geometry): geometry.position
        case .magnet(let geometry): geometry.position
        }
    }
}

extension Geometry {
    public var nestedChildren: GeometryNestedChildren {
        GeometryNestedChildren(geometry: self)
    }
}

public struct GeometryNestedChildren: Sequence {
    public typealias Element = Geometry
    public var geometry: Geometry
    public final class Iterator: IteratorProtocol {
        public typealias Element = Geometry
        public var geometry: Geometry
        public var index: Int?
        public var childIterator: Iterator?
        
        init(geometry: Geometry) {
            self.geometry = geometry
        }
        
        public func next() -> Element? {
            guard let index else {
                index = 0
                return geometry
            }
            if let childIterator = childIterator {
                if let element = childIterator.next() {
                    return element
                } else {
                    self.index = index &+ 1
                    self.childIterator = nil
                    return next()
                }
            } else {
                guard geometry.children.indices.contains(index) else {
                    return nil
                }
                self.childIterator = Iterator(geometry: geometry.children[index])
                return next()
            }
        }
    }
    public func makeIterator() -> Iterator {
        .init(geometry: geometry)
    }
}

public protocol GeometryProtocol {
    static var kind: Geometry.Kind { get }
    /// The unique name of geometry. Recommendation for conventional is “Body”. Recommendation for a geometry that is representing the base housing of a moving head is “Base”.
    var name: String { get }
    /// Link to the corresponding model.
    var model: String? { get }
    /// Relative position of geometry; Default value: Identity Matrix
    var position: Matrix { get }
    
    var children: [Geometry] { get }
}

/// General Geometry.
///
/// It is a basic geometry type without specification (XML node <Geometry>).
public struct GeneralGeometry: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .general }
    /// The unique name of geometry. Recommendation for conventional is “Body”. Recommendation for a geometry that is representing the base housing of a moving head is “Base”.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry with axis.
///
/// This type of geometry defines device parts with a rotation axis (XML node <Axis>).
public struct Axis: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .axis }
    /// The unique name of the geometry. Recommendation for an axis-geometry is “Yoke”. Recommendation for an axis-geometry representing the lamp housing of a moving head is “Head”. Note: The Head of a moving head is usually mounted to the Yoke.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry with a beam filter.
///
/// This type of geometry defines device parts with a beam filter (XML node <FilterBeam>).
public struct FilterBeam: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .filterBeam }
    /// The unique name of the geometry. Recommendation for beam filter limiting the diffusion of light is “BarnDoor”. Recommendation for beam filter adjusting the diameter of the beam is “Iris”. Note: BarnDoor and Iris are usually mounted to conventional.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry with color filter.
///
/// This type of geometry is used to describe device parts which have a color filter (XML node <FilterColor>).
public struct FilterColor: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .filterColor }
    /// The unique name of geometry. Recommendation for filter of a color or mechanical color changer is “FilterColor”. Note: FilterColor is usually mounted to conventional.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry with gobo.
/// This type of geometry is used to describe device parts which have gobo wheels (XML node <FilterGobo>).
public struct FilterGobo: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .filterGobo }
    /// The unique name of the geometry. Recommendation for filter of a gobo or mechanical gobo changer is “FilterGobo”. Note: FilterGobo is usually mounted to conventional.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry with shaper.
/// This type of geometry is used to describe device parts which have a shaper (XML node <FilterShaper>).
public struct FilterShaper: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .filterShaper }
    /// The unique name of the geometry; Recommendation for filter used to form the beam to a framed, triangular, or trapezoid shape, is “Shaper”. Note: Shaper is usually mounted to conventional.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry that describes a light output to project.
///
/// This type of geometry is used to describe device parts which have a light source (XML node <Beam>).
///
/// Use the Geometry Type "Beam" to describe the position of the fixture's light output (usually the position of the lens) and not the position of the light source inside the device. The origin of the Geometry Type "Beam" is the origin of the rendered beam. The origin of the Geometry Type "Beam" should not be covered by any faces of other geometries in order to not block the rendered beam.
public struct Beam: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .beam }
    /// The unique name of the geometry. Recommendation for a light source of a conventional or moving head or a projector is “Beam”. Note 1: Beam is usually mounted to Head or Body. Recommendation for a self-emitting single light source is “Pixel”. Note 2: Pixel is usually mounted to Head or Body. Recommendation for a number of Pixel that are controlled at the same time is “Array”. Note 3: Array is usually mounted to Head or Body. Recommendation for a light source of a moving mirror is “Mirror”. Note 4: Mirror is usually mounted to Yoke.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// Defines type of the light source
    public var lampType: LampType
    /// Power consumption; Default value: 1000; Unit: Watt
    public var powerConsumption: Double
    /// Intensity of all the represented light emitters; Default value: 10000; Unit: lumen
    public var luminousFlux: Double
    /// Color temperature; Default value: 6000; Unit: kelvin
    public var colorTemperature: Double
    /// Beam angle; Default value: 25.0; Unit: degree
    public var beamAngle: Double
    /// Field angle; Default value: 25.0; Unit: degree
    public var fieldAngle: Double
    /// Throw Ratio of the lens for BeamType Rectangle; Default value: 1; Unit: None
    public var throwRatio: Double
    /// Ratio from Width to Height of the Rectangle Type Beam; Default value: 1.7777; Unit: None
    public var rectangleRatio: Double
    /// Beam radius on starting point. Default value: 0.05; Unit: meter.
    public var beamRadius: Double
    /// Beam Type
    public var beamType: BeamType
    /// The CRI according to TM-30 is a quantitative measure of the ability of the light source showing the object color naturally as it does as daylight reference. Size 1 byte. Default value 100.
    public var colorRenderingIndex: Int
    /// Optional link to emitter in the physical description; use this to define the white light source of a subtractive color mixing system. Starting point: Emitter Collect; Default spectrum is a Black-Body with the defined ColorTemperature.
    public var emitterSpectrum: String? // TODO: should we resolve the link eagerly?
    
    public var children: [Geometry]
}

/// Geometry that describes a media representation layer of a media device.
///
/// This type of geometry is used to describe the layer of a media device that is used for representation of media files (XML node <MediaServerLayer>).
public struct MediaServerLayer: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .mediaServerLayer }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry that describes a camera or output layer of a media device.
///
/// This type of geometry is used to describe the camera or output of a media device (XML node <MediaServerCamera>).
/// The media server camera-view points into the positive Y-direction (and Z-up).
public struct MediaServerCamera: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .mediaServerCamera }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry that describes a master control layer of a media device.
///
/// This type of geometry is used to describe the master control of one or several media devices (XML node <MediaServerMaster>).
public struct MediaServerMaster: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .mediaServerMaster }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}

/// Geometry that describes a surface to display visual media.
///
/// This type of geometry is used to describe a self-emitting surface which is used to display visual media (XML node <Display>).
public struct Display: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .display }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// Name of the mapped texture in Model file that will be swapped out for the media resource.
    public var texture: FileResource?
    
    public var children: [Geometry]
}

/// Reference to already described geometries.
///
/// The Geometry Type Reference is used to describe multiple instances of the same geometry. Example: LED panel with multiple pixels. (XML node ).
/// Note 1: Geometry Reference also allows easier definition of the DMX Channels for these geometries.
public struct GeometryReference: GeometryProtocol, Codable {
    public static var kind: Geometry.Kind { .reference }
    
    enum Child {
        enum Kind {
            case geometry(Geometry.Kind)
            case dmxBreak
            init?(rawValue: String) {
                if rawValue == "Break" {
                    self = .dmxBreak
                } else if let geometry = Geometry.Kind(rawValue: rawValue) {
                    self = .geometry(geometry)
                } else {
                    return nil
                }
            }
        }
        case geometry(Geometry)
        case dmxBreak(DMXBreak)
    }
    
    /// The unique name of the geometry.
    public var name: String
    /// Optional. Link to the corresponding model. The model only replaces the model of the parent of the referenced geometry. The models of the children of the referenced geometry are not affected. The starting point is Models Collect. If model is not set, the model is taken from the referenced geometry.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// Name of the referenced geometry. Only top level geometries are allowed to be referenced.
    /// Note: Should really be non-optional but ~15 GDTFs from GDTF Share currently don't define it. It already prodcues a warning in the GDTF editor so maybe we can revisit this in the future.
    public var geometry: String?
    
    /// As children, the Geometry Type Reference has a list of breaks. The count of the children depends on the number of different breaks in the DMX channels of the referenced geometry. If the referenced geometry, for example, has DMX channels with DMX break 2 and 4, the geometry reference has to have 2 children. The first child with DMX offset for DMX break 2 and the second child for DMX break 4. If one or more of the DMX channels of the referenced geometry have the special value “Overwrite” as a DMX break, the DMX break for those channels and the DMX offsets need to be defined.
    public var dmxBreaks: [DMXBreak]
    
    public var children: [Geometry]
}

/// Geometry with a laser light output.
///
/// This type of geometry is used to describe the position of a laser's light output (XML node <Laser>).
public struct Laser: Codable, GeometryProtocol {
    /// This XML node specifies the protocol for a Laser (XML node <Protocol>).
    // Just `Protocol` isn't working great e.g. [Laser.Protocol]() doesn't work (with or without "`")
    public struct LaserProtocol: Codable {
        /// Name of the protocol
        public var name: String
    }
    
    enum Child {
        enum Kind {
            case geometry(Geometry.Kind)
            case `protocol`
            init?(rawValue: String) {
                if rawValue == "Protocol" {
                    self = .protocol
                } else if let geometry = Geometry.Kind(rawValue: rawValue) {
                    self = .geometry(geometry)
                } else {
                    return nil
                }
            }
        }
        case geometry(Geometry)
        case `protocol`(LaserProtocol)
    }
    public static var kind: Geometry.Kind { .laser }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// Color type of the diode
    public var colorType: ColorType
    /// Optional link to the emitter group. The starting point is the Emitter Collect.
    public var emitter: String?
    
    /// Required if ColorType is "SingleWaveLength"; Unit:nm (nanometers)
    public var color: Double
    /// Output Strength of the Laser; Unit: Watt
    public var outputStrength: Double
    /// Beam diameter where it leaves the projector; Unit: meter
    public var beamDiameter: Double
    /// Minimum beam divergence; Unit: mrad (milliradian)
    public var beamDivergenceMin: Double
    /// Maximum beam divergence; Unit: mrad (milliradian)
    public var beamDivergenceMax: Double
    /// Possible Total Scan Angle Pan of the beam. Assumes symmetrical output; Unit: Degree
    public var scanAnglePan: Double
    /// Possible Total Scan Angle Tilt of the beam. Assumes symmetrical output; Unit: Degree
    public var scanAngleTilt: Double
    /// Speed of the beam; Unit: kilo point per second
    public var scanSpeed: Double

    public var children: [Geometry]
    
    public var protocols: [LaserProtocol]
}

/// Geometry that describes an internal wiring for power or data.
public struct WiringObject: Codable, GeometryProtocol {
    /// This XML node (XML node <PinPatch>) specifies how the different sockets of its parent wiring object are connected to the pins of other wiring objects.
    public struct PinPatch: Codable {
        /// Link to the wiring object connected through this pin patch.
        public var toWiringObject: String
        /// The pin number used by the parent wiring object to connect to the targeted wiring object "ToWiringObject".
        public var fromPin: Int
        /// The pin number used by the targeted wiring object "ToWiringObject" to connect to the parent wiring object.
        public var toPin: Int
        
    }
    
    enum Child {
        enum Kind {
            case geometry(Geometry.Kind)
            case pinPatch
            init?(rawValue: String) {
                if rawValue == "PinPatch" {
                    self = .pinPatch
                } else if let geometry = Geometry.Kind(rawValue: rawValue) {
                    self = .geometry(geometry)
                } else {
                    return nil
                }
            }
        }
        case geometry(Geometry)
        case pinPatch(PinPatch)
    }
    
    public struct Consumer: Codable {
        /// The electrical consumption in Watts. Only for Consumers. Unit: Watt.
        public var electricalPayLoad: Double
        /// The voltage range's maximum value. Only for Consumers. Unit:volt.
        public var voltageRangeMax: Double
        /// The voltage range's minimum value. Only for Consumers. Unit: volt.
        public var voltageRangeMin: Double
        /// The Frequency range's maximum value. Only for Consumers. Unit: hertz.
        public var frequencyRangeMax: Double
        /// The Frequency range's minimum value. Only for Consumers. Unit: hertz.
        public var frequencyRangeMin: Double
        /// The Power Factor of the device. Only for consumers.
        public var cosPhi: Double
    }
    
    public struct PowerSource: Codable {
        /// The maximum electrical payload that this power source can handle. Only for Power Sources. Unit: voltampere.
        public var maxPayLoad: Double
        /// The voltage output that this power source can handle. Only for Power Sources. Unit: volt.
        public var voltage: Double
    }
    
    public struct Fuse: Codable {
        /// The fuse value. Only for fuses. Unit: ampere.
        public var fuseCurrent: Double
        /// Fuse Rating.
        public var fuseRating: FuseRating
    }
    
    public enum Component: Codable {
        /// The type of the electrical component used.
        public enum Kind: String, Codable, Sendable {
            case input = "Input"
            case output = "Output"
            case powerSource = "PowerSource"
            case consumer = "Consumer"
            case fuse = "Fuse"
            case networkProvider = "NetworkProvider"
            case networkInput = "NetworkInput"
            case networkOutput = "NetworkOutput"
            case networkInOut = "NetworkInOut"
        }
        case input
        case output
        case powerSource(PowerSource)
        case consumer(Consumer)
        case fuse(Fuse)
        case networkProvider
        case networkInput
        case networkOutput
        case networkInOut
    }
    
    public static var kind: Geometry.Kind { .wiringObject }
    /// The unique name of the geometry. The name is also the name of the interface to the outside
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// The type of the connector. Find a list of predefined types in Annex D. This is not applicable for Component Types Fuses. Custom type of connector can also be defined, for example "Loose End".
    public var connectorType: String
    /// The type of the electrical component used.
    public var component: Component
    /// The type of the signal used. Predefinded values are "Power", "DMX512", "Protocol", "AES", "AnalogVideo", "AnalogAudio". When you have a custom protocol, you can add it here.
    public var signalType: String
    /// The number of available pins of the connector type to connect internal wiring to it.
    public var pinCount: Int
    /// The layer of the Signal Type. In one device, all wiring geometry that use the same Signal Layers are connected. Special value 0: Connected to all geometries.
    public var signalLayer: Int
    /// Where the pins are placed on the object.
    public var orientation: Orientation
    /// Name of the group to which this wiring object belong.
    public var wireGroup: String

    public var children: [Geometry]
    
    public var pinPatches: [PinPatch]
}

/// Geometry that describes an additional item that can be used for a fixture (like a rain cover).
///
/// This type of geometry is used to describe a geometry used for the inventory (XML node <Inventory>).
public struct Inventory: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .inventory }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// The default count for new objects.
    public var count: Int
    
    public var children: [Geometry]
}

/// Geometry that describes the internal framing of an object (like members).
///
/// This type of geometry is used to describe a structure (XML node <Structure>).
public struct Structure: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .structure }
    /// The type of cross section. Defined values are "TrussFramework", "Tube".
    public enum Kind: String {
        case trussFramework = "TrussFramework"
        case tube = "Tube"
    }
    public struct TrussFramework: Codable {
        /// The name of the truss cross section. Only for Trusses.
        public var trussCrossSection: String
    }
    public struct Tube: Codable {
        /// The height of the cross section. Only for Tubes. Unit: meter.
        public var crossSectionHeight: Double
        /// The thickness of the wall of the cross section. Only for Tubes. Unit: meter.
        public var crossSectionWallThickness: Double
    }
    /// The type of cross section. Defined values are "TrussFramework", "Tube".
    public enum CrossSectionType: Codable {
        /// The type of cross section. Defined values are "TrussFramework", "Tube".
        public enum Kind: String {
            case trussFramework = "TrussFramework"
            case tube = "Tube"
        }
        case trussFramework(TrussFramework)
        case tube(Tube)
    }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// The linked geometry.
    public var linkedGeometry: String
    /// The type of structure.
    public var structureType: StructureType
    /// The type of cross section.
    public var crossSectionType: CrossSectionType
    
    public var children: [Geometry]
}




/// Geometry that describes a support like a base plate or a hoist.
public struct Support: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .support }
    
    public struct Rope: Codable {
        /// The name of the rope cross section. Only for Ropes.
        public var ropeCrossSection: String
        /// The Offset of the rope from bottom to top. Only for Ropes. Unit: meter.
        public var ropeOffset: Vector3
    }
    
    public struct GroundSupport: Codable {
        /// The compression ratio for this support along the X-Axis. Unit N/m. Only for Ground Supports.
        public var resistanceX: Double
        /// The compression ratio for this support along the Y-Axis. Unit N/m. Only for Ground Supports.
        public var resistanceY: Double
        /// The compression ratio for this support along the Z-Axis. Unit N/m. Only for Ground Supports.
        public var resistanceZ: Double
        /// The compression ratio for this support around the X-Axis. Unit N/m. Only for Ground Supports.
        public var resistanceXX: Double
        /// The compression ratio for this support around the Y-Axis. Unit N/m. Only for Ground Supports.
        public var resistanceYY: Double
        /// The compression ratio for this support around the Z-Axis. Unit N/m. Only for Ground Supports.
        public var resistanceZZ: Double
    }
    
    public enum SupportType: Codable {
        public enum Kind: String {
            case rope = "Rope"
            case groundSupport = "GroundSupport"
        }
        case rope(Rope)
        case groundSupport(GroundSupport)
    }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    /// The type of support. Defined values are "Rope", "GroundSupport".
    public var supportType: SupportType
    
    /// The allowable force on the X-Axis applied to the object according to the Eurocode. Unit: N.
    public var capacityX: Double
    /// The allowable force on the Y-Axis applied to the object according to the Eurocode. Unit: N.
    public var capacityY: Double
    /// The allowable force on the Z-Axis applied to the object according to the Eurocode. Unit: N.
    public var capacityZ: Double
    /// The allowable moment around the X-Axis applied to the object according to the Eurocode. Unit: N/m.
    public var capacityXX: Double
    /// The allowable moment around the Y-Axis applied to the object according to the Eurocode. Unit: N/m.
    public var capacityYY: Double
    /// The allowable moment around the Z-Axis applied to the object according to the Eurocode. Unit: N/m.
    public var capacityZZ: Double
    
    public var children: [Geometry]
}

/// Geometry that describes a point where other geometries should be attached.
///
/// This type of geometry is used to describe a magnet, a point where other geometries should be attached (XML node <Magnet>).
public struct Magnet: Codable, GeometryProtocol {
    public static var kind: Geometry.Kind { .magnet }
    /// The unique name of the geometry.
    public var name: String
    /// Link to the corresponding model.
    public var model: String?
    /// Relative position of geometry; Default value: Identity Matrix
    public var position: Matrix
    
    public var children: [Geometry]
}
