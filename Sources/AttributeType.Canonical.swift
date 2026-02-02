//
//  Untitled.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 12/25/25.
//

extension AttributeType {
    /// Canonical representation of AttributeType cases without associated values (except custom)
    public enum Canonical: Hashable, Codable, Sendable, CodingKeyRepresentable, Comparable {
        public static func <(lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.custom(let lhs), .custom(let rhs)):
                return lhs < rhs
            case (.custom, _):
                return false
            case (_, .custom):
                return true
            default:
                assert(!lhs.isCustom && !rhs.isCustom)
                let lhs = AttributeDescription.attributes.keys.firstIndex(of: lhs)!
                let rhs = AttributeDescription.attributes.keys.firstIndex(of: rhs)!
                return lhs < rhs
            }
        }
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
        
        public var isCustom: Bool {
            if case .custom = self {
                true
            } else {
                false
            }
        }

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
}
