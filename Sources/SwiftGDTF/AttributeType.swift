//
//  AttributeTYpe.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 12/25/25.
//

// see Annex A: https://github.com/mvrdevelopment/spec/blob/main/gdtf-spec.md#annex-a-normative-attribute-definitions
public enum AttributeType: Hashable, Codable, CustomStringConvertible, Sendable {
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
    case fanMode
    case followSpotMode
    case beamEffectIndexRotateMode
    case intensityMovementSpeed
    case positionMovementSpeed
    case colorMixMovementSpeed
    case colorWheelSelectMovementSpeed
    case goboWheelMovementSpeed(n: Int)
    case irisMovementSpeed
    case prismMovementSpeed(n: Int)
    case focusMovementSpeed
    case frostMovementSpeed(n: Int)
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
        case .fanMode: return "Fan Mode"
        case .followSpotMode: return "Follow Spot Mode"
        case .beamEffectIndexRotateMode: return "Beam Effect Index Rotate Mode"

            // Speed
        case .intensityMovementSpeed: return "Intensity Movement Speed"
        case .positionMovementSpeed: return "Position Movement Speed"
        case .colorMixMovementSpeed: return "Color Mix Movement Speed"
        case .colorWheelSelectMovementSpeed: return "Color Wheel Select Movement Speed"
        case .goboWheelMovementSpeed(let n): return "Gobo Wheel Movement Speed \(n)"
        case .irisMovementSpeed: return "Iris Movement Speed"
        case .prismMovementSpeed(let n): return "Prism Movement Speed \(n)"
        case .focusMovementSpeed: return "Focus Movement Speed"
        case .frostMovementSpeed(let n): return "Frost Movement Speed \(n)"
        case .zoomMovementSpeed: return "Zoom Movement Speed"
        case .frameMovementSpeed: return "Frame Movement Speed"
        case .globalMovementSpeed: return "Global Movement Speed"

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

extension AttributeType {
    private static let prefix: [Substring: AttributeType] = [
        "Dimmer": .dimmer,
        "Pan": .pan,
        "Tilt": .tilt,
        "PanRotate": .panRotate,
        "TiltRotate": .tiltRotate,
        "PositionEffect": .positionEffect,
        "PositionEffectRate": .positionEffectRate,
        "PositionEffectFade": .positionEffectFade,
        "XYZ_X": .xyzX,
        "XYZ_Y": .xyzY,
        "XYZ_Z": .xyzZ,
        "Rot_X": .rotationX,
        "Rot_Y": .rotationY,
        "Rot_Z": .rotationZ,
        "Scale_X": .scaleX,
        "Scale_Y": .scaleY,
        "Scale_Z": .scaleZ,
        "Scale_XYZ": .scaleXYZ,
        "PlayMode": .playMode,
        "Playmode": .playMode,
        "PlayBegin": .playBegin,
        "PlayEnd": .playEnd,
        "PlaySpeed": .playSpeed,
        "ColorAdd_R": .colorAddRed,
        "ColorAdd_G": .colorAddGreen,
        "ColorAdd_B": .colorAddBlue,
        "ColorAdd_C": .colorAddCyan,
        "ColorAdd_M": .colorAddMagenta,
        "ColorAdd_Y": .colorAddYellow,
        "ColorAdd_RY": .colorAddRedYellow,
        "ColorAdd_GY": .colorAddGreenYellow,
        "ColorAdd_GC": .colorAddGreenCyan,
        "ColorAdd_BC": .colorAddBlueCyan,
        "ColorAdd_BM": .colorAddBlueMagenta,
        "ColorAdd_RM": .colorAddRedMagenta,
        "ColorAdd_W": .colorAddWhite,
        "ColorAdd_WW": .colorAddWarmWhite,
        "ColorAdd_CW": .colorAddCoolWhite,
        "ColorAdd_UV": .colorAddUltraviolet,
        "ColorSub_R": .colorSubtractRed,
        "ColorSub_G": .colorSubtractGreen,
        "ColorSub_B": .colorSubtractBlue,
        "ColorSub_C": .colorSubtractCyan,
        "ColorSub_M": .colorSubtractMagenta,
        "ColorSub_Y": .colorSubtractYellow,
        "CTO": .colorTemperatureOrange,
        "CTC": .colorTemperatureCorrection,
        "CTB": .colorTemperatureBlue,
        "Tint": .tint,
        "HSB_Hue": .hueShiftBlueHue,
        "HSB_Saturation": .hueShiftBlueSaturation,
        "HSB_Brightness": .hueShiftBlueBrightness,
        "HSB_Quality": .hueShiftBlueQuality,
        "CIE_X": .chromaticityX,
        "CIE_Y": .chromaticityY,
        "CIE_Brightness": .chromaticityBrightness,
        "ColorRGB_Red": .colorRGBRed,
        "ColorRGB_Green": .colorRGBGreen,
        "ColorRGB_Blue": .colorRGBBlue,
        "ColorRGB_Cyan": .colorRGBCyan,
        "ColorRGB_Magenta": .colorRGBMagenta,
        "ColorRGB_Yellow": .colorRGBYellow,
        "ColorRGB_Quality": .colorRGBQuality,
        "VideoBoost_R": .videoBoostRed,
        "VideoBoost_G": .videoBoostGreen,
        "VideoBoost_B": .videoBoostBlue,
        "VideoHueShift": .videoHueShift,
        "VideoSaturation": .videoSaturation,
        "VideoBrightness": .videoBrightness,
        "VideoContrast": .videoContrast,
        "VideoKeyColor_R": .videoKeyColorRed,
        "VideoKeyColor_G": .videoKeyColorGreen,
        // This should really be VideoKeyColor_B but the spec got it initally wrong and we have two fixtures that use this
        "VideoColorKey_B": .videoKeyColorBlue,
        "VideoKeyIntensity": .videoKeyIntensity,
        "VideoKeyTolerance": .videoKeyTolerance,
        "StrobeDuration": .strobeDuration,
        "StrobeRate": .strobeRate,
        "StrobeFrequency": .strobeFrequency,
        "StrobeModeShutter": .strobeModeShutter,
        "StrobeModeStrobe": .strobeModeStrobe,
        "StrobeModePulse": .strobeModePulse,
        "StrobeModePulseOpen": .strobeModePulseOpen,
        "StrobeModePulseClose": .strobeModePulseClose,
        "StrobeModeRandom": .strobeModeRandom,
        "StrobeModeRandomPulse": .strobeModeRandomPulse,
        "StrobeModeRandomPulseOpen": .strobeModeRandomPulseOpen,
        "StrobeModeRandomPulseClose": .strobeModeRandomPulseClose,
        "StrobeModeEffect": .strobeModeEffect,
        "Iris": .iris,
        "IrisStrobe": .irisStrobe,
        "IrisStrobeRandom": .irisStrobeRandom,
        "IrisPulseClose": .irisPulseClose,
        "IrisPulseOpen": .irisPulseOpen,
        "IrisRandomPulseClose": .irisRandomPulseClose,
        "IrisRandomPulseOpen": .irisRandomPulseOpen,
        "EffectsSync": .effectsSync,
        "BeamShaper": .beamShaper,
        "BeamShaperMacro": .beamShaperMacro,
        "BeamShaperPos": .beamShaperPosition,
        "BeamShaperPosRotate": .beamShaperPositionRotate,
        "Zoom": .zoom,
        "ZoomModeSpot": .zoomModeSpot,
        "ZoomModeBeam": .zoomModeBeam,
        "DigitalZoom": .digitalZoom,
        "DimmerMode": .dimmerMode,
        "DimmerCurve": .dimmerCurve,
        "BlackoutMode": .blackoutMode,
        "LEDFrequency": .ledFrequency,
        "LEDZoneMode": .ledZoneMode,
        "PixelMode": .pixelMode,
        "PanMode": .panMode,
        "TiltMode": .tiltMode,
        "PanTiltMode": .panTiltMode,
        "PositionModes": .positionModes,
        "GoboWheelShortcutMode": .goboWheelShortcutMode,
        "AnimationWheelShortcutMode": .animationWheelShortcutMode,
        "ColorWheelShortcutMode": .colorWheelShortcutMode,
        "CyanMode": .cyanMode,
        "MagentaMode": .magentaMode,
        "YellowMode": .yellowMode,
        "ColorMixMode": .colorMixMode,
        "ChromaticMode": .chromaticMode,
        "ColorCalibrationMode": .colorCalibrationMode,
        "ColorConsistency": .colorConsistency,
        "ColorControl": .colorControl,
        "ColorModelMode": .colorModelMode,
        "ColorSettingsReset": .colorSettingsReset,
        "ColorUniformity": .colorUniformity,
        "CRIMode": .colorRenderingIndexMode,
        "CustomColor": .customColor,
        "UVStability": .ultravioletStability,
        // spec has WaveLengthCorrection listed in Annex B
        "WavelengthCorrection": .wavelengthCorrection,
        "WhiteCount": .whiteCount,
        "StrobeMode": .strobeMode,
        "ZoomMode": .zoomMode,
        "FocusMode": .focusMode,
        "IrisMode": .irisMode,
        "FanMode": .fanMode,
        "FollowSpotMode": .followSpotMode,
        "BeamEffectIndexRotateMode": .beamEffectIndexRotateMode,
        "IntensityMSpeed": .intensityMovementSpeed,
        "PositionMSpeed": .positionMovementSpeed,
        "ColorMixMSpeed": .colorMixMovementSpeed,
        "ColorWheelSelectMSpeed": .colorWheelSelectMovementSpeed,
        "IrisMSpeed": .irisMovementSpeed,
        "FocusMSpeed": .focusMovementSpeed,
        "ZoomMSpeed": .zoomMovementSpeed,
        "FrameMSpeed": .frameMovementSpeed,
        "GlobalMSpeed": .globalMovementSpeed,
        "ReflectorAdjust": .reflectorAdjust,
        "FixtureGlobalReset": .fixtureGlobalReset,
        "DimmerReset": .dimmerReset,
        "ShutterReset": .shutterReset,
        "BeamReset": .beamReset,
        "ColorMixReset": .colorMixReset,
        "ColorWheelReset": .colorWheelReset,
        "FocusReset": .focusReset,
        "FrameReset": .frameReset,
        "GoboWheelReset": .goboWheelReset,
        "IntensityReset": .intensityReset,
        "IrisReset": .irisReset,
        "PositionReset": .positionReset,
        "PanReset": .panReset,
        "TiltReset": .tiltReset,
        "ZoomReset": .zoomReset,
        "CTBReset": .colorTemperatureBlueReset,
        "CTOReset": .colorTemperatureOrangeReset,
        "CTCReset": .colorTemperatureCorrectionReset,
        "AnimationSystemReset": .animationSystemReset,
        "FixtureCalibrationReset": .fixtureCalibrationReset,
        "Function": .function,
        "LampControl": .lampControl,
        "DisplayIntensity": .displayIntensity,
        "DMXInput": .dmxInput,
        "NoFeature": .noFeature,
        "Dummy": .dummy,
        "LampPowerMode": .lampPowerMode,
        "Fans": .fans,
        "ShaperRot": .shaperRotation,
        "ShaperMacros": .shaperMacros,
        "ShaperMacrosSpeed": .shaperMacrosSpeed,
        "Video": .video,
        "VideoBlendMode": .videoBlendMode,
        "InputSource": .inputSource,
        "FieldOfView": .fieldOfView,
    ]
    private static let prefixN: [Substring: @convention(thin) (Int) -> AttributeType] = [
        "Gobo": { n in .gobo(n: n) },
        "AnimationWheel": { n in .animationWheel(n: n) },
        "AnimationSystem": { n in .animationSystem(n: n) },
        "MediaFolder": { n in .mediaFolder(n: n) },
        "MediaContent": { n in .mediaContent(n: n) },
        "ModelFolder": { n in .modelFolder(n: n) },
        "ModelContent": { n in .modelContent(n: n) },
        "ColorEffects": { n in .colorEffects(n: n) },
        "Color": { n in .color(n: n) },
        "ColorMacro": { n in .colorMacro(n: n) },
        "Shutter": { n in .shutter(n: n) },
        "Frost": { n in .frost(n: n) },
        "Prism": { n in .prism(n: n) },
        "Effects": { n in .effects(n: n) },
        "Focus": { n in .focus(n: n) },
        "Control": { n in .control(n: n) },
        "Blower": { n in .blower(n: n) },
        "Fan": { n in .fan(n: n) },
        "Fog": { n in .fog(n: n) },
        "Haze": { n in .haze(n: n) },
        "VideoCamera": { n in .videoCamera(n: n) },
        "VideoSoundVolume": { n in .videoSoundVolume(n: n) },
    ]
    private struct PrefixSuffix: Hashable {
        var prefix: Substring
        var suffix: Substring
        init(_ prefix: Substring, _ suffix: Substring) {
            self.prefix = prefix
            self.suffix = suffix
        }
    }
    private static let prefixNSuffix: [PrefixSuffix: @convention(thin) (Int) -> AttributeType] = [
        .init("Gobo", "SelectSpin"): { n in .goboSelectSpin(n: n) },
        .init("Gobo", "SelectShake"): { n in .goboSelectShake(n: n) },
        .init("Gobo", "SelectEffects"): { n in .goboSelectEffects(n: n) },
        .init("Gobo", "WheelIndex"): { n in .goboWheelIndex(n: n) },
        .init("Gobo", "WheelSpin"): { n in .goboWheelSpin(n: n) },
        .init("Gobo", "WheelShake"): { n in .goboWheelShake(n: n) },
        .init("Gobo", "WheelRandom"): { n in .goboWheelRandom(n: n) },
        .init("Gobo", "WheelAudio"): { n in .goboWheelAudio(n: n) },
        .init("Gobo", "Pos"): { n in .goboPosition(n: n) },
        .init("Gobo", "PosRotate"): { n in .goboPositionRotate(n: n) },
        .init("Gobo", "PosShake"): { n in .goboPositionShake(n: n) },
        .init("AnimationWheel", "Audio"): { n in .animationWheelAudio(n: n) },
        .init("AnimationWheel", "Macro"): { n in .animationWheelMacro(n: n) },
        .init("AnimationWheel", "Random"): { n in .animationWheelRandom(n: n) },
        .init("AnimationWheel", "SelectEffects"): { n in .animationWheelSelectEffects(n: n) },
        .init("AnimationWheel", "SelectShake"): { n in .animationWheelSelectShake(n: n) },
        .init("AnimationWheel", "SelectSpin"): { n in .animationWheelSelectSpin(n: n) },
        .init("AnimationWheel", "Pos"): { n in .animationWheelPosition(n: n) },
        .init("AnimationWheel", "PosRotate"): { n in .animationWheelPositionRotate(n: n) },
        .init("AnimationWheel", "PosShake"): { n in .animationWheelPositionShake(n: n) },
        .init("AnimationSystem", "Ramp"): { n in .animationSystemRamp(n: n) },
        .init("AnimationSystem", "Shake"): { n in .animationSystemShake(n: n) },
        .init("AnimationSystem", "Audio"): { n in .animationSystemAudio(n: n) },
        .init("AnimationSystem", "Random"): { n in .animationSystemRandom(n: n) },
        .init("AnimationSystem", "Pos"): { n in .animationSystemPosition(n: n) },
        .init("AnimationSystem", "PosRotate"): { n in .animationSystemPositionRotate(n: n) },
        .init("AnimationSystem", "PosShake"): { n in .animationSystemPositionShake(n: n) },
        .init("AnimationSystem", "PosRandom"): { n in .animationSystemPositionRandom(n: n) },
        .init("AnimationSystem", "PosAudio"): { n in .animationSystemPositionAudio(n: n) },
        .init("AnimationSystem", "Macro"): { n in .animationSystemMacro(n: n) },
        .init("Color", "WheelIndex"): { n in .colorWheelIndex(n: n) },
        .init("Color", "WheelSpin"): { n in .colorWheelSpin(n: n) },
        .init("Color", "WheelRandom"): { n in .colorWheelRandom(n: n) },
        .init("Color", "WheelAudio"): { n in .colorWheelAudio(n: n) },
        .init("ColorMacro", "Rate"): { n in .colorMacroRate(n: n) },
        .init("Shutter", "Strobe"): { n in .shutterStrobe(n: n) },
        .init("Shutter", "StrobePulse"): { n in .shutterStrobePulse(n: n) },
        .init("Shutter", "StrobePulseClose"): { n in .shutterStrobePulseClose(n: n) },
        .init("Shutter", "StrobePulseOpen"): { n in .shutterStrobePulseOpen(n: n) },
        .init("Shutter", "StrobeRandom"): { n in .shutterStrobeRandom(n: n) },
        .init("Shutter", "StrobeRandomPulse"): { n in .shutterStrobeRandomPulse(n: n) },
        .init("Shutter", "StrobeRandomPulseClose"): { n in .shutterStrobeRandomPulseClose(n: n) },
        .init("Shutter", "StrobeRandomPulseOpen"): { n in .shutterStrobeRandomPulseOpen(n: n) },
        .init("Shutter", "StrobeEffect"): { n in .shutterStrobeEffect(n: n) },
        .init("Frost", "PulseOpen"): { n in .frostPulseOpen(n: n) },
        .init("Frost", "PulseClose"): { n in .frostPulseClose(n: n) },
        .init("Frost", "Ramp"): { n in .frostRamp(n: n) },
        .init("Prism", "SelectSpin"): { n in .prismSelectSpin(n: n) },
        .init("Prism", "Macro"): { n in .prismMacro(n: n) },
        .init("Prism", "Pos"): { n in .prismPosition(n: n) },
        .init("Prism", "PosRotate"): { n in .prismPositionRotate(n: n) },
        .init("Effects", "Rate"): { n in .effectsRate(n: n) },
        .init("Effects", "Fade"): { n in .effectsFade(n: n) },
        .init("Effects", "Pos"): { n in .effectsPosition(n: n) },
        .init("Effects", "PosRotate"): { n in .effectsPositionRotate(n: n) },
        .init("Focus", "Adjust"): { n in .focusAdjust(n: n) },
        .init("Focus", "Distance"): { n in .focusDistance(n: n) },
        .init("Gobo", "WheelMode"): { n in .goboWheelMode(n: n) },
        .init("AnimationWheel", "Mode"): { n in .animationWheelMode(n: n) },
        .init("Color", "Mode"): { n in .colorMode(n: n) },
        .init("GoboWheel", "MSpeed"): { n in .goboWheelMovementSpeed(n: n) },
        .init("Prism", "MSpeed"): { n in .prismMovementSpeed(n: n) },
        .init("Frost", "MSpeed"): { n in .frostMovementSpeed(n: n) },
        .init("Blade", "A"): { n in .bladeA(n: n) },
        .init("Blade", "B"): { n in .bladeB(n: n) },
        .init("Blade", "Rot"): { n in .bladeRotation(n: n) },
        .init("BladeSoft", "A"): { n in .bladeSoftA(n: n) },
        .init("BladeSoft", "B"): { n in .bladeSoftB(n: n) },
        .init("KeyStone", "A"): { n in .keystoneA(n: n) },
        .init("KeyStone", "B"): { n in .keystoneB(n: n) },
        .init("VideoEffect", "Type"): { n in .videoEffectType(n: n) },
    ]
    
    public func getNM() -> (n: Int, m: Int?)? {
        switch self{
        // n
        case .gobo(let n): (n, nil)
        case .animationWheel(let n): (n, nil)
        case .animationSystem(let n): (n, nil)
        case .mediaFolder(let n): (n, nil)
        case .mediaContent(let n): (n, nil)
        case .modelFolder(let n): (n, nil)
        case .modelContent(let n): (n, nil)
        case .colorEffects(let n): (n, nil)
        case .color(let n): (n, nil)
        case .colorMacro(let n): (n, nil)
        case .shutter(let n): (n, nil)
        case .frost(let n): (n, nil)
        case .prism(let n): (n, nil)
        case .effects(let n): (n, nil)
        case .focus(let n): (n, nil)
        case .control(let n): (n, nil)
        case .blower(let n): (n, nil)
        case .fan(let n): (n, nil)
        case .fog(let n): (n, nil)
        case .haze(let n): (n, nil)
        case .videoCamera(let n): (n, nil)
        case .videoSoundVolume(let n): (n, nil)
        case .goboSelectSpin(let n): (n, nil)
        case .goboSelectShake(let n): (n, nil)
        case .goboSelectEffects(let n): (n, nil)
        case .goboWheelIndex(let n): (n, nil)
        case .goboWheelSpin(let n): (n, nil)
        case .goboWheelShake(let n): (n, nil)
        case .goboWheelRandom(let n): (n, nil)
        case .goboWheelAudio(let n): (n, nil)
        case .goboPosition(let n): (n, nil)
        case .goboPositionRotate(let n): (n, nil)
        case .goboPositionShake(let n): (n, nil)
        case .animationWheelAudio(let n): (n, nil)
        case .animationWheelMacro(let n): (n, nil)
        case .animationWheelRandom(let n): (n, nil)
        case .animationWheelSelectEffects(let n): (n, nil)
        case .animationWheelSelectShake(let n): (n, nil)
        case .animationWheelSelectSpin(let n): (n, nil)
        case .animationWheelPosition(let n): (n, nil)
        case .animationWheelPositionRotate(let n): (n, nil)
        case .animationWheelPositionShake(let n): (n, nil)
        case .animationSystemRamp(let n): (n, nil)
        case .animationSystemShake(let n): (n, nil)
        case .animationSystemAudio(let n): (n, nil)
        case .animationSystemRandom(let n): (n, nil)
        case .animationSystemPosition(let n): (n, nil)
        case .animationSystemPositionRotate(let n): (n, nil)
        case .animationSystemPositionShake(let n): (n, nil)
        case .animationSystemPositionRandom(let n): (n, nil)
        case .animationSystemPositionAudio(let n): (n, nil)
        case .animationSystemMacro(let n): (n, nil)
        case .colorWheelIndex(let n): (n, nil)
        case .colorWheelSpin(let n): (n, nil)
        case .colorWheelRandom(let n): (n, nil)
        case .colorWheelAudio(let n): (n, nil)
        case .colorMacroRate(let n): (n, nil)
        case .shutterStrobe(let n): (n, nil)
        case .shutterStrobePulse(let n): (n, nil)
        case .shutterStrobePulseClose(let n): (n, nil)
        case .shutterStrobePulseOpen(let n): (n, nil)
        case .shutterStrobeRandom(let n): (n, nil)
        case .shutterStrobeRandomPulse(let n): (n, nil)
        case .shutterStrobeRandomPulseClose(let n): (n, nil)
        case .shutterStrobeRandomPulseOpen(let n): (n, nil)
        case .shutterStrobeEffect(let n): (n, nil)
        case .frostPulseOpen(let n): (n, nil)
        case .frostPulseClose(let n): (n, nil)
        case .frostRamp(let n): (n, nil)
        case .prismSelectSpin(let n): (n, nil)
        case .prismMacro(let n): (n, nil)
        case .prismPosition(let n): (n, nil)
        case .prismPositionRotate(let n): (n, nil)
        case .effectsRate(let n): (n, nil)
        case .effectsFade(let n): (n, nil)
        case .effectsPosition(let n): (n, nil)
        case .effectsPositionRotate(let n): (n, nil)
        case .focusAdjust(let n): (n, nil)
        case .focusDistance(let n): (n, nil)
        case .goboWheelMode(let n): (n, nil)
        case .animationWheelMode(let n): (n, nil)
        case .colorMode(let n): (n, nil)
        case .goboWheelMovementSpeed(let n): (n, nil)
        case .prismMovementSpeed(let n): (n, nil)
        case .frostMovementSpeed(let n): (n, nil)
        case .bladeA(let n): (n, nil)
        case .bladeB(let n): (n, nil)
        case .bladeRotation(let n): (n, nil)
        case .bladeSoftA(let n): (n, nil)
        case .bladeSoftB(let n): (n, nil)
        case .keystoneA(let n): (n, nil)
        case .keystoneB(let n): (n, nil)
        case .videoEffectType(let n): (n, nil)
        // n + m
        case .effectsAdjust(let n, let m): (n, m)
        case .videoEffectParameter(let n, let m): (n, m)
        
        default: nil
        }
    }
    private static let prefixNSuffixM: [PrefixSuffix: @convention(thin) (_ n: Int, _ m: Int) -> AttributeType] = [
        .init("Effects","Adjust"): { n, m in .effectsAdjust(n: n, m: m) },
        .init("VideoEffect", "Parameter"): { n, m in .videoEffectParameter(n: n, m: m) },
    ]
    
    public init(fromString string: String) {
        /// We are parsing a string in the form of "Prefix(n)Suffix(m)" where only Prefix is required and (n) and (m) are integers
        let substring = string[...]
        guard substring.startIndex != substring.endIndex else {
            // empty string
            self = .custom(name: string)
            return
        }
        
        var prefixEnd: Substring.Index?
        for i in substring.indices {
            if substring[i].isNumber {
                prefixEnd = i
                break
            }
        }
        
        guard let prefixEnd else {
            // no n, m or suffix, just prefix: "Prefix"
            guard let attribute = Self.prefix[substring] else {
                // unkown attribute
                self = .custom(name: string)
                return
            }
            self = attribute
            return
        }
        
        var nEnd: Substring.Index?
        for i in substring[prefixEnd...].indices {
            if !substring[i].isWholeNumber {
                nEnd = i
                break
            }
        }
        guard let nEnd else {
            // we have a string with prefix and suffix but no suffix or m: "Prefix(n)"
            let prefix = substring[..<prefixEnd]
            let nString = substring[prefixEnd...]
            guard let n = Int(nString) else {
                // can't parse n as integer
                self = .custom(name: string)
                return
            }
            guard let factory = Self.prefixN[prefix] else {
                // unknown attribute
                self = .custom(name: string)
                return
            }
            self = factory(n)
            return
        }

        var suffixEnd: Substring.Index?
        for i in substring[nEnd...].indices {
            if substring[i].isWholeNumber {
                suffixEnd = i
                break
            }
        }
        guard let suffixEnd else {
            // we have a string with prefix, n and suffix but no m: "Prefix(n)Suffix"
            let prefix = substring[..<prefixEnd]
            let nString = substring[prefixEnd..<nEnd]
            guard let n = Int(nString) else {
                // can't parse n as integer
                self = .custom(name: string)
                return
            }
            let suffix = substring[nEnd...]
            guard let factory = Self.prefixNSuffix[.init(prefix, suffix)] else {
                // unknown attribute
                self = .custom(name: string)
                return
            }
            self = factory(n)
            return
        }
        var mEnd: Substring.Index?
        for i in substring[suffixEnd...].indices {
            if !substring[i].isWholeNumber {
                mEnd = i
                break
            }
        }
        guard mEnd == nil else {
            // there is more after the m number which isn't possible with the current set of attributes
            self = .custom(name: string)
            return
        }
        
        // we have a string with prefix, n, suffix and m: "Prefix(n)Suffix(m)"
        let prefix = substring[..<prefixEnd]
        let nString = substring[prefixEnd..<nEnd]
        guard let n = Int(nString) else {
            // can't parse n as integer
            self = .custom(name: string)
            return
        }
        let suffix = substring[nEnd..<suffixEnd]
        let mString = substring[suffixEnd...]
        guard let m = Int(mString) else {
            // can't parse m as integer
            self = .custom(name: string)
            return
        }
        guard let factory = Self.prefixNSuffixM[.init(prefix, suffix)] else {
            // unknown attribute
            self = .custom(name: string)
            return
        }
        self = factory(n, m)
    }
}
