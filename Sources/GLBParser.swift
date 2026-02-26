//
//  GLBParser.swift
//  SwiftGDTF
//
//  Parses the glTF Binary (.glb) file format (version 2.0).
//
//  A .glb file consists of:
//    - 12-byte header: magic (0x46546C67), version (2), total byte length
//    - Chunk 0 (JSON):  type 0x4E4F534A — the glTF JSON descriptor
//    - Chunk 1 (BIN):   type 0x004E4942 — raw binary buffer data
//
//  This parser extracts mesh geometry (positions, normals, UVs, indices)
//  and basic PBR material colours.  It ignores animations, skins,
//  extensions, and embedded textures — none of which are required by the
//  GDTF spec for fixture geometry.
//

import Foundation

// MARK: - Public types

/// A parsed representation of a glTF Binary (.glb) file.
public struct GLBFile: Sendable {
    /// All mesh objects found in the file (one per mesh primitive).
    public var objects: [GLBObject]
    /// All materials found in the file.
    public var materials: [GLBMaterial]
}

/// A single mesh primitive extracted from a .glb file.
public struct GLBObject: Sendable {
    /// The mesh name (from the glTF mesh node).
    public var name: String
    /// Vertex positions (x, y, z).
    public var vertices: [SIMD3<Float>]
    /// Per-vertex normals; may be empty.
    public var normals: [SIMD3<Float>]
    /// UV texture coordinates; may be empty.
    public var textureCoordinates: [SIMD2<Float>]
    /// Triangle face indices into `vertices`.
    public var faces: [SIMD3<UInt32>]
    /// Index of the material in `GLBFile.materials`; may be nil.
    public var materialIndex: Int?
}

/// A material extracted from a .glb file.
public struct GLBMaterial: Sendable {
    /// The material name as stored in the file.
    public var name: String
    /// Base colour (RGBA) from pbrMetallicRoughness.baseColorFactor; may be nil.
    public var baseColor: SIMD4<Float>?
}

// MARK: - Errors

public enum GLBParseError: Error, Equatable {
    case unexpectedEndOfData
    case invalidMagic
    case unsupportedVersion(UInt32)
    case missingJSONChunk
    case invalidJSON
    case missingBINChunk
    case invalidAccessor(String)
}

// MARK: - Parser

extension GLBFile {

    /// Parses a .glb file from raw `Data`.
    public static func parse(data: Data) throws -> GLBFile {
        var parser = Parser(data: data)
        return try parser.parseFile()
    }

    // MARK: - JSON schema types (Decodable)

    private struct GLTFRoot: Decodable {
        var meshes: [GLTFMesh]?
        var accessors: [GLTFAccessor]?
        var bufferViews: [GLTFBufferView]?
        var buffers: [GLTFBuffer]?
        var materials: [GLTFMaterial]?
        var nodes: [GLTFNode]?
    }

    private struct GLTFMesh: Decodable {
        var name: String?
        var primitives: [GLTFPrimitive]
    }

    private struct GLTFPrimitive: Decodable {
        var attributes: [String: Int]
        var indices: Int?
        var material: Int?
        var mode: Int?   // default 4 = TRIANGLES
    }

    private struct GLTFAccessor: Decodable {
        var bufferView: Int?
        var byteOffset: Int?
        var componentType: Int   // 5120=BYTE, 5121=UBYTE, 5122=SHORT, 5123=USHORT, 5125=UINT, 5126=FLOAT
        var count: Int
        var type: String         // "SCALAR", "VEC2", "VEC3", "VEC4"
    }

    private struct GLTFBufferView: Decodable {
        var buffer: Int
        var byteOffset: Int?
        var byteLength: Int
        var byteStride: Int?
    }

    private struct GLTFBuffer: Decodable {
        var byteLength: Int
    }

    private struct GLTFMaterial: Decodable {
        var name: String?
        var pbrMetallicRoughness: GLTFPBR?
    }

    private struct GLTFPBR: Decodable {
        var baseColorFactor: [Float]?
    }

    private struct GLTFNode: Decodable {
        var name: String?
        var mesh: Int?
        var children: [Int]?
    }

    // MARK: - Internal parser

    private struct Parser {
        let data: Data
        var offset: Int = 0

        // MARK: Primitive reads

        mutating func readUInt32() throws -> UInt32 {
            guard offset + 4 <= data.count else { throw GLBParseError.unexpectedEndOfData }
            defer { offset += 4 }
            return data[offset..<(offset + 4)].withUnsafeBytes { $0.load(as: UInt32.self) }
        }

        // MARK: Top-level

        mutating func parseFile() throws -> GLBFile {
            guard data.count >= 12 else { throw GLBParseError.unexpectedEndOfData }

            // --- Header (12 bytes) ---
            let magic = try readUInt32()
            guard magic == 0x46546C67 else { throw GLBParseError.invalidMagic }

            let version = try readUInt32()
            guard version == 2 else { throw GLBParseError.unsupportedVersion(version) }

            let _ = try readUInt32() // totalLength — we rely on Data.count

            // --- Chunk 0: JSON ---
            guard offset + 8 <= data.count else { throw GLBParseError.missingJSONChunk }
            let jsonLength = try readUInt32()
            let jsonType = try readUInt32()
            guard jsonType == 0x4E4F534A else { throw GLBParseError.missingJSONChunk }
            guard offset + Int(jsonLength) <= data.count else { throw GLBParseError.unexpectedEndOfData }

            let jsonData = data[offset..<(offset + Int(jsonLength))]
            offset += Int(jsonLength)

            let root: GLTFRoot
            do {
                root = try JSONDecoder().decode(GLTFRoot.self, from: jsonData)
            } catch {
                throw GLBParseError.invalidJSON
            }

            // --- Chunk 1: BIN (optional — some files have no binary data) ---
            var binData: Data = Data()
            if offset + 8 <= data.count {
                let binLength = try readUInt32()
                let binType = try readUInt32()
                if binType == 0x004E4942 {
                    guard offset + Int(binLength) <= data.count else { throw GLBParseError.unexpectedEndOfData }
                    binData = data[offset..<(offset + Int(binLength))]
                }
            }

            // --- Extract materials ---
            let materials: [GLBMaterial] = (root.materials ?? []).map { mat in
                var baseColor: SIMD4<Float>?
                if let factors = mat.pbrMetallicRoughness?.baseColorFactor, factors.count >= 4 {
                    baseColor = SIMD4(factors[0], factors[1], factors[2], factors[3])
                } else if let factors = mat.pbrMetallicRoughness?.baseColorFactor, factors.count >= 3 {
                    baseColor = SIMD4(factors[0], factors[1], factors[2], 1)
                }
                return GLBMaterial(name: mat.name ?? "", baseColor: baseColor)
            }

            // --- Extract mesh primitives ---
            let accessors = root.accessors ?? []
            let bufferViews = root.bufferViews ?? []

            var objects: [GLBObject] = []

            for mesh in root.meshes ?? [] {
                let meshName = mesh.name ?? ""

                for (primIndex, primitive) in mesh.primitives.enumerated() {
                    // Only handle triangles (mode 4, the default)
                    let mode = primitive.mode ?? 4
                    guard mode == 4 else { continue }

                    // --- Positions (required) ---
                    guard let posAccessorIndex = primitive.attributes["POSITION"],
                          posAccessorIndex < accessors.count else { continue }
                    let posAccessor = accessors[posAccessorIndex]

                    let vertices: [SIMD3<Float>] = try extractVec3(
                        accessor: posAccessor, bufferViews: bufferViews, binData: binData
                    )
                    guard !vertices.isEmpty else { continue }

                    // --- Normals (optional) ---
                    var normals: [SIMD3<Float>] = []
                    if let normalIndex = primitive.attributes["NORMAL"],
                       normalIndex < accessors.count {
                        normals = try extractVec3(
                            accessor: accessors[normalIndex], bufferViews: bufferViews, binData: binData
                        )
                    }

                    // --- Texture coordinates (optional) ---
                    var texCoords: [SIMD2<Float>] = []
                    if let uvIndex = primitive.attributes["TEXCOORD_0"],
                       uvIndex < accessors.count {
                        texCoords = try extractVec2(
                            accessor: accessors[uvIndex], bufferViews: bufferViews, binData: binData
                        )
                    }

                    // --- Indices ---
                    var faces: [SIMD3<UInt32>] = []
                    if let indicesIndex = primitive.indices, indicesIndex < accessors.count {
                        let indexAccessor = accessors[indicesIndex]
                        let rawIndices: [UInt32] = try extractScalarIndices(
                            accessor: indexAccessor, bufferViews: bufferViews, binData: binData
                        )
                        // Group into triangles
                        let triCount = rawIndices.count / 3
                        faces.reserveCapacity(triCount)
                        for i in 0..<triCount {
                            faces.append(SIMD3(rawIndices[i * 3], rawIndices[i * 3 + 1], rawIndices[i * 3 + 2]))
                        }
                    } else {
                        // Non-indexed: generate sequential indices
                        let triCount = vertices.count / 3
                        faces.reserveCapacity(triCount)
                        for i in 0..<triCount {
                            faces.append(SIMD3(UInt32(i * 3), UInt32(i * 3 + 1), UInt32(i * 3 + 2)))
                        }
                    }

                    let name = mesh.primitives.count > 1
                        ? "\(meshName)_prim\(primIndex)"
                        : meshName

                    objects.append(GLBObject(
                        name: name,
                        vertices: vertices,
                        normals: normals,
                        textureCoordinates: texCoords,
                        faces: faces,
                        materialIndex: primitive.material
                    ))
                }
            }

            return GLBFile(objects: objects, materials: materials)
        }

        // MARK: - Buffer extraction helpers

        /// Extracts VEC3 float data from an accessor.
        private func extractVec3(
            accessor: GLTFAccessor,
            bufferViews: [GLTFBufferView],
            binData: Data
        ) throws -> [SIMD3<Float>] {
            guard accessor.type == "VEC3", accessor.componentType == 5126 else {
                // VEC3 with non-FLOAT components — not expected in GDTF, skip gracefully
                return []
            }
            guard let bvIndex = accessor.bufferView, bvIndex < bufferViews.count else { return [] }
            let bv = bufferViews[bvIndex]
            let stride = bv.byteStride ?? (3 * MemoryLayout<Float>.size)
            let baseOffset = (bv.byteOffset ?? 0) + (accessor.byteOffset ?? 0)

            var result: [SIMD3<Float>] = []
            result.reserveCapacity(accessor.count)

            for i in 0..<accessor.count {
                let elemOffset = baseOffset + i * stride
                guard elemOffset + 12 <= binData.count else { break }
                let x = binData[binData.startIndex + elemOffset ..< binData.startIndex + elemOffset + 4]
                    .withUnsafeBytes { $0.load(as: Float.self) }
                let y = binData[binData.startIndex + elemOffset + 4 ..< binData.startIndex + elemOffset + 8]
                    .withUnsafeBytes { $0.load(as: Float.self) }
                let z = binData[binData.startIndex + elemOffset + 8 ..< binData.startIndex + elemOffset + 12]
                    .withUnsafeBytes { $0.load(as: Float.self) }
                result.append(SIMD3(x, y, z))
            }
            return result
        }

        /// Extracts VEC2 float data from an accessor (for texture coordinates).
        private func extractVec2(
            accessor: GLTFAccessor,
            bufferViews: [GLTFBufferView],
            binData: Data
        ) throws -> [SIMD2<Float>] {
            guard accessor.type == "VEC2", accessor.componentType == 5126 else {
                return []
            }
            guard let bvIndex = accessor.bufferView, bvIndex < bufferViews.count else { return [] }
            let bv = bufferViews[bvIndex]
            let stride = bv.byteStride ?? (2 * MemoryLayout<Float>.size)
            let baseOffset = (bv.byteOffset ?? 0) + (accessor.byteOffset ?? 0)

            var result: [SIMD2<Float>] = []
            result.reserveCapacity(accessor.count)

            for i in 0..<accessor.count {
                let elemOffset = baseOffset + i * stride
                guard elemOffset + 8 <= binData.count else { break }
                let u = binData[binData.startIndex + elemOffset ..< binData.startIndex + elemOffset + 4]
                    .withUnsafeBytes { $0.load(as: Float.self) }
                let v = binData[binData.startIndex + elemOffset + 4 ..< binData.startIndex + elemOffset + 8]
                    .withUnsafeBytes { $0.load(as: Float.self) }
                result.append(SIMD2(u, v))
            }
            return result
        }

        /// Extracts scalar index data from an accessor, converting to UInt32.
        private func extractScalarIndices(
            accessor: GLTFAccessor,
            bufferViews: [GLTFBufferView],
            binData: Data
        ) throws -> [UInt32] {
            guard accessor.type == "SCALAR" else { return [] }
            guard let bvIndex = accessor.bufferView, bvIndex < bufferViews.count else { return [] }
            let bv = bufferViews[bvIndex]
            let baseOffset = (bv.byteOffset ?? 0) + (accessor.byteOffset ?? 0)

            var result: [UInt32] = []
            result.reserveCapacity(accessor.count)

            switch accessor.componentType {
            case 5121: // UNSIGNED_BYTE
                let stride = bv.byteStride ?? 1
                for i in 0..<accessor.count {
                    let elemOffset = baseOffset + i * stride
                    guard elemOffset + 1 <= binData.count else { break }
                    result.append(UInt32(binData[binData.startIndex + elemOffset]))
                }
            case 5122: // SHORT (signed, but used as index)
                let stride = bv.byteStride ?? 2
                for i in 0..<accessor.count {
                    let elemOffset = baseOffset + i * stride
                    guard elemOffset + 2 <= binData.count else { break }
                    let val = binData[binData.startIndex + elemOffset ..< binData.startIndex + elemOffset + 2]
                        .withUnsafeBytes { $0.load(as: Int16.self) }
                    result.append(UInt32(bitPattern: Int32(val)))
                }
            case 5123: // UNSIGNED_SHORT
                let stride = bv.byteStride ?? 2
                for i in 0..<accessor.count {
                    let elemOffset = baseOffset + i * stride
                    guard elemOffset + 2 <= binData.count else { break }
                    let val = binData[binData.startIndex + elemOffset ..< binData.startIndex + elemOffset + 2]
                        .withUnsafeBytes { $0.load(as: UInt16.self) }
                    result.append(UInt32(val))
                }
            case 5125: // UNSIGNED_INT
                let stride = bv.byteStride ?? 4
                for i in 0..<accessor.count {
                    let elemOffset = baseOffset + i * stride
                    guard elemOffset + 4 <= binData.count else { break }
                    let val = binData[binData.startIndex + elemOffset ..< binData.startIndex + elemOffset + 4]
                        .withUnsafeBytes { $0.load(as: UInt32.self) }
                    result.append(val)
                }
            default:
                // Unknown component type for indices
                break
            }
            return result
        }
    }
}
