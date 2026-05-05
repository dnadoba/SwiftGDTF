//
//  DMXModeResolvedTests.swift
//  SwiftGDTFTests
//

import Foundation
import simd
import Testing
@testable import SwiftGDTF

// MARK: - Helpers

private let identityMatrix = Matrix(from: matrix_identity_float4x4)

private func makeGeneral(_ name: String, children: [Geometry] = []) -> Geometry {
    .general(GeneralGeometry(
        name: name,
        model: nil,
        position: identityMatrix,
        children: children
    ))
}

private func makeReference(
    _ name: String,
    targets template: String,
    breaks: [(break: Int, offset: Int)]
) -> Geometry {
    .reference(GeometryReference(
        name: name,
        model: nil,
        position: identityMatrix,
        geometry: template,
        dmxBreaks: breaks.map {
            DMXBreak(
                offset: DMXAddress(universe: 1, address: $0.offset),
                break: $0.break
            )
        }
    ))
}

private func makeChannel(
    geometry: String,
    break dmxBreak: Int = 1,
    offset: [Int]
) -> DMXChannel {
    DMXChannel(
        name: nil,
        dmxBreak: .id(dmxBreak),
        offset: offset,
        initialFunction: nil,
        highlight: nil,
        logicalChannels: [],
        geometry: geometry
    )
}

/// (dmxBreak, firstOffset) → DMXChannel. Multi-byte channels are keyed
/// by their *first* offset, so a 16-bit channel `[17, 18]` lives at
/// (break, 17).
private struct ChannelKey: Hashable {
    let dmxBreak: DMXChannel.Break
    let firstOffset: Int
}

private func indexByAddress(_ channels: [DMXChannel]) -> [ChannelKey: DMXChannel] {
    Dictionary(uniqueKeysWithValues: channels.compactMap { ch in
        guard let first = ch.offset.first else { return nil }
        return (ChannelKey(dmxBreak: ch.dmxBreak, firstOffset: first), ch)
    })
}

private func channel(
    in index: [ChannelKey: DMXChannel],
    break dmxBreak: Int,
    at offset: Int
) -> DMXChannel? {
    index[ChannelKey(dmxBreak: .id(dmxBreak), firstOffset: offset)]
}

// MARK: - In-code tests

@Suite("DMXMode.resolved — in-code")
struct DMXModeResolvedInCodeTests {

    /// Minimal repro of the "channel on a referenced template's descendant is dropped" bug.
    ///
    ///   Root (general)
    ///   └── Ref (→ Template, break 1 offset 1)
    ///   Template
    ///   └── Child
    ///
    /// One DMX channel `Geometry="Child"` at offset 1 on break 1. After resolution it should appear once at address 1. The current
    /// implementation drops it because `Child` matches neither the root tree nor the top-level template name `Template`.
    @Test func channelOnTemplateDescendantIsReplicated() {
        let root = makeGeneral("Root", children: [
            makeReference("Ref", targets: "Template", breaks: [(break: 1, offset: 1)]),
        ])
        let template = makeGeneral("Template", children: [makeGeneral("Child")])

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [makeChannel(geometry: "Child", offset: [1])],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, template])

        #expect(resolved.channels.count == 1)
        let ch = channel(in: indexByAddress(resolved.channels), break: 1, at: 1)
        #expect(ch?.geometry == "Child")
        #expect(ch?.offset == [1])
    }

    /// Channel on a descendant of a referenced template, replicated through **two outer references** at different offsets —
    /// verifies that single-level offset resolution still uses the per-reference break offset.
    ///
    ///   Root
    ///   ├── RefA (→ Template, break 1 offset 1)
    ///   └── RefB (→ Template, break 1 offset 100)
    ///   Template
    ///   └── Child
    ///
    /// One channel on `Child` at offset 5. Expect two resolved channels at addresses 5 (= 5 + 0) and 104 (= 5 + 99).
    @Test func channelOnTemplateDescendantReplicatedAcrossMultipleReferences() {
        let root = makeGeneral("Root", children: [
            makeReference("RefA", targets: "Template", breaks: [(break: 1, offset: 1)]),
            makeReference("RefB", targets: "Template", breaks: [(break: 1, offset: 100)]),
        ])
        let template = makeGeneral("Template", children: [makeGeneral("Child")])

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [makeChannel(geometry: "Child", offset: [5])],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, template])
        let byAddress = indexByAddress(resolved.channels)

        #expect(resolved.channels.count == 2)
        #expect(channel(in: byAddress, break: 1, at: 5)?.geometry == "Child")
        #expect(channel(in: byAddress, break: 1, at: 104)?.geometry == "Child")
    }

    /// **Chained references**: the offset of a nested `GeometryReference` inside a referenced template must add to the outer
    /// reference's offset.
    ///
    ///   Root
    ///   └── Outer (→ TemplateA, break 1 offset 10)
    ///   TemplateA
    ///   └── Inner (→ TemplateB, break 1 offset 5)
    ///   TemplateB
    ///   └── Child
    ///
    /// One channel on `Child` at offset 1, break 1. Expected resolved address: 1 + (5 − 1) + (10 − 1) = 14.
    @Test func channelOnDescendantOfChainedReferenceIsResolvedWithSummedOffsets() {
        let root = makeGeneral("Root", children: [
            makeReference("Outer", targets: "TemplateA", breaks: [(break: 1, offset: 10)]),
        ])
        let templateA = makeGeneral("TemplateA", children: [
            makeReference("Inner", targets: "TemplateB", breaks: [(break: 1, offset: 5)]),
        ])
        let templateB = makeGeneral("TemplateB", children: [makeGeneral("Child")])

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [makeChannel(geometry: "Child", offset: [1])],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, templateA, templateB])
        let byAddress = indexByAddress(resolved.channels)

        #expect(resolved.channels.count == 1)
        let ch = channel(in: byAddress, break: 1, at: 14)
        #expect(ch?.geometry == "Child", "Channel for Child should land at address 14 after chained offset resolution")
        #expect(ch?.offset == [14])
    }

    /// Replication through chained references: 2 outer × 2 inner references fanning out a single channel into 4 resolved replicas.
    ///
    ///   Root
    ///   ├── OuterA (→ TemplateA, break 1 offset 1)
    ///   └── OuterB (→ TemplateA, break 1 offset 1000)
    ///   TemplateA
    ///   ├── InnerA (→ TemplateB, break 1 offset 1)
    ///   └── InnerB (→ TemplateB, break 1 offset 100)
    ///   TemplateB
    ///   └── Child
    ///
    /// Channel on `Child` at offset 7. Expected addresses (1-based, channel_offset + Σ(ref_offset − 1)):
    ///   • OuterA + InnerA: 7 + 0 +    0 =    7
    ///   • OuterA + InnerB: 7 + 99 +   0 =  106
    ///   • OuterB + InnerA: 7 + 0 +  999 = 1006
    ///   • OuterB + InnerB: 7 + 99 + 999 = 1105
    @Test(arguments: [
        (label: "OuterA × InnerA", expected: 7),
        (label: "OuterA × InnerB", expected: 106),
        (label: "OuterB × InnerA", expected: 1006),
        (label: "OuterB × InnerB", expected: 1105),
    ])
    func chainedReferencesProduceCartesianProductOfOffsets(label: String, expected: Int) {
        let root = makeGeneral("Root", children: [
            makeReference("OuterA", targets: "TemplateA", breaks: [(break: 1, offset: 1)]),
            makeReference("OuterB", targets: "TemplateA", breaks: [(break: 1, offset: 1000)]),
        ])
        let templateA = makeGeneral("TemplateA", children: [
            makeReference("InnerA", targets: "TemplateB", breaks: [(break: 1, offset: 1)]),
            makeReference("InnerB", targets: "TemplateB", breaks: [(break: 1, offset: 100)]),
        ])
        let templateB = makeGeneral("TemplateB", children: [makeGeneral("Child")])

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [makeChannel(geometry: "Child", offset: [7])],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, templateA, templateB])
        #expect(resolved.channels.count == 4, "expected 4 replicas (2 outer × 2 inner)")

        let byAddress = indexByAddress(resolved.channels)
        let ch = channel(in: byAddress, break: 1, at: expected)
        #expect(ch != nil, "[\(label)] missing resolved channel at address \(expected)")
        #expect(ch?.geometry == "Child")
    }

    /// A self-referencing template (`TemplateA → TemplateA`) must not trigger infinite recursion in the path-collection walk.
    /// The cycle guard breaks re-entry into a template that's already on the active chain.
    ///
    ///   Root
    ///   └── Outer (→ TemplateA, break 1 offset 1)
    ///   TemplateA
    ///   ├── Self (→ TemplateA, break 1 offset 100)   ← cycle
    ///   └── Child
    ///
    /// `Child` is reachable only through `Outer`; the `Self` back-edge is skipped. If the guard is removed this test never terminates.
    @Test func referenceCycleIsBrokenByCycleGuard() {
        let root = makeGeneral("Root", children: [
            makeReference("Outer", targets: "TemplateA", breaks: [(break: 1, offset: 1)]),
        ])
        let templateA = makeGeneral("TemplateA", children: [
            makeReference("Self", targets: "TemplateA", breaks: [(break: 1, offset: 100)]),
            makeGeneral("Child"),
        ])

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [makeChannel(geometry: "Child", offset: [1])],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, templateA])
        #expect(resolved.channels.count == 1, "Child should be reached via the single non-cyclic path")
        let byAddress = indexByAddress(resolved.channels)
        #expect(channel(in: byAddress, break: 1, at: 1)?.geometry == "Child")
    }

    /// `.overwrite` break is resolved at the **innermost** reference (which turns it into a concrete break id and contributes that
    /// reference's offset for that break), then each outer reference looks up the now-concrete id to add its own offset.
    ///
    ///   Root
    ///   └── Outer  (→ TemplateA, breaks: [(1, 1), (7, 200)])
    ///   TemplateA
    ///   └── Inner  (→ TemplateB, breaks: [(1, 5), (7, 50)])
    ///   TemplateB
    ///   └── Child
    ///
    ///   Channel: Break = .overwrite, offset 1, geometry = Child
    ///
    /// Inside-out resolution:
    ///   • Inner.getDMXBreak(.overwrite) → last entry (break 7, offset 50): shift = 49, break → .id(7)
    ///   • Outer.getDMXBreak(.id(7))     → (break 7, offset 200):           shift = 199 (Σ 248)
    ///   ⇒ final address = 1 + 248 = 249, on break 7.
    @Test func overwriteBreakIsResolvedAtInnermostReferenceAndChainedThroughOuter() {
        let root = makeGeneral("Root", children: [
            makeReference("Outer", targets: "TemplateA", breaks: [
                (break: 1, offset: 1), (break: 7, offset: 200),
            ]),
        ])
        let templateA = makeGeneral("TemplateA", children: [
            makeReference("Inner", targets: "TemplateB", breaks: [
                (break: 1, offset: 5), (break: 7, offset: 50),
            ]),
        ])
        let templateB = makeGeneral("TemplateB", children: [makeGeneral("Child")])

        let overwriteChannel = DMXChannel(
            name: nil,
            dmxBreak: .overwrite,
            offset: [1],
            initialFunction: nil,
            highlight: nil,
            logicalChannels: [],
            geometry: "Child"
        )

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [overwriteChannel],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, templateA, templateB])
        #expect(resolved.channels.count == 1)

        let byAddress = indexByAddress(resolved.channels)
        let ch = channel(in: byAddress, break: 7, at: 249)
        #expect(ch != nil, "expected a single channel at break 7 address 249")
        #expect(ch?.dmxBreak == .id(7))
        #expect(ch?.offset == [249])
    }

    /// Resolved channel names join the chain with `" -> "`, matching the GDTF Builder's display convention and making chained
    /// references readable (`Outer -> Inner -> Pan`).
    @Test func resolvedChannelNameJoinsChainWithArrowSeparator() {
        let root = makeGeneral("Root", children: [
            makeReference("Outer", targets: "TemplateA", breaks: [(break: 1, offset: 1)]),
        ])
        let templateA = makeGeneral("TemplateA", children: [
            makeReference("Inner", targets: "TemplateB", breaks: [(break: 1, offset: 1)]),
        ])
        let templateB = makeGeneral("TemplateB", children: [makeGeneral("Child")])

        let namedChannel = DMXChannel(
            name: "Pan",
            dmxBreak: .id(1),
            offset: [1],
            initialFunction: nil,
            highlight: nil,
            logicalChannels: [],
            geometry: "Child"
        )

        let mode = DMXMode(
            name: "Test",
            description: "",
            geometry: "Root",
            channels: [namedChannel],
            relations: [],
            macros: []
        )

        let resolved = mode.resolved(with: [root, templateA, templateB])
        #expect(resolved.channels.first?.name == "Outer -> Inner -> Pan")
    }
}

// MARK: - GDTF file-based tests (Ayrton MagicBlade Neo, rid 136919)

@Suite("DMXMode.resolved — Ayrton MagicBlade Neo")
struct DMXModeResolvedAyrtonMagicBladeNeoTests {

    private static func loadFixture() throws -> GDTF {
        let url = try #require(
            Bundle.module.url(
                forResource: "Ayrton_MagicBlade_Neo_136919",
                withExtension: "gdtf",
                subdirectory: "GDTFTestFixtures"
            ),
            "test fixture missing"
        )
        return try loadGDTF(url: url)
    }

    /// `Extended` mode: 5 head replicas of the `Yoke_Ext` template (each occupying 35 channel slots, with slots 22 and 35 inside
    /// that block belonging to the `Base Extended` root).
    ///
    /// Layout (single break, break 1):
    ///   • 24 template channels × 5 heads = 120
    ///   • 2 root channels (Control1 @22, Liquid Control @35)
    ///   • Total: 122 resolved channels.
    @Test func extendedModeHasAllReplicatedAndRootChannels() throws {
        let gdtf = try Self.loadFixture()
        let extended = try #require(
            gdtf.fixtureType.dmxModes.first(where: { $0.name == "Extended" }),
            "Extended mode missing"
        )

        let resolved = extended.resolved(with: gdtf.fixtureType.geometries)
        let byAddress = indexByAddress(resolved.channels)

        #expect(extended.channels.count == 26, "Extended (unresolved) should have 26 channel definitions")
        #expect(resolved.channels.count == 122,
                "Expected 122 resolved channels, got \(resolved.channels.count)")

        // Root channels appear exactly once at their original offsets.
        #expect(channel(in: byAddress, break: 1, at: 22)?.geometry == "Base Extended")
        #expect(channel(in: byAddress, break: 1, at: 35)?.geometry == "Base Extended")

        // 24 template channel start offsets (within the 35-channel template
        // block). Slots 22 and 35 inside the block belong to the root.
        let templateOffsets: [Int] = [
            1, 3, 5, 6, 7, 8, 10, 12, 14, 16, 17, 19, 20,
            23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
        ]
        let outerBases: [Int] = [1, 36, 71, 106, 141]

        for outer in outerBases {
            for offset in templateOffsets {
                let address = (outer - 1) + offset
                let ch = channel(in: byAddress, break: 1, at: address)
                #expect(ch != nil,
                        "Missing resolved channel at break 1 address \(address) (template offset \(offset), outer \(outer))")
            }
        }

        // Spot-check geometry on a descendant of the template at a few
        // addresses across heads.
        #expect(channel(in: byAddress, break: 1, at: 3)?.geometry == "Head_Ext")           // Head 1, Tilt
        #expect(channel(in: byAddress, break: 1, at: 38)?.geometry == "Head_Ext")          // Head 2, Tilt
        #expect(channel(in: byAddress, break: 1, at: 17)?.geometry == "LED")               // Head 1, Dimmer
        #expect(channel(in: byAddress, break: 1, at: 157)?.geometry == "LED")              // Head 5, Dimmer
        #expect(channel(in: byAddress, break: 1, at: 168)?.geometry == "Liquid Effect Back") // Head 5
    }

    /// `Extended+Liquid` mode: same outer 5×35 layout on break 1 plus an extra break 2 with **chained references** — the
    /// `Yoke_Ext_Pxl` template contains 60 nested `GeometryReference`s to `Pixel Liquid` (Pxl1..Pxl60 at inner offsets
    /// 1, 4, 7, …, 178). Each `Pixel Liquid` reference contributes 3 channels (R/G/B at template offsets 1/2/3 on break 2).
    ///
    /// Expected break 2 layout (per outer head at outer break-2 offsets 1, 181, 361, 541, 721):
    ///   • 60 pixels × 3 channels = 180 channels per outer head
    ///   • × 5 outer heads = 900 channels on break 2
    ///
    /// Plus break 1 (same as Extended): 122 channels. Total resolved channels in Extended+Liquid: 122 + 900 = 1022.
    @Test func extendedPlusLiquidModeChainsBreak2OffsetsCorrectly() throws {
        let gdtf = try Self.loadFixture()
        let mode = try #require(
            gdtf.fixtureType.dmxModes.first(where: { $0.name == "Extended+Liquid" }),
            "Extended+Liquid mode missing"
        )

        let resolved = mode.resolved(with: gdtf.fixtureType.geometries)
        let byAddress = indexByAddress(resolved.channels)

        #expect(resolved.channels.count == 1022,
                "Expected 122 break-1 + 900 break-2 = 1022 resolved channels, got \(resolved.channels.count)")

        // Sample the 4 corners + middle of the chained break 2 layout.
        // Pxl inner offsets are 1, 4, 7, ..., 178 (step 3).
        // R/G/B channel offsets are 1, 2, 3.
        let outerBases: [(head: Int, offset: Int)] = [
            (1, 1), (2, 181), (3, 361), (4, 541), (5, 721),
        ]
        let pxlInnerOffsets: [(pxl: Int, offset: Int)] = [
            (1, 1),    // first pixel
            (5, 13),
            (30, 88),
            (60, 178), // last pixel
        ]

        for outer in outerBases {
            for pxl in pxlInnerOffsets {
                for (channelOffset, expectedColor) in [(1, "R"), (2, "G"), (3, "B")] {
                    let address = channelOffset + (pxl.offset - 1) + (outer.offset - 1)
                    let ch = channel(in: byAddress, break: 2, at: address)
                    #expect(ch != nil,
                            "Missing break 2 channel at address \(address) (head \(outer.head), Pxl\(pxl.pxl), \(expectedColor))")
                    #expect(ch?.geometry == "Pixel Liquid",
                            "break 2 address \(address) should target Pixel Liquid (head \(outer.head), Pxl\(pxl.pxl), \(expectedColor)), got \(ch?.geometry ?? "nil")")
                }
            }
        }

        // Boundary checks: extreme addresses on break 2.
        #expect(channel(in: byAddress, break: 2, at: 1) != nil,
                "Break 2 should start at address 1 (head 1, Pxl1, R)")
        #expect(channel(in: byAddress, break: 2, at: 900) != nil,
                "Break 2 should end at address 900 (head 5, Pxl60, B)")
        // One past the end must be empty.
        #expect(channel(in: byAddress, break: 2, at: 901) == nil)
    }
}
