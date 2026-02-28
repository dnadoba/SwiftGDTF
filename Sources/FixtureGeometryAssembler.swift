//
//  FixtureGeometryAssembler.swift
//  SwiftGDTF
//
//  Renderer-agnostic fixture geometry assembly.
//
//  Walks the GDTF geometry tree, resolves GeometryReference nodes, extracts
//  mesh data from .3ds / .glb / primitive sources, and produces a hierarchical
//  `AssembledNode` tree that any renderer (SceneKit, Metal, etc.) can convert
//  to its own scene graph.
//

import Foundation
import simd

// MARK: - Public types

/// Renderer-agnostic mesh container.
public struct MeshData: Sendable {
    public var submeshes: [Submesh]

    public struct Submesh: Sendable {
        public var name: String
        public var vertices: [SIMD3<Float>]
        /// Per-vertex normals; empty if unavailable.
        public var normals: [SIMD3<Float>]
        /// Per-vertex UV coordinates; empty if unavailable.
        public var textureCoordinates: [SIMD2<Float>]
        /// Triangle face indices.
        public var faceIndices: [SIMD3<UInt32>]
    }
}

/// Axis-aligned bounding box computed from raw vertices.
public struct MeshBoundingBox: Sendable {
    public var min: SIMD3<Float>
    public var max: SIMD3<Float>

    public var span: SIMD3<Float> { max - min }

    public init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.min = min
        self.max = max
    }

    public init(vertices: some Sequence<SIMD3<Float>>) {
        var mn = SIMD3<Float>(repeating:  Float.infinity)
        var mx = SIMD3<Float>(repeating: -Float.infinity)
        for v in vertices {
            mn = simd_min(mn, v)
            mx = simd_max(mx, v)
        }
        self.min = mn
        self.max = mx
    }

    /// Returns the AABB of the 8 corners after applying the given transform.
    public func transformed(by transform: simd_float4x4) -> MeshBoundingBox {
        var rMin = SIMD3<Float>(repeating:  Float.infinity)
        var rMax = SIMD3<Float>(repeating: -Float.infinity)
        for dx in [min.x, max.x] {
            for dy in [min.y, max.y] {
                for dz in [min.z, max.z] {
                    let rp = transform * SIMD4<Float>(dx, dy, dz, 1)
                    rMin = simd_min(rMin, SIMD3(rp.x, rp.y, rp.z))
                    rMax = simd_max(rMax, SIMD3(rp.x, rp.y, rp.z))
                }
            }
        }
        return MeshBoundingBox(min: rMin, max: rMax)
    }

    /// Expands this bounding box to include `other`.
    public mutating func formUnion(_ other: MeshBoundingBox) {
        min = simd_min(min, other.min)
        max = simd_max(max, other.max)
    }

    /// An empty bounding box (inverted extents).
    public static var empty: MeshBoundingBox {
        MeshBoundingBox(
            min: SIMD3<Float>(repeating:  Float.infinity),
            max: SIMD3<Float>(repeating: -Float.infinity)
        )
    }
}

/// Describes a rotation axis (pan or tilt) for a specific geometry.
public struct GeometryAxisInfo: Sendable {
    /// Physical range in degrees. Nil if no pan channel found.
    public var panRange: ClosedRange<Double>?
    /// Whether pan supports infinite rotation (panRotate attribute).
    public var panInfinite: Bool = false
    /// Physical range in degrees for tilt. Nil if no tilt channel found.
    public var tiltRange: ClosedRange<Double>?
    /// Whether tilt supports infinite rotation (tiltRotate attribute).
    public var tiltInfinite: Bool = false

    public init(panRange: ClosedRange<Double>? = nil, panInfinite: Bool = false,
                tiltRange: ClosedRange<Double>? = nil, tiltInfinite: Bool = false) {
        self.panRange = panRange
        self.panInfinite = panInfinite
        self.tiltRange = tiltRange
        self.tiltInfinite = tiltInfinite
    }
}

/// A node in the assembled fixture hierarchy.
public struct AssembledNode: Sendable {
    /// Name from the GDTF geometry (e.g. "Base", "Yoke", "Head").
    public var name: String
    /// Local transform relative to parent (position only).
    /// Affects both this node's mesh and all children.
    public var localTransform: simd_float4x4
    /// Transform applied only to the mesh, not to children.
    /// Contains mesh scaling and coordinate conversion.
    public var meshLocalTransform: simd_float4x4?
    /// Mesh data, if this geometry has a model. Nil for pure grouping nodes.
    public var meshData: MeshData?
    /// Child nodes in the geometry hierarchy.
    public var children: [AssembledNode]
    /// Pan/tilt axis info if this geometry has DMX pan/tilt channels.
    public var axisInfo: GeometryAxisInfo?
}

/// Top-level output of the assembler.
public struct AssembledFixture: Sendable {
    /// Root node of the assembled hierarchy.
    public var root: AssembledNode
    /// World AABB before normalization.
    public var worldBounds: MeshBoundingBox
}

// MARK: - Conversion helpers

extension ThreeDSFile {
    /// Converts all non-degenerate objects to renderer-agnostic mesh data.
    func toMeshData(includeMarkers: Bool = false) -> MeshData {
        var submeshes: [MeshData.Submesh] = []
        for object in objects {
            guard !object.vertices.isEmpty, !object.faces.isEmpty else { continue }
            if !includeMarkers && object.isDegenerateMarker { continue }
            submeshes.append(MeshData.Submesh(
                name: object.name,
                vertices: object.vertices,
                normals: [],
                textureCoordinates: object.textureCoordinates,
                faceIndices: object.faces.map { SIMD3<UInt32>(UInt32($0.x), UInt32($0.y), UInt32($0.z)) }
            ))
        }
        return MeshData(submeshes: submeshes)
    }

    /// Bounding box across ALL objects (including degenerate markers).
    func fullBoundingBox() -> MeshBoundingBox {
        var mn = SIMD3<Float>(repeating:  Float.infinity)
        var mx = SIMD3<Float>(repeating: -Float.infinity)
        for object in objects {
            for v in object.vertices {
                mn = simd_min(mn, v)
                mx = simd_max(mx, v)
            }
        }
        return MeshBoundingBox(min: mn, max: mx)
    }
}

extension GLBFile {
    /// Converts all objects to renderer-agnostic mesh data.
    func toMeshData() -> MeshData {
        var submeshes: [MeshData.Submesh] = []
        for object in objects {
            guard !object.vertices.isEmpty, !object.faces.isEmpty else { continue }
            submeshes.append(MeshData.Submesh(
                name: object.name,
                vertices: object.vertices,
                normals: object.normals,
                textureCoordinates: object.textureCoordinates,
                faceIndices: object.faces
            ))
        }
        return MeshData(submeshes: submeshes)
    }
}

// MARK: - MeshData bounding box

extension MeshData {
    /// Computes the AABB across all submeshes.
    func boundingBox() -> MeshBoundingBox {
        var mn = SIMD3<Float>(repeating:  Float.infinity)
        var mx = SIMD3<Float>(repeating: -Float.infinity)
        for sub in submeshes {
            for v in sub.vertices {
                mn = simd_min(mn, v)
                mx = simd_max(mx, v)
            }
        }
        return MeshBoundingBox(min: mn, max: mx)
    }
}

// MARK: - FixtureGeometryAssembler

/// Assembles a renderer-agnostic geometry tree for a GDTF fixture.
public struct FixtureGeometryAssembler {
    public let gdtf: GDTF
    public let gdtfData: Data

    public init(gdtf: GDTF, gdtfData: Data) {
        self.gdtf = gdtf
        self.gdtfData = gdtfData
    }

    /// Assembles the fixture geometry tree.
    ///
    /// - Parameters:
    ///   - rootGeometryName: Name of the top-level geometry to use as root.
    ///     Pass `nil` to use the first top-level geometry.
    ///   - dmxMode: Optional DMX mode to extract per-geometry pan/tilt axis info.
    ///     When provided, the mode is resolved and axis info is attached to matching nodes.
    ///   - normalize: If `true`, scales the root so the longest AABB axis == 1
    ///     and centres the fixture at the origin.
    /// - Returns: The assembled fixture, or `nil` if no geometry is found.
    public func assemble(rootGeometryName: String? = nil,
                         dmxMode: DMXMode? = nil,
                         normalize: Bool = true) -> AssembledFixture? {
        let topLevel = gdtf.fixtureType.geometries

        let topLevelMap: [String: Geometry] = Dictionary(
            topLevel.map { ($0.name, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        let modelMap: [String: GDTFModel] = Dictionary(
            gdtf.fixtureType.models.map { ($0.name, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        let rootGeometry: Geometry
        if let name = rootGeometryName, let found = topLevelMap[name] {
            rootGeometry = found
        } else if let first = topLevel.first {
            rootGeometry = first
        } else {
            return nil
        }

        // Build per-geometry axis info map from DMX mode if provided.
        let axisInfoMap: [String: GeometryAxisInfo]
        if let dmxMode {
            let resolved = dmxMode.resolved(with: topLevel)
            axisInfoMap = resolved.geometryAxisInfoMap()
        } else {
            axisInfoMap = [:]
        }

        let context = AssemblyContext(gdtfData: gdtfData, modelMap: modelMap,
                                       topLevelMap: topLevelMap, axisInfoMap: axisInfoMap)

        // Walk the root geometry to produce a hierarchical tree.
        guard let rootGeoNode = context.walk(rootGeometry, modelOverride: nil, depth: 0) else {
            return nil
        }

        // GDTF uses Z-up; we convert to Y-up (SceneKit / Metal convention).
        // (x, y, z)_GDTF → (x, z, -y)_SceneKit
        let gdtfToSceneKit = simd_float4x4(
            SIMD4<Float>(1, 0,  0, 0),
            SIMD4<Float>(0, 0, -1, 0),
            SIMD4<Float>(0, 1,  0, 0),
            SIMD4<Float>(0, 0,  0, 1)
        )

        // Pre-normalization world AABB (gdtfToSceneKit is part of the root)
        var worldBounds = MeshBoundingBox.empty
        computeWorldBounds(node: rootGeoNode, parentTransform: gdtfToSceneKit, bounds: &worldBounds)

        var rootTransform = gdtfToSceneKit
        if normalize {
            let span = worldBounds.span
            let maxDim = Swift.max(span.x, Swift.max(span.y, span.z))
            if maxDim > 0 {
                let s = 1.0 / maxDim
                let centre = (worldBounds.min + worldBounds.max) * 0.5
                // normalization * gdtfToSceneKit
                let normalization = simd_float4x4(diagonal: SIMD4(s, s, s, 1)) * simd_float4x4(columns: (
                    SIMD4<Float>(1, 0, 0, 0),
                    SIMD4<Float>(0, 1, 0, 0),
                    SIMD4<Float>(0, 0, 1, 0),
                    SIMD4<Float>(-centre.x, -centre.y, -centre.z, 1)
                ))
                rootTransform = normalization * gdtfToSceneKit
            }
        }

        let root = AssembledNode(
            name: rootGeometry.name,
            localTransform: rootTransform,
            meshLocalTransform: nil,
            meshData: nil,
            children: [rootGeoNode]
        )

        return AssembledFixture(root: root, worldBounds: worldBounds)
    }

    /// Recursively computes the world AABB across all mesh nodes.
    private func computeWorldBounds(node: AssembledNode,
                                     parentTransform: simd_float4x4,
                                     bounds: inout MeshBoundingBox) {
        let worldTransform = parentTransform * node.localTransform
        if let meshData = node.meshData {
            let meshWorldTransform = worldTransform * (node.meshLocalTransform ?? .init(1))
            let localBB = meshData.boundingBox()
            let worldBB = localBB.transformed(by: meshWorldTransform)
            bounds.formUnion(worldBB)
        }
        for child in node.children {
            computeWorldBounds(node: child, parentTransform: worldTransform, bounds: &bounds)
        }
    }
}

// MARK: - Assembly context (internal)

extension FixtureGeometryAssembler {

    /// Whether a mesh's vertices are in Y-up (glTF/.glb) coordinate space.
    private typealias IsYUp = Bool

    struct AssemblyContext {
        let gdtfData: Data
        let modelMap: [String: GDTFModel]
        let topLevelMap: [String: Geometry]
        let axisInfoMap: [String: GeometryAxisInfo]

        /// Converts Y-up → Z-up: (x, y, z)_SceneKit → (x, -z, y)_GDTF.
        let sceneKitToGdtf = simd_float4x4(
            SIMD4<Float>(1,  0, 0, 0),
            SIMD4<Float>(0,  0, 1, 0),
            SIMD4<Float>(0, -1, 0, 0),
            SIMD4<Float>(0,  0, 0, 1)
        )

        /// Walks a geometry and its children, returning a single hierarchical node.
        ///
        /// Each node's `localTransform` is the geometry's position matrix.
        /// The `meshLocalTransform` (scaling + optional coord conversion) only
        /// applies to the mesh, not to child positions.
        func walk(
            _ geometry: Geometry,
            modelOverride: String?,
            depth: Int
        ) -> AssembledNode? {
            guard depth < 64 else { return nil }

            switch geometry {
            case .reference(let ref):
                return walkReference(ref, depth: depth)
            default:
                let position = geometry.position.matrix.float4x4

                // Try to extract mesh data and compute its local transform
                var meshData: MeshData? = nil
                var meshLocalTransform: simd_float4x4? = nil

                let modelName = modelOverride ?? geometry.model
                if let modelName, let gdtfModel = modelMap[modelName],
                   let (mesh, isYUp, bbOverride) = extractMesh(gdtfModel: gdtfModel) {
                    meshData = mesh
                    if isYUp {
                        let scaleInZUp = meshScaleMatrix(gdtfModel: gdtfModel, meshBounds: mesh.boundingBox(),
                                                          coordRotation: sceneKitToGdtf,
                                                          boundingBoxOverride: bbOverride)
                        meshLocalTransform = scaleInZUp * sceneKitToGdtf
                    } else {
                        let scale = meshScaleMatrix(gdtfModel: gdtfModel, meshBounds: mesh.boundingBox(),
                                                      coordRotation: nil,
                                                      boundingBoxOverride: bbOverride)
                        meshLocalTransform = scale
                    }
                }

                // Recurse into children
                var childNodes: [AssembledNode] = []
                for child in geometry.children {
                    if let childNode = walk(child, modelOverride: nil, depth: depth + 1) {
                        childNodes.append(childNode)
                    }
                }

                // Only create a node if we have mesh or children
                guard meshData != nil || !childNodes.isEmpty else { return nil }

                return AssembledNode(
                    name: geometry.name,
                    localTransform: position,
                    meshLocalTransform: meshLocalTransform,
                    meshData: meshData,
                    children: childNodes,
                    axisInfo: axisInfoMap[geometry.name]
                )
            }
        }

        private func walkReference(
            _ ref: GeometryReference,
            depth: Int
        ) -> AssembledNode? {
            guard let targetName = ref.geometry,
                  let target = topLevelMap[targetName] else { return nil }

            let refPosition = ref.position.matrix.float4x4

            // Walk the target geometry as a subtree under this reference's position.
            guard let targetNode = walk(target, modelOverride: ref.model, depth: depth + 1) else {
                return nil
            }

            return AssembledNode(
                name: ref.name,
                localTransform: refPosition,
                meshLocalTransform: nil,
                meshData: nil,
                children: [targetNode],
                axisInfo: axisInfoMap[ref.name]
            )
        }

        /// Result type for mesh extraction.
        private typealias MeshResult = (MeshData, IsYUp, MeshBoundingBox?)

        /// Extracts mesh data for a model, trying .3ds → .glb → primitive.
        private func extractMesh(gdtfModel: GDTFModel) -> MeshResult? {
            // .3ds — always Z-up
            for lod in GDTFModel.LOD.allCases {
                if let data = gdtfModel.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod),
                   let file = try? ThreeDSFile.parse(data: data) {
                    let meshData = file.toMeshData()
                    let bbOverride = file.objects.contains(where: \.isDegenerateMarker)
                        ? file.fullBoundingBox()
                        : nil
                    return (meshData, false, bbOverride)
                }
            }
            // .glb — always Y-up
            for lod in GDTFModel.LOD.allCases {
                if let data = gdtfModel.resolveFile(gdtf: gdtfData, format: .glb, lod: lod),
                   let file = try? GLBFile.parse(data: data) {
                    let meshData = file.toMeshData()
                    return (meshData, true, nil)
                }
            }
            // Primitive type — Z-up
            if gdtfModel.primitiveType != .undefined,
               let meshData = makePrimitiveMeshData(gdtfModel.primitiveType) {
                return (meshData, false, nil)
            }
            return nil
        }

        /// Builds a scale matrix that makes the mesh match declared dimensions.
        private func meshScaleMatrix(gdtfModel: GDTFModel, meshBounds: MeshBoundingBox,
                                     coordRotation: simd_float4x4?,
                                     boundingBoxOverride: MeshBoundingBox? = nil) -> simd_float4x4 {
            let bb = boundingBoxOverride ?? meshBounds

            let meshSpan: SIMD3<Double>
            if let rot = coordRotation {
                let rotated = bb.transformed(by: rot)
                meshSpan = SIMD3<Double>(
                    Double(rotated.span.x),
                    Double(rotated.span.y),
                    Double(rotated.span.z)
                )
            } else {
                meshSpan = SIMD3<Double>(
                    Double(bb.span.x),
                    Double(bb.span.y),
                    Double(bb.span.z)
                )
            }

            let declared = SIMD3<Double>(gdtfModel.length, gdtfModel.width, gdtfModel.height)
            let minSpan = 1e-9

            var fallbackScale = 0.001
            for i in 0..<3 {
                if declared[i] > 0 && meshSpan[i] > minSpan {
                    fallbackScale = declared[i] / meshSpan[i]
                    break
                }
            }

            var scale = SIMD3<Double>(repeating: fallbackScale)
            for i in 0..<3 {
                if declared[i] > 0 && meshSpan[i] > minSpan {
                    scale[i] = declared[i] / meshSpan[i]
                }
            }

            return simd_float4x4(diagonal: SIMD4<Float>(Float(scale.x), Float(scale.y), Float(scale.z), 1))
        }

        // MARK: - Primitive mesh generation

        /// Creates renderer-agnostic mesh data for a GDTF primitive type.
        private func makePrimitiveMeshData(_ primitiveType: PrimitiveType) -> MeshData? {
            switch primitiveType {
            case .undefined:
                return nil
            case .cube:
                return Self.makeCubeMeshData()
            case .cylinder, .pigtail:
                return Self.makeCylinderMeshData()
            case .sphere:
                return Self.makeSphereMeshData()
            case .base:          return Self.loadBundledPrimitiveMesh("base")
            case .yoke:          return Self.loadBundledPrimitiveMesh("yoke")
            case .head:          return Self.loadBundledPrimitiveMesh("head")
            case .scanner:       return Self.loadBundledPrimitiveMesh("scanner")
            case .conventional:  return Self.loadBundledPrimitiveMesh("conventional")
            case .base1_1:       return Self.loadBundledPrimitiveMesh("base_1_1")
            case .scanner1_1:    return Self.loadBundledPrimitiveMesh("scanner_1_1")
            case .conventional1_1: return Self.loadBundledPrimitiveMesh("conventional_1_1")
            }
        }

        private static func loadBundledPrimitiveMesh(_ name: String) -> MeshData? {
            guard let url = Bundle.module.url(forResource: name, withExtension: "3ds"),
                  let data = try? Data(contentsOf: url),
                  let file = try? ThreeDSFile.parse(data: data) else {
                return nil
            }
            return file.toMeshData()
        }

        // MARK: Procedural primitives

        /// Unit cube centered at origin, 24 vertices (4 per face, flat normals).
        private static func makeCubeMeshData() -> MeshData {
            // 6 faces, each with 4 vertices and 2 triangles
            var verts: [SIMD3<Float>] = []
            var norms: [SIMD3<Float>] = []
            var faces: [SIMD3<UInt32>] = []

            let h: Float = 0.5
            let faceData: [(normal: SIMD3<Float>, corners: [SIMD3<Float>])] = [
                // +X
                (SIMD3( 1, 0, 0), [SIMD3( h,-h,-h), SIMD3( h, h,-h), SIMD3( h, h, h), SIMD3( h,-h, h)]),
                // -X
                (SIMD3(-1, 0, 0), [SIMD3(-h, h,-h), SIMD3(-h,-h,-h), SIMD3(-h,-h, h), SIMD3(-h, h, h)]),
                // +Y
                (SIMD3( 0, 1, 0), [SIMD3(-h, h,-h), SIMD3(-h, h, h), SIMD3( h, h, h), SIMD3( h, h,-h)]),
                // -Y
                (SIMD3( 0,-1, 0), [SIMD3(-h,-h, h), SIMD3(-h,-h,-h), SIMD3( h,-h,-h), SIMD3( h,-h, h)]),
                // +Z
                (SIMD3( 0, 0, 1), [SIMD3(-h,-h, h), SIMD3( h,-h, h), SIMD3( h, h, h), SIMD3(-h, h, h)]),
                // -Z
                (SIMD3( 0, 0,-1), [SIMD3( h,-h,-h), SIMD3(-h,-h,-h), SIMD3(-h, h,-h), SIMD3( h, h,-h)]),
            ]

            for (normal, corners) in faceData {
                let base = UInt32(verts.count)
                verts.append(contentsOf: corners)
                norms.append(contentsOf: [normal, normal, normal, normal])
                faces.append(SIMD3(base, base + 1, base + 2))
                faces.append(SIMD3(base, base + 2, base + 3))
            }

            return MeshData(submeshes: [MeshData.Submesh(
                name: "Cube",
                vertices: verts,
                normals: norms,
                textureCoordinates: [],
                faceIndices: faces
            )])
        }

        /// Cylinder with radius 0.5, height 1, along Z axis (Z-up).
        /// 32 segments with top and bottom caps.
        private static func makeCylinderMeshData() -> MeshData {
            let segments = 32
            let radius: Float = 0.5
            let halfH: Float = 0.5

            var verts: [SIMD3<Float>] = []
            var norms: [SIMD3<Float>] = []
            var faces: [SIMD3<UInt32>] = []

            // Side vertices: 2 rings
            for i in 0...segments {
                let angle = Float(i) / Float(segments) * 2 * .pi
                let x = radius * cos(angle)
                let y = radius * sin(angle)
                let n = SIMD3<Float>(cos(angle), sin(angle), 0)
                // Bottom ring
                verts.append(SIMD3(x, y, -halfH))
                norms.append(n)
                // Top ring
                verts.append(SIMD3(x, y, halfH))
                norms.append(n)
            }

            // Side faces
            for i in 0..<segments {
                let bl = UInt32(i * 2)
                let br = UInt32(i * 2 + 2)
                let tl = bl + 1
                let tr = br + 1
                faces.append(SIMD3(bl, br, tl))
                faces.append(SIMD3(tl, br, tr))
            }

            // Bottom cap
            let bottomCenter = UInt32(verts.count)
            verts.append(SIMD3(0, 0, -halfH))
            norms.append(SIMD3(0, 0, -1))
            for i in 0..<segments {
                let angle1 = Float(i) / Float(segments) * 2 * .pi
                let angle2 = Float(i + 1) / Float(segments) * 2 * .pi
                let v1 = UInt32(verts.count)
                verts.append(SIMD3(radius * cos(angle1), radius * sin(angle1), -halfH))
                norms.append(SIMD3(0, 0, -1))
                let v2 = UInt32(verts.count)
                verts.append(SIMD3(radius * cos(angle2), radius * sin(angle2), -halfH))
                norms.append(SIMD3(0, 0, -1))
                faces.append(SIMD3(bottomCenter, v2, v1))
            }

            // Top cap
            let topCenter = UInt32(verts.count)
            verts.append(SIMD3(0, 0, halfH))
            norms.append(SIMD3(0, 0, 1))
            for i in 0..<segments {
                let angle1 = Float(i) / Float(segments) * 2 * .pi
                let angle2 = Float(i + 1) / Float(segments) * 2 * .pi
                let v1 = UInt32(verts.count)
                verts.append(SIMD3(radius * cos(angle1), radius * sin(angle1), halfH))
                norms.append(SIMD3(0, 0, 1))
                let v2 = UInt32(verts.count)
                verts.append(SIMD3(radius * cos(angle2), radius * sin(angle2), halfH))
                norms.append(SIMD3(0, 0, 1))
                faces.append(SIMD3(topCenter, v1, v2))
            }

            return MeshData(submeshes: [MeshData.Submesh(
                name: "Cylinder",
                vertices: verts,
                normals: norms,
                textureCoordinates: [],
                faceIndices: faces
            )])
        }

        /// UV sphere with radius 0.5, 16×16 segments.
        private static func makeSphereMeshData() -> MeshData {
            let stacks = 16
            let slices = 16
            let radius: Float = 0.5

            var verts: [SIMD3<Float>] = []
            var norms: [SIMD3<Float>] = []
            var faces: [SIMD3<UInt32>] = []

            for stack in 0...stacks {
                let phi = Float(stack) / Float(stacks) * .pi
                for slice in 0...slices {
                    let theta = Float(slice) / Float(slices) * 2 * .pi
                    let x = sin(phi) * cos(theta)
                    let y = sin(phi) * sin(theta)
                    let z = cos(phi)
                    verts.append(SIMD3(radius * x, radius * y, radius * z))
                    norms.append(SIMD3(x, y, z))
                }
            }

            for stack in 0..<stacks {
                for slice in 0..<slices {
                    let first = UInt32(stack * (slices + 1) + slice)
                    let second = first + UInt32(slices + 1)
                    faces.append(SIMD3(first, second, first + 1))
                    faces.append(SIMD3(first + 1, second, second + 1))
                }
            }

            return MeshData(submeshes: [MeshData.Submesh(
                name: "Sphere",
                vertices: verts,
                normals: norms,
                textureCoordinates: [],
                faceIndices: faces
            )])
        }
    }
}

// MARK: - Internal helpers promoted from ThreeDSView

extension simd_double4x4 {
    /// Lossy conversion to single-precision.
    var float4x4: simd_float4x4 {
        simd_float4x4(columns: (
            simd_float4(Float(self[0,0]), Float(self[0,1]), Float(self[0,2]), Float(self[0,3])),
            simd_float4(Float(self[1,0]), Float(self[1,1]), Float(self[1,2]), Float(self[1,3])),
            simd_float4(Float(self[2,0]), Float(self[2,1]), Float(self[2,2]), Float(self[2,3])),
            simd_float4(Float(self[3,0]), Float(self[3,1]), Float(self[3,2]), Float(self[3,3]))
        ))
    }
}

extension ThreeDSObject {
    /// Whether this object is a degenerate single-triangle marker.
    var isDegenerateMarker: Bool {
        guard vertices.count == 3, faces.count == 1 else { return false }
        let e1 = vertices[1] - vertices[0]
        let e2 = vertices[2] - vertices[0]
        return simd_length(simd_cross(e1, e2)) < 1e-6
    }
}
