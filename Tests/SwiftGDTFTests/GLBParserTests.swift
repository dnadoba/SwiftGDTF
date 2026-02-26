import Testing
import Foundation
@testable import SwiftGDTF

// MARK: - Helpers

/// Builds a minimal valid GLB binary containing a single triangle.
///
/// GLB layout:
///   Header (12 bytes): magic, version=2, totalLength
///   JSON chunk: minimal glTF JSON with one mesh, one primitive, accessors, bufferViews
///   BIN chunk: vertex positions (3×VEC3) + triangle indices (3×UNSIGNED_SHORT)
func buildSingleTriangleGLB() -> Data {
    // --- BIN data: 3 vertices (3×12=36 bytes) + 3 indices (3×2=6 bytes, padded to 8) ---
    var bin = Data()
    func writeFloat(_ v: Float) { withUnsafeBytes(of: v) { bin.append(contentsOf: $0) } }
    func writeUInt16(_ v: UInt16) { withUnsafeBytes(of: v) { bin.append(contentsOf: $0) } }

    // Vertices: (0,0,0), (1,0,0), (0,1,0)
    writeFloat(0); writeFloat(0); writeFloat(0)
    writeFloat(1); writeFloat(0); writeFloat(0)
    writeFloat(0); writeFloat(1); writeFloat(0)
    // Indices: 0, 1, 2
    writeUInt16(0); writeUInt16(1); writeUInt16(2)
    // Pad to 4-byte alignment
    writeUInt16(0)

    // --- JSON ---
    let json = """
    {
      "asset": {"version": "2.0"},
      "scene": 0,
      "scenes": [{"nodes": [0]}],
      "nodes": [{"mesh": 0, "name": "TriangleNode"}],
      "meshes": [{
        "name": "TriangleMesh",
        "primitives": [{
          "attributes": {"POSITION": 0},
          "indices": 1,
          "material": 0
        }]
      }],
      "accessors": [
        {"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3"},
        {"bufferView": 1, "componentType": 5123, "count": 3, "type": "SCALAR"}
      ],
      "bufferViews": [
        {"buffer": 0, "byteOffset": 0, "byteLength": 36},
        {"buffer": 0, "byteOffset": 36, "byteLength": 6}
      ],
      "buffers": [{"byteLength": \(bin.count)}],
      "materials": [{"name": "TestMat", "pbrMetallicRoughness": {"baseColorFactor": [1.0, 0.0, 0.0, 1.0]}}]
    }
    """
    var jsonData = json.data(using: .utf8)!
    // Pad JSON to 4-byte alignment
    while jsonData.count % 4 != 0 { jsonData.append(0x20) } // space padding

    // --- Assemble GLB ---
    var glb = Data()
    func writeGLBUInt32(_ v: UInt32) { withUnsafeBytes(of: v) { glb.append(contentsOf: $0) } }

    let totalLength = 12 + 8 + jsonData.count + 8 + bin.count

    // Header
    writeGLBUInt32(0x46546C67)       // magic "glTF"
    writeGLBUInt32(2)                 // version
    writeGLBUInt32(UInt32(totalLength))

    // JSON chunk
    writeGLBUInt32(UInt32(jsonData.count))
    writeGLBUInt32(0x4E4F534A)       // "JSON"
    glb.append(jsonData)

    // BIN chunk
    writeGLBUInt32(UInt32(bin.count))
    writeGLBUInt32(0x004E4942)       // "BIN\0"
    glb.append(bin)

    return glb
}

/// Builds a minimal valid GLB with no meshes (just the header and an empty JSON chunk).
func buildEmptyMeshGLB() -> Data {
    let json = """
    {"asset": {"version": "2.0"}}
    """
    var jsonData = json.data(using: .utf8)!
    while jsonData.count % 4 != 0 { jsonData.append(0x20) }

    var glb = Data()
    func writeGLBUInt32(_ v: UInt32) { withUnsafeBytes(of: v) { glb.append(contentsOf: $0) } }

    let totalLength = 12 + 8 + jsonData.count

    writeGLBUInt32(0x46546C67)
    writeGLBUInt32(2)
    writeGLBUInt32(UInt32(totalLength))
    writeGLBUInt32(UInt32(jsonData.count))
    writeGLBUInt32(0x4E4F534A)
    glb.append(jsonData)

    return glb
}

// MARK: - GLB Parser Tests

@Suite("GLB Parser")
struct GLBParserTests {

    @Test("Empty data throws unexpectedEndOfData")
    func parseEmptyData() {
        #expect(throws: GLBParseError.unexpectedEndOfData) {
            _ = try GLBFile.parse(data: Data())
        }
    }

    @Test("Truncated header throws unexpectedEndOfData")
    func parseTruncatedHeader() {
        let truncated = Data([0x67, 0x6C, 0x54, 0x46]) // just magic, no version/length
        #expect(throws: GLBParseError.unexpectedEndOfData) {
            _ = try GLBFile.parse(data: truncated)
        }
    }

    @Test("Invalid magic throws invalidMagic")
    func parseInvalidMagic() {
        var data = Data(repeating: 0, count: 12)
        // Write wrong magic
        data[0] = 0xFF; data[1] = 0xFF; data[2] = 0xFF; data[3] = 0xFF
        #expect(throws: GLBParseError.invalidMagic) {
            _ = try GLBFile.parse(data: data)
        }
    }

    @Test("Wrong version throws unsupportedVersion")
    func parseWrongVersion() {
        var data = Data(repeating: 0, count: 20)
        // magic
        withUnsafeBytes(of: UInt32(0x46546C67)) { data.replaceSubrange(0..<4, with: $0) }
        // version = 1
        withUnsafeBytes(of: UInt32(1)) { data.replaceSubrange(4..<8, with: $0) }
        // total length
        withUnsafeBytes(of: UInt32(20)) { data.replaceSubrange(8..<12, with: $0) }
        // JSON chunk header
        withUnsafeBytes(of: UInt32(0)) { data.replaceSubrange(12..<16, with: $0) }
        withUnsafeBytes(of: UInt32(0x4E4F534A)) { data.replaceSubrange(16..<20, with: $0) }
        #expect(throws: GLBParseError.unsupportedVersion(1)) {
            _ = try GLBFile.parse(data: data)
        }
    }

    @Test("Minimal GLB with no meshes produces empty objects")
    func parseMinimalGLB() throws {
        let glb = buildEmptyMeshGLB()
        let file = try GLBFile.parse(data: glb)
        #expect(file.objects.isEmpty)
        #expect(file.materials.isEmpty)
    }

    @Test("Single triangle GLB produces correct geometry")
    func parseSingleTriangle() throws {
        let glb = buildSingleTriangleGLB()
        let file = try GLBFile.parse(data: glb)

        #expect(file.objects.count == 1)
        #expect(file.materials.count == 1)

        let obj = file.objects[0]
        #expect(obj.name == "TriangleMesh")
        #expect(obj.vertices.count == 3)
        #expect(obj.faces.count == 1)
        #expect(obj.normals.isEmpty)
        #expect(obj.textureCoordinates.isEmpty)
        #expect(obj.materialIndex == 0)

        // Check vertex positions
        #expect(obj.vertices[0] == SIMD3<Float>(0, 0, 0))
        #expect(obj.vertices[1] == SIMD3<Float>(1, 0, 0))
        #expect(obj.vertices[2] == SIMD3<Float>(0, 1, 0))

        // Check face indices
        #expect(obj.faces[0] == SIMD3<UInt32>(0, 1, 2))

        // Check material
        let mat = file.materials[0]
        #expect(mat.name == "TestMat")
        #expect(mat.baseColor == SIMD4<Float>(1, 0, 0, 1))
    }

    @Test("Real .glb file from fixture 100110")
    func parseFromFixture100110() throws {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwiftGDTF/Fixtures")
        let fixtureURL = cacheDir.appendingPathComponent("100110.gdtf")

        guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
            print("Skipping: 100110.gdtf not in cache")
            return
        }

        let gdtfData = try Data(contentsOf: fixtureURL)
        let gdtf = try loadGDTF(data: gdtfData)

        var parsedCount = 0
        for model in gdtf.fixtureType.models {
            for lod in GDTFModel.LOD.allCases {
                guard let raw = model.resolveFile(gdtf: gdtfData, format: .glb, lod: lod) else { continue }
                let parsed = try GLBFile.parse(data: raw)
                for obj in parsed.objects {
                    #expect(!obj.vertices.isEmpty,
                            "Object '\(obj.name)' in '\(model.name)' has no vertices")
                    #expect(!obj.faces.isEmpty,
                            "Object '\(obj.name)' in '\(model.name)' has no faces")
                    // All face indices must be within bounds
                    for face in obj.faces {
                        #expect(Int(face.x) < obj.vertices.count)
                        #expect(Int(face.y) < obj.vertices.count)
                        #expect(Int(face.z) < obj.vertices.count)
                    }
                }
                parsedCount += 1
            }
        }
        #expect(parsedCount > 0, "Expected at least one .glb model in fixture 100110")
    }
}

// MARK: - Cached Fixture GLB Parsing

@Suite("Cached GLB Fixtures")
struct CachedGLBFixtures {
    let fixturesFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SwiftGDTF")
        .appendingPathComponent("Fixtures")

    /// Iterates every cached GDTF, finds all models that have a .glb file entry, and
    /// asserts that `GLBFile.parse` succeeds.
    @Test func parseGLBModels() async throws {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: fixturesFolder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let gdtfFiles = fileURLs.filter { $0.pathExtension.lowercased() == "gdtf" }

        guard !gdtfFiles.isEmpty else {
            print("No GDTF files found in \(fixturesFolder) — run parseAllFixtures first.")
            return
        }

        struct ModelResult: Sendable {
            var parsed: Int
            var failures: [(file: String, model: String, error: String)]
            var fixturesWithGLB: [(rid: String, name: String)]
        }

        let results = await withTaskGroup(of: ModelResult.self) { group in
            for fileURL in gdtfFiles {
                group.addTask {
                    let gdtfData: Data
                    let gdtf: GDTF
                    do {
                        gdtfData = try Data(contentsOf: fileURL)
                        gdtf = try loadGDTF(data: gdtfData)
                    } catch {
                        return ModelResult(parsed: 0, failures: [], fixturesWithGLB: [])
                    }

                    var parsed = 0
                    var failures: [(file: String, model: String, error: String)] = []
                    var hasGLB = false

                    for model in gdtf.fixtureType.models {
                        for lod in GDTFModel.LOD.allCases {
                            guard let raw = model.resolveFile(gdtf: gdtfData, format: .glb, lod: lod) else {
                                continue
                            }
                            do {
                                let glb = try GLBFile.parse(data: raw)
                                hasGLB = true

                                for object in glb.objects {
                                    #expect(!object.vertices.isEmpty,
                                            "Object '\(object.name)' in '\(model.name)' has no vertices")
                                    #expect(!object.faces.isEmpty,
                                            "Object '\(object.name)' in '\(model.name)' has no faces")
                                    // UV coordinates are optional, but if present must match vertex count
                                    if !object.textureCoordinates.isEmpty {
                                        #expect(object.textureCoordinates.count == object.vertices.count,
                                                "UV count mismatch in '\(object.name)'")
                                    }
                                    // Normals are optional, but if present must match vertex count
                                    if !object.normals.isEmpty {
                                        #expect(object.normals.count == object.vertices.count,
                                                "Normal count mismatch in '\(object.name)'")
                                    }
                                    // All face indices must be within bounds
                                    for face in object.faces {
                                        #expect(Int(face.x) < object.vertices.count, "Face index out of bounds in '\(object.name)'")
                                        #expect(Int(face.y) < object.vertices.count, "Face index out of bounds in '\(object.name)'")
                                        #expect(Int(face.z) < object.vertices.count, "Face index out of bounds in '\(object.name)'")
                                    }
                                }

                                parsed += 1
                            } catch {
                                failures.append((
                                    file: fileURL.lastPathComponent,
                                    model: "\(model.name) (\(lod))",
                                    error: "\(error)"
                                ))
                            }
                        }
                    }

                    let rid = fileURL.deletingPathExtension().lastPathComponent
                    let fixtureName = "\(gdtf.fixtureType.manufacturer) \(gdtf.fixtureType.name)"
                    let fixturesWithGLB: [(rid: String, name: String)] = hasGLB
                        ? [(rid: rid, name: fixtureName)]
                        : []
                    return ModelResult(parsed: parsed, failures: failures, fixturesWithGLB: fixturesWithGLB)
                }
            }

            var combined = ModelResult(parsed: 0, failures: [], fixturesWithGLB: [])
            for await result in group {
                combined.parsed += result.parsed
                combined.failures += result.failures
                combined.fixturesWithGLB += result.fixturesWithGLB
            }
            return combined
        }

        let total = results.parsed + results.failures.count
        print("\nGLB Model Parsing Summary:")
        print("  Total .glb entries found : \(total)")
        print("  Successfully parsed      : \(results.parsed)")
        print("  Parse failures           : \(results.failures.count)")
        if !results.failures.isEmpty {
            for failure in results.failures.prefix(20) {
                print("  FAIL: \(failure.file) / \(failure.model): \(failure.error)")
            }
            if results.failures.count > 20 {
                print("  ... and \(results.failures.count - 20) more failures")
            }
        }

        let sorted = results.fixturesWithGLB.sorted { $0.rid < $1.rid }
        print("\nFixtures with .glb models (\(sorted.count) total):")
        for fixture in sorted.prefix(30) {
            print("  rid: \(fixture.rid)  name: \(fixture.name)")
        }
        if sorted.count > 30 {
            print("  ... and \(sorted.count - 30) more")
        }

        #expect(results.failures.isEmpty, "Some .glb models failed to parse — see output above.")
    }
}
