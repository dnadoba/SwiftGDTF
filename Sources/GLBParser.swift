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
import simd

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
        var scene: Int?
        var scenes: [GLTFScene]?
        var meshes: [GLTFMesh]?
        var accessors: [GLTFAccessor]?
        var bufferViews: [GLTFBufferView]?
        var buffers: [GLTFBuffer]?
        var materials: [GLTFMaterial]?
        var nodes: [GLTFNode]?
    }

    private struct GLTFScene: Decodable {
        var nodes: [Int]?
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
        var translation: SIMD3<Float>?
        var rotation: simd_quatf?      // [x, y, z, w]
        var scale: SIMD3<Float>?
        var matrix: [Float]?           // column-major 4×4 (16 elements)

        /// Computes the local transform matrix for this node.
        ///
        /// Per the glTF spec, if `matrix` is present it is used directly.
        /// Otherwise the transform is composed from `T * R * S`.
        var localTransform: simd_float4x4 {
            if let m = matrix, m.count == 16 {
                // glTF stores matrices in column-major order
                return simd_float4x4(
                    SIMD4(m[0],  m[1],  m[2],  m[3]),
                    SIMD4(m[4],  m[5],  m[6],  m[7]),
                    SIMD4(m[8],  m[9],  m[10], m[11]),
                    SIMD4(m[12], m[13], m[14], m[15])
                )
            }

            let s = scale ?? SIMD3<Float>(1, 1, 1)
            let r = rotation ?? simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
            let t = translation ?? SIMD3<Float>(0, 0, 0)

            let scaleMatrix = simd_float4x4(diagonal: SIMD4(s.x, s.y, s.z, 1))
            let rotMatrix = simd_float4x4(r)
            var trs = rotMatrix * scaleMatrix
            trs[3] = SIMD4(t.x, t.y, t.z, 1)
            return trs
        }

        // Custom Decodable to parse SIMD types from JSON arrays
        private enum CodingKeys: String, CodingKey {
            case name, mesh, children, translation, rotation, scale, matrix
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            mesh = try container.decodeIfPresent(Int.self, forKey: .mesh)
            children = try container.decodeIfPresent([Int].self, forKey: .children)
            matrix = try container.decodeIfPresent([Float].self, forKey: .matrix)

            if let t = try container.decodeIfPresent([Float].self, forKey: .translation), t.count >= 3 {
                translation = SIMD3(t[0], t[1], t[2])
            }
            if let r = try container.decodeIfPresent([Float].self, forKey: .rotation), r.count >= 4 {
                rotation = simd_quatf(ix: r[0], iy: r[1], iz: r[2], r: r[3])
            }
            if let s = try container.decodeIfPresent([Float].self, forKey: .scale), s.count >= 3 {
                scale = SIMD3(s[0], s[1], s[2])
            }
        }
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

            // --- Extract mesh primitives by walking the node hierarchy ---
            // Each node may have a transform (TRS or matrix) that must be
            // applied to its mesh vertices.  The scene graph is walked to
            // accumulate world transforms.
            let accessors = root.accessors ?? []
            let bufferViews = root.bufferViews ?? []
            let nodes = root.nodes ?? []
            let meshes = root.meshes ?? []

            // Determine root nodes: those in the default scene, or all nodes
            // not referenced as children of other nodes.
            var rootNodeIndices: [Int]
            if let scenes = root.scenes, let sceneIndex = root.scene,
               sceneIndex < scenes.count, let sceneNodes = scenes[sceneIndex].nodes {
                rootNodeIndices = sceneNodes
            } else {
                var childSet = Set<Int>()
                for node in nodes {
                    for c in node.children ?? [] { childSet.insert(c) }
                }
                rootNodeIndices = (0..<nodes.count).filter { !childSet.contains($0) }
            }

            // Walk the node tree to collect (meshIndex, worldTransform) pairs
            var meshInstances: [(meshIndex: Int, worldTransform: simd_float4x4)] = []

            func walkNode(_ nodeIndex: Int, worldTransform: simd_float4x4) {
                guard nodeIndex >= 0, nodeIndex < nodes.count else { return }
                let node = nodes[nodeIndex]
                let localTransform = worldTransform * node.localTransform

                if let meshIndex = node.mesh, meshIndex < meshes.count {
                    meshInstances.append((meshIndex, localTransform))
                }

                for childIndex in node.children ?? [] {
                    walkNode(childIndex, worldTransform: localTransform)
                }
            }

            for rootIndex in rootNodeIndices {
                walkNode(rootIndex, worldTransform: .init(1))
            }

            // If no scene graph, fall back to meshes without transforms
            if meshInstances.isEmpty {
                for i in meshes.indices {
                    meshInstances.append((i, .init(1)))
                }
            }

            var objects: [GLBObject] = []

            for (meshIndex, worldTransform) in meshInstances {
                let mesh = meshes[meshIndex]
                let meshName = mesh.name ?? ""

                for (primIndex, primitive) in mesh.primitives.enumerated() {
                    let mode = primitive.mode ?? 4
                    guard mode == 4 else { continue }

                    guard let posAccessorIndex = primitive.attributes["POSITION"],
                          posAccessorIndex < accessors.count else { continue }

                    var vertices: [SIMD3<Float>] = try extractVec3(
                        accessor: accessors[posAccessorIndex], bufferViews: bufferViews, binData: binData
                    )
                    guard !vertices.isEmpty else { continue }

                    // Apply world transform to vertex positions
                    for i in vertices.indices {
                        let v = worldTransform * SIMD4<Float>(vertices[i].x, vertices[i].y, vertices[i].z, 1)
                        vertices[i] = SIMD3(v.x, v.y, v.z)
                    }

                    // Normals (optional) — transform by the upper-left 3×3
                    var normals: [SIMD3<Float>] = []
                    if let normalIndex = primitive.attributes["NORMAL"],
                       normalIndex < accessors.count {
                        normals = try extractVec3(
                            accessor: accessors[normalIndex], bufferViews: bufferViews, binData: binData
                        )
                        if !normals.isEmpty {
                            let normalMatrix = simd_float3x3(
                                SIMD3(worldTransform[0].x, worldTransform[0].y, worldTransform[0].z),
                                SIMD3(worldTransform[1].x, worldTransform[1].y, worldTransform[1].z),
                                SIMD3(worldTransform[2].x, worldTransform[2].y, worldTransform[2].z)
                            )
                            for i in normals.indices {
                                normals[i] = normalize(normalMatrix * normals[i])
                            }
                        }
                    }

                    // Texture coordinates (optional) — no transform needed
                    var texCoords: [SIMD2<Float>] = []
                    if let uvIndex = primitive.attributes["TEXCOORD_0"],
                       uvIndex < accessors.count {
                        texCoords = try extractVec2(
                            accessor: accessors[uvIndex], bufferViews: bufferViews, binData: binData
                        )
                    }

                    // Indices
                    var faces: [SIMD3<UInt32>] = []
                    if let indicesIndex = primitive.indices, indicesIndex < accessors.count {
                        let rawIndices: [UInt32] = try extractScalarIndices(
                            accessor: accessors[indicesIndex], bufferViews: bufferViews, binData: binData
                        )
                        let triCount = rawIndices.count / 3
                        faces.reserveCapacity(triCount)
                        for i in 0..<triCount {
                            faces.append(SIMD3(rawIndices[i * 3], rawIndices[i * 3 + 1], rawIndices[i * 3 + 2]))
                        }
                    } else {
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
