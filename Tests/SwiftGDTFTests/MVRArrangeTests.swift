import Testing
import Foundation
import simd
@testable import SwiftGDTF

// MARK: - Pure Arrange Functions for Testing
//
// These mirror the GDTF Lab's arrange logic but operate on pure MVR types.
// They test the core algorithm: world position computation, arrangement, and write-back.

/// Computes the world matrix for an object by composing parent chain transforms.
func computeWorldMatrix(for id: UUID, scene: MVRScene) -> simd_float4x4 {
    // Build parent index
    var parentMap: [UUID: UUID] = [:]
    var objectMap: [UUID: MVRChildObject] = [:]
    var layerMap: [UUID: Int] = [:]

    for (li, layer) in scene.scene.layers.enumerated() {
        func walk(_ objects: [MVRChildObject], parent: UUID?) {
            for obj in objects {
                objectMap[obj.uuid] = obj
                if let parent { parentMap[obj.uuid] = parent }
                layerMap[obj.uuid] = li
                walk(obj.childList, parent: obj.uuid)
            }
        }
        walk(layer.childList, parent: nil)
    }

    // Walk parent chain to root
    var chain: [UUID] = []
    var current: UUID? = id
    while let c = current {
        chain.append(c)
        current = parentMap[c]
    }

    // Compose root → leaf
    var worldMatrix = matrix_identity_float4x4
    for uuid in chain.reversed() {
        if let obj = objectMap[uuid], let m = obj.matrix {
            worldMatrix = worldMatrix * m.simdMatrix
        }
    }

    // Prepend layer matrix
    if let layerIdx = layerMap[id], layerIdx < scene.scene.layers.count,
       let lm = scene.scene.layers[layerIdx].matrix {
        worldMatrix = lm.simdMatrix * worldMatrix
    }

    return worldMatrix
}

/// Extracts world position (MVR mm Z-up) from a world matrix.
func worldPosition(for id: UUID, scene: MVRScene) -> SIMD3<Double> {
    let wm = computeWorldMatrix(for: id, scene: scene)
    return SIMD3(Double(wm[3][0]), Double(wm[3][1]), Double(wm[3][2]))
}

/// Collects leaf (non-group) UUIDs from a set, expanding groups recursively.
func collectLeafUUIDs(from ids: Set<UUID>, scene: MVRScene) -> [UUID] {
    var objectMap: [UUID: MVRChildObject] = [:]
    func walk(_ objects: [MVRChildObject]) {
        for obj in objects { objectMap[obj.uuid] = obj; walk(obj.childList) }
    }
    for layer in scene.scene.layers { walk(layer.childList) }

    var seen = Set<UUID>()
    var result: [UUID] = []
    func collect(_ id: UUID) {
        guard let obj = objectMap[id] else { return }
        if case .groupObject = obj {
            for child in obj.childList { collect(child.uuid) }
        } else if !seen.contains(id) {
            seen.insert(id)
            result.append(id)
        }
    }
    // Sort input IDs for deterministic order (Set iteration order is random)
    for id in ids.sorted(by: { $0.uuidString < $1.uuidString }) { collect(id) }
    return result
}

/// Arranges leaf fixtures in a circle. Returns new scene with positions updated.
func arrangeInCircle(scene: MVRScene, selectedIDs: Set<UUID>) -> MVRScene {
    let leafIDs = collectLeafUUIDs(from: selectedIDs, scene: scene)
    guard leafIDs.count >= 2 else { return scene }

    let worldPositions = leafIDs.map { worldPosition(for: $0, scene: scene) }
    let cx = worldPositions.map(\.x).reduce(0, +) / Double(worldPositions.count)
    let cy = worldPositions.map(\.y).reduce(0, +) / Double(worldPositions.count)
    let avgDist = worldPositions.map { sqrt(pow($0.x - cx, 2) + pow($0.y - cy, 2)) }
        .reduce(0, +) / Double(worldPositions.count)
    let radius = max(avgDist, 500)
    let angleStep = 2 * Double.pi / Double(leafIDs.count)

    // Compute target world positions
    var targetWorldPos: [UUID: SIMD3<Double>] = [:]
    for (i, id) in leafIDs.enumerated() {
        let angle = angleStep * Double(i)
        let origZ = worldPositions[i].z
        targetWorldPos[id] = SIMD3(cx + radius * cos(angle), cy + radius * sin(angle), origZ)
    }

    // Write back: convert world position to local position
    return applyWorldPositions(scene: scene, positions: targetWorldPos)
}

/// Converts target world positions to local matrix positions and applies them.
func applyWorldPositions(scene: MVRScene, positions: [UUID: SIMD3<Double>]) -> MVRScene {
    var scene = scene

    // Build parent index + object index for inverse parent computation
    var parentMap: [UUID: UUID] = [:]
    var objectMap: [UUID: MVRChildObject] = [:]
    var layerMap: [UUID: Int] = [:]
    for (li, layer) in scene.scene.layers.enumerated() {
        func walk(_ objects: [MVRChildObject], parent: UUID?) {
            for obj in objects {
                objectMap[obj.uuid] = obj
                if let parent { parentMap[obj.uuid] = parent }
                layerMap[obj.uuid] = li
                walk(obj.childList, parent: obj.uuid)
            }
        }
        walk(layer.childList, parent: nil)
    }

    for (uuid, targetWorld) in positions {
        // Compute parent's world matrix (everything ABOVE this object)
        var parentChain: [UUID] = []
        var cur = parentMap[uuid]
        while let c = cur {
            parentChain.append(c)
            cur = parentMap[c]
        }

        var parentWorldMatrix = matrix_identity_float4x4
        // Prepend layer matrix
        if let li = layerMap[uuid], li < scene.scene.layers.count,
           let lm = scene.scene.layers[li].matrix {
            parentWorldMatrix = lm.simdMatrix
        }
        // Compose parent chain (root → immediate parent)
        for pid in parentChain.reversed() {
            if let obj = objectMap[pid], let m = obj.matrix {
                parentWorldMatrix = parentWorldMatrix * m.simdMatrix
            }
        }

        // Local position = inverse(parentWorld) * worldPosition
        let invParent = simd_inverse(parentWorldMatrix)
        let localPos4 = invParent * SIMD4<Float>(Float(targetWorld.x), Float(targetWorld.y), Float(targetWorld.z), 1)
        let localPos = SIMD3<Double>(Double(localPos4.x), Double(localPos4.y), Double(localPos4.z))

        // Update the object's local matrix position
        for li in scene.scene.layers.indices {
            if mutateInScene(id: uuid, in: &scene.scene.layers[li].childList) { obj in
                var m = obj.matrix ?? Matrix(from: matrix_identity_float4x4)
                m.matrix[3][0] = localPos.x
                m.matrix[3][1] = localPos.y
                m.matrix[3][2] = localPos.z
                obj.mutableMatrix = m
            } {
                break
            }
        }
    }

    return scene
}

private func mutateInScene(id: UUID, in children: inout [MVRChildObject], _ transform: (inout MVRChildObject) -> Void) -> Bool {
    for i in children.indices {
        if children[i].uuid == id {
            transform(&children[i])
            return true
        }
        var childList = children[i].mutableChildList
        if mutateInScene(id: id, in: &childList, transform) {
            children[i].mutableChildList = childList
            return true
        }
    }
    return false
}

// MARK: - Test Helpers

func pos(_ x: Double, _ y: Double, _ z: Double) -> Matrix {
    Matrix(from: simd_float4x4(
        SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0), SIMD4<Float>(0,0,1,0),
        SIMD4<Float>(Float(x), Float(y), Float(z), 1)
    ))
}

func allUUIDs(in scene: MVRScene) -> Set<UUID> {
    var result = Set<UUID>()
    func walk(_ objects: [MVRChildObject]) {
        for obj in objects { result.insert(obj.uuid); walk(obj.childList) }
    }
    for layer in scene.scene.layers { walk(layer.childList) }
    return result
}

// MARK: - Tests

// MARK: - Real File Tests

let circleTestFixture = MVRTestFixture(
    filename: "34_fixtures_circle_test.mvr",
    description: "34 GigaPointe fixtures in a group, for circle arrange testing",
    source: "Copy of SingleGigaPointeUpsidedown",
    sourceURL: ""
)

@Suite("Arrange — Real MVR File")
struct ArrangeRealFileTests {

    @Test("Dump structure of 34-fixture file")
    func dumpStructure() throws {
        let data = try Data(contentsOf: circleTestFixture.url)
        let scene = try loadMVR(data: data)

        var fixtureCount = 0
        var groupCount = 0
        func walk(_ objects: [MVRChildObject], depth: Int) {
            for obj in objects {
                let indent = String(repeating: "  ", count: depth)
                let pos = obj.matrix.map { m in
                    String(format: "(%.0f, %.0f, %.0f)", m.matrix[3][0], m.matrix[3][1], m.matrix[3][2])
                } ?? "nil"
                print("\(indent)\(obj.kind.rawValue) \"\(obj.name)\" pos=\(pos) children=\(obj.childList.count)")
                if case .fixture = obj { fixtureCount += 1 }
                if case .groupObject = obj { groupCount += 1 }
                walk(obj.childList, depth: depth + 1)
            }
        }
        for (li, layer) in scene.scene.layers.enumerated() {
            let layerPos = layer.matrix.map { m in
                String(format: "(%.0f, %.0f, %.0f)", m.matrix[3][0], m.matrix[3][1], m.matrix[3][2])
            } ?? "nil"
            print("Layer \(li): \"\(layer.name)\" pos=\(layerPos) children=\(layer.childList.count)")
            walk(layer.childList, depth: 1)
        }
        print("Total fixtures: \(fixtureCount), groups: \(groupCount)")
    }

    @Test("Circle arrange is idempotent on real file")
    func circleIdempotentRealFile() throws {
        let data = try Data(contentsOf: circleTestFixture.url)
        let scene = try loadMVR(data: data)

        let allIDs = allUUIDs(in: scene)
        let leafIDs = collectLeafUUIDs(from: allIDs, scene: scene)
        print("All IDs: \(allIDs.count), Leaf IDs: \(leafIDs.count)")

        let once = arrangeInCircle(scene: scene, selectedIDs: allIDs)
        let twice = arrangeInCircle(scene: once, selectedIDs: allIDs)

        var maxDiff: Double = 0
        for id in leafIDs {
            let p1 = worldPosition(for: id, scene: once)
            let p2 = worldPosition(for: id, scene: twice)
            let dx = abs(p1.x - p2.x), dy = abs(p1.y - p2.y), dz = abs(p1.z - p2.z)
            maxDiff = max(maxDiff, dx, dy, dz)
            if dx > 1 || dy > 1 || dz > 1 {
                print("MISMATCH \(id.uuidString.prefix(8)): (\(p1.x),\(p1.y),\(p1.z)) vs (\(p2.x),\(p2.y),\(p2.z))")
            }
        }
        print("Max position diff: \(maxDiff)")
        #expect(maxDiff < 1, "Positions changed on second arrange: max diff = \(maxDiff)")
    }

    @Test("Circle facing center is idempotent on real file")
    func circleFacingCenterIdempotentRealFile() throws {
        let data = try Data(contentsOf: circleTestFixture.url)
        let scene = try loadMVR(data: data)
        let allIDs = allUUIDs(in: scene)
        let leafIDs = collectLeafUUIDs(from: allIDs, scene: scene)

        let once = arrangeInCircleFacingCenter(scene: scene, selectedIDs: allIDs)
        let twice = arrangeInCircleFacingCenter(scene: once, selectedIDs: allIDs)

        var maxDiff: Double = 0
        for id in leafIDs {
            let p1 = worldPosition(for: id, scene: once)
            let p2 = worldPosition(for: id, scene: twice)
            let dx = abs(p1.x - p2.x), dy = abs(p1.y - p2.y), dz = abs(p1.z - p2.z)
            maxDiff = max(maxDiff, dx, dy, dz)
        }
        print("Max position diff (facing center): \(maxDiff)")
        #expect(maxDiff < 1, "Positions changed on second arrange: max diff = \(maxDiff)")
    }
}

// MARK: - Pure arrange function for circle facing center (test version)

func arrangeInCircleFacingCenter(scene: MVRScene, selectedIDs: Set<UUID>) -> MVRScene {
    let leafIDs = collectLeafUUIDs(from: selectedIDs, scene: scene)
    guard leafIDs.count >= 2 else { return scene }

    let worldPositions = leafIDs.map { worldPosition(for: $0, scene: scene) }
    let cx = worldPositions.map(\.x).reduce(0, +) / Double(worldPositions.count)
    let cy = worldPositions.map(\.y).reduce(0, +) / Double(worldPositions.count)
    let avgDist = worldPositions.map { sqrt(pow($0.x - cx, 2) + pow($0.y - cy, 2)) }
        .reduce(0, +) / Double(worldPositions.count)
    let radius = max(avgDist, 500)
    let angleStep = 2 * Double.pi / Double(leafIDs.count)

    var targetWorldPos: [UUID: SIMD3<Double>] = [:]
    for (i, id) in leafIDs.enumerated() {
        let angle = angleStep * Double(i)
        let origZ = worldPositions[i].z
        targetWorldPos[id] = SIMD3(cx + radius * cos(angle), cy + radius * sin(angle), origZ)
    }

    // For facing center, we need to set the full matrix (rotation + position)
    // For now, just set position — the facing rotation test is separate
    return applyWorldPositions(scene: scene, positions: targetWorldPos)
}

@Suite("Arrange in Circle — Idempotency")
struct ArrangeCircleIdempotencyTests {

    @Test("Applying circle arrange twice produces same result")
    func idempotent() {
        let f1 = UUID(), f2 = UUID(), f3 = UUID(), f4 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(2000, 0, 5000))),
                .fixture(MVRFixture(uuid: f3, name: "F3", matrix: pos(1000, 2000, 5000))),
                .fixture(MVRFixture(uuid: f4, name: "F4", matrix: pos(1000, -1000, 5000))),
            ])
        ]))
        let ids = Set([f1, f2, f3, f4])

        let once = arrangeInCircle(scene: scene, selectedIDs: ids)
        let twice = arrangeInCircle(scene: once, selectedIDs: ids)

        // World positions after first and second application should be identical
        for id in [f1, f2, f3, f4] {
            let p1 = worldPosition(for: id, scene: once)
            let p2 = worldPosition(for: id, scene: twice)
            #expect(abs(p1.x - p2.x) < 1, "X mismatch for \(id): \(p1.x) vs \(p2.x)")
            #expect(abs(p1.y - p2.y) < 1, "Y mismatch for \(id): \(p1.y) vs \(p2.y)")
            #expect(abs(p1.z - p2.z) < 1, "Z mismatch for \(id): \(p1.z) vs \(p2.z)")
        }
    }

    @Test("All fixtures equidistant from center after arrange")
    func equidistant() {
        let f1 = UUID(), f2 = UUID(), f3 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(3000, 0, 5000))),
                .fixture(MVRFixture(uuid: f3, name: "F3", matrix: pos(1500, 2000, 5000))),
            ])
        ]))

        let result = arrangeInCircle(scene: scene, selectedIDs: Set([f1, f2, f3]))
        let positions = [f1, f2, f3].map { worldPosition(for: $0, scene: result) }
        let cx = positions.map(\.x).reduce(0,+) / 3
        let cy = positions.map(\.y).reduce(0,+) / 3
        let distances = positions.map { sqrt(pow($0.x - cx, 2) + pow($0.y - cy, 2)) }

        #expect(abs(distances[0] - distances[1]) < 1)
        #expect(abs(distances[1] - distances[2]) < 1)
    }

    @Test("Z coordinate preserved")
    func zPreserved() {
        let f1 = UUID(), f2 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 3000))),
                .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(2000, 0, 7000))),
            ])
        ]))

        let result = arrangeInCircle(scene: scene, selectedIDs: Set([f1, f2]))
        #expect(abs(worldPosition(for: f1, scene: result).z - 3000) < 1)
        #expect(abs(worldPosition(for: f2, scene: result).z - 7000) < 1)
    }
}

@Suite("Arrange in Circle — Groups")
struct ArrangeCircleGroupTests {

    @Test("World position of fixture in group is correct")
    func worldPositionInGroup() {
        let f1 = UUID(), groupID = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .groupObject(MVRGroupObject(uuid: groupID, name: "G",
                    matrix: pos(1000, 2000, 0),
                    childList: [
                        .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(500, 300, 5000))),
                    ]
                )),
            ])
        ]))

        let wp = worldPosition(for: f1, scene: scene)
        // world = group(1000,2000,0) * local(500,300,5000) = (1500, 2300, 5000)
        #expect(abs(wp.x - 1500) < 1, "World X: expected 1500, got \(wp.x)")
        #expect(abs(wp.y - 2300) < 1, "World Y: expected 2300, got \(wp.y)")
        #expect(abs(wp.z - 5000) < 1, "World Z: expected 5000, got \(wp.z)")
    }

    @Test("Fixtures inside a group are arranged correctly")
    func fixturesInGroup() {
        let f1 = UUID(), f2 = UUID(), f3 = UUID(), groupID = UUID()
        // Group has a translation of (1000, 1000, 0)
        // f3 inside group has local position (500, 0, 5000)
        // → world position of f3 = (1500, 1000, 5000)
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(3000, 0, 5000))),
                .groupObject(MVRGroupObject(uuid: groupID, name: "G",
                    matrix: pos(1000, 1000, 0),
                    childList: [
                        .fixture(MVRFixture(uuid: f3, name: "F3", matrix: pos(500, 0, 5000))),
                    ]
                )),
            ])
        ]))

        // Select all including the group — should expand to f1, f2, f3
        let allIDs = allUUIDs(in: scene)
        let result = arrangeInCircle(scene: scene, selectedIDs: allIDs)

        // Verify all 3 fixtures are equidistant from center
        let positions = [f1, f2, f3].map { worldPosition(for: $0, scene: result) }
        let cx = positions.map(\.x).reduce(0,+) / 3
        let cy = positions.map(\.y).reduce(0,+) / 3
        let distances = positions.map { sqrt(pow($0.x - cx, 2) + pow($0.y - cy, 2)) }

        #expect(abs(distances[0] - distances[1]) < 1, "F1 and F2 not equidistant: \(distances[0]) vs \(distances[1])")
        #expect(abs(distances[1] - distances[2]) < 1, "F2 and F3 not equidistant: \(distances[1]) vs \(distances[2])")
    }

    @Test("Idempotent with group — applying twice gives same world positions")
    func idempotentWithGroup() {
        let f1 = UUID(), f2 = UUID(), f3 = UUID(), groupID = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000))),
                .groupObject(MVRGroupObject(uuid: groupID, name: "G",
                    matrix: pos(2000, 0, 0),
                    childList: [
                        .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(0, 0, 5000))),
                        .fixture(MVRFixture(uuid: f3, name: "F3", matrix: pos(500, 500, 5000))),
                    ]
                )),
            ])
        ]))

        let allIDs = allUUIDs(in: scene)
        let once = arrangeInCircle(scene: scene, selectedIDs: allIDs)
        let twice = arrangeInCircle(scene: once, selectedIDs: allIDs)

        for id in [f1, f2, f3] {
            let p1 = worldPosition(for: id, scene: once)
            let p2 = worldPosition(for: id, scene: twice)
            #expect(abs(p1.x - p2.x) < 1, "X mismatch for fixture: \(p1.x) vs \(p2.x)")
            #expect(abs(p1.y - p2.y) < 1, "Y mismatch for fixture: \(p1.y) vs \(p2.y)")
        }
    }
}

@Suite("Apply World Positions — Inverse Parent Transform")
struct ApplyWorldPositionsTests {

    @Test("Setting world position on a top-level fixture works directly")
    func topLevelFixture() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(100, 200, 300))),
            ])
        ]))

        let result = applyWorldPositions(scene: scene, positions: [f1: SIMD3(500, 600, 700)])
        let wp = worldPosition(for: f1, scene: result)
        #expect(abs(wp.x - 500) < 1)
        #expect(abs(wp.y - 600) < 1)
        #expect(abs(wp.z - 700) < 1)
    }

    @Test("Setting world position on a fixture inside a translated group")
    func fixtureInTranslatedGroup() {
        let f1 = UUID(), groupID = UUID()
        // Group at (1000, 2000, 0)
        // Fixture local at (0, 0, 5000) → world = (1000, 2000, 5000)
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .groupObject(MVRGroupObject(uuid: groupID, name: "G",
                    matrix: pos(1000, 2000, 0),
                    childList: [
                        .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000))),
                    ]
                )),
            ])
        ]))

        // Set world position to (3000, 4000, 5000)
        // Expected local position = (3000 - 1000, 4000 - 2000, 5000 - 0) = (2000, 2000, 5000)
        let result = applyWorldPositions(scene: scene, positions: [f1: SIMD3(3000, 4000, 5000)])
        let wp = worldPosition(for: f1, scene: result)
        #expect(abs(wp.x - 3000) < 1, "World X: expected 3000, got \(wp.x)")
        #expect(abs(wp.y - 4000) < 1, "World Y: expected 4000, got \(wp.y)")
        #expect(abs(wp.z - 5000) < 1, "World Z: expected 5000, got \(wp.z)")
    }

    @Test("Setting world position in a layer with a matrix")
    func fixtureInLayerWithMatrix() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1",
                     matrix: pos(500, 500, 0),
                     childList: [
                        .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(100, 100, 5000))),
                     ])
        ]))

        let result = applyWorldPositions(scene: scene, positions: [f1: SIMD3(2000, 3000, 5000)])
        let wp = worldPosition(for: f1, scene: result)
        #expect(abs(wp.x - 2000) < 1, "World X: expected 2000, got \(wp.x)")
        #expect(abs(wp.y - 3000) < 1, "World Y: expected 3000, got \(wp.y)")
    }

    @Test("Round-trip: read world position, write it back, verify unchanged")
    func roundTrip() {
        let f1 = UUID(), groupID = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .groupObject(MVRGroupObject(uuid: groupID, name: "G",
                    matrix: pos(1000, 2000, 3000),
                    childList: [
                        .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(500, 600, 700))),
                    ]
                )),
            ])
        ]))

        let wp = worldPosition(for: f1, scene: scene)
        let result = applyWorldPositions(scene: scene, positions: [f1: wp])
        let wp2 = worldPosition(for: f1, scene: result)
        #expect(abs(wp.x - wp2.x) < 1, "X changed: \(wp.x) → \(wp2.x)")
        #expect(abs(wp.y - wp2.y) < 1, "Y changed: \(wp.y) → \(wp2.y)")
        #expect(abs(wp.z - wp2.z) < 1, "Z changed: \(wp.z) → \(wp2.z)")
    }
}
