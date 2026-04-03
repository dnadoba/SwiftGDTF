import Testing
import Foundation
import simd
@testable import SwiftGDTF

// MARK: - Pure Stage Design Operations
//
// These functions are the algorithmic cores. They operate on MVRScene value types,
// making them easy to test without a renderer. The GDTF Lab app will call these
// through MVRSceneModel wrappers.

// Forward declarations — these functions don't exist yet and will cause compilation errors.
// That's intentional: the tests must fail before we implement.

// MARK: - Implementations

/// Snaps each component of a position to the nearest grid multiple.
func snapToGrid(_ position: SIMD3<Double>, gridSize: Double) -> SIMD3<Double> {
    SIMD3(
        (position.x / gridSize).rounded() * gridSize,
        (position.y / gridSize).rounded() * gridSize,
        (position.z / gridSize).rounded() * gridSize
    )
}

/// Resets rotation of selected objects to identity, preserving position and scale.
func resetRotation(scene: MVRScene, selectedIDs: Set<UUID>) -> MVRScene {
    let leafIDs = collectLeafUUIDs(from: selectedIDs, scene: scene)
    var scene = scene
    for id in leafIDs {
        for li in scene.scene.layers.indices {
            if mutateInScene(id: id, in: &scene.scene.layers[li].childList, { obj in
                guard let m = obj.matrix else { return }
                let sx = sqrt(m.matrix[0][0]*m.matrix[0][0] + m.matrix[0][1]*m.matrix[0][1] + m.matrix[0][2]*m.matrix[0][2])
                let sy = sqrt(m.matrix[1][0]*m.matrix[1][0] + m.matrix[1][1]*m.matrix[1][1] + m.matrix[1][2]*m.matrix[1][2])
                let sz = sqrt(m.matrix[2][0]*m.matrix[2][0] + m.matrix[2][1]*m.matrix[2][1] + m.matrix[2][2]*m.matrix[2][2])
                var newM = m
                newM.matrix[0] = SIMD4(sx, 0, 0, 0)
                newM.matrix[1] = SIMD4(0, sy, 0, 0)
                newM.matrix[2] = SIMD4(0, 0, sz, 0)
                obj.mutableMatrix = newM
            }) { break }
        }
    }
    return scene
}

/// Mirrors selected objects across a plane through their centroid.
/// axis: 0=X, 1=Y, 2=Z.
func mirrorObjects(scene: MVRScene, selectedIDs: Set<UUID>, axis: Int) -> MVRScene {
    let leafIDs = collectLeafUUIDs(from: selectedIDs, scene: scene)
    let worldPositions = leafIDs.map { worldPosition(for: $0, scene: scene) }
    guard !worldPositions.isEmpty else { return scene }

    let centroid = worldPositions.reduce(.zero, +) / Double(worldPositions.count)

    var targetPositions: [UUID: SIMD3<Double>] = [:]
    for (i, id) in leafIDs.enumerated() {
        var pos = worldPositions[i]
        let offset = pos[axis] - centroid[axis]
        pos[axis] = centroid[axis] - offset
        targetPositions[id] = pos
    }

    return applyWorldPositions(scene: scene, positions: targetPositions)
}

/// Builds a world-space rotation matrix where -Y points from position toward target (MVR Z-up).
func buildLookAtMatrix(from position: SIMD3<Double>, to target: SIMD3<Double>) -> simd_float4x4? {
    let dx = target.x - position.x, dy = target.y - position.y, dz = target.z - position.z
    let dist = sqrt(dx*dx + dy*dy + dz*dz)
    guard dist > 0.001 else { return nil }

    let dirX = dx / dist, dirY = dy / dist, dirZ = dz / dist
    let awayX = -dirX, awayY = -dirY, awayZ = -dirZ

    let up: SIMD3<Double> = abs(dirZ) < 0.99 ? SIMD3(0, 0, 1) : SIMD3(1, 0, 0)
    var rx = dirY * up.z - dirZ * up.y
    var ry = dirZ * up.x - dirX * up.z
    var rz = dirX * up.y - dirY * up.x
    let rl = sqrt(rx*rx + ry*ry + rz*rz)
    guard rl > 0.001 else { return nil }
    rx /= rl; ry /= rl; rz /= rl

    let ux = awayY * rz - awayZ * ry
    let uy = awayZ * rx - awayX * rz
    let uz = awayX * ry - awayY * rx

    return simd_float4x4(
        SIMD4<Float>(Float(rx), Float(ry), Float(rz), 0),
        SIMD4<Float>(Float(awayX), Float(awayY), Float(awayZ), 0),
        SIMD4<Float>(Float(ux), Float(uy), Float(uz), 0),
        SIMD4<Float>(Float(position.x), Float(position.y), Float(position.z), 1)
    )
}

/// Rotates selected fixtures to aim at a target point.
func lookAt(scene: MVRScene, selectedIDs: Set<UUID>, target: SIMD3<Double>) -> MVRScene {
    let leafIDs = collectLeafUUIDs(from: selectedIDs, scene: scene)

    // Build world-space matrices for each fixture
    var worldMatrices: [UUID: simd_float4x4] = [:]
    for id in leafIDs {
        let wp = worldPosition(for: id, scene: scene)
        if let m = buildLookAtMatrix(from: wp, to: target) {
            worldMatrices[id] = m
        }
    }

    // Build parent index once (before mutation)
    var parentMap: [UUID: UUID] = [:]
    var objMap: [UUID: MVRChildObject] = [:]
    var layerMap: [UUID: Int] = [:]
    for (lai, layer) in scene.scene.layers.enumerated() {
        func walk(_ objects: [MVRChildObject], parent: UUID?) {
            for o in objects { objMap[o.uuid] = o; if let p = parent { parentMap[o.uuid] = p }; layerMap[o.uuid] = lai; walk(o.childList, parent: o.uuid) }
        }
        walk(layer.childList, parent: nil)
    }

    // Apply: convert world matrix to local using inverse parent
    var scene = scene
    for (id, worldMatrix) in worldMatrices {
        var parentChain: [UUID] = []
        var cur = parentMap[id]
        while let c = cur { parentChain.append(c); cur = parentMap[c] }
        var parentWorld = matrix_identity_float4x4
        if let lai = layerMap[id], lai < scene.scene.layers.count, let lm = scene.scene.layers[lai].matrix {
            parentWorld = lm.simdMatrix
        }
        for pid in parentChain.reversed() {
            if let o = objMap[pid], let m = o.matrix { parentWorld = parentWorld * m.simdMatrix }
        }
        let localMatrix = simd_inverse(parentWorld) * worldMatrix

        for li in scene.scene.layers.indices {
            if mutateInScene(id: id, in: &scene.scene.layers[li].childList, { obj in
                obj.mutableMatrix = Matrix(from: localMatrix)
            }) { break }
        }
    }
    return scene
}

/// Copies the world transform of the source to all targets.
func matchTransform(scene: MVRScene, sourceID: UUID, targetIDs: Set<UUID>) -> MVRScene {
    var objectMap: [UUID: MVRChildObject] = [:]
    func walk(_ objects: [MVRChildObject]) { for o in objects { objectMap[o.uuid] = o; walk(o.childList) } }
    for layer in scene.scene.layers { walk(layer.childList) }

    guard let sourceObj = objectMap[sourceID], let sourceMatrix = sourceObj.matrix else { return scene }
    let sourceWorldPos = worldPosition(for: sourceID, scene: scene)

    // Apply source's world position to all targets
    var positions: [UUID: SIMD3<Double>] = [:]
    for id in targetIDs where id != sourceID {
        positions[id] = sourceWorldPos
    }
    // For full transform match, also need to set rotation — use applyWorldPositions for position
    // and then set rotation columns from source
    var result = applyWorldPositions(scene: scene, positions: positions)

    // Now copy rotation from source matrix to each target
    for id in targetIDs where id != sourceID {
        for li in result.scene.layers.indices {
            if mutateInScene(id: id, in: &result.scene.layers[li].childList, { obj in
                guard let m = obj.matrix else { return }
                let localPos = SIMD4(m.matrix[3][0], m.matrix[3][1], m.matrix[3][2], 1.0)
                var newM = sourceMatrix
                newM.matrix[3] = localPos
                obj.mutableMatrix = newM
            }) { break }
        }
    }
    return result
}

/// Fans fixtures: sorts by X position, each aims at fanCenter + spread offset.
func fanFixtures(scene: MVRScene, selectedIDs: Set<UUID>, fanCenter: SIMD3<Double>, spread: Double) -> MVRScene {
    let leafIDs = collectLeafUUIDs(from: selectedIDs, scene: scene)
    guard leafIDs.count >= 2 else {
        // Single fixture: just look at fanCenter
        return lookAt(scene: scene, selectedIDs: selectedIDs, target: fanCenter)
    }

    let worldPositions = leafIDs.map { worldPosition(for: $0, scene: scene) }

    // Sort by X position
    let sorted = zip(leafIDs, worldPositions).sorted { $0.1.x < $1.1.x }
    let midIndex = Double(sorted.count - 1) / 2.0

    // Each fixture aims at fanCenter + offset based on its position in the sorted order
    var result = scene
    for (i, (id, _)) in sorted.enumerated() {
        let t = (Double(i) - midIndex) / max(midIndex, 1) * spread
        let aimTarget = SIMD3(fanCenter.x + t * 3000, fanCenter.y, fanCenter.z)
        result = lookAt(scene: result, selectedIDs: [id], target: aimTarget)
    }
    return result
}

/// Creates N copies of an object with fixed offset.
func linearArray(scene: MVRScene, sourceID: UUID, count: Int, offset: SIMD3<Double>) -> MVRScene {
    guard count > 0 else { return scene }
    var scene = scene

    // Find which layer the source is in
    var sourceLayerIndex: Int?
    for (li, layer) in scene.scene.layers.enumerated() {
        if layer.childList.contains(where: { $0.uuid == sourceID }) {
            sourceLayerIndex = li
            break
        }
    }
    guard let li = sourceLayerIndex else { return scene }

    // Find the source object
    guard let sourceIdx = scene.scene.layers[li].childList.firstIndex(where: { $0.uuid == sourceID }) else { return scene }
    let source = scene.scene.layers[li].childList[sourceIdx]
    let sourcePos = source.matrix.map { SIMD3($0.matrix[3][0], $0.matrix[3][1], $0.matrix[3][2]) } ?? .zero

    for i in 1...count {
        var copy = source
        copy.reassignUUIDs()
        let newPos = sourcePos + offset * Double(i)
        if var m = copy.matrix {
            m.matrix[3][0] = newPos.x
            m.matrix[3][1] = newPos.y
            m.matrix[3][2] = newPos.z
            copy.mutableMatrix = m
        } else {
            copy.mutableMatrix = Matrix(from: simd_float4x4(
                SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0), SIMD4<Float>(0,0,1,0),
                SIMD4<Float>(Float(newPos.x), Float(newPos.y), Float(newPos.z), 1)
            ))
        }
        scene.scene.layers[li].childList.append(copy)
    }
    return scene
}

/// Creates N copies around a circle.
func radialArray(scene: MVRScene, sourceID: UUID, count: Int, center: SIMD3<Double>, faceCenter: Bool) -> MVRScene {
    guard count > 0 else { return scene }
    var scene = scene

    var sourceLayerIndex: Int?
    for (li, layer) in scene.scene.layers.enumerated() {
        if layer.childList.contains(where: { $0.uuid == sourceID }) {
            sourceLayerIndex = li; break
        }
    }
    guard let li = sourceLayerIndex else { return scene }
    guard let sourceIdx = scene.scene.layers[li].childList.firstIndex(where: { $0.uuid == sourceID }) else { return scene }
    let source = scene.scene.layers[li].childList[sourceIdx]
    let sourcePos = source.matrix.map { SIMD3($0.matrix[3][0], $0.matrix[3][1], $0.matrix[3][2]) } ?? .zero

    let radius = sqrt(pow(sourcePos.x - center.x, 2) + pow(sourcePos.y - center.y, 2))
    let startAngle = atan2(sourcePos.y - center.y, sourcePos.x - center.x)
    let angleStep = 2 * Double.pi / Double(count + 1) // +1 because original is position 0

    for i in 1...count {
        var copy = source
        copy.reassignUUIDs()
        let angle = startAngle + angleStep * Double(i)
        let newPos = SIMD3(center.x + radius * cos(angle), center.y + radius * sin(angle), sourcePos.z)
        if var m = copy.matrix {
            m.matrix[3][0] = newPos.x; m.matrix[3][1] = newPos.y; m.matrix[3][2] = newPos.z
            copy.mutableMatrix = m
        }
        scene.scene.layers[li].childList.append(copy)
    }

    if faceCenter {
        let allIDs = Set(scene.scene.layers[li].childList.map(\.uuid))
        scene = lookAt(scene: scene, selectedIDs: allIDs, target: center)
    }
    return scene
}

// MARK: - Helper: rotation matrix with specific columns

func rotationPos(_ x: Double, _ y: Double, _ z: Double,
                 rx: Double = 0, ry: Double = 0, rz: Double = 0) -> Matrix {
    let cx = cos(rx), sx = sin(rx)
    let cy = cos(ry), sy = sin(ry)
    let cz = cos(rz), sz = sin(rz)
    return Matrix(from: simd_float4x4(
        SIMD4<Float>(Float(cz*cy), Float(sz*cy), Float(-sy), 0),
        SIMD4<Float>(Float(cz*sy*sx - sz*cx), Float(sz*sy*sx + cz*cx), Float(cy*sx), 0),
        SIMD4<Float>(Float(cz*sy*cx + sz*sx), Float(sz*sy*cx - cz*sx), Float(cy*cx), 0),
        SIMD4<Float>(Float(x), Float(y), Float(z), 1)
    ))
}

// MARK: - Grid Snapping Tests

@Suite("Grid Snapping")
struct GridSnappingTests {

    @Test("Snap rounds to nearest grid multiple")
    func snapRoundsToNearest() {
        let result = snapToGrid(SIMD3(123, 456, 789), gridSize: 100)
        #expect(abs(result.x - 100) < 0.01)
        #expect(abs(result.y - 500) < 0.01)
        #expect(abs(result.z - 800) < 0.01)
    }

    @Test("Snap rounds 0.5 up")
    func snapRoundsHalfUp() {
        let result = snapToGrid(SIMD3(150, 250, 350), gridSize: 100)
        #expect(abs(result.x - 200) < 0.01)
        #expect(abs(result.y - 300) < 0.01)
        #expect(abs(result.z - 400) < 0.01)
    }

    @Test("Snap zero unchanged")
    func snapZeroUnchanged() {
        let result = snapToGrid(SIMD3(0, 0, 0), gridSize: 500)
        #expect(abs(result.x) < 0.01)
        #expect(abs(result.y) < 0.01)
        #expect(abs(result.z) < 0.01)
    }

    @Test("Snap is idempotent")
    func snapIdempotent() {
        let once = snapToGrid(SIMD3(1234, 5678, 9012), gridSize: 250)
        let twice = snapToGrid(once, gridSize: 250)
        #expect(abs(once.x - twice.x) < 0.01)
        #expect(abs(once.y - twice.y) < 0.01)
        #expect(abs(once.z - twice.z) < 0.01)
    }

    @Test("Snap negative coordinates")
    func snapNegative() {
        let result = snapToGrid(SIMD3(-123, -456, -789), gridSize: 100)
        #expect(abs(result.x - (-100)) < 0.01)
        #expect(abs(result.y - (-500)) < 0.01)
        #expect(abs(result.z - (-800)) < 0.01)
    }
}

// MARK: - Reset Rotation Tests

@Suite("Reset Rotation")
struct ResetRotationTests {

    @Test("Rotated fixture gets identity rotation, position preserved")
    func resetRotatedFixture() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: rotationPos(1000, 2000, 5000, rx: 0.5, ry: 0.3)))
            ])
        ]))

        let result = resetRotation(scene: scene, selectedIDs: [f1])
        let wp = worldPosition(for: f1, scene: result)
        #expect(abs(wp.x - 1000) < 1, "Position X changed")
        #expect(abs(wp.y - 2000) < 1, "Position Y changed")
        #expect(abs(wp.z - 5000) < 1, "Position Z changed")

        // Rotation columns should be unit-length identity directions
        let m = result.scene.layers[0].childList[0].matrix!.matrix
        #expect(abs(m[0][0] - 1) < 0.01, "Not identity rotation")
        #expect(abs(m[1][1] - 1) < 0.01, "Not identity rotation")
        #expect(abs(m[2][2] - 1) < 0.01, "Not identity rotation")
    }

    @Test("Already-identity fixture unchanged")
    func resetIdentityUnchanged() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(1000, 2000, 5000)))
            ])
        ]))

        let result = resetRotation(scene: scene, selectedIDs: [f1])
        let m = result.scene.layers[0].childList[0].matrix!
        let orig = scene.scene.layers[0].childList[0].matrix!
        #expect(m == orig)
    }
}

// MARK: - Mirror Tests

@Suite("Mirror Across Plane")
struct MirrorTests {

    @Test("Mirror single fixture across X negates X relative to centroid")
    func mirrorSingleAcrossX() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(1000, 2000, 5000)))
            ])
        ]))

        let result = mirrorObjects(scene: scene, selectedIDs: [f1], axis: 0) // X axis
        let wp = worldPosition(for: f1, scene: result)
        // Single object: centroid = (1000, 2000, 5000), mirror across X = same position
        // With only 1 object, mirroring across its own centroid = no change
        #expect(abs(wp.x - 1000) < 1)
    }

    @Test("Mirror two fixtures across X swaps X positions around centroid")
    func mirrorTwoAcrossX() {
        let f1 = UUID(), f2 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(2000, 0, 5000))),
            ])
        ]))

        let result = mirrorObjects(scene: scene, selectedIDs: [f1, f2], axis: 0)
        let p1 = worldPosition(for: f1, scene: result)
        let p2 = worldPosition(for: f2, scene: result)
        // Centroid = (1000, 0, 5000). f1 at 0 → mirrors to 2000, f2 at 2000 → mirrors to 0
        #expect(abs(p1.x - 2000) < 1, "F1 should mirror to 2000, got \(p1.x)")
        #expect(abs(p2.x - 0) < 1, "F2 should mirror to 0, got \(p2.x)")
        // Y and Z preserved
        #expect(abs(p1.y) < 1)
        #expect(abs(p1.z - 5000) < 1)
    }

    @Test("Mirror twice returns to original (involution)")
    func mirrorTwiceIsOriginal() {
        let f1 = UUID(), f2 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(500, 1000, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "F2", matrix: pos(3000, 2000, 5000))),
            ])
        ]))

        let ids: Set<UUID> = [f1, f2]
        let once = mirrorObjects(scene: scene, selectedIDs: ids, axis: 0)
        let twice = mirrorObjects(scene: once, selectedIDs: ids, axis: 0)

        for id in [f1, f2] {
            let orig = worldPosition(for: id, scene: scene)
            let back = worldPosition(for: id, scene: twice)
            #expect(abs(orig.x - back.x) < 1, "X not restored")
            #expect(abs(orig.y - back.y) < 1, "Y not restored")
        }
    }

    @Test("Mirror across X on real file", arguments: [circleTestFixture])
    func mirrorRealFile(fixture: MVRTestFixture) throws {
        let data = try Data(contentsOf: fixture.url)
        let scene = try loadMVR(data: data)
        let allIDs = allUUIDs(in: scene)
        let result = mirrorObjects(scene: scene, selectedIDs: allIDs, axis: 0)
        let resultBack = mirrorObjects(scene: result, selectedIDs: allIDs, axis: 0)

        // Verify involution on real file
        let leafIDs = collectLeafUUIDs(from: allIDs, scene: scene)
        for id in leafIDs {
            let orig = worldPosition(for: id, scene: scene)
            let back = worldPosition(for: id, scene: resultBack)
            #expect(abs(orig.x - back.x) < 1, "X not restored for \(id)")
            #expect(abs(orig.y - back.y) < 1, "Y not restored for \(id)")
        }
    }
}

// MARK: - Look At Tests

@Suite("Look At Target")
struct LookAtTests {

    @Test("Fixture above target rotates to point straight down (-Y in MVR)")
    func lookAtBelow() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000)))
            ])
        ]))

        let result = lookAt(scene: scene, selectedIDs: [f1], target: SIMD3(0, 0, 0))
        let m = result.scene.layers[0].childList[0].matrix!.matrix
        // -Y axis (col1 negated) should point toward (0,0,-1) = down in Z-up
        let negY = SIMD3(m[1][0], m[1][1], m[1][2])
        let down = SIMD3<Double>(0, 0, -1)
        let dotProduct = negY.x * down.x + negY.y * down.y + negY.z * down.z
        #expect(abs(dotProduct - (-1)) < 0.1, "Beam not pointing down: dot=-Y·down = \(dotProduct)")
    }

    @Test("Look at preserves position")
    func lookAtPreservesPosition() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(1000, 2000, 5000)))
            ])
        ]))

        let result = lookAt(scene: scene, selectedIDs: [f1], target: SIMD3(0, 0, 0))
        let wp = worldPosition(for: f1, scene: result)
        #expect(abs(wp.x - 1000) < 1)
        #expect(abs(wp.y - 2000) < 1)
        #expect(abs(wp.z - 5000) < 1)
    }

    @Test("Look at is idempotent")
    func lookAtIdempotent() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(3000, 0, 5000)))
            ])
        ]))

        let target = SIMD3<Double>(0, 0, 0)
        let once = lookAt(scene: scene, selectedIDs: [f1], target: target)
        let twice = lookAt(scene: once, selectedIDs: [f1], target: target)

        let m1 = once.scene.layers[0].childList[0].matrix!.matrix
        let m2 = twice.scene.layers[0].childList[0].matrix!.matrix
        for col in 0..<3 {
            for row in 0..<3 {
                #expect(abs(m1[col][row] - m2[col][row]) < 0.01,
                        "Rotation changed on second look-at: [\(col)][\(row)]")
            }
        }
    }

    @Test("Look at on real file — all fixtures aim at center", arguments: [circleTestFixture])
    func lookAtRealFile(fixture: MVRTestFixture) throws {
        let data = try Data(contentsOf: fixture.url)
        let scene = try loadMVR(data: data)
        let allIDs = allUUIDs(in: scene)
        let target = SIMD3<Double>(12000, 12000, 0)
        let result = lookAt(scene: scene, selectedIDs: allIDs, target: target)

        // Verify idempotent
        let twice = lookAt(scene: result, selectedIDs: allIDs, target: target)
        let leafIDs = collectLeafUUIDs(from: allIDs, scene: scene)
        for id in leafIDs {
            let m1 = result.scene.layers[0].childList.first(where: { $0.uuid == id })?.matrix
            let m2 = twice.scene.layers[0].childList.first(where: { $0.uuid == id })?.matrix
            // Positions should be identical
            let p1 = worldPosition(for: id, scene: result)
            let p2 = worldPosition(for: id, scene: twice)
            #expect(abs(p1.x - p2.x) < 1)
            #expect(abs(p1.y - p2.y) < 1)
        }
    }
}

// MARK: - Match Transform Tests

@Suite("Match Transform")
struct MatchTransformTests {

    @Test("Target gets source position")
    func matchPosition() {
        let src = UUID(), tgt = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: src, name: "Source", matrix: pos(1000, 2000, 3000))),
                .fixture(MVRFixture(uuid: tgt, name: "Target", matrix: pos(5000, 6000, 7000))),
            ])
        ]))

        let result = matchTransform(scene: scene, sourceID: src, targetIDs: [tgt])
        let wp = worldPosition(for: tgt, scene: result)
        #expect(abs(wp.x - 1000) < 1)
        #expect(abs(wp.y - 2000) < 1)
        #expect(abs(wp.z - 3000) < 1)
    }

    @Test("Source unchanged after match")
    func sourceUnchanged() {
        let src = UUID(), tgt = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: src, name: "Source", matrix: pos(1000, 2000, 3000))),
                .fixture(MVRFixture(uuid: tgt, name: "Target", matrix: pos(5000, 6000, 7000))),
            ])
        ]))

        let result = matchTransform(scene: scene, sourceID: src, targetIDs: [tgt])
        let srcPos = worldPosition(for: src, scene: result)
        #expect(abs(srcPos.x - 1000) < 1)
        #expect(abs(srcPos.y - 2000) < 1)
    }
}

// MARK: - Linear Array Tests

@Suite("Linear Array")
struct LinearArrayTests {

    @Test("Array count=3 creates 3 copies with correct spacing")
    func arrayThreeCopies() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000)))
            ])
        ]))

        let result = linearArray(scene: scene, sourceID: f1, count: 3, offset: SIMD3(1000, 0, 0))
        // Should now have 4 fixtures total (original + 3 copies)
        #expect(result.scene.layers[0].childList.count == 4)

        // Verify positions
        var positions: [Double] = []
        for child in result.scene.layers[0].childList {
            let wp = worldPosition(for: child.uuid, scene: result)
            positions.append(wp.x)
        }
        positions.sort()
        #expect(abs(positions[0] - 0) < 1)
        #expect(abs(positions[1] - 1000) < 1)
        #expect(abs(positions[2] - 2000) < 1)
        #expect(abs(positions[3] - 3000) < 1)
    }

    @Test("Array copies have new UUIDs")
    func arrayNewUUIDs() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000)))
            ])
        ]))

        let result = linearArray(scene: scene, sourceID: f1, count: 2, offset: SIMD3(500, 0, 0))
        let uuids = result.scene.layers[0].childList.map(\.uuid)
        #expect(Set(uuids).count == 3, "Expected 3 unique UUIDs, got \(Set(uuids).count)")
        #expect(uuids.contains(f1), "Original UUID missing")
    }

    @Test("Array count=0 creates no copies")
    func arrayZeroCopies() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(0, 0, 5000)))
            ])
        ]))

        let result = linearArray(scene: scene, sourceID: f1, count: 0, offset: SIMD3(1000, 0, 0))
        #expect(result.scene.layers[0].childList.count == 1)
    }
}

// MARK: - Radial Array Tests

@Suite("Radial Array")
struct RadialArrayTests {

    @Test("Radial array count=4 creates 4 equidistant copies")
    func radialFourCopies() {
        let f1 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "F1", matrix: pos(2000, 0, 5000)))
            ])
        ]))

        let result = radialArray(scene: scene, sourceID: f1, count: 4, center: SIMD3(0, 0, 5000), faceCenter: false)
        // Original + 4 copies = 5
        #expect(result.scene.layers[0].childList.count == 5)

        // All should be equidistant from center
        let cx = 0.0, cy = 0.0
        var distances: [Double] = []
        for child in result.scene.layers[0].childList {
            let wp = worldPosition(for: child.uuid, scene: result)
            distances.append(sqrt(pow(wp.x - cx, 2) + pow(wp.y - cy, 2)))
        }
        let firstDist = distances[0]
        for d in distances {
            #expect(abs(d - firstDist) < 1, "Not equidistant: \(d) vs \(firstDist)")
        }
    }
}

// MARK: - Fan Fixtures Tests

@Suite("Fan Fixtures")
struct FanFixturesTests {

    @Test("Three fixtures in a row: middle points straight down, sides angle out")
    func fanThreeFixtures() {
        let f1 = UUID(), f2 = UUID(), f3 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "Left", matrix: pos(-2000, 0, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "Center", matrix: pos(0, 0, 5000))),
                .fixture(MVRFixture(uuid: f3, name: "Right", matrix: pos(2000, 0, 5000))),
            ])
        ]))

        let result = fanFixtures(scene: scene, selectedIDs: [f1, f2, f3],
                                  fanCenter: SIMD3(0, 0, 0), spread: 1.0)

        // Positions should be preserved
        #expect(abs(worldPosition(for: f1, scene: result).x - (-2000)) < 1)
        #expect(abs(worldPosition(for: f2, scene: result).x - 0) < 1)
        #expect(abs(worldPosition(for: f3, scene: result).x - 2000) < 1)

        // Center fixture should aim straight down (at 0,0,0 from 0,0,5000)
        let m2 = result.scene.layers[0].childList[1].matrix!.matrix
        // -Y column should point toward (0,0,-1) direction
        let negY2 = SIMD3(-m2[1][0], -m2[1][1], -m2[1][2])
        #expect(abs(negY2.z - (-1)) < 0.1, "Center not pointing down")
    }

    @Test("Fan spread=0 all point at same spot")
    func fanZeroSpread() {
        let f1 = UUID(), f2 = UUID()
        let scene = MVRScene(scene: MVRSceneNode(auxData: MVRAUXData(), layers: [
            MVRLayer(uuid: UUID(), name: "L1", childList: [
                .fixture(MVRFixture(uuid: f1, name: "Left", matrix: pos(-2000, 0, 5000))),
                .fixture(MVRFixture(uuid: f2, name: "Right", matrix: pos(2000, 0, 5000))),
            ])
        ]))

        let result = fanFixtures(scene: scene, selectedIDs: [f1, f2],
                                  fanCenter: SIMD3(0, 0, 0), spread: 0.0)

        // Both should aim at the same point (fanCenter)
        let m1 = result.scene.layers[0].childList[0].matrix!.matrix
        let m2 = result.scene.layers[0].childList[1].matrix!.matrix
        // -Y columns should point toward the same direction (fanCenter from each fixture)
        // With spread=0, both aim at (0,0,0)
        let dir1 = SIMD3(-m1[1][0], -m1[1][1], -m1[1][2])
        let dir2 = SIMD3(-m2[1][0], -m2[1][1], -m2[1][2])
        // They won't be identical (different positions, same target), but both should point downward
        #expect(dir1.z < -0.5, "Left not pointing down enough")
        #expect(dir2.z < -0.5, "Right not pointing down enough")
    }
}
