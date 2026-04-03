import Testing
import Foundation
import simd
@testable import SwiftGDTF

// MARK: - MVRChildObject Mutation Helper Tests

@Suite("MVRChildObject Mutable Accessors")
struct MVRChildObjectMutationTests {

    // MARK: - Name Mutation

    @Test("mutableName setter works for all 8 kinds",
          arguments: allObjectKinds)
    func mutableNameSetterAllKinds(kind: MVRChildObject.Kind) {
        var obj = makeObject(kind: kind, name: "Original")
        #expect(obj.name == "Original")
        obj.mutableName = "Updated"
        #expect(obj.name == "Updated")
        #expect(obj.kind == kind) // kind preserved
    }

    // MARK: - Matrix Mutation

    @Test("mutableMatrix setter works for all 8 kinds",
          arguments: allObjectKinds)
    func mutableMatrixSetterAllKinds(kind: MVRChildObject.Kind) {
        var obj = makeObject(kind: kind)
        #expect(obj.matrix == nil)

        let testMatrix = Matrix(from: simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(1000, 2000, 3000, 1)
        ))
        obj.mutableMatrix = testMatrix
        #expect(obj.matrix != nil)
        #expect(obj.matrix == testMatrix)

        obj.mutableMatrix = nil
        #expect(obj.matrix == nil)
    }

    // MARK: - ChildList Mutation

    @Test("mutableChildList setter works for all kinds with children",
          arguments: kindsWithChildren)
    func mutableChildListSetterAllKinds(kind: MVRChildObject.Kind) {
        var obj = makeObject(kind: kind)
        #expect(obj.childList.isEmpty)

        let child = MVRChildObject.focusPoint(MVRFocusPoint(uuid: UUID(), name: "FP1"))
        obj.mutableChildList = [child]
        #expect(obj.childList.count == 1)
        #expect(obj.childList[0].name == "FP1")

        obj.mutableChildList = []
        #expect(obj.childList.isEmpty)
    }

    @Test("mutableChildList setter on focusPoint is no-op")
    func focusPointChildListNoOp() {
        var obj = MVRChildObject.focusPoint(MVRFocusPoint(uuid: UUID()))
        obj.mutableChildList = [MVRChildObject.focusPoint(MVRFocusPoint(uuid: UUID()))]
        #expect(obj.childList.isEmpty) // focus points have no children
    }

    // MARK: - UUID Mutation

    @Test("mutableUUID setter works for all 8 kinds",
          arguments: allObjectKinds)
    func mutableUUIDSetterAllKinds(kind: MVRChildObject.Kind) {
        let originalUUID = UUID()
        var obj = makeObject(kind: kind, uuid: originalUUID)
        #expect(obj.uuid == originalUUID)

        let newUUID = UUID()
        obj.mutableUUID = newUUID
        #expect(obj.uuid == newUUID)
        #expect(obj.kind == kind)
    }

    // MARK: - GDTF Spec Mutation

    @Test("mutableGdtfSpec setter works for kinds with GDTF spec",
          arguments: kindsWithGdtfSpec)
    func mutableGdtfSpecSetterAllKinds(kind: MVRChildObject.Kind) {
        var obj = makeObject(kind: kind)
        obj.mutableGdtfSpec = "Robe@MegaPointe.gdtf"
        #expect(obj.gdtfSpec == "Robe@MegaPointe.gdtf")

        obj.mutableGdtfSpec = nil
        #expect(obj.gdtfSpec == nil)
    }

    @Test("mutableGdtfSpec setter on groupObject/focusPoint is no-op")
    func gdtfSpecNoOpOnGroupAndFocusPoint() {
        var group = makeObject(kind: .groupObject)
        group.mutableGdtfSpec = "Test.gdtf"
        #expect(group.gdtfSpec == nil)

        var fp = makeObject(kind: .focusPoint)
        fp.mutableGdtfSpec = "Test.gdtf"
        #expect(fp.gdtfSpec == nil)
    }

    // MARK: - Classing Mutation

    @Test("mutableClassing setter works for all 8 kinds",
          arguments: allObjectKinds)
    func mutableClassingSetterAllKinds(kind: MVRChildObject.Kind) {
        var obj = makeObject(kind: kind)
        #expect(obj.classing == nil)

        let classUUID = UUID()
        obj.mutableClassing = classUUID
        #expect(obj.classing == classUUID)

        obj.mutableClassing = nil
        #expect(obj.classing == nil)
    }

    // MARK: - reassignUUIDs

    @Test("reassignUUIDs assigns new UUID to object")
    func reassignUUIDsSingle() {
        let originalUUID = UUID()
        var obj = makeObject(kind: .fixture, uuid: originalUUID)
        let mapping = obj.reassignUUIDs()
        #expect(obj.uuid != originalUUID)
        #expect(mapping[originalUUID] == obj.uuid)
    }

    @Test("reassignUUIDs recursively updates children")
    func reassignUUIDsRecursive() {
        let parentUUID = UUID()
        let child1UUID = UUID()
        let child2UUID = UUID()
        var parent = MVRChildObject.groupObject(MVRGroupObject(
            uuid: parentUUID,
            name: "Group",
            childList: [
                .fixture(MVRFixture(uuid: child1UUID, name: "F1")),
                .focusPoint(MVRFocusPoint(uuid: child2UUID, name: "FP1")),
            ]
        ))
        let mapping = parent.reassignUUIDs()
        #expect(mapping.count == 3) // parent + 2 children
        #expect(parent.uuid != parentUUID)
        #expect(parent.childList[0].uuid != child1UUID)
        #expect(parent.childList[1].uuid != child2UUID)
        // All new UUIDs are unique
        let newUUIDs = [parent.uuid, parent.childList[0].uuid, parent.childList[1].uuid]
        #expect(Set(newUUIDs).count == 3)
    }
}

// MARK: - Matrix <-> simd_float4x4 Conversion Tests

@Suite("Matrix simd_float4x4 Conversion")
struct MatrixConversionTests {

    @Test("Matrix from simd_float4x4 round-trips through simdMatrix")
    func matrixFloat4x4RoundTrip() {
        let original = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 0.707, -0.707, 0),
            SIMD4<Float>(0, 0.707, 0.707, 0),
            SIMD4<Float>(5000, -3000, 8000, 1)
        )
        let matrix = Matrix(from: original)
        let recovered = matrix.simdMatrix

        for col in 0..<4 {
            for row in 0..<4 {
                #expect(abs(recovered[col][row] - original[col][row]) < 0.001,
                        "Mismatch at [\(col)][\(row)]: \(recovered[col][row]) vs \(original[col][row])")
            }
        }
    }

    @Test("Identity matrix round-trips")
    func identityRoundTrip() {
        let identity = matrix_identity_float4x4
        let matrix = Matrix(from: identity)
        let recovered = matrix.simdMatrix
        for col in 0..<4 {
            for row in 0..<4 {
                let expected: Float = (col == row) ? 1 : 0
                #expect(abs(recovered[col][row] - expected) < 0.0001)
            }
        }
    }

    @Test("Translation matrix preserves position")
    func translationPreserved() {
        let translation = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(1234, 5678, 9012, 1)
        )
        let matrix = Matrix(from: translation)
        let recovered = matrix.simdMatrix
        #expect(abs(recovered[3][0] - 1234) < 0.01)
        #expect(abs(recovered[3][1] - 5678) < 0.01)
        #expect(abs(recovered[3][2] - 9012) < 0.01)
    }
}

// MARK: - Helpers

let allObjectKinds: [MVRChildObject.Kind] = [
    .sceneObject, .groupObject, .focusPoint, .fixture,
    .truss, .support, .videoScreen, .projector
]

/// Kinds that support child lists (all except focusPoint).
let kindsWithChildren: [MVRChildObject.Kind] = [
    .sceneObject, .groupObject, .fixture,
    .truss, .support, .videoScreen, .projector
]

/// Kinds that have gdtfSpec (all except groupObject and focusPoint).
let kindsWithGdtfSpec: [MVRChildObject.Kind] = [
    .sceneObject, .fixture, .truss, .support, .videoScreen, .projector
]

extension MVRChildObject.Kind: CustomTestStringConvertible {
    public var testDescription: String { rawValue }
}

/// Creates a minimal MVRChildObject of the given kind.
func makeObject(kind: MVRChildObject.Kind, name: String = "", uuid: UUID = UUID()) -> MVRChildObject {
    switch kind {
    case .sceneObject: .sceneObject(MVRSceneObject(uuid: uuid, name: name))
    case .groupObject: .groupObject(MVRGroupObject(uuid: uuid, name: name))
    case .focusPoint: .focusPoint(MVRFocusPoint(uuid: uuid, name: name))
    case .fixture: .fixture(MVRFixture(uuid: uuid, name: name))
    case .truss: .truss(MVRTruss(uuid: uuid, name: name))
    case .support: .support(MVRSupport(uuid: uuid, name: name))
    case .videoScreen: .videoScreen(MVRVideoScreen(uuid: uuid, name: name))
    case .projector: .projector(MVRProjector(uuid: uuid, name: name))
    }
}
