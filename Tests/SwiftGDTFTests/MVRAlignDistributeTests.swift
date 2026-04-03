import Testing
import Foundation
import simd
@testable import SwiftGDTF

// MARK: - Align/Distribute Algorithm Tests
//
// These test the pure algorithmic functions that the GDTF Lab app's
// MVRArrangeCommands.swift builds on. We replicate the algorithms here
// to keep the tests in the SwiftGDTF package (which has the MVR test fixtures).

// MARK: - Algorithm Reimplementation (for testing)

enum TestAxis: String, CaseIterable {
    case x, y, z
    var index: Int {
        switch self { case .x: 0; case .y: 1; case .z: 2 }
    }
}

enum TestAnchor: String, CaseIterable {
    case min, center, max
}

extension TestAxis: CustomTestStringConvertible {
    var testDescription: String { rawValue }
}

extension TestAnchor: CustomTestStringConvertible {
    var testDescription: String { rawValue }
}

extension MVRChildObject {
    var testPosition: SIMD3<Double> {
        guard let m = matrix else { return .zero }
        return SIMD3(m.matrix[3][0], m.matrix[3][1], m.matrix[3][2])
    }

    mutating func setTestPosition(_ pos: SIMD3<Double>) {
        mutableMatrix = Matrix(from: simd_float4x4(
            SIMD4<Float>(1,0,0,0), SIMD4<Float>(0,1,0,0), SIMD4<Float>(0,0,1,0),
            SIMD4<Float>(Float(pos.x), Float(pos.y), Float(pos.z), 1)
        ))
    }
}

func testAlign(_ objects: [MVRChildObject], axis: TestAxis, anchor: TestAnchor) -> [MVRChildObject] {
    guard objects.count >= 2 else { return objects }
    let values = objects.map { $0.testPosition[axis.index] }
    let target: Double
    switch anchor {
    case .min: target = values.min()!
    case .max: target = values.max()!
    case .center: target = (values.min()! + values.max()!) / 2
    }
    return objects.map { obj in
        var obj = obj
        var pos = obj.testPosition
        pos[axis.index] = target
        obj.setTestPosition(pos)
        return obj
    }
}

func testDistribute(_ objects: [MVRChildObject], axis: TestAxis) -> [MVRChildObject] {
    guard objects.count >= 3 else { return objects }
    let sorted = objects.sorted { $0.testPosition[axis.index] < $1.testPosition[axis.index] }
    let minVal = sorted.first!.testPosition[axis.index]
    let maxVal = sorted.last!.testPosition[axis.index]
    let step = (maxVal - minVal) / Double(sorted.count - 1)
    var newPositions: [UUID: SIMD3<Double>] = [:]
    for (i, obj) in sorted.enumerated() {
        var pos = obj.testPosition
        pos[axis.index] = minVal + step * Double(i)
        newPositions[obj.uuid] = pos
    }
    return objects.map { obj in
        guard let newPos = newPositions[obj.uuid] else { return obj }
        var obj = obj
        obj.setTestPosition(newPos)
        return obj
    }
}

// MARK: - Test Helpers

func makeFixtureAt(x: Double, y: Double, z: Double, name: String = "") -> MVRChildObject {
    var f = MVRChildObject.fixture(MVRFixture(uuid: UUID(), name: name))
    f.setTestPosition(SIMD3(x, y, z))
    return f
}

// MARK: - Align Tests

@Suite("MVR Align")
struct MVRAlignTests {

    @Test("Align min sets all to minimum value on axis",
          arguments: TestAxis.allCases)
    func alignMinSetsToMinimum(axis: TestAxis) {
        let objects = [
            makeFixtureAt(x: 100, y: 200, z: 300),
            makeFixtureAt(x: 400, y: 500, z: 600),
            makeFixtureAt(x: 700, y: 800, z: 900),
        ]
        let result = testAlign(objects, axis: axis, anchor: .min)
        let values = result.map { $0.testPosition[axis.index] }
        let expected: Double = switch axis { case .x: 100; case .y: 200; case .z: 300 }
        for v in values {
            #expect(abs(v - expected) < 0.01)
        }
    }

    @Test("Align max sets all to maximum value on axis",
          arguments: TestAxis.allCases)
    func alignMaxSetsToMaximum(axis: TestAxis) {
        let objects = [
            makeFixtureAt(x: 100, y: 200, z: 300),
            makeFixtureAt(x: 400, y: 500, z: 600),
            makeFixtureAt(x: 700, y: 800, z: 900),
        ]
        let result = testAlign(objects, axis: axis, anchor: .max)
        let values = result.map { $0.testPosition[axis.index] }
        let expected: Double = switch axis { case .x: 700; case .y: 800; case .z: 900 }
        for v in values {
            #expect(abs(v - expected) < 0.01)
        }
    }

    @Test("Align center sets all to midpoint",
          arguments: TestAxis.allCases)
    func alignCenterSetsMidpoint(axis: TestAxis) {
        let objects = [
            makeFixtureAt(x: 100, y: 200, z: 300),
            makeFixtureAt(x: 700, y: 800, z: 900),
        ]
        let result = testAlign(objects, axis: axis, anchor: .center)
        let values = result.map { $0.testPosition[axis.index] }
        let expected: Double = switch axis { case .x: 400; case .y: 500; case .z: 600 }
        for v in values {
            #expect(abs(v - expected) < 0.01)
        }
    }

    @Test("Align preserves other axes")
    func alignPreservesOtherAxes() {
        let objects = [
            makeFixtureAt(x: 100, y: 200, z: 300),
            makeFixtureAt(x: 400, y: 500, z: 600),
        ]
        let result = testAlign(objects, axis: .x, anchor: .min)
        // Y and Z should be unchanged
        #expect(abs(result[0].testPosition.y - 200) < 0.01)
        #expect(abs(result[0].testPosition.z - 300) < 0.01)
        #expect(abs(result[1].testPosition.y - 500) < 0.01)
        #expect(abs(result[1].testPosition.z - 600) < 0.01)
    }

    @Test("Align single object returns unchanged")
    func alignSingleObjectUnchanged() {
        let objects = [makeFixtureAt(x: 100, y: 200, z: 300)]
        let result = testAlign(objects, axis: .x, anchor: .min)
        #expect(result.count == 1)
        #expect(abs(result[0].testPosition.x - 100) < 0.01)
    }
}

// MARK: - Distribute Tests

@Suite("MVR Distribute")
struct MVRDistributeTests {

    @Test("Distribute evenly spaces objects",
          arguments: TestAxis.allCases)
    func distributeEvenSpacing(axis: TestAxis) {
        let objects = [
            makeFixtureAt(x: 0, y: 0, z: 0),
            makeFixtureAt(x: 600, y: 600, z: 600),  // will move
            makeFixtureAt(x: 1000, y: 1000, z: 1000),
        ]
        let result = testDistribute(objects, axis: axis)
        let values = result.sorted { $0.testPosition[axis.index] < $1.testPosition[axis.index] }
            .map { $0.testPosition[axis.index] }
        #expect(abs(values[0] - 0) < 0.01)
        #expect(abs(values[1] - 500) < 0.01) // evenly spaced
        #expect(abs(values[2] - 1000) < 0.01)
    }

    @Test("Distribute preserves endpoints")
    func distributePreservesEndpoints() {
        let objects = [
            makeFixtureAt(x: 0, y: 0, z: 0),
            makeFixtureAt(x: 100, y: 0, z: 0),
            makeFixtureAt(x: 1000, y: 0, z: 0),
        ]
        let result = testDistribute(objects, axis: .x)
        let sorted = result.sorted { $0.testPosition.x < $1.testPosition.x }
        #expect(abs(sorted.first!.testPosition.x - 0) < 0.01)
        #expect(abs(sorted.last!.testPosition.x - 1000) < 0.01)
    }

    @Test("Distribute 10 objects evenly")
    func distributeTenObjects() {
        var objects: [MVRChildObject] = []
        for i in 0..<10 {
            objects.append(makeFixtureAt(x: Double(i * i * 100), y: 0, z: 0)) // non-linear spacing
        }
        let result = testDistribute(objects, axis: .x)
        let sorted = result.sorted { $0.testPosition.x < $1.testPosition.x }
        let step = (sorted.last!.testPosition.x - sorted.first!.testPosition.x) / 9.0
        for i in 0..<10 {
            let expected = sorted.first!.testPosition.x + step * Double(i)
            #expect(abs(sorted[i].testPosition.x - expected) < 0.01,
                    "Object \(i): expected \(expected), got \(sorted[i].testPosition.x)")
        }
    }

    @Test("Distribute two objects returns unchanged")
    func distributeTwoObjectsUnchanged() {
        let objects = [
            makeFixtureAt(x: 100, y: 0, z: 0),
            makeFixtureAt(x: 500, y: 0, z: 0),
        ]
        let result = testDistribute(objects, axis: .x)
        #expect(result.count == 2)
        // Order preserved, positions unchanged
        #expect(abs(result[0].testPosition.x - 100) < 0.01)
        #expect(abs(result[1].testPosition.x - 500) < 0.01)
    }

    @Test("Distribute preserves other axes")
    func distributePreservesOtherAxes() {
        let objects = [
            makeFixtureAt(x: 0, y: 111, z: 222),
            makeFixtureAt(x: 600, y: 333, z: 444),
            makeFixtureAt(x: 1000, y: 555, z: 666),
        ]
        let result = testDistribute(objects, axis: .x)
        // Y and Z should be untouched
        for (orig, new) in zip(objects, result) {
            #expect(abs(new.testPosition.y - orig.testPosition.y) < 0.01)
            #expect(abs(new.testPosition.z - orig.testPosition.z) < 0.01)
        }
    }

    @Test("Distribute already-even objects is no-op")
    func distributeAlreadyEvenIsNoOp() {
        let objects = [
            makeFixtureAt(x: 0, y: 0, z: 0),
            makeFixtureAt(x: 500, y: 0, z: 0),
            makeFixtureAt(x: 1000, y: 0, z: 0),
        ]
        let result = testDistribute(objects, axis: .x)
        for (orig, new) in zip(objects, result) {
            #expect(abs(new.testPosition.x - orig.testPosition.x) < 0.01)
        }
    }
}
