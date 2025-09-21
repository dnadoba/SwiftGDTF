//
//  Types.swift
//  
//
//  Created by Brandon Wees on 7/2/24.
//

import Foundation
import ZIPFoundation

public enum PhysicalUnit: String, Codable {
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
}

public enum SubPhysicalType: String, Codable {
    case placementOffset = "PlacementOffset"
    case amplitude = "Amplitude"
    case amplitudeMin = "AmplitudeMin"
    case amplitudeMax = "AmplitudeMax"
    case duration = "Duration"
    case dutyCycle = "DutyCycle"
    case timeOffset = "TimeOffset"
    case minimumOpening = "MinimumOpening"
    case value = "Value"
    case ratioHorizontal = "RatioHorizontal"
    case ratioVertical = "RatioVertical"
}

public enum InterpolationTo: String, Codable {
    case linear = "Linear"
    case step = "Step"
    case log = "Log"
}

public enum ColorSpaceMode: String, Codable {
    case custom = "Custom"
    case srgb = "sRGB"
    case proPhoto = "ProPhoto"
    case ansi = "ANSI"
}

public enum PrimitiveType: String, Codable {
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
}

public enum LampType: String, Codable {
    case discharge = "Discharge"
    case tungsten = "Tungsten"
    case halogen = "Halogen"
    case led = "LED"
}

public enum ColorType: String, Codable {
    case rgb = "RGB"
    case singleWaveLength = "SingleWaveLength"
}

public enum FuseRating: String, Codable {
    case b = "B"
    case c = "C"
    case d = "D"
    case k = "K"
    case z = "Z"
}

public enum Orientation: String, Codable {
    case left = "Left"
    case right = "Right"
    case top = "Top"
    case bottom = "Bottom"
}

public enum ComponentType: String, Codable {
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

public enum BeamType: String, Codable {
    case wash = "Wash"
    case spot = "Spot"
    case none = "None"
    case rectangle = "Rectangle"
    case pc = "PC"
    case fresnel = "Fresnel"
    case glow = "Glow"
}

public enum Snap: String, Codable {
    case yes = "Yes"
    case no = "No"
    case on = "On"
    case off = "Off"
}

public enum Master: String, Codable {
    case none = "None"
    case grand = "Grand"
    case group = "Group"
}

public enum DmxInvert: String, Codable {
    case yes = "Yes"
    case no = "No"
}

public enum RelationType: String, Codable {
    case multiply = "Multiply"
    case override = "Override"
}

public struct DMXAddress: Codable {
    public var universe: Int
    public var address: Int
}

extension DMXAddress {
    init(from rawValue: String) {
        if rawValue.contains(".") {
            let split: [Int] = rawValue.split(separator: ".").map { Int($0) ?? 0 }
            self.universe = split[0]
            self.address = split[1]
        } else {
            self.universe = 1
            self.address = Int(rawValue) ?? 0
        }
    }
}

public struct DMXValue: Codable {
    public var value: Int
    public var byteCount: Int
    
    public var maxValue: Int {
        return Int(powl(2, 8*Double(byteCount))) - 1
    }
    
    public var bytes: [UInt8] {
        var result: [UInt8] = []
        for i in 0..<byteCount {
            // Shift the number to the right by (byteDepth - 1 - i) * 8 bits and mask the lower 8 bits
            let shiftAmount = (byteCount - 1 - i) * 8
            let byte = UInt8((value >> shiftAmount) & 0xFF)
            result.append(byte)
        }
        
        return result
    }
}

public extension DMXValue {
    init(_ percentage: Double, byteCount: Int) {
        let maxValue = powl(2, 8*Double(byteCount)) - 1

        self.init(value: Int(percentage.constrain(min: 0, max: 1) * maxValue), byteCount: byteCount)
    }

    init(from rawValue: String) {
        let split: [Int] = rawValue.split(separator: "/").map { Int($0) ?? 0 }
        self.init(value: split[0], byteCount: split[1])
    }
}

public struct ColorCIE: Codable {
    public var x: Double
    public var y: Double
    public var Y: Double
    
    public init(x: Double, y: Double, Y: Double) {
        self.x = x
        self.y = y
        self.Y = Y
    }
}

extension ColorCIE {
    init(from rawValue: String) {        
        let split: [Double] = rawValue.split(separator: ",").map { Double($0) ?? 0 }
        
        self.x = split[0]
        self.y = split[1]
        
        if (split.count == 3) {
            self.Y = split[2] > 1 ? split[2] / 100 : split[2]
        } else {
            self.Y = 1.0
        }
    }
}

public struct Rotation: Codable {
    public var matrix: [[Double]]
}

extension Rotation {
    init(from rawValue: String) {
        var strMatrix = rawValue
        strMatrix = strMatrix.replacingOccurrences(of: "}{", with: ",")
        strMatrix = strMatrix.replacingOccurrences(of: "{", with: "")
        strMatrix = strMatrix.replacingOccurrences(of: "}", with: "")
        
        let flatMatrix: [Double] = strMatrix.split(separator: ",").map{ Double($0) ?? 0 }
        assert(flatMatrix.count == 9)

        /// convert 1D array into 3x3 2D array (matrix)
        let matrix: [[Double]] = stride(from: 0, to: flatMatrix.count,by: 3)
                                    .map{ Array(flatMatrix[$0..<$0 + 3]) }
        
        self.matrix = matrix
    }
}

public struct Matrix: Codable {
    public var matrix: [[Double]] = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1],
    ]
}

extension Matrix {
    init(from rawValue: String) {
        var strMatrix = rawValue
        strMatrix = strMatrix.replacingOccurrences(of: "}{", with: ",")
        strMatrix = strMatrix.replacingOccurrences(of: "{", with: "")
        strMatrix = strMatrix.replacingOccurrences(of: "}", with: "")
        
        let flatMatrix: [Double] = strMatrix.split(separator: ",").map{ Double($0) ?? 0 }
        assert(flatMatrix.count == 16)
        
        /// convert 1D array into 3x3 2D array (matrix)
        let matrix: [[Double]] = stride(from: 0, to: flatMatrix.count,by: 4)
                                    .map{ Array(flatMatrix[$0..<$0 + 4]) }
        
        self.matrix = matrix
    }
}

public struct FileResource: Codable {
    public var name: String
    public var fileExtension: String
    
    init?(name: String?, fileExtension: String) {
        guard let name = name, !name.isEmpty else {
            return nil
        }
        
        self.name = name
        self.fileExtension = fileExtension
    }
    
    init?(filename name: String?) {
        guard let name = name, !name.isEmpty else {
            return nil
        }

        let url = URL(fileURLWithPath: name)
        
        self.name = url.deletingPathExtension().lastPathComponent
        self.fileExtension = url.pathExtension
    }
    
    public var filename: String {
        return "\(name).\(fileExtension)"
    }
    
    public func resolve(gdtf: Data) -> Data? {
        do {
            let zipArchive = try Archive(data: gdtf, accessMode: .read)
            
            /// Verify a description.xml file was found, otherwise invalid GDTF
            guard let entry = zipArchive[filename] else {
                return nil
            }
            
            /// Make buffer to append extracted ZIP data
            var xmlData = Data()

            /// Extract the data into data buffer
            _ = try zipArchive.extract(entry) { data in
                xmlData.append(data)
            }
            
            return xmlData
        } catch {
            return nil
        }
    }
    enum ExtractError: Error {
        case doesNotExist(filename: String)
    }
    public func extract(from gdtf: URL, to destination: URL) throws {
        let zipArchive = try Archive(url: gdtf, accessMode: .read)

        /// Verify a description.xml file was found, otherwise invalid GDTF
        guard let entry = zipArchive[filename] else {
            throw ExtractError.doesNotExist(filename: filename)
        }

        /// Make buffer to append extracted ZIP data
        _ = try zipArchive.extract(entry, to: destination)
    }
}

//
// SwiftGDTF Specfic Types
//

/// Errors related to parsing GDTF data
public enum GDTFError: Error {
    case invalidGDTF
    case invalidGDTFDescription
    case dmxModeNotFound
    case fileResourceNotFound(String)
}

public struct FixturePackage {
    public var info: FixtureInfo
    public var mode: DMXMode
    public var fileResources: [String:Data]
}

// includes only basic information about a DMXMode
public struct HighLevelMode {
    public var name: String
    public var description: String
    public var footprint: UInt
}

/// Includes basica info about a fixture, useful when showing a list of all fixtures in a patch window
public struct FixtureDetails {
    public var info: FixtureInfo
    public var modes: [HighLevelMode]
}
