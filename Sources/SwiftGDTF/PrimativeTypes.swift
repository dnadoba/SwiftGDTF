//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/2/24.
//

import Foundation

public enum PhysicalUnit: String {
    case none = "None"
    case percent = "Percent"
    case length = "Length"
    case mass = "Mass"
    case time = "Time"
    case temperature = "Temperature"
    case luminousIntensity = "LuminousIntensity"
    case angle = "Angle"
    case force = "Force"
    case frequency = "Frequency"
    case current = "Current"
    case voltage = "Voltage"
    case power = "Power"
    case energy = "Energy"
    case area = "Area"
    case volume = "Volume"
    case speed = "Speed"
    case acceleration = "Acceleration"
    case angularSpeed = "AngularSpeed"
    case angularAcc = "AngularAcc"
    case waveLength = "WaveLength"
    case colorComponent = "ColorComponent"
    
    static func fromString(_ rawValue: String) -> PhysicalUnit {
        return PhysicalUnit(rawValue: rawValue) ?? .none
    }
}

public enum InterpolationTo: String {
    case linear = "Linear"
    case step = "Step"
    case log = "Log"
    
    static func fromString(_ rawValue: String) -> InterpolationTo {
        return InterpolationTo(rawValue: rawValue) ?? .linear
    }
}

public enum ColorSpaceMode: String {
    case custom = "Custom"
    case srgb = "sRGB"
    case proPhoto = "ProPhoto"
    case ansi = "ANSI"
    
    static func fromString(_ rawValue: String) -> ColorSpaceMode {
        return ColorSpaceMode(rawValue: rawValue) ?? .srgb
    }
}

public enum CES: String {
    case ces01 = "CES01"
    case ces02 = "CES02"
    case ces03 = "CES03"
    // Continue for all values up to CES99
    case ces99 = "CES99"
    
    static func fromString(_ rawValue: String) -> CES {
        return CES(rawValue: rawValue) ?? .ces01
    }
}

public enum PrimitiveType: String {
    case undefined = "Undefined"
    case cube = "Cube"
    case cylinder = "Cylinder"
    case sphere = "Sphere"
    case base = "Base"
    case yoke = "Yoke"
    case head = "Head"
    case scanner = "Scanner"
    case conventional = "Conventional"
    case pigtail = "Pigtail"
    case base1_1 = "Base1_1"
    case scanner1_1 = "Scanner1_1"
    case conventional1_1 = "Conventional1_1"
    
    static func fromString(_ rawValue: String) -> PrimitiveType {
        return PrimitiveType(rawValue: rawValue) ?? .undefined
    }
}

public enum LampType: String {
    case discharge = "Discharge"
    case tungsten = "Tungsten"
    case halogen = "Halogen"
    case led = "LED"
    
    static func fromString(_ rawValue: String) -> LampType {
        return LampType(rawValue: rawValue) ?? .discharge
    }
}

public enum ColorType: String {
    case rgb = "RGB"
    case singleWaveLength = "SingleWaveLength"
    
    static func fromString(_ rawValue: String) -> ColorType {
        return ColorType(rawValue: rawValue) ?? .rgb
    }
}

public enum FuseRating: String {
    case b = "B"
    case c = "C"
    case d = "D"
    case k = "K"
    case z = "Z"
    
    static func fromString(_ rawValue: String) -> FuseRating {
        return FuseRating(rawValue: rawValue) ?? .b
    }
}

public enum Orientation: String {
    case left = "Left"
    case right = "Right"
    case top = "Top"
    case bottom = "Bottom"
    
    static func fromString(_ rawValue: String) -> Orientation {
        return Orientation(rawValue: rawValue) ?? .left
    }
}

public enum ComponentType: String {
    case input = "Input"
    case output = "Output"
    case powerSource = "PowerSource"
    case consumer = "Consumer"
    case fuse = "Fuse"
    case networkProvider = "NetworkProvider"
    case networkInput = "NetworkInput"
    case networkOutput = "NetworkOutput"
    case networkInOut = "NetworkInOut"
    
    static func fromString(_ rawValue: String) -> ComponentType {
        return ComponentType(rawValue: rawValue) ?? .input
    }
}

public enum BeamType: String {
    case wash = "Wash"
    case spot = "Spot"
    case none = "None"
    case rectangle = "Rectangle"
    case pc = "PC"
    case fresnel = "Fresnel"
    case glow = "Glow"
    
    static func fromString(_ rawValue: String) -> BeamType {
        return BeamType(rawValue: rawValue) ?? .wash
    }
}

public enum Snap: String {
    case yes = "Yes"
    case no = "No"
    case on = "On"
    case off = "Off"
    
    static func fromString(_ rawValue: String) -> Snap {
        return Snap(rawValue: rawValue) ?? .no
    }
}

public enum Master: String {
    case none = "None"
    case grand = "Grand"
    case group = "Group"
    
    static func fromString(_ rawValue: String) -> Master {
        return Master(rawValue: rawValue) ?? .none
    }
}

public enum DmxInvert: String {
    case yes = "Yes"
    case no = "No"
    
    static func fromString(_ rawValue: String) -> DmxInvert {
        return DmxInvert(rawValue: rawValue) ?? .no
    }
}

public enum RelationType: String {
    case multiply = "Multiply"
    case override = "Override"
}

public struct Resource {
    var name: String = ""
    var extenstion: String
}

public struct DMXAddress {
    var universe: Int
    var address: Int
    
    static func fromString(_ rawValue: String) -> DMXAddress {
        if rawValue.contains(".") {
            let split: [Int] = rawValue.split(separator: ".").map { Int($0)! }
            return DMXAddress(universe: split[0], address: split[1])
        }
        
        return DMXAddress(universe: 1, address: Int(rawValue)!)
    }
}

public struct DMXValue {
    var value: Int
    var byteCount: Int
    
    static func fromString(_ rawValue: String) -> DMXValue {
        let split: [Int] = rawValue.split(separator: "/").map { Int($0)! }
        
        return DMXValue(value: split[0], byteCount: split[1])
    }
}

public struct ColorCIE {
    var x: Float?
    var y: Float?
    var Y: Float?
    
    static func fromString(_ rawValue: String) -> ColorCIE {
        let split: [Float] = rawValue.split(separator: ",").map { Float($0)! }
        
        // if we do not have all values, return white
        if split.count != 3 { return ColorCIE(x: 0.3127, y: 0.3290, Y: 100) }
            
        return ColorCIE(x: split[safe: 0], y: split[safe: 1], Y: split[safe: 2])
    }
}

public struct Rotation {
    var matrix: [[Float]]
    
    static func fromString(_ rawValue: String) -> Rotation {
        var strMatrix = rawValue
        strMatrix = strMatrix.replacingOccurrences(of: "}{", with: ",")
        strMatrix = strMatrix.replacingOccurrences(of: "{", with: "")
        strMatrix = strMatrix.replacingOccurrences(of: "}", with: "")
        
        let flatMatrix: [Float] = strMatrix.split(separator: ",").map{ Float($0)! }
        assert(flatMatrix.count == 9)

        /// convert 1D array into 3x3 2D array (matrix)
        let matrix: [[Float]] = stride(from: 0, to: flatMatrix.count,by: 3)
                                    .map{ Array(flatMatrix[$0..<$0 + 3]) }
        
        return Rotation(matrix: matrix)
    }
}

public struct Matrix {
    var matrix: [[Float]] = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1],
    ]
    
    static func fromString(_ rawValue: String) -> Matrix {
        var strMatrix = rawValue
        strMatrix = strMatrix.replacingOccurrences(of: "}{", with: ",")
        strMatrix = strMatrix.replacingOccurrences(of: "{", with: "")
        strMatrix = strMatrix.replacingOccurrences(of: "}", with: "")
        
        let flatMatrix: [Float] = strMatrix.split(separator: ",").map{ Float($0)! }
        assert(flatMatrix.count == 16)
        
        /// convert 1D array into 3x3 2D array (matrix)
        let matrix: [[Float]] = stride(from: 0, to: flatMatrix.count,by: 4)
                                    .map{ Array(flatMatrix[$0..<$0 + 4]) }
        
        return Matrix(matrix: matrix)
    }
}

public struct NodeLink {
    var start_point: String
    var path: [String]
}

public struct ColorSpaceDefinition {
    var r: ColorCIE
    var g: ColorCIE
    var b: ColorCIE
    var w: ColorCIE
}

public struct ThumbnailOffset {
    var x: Int
    var y: Int
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
