import Testing
import Foundation
@testable import SwiftGDTF

/// Tests for ChannelSet PhysicalFrom/PhysicalTo defaults.
///
/// Per the GDTF spec and the behavior of the GDTF Editor: when a ChannelSet
/// omits PhysicalFrom/PhysicalTo, the value must be linearly interpolated from
/// the parent ChannelFunction's physical range based on the ChannelSet's DMX
/// position within the parent ChannelFunction's DMX range.
///
/// Fixture used: Robe Robin T.5 Profile — Blade1Rot channel
/// (https://fixturebuilder.gdtf-share.com/load/?rid=139727)
@Suite
struct ChannelSetInterpolationTests {

    /// Minimal GDTF description.xml carrying just the Blade1Rot ChannelFunction
    /// from the Robe Robin T.5 Profile, with the surrounding scaffolding needed
    /// for parsing to succeed.
    static let bladeRotXML = #"""
    <?xml version="1.0" encoding="UTF-8" standalone="no" ?>
    <GDTF DataVersion="1.2">
      <FixtureType Name="ChannelSetTest" ShortName="CST" LongName="ChannelSetTest" Manufacturer="Test" Description="Test fixture" FixtureTypeID="00000000-0000-0000-0000-000000000001">
        <AttributeDefinitions>
          <FeatureGroups>
            <FeatureGroup Name="Beam" Pretty="B">
              <Feature Name="Beam"/>
            </FeatureGroup>
          </FeatureGroups>
          <Attributes>
            <Attribute Name="Blade1Rot" Pretty="Blade1Rot" Feature="Beam.Beam" PhysicalUnit="Angle"/>
          </Attributes>
        </AttributeDefinitions>
        <Wheels/>
        <PhysicalDescriptions/>
        <DMXModes>
          <DMXMode Name="Default" Description="">
            <DMXChannels>
              <DMXChannel DMXBreak="1" Geometry="Head" Highlight="None" InitialFunction="Head_Blade1Rot.Blade1Rot.Blade 1 rot" Offset="40">
                <LogicalChannel Attribute="Blade1Rot" DMXChangeTimeLimit="0.000000" Master="None" MibFade="0.000000" Snap="No">
                  <ChannelFunction Attribute="Blade1Rot" CustomName="" DMXFrom="0/1" Default="128/1" Max="1.000000" Min="0.000000" Name="Blade 1 rot" OriginalAttribute="Framing shutter 1 - swivelling" PhysicalFrom="30.000000" PhysicalTo="-30.000000" RealAcceleration="0.000000" RealFade="0.225000">
                    <ChannelSet DMXFrom="0/1" Name="min" WheelSlotIndex="0"/>
                    <ChannelSet DMXFrom="1/1" Name="" WheelSlotIndex="0"/>
                    <ChannelSet DMXFrom="128/1" Name="center" PhysicalFrom="0.000000" PhysicalTo="0.000000" WheelSlotIndex="0"/>
                    <ChannelSet DMXFrom="129/1" Name="" WheelSlotIndex="0"/>
                    <ChannelSet DMXFrom="255/1" Name="max" WheelSlotIndex="0"/>
                  </ChannelFunction>
                </LogicalChannel>
              </DMXChannel>
            </DMXChannels>
            <Relations/>
            <FTMacros/>
          </DMXMode>
        </DMXModes>
      </FixtureType>
    </GDTF>
    """#

    private func loadBladeRotChannelSets() throws -> [ChannelSet] {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ChannelSetInterpolationTest-\(UUID().uuidString).xml")
        try Self.bladeRotXML.write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let gdtf = try loadGDTFDescription(url: tmp)
        let channelFunction = try #require(
            gdtf.fixtureType.dmxModes.first?
                .channels.first?
                .logicalChannels.first?
                .channelFunctions.first
        )
        return channelFunction.channelSets
    }

    @Test
    func channelSetsPhysicalValuesAreInterpolatedFromParent() throws {
        let sets = try loadBladeRotChannelSets()

        try #require(sets.count == 5, "expected 5 ChannelSets, got \(sets.count)")

        // Parent ChannelFunction: DMX 0..255 (8-bit), PhysicalFrom=30, PhysicalTo=-30.
        // Linear interpolation: physical(dmx) = 30 + (dmx / 255) * (-30 - 30) = 30 - dmx * (60/255).

        // "min" — DMX 0..0, no explicit physical → both ends interpolate to 30.
        #expect(sets[0].name == "min")
        #expect(sets[0].physicalFrom == 30)
        #expect(sets[0].physicalTo == 30)

        // unnamed gap — DMX 1..127, no explicit physical → interpolated at both DMX ends.
        #expect(sets[1].name == "")
        let expectedFrom1 = 30.0 - (1.0 / 255.0) * 60.0
        let expectedTo1 = 30.0 - (127.0 / 255.0) * 60.0
        #expect(abs(sets[1].physicalFrom - expectedFrom1) < 1e-9)
        #expect(abs(sets[1].physicalTo - expectedTo1) < 1e-9)

        // "center" — DMX 128..128, explicit Physical=0 → unchanged.
        #expect(sets[2].name == "center")
        #expect(sets[2].physicalFrom == 0)
        #expect(sets[2].physicalTo == 0)

        // unnamed gap — DMX 129..254, no explicit physical → interpolated at both DMX ends.
        #expect(sets[3].name == "")
        let expectedFrom3 = 30.0 - (129.0 / 255.0) * 60.0
        let expectedTo3 = 30.0 - (254.0 / 255.0) * 60.0
        #expect(abs(sets[3].physicalFrom - expectedFrom3) < 1e-9)
        #expect(abs(sets[3].physicalTo - expectedTo3) < 1e-9)

        // "max" — DMX 255..255, no explicit physical → both ends interpolate to -30.
        #expect(sets[4].name == "max")
        #expect(sets[4].physicalFrom == -30)
        #expect(sets[4].physicalTo == -30)
    }
}
