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


// MARK: - Stub: Parse MVR

/// Parses an MVR file from the given data and returns the scene model.
///
/// **Not yet implemented** — will be replaced by the real parser.
func parseMVR(data: Data) throws -> Never {
    // TODO: Replace return type with the real MVR model type.
    struct MVRParserNotImplemented: Error, CustomStringConvertible {
        let description = "MVR parser not yet implemented. This is the stub that needs to be replaced with the real implementation."
    }
    throw MVRParserNotImplemented()
}

/// Extracts high-level statistics from a parsed MVR scene for test validation.
///
/// **Not yet implemented** — depends on the MVR model type from `parseMVR`.
/// This function intentionally performs more expensive analysis than normal
/// parsing (e.g. flattening the tree, counting across all nesting levels)
/// to produce a comprehensive test snapshot.
func extractMVRStatistics(from mvrData: Data) throws -> MVRSceneStatistics {
    // TODO: Replace with real implementation that:
    // 1. Calls parseMVR(data:) to get the model
    // 2. Walks the model tree to compute statistics
    // For now, just attempt the parse so we get the "not implemented" error.
    _ = try parseMVR(data: mvrData)
    fatalError("unreachable")
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
    // MVR v1.5 | 7 fixtures | 5 layers | Vectorworks export | Non-identity matrices
    @Test func sevenFixturesSample() throws {
        let stats = try loadAndExtractStatistics(from: sevenFixturesSampleMVR)
        expectStatistics(
            stats,
            version: "1.5",
            provider: "Vectorworks",
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
            layerNames: ["Stage"],
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
                NamedCount("Stage", 10),
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
            layerNames: ["Backtruss", "Midtruss", "Fronttruss", "Floor", "LED Wall", "Stage"],
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
                NamedCount("Generic@LED steps small", 4),
                NamedCount("Generic@Led Tile RGB8 Wall", 72),
                NamedCount("Martin Professional@MAC Encore Performance CLD", 48),
                NamedCount("Martin@Mac Aura XB", 36),
                NamedCount("Martin@Rush Par 2 RGBW Zoom", 16),
            ],
            fixtureCountByLayer: [
                NamedCount("Backtruss", 34),
                NamedCount("Floor", 16),
                NamedCount("Fronttruss", 30),
                NamedCount("LED Wall", 72),
                NamedCount("Midtruss", 20),
                NamedCount("Stage", 4),
            ],
            archiveFileCount: 13,
            gdtfFileCount: 5,
            threeDSFileCount: 5
        )
    }

    // MARK: scene_objects.mvr
    // MVR v1.5 | 72 fixtures | 7 layers | Vectorworks | FocusPoints + SceneObjects with GLB geometry
    @Test func sceneObjects() throws {
        let stats = try loadAndExtractStatistics(from: sceneObjectsMVR)
        expectStatistics(
            stats,
            version: "1.5",
            provider: "Vectorworks",
            layerCount: 7,
            layerNames: [
                "Theatre FloorPlan", "Hanging Positions",
                "Focus Points", "Audience Seating", "Balcony",
                "Main", "Scenic Dressing",
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
                NamedCount("Hanging Positions", 72),
            ],
            archiveFileCount: 17,
            gdtfFileCount: 1,
            glbFileCount: 15
        )
    }

    // MARK: fixture-line-gltf.mvr
    // MVR v1.5 | 16 fixtures | 1 layer | Vectorworks | 4 GDTF specs with GLB meshes inside
    @Test func fixtureLineGltf() throws {
        let stats = try loadAndExtractStatistics(from: fixtureLineGltfMVR)
        expectStatistics(
            stats,
            version: "1.5",
            provider: "Vectorworks",
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
                NamedCount("Robe Lighting@Robin BMFL Wash.gdtf", 4),
                NamedCount("Robe Lighting@Robin MMX Blade.gdtf", 4),
                NamedCount("Robe Lighting@Robin Spiider.gdtf", 4),
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
                "Default layer", "Truss Lights", "Wash Lights",
                "PAR Cans", "Blinders", "Projection",
                "Truss", "Wall", "Roof", "Misc", "Floor",
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
                NamedCount("ADB@ALC4@r3012.gdtf", 16),
                NamedCount("Clay Paky@A.leda Wash K20@r3044.gdtf", 10),
                NamedCount("Clay Paky@Alpha Spot QWO 800@r3048.gdtf", 20),
                NamedCount("Robe@Robin MMX Spot@r3046.gdtf", 10),
                NamedCount("Robe@Robin MMX WashBeam@r3039.gdtf", 20),
            ],
            fixtureCountByLayer: [
                NamedCount("Blinders", 4),
                NamedCount("PAR Cans", 16),
                NamedCount("Projection", 4),
                NamedCount("Truss Lights", 20),
                NamedCount("Wash Lights", 32),
            ],
            archiveFileCount: 24,
            gdtfFileCount: 5,
            threeDSFileCount: 17
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
            layerNames: ["Stage", "Truss"],
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
                NamedCount("GLP@JDC1 Strobe@r3034.gdtf", 18),
                NamedCount("Martin@MAC Aura XIP@r3009.gdtf", 24),
                NamedCount("Martin@MAC Viper XIP@r3000.gdtf", 24),
                NamedCount("Robe@Robin MegaPointe@r3038.gdtf", 28),
                NamedCount("Robe@Robin Tetra2@r3031.gdtf", 24),
            ],
            fixtureCountByLayer: [
                NamedCount("Truss", 118),
            ],
            archiveFileCount: 8,
            gdtfFileCount: 5,
            threeDSFileCount: 2
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
                "Automation", "Blinders", "Followspots", "Main Stage - East",
                "Main Stage - North", "Main Stage - South", "Main Stage - West",
                "Scenery", "Side Stage - East", "Side Stage - North",
                "Side Stage - South", "Side Stage - West", "Spot Lights",
                "Strobes", "Wash Lights",
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
                NamedCount("Elation@Colour Chorus 72.gdtf", 32),
                NamedCount("Elation@Platinum Beam 5R Extreme.gdtf", 8),
                NamedCount("Generic@Par 64.gdtf", 16),
                NamedCount("James Thomas Engineering@Molefay 4 Cell Blinder.gdtf", 16),
                NamedCount("Martin@Atomic 3000 LED.gdtf", 8),
                NamedCount("Martin@MAC 101.gdtf", 48),
                NamedCount("Martin@MAC Viper Profile.gdtf", 40),
            ],
            fixtureCountByLayer: [
                NamedCount("Blinders", 16),
                NamedCount("Followspots", 4),
                NamedCount("Main Stage - East", 12),
                NamedCount("Main Stage - North", 28),
                NamedCount("Main Stage - South", 28),
                NamedCount("Main Stage - West", 12),
                NamedCount("Side Stage - East", 4),
                NamedCount("Side Stage - North", 8),
                NamedCount("Side Stage - South", 8),
                NamedCount("Side Stage - West", 4),
                NamedCount("Spot Lights", 16),
                NamedCount("Strobes", 8),
                NamedCount("Wash Lights", 20),
            ],
            archiveFileCount: 10,
            gdtfFileCount: 7,
            threeDSFileCount: 2
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
                "Spot", "Wash", "FX1", "FX2", "Blinder", "LED",
                "Backlight", "Stairs", "Curtain", "Truss", "Stage", "Screen",
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
                NamedCount("Ayrton@MagicDot SX", 12),
                NamedCount("Generic@LED Wall 10x10", 16),
                NamedCount("Martin Professional@MAC Aura XB", 24),
                NamedCount("Martin Professional@MAC Ultra Performance", 16),
                NamedCount("Prolights@EclFresnel2KTW", 11),
                NamedCount("Prolights@Sunrise2IP", 24),
                NamedCount("Robe Lighting@Robin SuperSpikie", 16),
            ],
            fixtureCountByLayer: [
                NamedCount("Backlight", 11),
                NamedCount("Blinder", 12),
                NamedCount("FX1", 8),
                NamedCount("FX2", 8),
                NamedCount("LED", 16),
                NamedCount("Spot", 16),
                NamedCount("Wash", 48),
            ],
            archiveFileCount: 9,
            gdtfFileCount: 7,
            glbFileCount: 1
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
                "Esprite A", "Esprite B", "Esprite Floor",
                "Spiider A", "Spiider B", "Spiider Floor",
                "Viper A", "Viper B", "Viper Floor",
                "Cluster FOH A", "Cluster FOH B", "Cluster FOH Floor",
                "Cluster B4 A", "Cluster B4 B", "Cluster B4 Floor",
                "Astera", "Blinder", "Stage", "Truss 1",
                "Truss 2", "Truss 3", "Ground Support", "FOH",
                "Crowd Barrier", "Floor Truss",
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
                NamedCount("Astera LED Technology@AX2-100 PixelBar.gdtf", 8),
                NamedCount("Cluster S2", 12),
                NamedCount("Custom@Roxx_Cluster_B4_FC.gdtf", 6),
                NamedCount("Martin Professional@MAC Viper AirFX.gdtf", 18),
                NamedCount("ROXX@CLUSTER B4-FC.gdtf", 6),
                NamedCount("Robe Lighting@Robin Esprite.gdtf", 30),
                NamedCount("Robe Lighting@Robin Spiider.gdtf", 60),
                NamedCount("Roxx@Cluster S2.gdtf", 6),
            ],
            fixtureCountByLayer: [
                NamedCount("Astera", 8),
                NamedCount("Blinder", 12),
                NamedCount("Cluster B4 A", 4),
                NamedCount("Cluster B4 B", 4),
                NamedCount("Cluster B4 Floor", 4),
                NamedCount("Cluster FOH A", 4),
                NamedCount("Cluster FOH B", 4),
                NamedCount("Cluster FOH Floor", 4),
                NamedCount("Esprite A", 10),
                NamedCount("Esprite B", 10),
                NamedCount("Esprite Floor", 10),
                NamedCount("Spiider A", 20),
                NamedCount("Spiider B", 20),
                NamedCount("Spiider Floor", 20),
                NamedCount("Viper A", 6),
                NamedCount("Viper B", 6),
                NamedCount("Viper Floor", 6),
            ],
            archiveFileCount: 10,
            gdtfFileCount: 7,
            glbFileCount: 2
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
                "Esprite Floor", "Esprite A", "Esprite B",
                "Spiider A", "Spiider B", "Spiider Floor",
                "LedPOINTE A", "LedPOINTE B",
                "Tetra A", "Tetra B",
                "TetraX A", "TetraX B",
                "Stage Main", "Stage Small", "Stage Back",
                "Stage Walkway", "Ground Support",
                "Truss 1", "Truss 2", "Truss 3",
                "Floor Truss", "Ground Truss",
                "Audience", "Crowd Barrier",
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
                NamedCount("Robe Lighting@Robin Esprite.gdtf", 22),
                NamedCount("Robe Lighting@Robin LedPOINTE.gdtf", 16),
                NamedCount("Robe Lighting@Robin Spiider.gdtf", 16),
                NamedCount("Robe Lighting@Robin Tetra2.gdtf", 12),
                NamedCount("Robe Lighting@Robin TetraX.gdtf", 8),
            ],
            fixtureCountByLayer: [
                NamedCount("Esprite A", 8),
                NamedCount("Esprite B", 8),
                NamedCount("Esprite Floor", 6),
                NamedCount("LedPOINTE A", 8),
                NamedCount("LedPOINTE B", 8),
                NamedCount("Spiider A", 6),
                NamedCount("Spiider B", 6),
                NamedCount("Spiider Floor", 4),
                NamedCount("Tetra A", 6),
                NamedCount("Tetra B", 6),
                NamedCount("TetraX A", 4),
                NamedCount("TetraX B", 4),
            ],
            archiveFileCount: 8,
            gdtfFileCount: 5,
            glbFileCount: 2
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
                "Spots", "Wash A", "Wash B", "FX",
                "Blinder A", "Blinder B",
                "Truss A", "Truss B", "Ground Support",
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
                NamedCount("Prolights@Sunrise2IP", 24),
                NamedCount("Robe Lighting@Robin Esprite", 27),
                NamedCount("Robe Lighting@Robin Spiider", 60),
                NamedCount("SGM Light@Q-8", 24),
            ],
            fixtureCountByLayer: [
                NamedCount("Blinder A", 12),
                NamedCount("Blinder B", 12),
                NamedCount("FX", 24),
                NamedCount("Spots", 27),
                NamedCount("Wash A", 30),
                NamedCount("Wash B", 30),
            ],
            archiveFileCount: 6,
            gdtfFileCount: 4,
            glbFileCount: 1
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
                "Esprite Stage A", "Esprite Stage B",
                "LedBeam 150 Stage A", "LedBeam 150 Stage B",
                "LedPOINTE Stage A", "LedPOINTE Stage B",
                "LedBeam 350 A", "LedBeam 350 B",
                "Cluster", "Astera",
                "Fresnel A", "Fresnel B",
                "Pulse Panel A", "Pulse Panel B",
                "Stage Front", "Stage Back",
                "Ground Support Front", "Ground Support Back",
                "Truss 1", "Truss 2",
                "Truss 3", "Truss 4",
                "Audience", "Crowd Barrier",
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
                NamedCount("Elation@Pulse Panel", 4),
                NamedCount("Prolights@EclFresnel CT+L", 8),
                NamedCount("ROXX@CLUSTER B2-FC", 4),
                NamedCount("Robe Lighting@Robin Esprite", 12),
                NamedCount("Robe Lighting@Robin LEDBeam 150 RGBW", 16),
                NamedCount("Robe Lighting@Robin LEDBeam 350", 8),
                NamedCount("Robe Lighting@Robin LedPOINTE", 16),
            ],
            fixtureCountByLayer: [
                NamedCount("Astera", 8),
                NamedCount("Cluster", 4),
                NamedCount("Esprite Stage A", 6),
                NamedCount("Esprite Stage B", 6),
                NamedCount("Fresnel A", 4),
                NamedCount("Fresnel B", 4),
                NamedCount("LedBeam 150 Stage A", 8),
                NamedCount("LedBeam 150 Stage B", 8),
                NamedCount("LedBeam 350 A", 4),
                NamedCount("LedBeam 350 B", 4),
                NamedCount("LedPOINTE Stage A", 8),
                NamedCount("LedPOINTE Stage B", 8),
                NamedCount("Pulse Panel A", 2),
                NamedCount("Pulse Panel B", 2),
            ],
            archiveFileCount: 10,
            gdtfFileCount: 8,
            glbFileCount: 1
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
