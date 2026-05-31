import Testing
@testable import SwiftGDTF

// Pure-function tests for the physical-description additions: ColorCIE list parsing,
// color-space primaries, and DMX-profile polynomial evaluation. These need no fixtures.

@Suite("Physical Descriptions")
struct PhysicalDescriptionTests {

    // MARK: ColorCIE.parseList

    @Test func parsesBraceWrappedGamutPoints() {
        let points = ColorCIE.parseList("{0.6400,0.3300,21.26}{0.3000,0.6000,71.52}{0.1500,0.0600,7.22}")
        #expect(points.count == 3)
        #expect(abs(points[0].x - 0.64) < 1e-6)
        #expect(abs(points[0].y - 0.33) < 1e-6)
        // Y > 1 is interpreted as a percentage and normalized to [0, 1].
        #expect(abs(points[0].Y - 0.2126) < 1e-6)
        #expect(abs(points[2].x - 0.15) < 1e-6)
    }

    @Test func parsesWhitespaceSeparatedGamutPoints() {
        let points = ColorCIE.parseList("0.64,0.33,0.21 0.30,0.60,0.71 0.15,0.06,0.07")
        #expect(points.count == 3)
        #expect(abs(points[1].x - 0.30) < 1e-6)
        #expect(abs(points[1].y - 0.60) < 1e-6)
    }

    @Test func parseListSkipsMalformedAndEmpty() {
        #expect(ColorCIE.parseList("").isEmpty)
        #expect(ColorCIE.parseList("   ").isEmpty)
        // A lone scalar (one component) is not a valid point and is skipped.
        let points = ColorCIE.parseList("{0.5}{0.64,0.33,0.21}")
        #expect(points.count == 1)
        #expect(abs(points[0].x - 0.64) < 1e-6)
    }

    // MARK: ColorSpace primaries

    @Test func sRGBPredefinedPrimaries() {
        let p = ColorSpace.predefinedPrimaries(for: .srgb)
        #expect(p != nil)
        #expect(abs(p!.red.x - 0.64) < 1e-6)
        #expect(abs(p!.green.y - 0.60) < 1e-6)
        #expect(abs(p!.blue.x - 0.15) < 1e-6)
        #expect(abs(p!.whitePoint.x - 0.3127) < 1e-6)
    }

    @Test func customColorSpaceWithoutPrimariesHasNoEffectivePrimaries() {
        let cs = ColorSpace(name: "C", mode: .custom, red: nil, green: nil, blue: nil, whitePoint: nil)
        #expect(cs.effectivePrimaries == nil)
    }

    @Test func customColorSpaceBackfillsMissingPrimariesFromSRGB() {
        let cs = ColorSpace(
            name: "C", mode: .custom,
            red: ColorCIE(x: 0.7, y: 0.3, Y: 0.2),
            green: nil, blue: nil, whitePoint: nil
        )
        let p = cs.effectivePrimaries
        #expect(p != nil)
        #expect(abs(p!.red.x - 0.7) < 1e-6)                 // explicit
        #expect(abs(p!.green.x - 0.30) < 1e-6)              // backfilled from sRGB
        #expect(abs(p!.whitePoint.x - 0.3127) < 1e-6)       // backfilled from sRGB
    }

    @Test func predefinedColorSpaceIgnoresCustomFields() {
        let cs = ColorSpace(name: "S", mode: .srgb, red: ColorCIE(x: 0.9, y: 0.9, Y: 1), green: nil, blue: nil, whitePoint: nil)
        let p = cs.effectivePrimaries
        #expect(abs(p!.red.x - 0.64) < 1e-6)                // predefined wins over the stray custom value
    }

    // MARK: DMXProfile evaluation (spec Table 24 formula)

    @Test func dmxProfilePiecewiseEvaluation() {
        let profile = DMXProfile(name: "P", points: [
            Point(dmxPercentage: 0.0, cfc0: 0, cfc1: 1, cfc2: 0, cfc3: 0),   // y = x on [0, 0.5)
            Point(dmxPercentage: 0.5, cfc0: 0.5, cfc1: 0, cfc2: 0, cfc3: 0), // y = 0.5 on [0.5, ∞)
        ])
        #expect(abs(profile.output(at: 0.0) - 0.0) < 1e-9)
        #expect(abs(profile.output(at: 0.25) - 0.25) < 1e-9)
        #expect(abs(profile.output(at: 0.5) - 0.5) < 1e-9)
        #expect(abs(profile.output(at: 0.75) - 0.5) < 1e-9)
    }

    @Test func dmxProfileOutputsZeroBelowFirstPoint() {
        let profile = DMXProfile(name: "P", points: [
            Point(dmxPercentage: 0.5, cfc0: 1, cfc1: 0, cfc2: 0, cfc3: 0),
        ])
        // No point with dmxPercentage <= x → 0 per spec.
        #expect(profile.output(at: 0.25) == 0)
        #expect(abs(profile.output(at: 0.5) - 1) < 1e-9)
    }

    @Test func dmxProfileCubicTerm() {
        // Single point at 0 with f(x) = x³ + x (the GDTF editor's example curve).
        let profile = DMXProfile(name: "P", points: [
            Point(dmxPercentage: 0.0, cfc0: 0, cfc1: 1, cfc2: 0, cfc3: 1),
        ])
        #expect(abs(profile.output(at: 1.0) - 2.0) < 1e-9)   // 1 + 1
        #expect(abs(profile.output(at: 0.5) - 0.625) < 1e-9) // 0.125 + 0.5
    }
}
