import Testing
import Foundation
import simd
@testable import SwiftGDTF

// MARK: - Cross-Document Copy/Paste Tests
//
// These test the clipboard serialization round-trip: selecting objects from
// one MVR scene, encoding them to a clipboard MVR archive (with embedded
// resources), then decoding and inserting into a different scene.

/// Simulates the clipboard flow: select objects → encodeMVR → loadMVR → insert.
/// Returns (targetScene with pasted objects, clipboard archive for resource extraction).
func simulateCopyPaste(
    sourceScene: MVRScene,
    sourceArchive: MVRArchive,
    selectedIDs: Set<UUID>,
    targetScene: MVRScene
) throws -> (scene: MVRScene, clipboardArchive: MVRArchive) {
    // 1. Collect selected objects from source
    var objectMap: [UUID: MVRChildObject] = [:]
    func walk(_ objects: [MVRChildObject]) {
        for obj in objects { objectMap[obj.uuid] = obj; walk(obj.childList) }
    }
    for layer in sourceScene.scene.layers { walk(layer.childList) }

    let selectedObjects = selectedIDs.compactMap { objectMap[$0] }
    guard !selectedObjects.isEmpty else { throw TestError.noSelection }

    // 2. Create clipboard MVR with selected objects + resources
    let clipScene = MVRScene(scene: MVRSceneNode(
        auxData: MVRAUXData(),
        layers: [MVRLayer(uuid: UUID(), name: "_clipboard", childList: selectedObjects)]
    ))

    // Collect resources needed by these objects
    var resources: [String: Data] = [:]
    for obj in selectedObjects {
        if let spec = obj.gdtfSpec {
            let specWithExt = spec.hasSuffix(".gdtf") ? spec : spec + ".gdtf"
            if let data = try? sourceArchive.extractResource(named: specWithExt) {
                resources[specWithExt] = data
            } else if let data = try? sourceArchive.extractResource(named: spec) {
                resources[spec] = data
            }
        }
        // Also collect geometry resources
        for geo in obj.geometries {
            if case .geometry3D(let g) = geo {
                let name = g.fileName.contains(".") ? g.fileName : g.fileName + ".3ds"
                if let data = try? sourceArchive.extractResource(named: name) {
                    resources[name] = data
                }
            }
        }
    }

    let clipData = try encodeMVR(scene: clipScene, resources: resources)
    let clipArchive = try MVRArchive(data: clipData)

    // 3. Parse clipboard and insert into target
    let decodedScene = try loadMVR(data: clipData)
    guard let clipLayer = decodedScene.scene.layers.first else { throw TestError.emptyClipboard }

    var pastedObjects = clipLayer.childList
    for i in pastedObjects.indices {
        pastedObjects[i].reassignUUIDs()
    }

    var result = targetScene
    guard !result.scene.layers.isEmpty else { throw TestError.noTargetLayer }
    result.scene.layers[0].childList.append(contentsOf: pastedObjects)

    return (result, clipArchive)
}

enum TestError: Error {
    case noSelection, emptyClipboard, noTargetLayer
}

// MARK: - Tests

@Suite("Cross-Document Copy/Paste")
struct CrossDocumentCopyPasteTests {

    @Test("Paste fixture from one MVR to another preserves GDTF spec")
    func pastePreservesGDTFSpec() throws {
        // Source: 7-fixtures-sample (has Robe ColorWash 2500 AT)
        let sourceData = try Data(contentsOf: sevenFixturesSampleMVR.url)
        let sourceArchive = try MVRArchive(data: sourceData)
        let sourceScene = sourceArchive.scene

        // Target: basic_fixture (has LED PAR 64 RGBW)
        let targetData = try Data(contentsOf: basicFixtureMVR.url)
        let targetScene = try loadMVR(data: targetData)

        // Select first fixture from source
        let firstFixtureID = sourceScene.scene.layers[0].childList[0].uuid
        let (result, _) = try simulateCopyPaste(
            sourceScene: sourceScene, sourceArchive: sourceArchive,
            selectedIDs: [firstFixtureID], targetScene: targetScene
        )

        // The pasted fixture should have the source's GDTF spec
        let sourceSpec = sourceScene.scene.layers[0].childList[0].gdtfSpec
        let pastedFixtures = result.scene.layers[0].childList.filter { $0.uuid != result.scene.layers[0].childList.first?.uuid }
        #expect(!pastedFixtures.isEmpty, "No fixtures were pasted")
        let pastedSpec = pastedFixtures.first?.gdtfSpec
        #expect(pastedSpec == sourceSpec, "GDTF spec not preserved: \(pastedSpec ?? "nil") vs \(sourceSpec ?? "nil")")
    }

    @Test("Paste fixture includes GDTF resource data in clipboard archive")
    func pasteIncludesGDTFResource() throws {
        let sourceData = try Data(contentsOf: sevenFixturesSampleMVR.url)
        let sourceArchive = try MVRArchive(data: sourceData)
        let sourceScene = sourceArchive.scene

        let targetData = try Data(contentsOf: basicFixtureMVR.url)
        let targetScene = try loadMVR(data: targetData)

        let firstFixtureID = sourceScene.scene.layers[0].childList[0].uuid
        let (_, clipArchive) = try simulateCopyPaste(
            sourceScene: sourceScene, sourceArchive: sourceArchive,
            selectedIDs: [firstFixtureID], targetScene: targetScene
        )

        // The clipboard archive should contain the GDTF file
        let resourceNames = try clipArchive.resourceNames
        let gdtfResources = resourceNames.filter { $0.hasSuffix(".gdtf") }
        #expect(!gdtfResources.isEmpty, "No GDTF resources in clipboard: \(resourceNames)")
        print("Clipboard resources: \(resourceNames)")
    }

    @Test("Paste GDTF from clipboard archive can be loaded")
    func pasteGDTFCanBeLoaded() throws {
        let sourceData = try Data(contentsOf: sevenFixturesSampleMVR.url)
        let sourceArchive = try MVRArchive(data: sourceData)
        let sourceScene = sourceArchive.scene

        let targetData = try Data(contentsOf: basicFixtureMVR.url)
        let targetScene = try loadMVR(data: targetData)

        let firstFixtureID = sourceScene.scene.layers[0].childList[0].uuid
        let (result, clipArchive) = try simulateCopyPaste(
            sourceScene: sourceScene, sourceArchive: sourceArchive,
            selectedIDs: [firstFixtureID], targetScene: targetScene
        )

        // Try loading the GDTF from the clipboard archive
        let pastedFixture = result.scene.layers[0].childList.last!
        guard let spec = pastedFixture.gdtfSpec else {
            Issue.record("Pasted fixture has no GDTF spec")
            return
        }

        // Try loading with and without .gdtf extension
        let specWithExt = spec.hasSuffix(".gdtf") ? spec : spec + ".gdtf"
        var loaded = false
        for name in [spec, specWithExt] {
            if let data = try? clipArchive.extractResource(named: name),
               let _ = try? loadGDTF(data: data) {
                loaded = true
                break
            }
        }
        let clipResNames = (try? clipArchive.resourceNames) ?? []
        #expect(loaded, "Could not load GDTF '\(spec)' from clipboard archive. Resources: \(clipResNames)")
    }

    @Test("Paste preserves fixture position")
    func pastePreservesPosition() throws {
        let sourceData = try Data(contentsOf: sevenFixturesSampleMVR.url)
        let sourceArchive = try MVRArchive(data: sourceData)
        let sourceScene = sourceArchive.scene

        let targetData = try Data(contentsOf: basicFixtureMVR.url)
        let targetScene = try loadMVR(data: targetData)

        let firstFixture = sourceScene.scene.layers[0].childList[0]
        let sourcePos = firstFixture.matrix.map {
            SIMD3($0.matrix[3][0], $0.matrix[3][1], $0.matrix[3][2])
        } ?? SIMD3<Double>.zero

        let (result, _) = try simulateCopyPaste(
            sourceScene: sourceScene, sourceArchive: sourceArchive,
            selectedIDs: [firstFixture.uuid], targetScene: targetScene
        )

        let pastedFixture = result.scene.layers[0].childList.last!
        let pastedPos = pastedFixture.matrix.map {
            SIMD3($0.matrix[3][0], $0.matrix[3][1], $0.matrix[3][2])
        } ?? SIMD3<Double>.zero

        #expect(abs(sourcePos.x - pastedPos.x) < 1, "X position changed")
        #expect(abs(sourcePos.y - pastedPos.y) < 1, "Y position changed")
        #expect(abs(sourcePos.z - pastedPos.z) < 1, "Z position changed")
    }

    @Test("Paste from scene with groups preserves group structure")
    func pastePreservesGroups() throws {
        // Use the 34-fixture file which has a group
        let sourceData = try Data(contentsOf: circleTestFixture.url)
        let sourceArchive = try MVRArchive(data: sourceData)
        let sourceScene = sourceArchive.scene

        let targetScene = MVRScene(scene: MVRSceneNode(
            auxData: MVRAUXData(),
            layers: [MVRLayer(uuid: UUID(), name: "Target")]
        ))

        // Select the group (which contains 33 fixtures)
        let groupObj = sourceScene.scene.layers[0].childList.first(where: {
            if case .groupObject = $0 { return true }; return false
        })!

        let (result, _) = try simulateCopyPaste(
            sourceScene: sourceScene, sourceArchive: sourceArchive,
            selectedIDs: [groupObj.uuid], targetScene: targetScene
        )

        // The pasted group should have children
        let pastedGroup = result.scene.layers[0].childList.first(where: {
            if case .groupObject = $0 { return true }; return false
        })
        #expect(pastedGroup != nil, "No group was pasted")
        #expect(pastedGroup!.childList.count == groupObj.childList.count,
                "Group children count: \(pastedGroup!.childList.count) vs \(groupObj.childList.count)")
    }

    @Test("Paste across ALL test fixtures — resources roundtrip", arguments: allMVRTestFixtures)
    func pasteResourceRoundTrip(fixture: MVRTestFixture) throws {
        let sourceData = try Data(contentsOf: fixture.url)
        let sourceArchive = try MVRArchive(data: sourceData)
        let sourceScene = sourceArchive.scene

        // Collect all GDTF specs referenced in the scene
        var specs = Set<String>()
        func walk(_ objects: [MVRChildObject]) {
            for obj in objects { if let s = obj.gdtfSpec { specs.insert(s) }; walk(obj.childList) }
        }
        for layer in sourceScene.scene.layers { walk(layer.childList) }

        // For each spec, verify we can extract the GDTF from the source archive
        var extractable = 0
        for spec in specs {
            let withExt = spec.hasSuffix(".gdtf") ? spec : spec + ".gdtf"
            if (try? sourceArchive.extractResource(named: withExt)) != nil ||
               (try? sourceArchive.extractResource(named: spec)) != nil {
                extractable += 1
            }
        }

        print("\(fixture.filename): \(specs.count) GDTF specs, \(extractable) extractable from archive")

        // Simulate paste into empty scene
        if let firstFixture = sourceScene.scene.layers.first?.childList.first {
            let targetScene = MVRScene(scene: MVRSceneNode(
                auxData: MVRAUXData(),
                layers: [MVRLayer(uuid: UUID(), name: "Target")]
            ))
            let (result, clipArchive) = try simulateCopyPaste(
                sourceScene: sourceScene, sourceArchive: sourceArchive,
                selectedIDs: [firstFixture.uuid], targetScene: targetScene
            )

            // Verify pasted fixture exists
            #expect(result.scene.layers[0].childList.count >= 1,
                    "\(fixture.filename): nothing was pasted")

            // Verify clipboard has resources
            let clipResources = (try? clipArchive.resourceNames) ?? []
            if let spec = firstFixture.gdtfSpec {
                let withExt = spec.hasSuffix(".gdtf") ? spec : spec + ".gdtf"
                let hasResource = clipResources.contains(spec) || clipResources.contains(withExt)
                if extractable > 0 {
                    #expect(hasResource,
                            "\(fixture.filename): clipboard missing GDTF '\(spec)'. Has: \(clipResources)")
                }
            }
        }
    }
}
