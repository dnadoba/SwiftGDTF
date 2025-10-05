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
    public enum Canonical: Hashable, Codable, Sendable {
        case dimmer
        case pan
        case tilt
        case panRotate
        case tiltRotate
        case positionEffect
        case positionEffectRate
        case positionEffectFade
        case xYZ_X
        case xYZ_Y
        case xYZ_Z
        case rot_X
        case rot_Y
        case rot_Z
        case scale_X
        case scale_Y
        case scale_Z
        case scale_XYZ
        case gobo
        case goboSelectSpin
        case goboSelectShake
        case goboSelectEffects
        case goboWheelIndex
        case goboWheelSpin
        case goboWheelShake
        case goboWheelRandom
        case goboWheelAudio
        case goboPos
        case goboPosRotate
        case goboPosShake
        case animationWheel
        case animationWheelAudio
        case animationWheelMacro
        case animationWheelRandom
        case animationWheelSelectEffects
        case animationWheelSelectShake
        case animationWheelSelectSpin
        case animationWheelPos
        case animationWheelPosRotate
        case animationWheelPosShake
        case animationSystem
        case animationSystemRamp
        case animationSystemShake
        case animationSystemAudio
        case animationSystemRandom
        case animationSystemPos
        case animationSystemPosRotate
        case animationSystemPosShake
        case animationSystemPosRandom
        case animationSystemPosAudio
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
        case colorAdd_R
        case colorAdd_G
        case colorAdd_B
        case colorAdd_C
        case colorAdd_M
        case colorAdd_Y
        case colorAdd_RY
        case colorAdd_GY
        case colorAdd_GC
        case colorAdd_BC
        case colorAdd_BM
        case colorAdd_RM
        case colorAdd_W
        case colorAdd_WW
        case colorAdd_CW
        case colorAdd_UV
        case colorSub_R
        case colorSub_G
        case colorSub_B
        case colorSub_C
        case colorSub_M
        case colorSub_Y
        case colorMacro
        case colorMacroRate
        case cTO
        case cTC
        case cTB
        case tint
        case hSB_Hue
        case hSB_Saturation
        case hSB_Brightness
        case hSB_Quality
        case cIE_X
        case cIE_Y
        case cIE_Brightness
        case colorRGB_Red
        case colorRGB_Green
        case colorRGB_Blue
        case colorRGB_Cyan
        case colorRGB_Magenta
        case colorRGB_Yellow
        case colorRGB_Quality
        case videoBoost_R
        case videoBoost_G
        case videoBoost_B
        case videoHueShift
        case videoSaturation
        case videoBrightness
        case videoContrast
        case videoKeyColor_R
        case videoKeyColor_G
        case videoKeyColor_B
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
        case prismPos
        case prismPosRotate
        case effects
        case effectsRate
        case effectsFade
        case effectsAdjust
        case effectsPos
        case effectsPosRotate
        case effectsSync
        case beamShaper
        case beamShaperMacro
        case beamShaperPos
        case beamShaperPosRotate
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
        case lEDFrequency
        case lEDZoneMode
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
        case cRIMode
        case customColor
        case uVStability
        case wavelengthCorrection
        case whiteCount
        case strobeMode
        case zoomMode
        case focusMode
        case irisMode
        case fanMode
        case followSpotMode
        case beamEffectIndexRotateMode
        case intensityMSpeed
        case positionMSpeed
        case colorMixMSpeed
        case colorWheelSelectMSpeed
        case goboWheelMSpeed
        case irisMSpeed
        case prismMSpeed
        case focusMSpeed
        case frostMSpeed
        case zoomMSpeed
        case frameMSpeed
        case globalMSpeed
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
        case cTBReset
        case cTOReset
        case cTCReset
        case animationSystemReset
        case fixtureCalibrationReset
        case function
        case lampControl
        case displayIntensity
        case dMXInput
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
        case bladeRot
        case shaperRot
        case shaperMacros
        case shaperMacrosSpeed
        case bladeSoftA
        case bladeSoftB
        case keyStoneA
        case keyStoneB
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

            switch name {
            case "Dimmer": self = .dimmer
            case "Pan": self = .pan
            case "Tilt": self = .tilt
            case "PanRotate": self = .panRotate
            case "TiltRotate": self = .tiltRotate
            case "PositionEffect": self = .positionEffect
            case "PositionEffectRate": self = .positionEffectRate
            case "PositionEffectFade": self = .positionEffectFade
            case "XYZ_X": self = .xYZ_X
            case "XYZ_Y": self = .xYZ_Y
            case "XYZ_Z": self = .xYZ_Z
            case "Rot_X": self = .rot_X
            case "Rot_Y": self = .rot_Y
            case "Rot_Z": self = .rot_Z
            case "Scale_X": self = .scale_X
            case "Scale_Y": self = .scale_Y
            case "Scale_Z": self = .scale_Z
            case "Scale_XYZ": self = .scale_XYZ
            case "Gobo(n)": self = .gobo
            case "Gobo(n)SelectSpin": self = .goboSelectSpin
            case "Gobo(n)SelectShake": self = .goboSelectShake
            case "Gobo(n)SelectEffects": self = .goboSelectEffects
            case "Gobo(n)WheelIndex": self = .goboWheelIndex
            case "Gobo(n)WheelSpin": self = .goboWheelSpin
            case "Gobo(n)WheelShake": self = .goboWheelShake
            case "Gobo(n)WheelRandom": self = .goboWheelRandom
            case "Gobo(n)WheelAudio": self = .goboWheelAudio
            case "Gobo(n)Pos": self = .goboPos
            case "Gobo(n)PosRotate": self = .goboPosRotate
            case "Gobo(n)PosShake": self = .goboPosShake
            case "AnimationWheel(n)": self = .animationWheel
            case "AnimationWheel(n)Audio": self = .animationWheelAudio
            case "AnimationWheel(n)Macro": self = .animationWheelMacro
            case "AnimationWheel(n)Random": self = .animationWheelRandom
            case "AnimationWheel(n)SelectEffects": self = .animationWheelSelectEffects
            case "AnimationWheel(n)SelectShake": self = .animationWheelSelectShake
            case "AnimationWheel(n)SelectSpin": self = .animationWheelSelectSpin
            case "AnimationWheel(n)Pos": self = .animationWheelPos
            case "AnimationWheel(n)PosRotate": self = .animationWheelPosRotate
            case "AnimationWheel(n)PosShake": self = .animationWheelPosShake
            case "AnimationSystem(n)": self = .animationSystem
            case "AnimationSystem(n)Ramp": self = .animationSystemRamp
            case "AnimationSystem(n)Shake": self = .animationSystemShake
            case "AnimationSystem(n)Audio": self = .animationSystemAudio
            case "AnimationSystem(n)Random": self = .animationSystemRandom
            case "AnimationSystem(n)Pos": self = .animationSystemPos
            case "AnimationSystem(n)PosRotate": self = .animationSystemPosRotate
            case "AnimationSystem(n)PosShake": self = .animationSystemPosShake
            case "AnimationSystem(n)PosRandom": self = .animationSystemPosRandom
            case "AnimationSystem(n)PosAudio": self = .animationSystemPosAudio
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
            case "ColorAdd_R": self = .colorAdd_R
            case "ColorAdd_G": self = .colorAdd_G
            case "ColorAdd_B": self = .colorAdd_B
            case "ColorAdd_C": self = .colorAdd_C
            case "ColorAdd_M": self = .colorAdd_M
            case "ColorAdd_Y": self = .colorAdd_Y
            case "ColorAdd_RY": self = .colorAdd_RY
            case "ColorAdd_GY": self = .colorAdd_GY
            case "ColorAdd_GC": self = .colorAdd_GC
            case "ColorAdd_BC": self = .colorAdd_BC
            case "ColorAdd_BM": self = .colorAdd_BM
            case "ColorAdd_RM": self = .colorAdd_RM
            case "ColorAdd_W": self = .colorAdd_W
            case "ColorAdd_WW": self = .colorAdd_WW
            case "ColorAdd_CW": self = .colorAdd_CW
            case "ColorAdd_UV": self = .colorAdd_UV
            case "ColorSub_R": self = .colorSub_R
            case "ColorSub_G": self = .colorSub_G
            case "ColorSub_B": self = .colorSub_B
            case "ColorSub_C": self = .colorSub_C
            case "ColorSub_M": self = .colorSub_M
            case "ColorSub_Y": self = .colorSub_Y
            case "ColorMacro(n)": self = .colorMacro
            case "ColorMacro(n)Rate": self = .colorMacroRate
            case "CTO": self = .cTO
            case "CTC": self = .cTC
            case "CTB": self = .cTB
            case "Tint": self = .tint
            case "HSB_Hue": self = .hSB_Hue
            case "HSB_Saturation": self = .hSB_Saturation
            case "HSB_Brightness": self = .hSB_Brightness
            case "HSB_Quality": self = .hSB_Quality
            case "CIE_X": self = .cIE_X
            case "CIE_Y": self = .cIE_Y
            case "CIE_Brightness": self = .cIE_Brightness
            case "ColorRGB_Red": self = .colorRGB_Red
            case "ColorRGB_Green": self = .colorRGB_Green
            case "ColorRGB_Blue": self = .colorRGB_Blue
            case "ColorRGB_Cyan": self = .colorRGB_Cyan
            case "ColorRGB_Magenta": self = .colorRGB_Magenta
            case "ColorRGB_Yellow": self = .colorRGB_Yellow
            case "ColorRGB_Quality": self = .colorRGB_Quality
            case "VideoBoost_R": self = .videoBoost_R
            case "VideoBoost_G": self = .videoBoost_G
            case "VideoBoost_B": self = .videoBoost_B
            case "VideoHueShift": self = .videoHueShift
            case "VideoSaturation": self = .videoSaturation
            case "VideoBrightness": self = .videoBrightness
            case "VideoContrast": self = .videoContrast
            case "VideoKeyColor_R": self = .videoKeyColor_R
            case "VideoKeyColor_G": self = .videoKeyColor_G
            case "VideoColorKey_B": self = .videoKeyColor_B
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
            case "Prism(n)Pos": self = .prismPos
            case "Prism(n)PosRotate": self = .prismPosRotate
            case "Effects(n)": self = .effects
            case "Effects(n)Rate": self = .effectsRate
            case "Effects(n)Fade": self = .effectsFade
            case "Effects(n)Adjust(m)": self = .effectsAdjust
            case "Effects(n)Pos": self = .effectsPos
            case "Effects(n)PosRotate": self = .effectsPosRotate
            case "EffectsSync": self = .effectsSync
            case "BeamShaper": self = .beamShaper
            case "BeamShaperMacro": self = .beamShaperMacro
            case "BeamShaperPos": self = .beamShaperPos
            case "BeamShaperPosRotate": self = .beamShaperPosRotate
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
            case "LEDFrequency": self = .lEDFrequency
            case "LEDZoneMode": self = .lEDZoneMode
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
            case "CRIMode": self = .cRIMode
            case "CustomColor": self = .customColor
            case "UVStability": self = .uVStability
            case "WaveLengthCorrection": self = .wavelengthCorrection
            case "WhiteCount": self = .whiteCount
            case "StrobeMode": self = .strobeMode
            case "ZoomMode": self = .zoomMode
            case "FocusMode": self = .focusMode
            case "IrisMode": self = .irisMode
            case "FanMode": self = .fanMode
            case "FollowSpotMode": self = .followSpotMode
            case "BeamEffectIndexRotateMode": self = .beamEffectIndexRotateMode
            case "IntensityMSpeed": self = .intensityMSpeed
            case "PositionMSpeed": self = .positionMSpeed
            case "ColorMixMSpeed": self = .colorMixMSpeed
            case "ColorWheelSelectMSpeed": self = .colorWheelSelectMSpeed
            case "GoboWheel(n)MSpeed": self = .goboWheelMSpeed
            case "IrisMSpeed": self = .irisMSpeed
            case "Prism(n)MSpeed": self = .prismMSpeed
            case "FocusMSpeed": self = .focusMSpeed
            case "Frost(n)MSpeed": self = .frostMSpeed
            case "ZoomMSpeed": self = .zoomMSpeed
            case "FrameMSpeed": self = .frameMSpeed
            case "GlobalMSpeed": self = .globalMSpeed
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
            case "CTBReset": self = .cTBReset
            case "CTOReset": self = .cTOReset
            case "CTCReset": self = .cTCReset
            case "AnimationSystemReset": self = .animationSystemReset
            case "FixtureCalibrationReset": self = .fixtureCalibrationReset
            case "Function": self = .function
            case "LampControl": self = .lampControl
            case "DisplayIntensity": self = .displayIntensity
            case "DMXInput": self = .dMXInput
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
            case "Blade(n)Rot": self = .bladeRot
            case "ShaperRot": self = .shaperRot
            case "ShaperMacros": self = .shaperMacros
            case "ShaperMacrosSpeed": self = .shaperMacrosSpeed
            case "BladeSoft(n)A": self = .bladeSoftA
            case "BladeSoft(n)B": self = .bladeSoftB
            case "KeyStone(n)A": self = .keyStoneA
            case "KeyStone(n)B": self = .keyStoneB
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
    case xYZ_X
    case xYZ_Y
    case xYZ_Z
    case rot_X
    case rot_Y
    case rot_Z
    case scale_X
    case scale_Y
    case scale_Z
    case scale_XYZ
    case gobo(n: Int)
    case goboSelectSpin(n: Int)
    case goboSelectShake(n: Int)
    case goboSelectEffects(n: Int)
    case goboWheelIndex(n: Int)
    case goboWheelSpin(n: Int)
    case goboWheelShake(n: Int)
    case goboWheelRandom(n: Int)
    case goboWheelAudio(n: Int)
    case goboPos(n: Int)
    case goboPosRotate(n: Int)
    case goboPosShake(n: Int)
    case animationWheel(n: Int)
    case animationWheelAudio(n: Int)
    case animationWheelMacro(n: Int)
    case animationWheelRandom(n: Int)
    case animationWheelSelectEffects(n: Int)
    case animationWheelSelectShake(n: Int)
    case animationWheelSelectSpin(n: Int)
    case animationWheelPos(n: Int)
    case animationWheelPosRotate(n: Int)
    case animationWheelPosShake(n: Int)
    case animationSystem(n: Int)
    case animationSystemRamp(n: Int)
    case animationSystemShake(n: Int)
    case animationSystemAudio(n: Int)
    case animationSystemRandom(n: Int)
    case animationSystemPos(n: Int)
    case animationSystemPosRotate(n: Int)
    case animationSystemPosShake(n: Int)
    case animationSystemPosRandom(n: Int)
    case animationSystemPosAudio(n: Int)
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
    case colorAdd_R
    case colorAdd_G
    case colorAdd_B
    case colorAdd_C
    case colorAdd_M
    case colorAdd_Y
    case colorAdd_RY
    case colorAdd_GY
    case colorAdd_GC
    case colorAdd_BC
    case colorAdd_BM
    case colorAdd_RM
    case colorAdd_W
    case colorAdd_WW
    case colorAdd_CW
    case colorAdd_UV
    case colorSub_R
    case colorSub_G
    case colorSub_B
    case colorSub_C
    case colorSub_M
    case colorSub_Y
    case colorMacro(n: Int)
    case colorMacroRate(n: Int)
    case cTO
    case cTC
    case cTB
    case tint
    case hSB_Hue
    case hSB_Saturation
    case hSB_Brightness
    case hSB_Quality
    case cIE_X
    case cIE_Y
    case cIE_Brightness
    case colorRGB_Red
    case colorRGB_Green
    case colorRGB_Blue
    case colorRGB_Cyan
    case colorRGB_Magenta
    case colorRGB_Yellow
    case colorRGB_Quality
    case videoBoost_R
    case videoBoost_G
    case videoBoost_B
    case videoHueShift
    case videoSaturation
    case videoBrightness
    case videoContrast
    case videoKeyColor_R
    case videoKeyColor_G
    case videoKeyColor_B
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
    case prismPos(n: Int)
    case prismPosRotate(n: Int)
    case effects(n: Int)
    case effectsRate(n: Int)
    case effectsFade(n: Int)
    case effectsAdjust(n: Int, m: Int)
    case effectsPos(n: Int)
    case effectsPosRotate(n: Int)
    case effectsSync
    case beamShaper
    case beamShaperMacro
    case beamShaperPos
    case beamShaperPosRotate
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
    case lEDFrequency
    case lEDZoneMode
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
    case cRIMode
    case customColor
    case uVStability
    case wavelengthCorrection
    case whiteCount
    case strobeMode
    case zoomMode
    case focusMode
    case irisMode
    case fanMode(n: Int)
    case followSpotMode
    case beamEffectIndexRotateMode
    case intensityMSpeed(n: Int)
    case positionMSpeed(n: Int)
    case colorMixMSpeed(n: Int)
    case colorWheelSelectMSpeed(n: Int)
    case goboWheelMSpeed(n: Int)
    case irisMSpeed(n: Int)
    case prismMSpeed(n: Int)
    case focusMSpeed(n: Int)
    case frostMSpeed(n: Int)
    case zoomMSpeed(n: Int)
    case frameMSpeed(n: Int)
    case globalMSpeed(n: Int)
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
    case cTBReset
    case cTOReset
    case cTCReset
    case animationSystemReset
    case fixtureCalibrationReset
    case function
    case lampControl
    case displayIntensity
    case dMXInput
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
    case bladeRot(n: Int)
    case shaperRot
    case shaperMacros
    case shaperMacrosSpeed
    case bladeSoftA(n: Int)
    case bladeSoftB(n: Int)
    case keyStoneA(n: Int)
    case keyStoneB(n: Int)
    case video
    case videoEffectType(n: Int)
    case videoEffectParameter(n: Int, m: Int)
    case videoCamera(n: Int)
    case videoSoundVolume(n: Int)
    case videoBlendMode
    case inputSource
    case fieldOfView
    case custom(name: String)

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
        case .xYZ_X: return "X Position"
        case .xYZ_Y: return "Y Position"
        case .xYZ_Z: return "Z Position"
        case .rot_X: return "X Rotation"
        case .rot_Y: return "Y Rotation"
        case .rot_Z: return "Z Rotation"
        case .scale_X: return "X Scale"
        case .scale_Y: return "Y Scale"
        case .scale_Z: return "Z Scale"
        case .scale_XYZ: return "XYZ Scale"
        
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
        case .goboPos(let n): return "Gobo \(n) Position"
        case .goboPosRotate(let n): return "Gobo \(n) Position Rotate"
        case .goboPosShake(let n): return "Gobo \(n) Position Shake"
        
        // Animation Wheel
        case .animationWheel(let n): return "Animation Wheel \(n)"
        case .animationWheelAudio(let n): return "Animation Wheel \(n) Audio"
        case .animationWheelMacro(let n): return "Animation Wheel \(n) Macro"
        case .animationWheelRandom(let n): return "Animation Wheel \(n) Random"
        case .animationWheelSelectEffects(let n): return "Animation Wheel \(n) Select Effects"
        case .animationWheelSelectShake(let n): return "Animation Wheel \(n) Select Shake"
        case .animationWheelSelectSpin(let n): return "Animation Wheel \(n) Select Spin"
        case .animationWheelPos(let n): return "Animation Wheel \(n) Position"
        case .animationWheelPosRotate(let n): return "Animation Wheel \(n) Position Rotate"
        case .animationWheelPosShake(let n): return "Animation Wheel \(n) Position Shake"
        
        // Animation System
        case .animationSystem(let n): return "Animation System \(n)"
        case .animationSystemRamp(let n): return "Animation System \(n) Ramp"
        case .animationSystemShake(let n): return "Animation System \(n) Shake"
        case .animationSystemAudio(let n): return "Animation System \(n) Audio"
        case .animationSystemRandom(let n): return "Animation System \(n) Random"
        case .animationSystemPos(let n): return "Animation System \(n) Position"
        case .animationSystemPosRotate(let n): return "Animation System \(n) Position Rotate"
        case .animationSystemPosShake(let n): return "Animation System \(n) Position Shake"
        case .animationSystemPosRandom(let n): return "Animation System \(n) Position Random"
        case .animationSystemPosAudio(let n): return "Animation System \(n) Position Audio"
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
        case .colorAdd_R: return "Color Add Red"
        case .colorAdd_G: return "Color Add Green"
        case .colorAdd_B: return "Color Add Blue"
        case .colorAdd_C: return "Color Add Cyan"
        case .colorAdd_M: return "Color Add Magenta"
        case .colorAdd_Y: return "Color Add Yellow"
        case .colorAdd_RY: return "Color Add Red-Yellow"
        case .colorAdd_GY: return "Color Add Green-Yellow"
        case .colorAdd_GC: return "Color Add Green-Cyan"
        case .colorAdd_BC: return "Color Add Blue-Cyan"
        case .colorAdd_BM: return "Color Add Blue-Magenta"
        case .colorAdd_RM: return "Color Add Red-Magenta"
        case .colorAdd_W: return "Color Add White"
        case .colorAdd_WW: return "Color Add Warm White"
        case .colorAdd_CW: return "Color Add Cool White"
        case .colorAdd_UV: return "Color Add UV"
        
        // Color Sub
        case .colorSub_R: return "Color Sub Red"
        case .colorSub_G: return "Color Sub Green"
        case .colorSub_B: return "Color Sub Blue"
        case .colorSub_C: return "Color Sub Cyan"
        case .colorSub_M: return "Color Sub Magenta"
        case .colorSub_Y: return "Color Sub Yellow"
        
        // Color Macros & Temperature
        case .colorMacro(let n): return "Color Macro \(n)"
        case .colorMacroRate(let n): return "Color Macro \(n) Rate"
        case .cTO: return "CTO"
        case .cTC: return "CTC"
        case .cTB: return "CTB"
        case .tint: return "Tint"
        
        // HSB
        case .hSB_Hue: return "HSB Hue"
        case .hSB_Saturation: return "HSB Saturation"
        case .hSB_Brightness: return "HSB Brightness"
        case .hSB_Quality: return "HSB Quality"
        
        // CIE
        case .cIE_X: return "CIE X"
        case .cIE_Y: return "CIE Y"
        case .cIE_Brightness: return "CIE Brightness"
        
        // RGB
        case .colorRGB_Red: return "RGB Red"
        case .colorRGB_Green: return "RGB Green"
        case .colorRGB_Blue: return "RGB Blue"
        case .colorRGB_Cyan: return "RGB Cyan"
        case .colorRGB_Magenta: return "RGB Magenta"
        case .colorRGB_Yellow: return "RGB Yellow"
        case .colorRGB_Quality: return "RGB Quality"
        
        // Video
        case .videoBoost_R: return "Video Boost Red"
        case .videoBoost_G: return "Video Boost Green"
        case .videoBoost_B: return "Video Boost Blue"
        case .videoHueShift: return "Video Hue Shift"
        case .videoSaturation: return "Video Saturation"
        case .videoBrightness: return "Video Brightness"
        case .videoContrast: return "Video Contrast"
        case .videoKeyColor_R: return "Video Key Red"
        case .videoKeyColor_G: return "Video Key Green"
        case .videoKeyColor_B: return "Video Key Blue"
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
        case .prismPos(let n): return "Prism \(n) Position"
        case .prismPosRotate(let n): return "Prism \(n) Position Rotate"
        
        // Effects
        case .effects(let n): return "Effects \(n)"
        case .effectsRate(let n): return "Effects \(n) Rate"
        case .effectsFade(let n): return "Effects \(n) Fade"
        case .effectsAdjust(let n, let m): return "Effects \(n) Adjust \(m)"
        case .effectsPos(let n): return "Effects \(n) Position"
        case .effectsPosRotate(let n): return "Effects \(n) Position Rotate"
        case .effectsSync: return "Effects Sync"
        
        // Beam Shaper
        case .beamShaper: return "Beam Shaper"
        case .beamShaperMacro: return "Beam Shaper Macro"
        case .beamShaperPos: return "Beam Shaper Position"
        case .beamShaperPosRotate: return "Beam Shaper Position Rotate"
        
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
        case .lEDFrequency: return "LED Frequency"
        case .lEDZoneMode: return "LED Zone Mode"
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
        case .cRIMode: return "CRI Mode"
        case .customColor: return "Custom Color"
        case .uVStability: return "UV Stability"
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
        case .intensityMSpeed(let n): return "Intensity Speed \(n)"
        case .positionMSpeed(let n): return "Position Speed \(n)"
        case .colorMixMSpeed(let n): return "Color Mix Speed \(n)"
        case .colorWheelSelectMSpeed(let n): return "Color Wheel Select Speed \(n)"
        case .goboWheelMSpeed(let n): return "Gobo Wheel Speed \(n)"
        case .irisMSpeed(let n): return "Iris Speed \(n)"
        case .prismMSpeed(let n): return "Prism Speed \(n)"
        case .focusMSpeed(let n): return "Focus Speed \(n)"
        case .frostMSpeed(let n): return "Frost Speed \(n)"
        case .zoomMSpeed(let n): return "Zoom Speed \(n)"
        case .frameMSpeed(let n): return "Frame Speed \(n)"
        case .globalMSpeed(let n): return "Global Speed \(n)"
        
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
        case .cTBReset: return "CTB Reset"
        case .cTOReset: return "CTO Reset"
        case .cTCReset: return "CTC Reset"
        case .animationSystemReset: return "Animation System Reset"
        case .fixtureCalibrationReset: return "Fixture Calibration Reset"
        
        // Misc
        case .function: return "Function"
        case .lampControl: return "Lamp Control"
        case .displayIntensity: return "Display Intensity"
        case .dMXInput: return "DMX Input"
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
        case .bladeRot(let n): return "Blade \(n) Rotation"
        case .shaperRot: return "Shaper Rotation"
        case .shaperMacros: return "Shaper Macros"
        case .shaperMacrosSpeed: return "Shaper Macros Speed"
        case .bladeSoftA(let n): return "Blade Soft A\(n)"
        case .bladeSoftB(let n): return "Blade Soft B\(n)"
        case .keyStoneA(let n): return "Keystone A\(n)"
        case .keyStoneB(let n): return "Keystone B\(n)"
        
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
        case .xYZ_X: return .xYZ_X
        case .xYZ_Y: return .xYZ_Y
        case .xYZ_Z: return .xYZ_Z
        case .rot_X: return .rot_X
        case .rot_Y: return .rot_Y
        case .rot_Z: return .rot_Z
        case .scale_X: return .scale_X
        case .scale_Y: return .scale_Y
        case .scale_Z: return .scale_Z
        case .scale_XYZ: return .scale_XYZ
        case .gobo: return .gobo
        case .goboSelectSpin: return .goboSelectSpin
        case .goboSelectShake: return .goboSelectShake
        case .goboSelectEffects: return .goboSelectEffects
        case .goboWheelIndex: return .goboWheelIndex
        case .goboWheelSpin: return .goboWheelSpin
        case .goboWheelShake: return .goboWheelShake
        case .goboWheelRandom: return .goboWheelRandom
        case .goboWheelAudio: return .goboWheelAudio
        case .goboPos: return .goboPos
        case .goboPosRotate: return .goboPosRotate
        case .goboPosShake: return .goboPosShake
        case .animationWheel: return .animationWheel
        case .animationWheelAudio: return .animationWheelAudio
        case .animationWheelMacro: return .animationWheelMacro
        case .animationWheelRandom: return .animationWheelRandom
        case .animationWheelSelectEffects: return .animationWheelSelectEffects
        case .animationWheelSelectShake: return .animationWheelSelectShake
        case .animationWheelSelectSpin: return .animationWheelSelectSpin
        case .animationWheelPos: return .animationWheelPos
        case .animationWheelPosRotate: return .animationWheelPosRotate
        case .animationWheelPosShake: return .animationWheelPosShake
        case .animationSystem: return .animationSystem
        case .animationSystemRamp: return .animationSystemRamp
        case .animationSystemShake: return .animationSystemShake
        case .animationSystemAudio: return .animationSystemAudio
        case .animationSystemRandom: return .animationSystemRandom
        case .animationSystemPos: return .animationSystemPos
        case .animationSystemPosRotate: return .animationSystemPosRotate
        case .animationSystemPosShake: return .animationSystemPosShake
        case .animationSystemPosRandom: return .animationSystemPosRandom
        case .animationSystemPosAudio: return .animationSystemPosAudio
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
        case .colorAdd_R: return .colorAdd_R
        case .colorAdd_G: return .colorAdd_G
        case .colorAdd_B: return .colorAdd_B
        case .colorAdd_C: return .colorAdd_C
        case .colorAdd_M: return .colorAdd_M
        case .colorAdd_Y: return .colorAdd_Y
        case .colorAdd_RY: return .colorAdd_RY
        case .colorAdd_GY: return .colorAdd_GY
        case .colorAdd_GC: return .colorAdd_GC
        case .colorAdd_BC: return .colorAdd_BC
        case .colorAdd_BM: return .colorAdd_BM
        case .colorAdd_RM: return .colorAdd_RM
        case .colorAdd_W: return .colorAdd_W
        case .colorAdd_WW: return .colorAdd_WW
        case .colorAdd_CW: return .colorAdd_CW
        case .colorAdd_UV: return .colorAdd_UV
        case .colorSub_R: return .colorSub_R
        case .colorSub_G: return .colorSub_G
        case .colorSub_B: return .colorSub_B
        case .colorSub_C: return .colorSub_C
        case .colorSub_M: return .colorSub_M
        case .colorSub_Y: return .colorSub_Y
        case .colorMacro: return .colorMacro
        case .colorMacroRate: return .colorMacroRate
        case .cTO: return .cTO
        case .cTC: return .cTC
        case .cTB: return .cTB
        case .tint: return .tint
        case .hSB_Hue: return .hSB_Hue
        case .hSB_Saturation: return .hSB_Saturation
        case .hSB_Brightness: return .hSB_Brightness
        case .hSB_Quality: return .hSB_Quality
        case .cIE_X: return .cIE_X
        case .cIE_Y: return .cIE_Y
        case .cIE_Brightness: return .cIE_Brightness
        case .colorRGB_Red: return .colorRGB_Red
        case .colorRGB_Green: return .colorRGB_Green
        case .colorRGB_Blue: return .colorRGB_Blue
        case .colorRGB_Cyan: return .colorRGB_Cyan
        case .colorRGB_Magenta: return .colorRGB_Magenta
        case .colorRGB_Yellow: return .colorRGB_Yellow
        case .colorRGB_Quality: return .colorRGB_Quality
        case .videoBoost_R: return .videoBoost_R
        case .videoBoost_G: return .videoBoost_G
        case .videoBoost_B: return .videoBoost_B
        case .videoHueShift: return .videoHueShift
        case .videoSaturation: return .videoSaturation
        case .videoBrightness: return .videoBrightness
        case .videoContrast: return .videoContrast
        case .videoKeyColor_R: return .videoKeyColor_R
        case .videoKeyColor_G: return .videoKeyColor_G
        case .videoKeyColor_B: return .videoKeyColor_B
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
        case .prismPos: return .prismPos
        case .prismPosRotate: return .prismPosRotate
        case .effects: return .effects
        case .effectsRate: return .effectsRate
        case .effectsFade: return .effectsFade
        case .effectsAdjust: return .effectsAdjust
        case .effectsPos: return .effectsPos
        case .effectsPosRotate: return .effectsPosRotate
        case .effectsSync: return .effectsSync
        case .beamShaper: return .beamShaper
        case .beamShaperMacro: return .beamShaperMacro
        case .beamShaperPos: return .beamShaperPos
        case .beamShaperPosRotate: return .beamShaperPosRotate
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
        case .lEDFrequency: return .lEDFrequency
        case .lEDZoneMode: return .lEDZoneMode
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
        case .cRIMode: return .cRIMode
        case .customColor: return .customColor
        case .uVStability: return .uVStability
        case .wavelengthCorrection: return .wavelengthCorrection
        case .whiteCount: return .whiteCount
        case .strobeMode: return .strobeMode
        case .zoomMode: return .zoomMode
        case .focusMode: return .focusMode
        case .irisMode: return .irisMode
        case .fanMode: return .fanMode
        case .followSpotMode: return .followSpotMode
        case .beamEffectIndexRotateMode: return .beamEffectIndexRotateMode
        case .intensityMSpeed: return .intensityMSpeed
        case .positionMSpeed: return .positionMSpeed
        case .colorMixMSpeed: return .colorMixMSpeed
        case .colorWheelSelectMSpeed: return .colorWheelSelectMSpeed
        case .goboWheelMSpeed: return .goboWheelMSpeed
        case .irisMSpeed: return .irisMSpeed
        case .prismMSpeed: return .prismMSpeed
        case .focusMSpeed: return .focusMSpeed
        case .frostMSpeed: return .frostMSpeed
        case .zoomMSpeed: return .zoomMSpeed
        case .frameMSpeed: return .frameMSpeed
        case .globalMSpeed: return .globalMSpeed
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
        case .cTBReset: return .cTBReset
        case .cTOReset: return .cTOReset
        case .cTCReset: return .cTCReset
        case .animationSystemReset: return .animationSystemReset
        case .fixtureCalibrationReset: return .fixtureCalibrationReset
        case .function: return .function
        case .lampControl: return .lampControl
        case .displayIntensity: return .displayIntensity
        case .dMXInput: return .dMXInput
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
        case .bladeRot: return .bladeRot
        case .shaperRot: return .shaperRot
        case .shaperMacros: return .shaperMacros
        case .shaperMacrosSpeed: return .shaperMacrosSpeed
        case .bladeSoftA: return .bladeSoftA
        case .bladeSoftB: return .bladeSoftB
        case .keyStoneA: return .keyStoneA
        case .keyStoneB: return .keyStoneB
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


}

