//
//  ThreeDSView.swift
//  SwiftGDTF
//
//  Two rendering modes:
//
//  • ThreeDSView — renders a single parsed ThreeDSFile (unchanged).
//
//  • GDTFFixtureView — assembles a full fixture by walking the GDTF
//    geometry tree, resolving GeometryReference nodes, looking up each
//    geometry's GDTFModel, extracting the matching .3ds or .glb file from
//    the GDTF ZIP, and building an SCNNode hierarchy with each geometry's
//    Position matrix applied as the node transform.
//
//  The scene is lit with a key + fill + ambient rig so the mesh is always
//  visible even without texture maps.  The user can orbit / zoom with
//  standard SceneKit camera controls.
//

import SwiftUI
import SceneKit

// MARK: - Platform colour alias

#if canImport(AppKit)
import AppKit
private typealias PlatformColor = NSColor
private typealias PlatformViewRepresentable = NSViewRepresentable
#elseif canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
private typealias PlatformViewRepresentable = UIViewRepresentable
#endif

// MARK: - SCNGeometry builder

extension ThreeDSFile {
    /// Converts this file into an `SCNNode` hierarchy that SceneKit can render.
    ///
    /// Each `ThreeDSObject` becomes a child node.  The whole scene is
    /// uniformly scaled so its bounding box fits inside a unit cube centred
    /// at the origin — this makes camera framing simple regardless of the
    /// original model units.
    public func sceneNode() -> SCNNode {
        let root = sceneNodeRaw()

        // Normalise: scale so the longest bounding-box axis == 1, then centre.
        let (minV, maxV) = root.boundingBox
        let spanX = maxV.x - minV.x
        let spanY = maxV.y - minV.y
        let spanZ = maxV.z - minV.z
        let maxDim = max(spanX, max(spanY, spanZ))
        if maxDim > 0 {
            let s = CGFloat(1.0) / CGFloat(maxDim)
            root.scale = SCNVector3(s, s, s)
            let cx = -(CGFloat(minV.x + maxV.x) / 2) * s
            let cy = -(CGFloat(minV.y + maxV.y) / 2) * s
            let cz = -(CGFloat(minV.z + maxV.z) / 2) * s
            root.position = SCNVector3(cx, cy, cz)
        }

        return root
    }

    /// Like `sceneNode()` but without the normalisation step.
    /// Used by `FixtureSceneBuilder` when assembling multi-geometry fixtures,
    /// where normalisation is applied once at the root level.
    func sceneNodeRaw() -> SCNNode {
        let root = SCNNode()

        let materialMap = Dictionary(
            materials.map { ($0.name, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        for object in objects {
            guard !object.vertices.isEmpty, !object.faces.isEmpty else { continue }

            // --- Vertex positions ---
            let positionSource = SCNGeometrySource(
                vertices: object.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
            )

            // --- Face indices ---
            var indices: [Int32] = []
            indices.reserveCapacity(object.faces.count * 3)
            for face in object.faces {
                indices.append(Int32(face.x))
                indices.append(Int32(face.y))
                indices.append(Int32(face.z))
            }
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

            // --- Sources ---
            var sources: [SCNGeometrySource] = [positionSource]

            // --- UV texture coordinates (optional, must match vertex count) ---
            if object.textureCoordinates.count == object.vertices.count {
                let uvData = object.textureCoordinates.withUnsafeBytes { Data($0) }
                let uvSource = SCNGeometrySource(
                    data: uvData,
                    semantic: .texcoord,
                    vectorCount: object.textureCoordinates.count,
                    usesFloatComponents: true,
                    componentsPerVector: 2,
                    bytesPerComponent: MemoryLayout<Float>.size,
                    dataOffset: 0,
                    dataStride: MemoryLayout<SIMD2<Float>>.stride
                )
                sources.append(uvSource)
            }

            let geometry = SCNGeometry(sources: sources, elements: [element])

            // --- Material ---
            let scnMaterial = SCNMaterial()
            scnMaterial.lightingModel = .phong
            scnMaterial.isDoubleSided = true

//            if let matName = object.materialName, let mat = materialMap[matName] {
//                scnMaterial.diffuse.contents = mat.diffuseColor.map {
//                    // Apply a minimum brightness so very dark fixtures are still
//                    // visible in the preview.  Preserves the hue of the original.
//                    let minBrightness: Float = 0.15
//                    let r = max($0.x, minBrightness)
//                    let g = max($0.y, minBrightness)
//                    let b = max($0.z, minBrightness)
//                    return PlatformColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
//                } ?? PlatformColor(white: 0.05, alpha: 1)
//                if let a = mat.ambientColor {
//                    scnMaterial.ambient.contents = PlatformColor(
//                        red: CGFloat(a.x), green: CGFloat(a.y), blue: CGFloat(a.z), alpha: 1
//                    )
//                }
//                if let s = mat.specularColor {
//                    scnMaterial.specular.contents = PlatformColor(
//                        red: CGFloat(s.x), green: CGFloat(s.y), blue: CGFloat(s.z), alpha: 1
//                    )
//                }
//            } else {
//                scnMaterial.diffuse.contents = PlatformColor(white: 0.2, alpha: 1)
//            }
            scnMaterial.diffuse.contents = PlatformColor(white: 0.2, alpha: 1)
            scnMaterial.specular.contents = PlatformColor(white: 0.4, alpha: 1)
            
            geometry.materials = [scnMaterial]

            let node = SCNNode(geometry: geometry)
            node.name = object.name
            root.addChildNode(node)
        }

        return root
    }
}

extension GLBFile {
    /// Converts this GLB file into an `SCNNode` hierarchy, one child per
    /// mesh primitive.  No normalisation — the caller handles that.
    func sceneNodeRaw() -> SCNNode {
        let root = SCNNode()

        for object in objects {
            guard !object.vertices.isEmpty, !object.faces.isEmpty else { continue }

            // --- Vertex positions ---
            let positionSource = SCNGeometrySource(
                vertices: object.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
            )

            // --- Face indices ---
            var indices: [Int32] = []
            indices.reserveCapacity(object.faces.count * 3)
            for face in object.faces {
                indices.append(Int32(face.x))
                indices.append(Int32(face.y))
                indices.append(Int32(face.z))
            }
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

            // --- Sources ---
            var sources: [SCNGeometrySource] = [positionSource]

            // --- Normals (optional, must match vertex count) ---
            if object.normals.count == object.vertices.count {
                let normalSource = SCNGeometrySource(
                    normals: object.normals.map { SCNVector3($0.x, $0.y, $0.z) }
                )
                sources.append(normalSource)
            }

            // --- UV texture coordinates (optional, must match vertex count) ---
            if object.textureCoordinates.count == object.vertices.count {
                let uvData = object.textureCoordinates.withUnsafeBytes { Data($0) }
                let uvSource = SCNGeometrySource(
                    data: uvData,
                    semantic: .texcoord,
                    vectorCount: object.textureCoordinates.count,
                    usesFloatComponents: true,
                    componentsPerVector: 2,
                    bytesPerComponent: MemoryLayout<Float>.size,
                    dataOffset: 0,
                    dataStride: MemoryLayout<SIMD2<Float>>.stride
                )
                sources.append(uvSource)
            }

            let geometry = SCNGeometry(sources: sources, elements: [element])

            // --- Material ---
            let scnMaterial = SCNMaterial()
            scnMaterial.lightingModel = .phong
            scnMaterial.isDoubleSided = true
            scnMaterial.diffuse.contents = PlatformColor(white: 0.2, alpha: 1)
            scnMaterial.specular.contents = PlatformColor(white: 0.4, alpha: 1)

            geometry.materials = [scnMaterial]

            let node = SCNNode(geometry: geometry)
            node.name = object.name
            root.addChildNode(node)
        }

        return root
    }
}

extension simd_double4x4 {
    /// Lossy conversion to single-precision for use with SceneKit / SIMD APIs.
    fileprivate var float4x4: simd_float4x4 {
        simd_float4x4(columns: (
            simd_float4(Float(self[0,0]), Float(self[0,1]), Float(self[0,2]), Float(self[0,3])),
            simd_float4(Float(self[1,0]), Float(self[1,1]), Float(self[1,2]), Float(self[1,3])),
            simd_float4(Float(self[2,0]), Float(self[2,1]), Float(self[2,2]), Float(self[2,3])),
            simd_float4(Float(self[3,0]), Float(self[3,1]), Float(self[3,2]), Float(self[3,3]))
        ))
    }
}



extension Matrix {
    /// Converts the GDTF 4×4 transform matrix to an `SCNMatrix4`.
    ///
    /// The GDTF `Matrix` stores a `simd_double4x4` where each raw data row
    /// becomes a SIMD column (no rotation transposition).  Translation is
    /// in column 3.  `matrix[col, row]` gives the element at that column
    /// and row.
    ///
    /// `SCNMatrix4` uses the same column-major convention as SIMD, so we
    /// convert via `simd_float4x4` and let `SCNMatrix4.init` copy the
    /// columns directly.
    var scnMatrix4: SCNMatrix4 {
        SCNMatrix4(matrix.float4x4)
    }
}

// MARK: - Fixture scene builder

/// Assembles an `SCNNode` hierarchy for a GDTF fixture by walking the geometry
/// tree, resolving `GeometryReference` nodes, and attaching the corresponding
/// `.3ds` or `.glb` mesh to each node.
public struct FixtureSceneBuilder {
    /// The parsed GDTF descriptor.
    public let gdtf: GDTF
    /// The raw GDTF ZIP bytes (used to extract model files).
    public let gdtfData: Data

    public init(gdtf: GDTF, gdtfData: Data) {
        self.gdtf = gdtf
        self.gdtfData = gdtfData
    }

    // MARK: - Public API

    /// Builds an `SCNNode` subtree for the named root geometry.
    ///
    /// - Parameter rootGeometryName: Name of the top-level geometry to use as
    ///   the root.  Pass `nil` to use the first top-level geometry.
    /// - Returns: A node whose children mirror the geometry tree, with mesh
    ///   data attached where available.  Returns an empty node if the named
    ///   geometry is not found.
    public func buildNode(rootGeometryName: String? = nil) -> SCNNode {
        let topLevel = gdtf.fixtureType.geometries

        // Build lookup: name → top-level Geometry (for reference resolution)
        let topLevelMap: [String: Geometry] = Dictionary(
            topLevel.map { ($0.name, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        // Build lookup: model name → GDTFModel
        let modelMap: [String: GDTFModel] = Dictionary(
            gdtf.fixtureType.models.map { ($0.name, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        // Find the requested root geometry
        let rootGeometry: Geometry
        if let name = rootGeometryName, let found = topLevelMap[name] {
            rootGeometry = found
        } else if let first = topLevel.first {
            rootGeometry = first
        } else {
            return SCNNode()
        }

        let context = BuildContext(gdtfData: gdtfData, modelMap: modelMap, topLevelMap: topLevelMap)

        // GDTF uses Z-up (X right, Y into screen, Z up).
        // SceneKit uses Y-up (X right, Y up, Z toward camera).
        // Mapping: (x, y, z)_GDTF → (x, z, -y)_SceneKit
        let gdtfToSceneKit = simd_float4x4(
            SIMD4<Float>(1, 0,  0, 0),
            SIMD4<Float>(0, 0, -1, 0),
            SIMD4<Float>(0, 1,  0, 0),
            SIMD4<Float>(0, 0,  0, 1)
        )

        let root = SCNNode()
        root.name = rootGeometry.name
        context.walk(rootGeometry, worldTransform: gdtfToSceneKit,
                     into: root, modelOverride: nil, depth: 0)

        // Normalise: scale so the longest AABB axis == 1, then centre.
        let (worldMin, worldMax) = worldAABB(root)
        let span = worldMax - worldMin
        let maxDim = span.max()
        if maxDim > 0 {
            let s = CGFloat(1.0 / maxDim)
            let centre = (worldMin + worldMax) * 0.5
            root.scale = SCNVector3(s, s, s)
            root.simdPosition = simd_float3(
                -centre.x * Float(s),
                -centre.y * Float(s),
                -centre.z * Float(s)
            )
        }

        return root
    }

    // MARK: - AABB helpers

    /// Computes the world-space axis-aligned bounding box of all geometry
    /// nodes in the subtree rooted at `node`.
    private func worldAABB(_ node: SCNNode) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        var wMin = SIMD3<Float>(repeating:  Float.infinity)
        var wMax = SIMD3<Float>(repeating: -Float.infinity)

        func accumulate(_ n: SCNNode) {
            if n.geometry != nil {
                let (localMin, localMax) = n.boundingBox
                let wt = n.simdWorldTransform
                for dx in [Float(localMin.x), Float(localMax.x)] {
                    for dy in [Float(localMin.y), Float(localMax.y)] {
                        for dz in [Float(localMin.z), Float(localMax.z)] {
                            let wp = wt * SIMD4<Float>(dx, dy, dz, 1)
                            wMin = min(wMin, SIMD3(wp.x, wp.y, wp.z))
                            wMax = max(wMax, SIMD3(wp.x, wp.y, wp.z))
                        }
                    }
                }
            }
            for child in n.childNodes { accumulate(child) }
        }
        accumulate(node)
        return (wMin, wMax)
    }

    // MARK: - Build context (captures shared state)

    private struct BuildContext {
        let gdtfData: Data
        let modelMap: [String: GDTFModel]
        let topLevelMap: [String: Geometry]

        /// Inverse of gdtfToSceneKit.  Converts SceneKit Y-up back to GDTF
        /// Z-up: (x, y, z)_SceneKit → (x, -z, y)_GDTF.
        /// Applied to GLB mesh nodes whose vertices are Y-up, so that
        /// the root gdtfToSceneKit transform cancels out.
        let sceneKitToGdtf = simd_float4x4(
            SIMD4<Float>(1,  0, 0, 0),
            SIMD4<Float>(0,  0, 1, 0),
            SIMD4<Float>(0, -1, 0, 0),
            SIMD4<Float>(0,  0, 0, 1)
        )

        /// Whether a mesh's vertices are in Z-up (GDTF/.3ds) or Y-up (glTF)
        /// coordinate space.
        private enum MeshCoordSystem { case zUp, yUp }

        /// Walks `geometry` and its children, adding mesh nodes to `root`.
        ///
        /// Per the GDTF spec, each geometry's Position matrix defines its
        /// offset relative to its parent.  The mesh is scaled per-axis to
        /// match the model's declared Length (X), Width (Y), Height (Z)
        /// dimensions in metres.
        func walk(
            _ geometry: Geometry,
            worldTransform: simd_float4x4,
            into root: SCNNode,
            modelOverride: String?,
            depth: Int
        ) {
            guard depth < 64 else { return }

            switch geometry {
            case .reference(let ref):
                walkReference(ref, parentTransform: worldTransform, into: root,
                              depth: depth)
            default:
                let combined = worldTransform * geometry.position.matrix.float4x4

                let modelName = modelOverride ?? geometry.model
                if let modelName, let gdtfModel = modelMap[modelName],
                   let (meshNode, coordSystem) = makeMeshNode(gdtfModel: gdtfModel) {
                    if coordSystem == .yUp {
                        // GLB vertices are Y-up.  First convert to Z-up via
                        // sceneKitToGdtf, then scale using Z-up declared
                        // dimensions.  The walk's worldTransform already
                        // includes gdtfToSceneKit which converts back to
                        // SceneKit Y-up for rendering.
                        let scaleInZUp = meshScaleMatrix(gdtfModel: gdtfModel, meshNode: meshNode,
                                                         coordRotation: sceneKitToGdtf)
                        meshNode.simdTransform = combined * scaleInZUp * sceneKitToGdtf
                    } else {
                        let scale = meshScaleMatrix(gdtfModel: gdtfModel, meshNode: meshNode,
                                                     coordRotation: nil)
                        meshNode.simdTransform = combined * scale
                    }
                    root.addChildNode(meshNode)
                }

                for child in geometry.children {
                    walk(child, worldTransform: combined, into: root,
                         modelOverride: nil, depth: depth + 1)
                }
            }
        }

        private func walkReference(
            _ ref: GeometryReference,
            parentTransform: simd_float4x4,
            into root: SCNNode,
            depth: Int
        ) {
            guard let targetName = ref.geometry,
                  let target = topLevelMap[targetName] else { return }

            let combined = parentTransform * ref.position.matrix.float4x4

            let tempRoot = SCNNode()
            walk(target, worldTransform: combined,
                 into: tempRoot, modelOverride: ref.model, depth: depth + 1)

            for child in tempRoot.childNodes {
                child.removeFromParentNode()
                root.addChildNode(child)
            }
        }

        /// Extracts the mesh file for `gdtfModel` from the ZIP and builds
        /// a flat `SCNNode` containing all mesh objects (no extra hierarchy).
        /// Tries .3ds first, then falls back to .glb.
        /// Auto-detects the coordinate system by comparing mesh extents to
        /// declared model dimensions.
        private func makeMeshNode(gdtfModel: GDTFModel) -> (SCNNode, MeshCoordSystem)? {
            // Try .3ds first
            for lod in GDTFModel.LOD.allCases {
                if let data = gdtfModel.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod),
                   let file = try? ThreeDSFile.parse(data: data) {
                    let node = file.sceneNodeRaw()
                    return (node, detectCoordSystem(gdtfModel: gdtfModel, meshNode: node))
                }
            }
            // Fall back to .glb
            for lod in GDTFModel.LOD.allCases {
                if let data = gdtfModel.resolveFile(gdtf: gdtfData, format: .glb, lod: lod),
                   let file = try? GLBFile.parse(data: data) {
                    let node = file.sceneNodeRaw()
                    return (node, detectCoordSystem(gdtfModel: gdtfModel, meshNode: node))
                }
            }
            return nil
        }

        /// Determines whether a mesh's vertices are in Z-up or Y-up by
        /// comparing the rank order of mesh bounding-box spans to declared
        /// GDTF dimensions under both axis mappings.  The mapping where the
        /// largest declared dimension aligns with the largest mesh span
        /// (and smallest with smallest) is preferred, because per-axis
        /// scaling can adjust magnitudes but a mismatched rank order would
        /// produce distorted proportions.
        private func detectCoordSystem(gdtfModel: GDTFModel, meshNode: SCNNode) -> MeshCoordSystem {
            let (mn, mx) = meshNode.boundingBox
            let span = SIMD3<Double>(
                Double(mx.x) - Double(mn.x),
                Double(mx.y) - Double(mn.y),
                Double(mx.z) - Double(mn.z)
            )

            // Z-up mapping: mesh (X,Y,Z) → declared (Length, Width, Height)
            let zUpDeclared = SIMD3<Double>(gdtfModel.length, gdtfModel.width, gdtfModel.height)
            // Y-up mapping (after sceneKitToGdtf rotation): mesh (X,Y,Z) → rotated AABB
            // sceneKitToGdtf maps (x,y,z)→(x,-z,y), so the rotated bounding box has:
            //   X span unchanged, Y span = Z span, Z span = Y span
            let yUpSpan = SIMD3<Double>(span.x, span.z, span.y)

            /// Returns how well the rank order of `declared` matches `meshSpan`.
            /// Lower is better (0 = perfect match).
            func rankMismatch(_ declared: SIMD3<Double>, _ meshSpan: SIMD3<Double>) -> Int {
                // Sort indices by value to get rank order
                func rankOrder(_ v: SIMD3<Double>) -> [Int] {
                    let indexed = [(0, v.x), (1, v.y), (2, v.z)]
                    return indexed.sorted { $0.1 < $1.1 }.map { $0.0 }
                }
                let dRank = rankOrder(declared)
                let mRank = rankOrder(meshSpan)
                // Count how many positions have the same axis
                var matches = 0
                for i in 0..<3 {
                    if dRank[i] == mRank[i] { matches += 1 }
                }
                return 3 - matches
            }

            let zUpMismatch = rankMismatch(zUpDeclared, span)
            let yUpMismatch = rankMismatch(zUpDeclared, yUpSpan)
            return yUpMismatch < zUpMismatch ? .yUp : .zUp
        }

        /// Builds a 4×4 matrix that scales the mesh so that its bounding box
        /// matches the model's declared dimensions (Length→X, Width→Y,
        /// Height→Z in GDTF Z-up metres).
        ///
        /// Per the GDTF spec (§ Model Collect): "The mesh is explicitly
        /// scaled to this dimension."  Each axis is scaled independently
        /// so that the mesh's bounding-box span on that axis equals the
        /// declared dimension in metres.
        ///
        /// When `coordRotation` is provided, the mesh bounding box is first
        /// rotated into GDTF Z-up space before comparing with declared dims.
        /// The returned scale matrix operates in the ROTATED coordinate space.
        private func meshScaleMatrix(gdtfModel: GDTFModel, meshNode: SCNNode,
                                     coordRotation: simd_float4x4?) -> simd_float4x4 {
            let (mn, mx) = meshNode.boundingBox

            // If a coordinate rotation is provided, transform the bounding box
            // corners to find the AABB in the rotated space.
            let meshSpan: SIMD3<Double>
            if let rot = coordRotation {
                var rMin = SIMD3<Float>(repeating:  Float.infinity)
                var rMax = SIMD3<Float>(repeating: -Float.infinity)
                for dx in [Float(mn.x), Float(mx.x)] {
                    for dy in [Float(mn.y), Float(mx.y)] {
                        for dz in [Float(mn.z), Float(mx.z)] {
                            let rp = rot * SIMD4<Float>(dx, dy, dz, 1)
                            rMin = min(rMin, SIMD3(rp.x, rp.y, rp.z))
                            rMax = max(rMax, SIMD3(rp.x, rp.y, rp.z))
                        }
                    }
                }
                meshSpan = SIMD3<Double>(
                    Double(rMax.x) - Double(rMin.x),
                    Double(rMax.y) - Double(rMin.y),
                    Double(rMax.z) - Double(rMin.z)
                )
            } else {
                meshSpan = SIMD3<Double>(
                    Double(mx.x) - Double(mn.x),
                    Double(mx.y) - Double(mn.y),
                    Double(mx.z) - Double(mn.z)
                )
            }

            // Always use Z-up declared dimensions: Length→X, Width→Y, Height→Z
            let declared = SIMD3<Double>(gdtfModel.length, gdtfModel.width, gdtfModel.height)

            // Per-axis scale.  Fall back to the best uniform scale for axes
            // where the declared dimension is zero.
            var fallbackScale = 0.001
            for i in 0..<3 {
                if declared[i] > 0 && meshSpan[i] > 0.0001 {
                    fallbackScale = declared[i] / meshSpan[i]
                    break
                }
            }

            var scale = SIMD3<Double>(repeating: fallbackScale)
            for i in 0..<3 {
                if declared[i] > 0 && meshSpan[i] > 0.0001 {
                    scale[i] = declared[i] / meshSpan[i]
                }
            }

            return simd_float4x4(diagonal: SIMD4<Float>(Float(scale.x), Float(scale.y), Float(scale.z), 1))
        }
    }
}



private func buildScene(node: SCNNode) -> SCNScene {
    let scene = SCNScene()
    scene.rootNode.addChildNode(node)

    // Camera — looking at the origin from front-right, slightly above.
    // GDTF coordinate system: Z up, Y into screen, X right.
    // Place camera at -Y (in front) with a small X and Z offset for a 3/4 view.
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.camera?.zNear = 0.001
    cameraNode.camera?.zFar = 100
    cameraNode.position = SCNVector3(0.3, 0.8, 1.5)
    // Point at the origin using a look-at constraint.
    let lookAt = SCNLookAtConstraint(target: scene.rootNode)
    lookAt.isGimbalLockEnabled = true
    cameraNode.constraints = [lookAt]
    scene.rootNode.addChildNode(cameraNode)

    // Key light (warm, upper-right-front)
    let keyLight = SCNNode()
    keyLight.light = SCNLight()
    keyLight.light!.type = .omni
    keyLight.light!.intensity = 1200
    keyLight.light!.color = PlatformColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1)
    keyLight.position = SCNVector3(1.5, 2, 1.5)
    scene.rootNode.addChildNode(keyLight)

    // Fill light (cool, opposite side)
    let fillLight = SCNNode()
    fillLight.light = SCNLight()
    fillLight.light!.type = .omni
    fillLight.light!.intensity = 800
    fillLight.light!.color = PlatformColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1)
    fillLight.position = SCNVector3(-1.5, 0.5, -1)
    scene.rootNode.addChildNode(fillLight)

    // Ambient fill — strong enough to reveal dark-bodied fixtures
    let ambientNode = SCNNode()
    ambientNode.light = SCNLight()
    ambientNode.light!.type = .ambient
    ambientNode.light!.intensity = 600
    ambientNode.light!.color = PlatformColor.white
    scene.rootNode.addChildNode(ambientNode)

    return scene
}

private func buildScene(for file: ThreeDSFile) -> SCNScene {
    buildScene(node: file.sceneNode())
}

// MARK: - Platform view wrapper

#if canImport(AppKit)
private struct SceneKitView: NSViewRepresentable {
    let scene: SCNScene

    func makeNSView(context: Context) -> SCNView {
        let v = SCNView()
        configure(v)
        return v
    }

    func updateNSView(_ v: SCNView, context: Context) {
        v.scene = scene
    }

    private func configure(_ v: SCNView) {
        v.scene = scene
        v.allowsCameraControl = true
        v.autoenablesDefaultLighting = true
        v.backgroundColor = NSColor.windowBackgroundColor
        v.antialiasingMode = .multisampling4X
    }
}
#elseif canImport(UIKit)
private struct SceneKitView: UIViewRepresentable {
    let scene: SCNScene

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        configure(v)
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        v.scene = scene
    }

    private func configure(_ v: SCNView) {
        v.scene = scene
        v.allowsCameraControl = true
        v.autoenablesDefaultLighting = false
        v.backgroundColor = UIColor.systemBackground
        v.antialiasingMode = .multisampling4X
    }
}
#endif

// MARK: - Public SwiftUI view (single .3ds file)

/// A SwiftUI view that displays a `ThreeDSFile` in an interactive SceneKit
/// viewport.  The user can orbit and zoom using standard trackpad / touch
/// gestures.
public struct ThreeDSView: View {
    public let file: ThreeDSFile

    public init(file: ThreeDSFile) {
        self.file = file
    }

    public var body: some View {
        SceneKitView(scene: buildScene(for: file))
            .overlay(alignment: .bottomLeading) {
                statsLabel
            }
    }

    private var statsLabel: some View {
        let objectCount = file.objects.count
        let vertexCount = file.objects.reduce(0) { $0 + $1.vertices.count }
        let faceCount   = file.objects.reduce(0) { $0 + $1.faces.count }
        return Text(
            "\(objectCount) object\(objectCount == 1 ? "" : "s")  ·  " +
            "\(vertexCount) vertices  ·  " +
            "\(faceCount) triangles"
        )
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(6)
    }
}

// MARK: - Public SwiftUI view (assembled GDTF fixture)

/// A SwiftUI view that displays a fully assembled GDTF fixture in an
/// interactive SceneKit viewport.
///
/// The geometry tree is walked from `rootGeometryName`, each geometry's
/// `.3ds` model is extracted from the GDTF ZIP and positioned using the
/// geometry's transform matrix.  `GeometryReference` nodes are resolved to
/// their referenced top-level geometry.
public struct GDTFFixtureView: View {
    public let builder: FixtureSceneBuilder
    public let rootGeometryName: String?

    public init(builder: FixtureSceneBuilder, rootGeometryName: String? = nil) {
        self.builder = builder
        self.rootGeometryName = rootGeometryName
    }

    public var body: some View {
        let node = builder.buildNode(rootGeometryName: rootGeometryName)
        SceneKitView(scene: buildScene(node: node))
            .overlay(alignment: .bottomLeading) { statsLabel(node: node) }
    }

    private func statsLabel(node: SCNNode) -> some View {
        // Count geometry nodes (non-empty names = geometry-backed nodes)
        let nodeCount = countNodes(node)
        return Text("\(nodeCount) geometry node\(nodeCount == 1 ? "" : "s")")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(6)
    }

    private func countNodes(_ node: SCNNode) -> Int {
        1 + node.childNodes.reduce(0) { $0 + countNodes($1) }
    }
}


// MARK: - Preview

#if DEBUG

private struct FixtureEntry: Identifiable, Hashable {
    let rid: String
    let name: String
    var id: String { rid }
}

private let previewFixtures: [FixtureEntry] = [
    FixtureEntry(rid: "9913",   name: "ARRI Orbiter"),
    FixtureEntry(rid: "80120",  name: "Cameo H1 FC"),
    FixtureEntry(rid: "80253",  name: "Clay Paky HY B-EYE K25"),
    FixtureEntry(rid: "80618",  name: "ETC S4 Series 2 Lustr"),
    FixtureEntry(rid: "80619",  name: "ETC S4 Series 1 Lustr"),
    FixtureEntry(rid: "83039",  name: "GLP JDC-1"),
    FixtureEntry(rid: "83969",  name: "Cameo Opus X4"),
    FixtureEntry(rid: "84086",  name: "Elation Proteus Atlas"),
    FixtureEntry(rid: "84272",  name: "Clay Paky Actoris ParLed"),
    FixtureEntry(rid: "85348",  name: "Martin Professional MAC 700 Profile"),
    FixtureEntry(rid: "85351",  name: "High End Systems Showpix"),
    FixtureEntry(rid: "85637",  name: "Vari-Lite VL3600 Profile IP"),
    FixtureEntry(rid: "86183",  name: "Martin Professional MAC Ultra Performance"),
    FixtureEntry(rid: "86751",  name: "ARRI SkyPanel S60C"),
    FixtureEntry(rid: "86752",  name: "ARRI SkyPanel S120C"),
    FixtureEntry(rid: "87690",  name: "SGM Light X-5"),
    FixtureEntry(rid: "88718",  name: "Elation Fuze Profile"),
    FixtureEntry(rid: "89495",  name: "Elation Proteus Brutus FS"),
    FixtureEntry(rid: "91000",  name: "GLP impression X5 IP"),
    FixtureEntry(rid: "91158",  name: "GLP impression FR1"),
    FixtureEntry(rid: "91164",  name: "GLP impression X5"),
    FixtureEntry(rid: "93699",  name: "Martin Professional MAC Quantum Wash"),
    FixtureEntry(rid: "96102",  name: "Elation Fuze Max Spot"),
    FixtureEntry(rid: "96152",  name: "Clay Paky Axcor Spot 400"),
    FixtureEntry(rid: "96333",  name: "Elation Artiste Picasso"),
    FixtureEntry(rid: "97062",  name: "Vari-Lite VL5LED Wash"),
    FixtureEntry(rid: "98126",  name: "Elation Platinum Spot 15R Pro"),
    FixtureEntry(rid: "98187",  name: "Clay Paky Arolla Profile HP"),
    FixtureEntry(rid: "99743",  name: "Martin Professional MAC One"),
    FixtureEntry(rid: "129856", name: "129856"),
    FixtureEntry(rid: "130017", name: "High End Systems SolaFrame Theatre"),
]

private enum PreviewLoadState {
    case loading
    case loaded(FixtureSceneBuilder, [String])   // builder + top-level geometry names
    case unavailable(String)
}

private struct GDTFFixturePickerPreview: View {
    let fixtures: [FixtureEntry]
    @State private var selectedIndex: Int = 0
    @State private var state: PreviewLoadState = .loading
    @State private var selectedGeometry: String = ""

    private var selectedFixture: FixtureEntry { fixtures[selectedIndex] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Stepper(
                    "\(selectedIndex + 1)/\(fixtures.count)",
                    value: $selectedIndex,
                    in: 0...(fixtures.count - 1)
                )
                .fixedSize()

                Picker("Fixture", selection: $selectedIndex) {
                    ForEach(Array(fixtures.enumerated()), id: \.offset) { i, entry in
                        Text(entry.name).tag(i)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                if case .loaded(_, let names) = state, !names.isEmpty {
                    Picker("Root Geometry", selection: $selectedGeometry) {
                        ForEach(names, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Link(destination: URL(string: "https://fixturebuilder.gdtf-share.com/load/?rid=\(selectedFixture.rid)")!) {
                    Label("GDTF Builder", systemImage: "safari")
                }
                .buttonStyle(.borderless)
            }
            .padding(8)

            Divider()

            Group {
                switch state {
                case .loading:
                    ProgressView("Loading…")
                case .loaded(let builder, _):
                    GDTFFixtureView(
                        builder: builder,
                        rootGeometryName: selectedGeometry.isEmpty ? nil : selectedGeometry
                    )
                case .unavailable(let message):
                    ContentUnavailableView(
                        "No 3D models",
                        systemImage: "cube.transparent",
                        description: Text(message)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 700, height: 560)
        .task(id: selectedFixture.rid) {
            await loadFixture(rid: selectedFixture.rid)
        }
    }

    private func loadFixture(rid: String) async {
        state = .loading
        selectedGeometry = ""
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwiftGDTF/Fixtures")
        let fixtureURL = cacheDir.appendingPathComponent("\(rid).gdtf")

        guard
            let gdtfData = try? Data(contentsOf: fixtureURL),
            let gdtf = try? loadGDTF(data: gdtfData)
        else {
            state = .unavailable("Fixture \(rid) not in cache.\nRun parseAllFixtures() to populate the cache.")
            return
        }

        // Check that at least one model has a mesh file (3DS or GLB)
        // somewhere in the archive (otherwise it will render as empty).
        let hasAnyModel = gdtf.fixtureType.models.contains { model in
            GDTFModel.LOD.allCases.contains { lod in
                model.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod) != nil ||
                model.resolveFile(gdtf: gdtfData, format: .glb, lod: lod) != nil
            }
        }
        guard hasAnyModel else {
            state = .unavailable("Fixture \(rid) has no 3D models.")
            return
        }

        let builder = FixtureSceneBuilder(gdtf: gdtf, gdtfData: gdtfData)
        let geometries = gdtf.fixtureType.geometries
        let geometryNames = geometries.map { $0.name }
        state = .loaded(builder, geometryNames)

        // Default to the geometry with the most descendants — that's typically
        // the full fixture body, not an instanced sub-component.
        func descendantCount(_ g: Geometry) -> Int {
            1 + g.children.reduce(0) { $0 + descendantCount($1) }
        }
        let best = geometries.max(by: { descendantCount($0) < descendantCount($1) })
        selectedGeometry = best?.name ?? geometryNames.first ?? ""
    }
}

private let glbPreviewFixtures: [FixtureEntry] = [
    // --- Original GLB test fixtures ---
    FixtureEntry(rid: "100110",  name: "PR Lighting P12 PR"),
    FixtureEntry(rid: "100255",  name: "Elation Flaris Blade"),
    FixtureEntry(rid: "100358",  name: "Robe Robin Esprite"),
    FixtureEntry(rid: "100447",  name: "Claypaky Xtylos"),
    FixtureEntry(rid: "102634",  name: "GLP S24"),
    FixtureEntry(rid: "48499",   name: "Chauvet Rogue Outcast 2X Wash"),
    FixtureEntry(rid: "52541",   name: "Chauvet Maverick Storm 3 BeamWash"),
    FixtureEntry(rid: "60992",   name: "Chauvet Maverick Force 2 BeamWash"),
    FixtureEntry(rid: "86884",   name: "MegaLite Viceroy"),
    FixtureEntry(rid: "88050",   name: "Cameo Matrix Panel 3WW"),
    FixtureEntry(rid: "91603",   name: "American DJ Ultra Bar 12"),
    FixtureEntry(rid: "115628",  name: "Prolights AstraWash19PIX"),
    FixtureEntry(rid: "95272",   name: "Chauvet FX Par 9"),
    FixtureEntry(rid: "122187",  name: "MARK BEAM LED 64"),
    // --- Robe ---
    FixtureEntry(rid: "119741",  name: "Robe Robin Tarrantula"),
    FixtureEntry(rid: "129297",  name: "Robe Robin SVB1 RGBA"),
    FixtureEntry(rid: "119734",  name: "Robe Robin iSpiiderX"),
    FixtureEntry(rid: "119729",  name: "Robe Robin Spiider"),
    FixtureEntry(rid: "93825",   name: "Robe Robin T1 Profile FS"),
    FixtureEntry(rid: "41461",   name: "Robe Robin T2 Profile FS"),
    FixtureEntry(rid: "121635",  name: "Robe Robin iForte LTX FS"),
    FixtureEntry(rid: "121463",  name: "Robe Robin WTF"),
    FixtureEntry(rid: "41709",   name: "Robe Robin BMFL FollowSpot"),
    FixtureEntry(rid: "119732",  name: "Robe Robin Spiider RGBA"),
    // --- Martin ---
    FixtureEntry(rid: "120130",  name: "Martin MAC Encore Two"),
    FixtureEntry(rid: "117468",  name: "Martin MAC Viper XIP"),
    FixtureEntry(rid: "117469",  name: "Martin ELP Manet 8F"),
    FixtureEntry(rid: "120566",  name: "Martin MAC One"),
    FixtureEntry(rid: "93699",   name: "Martin MAC Quantum Wash"),
    FixtureEntry(rid: "68977",   name: "Martin MAC Aura"),
    FixtureEntry(rid: "117897",  name: "Martin MAC Aura XIP"),
    FixtureEntry(rid: "110898",  name: "Martin MAC 101 RGB"),
    FixtureEntry(rid: "36848",   name: "Martin MAC Allure Wash PC"),
    FixtureEntry(rid: "117999",  name: "Martin MAC Aura Raven XIP"),
    // --- Ayrton ---
    FixtureEntry(rid: "129171",  name: "Ayrton Zonda 9 FX"),
    FixtureEntry(rid: "129078",  name: "Ayrton Argo 6 FX"),
    FixtureEntry(rid: "129159",  name: "Ayrton Zonda 3 FX"),
    FixtureEntry(rid: "70202",   name: "Ayrton AlienPix RS"),
    FixtureEntry(rid: "121985",  name: "Ayrton MagicDot Neo"),
    FixtureEntry(rid: "113010",  name: "Ayrton Zonda 9 WASH"),
    FixtureEntry(rid: "129163",  name: "Ayrton Nando 502"),
    FixtureEntry(rid: "110521",  name: "Ayrton Nando 502 (v2)"),
    FixtureEntry(rid: "129160",  name: "Ayrton Zonda 3 WASH"),
    FixtureEntry(rid: "129164",  name: "Ayrton Nando 602"),
]

#Preview("GDTF Fixture Assembler") {
    GDTFFixturePickerPreview(fixtures: previewFixtures)
}

#Preview("GLB Fixture Assembler") {
    GDTFFixturePickerPreview(fixtures: glbPreviewFixtures)
}
#endif
