//
//  GDTF.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation
import SWXMLHash

/// This is used to show a String that maps to a node that we cannot currently process
/// (usually because it results in a recursive type)
public typealias Node = String

public struct GDTF: Codable {
    public struct ID: Hashable, Codable, Sendable, Comparable, CustomStringConvertible, RawRepresentable {
        public static func <(lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public init(from decoder: any Decoder) throws {
            rawValue = try decoder.singleValueContainer().decode(Int.self)
        }
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
        public var rawValue: Int
        public var description: String {
            rawValue.description
        }
    }
    public var dataVersion: String
    public var fixtureType: FixtureType
}

public struct FixtureType: Codable {
    public var name: String
    public var shortName: String
    public var longName: String
    public var longNameOrFallback: String {
        if longName.isEmpty {
            if name.isEmpty {
                return shortName
            } else {
                return name
            }
        } else {
            return longName
        }
    }
    public var manufacturer: String
    public var description: String
    public var fixtureTypeID: UUID
    public var refFT: String?
    public var thumbnail: FileResource?
    public var thumbnailVector: FileResource?

    public var attributeDefinitions: AttributeDefinitions
    public var wheels: [Wheel]
    public var physicalDescriptions: PhysicalDescriptions?
    public var dmxModes: [DMXMode]
}

// this is an identical copy to FixtureType but only includes top level attributes
public struct FixtureInfo: Codable {
    public var name: String
    public var shortName: String
    public var longName: String
    public var manufacturer: String
    public var description: String
    public var fixtureTypeID: String
    public var refFT: String?
    public var thumbnail: FileResource?
}

///
/// AttributeDefinitions Schema
///

public struct AttributeDefinitions: Codable {
    public var activationGroups: [ActivationGroup]?
    public var featureGroups: [FeatureGroup]
    public var attributes: [FixtureAttribute]
}

public struct ActivationGroup: Codable {
    public var name: String
}

public struct FeatureGroup: Codable {
    public var name: String
    public var pretty: String
    
    public var features: [Feature]
}

public struct Feature: Codable {
    public var name: String
}

public struct FixtureAttribute: Codable {
    public var name: String
    public var type: AttributeType
    public var pretty: String
    public var activationGroup: ActivationGroup?
    public var feature: Feature?
    
    // This is a node but results in recursive type
    public var mainAttribute: Node?
    
    public var physicalUnit: PhysicalUnit = .none
    public var color: ColorCIE?
    
    public var subPhysicalUnits: [SubPhysicalUnit] = []
}

public struct SubPhysicalUnit: Codable {
    public var type: SubPhysicalType
    public var physicalUnit: PhysicalUnit = .none
    public var physicalFrom: Double = 0
    public var physicalTo: Double = 1
}

///
/// Wheels Schema
///

public struct Wheel: Codable {
    public var name: String
    public var slots: [Slot]
}

public struct Slot: Codable {
    public var name: String
    public var color: ColorCIE
    public var filter: Filter?
    public var mediaFileName: FileResource?
    public var slotIndex: Int
    
    public var facets: [PrismFacet]
    public var animationSystem: AnimationSystem?
}

public struct PrismFacet: Codable {
    public var color: ColorCIE
    public var rotation: Rotation
}

public struct AnimationSystem: Codable {
    public var p1: [Double]
    public var p2: [Double]
    public var p3: [Double]
    
    public var radius: Double
}

///
/// Physical Description Schema
///

public struct PhysicalDescriptions: Codable {
    public var emitters: [Emitter]
    public var filters: [Filter]
    public var colorSpace: ColorSpace?
    public var additionalColorSpaces: [ColorSpace]
    public var dmxProfiles: [DMXProfile]
    public var properties: Properties?
}

public struct Emitter: Codable {
    public var name: String
    public var color: ColorCIE?
    public var dominantWavelength: Double?
    public var diodePart: String?    
}

public struct GDTFMeasurement: Codable {
    public var physical: Double
    public var luminousIntensity: Double?
    public var transmission: Double?
    public var interpolationTo: InterpolationTo
    
    public var measurements: [MeasurementPoint]
}

public struct MeasurementPoint: Codable {
    public var wavelength: Double
    public var energy: Double
}

public struct Filter: Codable {
    public var name: String
    public var color: ColorCIE
    
    public var measurements: [GDTFMeasurement]
}

public struct ColorSpace: Codable {
    public var name: String
    public var mode: ColorSpaceMode
    
    // Only used when mode is .custom
    public var red: ColorCIE?
    public var green: ColorCIE?
    public var blue: ColorCIE?
    public var whitePoint: ColorCIE?
}

public struct DMXProfile: Codable {
    public var name: String
    public var points: [Point]
}

public struct Point: Codable {
    public var dmxPercentage: Double
    public var cfc0: Double
    public var cfc1: Double
    public var cfc2: Double
    public var cfc3: Double
}

public struct Properties: Codable {
    public var operatingTemp: OperatingTemp
    public var weight: Double
    public var legHeight: Double
}

public struct OperatingTemp: Codable {
    public var low: Double
    public var high: Double
}

///
/// DMX Mode Schema
///

public struct DMXMode: Codable {
    public var name: String
    public var description: String
    
    public var channels: [DMXChannel]
    public var relations: [Relation]
    public var macros: [Macro]

    public func maxOffset() -> Int? {
        channels.lazy.map { $0.offset.max() ?? 0 }.max()
    }
}

public struct DMXChannel: Codable {
    public var name: String?
    public var dmxBreak: Int
    public var offset: [Int]
    public var initialFunction: ChannelFunction?
    public var highlight: DMXValue?
    
    public var logicalChannels: [LogicalChannel]
    public var geometry: String
}

public struct LogicalChannel: Codable {
    public var attribute: FixtureAttribute
    public var snap: Snap
    public var master: Master
    public var mibFade: Double
    public var dmxChangeTimeLimit: Double
    
    public var channelFunctions: [ChannelFunction]
}

public struct ChannelFunction: Codable {
    public var name: String
    public var attribute: FixtureAttribute?
    public var originalAttribute: String
    public var dmxFrom: DMXValue
    public var dmxDefault: DMXValue
    public var physicalFrom: Double
    public var physicalTo: Double
    public var realFade: Double
    public var realAcceleration: Double
    
    public var wheel: Wheel?
    public var emitter: Emitter?
    public var filter: Filter?
    public var colorSpace: ColorSpace?
    
    // modeMaster is a node but can have multiple types
    // wil revisit this later
    public var modeMaster: Node?
    public var modeFrom: DMXValue?
    public var modeTo: DMXValue?
    
    public var dmxProfile: DMXProfile?
    
    public var minimum: Double
    public var maximum: Double
    public var customName: String?
    
    public var channelSets: [ChannelSet]
    public var subChannelSets: [SubChannelSet]
}

public struct ChannelSet: Codable {
    public var name: String
    public var dmxFrom: DMXValue
    public var physicalFrom: Double
    public var physicalTo: Double
    public var wheelSlotIndex: Int?
}

public struct SubChannelSet: Codable {
    public var name: String
    public var physicalFrom: Double
    public var physicalTo: Double
    public var subPhysicalUnit: SubPhysicalUnit
    public var wheelSlotIndex: Int?
    public var dmxProfile: DMXProfile?
}

public struct Relation: Codable {
    public var name: String
    public var master: DMXChannel
    public var follower: ChannelFunction
    public var type: RelationType
}

public struct Macro: Codable {
    public var name: String
    public var channelFunction: ChannelFunction?
    
    public var steps: [MacroStep]
}

public struct MacroStep: Codable {
    public var duration: Double
    public var values: [MacroValue]
}

public struct MacroValue: Codable {
    public var value: DMXValue
    public var dmxChannel: DMXChannel
}

// see Annex A: https://github.com/mvrdevelopment/spec/blob/main/gdtf-spec.md#annex-a-normative-attribute-definitions
public enum AttributeType: Hashable, Codable, CustomStringConvertible, Sendable {

    /// Canonical representation of AttributeType cases without associated values (except custom)
    public enum Canonical: Hashable, Codable, Sendable, CodingKeyRepresentable {
        public static let allCases: [Self] = [
            .dimmer,
            .pan,
            .tilt,
            .panRotate,
            .tiltRotate,
            .positionEffect,
            .positionEffectRate,
            .positionEffectFade,
            .xyzX,
            .xyzY,
            .xyzZ,
            .rotationX,
            .rotationY,
            .rotationZ,
            .scaleX,
            .scaleY,
            .scaleZ,
            .scaleXYZ,
            .gobo,
            .goboSelectSpin,
            .goboSelectShake,
            .goboSelectEffects,
            .goboWheelIndex,
            .goboWheelSpin,
            .goboWheelShake,
            .goboWheelRandom,
            .goboWheelAudio,
            .goboPosition,
            .goboPositionRotate,
            .goboPositionShake,
            .animationWheel,
            .animationWheelAudio,
            .animationWheelMacro,
            .animationWheelRandom,
            .animationWheelSelectEffects,
            .animationWheelSelectShake,
            .animationWheelSelectSpin,
            .animationWheelPosition,
            .animationWheelPositionRotate,
            .animationWheelPositionShake,
            .animationSystem,
            .animationSystemRamp,
            .animationSystemShake,
            .animationSystemAudio,
            .animationSystemRandom,
            .animationSystemPosition,
            .animationSystemPositionRotate,
            .animationSystemPositionShake,
            .animationSystemPositionRandom,
            .animationSystemPositionAudio,
            .animationSystemMacro,
            .mediaFolder,
            .mediaContent,
            .modelFolder,
            .modelContent,
            .playMode,
            .playBegin,
            .playEnd,
            .playSpeed,
            .colorEffects,
            .color,
            .colorWheelIndex,
            .colorWheelSpin,
            .colorWheelRandom,
            .colorWheelAudio,
            .colorAddRed,
            .colorAddGreen,
            .colorAddBlue,
            .colorAddCyan,
            .colorAddMagenta,
            .colorAddYellow,
            .colorAddRedYellow,
            .colorAddGreenYellow,
            .colorAddGreenCyan,
            .colorAddBlueCyan,
            .colorAddBlueMagenta,
            .colorAddRedMagenta,
            .colorAddWhite,
            .colorAddWarmWhite,
            .colorAddCoolWhite,
            .colorAddUltraviolet,
            .colorSubtractRed,
            .colorSubtractGreen,
            .colorSubtractBlue,
            .colorSubtractCyan,
            .colorSubtractMagenta,
            .colorSubtractYellow,
            .colorMacro,
            .colorMacroRate,
            .colorTemperatureOrange,
            .colorTemperatureCorrection,
            .colorTemperatureBlue,
            .tint,
            .hueShiftBlueHue,
            .hueShiftBlueSaturation,
            .hueShiftBlueBrightness,
            .hueShiftBlueQuality,
            .chromaticityX,
            .chromaticityY,
            .chromaticityBrightness,
            .colorRGBRed,
            .colorRGBGreen,
            .colorRGBBlue,
            .colorRGBCyan,
            .colorRGBMagenta,
            .colorRGBYellow,
            .colorRGBQuality,
            .videoBoostRed,
            .videoBoostGreen,
            .videoBoostBlue,
            .videoHueShift,
            .videoSaturation,
            .videoBrightness,
            .videoContrast,
            .videoKeyColorRed,
            .videoKeyColorGreen,
            .videoKeyColorBlue,
            .videoKeyIntensity,
            .videoKeyTolerance,
            .strobeDuration,
            .strobeRate,
            .strobeFrequency,
            .strobeModeShutter,
            .strobeModeStrobe,
            .strobeModePulse,
            .strobeModePulseOpen,
            .strobeModePulseClose,
            .strobeModeRandom,
            .strobeModeRandomPulse,
            .strobeModeRandomPulseOpen,
            .strobeModeRandomPulseClose,
            .strobeModeEffect,
            .shutter,
            .shutterStrobe,
            .shutterStrobePulse,
            .shutterStrobePulseClose,
            .shutterStrobePulseOpen,
            .shutterStrobeRandom,
            .shutterStrobeRandomPulse,
            .shutterStrobeRandomPulseClose,
            .shutterStrobeRandomPulseOpen,
            .shutterStrobeEffect,
            .iris,
            .irisStrobe,
            .irisStrobeRandom,
            .irisPulseClose,
            .irisPulseOpen,
            .irisRandomPulseClose,
            .irisRandomPulseOpen,
            .frost,
            .frostPulseOpen,
            .frostPulseClose,
            .frostRamp,
            .prism,
            .prismSelectSpin,
            .prismMacro,
            .prismPosition,
            .prismPositionRotate,
            .effects,
            .effectsRate,
            .effectsFade,
            .effectsAdjust,
            .effectsPosition,
            .effectsPositionRotate,
            .effectsSync,
            .beamShaper,
            .beamShaperMacro,
            .beamShaperPosition,
            .beamShaperPositionRotate,
            .zoom,
            .zoomModeSpot,
            .zoomModeBeam,
            .digitalZoom,
            .focus,
            .focusAdjust,
            .focusDistance,
            .control,
            .dimmerMode,
            .dimmerCurve,
            .blackoutMode,
            .ledFrequency,
            .ledZoneMode,
            .pixelMode,
            .panMode,
            .tiltMode,
            .panTiltMode,
            .positionModes,
            .goboWheelMode,
            .goboWheelShortcutMode,
            .animationWheelMode,
            .animationWheelShortcutMode,
            .colorMode,
            .colorWheelShortcutMode,
            .cyanMode,
            .magentaMode,
            .yellowMode,
            .colorMixMode,
            .chromaticMode,
            .colorCalibrationMode,
            .colorConsistency,
            .colorControl,
            .colorModelMode,
            .colorSettingsReset,
            .colorUniformity,
            .colorRenderingIndexMode,
            .customColor,
            .ultravioletStability,
            .wavelengthCorrection,
            .whiteCount,
            .strobeMode,
            .zoomMode,
            .focusMode,
            .irisMode,
            .fanMode,
            .followSpotMode,
            .beamEffectIndexRotateMode,
            .intensityMovementSpeed,
            .positionMovementSpeed,
            .colorMixMovementSpeed,
            .colorWheelSelectMovementSpeed,
            .goboWheelMovementSpeed,
            .irisMovementSpeed,
            .prismMovementSpeed,
            .focusMovementSpeed,
            .frostMovementSpeed,
            .zoomMovementSpeed,
            .frameMovementSpeed,
            .globalMovementSpeed,
            .reflectorAdjust,
            .fixtureGlobalReset,
            .dimmerReset,
            .shutterReset,
            .beamReset,
            .colorMixReset,
            .colorWheelReset,
            .focusReset,
            .frameReset,
            .goboWheelReset,
            .intensityReset,
            .irisReset,
            .positionReset,
            .panReset,
            .tiltReset,
            .zoomReset,
            .colorTemperatureBlueReset,
            .colorTemperatureOrangeReset,
            .colorTemperatureCorrectionReset,
            .animationSystemReset,
            .fixtureCalibrationReset,
            .function,
            .lampControl,
            .displayIntensity,
            .dmxInput,
            .noFeature,
            .dummy,
            .blower,
            .fan,
            .fog,
            .haze,
            .lampPowerMode,
            .fans,
            .bladeA,
            .bladeB,
            .bladeRotation,
            .shaperRotation,
            .shaperMacros,
            .shaperMacrosSpeed,
            .bladeSoftA,
            .bladeSoftB,
            .keystoneA,
            .keystoneB,
            .video,
            .videoEffectType,
            .videoEffectParameter,
            .videoCamera,
            .videoSoundVolume,
            .videoBlendMode,
            .inputSource,
            .fieldOfView,
        ]
        public var codingKey: any CodingKey {
            fatalError("encoding currently not supported")
        }

        public init?<T>(codingKey: T) where T : CodingKey {
            self.init(name: codingKey.stringValue)
        }

        case dimmer
        case pan
        case tilt
        case panRotate
        case tiltRotate
        case positionEffect
        case positionEffectRate
        case positionEffectFade
        case xyzX
        case xyzY
        case xyzZ
        case rotationX
        case rotationY
        case rotationZ
        case scaleX
        case scaleY
        case scaleZ
        case scaleXYZ
        case gobo
        case goboSelectSpin
        case goboSelectShake
        case goboSelectEffects
        case goboWheelIndex
        case goboWheelSpin
        case goboWheelShake
        case goboWheelRandom
        case goboWheelAudio
        case goboPosition
        case goboPositionRotate
        case goboPositionShake
        case animationWheel
        case animationWheelAudio
        case animationWheelMacro
        case animationWheelRandom
        case animationWheelSelectEffects
        case animationWheelSelectShake
        case animationWheelSelectSpin
        case animationWheelPosition
        case animationWheelPositionRotate
        case animationWheelPositionShake
        case animationSystem
        case animationSystemRamp
        case animationSystemShake
        case animationSystemAudio
        case animationSystemRandom
        case animationSystemPosition
        case animationSystemPositionRotate
        case animationSystemPositionShake
        case animationSystemPositionRandom
        case animationSystemPositionAudio
        case animationSystemMacro
        case mediaFolder
        case mediaContent
        case modelFolder
        case modelContent
        case playMode
        case playBegin
        case playEnd
        case playSpeed
        case colorEffects
        case color
        case colorWheelIndex
        case colorWheelSpin
        case colorWheelRandom
        case colorWheelAudio
        case colorAddRed
        case colorAddGreen
        case colorAddBlue
        case colorAddCyan
        case colorAddMagenta
        case colorAddYellow
        case colorAddRedYellow
        case colorAddGreenYellow
        case colorAddGreenCyan
        case colorAddBlueCyan
        case colorAddBlueMagenta
        case colorAddRedMagenta
        case colorAddWhite
        case colorAddWarmWhite
        case colorAddCoolWhite
        case colorAddUltraviolet
        case colorSubtractRed
        case colorSubtractGreen
        case colorSubtractBlue
        case colorSubtractCyan
        case colorSubtractMagenta
        case colorSubtractYellow
        case colorMacro
        case colorMacroRate
        case colorTemperatureOrange
        case colorTemperatureCorrection
        case colorTemperatureBlue
        case tint
        case hueShiftBlueHue
        case hueShiftBlueSaturation
        case hueShiftBlueBrightness
        case hueShiftBlueQuality
        case chromaticityX
        case chromaticityY
        case chromaticityBrightness
        case colorRGBRed
        case colorRGBGreen
        case colorRGBBlue
        case colorRGBCyan
        case colorRGBMagenta
        case colorRGBYellow
        case colorRGBQuality
        case videoBoostRed
        case videoBoostGreen
        case videoBoostBlue
        case videoHueShift
        case videoSaturation
        case videoBrightness
        case videoContrast
        case videoKeyColorRed
        case videoKeyColorGreen
        case videoKeyColorBlue
        case videoKeyIntensity
        case videoKeyTolerance
        case strobeDuration
        case strobeRate
        case strobeFrequency
        case strobeModeShutter
        case strobeModeStrobe
        case strobeModePulse
        case strobeModePulseOpen
        case strobeModePulseClose
        case strobeModeRandom
        case strobeModeRandomPulse
        case strobeModeRandomPulseOpen
        case strobeModeRandomPulseClose
        case strobeModeEffect
        case shutter
        case shutterStrobe
        case shutterStrobePulse
        case shutterStrobePulseClose
        case shutterStrobePulseOpen
        case shutterStrobeRandom
        case shutterStrobeRandomPulse
        case shutterStrobeRandomPulseClose
        case shutterStrobeRandomPulseOpen
        case shutterStrobeEffect
        case iris
        case irisStrobe
        case irisStrobeRandom
        case irisPulseClose
        case irisPulseOpen
        case irisRandomPulseClose
        case irisRandomPulseOpen
        case frost
        case frostPulseOpen
        case frostPulseClose
        case frostRamp
        case prism
        case prismSelectSpin
        case prismMacro
        case prismPosition
        case prismPositionRotate
        case effects
        case effectsRate
        case effectsFade
        case effectsAdjust
        case effectsPosition
        case effectsPositionRotate
        case effectsSync
        case beamShaper
        case beamShaperMacro
        case beamShaperPosition
        case beamShaperPositionRotate
        case zoom
        case zoomModeSpot
        case zoomModeBeam
        case digitalZoom
        case focus
        case focusAdjust
        case focusDistance
        case control
        case dimmerMode
        case dimmerCurve
        case blackoutMode
        case ledFrequency
        case ledZoneMode
        case pixelMode
        case panMode
        case tiltMode
        case panTiltMode
        case positionModes
        case goboWheelMode
        case goboWheelShortcutMode
        case animationWheelMode
        case animationWheelShortcutMode
        case colorMode
        case colorWheelShortcutMode
        case cyanMode
        case magentaMode
        case yellowMode
        case colorMixMode
        case chromaticMode
        case colorCalibrationMode
        case colorConsistency
        case colorControl
        case colorModelMode
        case colorSettingsReset
        case colorUniformity
        case colorRenderingIndexMode
        case customColor
        case ultravioletStability
        case wavelengthCorrection
        case whiteCount
        case strobeMode
        case zoomMode
        case focusMode
        case irisMode
        case fanMode
        case followSpotMode
        case beamEffectIndexRotateMode
        case intensityMovementSpeed
        case positionMovementSpeed
        case colorMixMovementSpeed
        case colorWheelSelectMovementSpeed
        case goboWheelMovementSpeed
        case irisMovementSpeed
        case prismMovementSpeed
        case focusMovementSpeed
        case frostMovementSpeed
        case zoomMovementSpeed
        case frameMovementSpeed
        case globalMovementSpeed
        case reflectorAdjust
        case fixtureGlobalReset
        case dimmerReset
        case shutterReset
        case beamReset
        case colorMixReset
        case colorWheelReset
        case focusReset
        case frameReset
        case goboWheelReset
        case intensityReset
        case irisReset
        case positionReset
        case panReset
        case tiltReset
        case zoomReset
        case colorTemperatureBlueReset
        case colorTemperatureOrangeReset
        case colorTemperatureCorrectionReset
        case animationSystemReset
        case fixtureCalibrationReset
        case function
        case lampControl
        case displayIntensity
        case dmxInput
        case noFeature
        case dummy
        case blower
        case fan
        case fog
        case haze
        case lampPowerMode
        case fans
        case bladeA
        case bladeB
        case bladeRotation
        case shaperRotation
        case shaperMacros
        case shaperMacrosSpeed
        case bladeSoftA
        case bladeSoftB
        case keystoneA
        case keystoneB
        case video
        case videoEffectType
        case videoEffectParameter
        case videoCamera
        case videoSoundVolume
        case videoBlendMode
        case inputSource
        case fieldOfView
        case custom(name: String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let name = try container.decode(String.self)
            self.init(name: name)
        }
        public init(name: String) {
            switch name {
            case "Dimmer": self = .dimmer
            case "Pan": self = .pan
            case "Tilt": self = .tilt
            case "PanRotate": self = .panRotate
            case "TiltRotate": self = .tiltRotate
            case "PositionEffect": self = .positionEffect
            case "PositionEffectRate": self = .positionEffectRate
            case "PositionEffectFade": self = .positionEffectFade
            case "XYZ_X": self = .xyzX
            case "XYZ_Y": self = .xyzY
            case "XYZ_Z": self = .xyzZ
            case "Rot_X": self = .rotationX
            case "Rot_Y": self = .rotationY
            case "Rot_Z": self = .rotationZ
            case "Scale_X": self = .scaleX
            case "Scale_Y": self = .scaleY
            case "Scale_Z": self = .scaleZ
            case "Scale_XYZ": self = .scaleXYZ
            case "Gobo(n)": self = .gobo
            case "Gobo(n)SelectSpin": self = .goboSelectSpin
            case "Gobo(n)SelectShake": self = .goboSelectShake
            case "Gobo(n)SelectEffects": self = .goboSelectEffects
            case "Gobo(n)WheelIndex": self = .goboWheelIndex
            case "Gobo(n)WheelSpin": self = .goboWheelSpin
            case "Gobo(n)WheelShake": self = .goboWheelShake
            case "Gobo(n)WheelRandom": self = .goboWheelRandom
            case "Gobo(n)WheelAudio": self = .goboWheelAudio
            case "Gobo(n)Pos": self = .goboPosition
            case "Gobo(n)PosRotate": self = .goboPositionRotate
            case "Gobo(n)PosShake": self = .goboPositionShake
            case "AnimationWheel(n)": self = .animationWheel
            case "AnimationWheel(n)Audio": self = .animationWheelAudio
            case "AnimationWheel(n)Macro": self = .animationWheelMacro
            case "AnimationWheel(n)Random": self = .animationWheelRandom
            case "AnimationWheel(n)SelectEffects": self = .animationWheelSelectEffects
            case "AnimationWheel(n)SelectShake": self = .animationWheelSelectShake
            case "AnimationWheel(n)SelectSpin": self = .animationWheelSelectSpin
            case "AnimationWheel(n)Pos": self = .animationWheelPosition
            case "AnimationWheel(n)PosRotate": self = .animationWheelPositionRotate
            case "AnimationWheel(n)PosShake": self = .animationWheelPositionShake
            case "AnimationSystem(n)": self = .animationSystem
            case "AnimationSystem(n)Ramp": self = .animationSystemRamp
            case "AnimationSystem(n)Shake": self = .animationSystemShake
            case "AnimationSystem(n)Audio": self = .animationSystemAudio
            case "AnimationSystem(n)Random": self = .animationSystemRandom
            case "AnimationSystem(n)Pos": self = .animationSystemPosition
            case "AnimationSystem(n)PosRotate": self = .animationSystemPositionRotate
            case "AnimationSystem(n)PosShake": self = .animationSystemPositionShake
            case "AnimationSystem(n)PosRandom": self = .animationSystemPositionRandom
            case "AnimationSystem(n)PosAudio": self = .animationSystemPositionAudio
            case "AnimationSystem(n)Macro": self = .animationSystemMacro
            case "MediaFolder(n)": self = .mediaFolder
            case "MediaContent(n)": self = .mediaContent
            case "ModelFolder(n)": self = .modelFolder
            case "ModelContent(n)": self = .modelContent
            case "PlayMode": self = .playMode
            case "Playmode": self = .playMode
            case "PlayBegin": self = .playBegin
            case "PlayEnd": self = .playEnd
            case "PlaySpeed": self = .playSpeed
            case "ColorEffects(n)": self = .colorEffects
            case "Color(n)": self = .color
            case "Color(n)WheelIndex": self = .colorWheelIndex
            case "Color(n)WheelSpin": self = .colorWheelSpin
            case "Color(n)WheelRandom": self = .colorWheelRandom
            case "Color(n)WheelAudio": self = .colorWheelAudio
            case "ColorAdd_R": self = .colorAddRed
            case "ColorAdd_G": self = .colorAddGreen
            case "ColorAdd_B": self = .colorAddBlue
            case "ColorAdd_C": self = .colorAddCyan
            case "ColorAdd_M": self = .colorAddMagenta
            case "ColorAdd_Y": self = .colorAddYellow
            case "ColorAdd_RY": self = .colorAddRedYellow
            case "ColorAdd_GY": self = .colorAddGreenYellow
            case "ColorAdd_GC": self = .colorAddGreenCyan
            case "ColorAdd_BC": self = .colorAddBlueCyan
            case "ColorAdd_BM": self = .colorAddBlueMagenta
            case "ColorAdd_RM": self = .colorAddRedMagenta
            case "ColorAdd_W": self = .colorAddWhite
            case "ColorAdd_WW": self = .colorAddWarmWhite
            case "ColorAdd_CW": self = .colorAddCoolWhite
            case "ColorAdd_UV": self = .colorAddUltraviolet
            case "ColorSub_R": self = .colorSubtractRed
            case "ColorSub_G": self = .colorSubtractGreen
            case "ColorSub_B": self = .colorSubtractBlue
            case "ColorSub_C": self = .colorSubtractCyan
            case "ColorSub_M": self = .colorSubtractMagenta
            case "ColorSub_Y": self = .colorSubtractYellow
            case "ColorMacro(n)": self = .colorMacro
            case "ColorMacro(n)Rate": self = .colorMacroRate
            case "CTO": self = .colorTemperatureOrange
            case "CTC": self = .colorTemperatureCorrection
            case "CTB": self = .colorTemperatureBlue
            case "Tint": self = .tint
            case "HSB_Hue": self = .hueShiftBlueHue
            case "HSB_Saturation": self = .hueShiftBlueSaturation
            case "HSB_Brightness": self = .hueShiftBlueBrightness
            case "HSB_Quality": self = .hueShiftBlueQuality
            case "CIE_X": self = .chromaticityX
            case "CIE_Y": self = .chromaticityY
            case "CIE_Brightness": self = .chromaticityBrightness
            case "ColorRGB_Red": self = .colorRGBRed
            case "ColorRGB_Green": self = .colorRGBGreen
            case "ColorRGB_Blue": self = .colorRGBBlue
            case "ColorRGB_Cyan": self = .colorRGBCyan
            case "ColorRGB_Magenta": self = .colorRGBMagenta
            case "ColorRGB_Yellow": self = .colorRGBYellow
            case "ColorRGB_Quality": self = .colorRGBQuality
            case "VideoBoost_R": self = .videoBoostRed
            case "VideoBoost_G": self = .videoBoostGreen
            case "VideoBoost_B": self = .videoBoostBlue
            case "VideoHueShift": self = .videoHueShift
            case "VideoSaturation": self = .videoSaturation
            case "VideoBrightness": self = .videoBrightness
            case "VideoContrast": self = .videoContrast
            case "VideoKeyColor_R": self = .videoKeyColorRed
            case "VideoKeyColor_G": self = .videoKeyColorGreen
            case "VideoColorKey_B": self = .videoKeyColorBlue
            case "VideoKeyIntensity": self = .videoKeyIntensity
            case "VideoKeyTolerance": self = .videoKeyTolerance
            case "StrobeDuration": self = .strobeDuration
            case "StrobeRate": self = .strobeRate
            case "StrobeFrequency": self = .strobeFrequency
            case "StrobeModeShutter": self = .strobeModeShutter
            case "StrobeModeStrobe": self = .strobeModeStrobe
            case "StrobeModePulse": self = .strobeModePulse
            case "StrobeModePulseOpen": self = .strobeModePulseOpen
            case "StrobeModePulseClose": self = .strobeModePulseClose
            case "StrobeModeRandom": self = .strobeModeRandom
            case "StrobeModeRandomPulse": self = .strobeModeRandomPulse
            case "StrobeModeRandomPulseOpen": self = .strobeModeRandomPulseOpen
            case "StrobeModeRandomPulseClose": self = .strobeModeRandomPulseClose
            case "StrobeModeEffect": self = .strobeModeEffect
            case "Shutter(n)": self = .shutter
            case "Shutter(n)Strobe": self = .shutterStrobe
            case "Shutter(n)StrobePulse": self = .shutterStrobePulse
            case "Shutter(n)StrobePulseClose": self = .shutterStrobePulseClose
            case "Shutter(n)StrobePulseOpen": self = .shutterStrobePulseOpen
            case "Shutter(n)StrobeRandom": self = .shutterStrobeRandom
            case "Shutter(n)StrobeRandomPulse": self = .shutterStrobeRandomPulse
            case "Shutter(n)StrobeRandomPulseClose": self = .shutterStrobeRandomPulseClose
            case "Shutter(n)StrobeRandomPulseOpen": self = .shutterStrobeRandomPulseOpen
            case "Shutter(n)StrobeEffect": self = .shutterStrobeEffect
            case "Iris": self = .iris
            case "IrisStrobe": self = .irisStrobe
            case "IrisStrobeRandom": self = .irisStrobeRandom
            case "IrisPulseClose": self = .irisPulseClose
            case "IrisPulseOpen": self = .irisPulseOpen
            case "IrisRandomPulseClose": self = .irisRandomPulseClose
            case "IrisRandomPulseOpen": self = .irisRandomPulseOpen
            case "Frost(n)": self = .frost
            case "Frost(n)PulseOpen": self = .frostPulseOpen
            case "Frost(n)PulseClose": self = .frostPulseClose
            case "Frost(n)Ramp": self = .frostRamp
            case "Prism(n)": self = .prism
            case "Prism(n)SelectSpin": self = .prismSelectSpin
            case "Prism(n)Macro": self = .prismMacro
            case "Prism(n)Pos": self = .prismPosition
            case "Prism(n)PosRotate": self = .prismPositionRotate
            case "Effects(n)": self = .effects
            case "Effects(n)Rate": self = .effectsRate
            case "Effects(n)Fade": self = .effectsFade
            case "Effects(n)Adjust(m)": self = .effectsAdjust
            case "Effects(n)Pos": self = .effectsPosition
            case "Effects(n)PosRotate": self = .effectsPositionRotate
            case "EffectsSync": self = .effectsSync
            case "BeamShaper": self = .beamShaper
            case "BeamShaperMacro": self = .beamShaperMacro
            case "BeamShaperPos": self = .beamShaperPosition
            case "BeamShaperPosRotate": self = .beamShaperPositionRotate
            case "Zoom": self = .zoom
            case "ZoomModeSpot": self = .zoomModeSpot
            case "ZoomModeBeam": self = .zoomModeBeam
            case "DigitalZoom": self = .digitalZoom
            case "Focus(n)": self = .focus
            case "Focus(n)Adjust": self = .focusAdjust
            case "Focus(n)Distance": self = .focusDistance
            case "Control(n)": self = .control
            case "DimmerMode": self = .dimmerMode
            case "DimmerCurve": self = .dimmerCurve
            case "BlackoutMode": self = .blackoutMode
            case "LEDFrequency": self = .ledFrequency
            case "LEDZoneMode": self = .ledZoneMode
            case "PixelMode": self = .pixelMode
            case "PanMode": self = .panMode
            case "TiltMode": self = .tiltMode
            case "PanTiltMode": self = .panTiltMode
            case "PositionModes": self = .positionModes
            case "Gobo(n)WheelMode": self = .goboWheelMode
            case "GoboWheelShortcutMode": self = .goboWheelShortcutMode
            case "AnimationWheel(n)Mode": self = .animationWheelMode
            case "AnimationWheelShortcutMode": self = .animationWheelShortcutMode
            case "Color(n)Mode": self = .colorMode
            case "ColorWheelShortcutMode": self = .colorWheelShortcutMode
            case "CyanMode": self = .cyanMode
            case "MagentaMode": self = .magentaMode
            case "YellowMode": self = .yellowMode
            case "ColorMixMode": self = .colorMixMode
            case "ChromaticMode": self = .chromaticMode
            case "ColorCalibrationMode": self = .colorCalibrationMode
            case "ColorConsistency": self = .colorConsistency
            case "ColorControl": self = .colorControl
            case "ColorModelMode": self = .colorModelMode
            case "ColorSettingsReset": self = .colorSettingsReset
            case "ColorUniformity": self = .colorUniformity
            case "CRIMode": self = .colorRenderingIndexMode
            case "CustomColor": self = .customColor
            case "UVStability": self = .ultravioletStability
            case "WaveLengthCorrection": self = .wavelengthCorrection
            case "WhiteCount": self = .whiteCount
            case "StrobeMode": self = .strobeMode
            case "ZoomMode": self = .zoomMode
            case "FocusMode": self = .focusMode
            case "IrisMode": self = .irisMode
            case "FanMode": self = .fanMode
            case "FollowSpotMode": self = .followSpotMode
            case "BeamEffectIndexRotateMode": self = .beamEffectIndexRotateMode
            case "IntensityMSpeed": self = .intensityMovementSpeed
            case "PositionMSpeed": self = .positionMovementSpeed
            case "ColorMixMSpeed": self = .colorMixMovementSpeed
            case "ColorWheelSelectMSpeed": self = .colorWheelSelectMovementSpeed
            case "GoboWheel(n)MSpeed": self = .goboWheelMovementSpeed
            case "IrisMSpeed": self = .irisMovementSpeed
            case "Prism(n)MSpeed": self = .prismMovementSpeed
            case "FocusMSpeed": self = .focusMovementSpeed
            case "Frost(n)MSpeed": self = .frostMovementSpeed
            case "ZoomMSpeed": self = .zoomMovementSpeed
            case "FrameMSpeed": self = .frameMovementSpeed
            case "GlobalMSpeed": self = .globalMovementSpeed
            case "ReflectorAdjust": self = .reflectorAdjust
            case "FixtureGlobalReset": self = .fixtureGlobalReset
            case "DimmerReset": self = .dimmerReset
            case "ShutterReset": self = .shutterReset
            case "BeamReset": self = .beamReset
            case "ColorMixReset": self = .colorMixReset
            case "ColorWheelReset": self = .colorWheelReset
            case "FocusReset": self = .focusReset
            case "FrameReset": self = .frameReset
            case "GoboWheelReset": self = .goboWheelReset
            case "IntensityReset": self = .intensityReset
            case "IrisReset": self = .irisReset
            case "PositionReset": self = .positionReset
            case "PanReset": self = .panReset
            case "TiltReset": self = .tiltReset
            case "ZoomReset": self = .zoomReset
            case "CTBReset": self = .colorTemperatureBlueReset
            case "CTOReset": self = .colorTemperatureOrangeReset
            case "CTCReset": self = .colorTemperatureCorrectionReset
            case "AnimationSystemReset": self = .animationSystemReset
            case "FixtureCalibrationReset": self = .fixtureCalibrationReset
            case "Function": self = .function
            case "LampControl": self = .lampControl
            case "DisplayIntensity": self = .displayIntensity
            case "DMXInput": self = .dmxInput
            case "NoFeature": self = .noFeature
            case "Dummy": self = .dummy
            case "Blower(n)": self = .blower
            case "Fan(n)": self = .fan
            case "Fog(n)": self = .fog
            case "Haze(n)": self = .haze
            case "LampPowerMode": self = .lampPowerMode
            case "Fans": self = .fans
            case "Blade(n)A": self = .bladeA
            case "Blade(n)B": self = .bladeB
            case "Blade(n)Rot": self = .bladeRotation
            case "ShaperRot": self = .shaperRotation
            case "ShaperMacros": self = .shaperMacros
            case "ShaperMacrosSpeed": self = .shaperMacrosSpeed
            case "BladeSoft(n)A": self = .bladeSoftA
            case "BladeSoft(n)B": self = .bladeSoftB
            case "KeyStone(n)A": self = .keystoneA
            case "KeyStone(n)B": self = .keystoneB
            case "Video": self = .video
            case "VideoEffect(n)Type": self = .videoEffectType
            case "VideoEffect(n)Parameter(m)": self = .videoEffectParameter
            case "VideoCamera(n)": self = .videoCamera
            case "VideoSoundVolume(n)": self = .videoSoundVolume
            case "VideoBlendMode": self = .videoBlendMode
            case "InputSource": self = .inputSource
            case "FieldOfView": self = .fieldOfView
            default:
                self = .custom(name: name)
            }
        }
    }


    case dimmer
    case pan
    case tilt
    case panRotate
    case tiltRotate
    case positionEffect
    case positionEffectRate
    case positionEffectFade
    case xyzX
    case xyzY
    case xyzZ
    case rotationX
    case rotationY
    case rotationZ
    case scaleX
    case scaleY
    case scaleZ
    case scaleXYZ
    case gobo(n: Int)
    case goboSelectSpin(n: Int)
    case goboSelectShake(n: Int)
    case goboSelectEffects(n: Int)
    case goboWheelIndex(n: Int)
    case goboWheelSpin(n: Int)
    case goboWheelShake(n: Int)
    case goboWheelRandom(n: Int)
    case goboWheelAudio(n: Int)
    case goboPosition(n: Int)
    case goboPositionRotate(n: Int)
    case goboPositionShake(n: Int)
    case animationWheel(n: Int)
    case animationWheelAudio(n: Int)
    case animationWheelMacro(n: Int)
    case animationWheelRandom(n: Int)
    case animationWheelSelectEffects(n: Int)
    case animationWheelSelectShake(n: Int)
    case animationWheelSelectSpin(n: Int)
    case animationWheelPosition(n: Int)
    case animationWheelPositionRotate(n: Int)
    case animationWheelPositionShake(n: Int)
    case animationSystem(n: Int)
    case animationSystemRamp(n: Int)
    case animationSystemShake(n: Int)
    case animationSystemAudio(n: Int)
    case animationSystemRandom(n: Int)
    case animationSystemPosition(n: Int)
    case animationSystemPositionRotate(n: Int)
    case animationSystemPositionShake(n: Int)
    case animationSystemPositionRandom(n: Int)
    case animationSystemPositionAudio(n: Int)
    case animationSystemMacro(n: Int)
    case mediaFolder(n: Int)
    case mediaContent(n: Int)
    case modelFolder(n: Int)
    case modelContent(n: Int)
    case playMode
    case playBegin
    case playEnd
    case playSpeed
    case colorEffects(n: Int)
    case color(n: Int)
    case colorWheelIndex(n: Int)
    case colorWheelSpin(n: Int)
    case colorWheelRandom(n: Int)
    case colorWheelAudio(n: Int)
    case colorAddRed
    case colorAddGreen
    case colorAddBlue
    case colorAddCyan
    case colorAddMagenta
    case colorAddYellow
    case colorAddRedYellow
    case colorAddGreenYellow
    case colorAddGreenCyan
    case colorAddBlueCyan
    case colorAddBlueMagenta
    case colorAddRedMagenta
    case colorAddWhite
    case colorAddWarmWhite
    case colorAddCoolWhite
    case colorAddUltraviolet
    case colorSubtractRed
    case colorSubtractGreen
    case colorSubtractBlue
    case colorSubtractCyan
    case colorSubtractMagenta
    case colorSubtractYellow
    case colorMacro(n: Int)
    case colorMacroRate(n: Int)
    case colorTemperatureOrange
    case colorTemperatureCorrection
    case colorTemperatureBlue
    case tint
    case hueShiftBlueHue
    case hueShiftBlueSaturation
    case hueShiftBlueBrightness
    case hueShiftBlueQuality
    case chromaticityX
    case chromaticityY
    case chromaticityBrightness
    case colorRGBRed
    case colorRGBGreen
    case colorRGBBlue
    case colorRGBCyan
    case colorRGBMagenta
    case colorRGBYellow
    case colorRGBQuality
    case videoBoostRed
    case videoBoostGreen
    case videoBoostBlue
    case videoHueShift
    case videoSaturation
    case videoBrightness
    case videoContrast
    case videoKeyColorRed
    case videoKeyColorGreen
    case videoKeyColorBlue
    case videoKeyIntensity
    case videoKeyTolerance
    case strobeDuration
    case strobeRate
    case strobeFrequency
    case strobeModeShutter
    case strobeModeStrobe
    case strobeModePulse
    case strobeModePulseOpen
    case strobeModePulseClose
    case strobeModeRandom
    case strobeModeRandomPulse
    case strobeModeRandomPulseOpen
    case strobeModeRandomPulseClose
    case strobeModeEffect
    case shutter(n: Int)
    case shutterStrobe(n: Int)
    case shutterStrobePulse(n: Int)
    case shutterStrobePulseClose(n: Int)
    case shutterStrobePulseOpen(n: Int)
    case shutterStrobeRandom(n: Int)
    case shutterStrobeRandomPulse(n: Int)
    case shutterStrobeRandomPulseClose(n: Int)
    case shutterStrobeRandomPulseOpen(n: Int)
    case shutterStrobeEffect(n: Int)
    case iris
    case irisStrobe
    case irisStrobeRandom
    case irisPulseClose
    case irisPulseOpen
    case irisRandomPulseClose
    case irisRandomPulseOpen
    case frost(n: Int)
    case frostPulseOpen(n: Int)
    case frostPulseClose(n: Int)
    case frostRamp(n: Int)
    case prism(n: Int)
    case prismSelectSpin(n: Int)
    case prismMacro(n: Int)
    case prismPosition(n: Int)
    case prismPositionRotate(n: Int)
    case effects(n: Int)
    case effectsRate(n: Int)
    case effectsFade(n: Int)
    case effectsAdjust(n: Int, m: Int)
    case effectsPosition(n: Int)
    case effectsPositionRotate(n: Int)
    case effectsSync
    case beamShaper
    case beamShaperMacro
    case beamShaperPosition
    case beamShaperPositionRotate
    case zoom
    case zoomModeSpot
    case zoomModeBeam
    case digitalZoom
    case focus(n: Int)
    case focusAdjust(n: Int)
    case focusDistance(n: Int)
    case control(n: Int)
    case dimmerMode
    case dimmerCurve
    case blackoutMode
    case ledFrequency
    case ledZoneMode
    case pixelMode
    case panMode
    case tiltMode
    case panTiltMode
    case positionModes
    case goboWheelMode(n: Int)
    case goboWheelShortcutMode
    case animationWheelMode(n: Int)
    case animationWheelShortcutMode
    case colorMode(n: Int)
    case colorWheelShortcutMode
    case cyanMode
    case magentaMode
    case yellowMode
    case colorMixMode
    case chromaticMode
    case colorCalibrationMode
    case colorConsistency
    case colorControl
    case colorModelMode
    case colorSettingsReset
    case colorUniformity
    case colorRenderingIndexMode
    case customColor
    case ultravioletStability
    case wavelengthCorrection
    case whiteCount
    case strobeMode
    case zoomMode
    case focusMode
    case irisMode
    case fanMode(n: Int)
    case followSpotMode
    case beamEffectIndexRotateMode
    case intensityMovementSpeed(n: Int)
    case positionMovementSpeed(n: Int)
    case colorMixMovementSpeed(n: Int)
    case colorWheelSelectMovementSpeed(n: Int)
    case goboWheelMovementSpeed(n: Int)
    case irisMovementSpeed(n: Int)
    case prismMovementSpeed(n: Int)
    case focusMovementSpeed(n: Int)
    case frostMovementSpeed(n: Int)
    case zoomMovementSpeed(n: Int)
    case frameMovementSpeed(n: Int)
    case globalMovementSpeed(n: Int)
    case reflectorAdjust
    case fixtureGlobalReset
    case dimmerReset
    case shutterReset
    case beamReset
    case colorMixReset
    case colorWheelReset
    case focusReset
    case frameReset
    case goboWheelReset
    case intensityReset
    case irisReset
    case positionReset
    case panReset
    case tiltReset
    case zoomReset
    case colorTemperatureBlueReset
    case colorTemperatureOrangeReset
    case colorTemperatureCorrectionReset
    case animationSystemReset
    case fixtureCalibrationReset
    case function
    case lampControl
    case displayIntensity
    case dmxInput
    case noFeature
    case dummy
    case blower(n: Int)
    case fan(n: Int)
    case fog(n: Int)
    case haze(n: Int)
    case lampPowerMode
    case fans
    case bladeA(n: Int)
    case bladeB(n: Int)
    case bladeRotation(n: Int)
    case shaperRotation
    case shaperMacros
    case shaperMacrosSpeed
    case bladeSoftA(n: Int)
    case bladeSoftB(n: Int)
    case keystoneA(n: Int)
    case keystoneB(n: Int)
    case video
    case videoEffectType(n: Int)
    case videoEffectParameter(n: Int, m: Int)
    case videoCamera(n: Int)
    case videoSoundVolume(n: Int)
    case videoBlendMode
    case inputSource
    case fieldOfView
    case custom(name: String)

    /// Returns the canonical representation of this attribute type (without associated values)
    public var canonical: Canonical {
        switch self {
        case .dimmer: return .dimmer
        case .pan: return .pan
        case .tilt: return .tilt
        case .panRotate: return .panRotate
        case .tiltRotate: return .tiltRotate
        case .positionEffect: return .positionEffect
        case .positionEffectRate: return .positionEffectRate
        case .positionEffectFade: return .positionEffectFade
        case .xyzX: return .xyzX
        case .xyzY: return .xyzY
        case .xyzZ: return .xyzZ
        case .rotationX: return .rotationX
        case .rotationY: return .rotationY
        case .rotationZ: return .rotationZ
        case .scaleX: return .scaleX
        case .scaleY: return .scaleY
        case .scaleZ: return .scaleZ
        case .scaleXYZ: return .scaleXYZ
        case .gobo: return .gobo
        case .goboSelectSpin: return .goboSelectSpin
        case .goboSelectShake: return .goboSelectShake
        case .goboSelectEffects: return .goboSelectEffects
        case .goboWheelIndex: return .goboWheelIndex
        case .goboWheelSpin: return .goboWheelSpin
        case .goboWheelShake: return .goboWheelShake
        case .goboWheelRandom: return .goboWheelRandom
        case .goboWheelAudio: return .goboWheelAudio
        case .goboPosition: return .goboPosition
        case .goboPositionRotate: return .goboPositionRotate
        case .goboPositionShake: return .goboPositionShake
        case .animationWheel: return .animationWheel
        case .animationWheelAudio: return .animationWheelAudio
        case .animationWheelMacro: return .animationWheelMacro
        case .animationWheelRandom: return .animationWheelRandom
        case .animationWheelSelectEffects: return .animationWheelSelectEffects
        case .animationWheelSelectShake: return .animationWheelSelectShake
        case .animationWheelSelectSpin: return .animationWheelSelectSpin
        case .animationWheelPosition: return .animationWheelPosition
        case .animationWheelPositionRotate: return .animationWheelPositionRotate
        case .animationWheelPositionShake: return .animationWheelPositionShake
        case .animationSystem: return .animationSystem
        case .animationSystemRamp: return .animationSystemRamp
        case .animationSystemShake: return .animationSystemShake
        case .animationSystemAudio: return .animationSystemAudio
        case .animationSystemRandom: return .animationSystemRandom
        case .animationSystemPosition: return .animationSystemPosition
        case .animationSystemPositionRotate: return .animationSystemPositionRotate
        case .animationSystemPositionShake: return .animationSystemPositionShake
        case .animationSystemPositionRandom: return .animationSystemPositionRandom
        case .animationSystemPositionAudio: return .animationSystemPositionAudio
        case .animationSystemMacro: return .animationSystemMacro
        case .mediaFolder: return .mediaFolder
        case .mediaContent: return .mediaContent
        case .modelFolder: return .modelFolder
        case .modelContent: return .modelContent
        case .playMode: return .playMode
        case .playBegin: return .playBegin
        case .playEnd: return .playEnd
        case .playSpeed: return .playSpeed
        case .colorEffects: return .colorEffects
        case .color: return .color
        case .colorWheelIndex: return .colorWheelIndex
        case .colorWheelSpin: return .colorWheelSpin
        case .colorWheelRandom: return .colorWheelRandom
        case .colorWheelAudio: return .colorWheelAudio
        case .colorAddRed: return .colorAddRed
        case .colorAddGreen: return .colorAddGreen
        case .colorAddBlue: return .colorAddBlue
        case .colorAddCyan: return .colorAddCyan
        case .colorAddMagenta: return .colorAddMagenta
        case .colorAddYellow: return .colorAddYellow
        case .colorAddRedYellow: return .colorAddRedYellow
        case .colorAddGreenYellow: return .colorAddGreenYellow
        case .colorAddGreenCyan: return .colorAddGreenCyan
        case .colorAddBlueCyan: return .colorAddBlueCyan
        case .colorAddBlueMagenta: return .colorAddBlueMagenta
        case .colorAddRedMagenta: return .colorAddRedMagenta
        case .colorAddWhite: return .colorAddWhite
        case .colorAddWarmWhite: return .colorAddWarmWhite
        case .colorAddCoolWhite: return .colorAddCoolWhite
        case .colorAddUltraviolet: return .colorAddUltraviolet
        case .colorSubtractRed: return .colorSubtractRed
        case .colorSubtractGreen: return .colorSubtractGreen
        case .colorSubtractBlue: return .colorSubtractBlue
        case .colorSubtractCyan: return .colorSubtractCyan
        case .colorSubtractMagenta: return .colorSubtractMagenta
        case .colorSubtractYellow: return .colorSubtractYellow
        case .colorMacro: return .colorMacro
        case .colorMacroRate: return .colorMacroRate
        case .colorTemperatureOrange: return .colorTemperatureOrange
        case .colorTemperatureCorrection: return .colorTemperatureCorrection
        case .colorTemperatureBlue: return .colorTemperatureBlue
        case .tint: return .tint
        case .hueShiftBlueHue: return .hueShiftBlueHue
        case .hueShiftBlueSaturation: return .hueShiftBlueSaturation
        case .hueShiftBlueBrightness: return .hueShiftBlueBrightness
        case .hueShiftBlueQuality: return .hueShiftBlueQuality
        case .chromaticityX: return .chromaticityX
        case .chromaticityY: return .chromaticityY
        case .chromaticityBrightness: return .chromaticityBrightness
        case .colorRGBRed: return .colorRGBRed
        case .colorRGBGreen: return .colorRGBGreen
        case .colorRGBBlue: return .colorRGBBlue
        case .colorRGBCyan: return .colorRGBCyan
        case .colorRGBMagenta: return .colorRGBMagenta
        case .colorRGBYellow: return .colorRGBYellow
        case .colorRGBQuality: return .colorRGBQuality
        case .videoBoostRed: return .videoBoostRed
        case .videoBoostGreen: return .videoBoostGreen
        case .videoBoostBlue: return .videoBoostBlue
        case .videoHueShift: return .videoHueShift
        case .videoSaturation: return .videoSaturation
        case .videoBrightness: return .videoBrightness
        case .videoContrast: return .videoContrast
        case .videoKeyColorRed: return .videoKeyColorRed
        case .videoKeyColorGreen: return .videoKeyColorGreen
        case .videoKeyColorBlue: return .videoKeyColorBlue
        case .videoKeyIntensity: return .videoKeyIntensity
        case .videoKeyTolerance: return .videoKeyTolerance
        case .strobeDuration: return .strobeDuration
        case .strobeRate: return .strobeRate
        case .strobeFrequency: return .strobeFrequency
        case .strobeModeShutter: return .strobeModeShutter
        case .strobeModeStrobe: return .strobeModeStrobe
        case .strobeModePulse: return .strobeModePulse
        case .strobeModePulseOpen: return .strobeModePulseOpen
        case .strobeModePulseClose: return .strobeModePulseClose
        case .strobeModeRandom: return .strobeModeRandom
        case .strobeModeRandomPulse: return .strobeModeRandomPulse
        case .strobeModeRandomPulseOpen: return .strobeModeRandomPulseOpen
        case .strobeModeRandomPulseClose: return .strobeModeRandomPulseClose
        case .strobeModeEffect: return .strobeModeEffect
        case .shutter: return .shutter
        case .shutterStrobe: return .shutterStrobe
        case .shutterStrobePulse: return .shutterStrobePulse
        case .shutterStrobePulseClose: return .shutterStrobePulseClose
        case .shutterStrobePulseOpen: return .shutterStrobePulseOpen
        case .shutterStrobeRandom: return .shutterStrobeRandom
        case .shutterStrobeRandomPulse: return .shutterStrobeRandomPulse
        case .shutterStrobeRandomPulseClose: return .shutterStrobeRandomPulseClose
        case .shutterStrobeRandomPulseOpen: return .shutterStrobeRandomPulseOpen
        case .shutterStrobeEffect: return .shutterStrobeEffect
        case .iris: return .iris
        case .irisStrobe: return .irisStrobe
        case .irisStrobeRandom: return .irisStrobeRandom
        case .irisPulseClose: return .irisPulseClose
        case .irisPulseOpen: return .irisPulseOpen
        case .irisRandomPulseClose: return .irisRandomPulseClose
        case .irisRandomPulseOpen: return .irisRandomPulseOpen
        case .frost: return .frost
        case .frostPulseOpen: return .frostPulseOpen
        case .frostPulseClose: return .frostPulseClose
        case .frostRamp: return .frostRamp
        case .prism: return .prism
        case .prismSelectSpin: return .prismSelectSpin
        case .prismMacro: return .prismMacro
        case .prismPosition: return .prismPosition
        case .prismPositionRotate: return .prismPositionRotate
        case .effects: return .effects
        case .effectsRate: return .effectsRate
        case .effectsFade: return .effectsFade
        case .effectsAdjust: return .effectsAdjust
        case .effectsPosition: return .effectsPosition
        case .effectsPositionRotate: return .effectsPositionRotate
        case .effectsSync: return .effectsSync
        case .beamShaper: return .beamShaper
        case .beamShaperMacro: return .beamShaperMacro
        case .beamShaperPosition: return .beamShaperPosition
        case .beamShaperPositionRotate: return .beamShaperPositionRotate
        case .zoom: return .zoom
        case .zoomModeSpot: return .zoomModeSpot
        case .zoomModeBeam: return .zoomModeBeam
        case .digitalZoom: return .digitalZoom
        case .focus: return .focus
        case .focusAdjust: return .focusAdjust
        case .focusDistance: return .focusDistance
        case .control: return .control
        case .dimmerMode: return .dimmerMode
        case .dimmerCurve: return .dimmerCurve
        case .blackoutMode: return .blackoutMode
        case .ledFrequency: return .ledFrequency
        case .ledZoneMode: return .ledZoneMode
        case .pixelMode: return .pixelMode
        case .panMode: return .panMode
        case .tiltMode: return .tiltMode
        case .panTiltMode: return .panTiltMode
        case .positionModes: return .positionModes
        case .goboWheelMode: return .goboWheelMode
        case .goboWheelShortcutMode: return .goboWheelShortcutMode
        case .animationWheelMode: return .animationWheelMode
        case .animationWheelShortcutMode: return .animationWheelShortcutMode
        case .colorMode: return .colorMode
        case .colorWheelShortcutMode: return .colorWheelShortcutMode
        case .cyanMode: return .cyanMode
        case .magentaMode: return .magentaMode
        case .yellowMode: return .yellowMode
        case .colorMixMode: return .colorMixMode
        case .chromaticMode: return .chromaticMode
        case .colorCalibrationMode: return .colorCalibrationMode
        case .colorConsistency: return .colorConsistency
        case .colorControl: return .colorControl
        case .colorModelMode: return .colorModelMode
        case .colorSettingsReset: return .colorSettingsReset
        case .colorUniformity: return .colorUniformity
        case .colorRenderingIndexMode: return .colorRenderingIndexMode
        case .customColor: return .customColor
        case .ultravioletStability: return .ultravioletStability
        case .wavelengthCorrection: return .wavelengthCorrection
        case .whiteCount: return .whiteCount
        case .strobeMode: return .strobeMode
        case .zoomMode: return .zoomMode
        case .focusMode: return .focusMode
        case .irisMode: return .irisMode
        case .fanMode: return .fanMode
        case .followSpotMode: return .followSpotMode
        case .beamEffectIndexRotateMode: return .beamEffectIndexRotateMode
        case .intensityMovementSpeed: return .intensityMovementSpeed
        case .positionMovementSpeed: return .positionMovementSpeed
        case .colorMixMovementSpeed: return .colorMixMovementSpeed
        case .colorWheelSelectMovementSpeed: return .colorWheelSelectMovementSpeed
        case .goboWheelMovementSpeed: return .goboWheelMovementSpeed
        case .irisMovementSpeed: return .irisMovementSpeed
        case .prismMovementSpeed: return .prismMovementSpeed
        case .focusMovementSpeed: return .focusMovementSpeed
        case .frostMovementSpeed: return .frostMovementSpeed
        case .zoomMovementSpeed: return .zoomMovementSpeed
        case .frameMovementSpeed: return .frameMovementSpeed
        case .globalMovementSpeed: return .globalMovementSpeed
        case .reflectorAdjust: return .reflectorAdjust
        case .fixtureGlobalReset: return .fixtureGlobalReset
        case .dimmerReset: return .dimmerReset
        case .shutterReset: return .shutterReset
        case .beamReset: return .beamReset
        case .colorMixReset: return .colorMixReset
        case .colorWheelReset: return .colorWheelReset
        case .focusReset: return .focusReset
        case .frameReset: return .frameReset
        case .goboWheelReset: return .goboWheelReset
        case .intensityReset: return .intensityReset
        case .irisReset: return .irisReset
        case .positionReset: return .positionReset
        case .panReset: return .panReset
        case .tiltReset: return .tiltReset
        case .zoomReset: return .zoomReset
        case .colorTemperatureBlueReset: return .colorTemperatureBlueReset
        case .colorTemperatureOrangeReset: return .colorTemperatureOrangeReset
        case .colorTemperatureCorrectionReset: return .colorTemperatureCorrectionReset
        case .animationSystemReset: return .animationSystemReset
        case .fixtureCalibrationReset: return .fixtureCalibrationReset
        case .function: return .function
        case .lampControl: return .lampControl
        case .displayIntensity: return .displayIntensity
        case .dmxInput: return .dmxInput
        case .noFeature: return .noFeature
        case .dummy: return .dummy
        case .blower: return .blower
        case .fan: return .fan
        case .fog: return .fog
        case .haze: return .haze
        case .lampPowerMode: return .lampPowerMode
        case .fans: return .fans
        case .bladeA: return .bladeA
        case .bladeB: return .bladeB
        case .bladeRotation: return .bladeRotation
        case .shaperRotation: return .shaperRotation
        case .shaperMacros: return .shaperMacros
        case .shaperMacrosSpeed: return .shaperMacrosSpeed
        case .bladeSoftA: return .bladeSoftA
        case .bladeSoftB: return .bladeSoftB
        case .keystoneA: return .keystoneA
        case .keystoneB: return .keystoneB
        case .video: return .video
        case .videoEffectType: return .videoEffectType
        case .videoEffectParameter: return .videoEffectParameter
        case .videoCamera: return .videoCamera
        case .videoSoundVolume: return .videoSoundVolume
        case .videoBlendMode: return .videoBlendMode
        case .inputSource: return .inputSource
        case .fieldOfView: return .fieldOfView
        case .custom(let name): return .custom(name: name)
        }
    }

    public var description: String {
        switch self {
            // Position
        case .dimmer: return "Dimmer"
        case .pan: return "Pan"
        case .tilt: return "Tilt"
        case .panRotate: return "Pan Rotate"
        case .tiltRotate: return "Tilt Rotate"
        case .positionEffect: return "Position Effect"
        case .positionEffectRate: return "Position Effect Rate"
        case .positionEffectFade: return "Position Effect Fade"

            // 3D Position
        case .xyzX: return "X Position"
        case .xyzY: return "Y Position"
        case .xyzZ: return "Z Position"
        case .rotationX: return "X Rotation"
        case .rotationY: return "Y Rotation"
        case .rotationZ: return "Z Rotation"
        case .scaleX: return "X Scale"
        case .scaleY: return "Y Scale"
        case .scaleZ: return "Z Scale"
        case .scaleXYZ: return "XYZ Scale"

            // Gobo
        case .gobo(let n): return "Gobo \(n)"
        case .goboSelectSpin(let n): return "Gobo \(n) Select Spin"
        case .goboSelectShake(let n): return "Gobo \(n) Select Shake"
        case .goboSelectEffects(let n): return "Gobo \(n) Select Effects"
        case .goboWheelIndex(let n): return "Gobo Wheel \(n) Index"
        case .goboWheelSpin(let n): return "Gobo Wheel \(n) Spin"
        case .goboWheelShake(let n): return "Gobo Wheel \(n) Shake"
        case .goboWheelRandom(let n): return "Gobo Wheel \(n) Random"
        case .goboWheelAudio(let n): return "Gobo Wheel \(n) Audio"
        case .goboPosition(let n): return "Gobo \(n) Position"
        case .goboPositionRotate(let n): return "Gobo \(n) Position Rotate"
        case .goboPositionShake(let n): return "Gobo \(n) Position Shake"

            // Animation Wheel
        case .animationWheel(let n): return "Animation Wheel \(n)"
        case .animationWheelAudio(let n): return "Animation Wheel \(n) Audio"
        case .animationWheelMacro(let n): return "Animation Wheel \(n) Macro"
        case .animationWheelRandom(let n): return "Animation Wheel \(n) Random"
        case .animationWheelSelectEffects(let n): return "Animation Wheel \(n) Select Effects"
        case .animationWheelSelectShake(let n): return "Animation Wheel \(n) Select Shake"
        case .animationWheelSelectSpin(let n): return "Animation Wheel \(n) Select Spin"
        case .animationWheelPosition(let n): return "Animation Wheel \(n) Position"
        case .animationWheelPositionRotate(let n): return "Animation Wheel \(n) Position Rotate"
        case .animationWheelPositionShake(let n): return "Animation Wheel \(n) Position Shake"

            // Animation System
        case .animationSystem(let n): return "Animation System \(n)"
        case .animationSystemRamp(let n): return "Animation System \(n) Ramp"
        case .animationSystemShake(let n): return "Animation System \(n) Shake"
        case .animationSystemAudio(let n): return "Animation System \(n) Audio"
        case .animationSystemRandom(let n): return "Animation System \(n) Random"
        case .animationSystemPosition(let n): return "Animation System \(n) Position"
        case .animationSystemPositionRotate(let n): return "Animation System \(n) Position Rotate"
        case .animationSystemPositionShake(let n): return "Animation System \(n) Position Shake"
        case .animationSystemPositionRandom(let n): return "Animation System \(n) Position Random"
        case .animationSystemPositionAudio(let n): return "Animation System \(n) Position Audio"
        case .animationSystemMacro(let n): return "Animation System \(n) Macro"

            // Media
        case .mediaFolder(let n): return "Media Folder \(n)"
        case .mediaContent(let n): return "Media Content \(n)"
        case .modelFolder(let n): return "Model Folder \(n)"
        case .modelContent(let n): return "Model Content \(n)"
        case .playMode: return "Play Mode"
        case .playBegin: return "Play Begin"
        case .playEnd: return "Play End"
        case .playSpeed: return "Play Speed"

            // Color
        case .colorEffects(let n): return "Color Effects \(n)"
        case .color(let n): return "Color \(n)"
        case .colorWheelIndex(let n): return "Color Wheel \(n) Index"
        case .colorWheelSpin(let n): return "Color Wheel \(n) Spin"
        case .colorWheelRandom(let n): return "Color Wheel \(n) Random"
        case .colorWheelAudio(let n): return "Color Wheel \(n) Audio"

            // Color Add
        case .colorAddRed: return "Color Add Red"
        case .colorAddGreen: return "Color Add Green"
        case .colorAddBlue: return "Color Add Blue"
        case .colorAddCyan: return "Color Add Cyan"
        case .colorAddMagenta: return "Color Add Magenta"
        case .colorAddYellow: return "Color Add Yellow"
        case .colorAddRedYellow: return "Color Add Red-Yellow"
        case .colorAddGreenYellow: return "Color Add Green-Yellow"
        case .colorAddGreenCyan: return "Color Add Green-Cyan"
        case .colorAddBlueCyan: return "Color Add Blue-Cyan"
        case .colorAddBlueMagenta: return "Color Add Blue-Magenta"
        case .colorAddRedMagenta: return "Color Add Red-Magenta"
        case .colorAddWhite: return "Color Add White"
        case .colorAddWarmWhite: return "Color Add Warm White"
        case .colorAddCoolWhite: return "Color Add Cool White"
        case .colorAddUltraviolet: return "Color Add UV"

            // Color Sub
        case .colorSubtractRed: return "Color Subtract Red"
        case .colorSubtractGreen: return "Color Subtract Green"
        case .colorSubtractBlue: return "Color Subtract Blue"
        case .colorSubtractCyan: return "Color Subtract Cyan"
        case .colorSubtractMagenta: return "Color Subtract Magenta"
        case .colorSubtractYellow: return "Color Subtract Yellow"

            // Color Macros & Temperature
        case .colorMacro(let n): return "Color Macro \(n)"
        case .colorMacroRate(let n): return "Color Macro \(n) Rate"
        case .colorTemperatureOrange: return "Color Temperature Orange"
        case .colorTemperatureCorrection: return "Color Temperature Correction"
        case .colorTemperatureBlue: return "Color Temperature Blue"
        case .tint: return "Tint"

            // HSB
        case .hueShiftBlueHue: return "Hue Shift Blue Hue"
        case .hueShiftBlueSaturation: return "Hue Shift Blue Saturation"
        case .hueShiftBlueBrightness: return "Hue Shift Blue Brightness"
        case .hueShiftBlueQuality: return "Hue Shift Blue Quality"

            // CIE
        case .chromaticityX: return "Chromaticity X"
        case .chromaticityY: return "Chromaticity Y"
        case .chromaticityBrightness: return "Chromaticity Brightness"

            // RGB
        case .colorRGBRed: return "RGB Red"
        case .colorRGBGreen: return "RGB Green"
        case .colorRGBBlue: return "RGB Blue"
        case .colorRGBCyan: return "RGB Cyan"
        case .colorRGBMagenta: return "RGB Magenta"
        case .colorRGBYellow: return "RGB Yellow"
        case .colorRGBQuality: return "RGB Quality"

            // Video
        case .videoBoostRed: return "Video Boost Red"
        case .videoBoostGreen: return "Video Boost Green"
        case .videoBoostBlue: return "Video Boost Blue"
        case .videoHueShift: return "Video Hue Shift"
        case .videoSaturation: return "Video Saturation"
        case .videoBrightness: return "Video Brightness"
        case .videoContrast: return "Video Contrast"
        case .videoKeyColorRed: return "Video Key Red"
        case .videoKeyColorGreen: return "Video Key Green"
        case .videoKeyColorBlue: return "Video Key Blue"
        case .videoKeyIntensity: return "Video Key Intensity"
        case .videoKeyTolerance: return "Video Key Tolerance"

            // Strobe
        case .strobeDuration: return "Strobe Duration"
        case .strobeRate: return "Strobe Rate"
        case .strobeFrequency: return "Strobe Frequency"
        case .strobeModeShutter: return "Strobe Mode Shutter"
        case .strobeModeStrobe: return "Strobe Mode Strobe"
        case .strobeModePulse: return "Strobe Mode Pulse"
        case .strobeModePulseOpen: return "Strobe Mode Pulse Open"
        case .strobeModePulseClose: return "Strobe Mode Pulse Close"
        case .strobeModeRandom: return "Strobe Mode Random"
        case .strobeModeRandomPulse: return "Strobe Mode Random Pulse"
        case .strobeModeRandomPulseOpen: return "Strobe Mode Random Pulse Open"
        case .strobeModeRandomPulseClose: return "Strobe Mode Random Pulse Close"
        case .strobeModeEffect: return "Strobe Mode Effect"

            // Shutter
        case .shutter(let n): return "Shutter \(n)"
        case .shutterStrobe(let n): return "Shutter \(n) Strobe"
        case .shutterStrobePulse(let n): return "Shutter \(n) Strobe Pulse"
        case .shutterStrobePulseClose(let n): return "Shutter \(n) Strobe Pulse Close"
        case .shutterStrobePulseOpen(let n): return "Shutter \(n) Strobe Pulse Open"
        case .shutterStrobeRandom(let n): return "Shutter \(n) Strobe Random"
        case .shutterStrobeRandomPulse(let n): return "Shutter \(n) Strobe Random Pulse"
        case .shutterStrobeRandomPulseClose(let n): return "Shutter \(n) Strobe Random Pulse Close"
        case .shutterStrobeRandomPulseOpen(let n): return "Shutter \(n) Strobe Random Pulse Open"
        case .shutterStrobeEffect(let n): return "Shutter \(n) Strobe Effect"

            // Iris
        case .iris: return "Iris"
        case .irisStrobe: return "Iris Strobe"
        case .irisStrobeRandom: return "Iris Strobe Random"
        case .irisPulseClose: return "Iris Pulse Close"
        case .irisPulseOpen: return "Iris Pulse Open"
        case .irisRandomPulseClose: return "Iris Random Pulse Close"
        case .irisRandomPulseOpen: return "Iris Random Pulse Open"

            // Frost
        case .frost(let n): return "Frost \(n)"
        case .frostPulseOpen(let n): return "Frost \(n) Pulse Open"
        case .frostPulseClose(let n): return "Frost \(n) Pulse Close"
        case .frostRamp(let n): return "Frost \(n) Ramp"

            // Prism
        case .prism(let n): return "Prism \(n)"
        case .prismSelectSpin(let n): return "Prism \(n) Select Spin"
        case .prismMacro(let n): return "Prism \(n) Macro"
        case .prismPosition(let n): return "Prism \(n) Position"
        case .prismPositionRotate(let n): return "Prism \(n) Position Rotate"

            // Effects
        case .effects(let n): return "Effects \(n)"
        case .effectsRate(let n): return "Effects \(n) Rate"
        case .effectsFade(let n): return "Effects \(n) Fade"
        case .effectsAdjust(let n, let m): return "Effects \(n) Adjust \(m)"
        case .effectsPosition(let n): return "Effects \(n) Position"
        case .effectsPositionRotate(let n): return "Effects \(n) Position Rotate"
        case .effectsSync: return "Effects Sync"

            // Beam Shaper
        case .beamShaper: return "Beam Shaper"
        case .beamShaperMacro: return "Beam Shaper Macro"
        case .beamShaperPosition: return "Beam Shaper Position"
        case .beamShaperPositionRotate: return "Beam Shaper Position Rotate"

            // Zoom & Focus
        case .zoom: return "Zoom"
        case .zoomModeSpot: return "Zoom Mode Spot"
        case .zoomModeBeam: return "Zoom Mode Beam"
        case .digitalZoom: return "Digital Zoom"
        case .focus(let n): return "Focus \(n)"
        case .focusAdjust(let n): return "Focus \(n) Adjust"
        case .focusDistance(let n): return "Focus \(n) Distance"

            // Control
        case .control(let n): return "Control \(n)"
        case .dimmerMode: return "Dimmer Mode"
        case .dimmerCurve: return "Dimmer Curve"
        case .blackoutMode: return "Blackout Mode"
        case .ledFrequency: return "LED Frequency"
        case .ledZoneMode: return "LED Zone Mode"
        case .pixelMode: return "Pixel Mode"
        case .panMode: return "Pan Mode"
        case .tiltMode: return "Tilt Mode"
        case .panTiltMode: return "Pan/Tilt Mode"
        case .positionModes: return "Position Modes"

            // Modes
        case .goboWheelMode(let n): return "Gobo Wheel \(n) Mode"
        case .goboWheelShortcutMode: return "Gobo Wheel Shortcut Mode"
        case .animationWheelMode(let n): return "Animation Wheel \(n) Mode"
        case .animationWheelShortcutMode: return "Animation Wheel Shortcut Mode"
        case .colorMode(let n): return "Color Mode \(n)"
        case .colorWheelShortcutMode: return "Color Wheel Shortcut Mode"
        case .cyanMode: return "Cyan Mode"
        case .magentaMode: return "Magenta Mode"
        case .yellowMode: return "Yellow Mode"
        case .colorMixMode: return "Color Mix Mode"
        case .chromaticMode: return "Chromatic Mode"
        case .colorCalibrationMode: return "Color Calibration Mode"
        case .colorConsistency: return "Color Consistency"
        case .colorControl: return "Color Control"
        case .colorModelMode: return "Color Model Mode"
        case .colorSettingsReset: return "Color Settings Reset"
        case .colorUniformity: return "Color Uniformity"
        case .colorRenderingIndexMode: return "Color Rendering Index Mode"
        case .customColor: return "Custom Color"
        case .ultravioletStability: return "Ultraviolet Stability"
        case .wavelengthCorrection: return "Wavelength Correction"
        case .whiteCount: return "White Count"
        case .strobeMode: return "Strobe Mode"
        case .zoomMode: return "Zoom Mode"
        case .focusMode: return "Focus Mode"
        case .irisMode: return "Iris Mode"
        case .fanMode(let n): return "Fan \(n) Mode"
        case .followSpotMode: return "Follow Spot Mode"
        case .beamEffectIndexRotateMode: return "Beam Effect Index Rotate Mode"

            // Speed
        case .intensityMovementSpeed(let n): return "Intensity Movement Speed \(n)"
        case .positionMovementSpeed(let n): return "Position Movement Speed \(n)"
        case .colorMixMovementSpeed(let n): return "Color Mix Movement Speed \(n)"
        case .colorWheelSelectMovementSpeed(let n): return "Color Wheel Select Movement Speed \(n)"
        case .goboWheelMovementSpeed(let n): return "Gobo Wheel Movement Speed \(n)"
        case .irisMovementSpeed(let n): return "Iris Movement Speed \(n)"
        case .prismMovementSpeed(let n): return "Prism Movement Speed \(n)"
        case .focusMovementSpeed(let n): return "Focus Movement Speed \(n)"
        case .frostMovementSpeed(let n): return "Frost Movement Speed \(n)"
        case .zoomMovementSpeed(let n): return "Zoom Movement Speed \(n)"
        case .frameMovementSpeed(let n): return "Frame Movement Speed \(n)"
        case .globalMovementSpeed(let n): return "Global Movement Speed \(n)"

            // Resets
        case .reflectorAdjust: return "Reflector Adjust"
        case .fixtureGlobalReset: return "Fixture Global Reset"
        case .dimmerReset: return "Dimmer Reset"
        case .shutterReset: return "Shutter Reset"
        case .beamReset: return "Beam Reset"
        case .colorMixReset: return "Color Mix Reset"
        case .colorWheelReset: return "Color Wheel Reset"
        case .focusReset: return "Focus Reset"
        case .frameReset: return "Frame Reset"
        case .goboWheelReset: return "Gobo Wheel Reset"
        case .intensityReset: return "Intensity Reset"
        case .irisReset: return "Iris Reset"
        case .positionReset: return "Position Reset"
        case .panReset: return "Pan Reset"
        case .tiltReset: return "Tilt Reset"
        case .zoomReset: return "Zoom Reset"
        case .colorTemperatureBlueReset: return "Color Temperature Blue Reset"
        case .colorTemperatureOrangeReset: return "Color Temperature Orange Reset"
        case .colorTemperatureCorrectionReset: return "Color Temperature Correction Reset"
        case .animationSystemReset: return "Animation System Reset"
        case .fixtureCalibrationReset: return "Fixture Calibration Reset"

            // Misc
        case .function: return "Function"
        case .lampControl: return "Lamp Control"
        case .displayIntensity: return "Display Intensity"
        case .dmxInput: return "DMX Input"
        case .noFeature: return "No Feature"
        case .dummy: return "Dummy"

            // Environmental
        case .blower(let n): return "Blower \(n)"
        case .fan(let n): return "Fan \(n)"
        case .fog(let n): return "Fog \(n)"
        case .haze(let n): return "Haze \(n)"
        case .lampPowerMode: return "Lamp Power Mode"
        case .fans: return "Fans"

            // Blades & Shapers
        case .bladeA(let n): return "Blade A\(n)"
        case .bladeB(let n): return "Blade B\(n)"
        case .bladeRotation(let n): return "Blade \(n) Rotation"
        case .shaperRotation: return "Shaper Rotation"
        case .shaperMacros: return "Shaper Macros"
        case .shaperMacrosSpeed: return "Shaper Macros Speed"
        case .bladeSoftA(let n): return "Blade Soft A\(n)"
        case .bladeSoftB(let n): return "Blade Soft B\(n)"
        case .keystoneA(let n): return "Keystone A\(n)"
        case .keystoneB(let n): return "Keystone B\(n)"

            // Video
        case .video: return "Video"
        case .videoEffectType(let n): return "Video Effect \(n) Type"
        case .videoEffectParameter(let n, let m): return "Video Effect \(n) Parameter \(m)"
        case .videoCamera(let n): return "Video Camera \(n)"
        case .videoSoundVolume(let n): return "Video Sound Volume \(n)"
        case .videoBlendMode: return "Video Blend Mode"
        case .inputSource: return "Input Source"
        case .fieldOfView: return "Field of View"

            // Custom
        case .custom(let name): return name
        }
    }
}

