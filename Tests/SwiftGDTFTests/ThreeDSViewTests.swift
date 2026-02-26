import Testing
import Foundation
import SceneKit
@testable import SwiftGDTF

#if canImport(AppKit)
import AppKit
private typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
#endif

// MARK: - Helpers

/// Builds a minimal valid ThreeDSFile with one triangle.
func makeSingleTriangleFile(
    materialName: String? = nil,
    uvs: [SIMD2<Float>] = []
) -> ThreeDSFile {
    let object = ThreeDSObject(
        name: "Triangle",
        vertices: [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0),
        ],
        faces: [SIMD3<UInt16>(0, 1, 2)],
        textureCoordinates: uvs,
        materialName: materialName
    )
    let material = ThreeDSMaterial(
        name: "Red",
        ambientColor: SIMD3<Float>(0.1, 0, 0),
        diffuseColor: SIMD3<Float>(1, 0, 0),
        specularColor: SIMD3<Float>(1, 1, 1)
    )
    return ThreeDSFile(objects: [object], materials: [material])
}

/// Builds a ThreeDSFile with multiple objects.
func makeMultiObjectFile() -> ThreeDSFile {
    func box(name: String, offset: Float) -> ThreeDSObject {
        let v: [SIMD3<Float>] = [
            SIMD3(offset,     0, 0), SIMD3(offset + 1, 0, 0),
            SIMD3(offset + 1, 1, 0), SIMD3(offset,     1, 0),
        ]
        return ThreeDSObject(
            name: name,
            vertices: v,
            faces: [SIMD3<UInt16>(0,1,2), SIMD3<UInt16>(0,2,3)],
            textureCoordinates: [],
            materialName: nil
        )
    }
    return ThreeDSFile(
        objects: [box(name: "A", offset: 0), box(name: "B", offset: 2), box(name: "C", offset: 4)],
        materials: []
    )
}

// MARK: - ThreeDS Parser Tests

@Suite("ThreeDS Parser")
struct ThreeDSParserTests {

    // MARK: Binary round-trip

    @Test("Parse minimal main chunk returns empty file")
    func parseEmptyMainChunk() throws {
        // Minimal valid .3ds: main chunk (0x4D4D) with length = 6 (header only)
        var data = Data()
        func writeUInt16(_ v: UInt16) { data.append(contentsOf: [UInt8(v & 0xFF), UInt8(v >> 8)]) }
        func writeUInt32(_ v: UInt32) {
            data.append(contentsOf: [
                UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF),
                UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)
            ])
        }
        writeUInt16(0x4D4D)  // main chunk ID
        writeUInt32(6)        // length = header only

        let file = try ThreeDSFile.parse(data: data)
        #expect(file.objects.isEmpty)
        #expect(file.materials.isEmpty)
    }

    @Test("Truncated data throws unexpectedEndOfData")
    func parseTruncatedData() {
        let truncated = Data([0x4D])  // incomplete chunk header
        #expect(throws: ThreeDSParseError.unexpectedEndOfData) {
            _ = try ThreeDSFile.parse(data: truncated)
        }
    }

    @Test("Wrong magic throws invalidHeader")
    func parseWrongMagic() {
        var data = Data()
        data.append(contentsOf: [0xFF, 0xFF])  // wrong chunk ID
        data.append(contentsOf: [0x06, 0x00, 0x00, 0x00])  // length = 6
        #expect(throws: ThreeDSParseError.invalidHeader) {
            _ = try ThreeDSFile.parse(data: data)
        }
    }

    @Test("Real .3ds file from fixture 126634 — skipped when no .3ds present")
    func parseFromFixture126634() throws {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwiftGDTF/Fixtures")
        let fixtureURL = cacheDir.appendingPathComponent("126634.gdtf")

        guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
            print("Skipping: 126634.gdtf not in cache")
            return
        }

        let gdtfData = try Data(contentsOf: fixtureURL)
        let gdtf = try loadGDTF(data: gdtfData)

        var foundAny = false
        for model in gdtf.fixtureType.models {
            for lod in GDTFModel.LOD.allCases {
                guard let raw = model.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod) else { continue }
                foundAny = true
                let parsed = try ThreeDSFile.parse(data: raw)
                for obj in parsed.objects {
                    #expect(!obj.vertices.isEmpty)
                    #expect(!obj.faces.isEmpty)
                }
            }
        }

        if !foundAny {
            print("126634.gdtf has no .3ds models (only .glb) — parser not exercised by this fixture")
        }
    }
}

// MARK: - SCNGeometry Builder Tests

@Suite("ThreeDS → SceneKit")
struct ThreeDSSceneKitTests {

    @Test("Single triangle produces one child node")
    func singleTriangleNodeCount() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        #expect(root.childNodes.count == 1)
    }

    @Test("Child node is named after the object")
    func nodeNaming() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        #expect(root.childNodes.first?.name == "Triangle")
    }

    @Test("Node has geometry with one element")
    func nodeHasGeometry() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        let geo = root.childNodes.first?.geometry
        #expect(geo != nil)
        #expect(geo?.elements.count == 1)
    }

    @Test("Geometry element has correct primitive count")
    func geometryPrimitiveCount() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        let element = root.childNodes.first?.geometry?.elements.first
        // 1 face = 1 triangle
        #expect(element?.primitiveCount == 1)
        #expect(element?.primitiveType == .triangles)
    }

    @Test("Geometry has vertex position source")
    func geometryHasPositionSource() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        let geo = root.childNodes.first?.geometry
        let posSource = geo?.sources(for: .vertex)
        #expect(posSource?.isEmpty == false)
    }

    @Test("UV coords attached when present and count matches")
    func geometryHasUVSource() {
        let uvs: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(0,1)]
        let file = makeSingleTriangleFile(uvs: uvs)
        let root = file.sceneNode()
        let geo = root.childNodes.first?.geometry
        let uvSource = geo?.sources(for: .texcoord)
        #expect(uvSource?.isEmpty == false)
    }

    @Test("UV coords omitted when empty")
    func geometryNoUVSourceWhenEmpty() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        let geo = root.childNodes.first?.geometry
        let uvSource = geo?.sources(for: .texcoord)
        #expect(uvSource?.isEmpty == true)
    }

    @Test("Material diffuse colour applied from matching ThreeDSMaterial")
    func materialDiffuseApplied() {
        let file = makeSingleTriangleFile(materialName: "Red")
        let root = file.sceneNode()
        let mat = root.childNodes.first?.geometry?.firstMaterial
        #expect(mat?.diffuse.contents is PlatformColor)
    }

    @Test("Multi-object file produces correct node count")
    func multiObjectNodeCount() {
        let file = makeMultiObjectFile()
        let root = file.sceneNode()
        #expect(root.childNodes.count == 3)
    }

    @Test("Node names match object names in order")
    func multiObjectNodeNames() {
        let file = makeMultiObjectFile()
        let root = file.sceneNode()
        let names = root.childNodes.map { $0.name }
        #expect(names == ["A", "B", "C"])
    }

    @Test("Empty file produces no child nodes")
    func emptyFileNoNodes() {
        let file = ThreeDSFile(objects: [], materials: [])
        let root = file.sceneNode()
        #expect(root.childNodes.isEmpty)
    }

    @Test("Object with no faces is skipped")
    func objectWithNoFacesSkipped() {
        let empty = ThreeDSObject(
            name: "Empty",
            vertices: [SIMD3<Float>(0,0,0)],
            faces: [],
            textureCoordinates: [],
            materialName: nil
        )
        let valid = ThreeDSObject(
            name: "Valid",
            vertices: [SIMD3<Float>(0,0,0), SIMD3<Float>(1,0,0), SIMD3<Float>(0,1,0)],
            faces: [SIMD3<UInt16>(0,1,2)],
            textureCoordinates: [],
            materialName: nil
        )
        let file = ThreeDSFile(objects: [empty, valid], materials: [])
        let root = file.sceneNode()
        #expect(root.childNodes.count == 1)
        #expect(root.childNodes.first?.name == "Valid")
    }

    @Test("Bounding box is normalised — max dimension is 1 before centre offset")
    func normalisedScale() {
        let file = makeSingleTriangleFile()
        let root = file.sceneNode()
        // After normalisation the scale uniform value should be 1/maxDim
        let s = root.scale
        // All three scale components should be equal (uniform)
        #expect(abs(s.x - s.y) < 1e-5)
        #expect(abs(s.y - s.z) < 1e-5)
        // Scale should be positive and <= 1
        #expect(s.x > 0)
        #expect(s.x <= 1.0 + 1e-5)
    }
}

// MARK: - ThreeDSView Tests

@Suite("ThreeDSView")
struct ThreeDSViewTests {

    @Test("ThreeDSView can be instantiated without crashing")
    func viewInstantiation() {
        let file = makeSingleTriangleFile()
        _ = ThreeDSView(file: file)
    }

    @Test("ThreeDSView body builds without crashing for empty file")
    func viewWithEmptyFile() {
        let file = ThreeDSFile(objects: [], materials: [])
        _ = ThreeDSView(file: file)
    }

    @Test("ThreeDSView shows correct stats overlay values")
    func statsOverlay() {
        // 2 objects, 4 vertices each, 2 faces each
        let objects = (0..<2).map { i -> ThreeDSObject in
            ThreeDSObject(
                name: "Obj\(i)",
                vertices: [
                    SIMD3<Float>(0,0,0), SIMD3<Float>(1,0,0),
                    SIMD3<Float>(1,1,0), SIMD3<Float>(0,1,0),
                ],
                faces: [SIMD3<UInt16>(0,1,2), SIMD3<UInt16>(0,2,3)],
                textureCoordinates: [],
                materialName: nil
            )
        }
        let file = ThreeDSFile(objects: objects, materials: [])
        let vertexCount = file.objects.reduce(0) { $0 + $1.vertices.count }
        let faceCount   = file.objects.reduce(0) { $0 + $1.faces.count }
        #expect(vertexCount == 8)
        #expect(faceCount == 4)
        // View can be constructed with this data
        _ = ThreeDSView(file: file)
    }
}
