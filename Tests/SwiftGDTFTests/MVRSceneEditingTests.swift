import Testing
import Foundation
import simd
@testable import SwiftGDTF

// MARK: - Test Scene Builder

/// Creates a test scene with known structure for mutation testing.
///
/// Structure:
/// ```
/// Layer 1 "Front Truss"
///   ├── Fixture 1 "Spot Left"      (position 1000,0,5000)
///   ├── Fixture 2 "Spot Right"     (position 2000,0,5000)
///   └── Group A "Wash Group"
///       └── Fixture 3 "Wash Center"
/// Layer 2 "Back Truss"
///   └── Truss 1 "Back Bar"
/// ```
func makeEditableTestScene() -> (scene: MVRScene, uuids: TestUUIDs) {
    let uuids = TestUUIDs()

    let fixture1 = MVRChildObject.fixture(MVRFixture(
        uuid: uuids.fixture1, name: "Spot Left",
        matrix: Matrix(from: simd_float4x4(
            SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0),
            SIMD4<Float>(0,0,1,0), SIMD4<Float>(1000,0,5000,1)
        ))
    ))
    let fixture2 = MVRChildObject.fixture(MVRFixture(
        uuid: uuids.fixture2, name: "Spot Right",
        matrix: Matrix(from: simd_float4x4(
            SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0),
            SIMD4<Float>(0,0,1,0), SIMD4<Float>(2000,0,5000,1)
        ))
    ))
    let fixture3 = MVRChildObject.fixture(MVRFixture(
        uuid: uuids.fixture3, name: "Wash Center"
    ))
    let groupA = MVRChildObject.groupObject(MVRGroupObject(
        uuid: uuids.groupA, name: "Wash Group",
        matrix: Matrix(from: simd_float4x4(
            SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0),
            SIMD4<Float>(0,0,1,0), SIMD4<Float>(500,0,0,1)
        )),
        childList: [fixture3]
    ))
    let truss1 = MVRChildObject.truss(MVRTruss(uuid: uuids.truss1, name: "Back Bar"))

    let layer1 = MVRLayer(uuid: uuids.layer1, name: "Front Truss",
                          childList: [fixture1, fixture2, groupA])
    let layer2 = MVRLayer(uuid: uuids.layer2, name: "Back Truss",
                          childList: [truss1])

    let scene = MVRScene(scene: MVRSceneNode(
        auxData: MVRAUXData(),
        layers: [layer1, layer2]
    ))
    return (scene, uuids)
}

struct TestUUIDs {
    let layer1 = UUID()
    let layer2 = UUID()
    let fixture1 = UUID()
    let fixture2 = UUID()
    let fixture3 = UUID()
    let groupA = UUID()
    let truss1 = UUID()
}

// MARK: - Helper: Object Index

/// Builds a flat UUID→object index from a scene.
func buildIndex(from scene: MVRScene) -> [UUID: MVRChildObject] {
    var index: [UUID: MVRChildObject] = [:]
    func walk(_ objects: [MVRChildObject]) {
        for obj in objects {
            index[obj.uuid] = obj
            walk(obj.childList)
        }
    }
    for layer in scene.scene.layers { walk(layer.childList) }
    return index
}

/// Finds and mutates an object in the scene by UUID.
@discardableResult
func mutateObject(id: UUID, in scene: inout MVRScene, transform: (inout MVRChildObject) -> Void) -> Bool {
    for li in scene.scene.layers.indices {
        if mutateInChildren(id: id, in: &scene.scene.layers[li].childList, transform: transform) {
            return true
        }
    }
    return false
}

private func mutateInChildren(id: UUID, in children: inout [MVRChildObject], transform: (inout MVRChildObject) -> Void) -> Bool {
    for i in children.indices {
        if children[i].uuid == id {
            transform(&children[i])
            return true
        }
        var childList = children[i].mutableChildList
        if mutateInChildren(id: id, in: &childList, transform: transform) {
            children[i].mutableChildList = childList
            return true
        }
    }
    return false
}

/// Removes objects by IDs from the scene tree.
func removeObjects(ids: Set<UUID>, from scene: inout MVRScene) {
    for li in scene.scene.layers.indices {
        scene.scene.layers[li].childList = removeFromChildren(scene.scene.layers[li].childList, ids: ids)
    }
}

private func removeFromChildren(_ children: [MVRChildObject], ids: Set<UUID>) -> [MVRChildObject] {
    children.compactMap { child in
        if ids.contains(child.uuid) { return nil }
        var child = child
        let filtered = removeFromChildren(child.childList, ids: ids)
        if filtered.count != child.childList.count {
            child.mutableChildList = filtered
        }
        return child
    }
}

/// Groups objects at the same level into a new group.
func groupObjects(ids: Set<UUID>, groupUUID: UUID, name: String, in scene: inout MVRScene) -> Bool {
    for li in scene.scene.layers.indices {
        if groupInChildren(&scene.scene.layers[li].childList, ids: ids, groupUUID: groupUUID, name: name) {
            return true
        }
    }
    return false
}

private func groupInChildren(_ children: inout [MVRChildObject], ids: Set<UUID>, groupUUID: UUID, name: String) -> Bool {
    let matchingIndices = children.indices.filter { ids.contains(children[$0].uuid) }
    if matchingIndices.count == ids.count {
        let grouped = matchingIndices.map { children[$0] }
        let insertAt = matchingIndices.first!
        for i in matchingIndices.reversed() {
            children.remove(at: i)
        }
        let group = MVRChildObject.groupObject(MVRGroupObject(
            uuid: groupUUID, name: name, childList: grouped
        ))
        children.insert(group, at: min(insertAt, children.count))
        return true
    }
    for i in children.indices {
        var childList = children[i].mutableChildList
        if groupInChildren(&childList, ids: ids, groupUUID: groupUUID, name: name) {
            children[i].mutableChildList = childList
            return true
        }
    }
    return false
}

/// Ungroups a group, promoting its children.
func ungroupObject(id: UUID, in scene: inout MVRScene) -> Bool {
    // Find the group first to get its matrix
    let index = buildIndex(from: scene)
    guard case .groupObject(let group) = index[id] else { return false }
    for li in scene.scene.layers.indices {
        if ungroupInChildren(&scene.scene.layers[li].childList, id: id, groupMatrix: group.matrix) {
            return true
        }
    }
    return false
}

private func ungroupInChildren(_ children: inout [MVRChildObject], id: UUID, groupMatrix: Matrix?) -> Bool {
    if let idx = children.firstIndex(where: { $0.uuid == id }) {
        let group = children[idx]
        var promoted = group.childList
        if let gm = groupMatrix {
            for i in promoted.indices {
                if let childMatrix = promoted[i].matrix {
                    let composed = gm.simdMatrix * childMatrix.simdMatrix
                    promoted[i].mutableMatrix = Matrix(from: composed)
                } else {
                    promoted[i].mutableMatrix = gm
                }
            }
        }
        children.remove(at: idx)
        children.insert(contentsOf: promoted, at: idx)
        return true
    }
    for i in children.indices {
        var childList = children[i].mutableChildList
        if ungroupInChildren(&childList, id: id, groupMatrix: groupMatrix) {
            children[i].mutableChildList = childList
            return true
        }
    }
    return false
}

// MARK: - Tests: Object Index

@Suite("MVR Scene Object Index")
struct MVRSceneObjectIndexTests {

    @Test("Index contains all objects in test scene")
    func indexContainsAll() {
        let (scene, _) = makeEditableTestScene()
        let index = buildIndex(from: scene)
        // fixture1, fixture2, fixture3, groupA, truss1 = 5
        #expect(index.count == 5)
    }

    @Test("Index updated after adding object")
    func indexUpdatedAfterAdd() {
        var (scene, _) = makeEditableTestScene()
        let newFixture = MVRChildObject.fixture(MVRFixture(uuid: UUID(), name: "New"))
        scene.scene.layers[0].childList.append(newFixture)
        let index = buildIndex(from: scene)
        #expect(index.count == 6)
    }
}

// MARK: - Tests: Remove

@Suite("MVR Scene Remove Operations")
struct MVRSceneRemoveTests {

    @Test("Remove fixture from layer")
    func removeFixtureFromLayer() {
        var (scene, uuids) = makeEditableTestScene()
        removeObjects(ids: [uuids.fixture1], from: &scene)
        #expect(scene.scene.layers[0].childList.count == 2) // was 3
        #expect(buildIndex(from: scene)[uuids.fixture1] == nil)
    }

    @Test("Remove group removes the group and its children from tree")
    func removeGroupRemovesChildren() {
        var (scene, uuids) = makeEditableTestScene()
        removeObjects(ids: [uuids.groupA], from: &scene)
        let index = buildIndex(from: scene)
        #expect(index[uuids.groupA] == nil)
        #expect(index[uuids.fixture3] == nil)
    }

    @Test("Remove preserves other objects")
    func removePreservesOthers() {
        var (scene, uuids) = makeEditableTestScene()
        removeObjects(ids: [uuids.fixture1], from: &scene)
        let index = buildIndex(from: scene)
        #expect(index[uuids.fixture2] != nil)
        #expect(index[uuids.groupA] != nil)
        #expect(index[uuids.truss1] != nil)
    }

    @Test("Remove nested object from group")
    func removeNestedObject() {
        var (scene, uuids) = makeEditableTestScene()
        removeObjects(ids: [uuids.fixture3], from: &scene)
        let index = buildIndex(from: scene)
        #expect(index[uuids.fixture3] == nil)
        #expect(index[uuids.groupA] != nil) // group still exists, just empty
        let group = index[uuids.groupA]!
        #expect(group.childList.isEmpty)
    }

    @Test("Remove multiple objects at once")
    func removeMultiple() {
        var (scene, uuids) = makeEditableTestScene()
        removeObjects(ids: [uuids.fixture1, uuids.fixture2], from: &scene)
        #expect(scene.scene.layers[0].childList.count == 1) // only groupA remains
    }
}

// MARK: - Tests: Mutate

@Suite("MVR Scene Mutate Operations")
struct MVRSceneMutateTests {

    @Test("Mutate object name by UUID")
    func mutateObjectName() {
        var (scene, uuids) = makeEditableTestScene()
        mutateObject(id: uuids.fixture1, in: &scene) { $0.mutableName = "Renamed" }
        #expect(buildIndex(from: scene)[uuids.fixture1]?.name == "Renamed")
    }

    @Test("Mutate nested object name")
    func mutateNestedObjectName() {
        var (scene, uuids) = makeEditableTestScene()
        mutateObject(id: uuids.fixture3, in: &scene) { $0.mutableName = "Deep Rename" }
        #expect(buildIndex(from: scene)[uuids.fixture3]?.name == "Deep Rename")
    }

    @Test("Mutate object matrix")
    func mutateObjectMatrix() {
        var (scene, uuids) = makeEditableTestScene()
        let newMatrix = Matrix(from: simd_float4x4(
            SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0),
            SIMD4<Float>(0,0,1,0), SIMD4<Float>(9999,0,0,1)
        ))
        mutateObject(id: uuids.fixture1, in: &scene) { $0.mutableMatrix = newMatrix }
        let m = buildIndex(from: scene)[uuids.fixture1]?.matrix
        #expect(m != nil)
        #expect(abs(m!.simdMatrix[3][0] - 9999) < 0.01)
    }
}

// MARK: - Tests: Duplicate

@Suite("MVR Scene Duplicate Operations")
struct MVRSceneDuplicateTests {

    @Test("Duplicate fixture creates copy with new UUID")
    func duplicateFixture() {
        var (scene, uuids) = makeEditableTestScene()
        let initialCount = scene.scene.layers[0].childList.count

        // Manually duplicate
        var copy = scene.scene.layers[0].childList[0]
        copy.reassignUUIDs()
        scene.scene.layers[0].childList.insert(copy, at: 1)

        #expect(scene.scene.layers[0].childList.count == initialCount + 1)
        #expect(scene.scene.layers[0].childList[1].uuid != uuids.fixture1)
        #expect(scene.scene.layers[0].childList[1].name == "Spot Left")
    }

    @Test("Duplicate group copies children with new UUIDs")
    func duplicateGroupCopiesChildren() {
        var (scene, uuids) = makeEditableTestScene()
        var copy = scene.scene.layers[0].childList[2] // groupA
        let mapping = copy.reassignUUIDs()

        #expect(copy.uuid != uuids.groupA)
        #expect(copy.childList.count == 1)
        #expect(copy.childList[0].uuid != uuids.fixture3)
        #expect(mapping.count == 2) // group + 1 child
    }
}

// MARK: - Tests: Group

@Suite("MVR Scene Group Operations")
struct MVRSceneGroupTests {

    @Test("Group two fixtures creates new group")
    func groupTwoFixtures() {
        var (scene, uuids) = makeEditableTestScene()
        let groupUUID = UUID()

        let success = groupObjects(
            ids: [uuids.fixture1, uuids.fixture2],
            groupUUID: groupUUID, name: "New Group",
            in: &scene
        )

        #expect(success)
        // Layer 1: was [f1, f2, groupA], now [newGroup, groupA]
        #expect(scene.scene.layers[0].childList.count == 2)
        let index = buildIndex(from: scene)
        let newGroup = index[groupUUID]!
        #expect(newGroup.childList.count == 2)
        #expect(newGroup.name == "New Group")
    }

    @Test("Group preserves child order")
    func groupPreservesOrder() {
        var (scene, uuids) = makeEditableTestScene()
        let groupUUID = UUID()

        groupObjects(ids: [uuids.fixture1, uuids.fixture2], groupUUID: groupUUID, name: "G", in: &scene)

        let group = buildIndex(from: scene)[groupUUID]!
        #expect(group.childList[0].uuid == uuids.fixture1)
        #expect(group.childList[1].uuid == uuids.fixture2)
    }

    @Test("Ungroup promotes children to parent level")
    func ungroupPromotesChildren() {
        var (scene, uuids) = makeEditableTestScene()
        let initialCount = scene.scene.layers[0].childList.count

        let success = ungroupObject(id: uuids.groupA, in: &scene)

        #expect(success)
        // Was [f1, f2, groupA(f3)], now [f1, f2, f3]
        #expect(scene.scene.layers[0].childList.count == initialCount) // 3→3
        let index = buildIndex(from: scene)
        #expect(index[uuids.groupA] == nil)
        #expect(index[uuids.fixture3] != nil)
    }

    @Test("Ungroup composes group matrix with child matrices")
    func ungroupComposesMatrices() {
        var (scene, uuids) = makeEditableTestScene()
        // groupA has matrix (500,0,0), fixture3 has no matrix
        ungroupObject(id: uuids.groupA, in: &scene)

        let fixture3 = buildIndex(from: scene)[uuids.fixture3]!
        // fixture3 should now have the group's matrix since it had none
        #expect(fixture3.matrix != nil)
        #expect(abs(fixture3.matrix!.simdMatrix[3][0] - 500) < 0.01)
    }

    @Test("Group then ungroup round-trips")
    func groupUngroupRoundTrip() {
        var (scene, uuids) = makeEditableTestScene()
        let originalNames = scene.scene.layers[0].childList.map(\.name)

        // Group f1 and f2
        let groupUUID = UUID()
        groupObjects(ids: [uuids.fixture1, uuids.fixture2], groupUUID: groupUUID, name: "Temp", in: &scene)

        // Ungroup
        ungroupObject(id: groupUUID, in: &scene)

        // Should be back to original structure (names and count)
        let resultNames = scene.scene.layers[0].childList.map(\.name)
        #expect(resultNames == originalNames)
    }
}

// MARK: - Tests: Encode Round-Trip

@Suite("MVR Scene Edit + Encode Round-Trip")
struct MVRSceneEditEncodeTests {

    @Test("Renamed object persists through encode/decode")
    func renamedObjectPersists() throws {
        var (scene, uuids) = makeEditableTestScene()
        mutateObject(id: uuids.fixture1, in: &scene) { $0.mutableName = "Persisted" }

        let data = try encodeMVR(scene: scene)
        let reloaded = try loadMVR(data: data)
        #expect(buildIndex(from: reloaded)[uuids.fixture1]?.name == "Persisted")
    }

    @Test("Added layer persists through encode/decode")
    func addedLayerPersists() throws {
        var (scene, _) = makeEditableTestScene()
        let newUUID = UUID()
        scene.scene.layers.append(MVRLayer(uuid: newUUID, name: "Added Layer"))

        let data = try encodeMVR(scene: scene)
        let reloaded = try loadMVR(data: data)
        #expect(reloaded.scene.layers.count == 3)
        #expect(reloaded.scene.layers.last?.name == "Added Layer")
    }

    @Test("Removed object is absent after encode/decode")
    func removedObjectAbsent() throws {
        var (scene, uuids) = makeEditableTestScene()
        removeObjects(ids: [uuids.fixture1], from: &scene)

        let data = try encodeMVR(scene: scene)
        let reloaded = try loadMVR(data: data)
        #expect(buildIndex(from: reloaded)[uuids.fixture1] == nil)
    }

    @Test("Grouped objects persist through encode/decode")
    func groupedObjectsPersist() throws {
        var (scene, uuids) = makeEditableTestScene()
        let groupUUID = UUID()
        groupObjects(ids: [uuids.fixture1, uuids.fixture2], groupUUID: groupUUID, name: "Saved Group", in: &scene)

        let data = try encodeMVR(scene: scene)
        let reloaded = try loadMVR(data: data)
        let index = buildIndex(from: reloaded)
        let group = index[groupUUID]
        #expect(group != nil)
        #expect(group?.childList.count == 2)
        #expect(group?.name == "Saved Group")
    }

    @Test("All 14 test fixtures survive edit+encode round-trip",
          arguments: allMVRTestFixtures)
    func editRoundTripAllFixtures(fixture: MVRTestFixture) throws {
        let data = try Data(contentsOf: fixture.url)
        var scene = try loadMVR(data: data)
        let originalLayerCount = scene.scene.layers.count

        // Add a new layer and fixture
        let newFixture = MVRChildObject.fixture(MVRFixture(uuid: UUID(), name: "Test Fixture"))
        scene.scene.layers.append(MVRLayer(uuid: UUID(), name: "Test Layer", childList: [newFixture]))

        // Encode and decode
        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        #expect(decoded.scene.layers.count == originalLayerCount + 1)
        #expect(decoded.scene.layers.last?.name == "Test Layer")
        #expect(decoded.scene.layers.last?.childList.count == 1)
    }
}
