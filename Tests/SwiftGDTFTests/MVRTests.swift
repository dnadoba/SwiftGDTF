import Testing
import Foundation
import ZIPFoundation
@testable import SwiftGDTF

// MARK: - MVR Test Fixtures

/// Metadata for a bundled MVR test fixture.
struct MVRTestFixture {
    /// Filename including extension, matching the file in MVRTestFixtures/.
    let filename: String
    /// Short human-readable description of the fixture contents.
    let description: String
    /// Application that originally exported this MVR file.
    let source: String
    /// URL where the file was downloaded from.
    let sourceURL: String

    var url: URL {
        Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "MVRTestFixtures")!
    }
}

// MARK: Named fixture constants

/// Minimal scene with a single LED PAR 64 RGBW fixture.
let basicFixtureMVR = MVRTestFixture(
    filename: "basic_fixture.mvr",
    description: "Minimal scene with a single LED PAR 64 RGBW fixture",
    source: "python-mvr test suite",
    sourceURL: "https://github.com/open-stage/python-mvr/raw/refs/heads/master/tests/basic_fixture.mvr"
)

/// 7 Robe ColorWash 2500 AT fixtures with a single GDTF file (Vectorworks export).
let sevenFixturesSampleMVR = MVRTestFixture(
    filename: "7-fixtures-sample.mvr",
    description: "7 Robe ColorWash 2500 AT fixtures with a single GDTF file",
    source: "MomentFactory Omniverse MVR-GDTF converter",
    sourceURL: "https://github.com/MomentFactory/Omniverse-MVR-GDTF-converter/raw/main/exts/mf.ov.mvr/sample/7-fixtures-sample.mvr"
)

/// Simple show with truss, MAC Encore fixtures, and a texture image (grandMA3 export).
let simpleShowMVR = MVRTestFixture(
    filename: "Simple_Show.mvr",
    description: "Simple show with truss, MAC Encore fixtures, and a texture image",
    source: "MA Lighting (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Simple_Show.mvr"
)

/// grandMA3 demo show with multiple fixture types, trusses, and scene objects.
let demoshowGrandMA3MVR = MVRTestFixture(
    filename: "Demoshow_grandMA3.mvr",
    description: "grandMA3 demo show with multiple fixture types (MAC Encore, Mac Aura XB, Rush Par, LED Tile, LED steps), trusses, and scene objects",
    source: "MA Lighting (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Demoshow_grandMA3.mvr"
)

/// Scene with fixtures, focus points, and multiple GLB scene objects (Vectorworks export).
let sceneObjectsMVR = MVRTestFixture(
    filename: "scene_objects.mvr",
    description: "Scene with fixtures, focus points, and multiple GLB scene objects",
    source: "python-mvr test suite (Vectorworks export)",
    sourceURL: "https://github.com/open-stage/python-mvr/raw/refs/heads/master/tests/scene_objects.mvr"
)

/// Line of Robe fixtures with GLB meshes in GDTF files (Vectorworks export).
let fixtureLineGltfMVR = MVRTestFixture(
    filename: "fixture-line-gltf.mvr",
    description: "Line of Robe fixtures (T1 Fresnel, MMX Blade, Spiider, BMFL Wash) with GLB meshes in GDTF files",
    source: "MomentFactory Omniverse MVR-GDTF converter (Vectorworks export)",
    sourceURL: "https://github.com/MomentFactory/Omniverse-MVR-GDTF-converter/raw/main/exts/mf.ov.mvr/sample/fixture-line-gltf.mvr"
)

/// Capture demo show with many fixture types, 3DS scene meshes, trusses, symbols, and group objects.
let captureDemoShowMVR = MVRTestFixture(
    filename: "capture_demo_show.mvr",
    description: "Capture demo show with many fixture types, 3DS scene meshes, trusses, symbols, and group objects",
    source: "Capture (via python-mvr test suite)",
    sourceURL: "https://github.com/open-stage/python-mvr/raw/refs/heads/master/tests/capture_demo_show.mvr"
)

/// Template stage with 3DS geometry meshes and group objects.
let templateStage1MVR = MVRTestFixture(
    filename: "Template_Stage1.mvr",
    description: "Template stage with 3DS geometry meshes and group objects",
    source: "Xzidental (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Template_Stage1.mvr"
)

/// Arena-scale scene with many 3DS scene objects, trusses, and group objects.
let keyArenaRemakeMVR = MVRTestFixture(
    filename: "Key_Arena_Remake_MVR.mvr",
    description: "Arena-scale scene with many 3DS scene objects, trusses, and group objects",
    source: "Xzidental (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Key_Arena_Remake_MVR.mvr"
)

/// grandMA3 demo stage with GLB geometry, symbols, and many classes.
let demostageMVR = MVRTestFixture(
    filename: "Demostage_MVR.mvr",
    description: "grandMA3 demo stage with GLB geometry, symbols, and many classes",
    source: "MA Lighting (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Demostage_MVR.mvr"
)

/// Festival stage with Roxx Cluster fixtures, scene geometry, and positions (grandMA3 v2.3.1.1 export).
let basicFestivalMVR = MVRTestFixture(
    filename: "Basic_Festival.mvr",
    description: "Festival stage with Roxx Cluster fixtures, scene geometry, and positions (grandMA3 v2.3.1.1 export)",
    source: "JMLutra (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Basic_Festival.mvr"
)

/// Circular stage with walkway, GLB geometry, positions, and multiple fixture types (grandMA3 v2.3.1.1 export).
let circleStageMVR = MVRTestFixture(
    filename: "Circle_Stage.mvr",
    description: "Circular stage with walkway, GLB geometry, positions, and multiple fixture types (grandMA3 v2.3.1.1 export)",
    source: "JMLutra (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Circle_Stage.mvr"
)

/// Complex scene with many fixture types, many symdefs/symbols, and a deliberately messy patch (grandMA3 export).
let messyPatchMVR = MVRTestFixture(
    filename: "Messy_Patch.mvr",
    description: "Complex scene with many fixture types, many symdefs/symbols, and a deliberately messy patch (grandMA3 export)",
    source: "JMLutra (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Messy_Patch.mvr"
)

/// Midsize stage with ground package, symdefs/symbols, and group objects (grandMA3 v2.3.0.4 export).
let midsizeWithGPMVR = MVRTestFixture(
    filename: "Midsize_w_GP.mvr",
    description: "Midsize stage with ground package, symdefs/symbols, and group objects (grandMA3 v2.3.0.4 export)",
    source: "JMLutra (via GDTF Hub)",
    sourceURL: "https://www.gdtf.eu/mvr_files/Midsize_w_GP.mvr"
)

/// All bundled MVR test fixtures, ordered roughly by complexity.
let allMVRTestFixtures: [MVRTestFixture] = [
    basicFixtureMVR, sevenFixturesSampleMVR,
    simpleShowMVR, demoshowGrandMA3MVR,
    sceneObjectsMVR, fixtureLineGltfMVR,
    captureDemoShowMVR,
    templateStage1MVR, keyArenaRemakeMVR,
    demostageMVR, basicFestivalMVR, circleStageMVR,
    messyPatchMVR, midsizeWithGPMVR,
]

// MARK: - MVR Test Statistics Model

/// A named count used for grouping statistics (e.g. fixtures per layer).
struct NamedCount: Equatable, CustomStringConvertible {
    var name: String
    var count: Int

    init(_ name: String, _ count: Int) {
        self.name = name
        self.count = count
    }

    var description: String { "\(name): \(count)" }
}

/// High-level statistics extracted from a parsed MVR scene, used to validate
/// the parser against known-good reference values.
///
/// This model is deliberately separate from the MVR data model itself.
/// The extraction function can perform more expensive transformations
/// (e.g. flattening the tree, counting across all nesting levels) that
/// the parser wouldn't normally do.
struct MVRSceneStatistics: Equatable, CustomStringConvertible {
    /// MVR format version (e.g. "1.5").
    var version: String
    /// Provider application name, empty if not specified.
    var provider: String

    /// Total number of layers in the scene.
    var layerCount: Int
    /// Names of all layers, in document order.
    var layerNames: [String]

    // -- Object counts (across ALL nesting levels) --
    var fixtureCount: Int
    var sceneObjectCount: Int
    var groupObjectCount: Int
    var focusPointCount: Int
    var trussCount: Int
    var supportCount: Int
    var videoScreenCount: Int
    var projectorCount: Int

    // -- AUXData counts --
    var symdefCount: Int
    var classCount: Int
    var positionCount: Int
    var mappingDefinitionCount: Int

    // -- Geometry counts --
    /// Total Geometry3D nodes (across symdefs, scene objects, etc.).
    var geometry3DCount: Int
    /// Total Symbol instance nodes.
    var symbolCount: Int

    // -- Fixture details --
    /// Unique GDTF spec references (filenames), sorted.
    var uniqueGDTFSpecs: [String]
    /// Number of fixtures that have at least one DMX address.
    var fixturesWithAddresses: Int
    /// Fixture counts grouped by GDTF spec name, sorted by spec name.
    var fixtureCountByGDTFSpec: [NamedCount]
    /// Fixture counts grouped by layer name, sorted by layer name.
    var fixtureCountByLayer: [NamedCount]

    // -- Archive contents --
    /// Total number of files in the MVR ZIP archive.
    var archiveFileCount: Int
    /// Number of .gdtf files in the archive.
    var gdtfFileCount: Int
    /// Number of .3ds files in the archive.
    var threeDSFileCount: Int
    /// Number of .glb files in the archive.
    var glbFileCount: Int

    var description: String {
        """
        MVR v\(version) (provider: \(provider.isEmpty ? "<none>" : provider))
        Layers: \(layerCount) \(layerNames)
        Fixtures: \(fixtureCount), SceneObjects: \(sceneObjectCount), \
        GroupObjects: \(groupObjectCount), FocusPoints: \(focusPointCount), \
        Trusses: \(trussCount), Supports: \(supportCount), \
        VideoScreens: \(videoScreenCount), Projectors: \(projectorCount)
        Symdefs: \(symdefCount), Classes: \(classCount), \
        Positions: \(positionCount), MappingDefs: \(mappingDefinitionCount)
        Geometry3D: \(geometry3DCount), Symbols: \(symbolCount)
        GDTF specs (\(uniqueGDTFSpecs.count)): \(uniqueGDTFSpecs.joined(separator: ", "))
        Fixtures with addresses: \(fixturesWithAddresses)
        Archive: \(archiveFileCount) files (\(gdtfFileCount) gdtf, \
        \(threeDSFileCount) 3ds, \(glbFileCount) glb)
        """
    }
}


// MARK: - Statistics Extraction

/// Extracts high-level statistics from a parsed MVR scene for test validation.
///
/// This function walks the full MVR tree to compute counts, and also inspects
/// the ZIP archive for file counts.
func extractMVRStatistics(from mvrData: Data) throws -> MVRSceneStatistics {
    let scene = try loadMVR(data: mvrData)

    var stats = MVRSceneStatistics(
        version: "\(scene.verMajor).\(scene.verMinor)",
        provider: scene.provider,
        layerCount: scene.scene.layers.count,
        layerNames: scene.scene.layers.map(\.name),
        fixtureCount: 0, sceneObjectCount: 0, groupObjectCount: 0,
        focusPointCount: 0, trussCount: 0, supportCount: 0,
        videoScreenCount: 0, projectorCount: 0,
        symdefCount: scene.scene.auxData.symdefs.count,
        classCount: scene.scene.auxData.classes.count,
        positionCount: scene.scene.auxData.positions.count,
        mappingDefinitionCount: scene.scene.auxData.mappingDefinitions.count,
        geometry3DCount: 0, symbolCount: 0,
        uniqueGDTFSpecs: [],
        fixturesWithAddresses: 0,
        fixtureCountByGDTFSpec: [],
        fixtureCountByLayer: [],
        archiveFileCount: 0, gdtfFileCount: 0, threeDSFileCount: 0, glbFileCount: 0
    )

    // Count geometry nodes in symdefs
    for symdef in scene.scene.auxData.symdefs {
        countGeometryNodes(symdef.children, stats: &stats)
    }

    // Walk each layer's child tree
    var gdtfSpecCounts: [String: Int] = [:]
    var layerFixtureCounts: [String: Int] = [:]

    for layer in scene.scene.layers {
        var layerFixtureCount = 0
        walkChildList(layer.childList, stats: &stats, gdtfSpecCounts: &gdtfSpecCounts,
                      layerFixtureCount: &layerFixtureCount)
        if layerFixtureCount > 0 {
            layerFixtureCounts[layer.name, default: 0] += layerFixtureCount
        }
    }

    stats.uniqueGDTFSpecs = gdtfSpecCounts.keys.sorted()
    stats.fixtureCountByGDTFSpec = gdtfSpecCounts.sorted(by: { $0.key < $1.key })
        .map { NamedCount($0.key, $0.value) }
    stats.fixtureCountByLayer = layerFixtureCounts.sorted(by: { $0.key < $1.key })
        .map { NamedCount($0.key, $0.value) }

    // Archive file counts
    if let archive = Archive(data: mvrData, accessMode: .read) {
        for entry in archive {
            let path = entry.path.lowercased()
            stats.archiveFileCount += 1
            if path.hasSuffix(".gdtf") { stats.gdtfFileCount += 1 }
            else if path.hasSuffix(".3ds") { stats.threeDSFileCount += 1 }
            else if path.hasSuffix(".glb") { stats.glbFileCount += 1 }
        }
    }

    return stats
}

/// Recursively walks a child list, updating statistics counters.
private func walkChildList(
    _ children: [MVRChildObject],
    stats: inout MVRSceneStatistics,
    gdtfSpecCounts: inout [String: Int],
    layerFixtureCount: inout Int
) {
    for child in children {
        switch child {
        case .fixture(let f):
            stats.fixtureCount += 1
            layerFixtureCount += 1
            if let spec = f.gdtfSpec {
                gdtfSpecCounts[spec, default: 0] += 1
            }
            if f.addresses.contains(where: { if case .address = $0 { return true } else { return false } }) {
                stats.fixturesWithAddresses += 1
            }
        case .sceneObject(let o):
            stats.sceneObjectCount += 1
            countGeometryNodes(o.geometries, stats: &stats)
        case .groupObject:
            stats.groupObjectCount += 1
        case .focusPoint(let fp):
            stats.focusPointCount += 1
            countGeometryNodes(fp.geometries, stats: &stats)
        case .truss(let t):
            stats.trussCount += 1
            countGeometryNodes(t.geometries, stats: &stats)
        case .support(let s):
            stats.supportCount += 1
            countGeometryNodes(s.geometries, stats: &stats)
        case .videoScreen(let v):
            stats.videoScreenCount += 1
            countGeometryNodes(v.geometries, stats: &stats)
        case .projector(let p):
            stats.projectorCount += 1
            countGeometryNodes(p.geometries, stats: &stats)
        }

        // Recurse into child lists
        walkChildList(child.childList, stats: &stats, gdtfSpecCounts: &gdtfSpecCounts,
                      layerFixtureCount: &layerFixtureCount)
    }
}

/// Counts Geometry3D and Symbol nodes in a geometry node list.
private func countGeometryNodes(_ nodes: [MVRGeometryNode], stats: inout MVRSceneStatistics) {
    for node in nodes {
        switch node {
        case .geometry3D: stats.geometry3DCount += 1
        case .symbol: stats.symbolCount += 1
        }
    }
}

// MARK: - Test Helpers

/// Loads an MVR test fixture and extracts statistics, providing a clear
/// error message that includes the fixture filename on failure.
func loadAndExtractStatistics(from fixture: MVRTestFixture) throws -> MVRSceneStatistics {
    let data = try Data(contentsOf: fixture.url)
    return try extractMVRStatistics(from: data)
}

/// Asserts a single field of the statistics matches the expected value.
/// Produces a clear, actionable error message showing field name, expected,
/// and actual values.
func expectField<T: Equatable>(
    _ fieldName: String,
    of stats: MVRSceneStatistics,
    expected: T,
    actual: T,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(
        actual == expected,
        "Field '\(fieldName)': expected \(expected), got \(actual)",
        sourceLocation: sourceLocation
    )
}

/// Validates MVR scene statistics against expected values.
/// Each field is checked individually so failures pinpoint exactly which
/// field is wrong.
func expectStatistics(
    _ stats: MVRSceneStatistics,
    version: String,
    provider: String = "",
    layerCount: Int,
    layerNames: [String],
    fixtureCount: Int,
    sceneObjectCount: Int = 0,
    groupObjectCount: Int = 0,
    focusPointCount: Int = 0,
    trussCount: Int = 0,
    supportCount: Int = 0,
    videoScreenCount: Int = 0,
    projectorCount: Int = 0,
    symdefCount: Int = 0,
    classCount: Int = 0,
    positionCount: Int = 0,
    mappingDefinitionCount: Int = 0,
    geometry3DCount: Int = 0,
    symbolCount: Int = 0,
    uniqueGDTFSpecs: [String],
    fixturesWithAddresses: Int,
    fixtureCountByGDTFSpec: [NamedCount],
    fixtureCountByLayer: [NamedCount],
    archiveFileCount: Int,
    gdtfFileCount: Int,
    threeDSFileCount: Int = 0,
    glbFileCount: Int = 0,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    expectField("version", of: stats, expected: version, actual: stats.version, sourceLocation: sourceLocation)
    expectField("provider", of: stats, expected: provider, actual: stats.provider, sourceLocation: sourceLocation)
    expectField("layerCount", of: stats, expected: layerCount, actual: stats.layerCount, sourceLocation: sourceLocation)
    expectField("layerNames", of: stats, expected: layerNames, actual: stats.layerNames, sourceLocation: sourceLocation)
    expectField("fixtureCount", of: stats, expected: fixtureCount, actual: stats.fixtureCount, sourceLocation: sourceLocation)
    expectField("sceneObjectCount", of: stats, expected: sceneObjectCount, actual: stats.sceneObjectCount, sourceLocation: sourceLocation)
    expectField("groupObjectCount", of: stats, expected: groupObjectCount, actual: stats.groupObjectCount, sourceLocation: sourceLocation)
    expectField("focusPointCount", of: stats, expected: focusPointCount, actual: stats.focusPointCount, sourceLocation: sourceLocation)
    expectField("trussCount", of: stats, expected: trussCount, actual: stats.trussCount, sourceLocation: sourceLocation)
    expectField("supportCount", of: stats, expected: supportCount, actual: stats.supportCount, sourceLocation: sourceLocation)
    expectField("videoScreenCount", of: stats, expected: videoScreenCount, actual: stats.videoScreenCount, sourceLocation: sourceLocation)
    expectField("projectorCount", of: stats, expected: projectorCount, actual: stats.projectorCount, sourceLocation: sourceLocation)
    expectField("symdefCount", of: stats, expected: symdefCount, actual: stats.symdefCount, sourceLocation: sourceLocation)
    expectField("classCount", of: stats, expected: classCount, actual: stats.classCount, sourceLocation: sourceLocation)
    expectField("positionCount", of: stats, expected: positionCount, actual: stats.positionCount, sourceLocation: sourceLocation)
    expectField("mappingDefinitionCount", of: stats, expected: mappingDefinitionCount, actual: stats.mappingDefinitionCount, sourceLocation: sourceLocation)
    expectField("geometry3DCount", of: stats, expected: geometry3DCount, actual: stats.geometry3DCount, sourceLocation: sourceLocation)
    expectField("symbolCount", of: stats, expected: symbolCount, actual: stats.symbolCount, sourceLocation: sourceLocation)
    expectField("uniqueGDTFSpecs", of: stats, expected: uniqueGDTFSpecs, actual: stats.uniqueGDTFSpecs, sourceLocation: sourceLocation)
    expectField("fixturesWithAddresses", of: stats, expected: fixturesWithAddresses, actual: stats.fixturesWithAddresses, sourceLocation: sourceLocation)

    expectField("fixtureCountByGDTFSpec", of: stats, expected: fixtureCountByGDTFSpec, actual: stats.fixtureCountByGDTFSpec, sourceLocation: sourceLocation)
    expectField("fixtureCountByLayer", of: stats, expected: fixtureCountByLayer, actual: stats.fixtureCountByLayer, sourceLocation: sourceLocation)

    expectField("archiveFileCount", of: stats, expected: archiveFileCount, actual: stats.archiveFileCount, sourceLocation: sourceLocation)
    expectField("gdtfFileCount", of: stats, expected: gdtfFileCount, actual: stats.gdtfFileCount, sourceLocation: sourceLocation)
    expectField("threeDSFileCount", of: stats, expected: threeDSFileCount, actual: stats.threeDSFileCount, sourceLocation: sourceLocation)
    expectField("glbFileCount", of: stats, expected: glbFileCount, actual: stats.glbFileCount, sourceLocation: sourceLocation)
}

// MARK: - Individual Test Functions

// How to derive expected statistics for a new MVR file:
//
// 1. Verify the archive is valid:
//      unzip -l NewFile.mvr
//
// 2. Extract and inspect the XML:
//      unzip -p NewFile.mvr GeneralSceneDescription.xml > /tmp/mvr.xml
//
// 3. Get version and provider from the root element:
//      grep 'GeneralSceneDescription' /tmp/mvr.xml   (verMajor, verMinor, provider)
//
// 4. Count node types (these counts include ALL nesting levels):
//      grep -c '<Fixture '    /tmp/mvr.xml
//      grep -c '<SceneObject ' /tmp/mvr.xml
//      grep -c '<GroupObject ' /tmp/mvr.xml
//      grep -c '<FocusPoint '  /tmp/mvr.xml
//      grep -c '<Truss '      /tmp/mvr.xml
//      grep -c '<Support '    /tmp/mvr.xml
//      grep -c '<VideoScreen ' /tmp/mvr.xml
//      grep -c '<Projector '  /tmp/mvr.xml
//      grep -c '<Layer '      /tmp/mvr.xml
//      grep -c '<Symdef '     /tmp/mvr.xml
//      grep -c '<Class '      /tmp/mvr.xml
//      grep -c '<Position '   /tmp/mvr.xml   (in AUXData, not the child element)
//      grep -c '<Geometry3D '  /tmp/mvr.xml
//      grep -c '<Symbol '     /tmp/mvr.xml
//
// 5. Get layer names (in document order):
//      grep -o 'Layer.*name="[^"]*"' /tmp/mvr.xml
//
// 6. Get unique GDTF specs (sorted, excluding empty):
//      grep -o '<GDTFSpec>[^<]*</GDTFSpec>' /tmp/mvr.xml | sed 's/<[^>]*>//g' | sort -u | grep .
//
// 7. Count fixtures per GDTF spec:
//      For each spec from step 6, grep for it inside <GDTFSpec> tags and count.
//      (Or use a quick script — see below.)
//
// 8. Count fixtures per layer:
//      This requires understanding the XML hierarchy — fixtures belong to the
//      nearest ancestor <Layer>. A script that walks the XML is most reliable.
//
// 9. Archive file counts:
//      unzip -Z -1 NewFile.mvr | wc -l                    # total
//      unzip -Z -1 NewFile.mvr | grep -c '\.gdtf$'        # GDTF
//      unzip -Z -1 NewFile.mvr | grep -c '\.3ds$'          # 3DS
//      unzip -Z -1 NewFile.mvr | grep -c '\.glb$'          # GLB
//
// 10. fixturesWithAddresses: count <Fixture> nodes that contain at least one
//     <Address> child. In most files this equals fixtureCount.

@Suite("MVR Parser Tests")
struct MVRParserTests {

    // MARK: basic_fixture.mvr
    // MVR v1.5 | 1 fixture | 1 layer | 1 GDTF spec | Simplest possible MVR
    @Test func basicFixture() throws {
        let stats = try loadAndExtractStatistics(from: basicFixtureMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 1,
            layerNames: ["None"],
            fixtureCount: 1,
            symdefCount: 1,
            classCount: 1,
            uniqueGDTFSpecs: ["LED PAR 64 RGBW.gdtf"],
            fixturesWithAddresses: 1,
            fixtureCountByGDTFSpec: [
                NamedCount("LED PAR 64 RGBW.gdtf", 1),
            ],
            fixtureCountByLayer: [
                NamedCount("None", 1),
            ],
            archiveFileCount: 2,
            gdtfFileCount: 1
        )
    }

    // MARK: 7-fixtures-sample.mvr
    // MVR v1.5 | 7 fixtures | 5 layers | Non-identity matrices
    @Test func sevenFixturesSample() throws {
        let stats = try loadAndExtractStatistics(from: sevenFixturesSampleMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 5,
            layerNames: ["Design Layer-1", "Main", "Venue", "Lights", "Rigging"],
            fixtureCount: 7,
            classCount: 1,
            uniqueGDTFSpecs: ["Custom@Light Instr Robe ColorWash 2500 AT"],
            fixturesWithAddresses: 7,
            fixtureCountByGDTFSpec: [
                NamedCount("Custom@Light Instr Robe ColorWash 2500 AT", 7),
            ],
            fixtureCountByLayer: [
                NamedCount("Design Layer-1", 7),
            ],
            archiveFileCount: 2,
            gdtfFileCount: 1
        )
    }

    // MARK: Simple_Show.mvr
    // MVR v1.5 | 10 fixtures | 1 layer | grandMA3 | Symdefs + Symbols + GroupObject
    @Test func simpleShow() throws {
        let stats = try loadAndExtractStatistics(from: simpleShowMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 1,
            layerNames: ["FixtureLayer 1"],
            fixtureCount: 10,
            sceneObjectCount: 4,
            groupObjectCount: 1,
            symdefCount: 1,
            classCount: 1,
            geometry3DCount: 1,
            symbolCount: 4,
            uniqueGDTFSpecs: ["Martin Professional@MAC Encore Performance CLD"],
            fixturesWithAddresses: 10,
            fixtureCountByGDTFSpec: [
                NamedCount("Martin Professional@MAC Encore Performance CLD", 10),
            ],
            fixtureCountByLayer: [
                NamedCount("FixtureLayer 1", 10),
            ],
            archiveFileCount: 4,
            gdtfFileCount: 1,
            threeDSFileCount: 1
        )
    }

    // MARK: Demoshow_grandMA3.mvr
    // MVR v1.5 | 176 fixtures | 6 layers | 5 GDTF specs | grandMA3 | Symdefs + Symbols + GroupObjects + Classes
    @Test func demoshowGrandMA3() throws {
        let stats = try loadAndExtractStatistics(from: demoshowGrandMA3MVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 6,
            layerNames: ["Backtruss", "Midtruss", "Floor", "Sidetruss", "Matrix", "Stage"],
            fixtureCount: 176,
            sceneObjectCount: 22,
            groupObjectCount: 3,
            symdefCount: 6,
            classCount: 8,
            geometry3DCount: 6,
            symbolCount: 22,
            uniqueGDTFSpecs: [
                "Generic@LED steps small",
                "Generic@Led Tile RGB8 Wall",
                "Martin Professional@MAC Encore Performance CLD",
                "Martin@Mac Aura XB",
                "Martin@Rush Par 2 RGBW Zoom",
            ],
            fixturesWithAddresses: 176,
            fixtureCountByGDTFSpec: [
                NamedCount("Generic@LED steps small", 40),
                NamedCount("Generic@Led Tile RGB8 Wall", 100),
                NamedCount("Martin Professional@MAC Encore Performance CLD", 13),
                NamedCount("Martin@Mac Aura XB", 16),
                NamedCount("Martin@Rush Par 2 RGBW Zoom", 7),
            ],
            fixtureCountByLayer: [
                NamedCount("Backtruss", 155),
                NamedCount("Floor", 8),
                NamedCount("Midtruss", 5),
                NamedCount("Sidetruss", 8),
            ],
            archiveFileCount: 13,
            gdtfFileCount: 5,
            threeDSFileCount: 6
        )
    }

    // MARK: scene_objects.mvr
    // MVR v1.5 | 72 fixtures | 7 layers | FocusPoints + SceneObjects with GLB geometry
    @Test func sceneObjects() throws {
        let stats = try loadAndExtractStatistics(from: sceneObjectsMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 7,
            layerNames: [
                "Theatre FloorPlan", "Scenery", "Soft Goods",
                "Lighting Positions", "Light Plot",
                "House LX", "House LX Focus Points",
            ],
            fixtureCount: 72,
            sceneObjectCount: 28,
            focusPointCount: 72,
            classCount: 5,
            geometry3DCount: 100,
            uniqueGDTFSpecs: ["Custom@Light Instr Light Source Pendant 44deg"],
            fixturesWithAddresses: 72,
            fixtureCountByGDTFSpec: [
                NamedCount("Custom@Light Instr Light Source Pendant 44deg", 72),
            ],
            fixtureCountByLayer: [
                NamedCount("House LX", 72),
            ],
            archiveFileCount: 106,
            gdtfFileCount: 2,
            glbFileCount: 100
        )
    }

    // MARK: fixture-line-gltf.mvr
    // MVR v1.5 | 16 fixtures | 1 layer | 4 GDTF specs with GLB meshes inside
    @Test func fixtureLineGltf() throws {
        let stats = try loadAndExtractStatistics(from: fixtureLineGltfMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 1,
            layerNames: ["Design Layer-1"],
            fixtureCount: 16,
            classCount: 1,
            uniqueGDTFSpecs: [
                "Robe Lighting@Robin BMFL Wash.gdtf",
                "Robe Lighting@Robin MMX Blade.gdtf",
                "Robe Lighting@Robin Spiider.gdtf",
                "Robe Lighting@Robin T1 Fresnel.gdtf",
            ],
            fixturesWithAddresses: 16,
            fixtureCountByGDTFSpec: [
                NamedCount("Robe Lighting@Robin BMFL Wash.gdtf", 3),
                NamedCount("Robe Lighting@Robin MMX Blade.gdtf", 3),
                NamedCount("Robe Lighting@Robin Spiider.gdtf", 6),
                NamedCount("Robe Lighting@Robin T1 Fresnel.gdtf", 4),
            ],
            fixtureCountByLayer: [
                NamedCount("Design Layer-1", 16),
            ],
            archiveFileCount: 5,
            gdtfFileCount: 4
        )
    }

    // MARK: capture_demo_show.mvr
    // MVR v1.4 | 76 fixtures | 11 layers | Capture | Trusses + Symdefs + Symbols + GroupObjects + SceneObjects
    @Test func captureDemoShow() throws {
        let stats = try loadAndExtractStatistics(from: captureDemoShowMVR)
        expectStatistics(
            stats,
            version: "1.4",
            layerCount: 11,
            layerNames: [
                "Default layer", "Truss Lights", "Venue",
                "Truss", "Floor Lights", "Rigging",
                "Band", "Stage", "Video", "Side Lights", "",
            ],
            fixtureCount: 76,
            sceneObjectCount: 2078,
            groupObjectCount: 63,
            trussCount: 13,
            symdefCount: 3,
            geometry3DCount: 2257,
            symbolCount: 13,
            uniqueGDTFSpecs: [
                "ADB@ALC4@r3012.gdtf",
                "Clay Paky@A.leda Wash K20@r3044.gdtf",
                "Clay Paky@Alpha Spot QWO 800@r3048.gdtf",
                "Robe@Robin MMX Spot@r3046.gdtf",
                "Robe@Robin MMX WashBeam@r3039.gdtf",
            ],
            fixturesWithAddresses: 76,
            fixtureCountByGDTFSpec: [
                NamedCount("ADB@ALC4@r3012.gdtf", 8),
                NamedCount("Clay Paky@A.leda Wash K20@r3044.gdtf", 10),
                NamedCount("Clay Paky@Alpha Spot QWO 800@r3048.gdtf", 10),
                NamedCount("Robe@Robin MMX Spot@r3046.gdtf", 24),
                NamedCount("Robe@Robin MMX WashBeam@r3039.gdtf", 24),
            ],
            fixtureCountByLayer: [
                NamedCount("", 58),
                NamedCount("Floor Lights", 8),
                NamedCount("Truss Lights", 10),
            ],
            archiveFileCount: 897,
            gdtfFileCount: 5,
            threeDSFileCount: 891
        )
    }

    // MARK: Template_Stage1.mvr
    // MVR v1.4 | 118 fixtures | 2 layers | 5 GDTF specs | Many SceneObjects + GroupObjects
    @Test func templateStage1() throws {
        let stats = try loadAndExtractStatistics(from: templateStage1MVR)
        expectStatistics(
            stats,
            version: "1.4",
            layerCount: 2,
            layerNames: ["Default layer", ""],
            fixtureCount: 118,
            sceneObjectCount: 557,
            groupObjectCount: 93,
            geometry3DCount: 557,
            uniqueGDTFSpecs: [
                "GLP@JDC1 Strobe@r3034.gdtf",
                "Martin@MAC Aura XIP@r3009.gdtf",
                "Martin@MAC Viper XIP@r3000.gdtf",
                "Robe@Robin MegaPointe@r3038.gdtf",
                "Robe@Robin Tetra2@r3031.gdtf",
            ],
            fixturesWithAddresses: 118,
            fixtureCountByGDTFSpec: [
                NamedCount("GLP@JDC1 Strobe@r3034.gdtf", 21),
                NamedCount("Martin@MAC Aura XIP@r3009.gdtf", 12),
                NamedCount("Martin@MAC Viper XIP@r3000.gdtf", 13),
                NamedCount("Robe@Robin MegaPointe@r3038.gdtf", 42),
                NamedCount("Robe@Robin Tetra2@r3031.gdtf", 30),
            ],
            fixtureCountByLayer: [
                NamedCount("", 118),
            ],
            archiveFileCount: 223,
            gdtfFileCount: 5,
            threeDSFileCount: 217
        )
    }

    // MARK: Key_Arena_Remake_MVR.mvr
    // MVR v1.4 | 168 fixtures | 15 layers | 7 GDTF specs | 5432 SceneObjects | 36 Trusses | 572 GroupObjects
    @Test func keyArenaRemake() throws {
        let stats = try loadAndExtractStatistics(from: keyArenaRemakeMVR)
        expectStatistics(
            stats,
            version: "1.4",
            layerCount: 15,
            layerNames: [
                "2.1 Video Wall", "3.1 Trussing",
                "1.1 Fixture Elation Platinum Beam 5R Extreme",
                "1.2 Fixture Martin Mac 101",
                "1.3 Fixture Martin Mac Viper Profile",
                "1.4 Elation Colour Chorus",
                "1.5 Fixture 4cell Molefays",
                "1.6 Fixture Martin Atomic 3000 LED",
                "4.1 Models", "4.2 Audience", "4.3 Decor", "4.4 Box",
                "4.1 Model2", "1.7 Fixture Generic Par 64", "",
            ],
            fixtureCount: 168,
            sceneObjectCount: 5432,
            groupObjectCount: 572,
            trussCount: 36,
            geometry3DCount: 5933,
            uniqueGDTFSpecs: [
                "Elation@Colour Chorus 72.gdtf",
                "Elation@Platinum Beam 5R Extreme.gdtf",
                "Generic@Par 64.gdtf",
                "James Thomas Engineering@Molefay 4 Cell Blinder.gdtf",
                "Martin@Atomic 3000 LED.gdtf",
                "Martin@MAC 101.gdtf",
                "Martin@MAC Viper Profile.gdtf",
            ],
            fixturesWithAddresses: 168,
            fixtureCountByGDTFSpec: [
                NamedCount("Elation@Colour Chorus 72.gdtf", 27),
                NamedCount("Elation@Platinum Beam 5R Extreme.gdtf", 36),
                NamedCount("Generic@Par 64.gdtf", 6),
                NamedCount("James Thomas Engineering@Molefay 4 Cell Blinder.gdtf", 8),
                NamedCount("Martin@Atomic 3000 LED.gdtf", 15),
                NamedCount("Martin@MAC 101.gdtf", 60),
                NamedCount("Martin@MAC Viper Profile.gdtf", 16),
            ],
            fixtureCountByLayer: [
                NamedCount("1.1 Fixture Elation Platinum Beam 5R Extreme", 36),
                NamedCount("1.2 Fixture Martin Mac 101", 60),
                NamedCount("1.3 Fixture Martin Mac Viper Profile", 16),
                NamedCount("1.4 Elation Colour Chorus", 27),
                NamedCount("1.5 Fixture 4cell Molefays", 8),
                NamedCount("1.6 Fixture Martin Atomic 3000 LED", 15),
                NamedCount("1.7 Fixture Generic Par 64", 6),
            ],
            archiveFileCount: 245,
            gdtfFileCount: 7,
            threeDSFileCount: 237
        )
    }

    // MARK: Demostage_MVR.mvr
    // MVR v1.5 | 119 fixtures | 12 layers | 7 GDTF specs | grandMA3 | 33 Symdefs + 54 Symbols + 27 Classes
    @Test func demostage() throws {
        let stats = try loadAndExtractStatistics(from: demostageMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 12,
            layerNames: [
                "FixtureLayer 1", "FixtureLayer 2", "FixtureLayer 3",
                "FixtureLayer 4", "FixtureLayer 5", "FixtureLayer 6",
                "FixtureLayer 7", "Design Layer-1", "Layer 1",
                "FixtureLayer 8", "FixtureLayer 9", "Light Plot",
            ],
            fixtureCount: 119,
            sceneObjectCount: 54,
            symdefCount: 33,
            classCount: 27,
            geometry3DCount: 48,
            symbolCount: 54,
            uniqueGDTFSpecs: [
                "Ayrton@MagicDot SX",
                "Generic@LED Wall 10x10",
                "Martin Professional@MAC Aura XB",
                "Martin Professional@MAC Ultra Performance",
                "Prolights@EclFresnel2KTW",
                "Prolights@Sunrise2IP",
                "Robe Lighting@Robin SuperSpikie",
            ],
            fixturesWithAddresses: 119,
            fixtureCountByGDTFSpec: [
                NamedCount("Ayrton@MagicDot SX", 15),
                NamedCount("Generic@LED Wall 10x10", 16),
                NamedCount("Martin Professional@MAC Aura XB", 22),
                NamedCount("Martin Professional@MAC Ultra Performance", 30),
                NamedCount("Prolights@EclFresnel2KTW", 9),
                NamedCount("Prolights@Sunrise2IP", 9),
                NamedCount("Robe Lighting@Robin SuperSpikie", 18),
            ],
            fixtureCountByLayer: [
                NamedCount("Light Plot", 119),
            ],
            archiveFileCount: 56,
            gdtfFileCount: 7,
            glbFileCount: 48
        )
    }

    // MARK: Basic_Festival.mvr
    // MVR v1.5 | 146 fixtures | 25 layers | 8 GDTF specs | grandMA3 | Positions + SceneObjects
    @Test func basicFestival() throws {
        let stats = try loadAndExtractStatistics(from: basicFestivalMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 25,
            layerNames: [
                "24_STROMPLANUNG SCHEMATISCH", "23_CONNECTCAD RACK",
                "22_CONNECTCAD SIGNALFLUSS", "--- CONNECTCAD ---",
                "21_LAYOUT", "20_VENUE", "18_PRODUKTION", "17_SICHERHEIT",
                "16_INFRASTRUKTUR", "15_GASTRONOMIE", "14_FLIEGENDE BAUTEN",
                "13_PUBLIKUM", "12_DEKO/MÖBEL", "11_STROM", "10_NETZWERK/IT",
                "09_KOMMUNIKATION", "08_BÜHNE", "07_BÜHNENBILD",
                "06_SFX", "05_KAMERA", "04.1_RIGGING GASSE", "04_RIGGING",
                "03_VIDEO", "02_AUDIO", "01_BELEUCHTUNG",
            ],
            fixtureCount: 146,
            sceneObjectCount: 52,
            classCount: 1,
            positionCount: 4,
            geometry3DCount: 52,
            uniqueGDTFSpecs: [
                "Astera LED Technology@AX2-100 PixelBar.gdtf",
                "Cluster S2",
                "Custom@Roxx_Cluster_B4_FC.gdtf",
                "Martin Professional@MAC Viper AirFX.gdtf",
                "ROXX@CLUSTER B4-FC.gdtf",
                "Robe Lighting@Robin Esprite.gdtf",
                "Robe Lighting@Robin Spiider.gdtf",
                "Roxx@Cluster S2.gdtf",
            ],
            fixturesWithAddresses: 146,
            fixtureCountByGDTFSpec: [
                NamedCount("Astera LED Technology@AX2-100 PixelBar.gdtf", 24),
                NamedCount("Cluster S2", 1),
                NamedCount("Custom@Roxx_Cluster_B4_FC.gdtf", 1),
                NamedCount("Martin Professional@MAC Viper AirFX.gdtf", 18),
                NamedCount("ROXX@CLUSTER B4-FC.gdtf", 23),
                NamedCount("Robe Lighting@Robin Esprite.gdtf", 3),
                NamedCount("Robe Lighting@Robin Spiider.gdtf", 44),
                NamedCount("Roxx@Cluster S2.gdtf", 32),
            ],
            fixtureCountByLayer: [
                NamedCount("01_BELEUCHTUNG", 146),
            ],
            archiveFileCount: 61,
            gdtfFileCount: 7,
            glbFileCount: 52
        )
    }

    // MARK: Circle_Stage.mvr
    // MVR v1.5 | 74 fixtures | 24 layers | 5 GDTF specs | grandMA3 | Positions + SceneObjects with GLB
    @Test func circleStage() throws {
        let stats = try loadAndExtractStatistics(from: circleStageMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 24,
            layerNames: [
                "24_STROMPLANUNG SCHEMATISCH", "23_CONNECTCAD RACK",
                "22_CONNECTCAD SIGNALFLUSS", "--- CONNECTCAD ---",
                "21_LAYOUT", "20_VENUE", "18_PRODUKTION", "17_SICHERHEIT",
                "16_INFRASTRUKTUR", "15_GASTRONOMIE", "14_FLIEGENDE BAUTEN",
                "13_PUBLIKUM", "12_DEKO/MÖBEL", "11_STROM", "10_NETZWERK/IT",
                "09_KOMMUNIKATION", "08_BÜHNE", "07_BÜHNENBILD",
                "06_SFX", "05_KAMERA", "04_RIGGING", "03_VIDEO",
                "02_BELEUCHTUNG FLOOR", "01_BELEUCHTUNG",
            ],
            fixtureCount: 74,
            sceneObjectCount: 46,
            classCount: 1,
            positionCount: 4,
            geometry3DCount: 46,
            uniqueGDTFSpecs: [
                "Robe Lighting@Robin Esprite.gdtf",
                "Robe Lighting@Robin LedPOINTE.gdtf",
                "Robe Lighting@Robin Spiider.gdtf",
                "Robe Lighting@Robin Tetra2.gdtf",
                "Robe Lighting@Robin TetraX.gdtf",
            ],
            fixturesWithAddresses: 74,
            fixtureCountByGDTFSpec: [
                NamedCount("Robe Lighting@Robin Esprite.gdtf", 14),
                NamedCount("Robe Lighting@Robin LedPOINTE.gdtf", 24),
                NamedCount("Robe Lighting@Robin Spiider.gdtf", 8),
                NamedCount("Robe Lighting@Robin Tetra2.gdtf", 12),
                NamedCount("Robe Lighting@Robin TetraX.gdtf", 16),
            ],
            fixtureCountByLayer: [
                NamedCount("01_BELEUCHTUNG", 66),
                NamedCount("02_BELEUCHTUNG FLOOR", 8),
            ],
            archiveFileCount: 53,
            gdtfFileCount: 5,
            glbFileCount: 46
        )
    }

    // MARK: Messy_Patch.mvr
    // MVR v1.5 | 135 fixtures | 9 layers | 4 GDTF specs | grandMA3 | 134 Symdefs + 160 Symbols + 10 Classes
    @Test func messyPatch() throws {
        let stats = try loadAndExtractStatistics(from: messyPatchMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 9,
            layerNames: [
                "FixtureLayer 1", "Beschr", "00",
                "01 Staging", "02 Rigging", "03 Audio",
                "04 Video", "05 SFX", "06 Lighting",
            ],
            fixtureCount: 135,
            sceneObjectCount: 160,
            symdefCount: 134,
            classCount: 10,
            geometry3DCount: 515,
            symbolCount: 160,
            uniqueGDTFSpecs: [
                "Prolights@Sunrise2IP",
                "Robe Lighting@Robin Esprite",
                "Robe Lighting@Robin Spiider",
                "SGM Light@Q-8",
            ],
            fixturesWithAddresses: 135,
            fixtureCountByGDTFSpec: [
                NamedCount("Prolights@Sunrise2IP", 18),
                NamedCount("Robe Lighting@Robin Esprite", 30),
                NamedCount("Robe Lighting@Robin Spiider", 51),
                NamedCount("SGM Light@Q-8", 36),
            ],
            fixtureCountByLayer: [
                NamedCount("06 Lighting", 135),
            ],
            archiveFileCount: 191,
            gdtfFileCount: 4,
            glbFileCount: 183
        )
    }

    // MARK: Midsize_w_GP.mvr
    // MVR v1.5 | 76 fixtures | 24 layers | 8 GDTF specs | grandMA3 | Symdefs + Symbols + GroupObject
    @Test func midsizeWithGP() throws {
        let stats = try loadAndExtractStatistics(from: midsizeWithGPMVR)
        expectStatistics(
            stats,
            version: "1.5",
            layerCount: 24,
            layerNames: [
                "24_STROMPLANUNG SCHEMATISCH", "23_CONNECTCAD RACK",
                "22_CONNECTCAD SIGNALFLUSS", "--- CONNECTCAD ---",
                "21_LAYOUT", "20_VENUE", "18_PRODUKTION", "17_SICHERHEIT",
                "16_INFRASTRUKTUR", "15_GASTRONOMIE", "14_FLIEGENDE BAUTEN",
                "13_PUBLIKUM", "12_DEKO/MÖBEL", "11_STROM", "10_NETZWERK/IT",
                "09_KOMMUNIKATION", "08_BÜHNE", "07_BÜHNENBILD",
                "06_SFX", "05_KAMERA", "04_RIGGING", "03_VIDEO",
                "02_AUDIO", "01_BELEUCHTUNG",
            ],
            fixtureCount: 76,
            sceneObjectCount: 39,
            groupObjectCount: 1,
            symdefCount: 13,
            classCount: 1,
            geometry3DCount: 13,
            symbolCount: 39,
            uniqueGDTFSpecs: [
                "Astera LED Technology@FP3 Hyperion Tube",
                "Elation@Pulse Panel",
                "Prolights@EclFresnel CT+L",
                "ROXX@CLUSTER B2-FC",
                "Robe Lighting@Robin Esprite",
                "Robe Lighting@Robin LEDBeam 150 RGBW",
                "Robe Lighting@Robin LEDBeam 350",
                "Robe Lighting@Robin LedPOINTE",
            ],
            fixturesWithAddresses: 76,
            fixtureCountByGDTFSpec: [
                NamedCount("Astera LED Technology@FP3 Hyperion Tube", 8),
                NamedCount("Elation@Pulse Panel", 8),
                NamedCount("Prolights@EclFresnel CT+L", 8),
                NamedCount("ROXX@CLUSTER B2-FC", 12),
                NamedCount("Robe Lighting@Robin Esprite", 2),
                NamedCount("Robe Lighting@Robin LEDBeam 150 RGBW", 12),
                NamedCount("Robe Lighting@Robin LEDBeam 350", 14),
                NamedCount("Robe Lighting@Robin LedPOINTE", 12),
            ],
            fixtureCountByLayer: [
                NamedCount("01_BELEUCHTUNG", 76),
            ],
            archiveFileCount: 22,
            gdtfFileCount: 8,
            threeDSFileCount: 4,
            glbFileCount: 9
        )
    }
}

// MARK: - Embedded GDTF Parsing Tests

/// Extracts all .gdtf entries from an MVR ZIP archive and parses each one
/// with the existing GDTF parser, verifying that all embedded GDTF files
/// can be extracted and parsed successfully.
///
/// Some MVR exporters bundle GDTF files that our parser cannot handle yet
/// (e.g. files without description.xml or with non-standard structure).
/// The test records an issue for each file that fails to parse but does
/// not stop — this way we see the full picture of which files work.
func parseAllEmbeddedGDTF(from fixture: MVRTestFixture) throws {
    let data = try Data(contentsOf: fixture.url)
    let archive = try #require(Archive(data: data, accessMode: .read), "Failed to open MVR as ZIP: \(fixture.filename)")

    var gdtfEntries: [Entry] = []
    for entry in archive where entry.path.hasSuffix(".gdtf") {
        gdtfEntries.append(entry)
    }

    #expect(!gdtfEntries.isEmpty, "No .gdtf files found in \(fixture.filename)")

    for entry in gdtfEntries {
        var gdtfData = Data()
        _ = try archive.extract(entry) { chunk in gdtfData.append(chunk) }
        do {
            let gdtf = try loadGDTF(data: gdtfData)
            #expect(
                !gdtf.fixtureType.name.isEmpty,
                "GDTF '\(entry.path)' in \(fixture.filename) parsed but has empty fixture type name"
            )
        } catch {
            Issue.record("Failed to parse GDTF '\(entry.path)' in \(fixture.filename): \(error)")
        }
    }
}

@Suite("MVR Embedded GDTF Parsing")
struct MVREmbeddedGDTFTests {
    @Test func basicFixtureGDTF() throws { try parseAllEmbeddedGDTF(from: basicFixtureMVR) }
    @Test func sevenFixturesSampleGDTF() throws { try parseAllEmbeddedGDTF(from: sevenFixturesSampleMVR) }
    @Test func simpleShowGDTF() throws { try parseAllEmbeddedGDTF(from: simpleShowMVR) }
    @Test func demoshowGrandMA3GDTF() throws { try parseAllEmbeddedGDTF(from: demoshowGrandMA3MVR) }
    @Test func sceneObjectsGDTF() throws { try parseAllEmbeddedGDTF(from: sceneObjectsMVR) }
    @Test func fixtureLineGltfGDTF() throws { try parseAllEmbeddedGDTF(from: fixtureLineGltfMVR) }
    @Test func captureDemoShowGDTF() throws { try parseAllEmbeddedGDTF(from: captureDemoShowMVR) }
    @Test func templateStage1GDTF() throws { try parseAllEmbeddedGDTF(from: templateStage1MVR) }
    @Test func keyArenaRemakeGDTF() throws { try parseAllEmbeddedGDTF(from: keyArenaRemakeMVR) }
    @Test func demostageGDTF() throws { try parseAllEmbeddedGDTF(from: demostageMVR) }
    @Test func basicFestivalGDTF() throws { try parseAllEmbeddedGDTF(from: basicFestivalMVR) }
    @Test func circleStageGDTF() throws { try parseAllEmbeddedGDTF(from: circleStageMVR) }
    @Test func messyPatchGDTF() throws { try parseAllEmbeddedGDTF(from: messyPatchMVR) }
    @Test func midsizeWithGPGDTF() throws { try parseAllEmbeddedGDTF(from: midsizeWithGPMVR) }
}
