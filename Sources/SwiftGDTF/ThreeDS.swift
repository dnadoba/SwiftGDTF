//
//  ThreeDS.swift
//  SwiftGDTF
//
//  Parses the 3D Studio (.3ds) binary file format.
//
//  The .3ds format uses a chunk-based structure. Every chunk begins with:
//    - chunkID:  UInt16  (little-endian)
//    - length:   UInt32  (little-endian, includes the 6-byte header)
//
//  Supported chunk IDs parsed below (see `Chunk.ID`).
//

import Foundation

/// A parsed representation of a 3D Studio (.3ds) file.
public struct ThreeDSFile {
    /// All named mesh objects found in the file.
    public var objects: [ThreeDSObject]
    /// All named materials found in the file.
    public var materials: [ThreeDSMaterial]
}

/// A single named mesh object from a .3ds file.
public struct ThreeDSObject {
    /// The object name as stored in the file.
    public var name: String
    /// Vertex positions; each element is (x, y, z) in the model's local coordinate space.
    public var vertices: [SIMD3<Float>]
    /// Triangle face indices into `vertices`; each element is (a, b, c).
    public var faces: [SIMD3<UInt16>]
    /// UV texture coordinates, one per vertex (parallel to `vertices`); may be empty.
    public var textureCoordinates: [SIMD2<Float>]
    /// Name of the material assigned to this mesh; may be nil.
    public var materialName: String?
}

/// A named material from a .3ds file.
public struct ThreeDSMaterial {
    /// The material name as stored in the file.
    public var name: String
    /// Ambient colour (r, g, b) in [0, 1].
    public var ambientColor: SIMD3<Float>?
    /// Diffuse colour (r, g, b) in [0, 1].
    public var diffuseColor: SIMD3<Float>?
    /// Specular colour (r, g, b) in [0, 1].
    public var specularColor: SIMD3<Float>?
}

// MARK: - Errors

public enum ThreeDSParseError: Error, Equatable {
    case unexpectedEndOfData
    case invalidHeader
    case unsupportedVersion(UInt16)
}

// MARK: - Chunk IDs

extension ThreeDSFile {
    enum ChunkID: UInt16 {
        // Top-level
        case main            = 0x4D4D
        // Editor
        case editor          = 0x3D3D
        case objectBlock     = 0x4000
        // Mesh
        case triangularMesh  = 0x4100
        case vertexList      = 0x4110
        case faceList        = 0x4120
        case faceMaterial    = 0x4130
        case texCoordList    = 0x4140
        // Material
        case materialBlock   = 0xAFFF
        case materialName    = 0xA000
        case ambientColor    = 0xA010
        case diffuseColor    = 0xA020
        case specularColor   = 0xA030
        case colorRGB        = 0x0010   // float RGB sub-chunk
        case colorRGB24      = 0x0011   // 24-bit RGB sub-chunk
    }
}

// MARK: - Parser

extension ThreeDSFile {
    // TODO: use RawSpan instead of Data once RawSpan can load basic types like Int8 and Float
    /// Parses a .3ds file from raw `Data`.
    public static func parse(data: Data) throws -> ThreeDSFile {
        var parser = Parser(data: data)
        return try parser.parseFile()
    }

    private struct Parser {
        let data: Data
        var offset: Int = 0

        init(data: Data) {
            self.data = data
        }

        // MARK: Primitive reads

        mutating func readUInt8() throws -> UInt8 {
            guard offset + 1 <= data.count else { throw ThreeDSParseError.unexpectedEndOfData }
            defer { offset += 1 }
            return data[offset]
        }

        mutating func readUInt16() throws -> UInt16 {
            guard offset + 2 <= data.count else { throw ThreeDSParseError.unexpectedEndOfData }
            defer { offset += 2 }
            return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
        }

        mutating func readUInt32() throws -> UInt32 {
            guard offset + 4 <= data.count else { throw ThreeDSParseError.unexpectedEndOfData }
            defer { offset += 4 }
            return UInt32(data[offset])
                | (UInt32(data[offset + 1]) << 8)
                | (UInt32(data[offset + 2]) << 16)
                | (UInt32(data[offset + 3]) << 24)
        }

        mutating func readFloat() throws -> Float {
            let bits = try readUInt32()
            return Float(bitPattern: bits)
        }

        /// Reads a null-terminated C string.
        mutating func readCString() throws -> String {
            var bytes: [UInt8] = []
            while true {
                let byte = try readUInt8()
                if byte == 0 { break }
                bytes.append(byte)
            }
            return String(bytes: bytes, encoding: .isoLatin1) ?? ""
        }

        mutating func skip(_ count: Int) throws {
            guard offset + count <= data.count else { throw ThreeDSParseError.unexpectedEndOfData }
            offset += count
        }

        // MARK: Chunk header

        mutating func readChunkHeader() throws -> (id: UInt16, length: UInt32) {
            let id = try readUInt16()
            let length = try readUInt32()
            return (id, length)
        }

        // MARK: Top-level entry point

        mutating func parseFile() throws -> ThreeDSFile {
            let (id, length) = try readChunkHeader()
            guard id == ChunkID.main.rawValue else { throw ThreeDSParseError.invalidHeader }
            let end = Int(length)   // main chunk spans the whole file
            guard end <= data.count else { throw ThreeDSParseError.unexpectedEndOfData }

            var objects: [ThreeDSObject] = []
            var materials: [ThreeDSMaterial] = []

            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= data.count else { throw ThreeDSParseError.unexpectedEndOfData }

                if chunkID == ChunkID.editor.rawValue {
                    try parseEditorChunk(end: chunkEnd, objects: &objects, materials: &materials)
                } else {
                    offset = chunkEnd
                }
            }

            return ThreeDSFile(objects: objects, materials: materials)
        }

        // MARK: Editor chunk (0x3D3D)

        mutating func parseEditorChunk(end: Int, objects: inout [ThreeDSObject], materials: inout [ThreeDSMaterial]) throws {
            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= end else { throw ThreeDSParseError.unexpectedEndOfData }

                switch chunkID {
                case ChunkID.objectBlock.rawValue:
                    if let object = try parseObjectBlock(end: chunkEnd) {
                        objects.append(object)
                    }
                case ChunkID.materialBlock.rawValue:
                    let material = try parseMaterialBlock(end: chunkEnd)
                    materials.append(material)
                default:
                    offset = chunkEnd
                }
            }
        }

        // MARK: Object block (0x4000)

        mutating func parseObjectBlock(end: Int) throws -> ThreeDSObject? {
            let name = try readCString()
            var vertices: [SIMD3<Float>] = []
            var faces: [SIMD3<UInt16>] = []
            var texCoords: [SIMD2<Float>] = []
            var materialName: String?

            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= end else { throw ThreeDSParseError.unexpectedEndOfData }

                switch chunkID {
                case ChunkID.triangularMesh.rawValue:
                    try parseMeshChunk(end: chunkEnd, vertices: &vertices, faces: &faces, texCoords: &texCoords, materialName: &materialName)
                default:
                    offset = chunkEnd
                }
            }

            guard !vertices.isEmpty || !faces.isEmpty else { return nil }
            return ThreeDSObject(name: name, vertices: vertices, faces: faces, textureCoordinates: texCoords, materialName: materialName)
        }

        // MARK: Triangular mesh (0x4100)

        mutating func parseMeshChunk(end: Int, vertices: inout [SIMD3<Float>], faces: inout [SIMD3<UInt16>], texCoords: inout [SIMD2<Float>], materialName: inout String?) throws {
            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= end else { throw ThreeDSParseError.unexpectedEndOfData }

                switch chunkID {
                case ChunkID.vertexList.rawValue:
                    vertices = try parseVertexList()
                case ChunkID.faceList.rawValue:
                    try parseFaceList(end: chunkEnd, faces: &faces, materialName: &materialName)
                case ChunkID.texCoordList.rawValue:
                    texCoords = try parseTexCoordList()
                default:
                    offset = chunkEnd
                }
            }
        }

        // MARK: Vertex list (0x4110)

        mutating func parseVertexList() throws -> [SIMD3<Float>] {
            let count = Int(try readUInt16())
            var verts: [SIMD3<Float>] = []
            verts.reserveCapacity(count)
            for _ in 0..<count {
                let x = try readFloat()
                let y = try readFloat()
                let z = try readFloat()
                verts.append(SIMD3(x, y, z))
            }
            return verts
        }

        // MARK: Face list (0x4120) — may contain sub-chunk 0x4130 for face-material mapping

        mutating func parseFaceList(end: Int, faces: inout [SIMD3<UInt16>], materialName: inout String?) throws {
            let count = Int(try readUInt16())
            faces.reserveCapacity(count)
            for _ in 0..<count {
                let a = try readUInt16()
                let b = try readUInt16()
                let c = try readUInt16()
                _ = try readUInt16()  // face flags — unused
                faces.append(SIMD3(a, b, c))
            }

            // Optional sub-chunks (e.g. face material assignment)
            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= end else { throw ThreeDSParseError.unexpectedEndOfData }

                if chunkID == ChunkID.faceMaterial.rawValue {
                    materialName = try readCString()
                    // skip face index list
                    offset = chunkEnd
                } else {
                    offset = chunkEnd
                }
            }
        }

        // MARK: Texture coordinate list (0x4140)

        mutating func parseTexCoordList() throws -> [SIMD2<Float>] {
            let count = Int(try readUInt16())
            var coords: [SIMD2<Float>] = []
            coords.reserveCapacity(count)
            for _ in 0..<count {
                let u = try readFloat()
                let v = try readFloat()
                coords.append(SIMD2(u, v))
            }
            return coords
        }

        // MARK: Material block (0xAFFF)

        mutating func parseMaterialBlock(end: Int) throws -> ThreeDSMaterial {
            var name = ""
            var ambient: SIMD3<Float>?
            var diffuse: SIMD3<Float>?
            var specular: SIMD3<Float>?

            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= end else { throw ThreeDSParseError.unexpectedEndOfData }

                switch chunkID {
                case ChunkID.materialName.rawValue:
                    name = try readCString()
                case ChunkID.ambientColor.rawValue:
                    ambient = try parseColorChunk(end: chunkEnd)
                case ChunkID.diffuseColor.rawValue:
                    diffuse = try parseColorChunk(end: chunkEnd)
                case ChunkID.specularColor.rawValue:
                    specular = try parseColorChunk(end: chunkEnd)
                default:
                    offset = chunkEnd
                }
            }

            return ThreeDSMaterial(name: name, ambientColor: ambient, diffuseColor: diffuse, specularColor: specular)
        }

        // MARK: Colour sub-chunk (0x0010 float RGB or 0x0011 24-bit RGB)

        mutating func parseColorChunk(end: Int) throws -> SIMD3<Float>? {
            while offset < end {
                let chunkStart = offset
                let (chunkID, chunkLength) = try readChunkHeader()
                let chunkEnd = chunkStart + Int(chunkLength)
                guard chunkEnd <= end else { throw ThreeDSParseError.unexpectedEndOfData }

                switch chunkID {
                case ChunkID.colorRGB.rawValue:
                    let r = try readFloat()
                    let g = try readFloat()
                    let b = try readFloat()
                    offset = chunkEnd
                    return SIMD3(r, g, b)
                case ChunkID.colorRGB24.rawValue:
                    let r = Float(try readUInt8()) / 255
                    let g = Float(try readUInt8()) / 255
                    let b = Float(try readUInt8()) / 255
                    offset = chunkEnd
                    return SIMD3(r, g, b)
                default:
                    offset = chunkEnd
                }
            }
            return nil
        }
    }
}
