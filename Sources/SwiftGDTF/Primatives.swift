//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/2/24.
//

import Foundation

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
    case no = "No"
    case yes = "Yes"
    case off = "Off"
    case on = "On"
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
