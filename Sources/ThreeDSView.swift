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
            guard !object.vertices.isEmpty, !object.faces.isEmpty,
                  !object.isDegenerateMarker else { continue }

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

/// Assembles an `SCNNode` hierarchy for a GDTF fixture by delegating to
/// `FixtureGeometryAssembler` and converting the result to SceneKit nodes.
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
        let assembler = FixtureGeometryAssembler(gdtf: gdtf, gdtfData: gdtfData)
        guard let assembled = assembler.assemble(
            rootGeometryName: rootGeometryName, normalize: true
        ) else { return SCNNode() }
        return makeSCNNode(from: assembled.root)
    }

    // MARK: - SCNNode bridge

    /// Recursively converts an `AssembledNode` tree to an `SCNNode` tree.
    ///
    /// Each geometry's `localTransform` (position) becomes the SCNNode transform.
    /// The mesh is placed on a child node with `meshLocalTransform` so that
    /// mesh scaling doesn't affect descendant positions.
    private func makeSCNNode(from node: AssembledNode) -> SCNNode {
        let scnNode = SCNNode()
        scnNode.name = node.name
        scnNode.simdTransform = node.localTransform

        if let meshData = node.meshData {
            let meshNode = SCNNode()
            meshNode.simdTransform = node.meshLocalTransform ?? .init(1)

            for submesh in meshData.submeshes {
                guard !submesh.vertices.isEmpty, !submesh.faceIndices.isEmpty else { continue }

                // Positions
                let positionSource = SCNGeometrySource(
                    vertices: submesh.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
                )

                // Indices
                var indices: [Int32] = []
                indices.reserveCapacity(submesh.faceIndices.count * 3)
                for face in submesh.faceIndices {
                    indices.append(Int32(face.x))
                    indices.append(Int32(face.y))
                    indices.append(Int32(face.z))
                }
                let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

                var sources: [SCNGeometrySource] = [positionSource]

                // Normals (optional)
                if submesh.normals.count == submesh.vertices.count {
                    let normalSource = SCNGeometrySource(
                        normals: submesh.normals.map { SCNVector3($0.x, $0.y, $0.z) }
                    )
                    sources.append(normalSource)
                }

                // UVs (optional)
                if submesh.textureCoordinates.count == submesh.vertices.count {
                    let uvData = submesh.textureCoordinates.withUnsafeBytes { Data($0) }
                    let uvSource = SCNGeometrySource(
                        data: uvData,
                        semantic: .texcoord,
                        vectorCount: submesh.textureCoordinates.count,
                        usesFloatComponents: true,
                        componentsPerVector: 2,
                        bytesPerComponent: MemoryLayout<Float>.size,
                        dataOffset: 0,
                        dataStride: MemoryLayout<SIMD2<Float>>.stride
                    )
                    sources.append(uvSource)
                }

                let geometry = SCNGeometry(sources: sources, elements: [element])

                let material = SCNMaterial()
                material.lightingModel = .phong
                material.isDoubleSided = true
                material.diffuse.contents = PlatformColor(white: 0.2, alpha: 1)
                material.specular.contents = PlatformColor(white: 0.4, alpha: 1)
                geometry.materials = [material]

                let submeshNode = SCNNode(geometry: geometry)
                submeshNode.name = submesh.name
                meshNode.addChildNode(submeshNode)
            }

            scnNode.addChildNode(meshNode)
        }

        for child in node.children {
            scnNode.addChildNode(makeSCNNode(from: child))
        }

        return scnNode
    }
}

// MARK: - Pan/tilt animation

extension FixtureSceneBuilder {
    /// Builds an animated `SCNNode` subtree that continuously pans and tilts.
    ///
    /// Uses the first DMX mode to determine per-geometry axis info. Geometries
    /// with pan/tilt channels get `SCNAction` animations that sweep within their
    /// declared physical ranges.
    ///
    /// The fixture is flipped 180° around X so it appears standing upright
    /// (GDTF stores fixtures hanging with Z-up pointing away from the stage).
    public func buildAnimatedNode(rootGeometryName: String? = nil) -> SCNNode {
        let assembler = FixtureGeometryAssembler(gdtf: gdtf, gdtfData: gdtfData)
        let dmxMode = gdtf.fixtureType.dmxModes.first
        guard let assembled = assembler.assemble(
            rootGeometryName: rootGeometryName,
            dmxMode: dmxMode,
            normalize: true
        ) else { return SCNNode() }

        let node = makeSCNNode(from: assembled.root)

        // Flip the fixture upright: rotate 180° around X.
        // GDTF fixtures are stored "hanging" — base at top, head pointing down.
        // This makes them stand with the base at the bottom.
        let flip = simd_float4x4(
            SIMD4<Float>(1,  0,  0, 0),
            SIMD4<Float>(0, -1,  0, 0),
            SIMD4<Float>(0,  0, -1, 0),
            SIMD4<Float>(0,  0,  0, 1)
        )
        node.simdTransform = flip * node.simdTransform

        applyAnimations(to: node, from: assembled.root)
        return node
    }

    /// Recursively applies pan/tilt animations to SCNNodes that have axis info.
    ///
    /// For nodes with axis info whose position matrix includes a rotation,
    /// the node is split: translation goes on the outer node (where the
    /// animation runs), and the rotation goes on a child wrapper so the
    /// animation axis is in the parent's coordinate frame.
    ///
    /// Pan rotates around GDTF Z axis. Tilt rotates around GDTF X axis.
    private func applyAnimations(to scnNode: SCNNode, from assembledNode: AssembledNode) {
        if let axisInfo = assembledNode.axisInfo {
            var actions: [SCNAction] = []

            // Pan animation (around Z axis in GDTF space)
            if let panAction = Self.makeAxisAction(
                range: axisInfo.panRange,
                infinite: axisInfo.panInfinite,
                axis: SIMD3<Float>(0, 0, 1)
            ) {
                actions.append(panAction)
            }

            // Tilt animation (around X axis in GDTF space)
            if let tiltAction = Self.makeAxisAction(
                range: axisInfo.tiltRange,
                infinite: axisInfo.tiltInfinite,
                axis: SIMD3<Float>(1, 0, 0)
            ) {
                actions.append(tiltAction)
            }

            if !actions.isEmpty {
                // If the node's localTransform has a rotation component, we need
                // to split it: put the translation on this node (where the animation
                // runs) and the rotation on a wrapper node below. Otherwise the
                // animation axis gets rotated by the position matrix.
                let transform = scnNode.simdTransform
                let translation = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                var rotScale = transform
                rotScale.columns.3 = SIMD4<Float>(0, 0, 0, 1)

                let isIdentityRotScale = simd_almost_equal_elements(rotScale, simd_float4x4(1), 0.001)

                if !isIdentityRotScale {
                    // Split: this node gets translation only, rotation goes to wrapper
                    scnNode.simdTransform = simd_float4x4(columns: (
                        SIMD4<Float>(1, 0, 0, 0),
                        SIMD4<Float>(0, 1, 0, 0),
                        SIMD4<Float>(0, 0, 1, 0),
                        SIMD4<Float>(translation.x, translation.y, translation.z, 1)
                    ))

                    let wrapper = SCNNode()
                    wrapper.simdTransform = rotScale

                    // Move all existing children to the wrapper
                    for child in scnNode.childNodes {
                        child.removeFromParentNode()
                        wrapper.addChildNode(child)
                    }
                    scnNode.addChildNode(wrapper)
                }

                scnNode.runAction(.group(actions))
            }
        }

        // Match SCNNode children to AssembledNode children by position.
        // The SCNNode may have extra children (mesh nodes, wrapper nodes) so we
        // search recursively by name within this node's direct subtree.
        for assembledChild in assembledNode.children {
            if let matchingChild = findDescendant(named: assembledChild.name, in: scnNode) {
                applyAnimations(to: matchingChild, from: assembledChild)
            }
        }
    }

    /// Finds a direct or wrapped child node by name (handles wrapper nodes).
    private func findDescendant(named name: String, in node: SCNNode) -> SCNNode? {
        for child in node.childNodes {
            if child.name == name { return child }
            // Check one level deeper for wrapper nodes (unnamed)
            if child.name == nil {
                for grandchild in child.childNodes {
                    if grandchild.name == name { return grandchild }
                }
            }
        }
        return nil
    }

    /// Creates an `SCNAction` for a single rotation axis.
    ///
    /// - For bounded ranges: sweeps the full declared range at ~30°/sec.
    /// - For infinite rotation with a bounded range: continuous full rotation.
    /// - For infinite-only (no bounded range): skipped — typically means the
    ///   axis is handled by a parent geometry's bounded pan/tilt.
    ///
    /// Uses `SCNAction.rotate(by:around:)` to avoid Euler angle gimbal lock.
    private static func makeAxisAction(
        range: ClosedRange<Double>?,
        infinite: Bool,
        axis: SIMD3<Float>
    ) -> SCNAction? {
        let degreesToRadians = Double.pi / 180.0
        let speed = 30.0 * degreesToRadians  // radians per second
        let axisVec = SCNVector3(axis.x, axis.y, axis.z)

        guard let range else {
            // No bounded range. If infinite-only, skip — the parent likely
            // handles this axis with a bounded range already.
            return nil
        }

        if infinite {
            let duration = (2 * Double.pi) / speed
            return .repeatForever(.rotate(
                by: CGFloat(2 * Double.pi),
                around: axisVec,
                duration: duration
            ))
        }

        let fromRad = range.lowerBound * degreesToRadians
        let toRad = range.upperBound * degreesToRadians
        let sweep = abs(toRad - fromRad)

        guard sweep > 0.001 else { return nil }

        let halfSweep = sweep / 2.0
        let halfDuration = halfSweep / speed
        let fullDuration = sweep / speed

        // Sweep: center → +half → -half → center (uses incremental rotation)
        let toPositive = SCNAction.rotate(by: CGFloat(halfSweep), around: axisVec, duration: halfDuration)
        let toNegative = SCNAction.rotate(by: CGFloat(-sweep), around: axisVec, duration: fullDuration)
        let backToCenter = SCNAction.rotate(by: CGFloat(halfSweep), around: axisVec, duration: halfDuration)

        toPositive.timingMode = .easeInEaseOut
        toNegative.timingMode = .easeInEaseOut
        backToCenter.timingMode = .easeInEaseOut

        return .repeatForever(.sequence([toPositive, toNegative, backToCenter]))
    }

    /// Builds a node with static pan/tilt applied at the given angles (in degrees).
    ///
    /// Pan rotates around GDTF Z axis, tilt around GDTF X axis.
    /// The fixture is flipped upright (same as `buildAnimatedNode`).
    public func buildPosedNode(rootGeometryName: String? = nil,
                               panDegrees: Double = 0,
                               tiltDegrees: Double = 0) -> SCNNode {
        let assembler = FixtureGeometryAssembler(gdtf: gdtf, gdtfData: gdtfData)
        let dmxMode = gdtf.fixtureType.dmxModes.first
        guard let assembled = assembler.assemble(
            rootGeometryName: rootGeometryName,
            dmxMode: dmxMode,
            normalize: true
        ) else { return SCNNode() }

        let node = makeSCNNode(from: assembled.root)

        // Flip upright
        let flip = simd_float4x4(
            SIMD4<Float>(1,  0,  0, 0),
            SIMD4<Float>(0, -1,  0, 0),
            SIMD4<Float>(0,  0, -1, 0),
            SIMD4<Float>(0,  0,  0, 1)
        )
        node.simdTransform = flip * node.simdTransform

        applyStaticPose(to: node, from: assembled.root,
                        panRad: Float(panDegrees * .pi / 180),
                        tiltRad: Float(tiltDegrees * .pi / 180))
        return node
    }

    /// Recursively applies static pan/tilt rotation to nodes with axis info.
    private func applyStaticPose(to scnNode: SCNNode, from assembledNode: AssembledNode,
                                  panRad: Float, tiltRad: Float) {
        if let axisInfo = assembledNode.axisInfo {
            // Only apply static rotation for bounded ranges, not infinite-only.
            let hasPan = axisInfo.panRange != nil
            let hasTilt = axisInfo.tiltRange != nil

            if hasPan || hasTilt {
                // Decompose: strip rotation from localTransform, apply pan/tilt
                // in the parent's frame, then re-apply the position's rotation.
                let transform = scnNode.simdTransform
                let translation = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                var rotScale = transform
                rotScale.columns.3 = SIMD4<Float>(0, 0, 0, 1)

                // Build pan/tilt rotation in GDTF space
                var rotation = simd_float4x4(1)
                if hasPan {
                    let c = cos(panRad), s = sin(panRad)
                    rotation = rotation * simd_float4x4(
                        SIMD4<Float>( c, s, 0, 0),
                        SIMD4<Float>(-s, c, 0, 0),
                        SIMD4<Float>( 0, 0, 1, 0),
                        SIMD4<Float>( 0, 0, 0, 1)
                    )
                }
                if hasTilt {
                    let c = cos(tiltRad), s = sin(tiltRad)
                    rotation = rotation * simd_float4x4(
                        SIMD4<Float>(1,  0, 0, 0),
                        SIMD4<Float>(0,  c, s, 0),
                        SIMD4<Float>(0, -s, c, 0),
                        SIMD4<Float>(0,  0, 0, 1)
                    )
                }

                // New transform: translate * pan/tilt rotation * original rotation
                let translationMatrix = simd_float4x4(columns: (
                    SIMD4<Float>(1, 0, 0, 0),
                    SIMD4<Float>(0, 1, 0, 0),
                    SIMD4<Float>(0, 0, 1, 0),
                    SIMD4<Float>(translation.x, translation.y, translation.z, 1)
                ))
                scnNode.simdTransform = translationMatrix * rotation * rotScale
            }
        }

        for assembledChild in assembledNode.children {
            if let matchingChild = findDescendant(named: assembledChild.name, in: scnNode) {
                applyStaticPose(to: matchingChild, from: assembledChild,
                                panRad: panRad, tiltRad: tiltRad)
            }
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
    FixtureEntry(rid: "69633",  name: "Ayrton Versapix 100"),
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
    var animated: Bool = false
    @State private var selectedIndex: Int = 0
    @State private var state: PreviewLoadState = .loading
    @State private var selectedGeometry: String = ""

    private var selectedFixture: FixtureEntry { fixtures[selectedIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Stepper(
                    "\(selectedIndex + 1)/\(fixtures.count)",
                    value: $selectedIndex,
                    in: 0...(fixtures.count - 1)
                )
                //.font(.default.monospacedDigit())
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
                    if animated {
                        AnimatedGDTFFixtureView(
                            builder: builder,
                            rootGeometryName: selectedGeometry.isEmpty ? nil : selectedGeometry
                        )
                    } else {
                        GDTFFixtureView(
                            builder: builder,
                            rootGeometryName: selectedGeometry.isEmpty ? nil : selectedGeometry
                        )
                    }
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

        // Check that at least one model has a mesh file (3DS, GLB, or
        // a non-undefined primitive type).
        let hasAnyModel = gdtf.fixtureType.models.contains { model in
            model.primitiveType != .undefined ||
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
    // --- Debugging ---
    FixtureEntry(rid: "71555",   name: "Ayrton WildSun K25-TC"),
    FixtureEntry(rid: "123451",  name: "Robe Robin LEDBeam 350 FW"),
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

private let primitivePreviewFixtures: [FixtureEntry] = [
    FixtureEntry(rid: "96454",   name: "Silver Star NH1"),
    FixtureEntry(rid: "80580",   name: "MANIAC M4 TILT 4415"),
    FixtureEntry(rid: "119308",  name: "Algam BAR WASH 244"),
    FixtureEntry(rid: "50698",   name: "BeamZ WBP612IP"),
    FixtureEntry(rid: "102817",  name: "Prolights Equinox Fusion 260ZR"),
    FixtureEntry(rid: "118149",  name: "Lucendi Retro 7"),
    FixtureEntry(rid: "126918",  name: "Sagitter J-Bar8Bat"),
    FixtureEntry(rid: "112114",  name: "Contest STB 520"),
    FixtureEntry(rid: "97750",   name: "Varytec Colors StarBar 12"),
    FixtureEntry(rid: "125267",  name: "Chauvet DJ FXpar 9"),
]

/// A SwiftUI view that displays a GDTF fixture with continuous pan/tilt animation.
private struct AnimatedGDTFFixtureView: View {
    let builder: FixtureSceneBuilder
    let rootGeometryName: String?

    var body: some View {
        let node = builder.buildAnimatedNode(rootGeometryName: rootGeometryName)
        SceneKitView(scene: buildScene(node: node))
    }
}

private let animatedPreviewFixtures: [FixtureEntry] = [
    FixtureEntry(rid: "91158",  name: "GLP impression FR1"),
    FixtureEntry(rid: "71555",  name: "Ayrton WildSun K25-TC"),
    FixtureEntry(rid: "80253",  name: "Clay Paky HY B-EYE K25"),
    FixtureEntry(rid: "83969",  name: "Cameo Opus X4"),
    FixtureEntry(rid: "84086",  name: "Elation Proteus Atlas"),
    FixtureEntry(rid: "85348",  name: "Martin Professional MAC 700 Profile"),
    FixtureEntry(rid: "86183",  name: "Martin Professional MAC Ultra Performance"),
    FixtureEntry(rid: "88718",  name: "Elation Fuze Profile"),
    FixtureEntry(rid: "91000",  name: "GLP impression X5 IP"),
    FixtureEntry(rid: "91164",  name: "GLP impression X5"),
    FixtureEntry(rid: "93699",  name: "Martin Professional MAC Quantum Wash"),
    FixtureEntry(rid: "96102",  name: "Elation Fuze Max Spot"),
    FixtureEntry(rid: "96333",  name: "Elation Artiste Picasso"),
    FixtureEntry(rid: "99743",  name: "Martin Professional MAC One"),
]

#Preview("GDTF Fixture Assembler") {
    GDTFFixturePickerPreview(fixtures: previewFixtures)
}

#Preview("GLB Fixture Assembler") {
    GDTFFixturePickerPreview(fixtures: glbPreviewFixtures)
}

#Preview("Primitive Fixture Assembler") {
    GDTFFixturePickerPreview(fixtures: primitivePreviewFixtures)
}

#Preview("Animated Fixture") {
    GDTFFixturePickerPreview(fixtures: animatedPreviewFixtures, animated: true)
}

private struct PosedGDTFFixtureView: View {
    let builder: FixtureSceneBuilder
    let rootGeometryName: String?
    let panDegrees: Double
    let tiltDegrees: Double

    var body: some View {
        let node = builder.buildPosedNode(
            rootGeometryName: rootGeometryName,
            panDegrees: panDegrees,
            tiltDegrees: tiltDegrees
        )
        SceneKitView(scene: buildScene(node: node))
    }
}

private struct PanTiltSliderPreview: View {
    let fixtures: [FixtureEntry]
    @State private var selectedIndex: Int = 0
    @State private var state: PreviewLoadState = .loading
    @State private var selectedGeometry: String = ""
    @State private var panDegrees: Double = 0
    @State private var tiltDegrees: Double = 0

    private var selectedFixture: FixtureEntry { fixtures[selectedIndex] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            }
            .padding(8)

            HStack {
                Text("Pan: \(Int(panDegrees))°")
                    .monospacedDigit()
                    .frame(width: 90, alignment: .leading)
                Slider(value: $panDegrees, in: -360...360)
            }
            .padding(.horizontal, 8)

            HStack {
                Text("Tilt: \(Int(tiltDegrees))°")
                    .monospacedDigit()
                    .frame(width: 90, alignment: .leading)
                Slider(value: $tiltDegrees, in: -180...180)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            Divider()

            Group {
                switch state {
                case .loading:
                    ProgressView("Loading…")
                case .loaded(let builder, _):
                    PosedGDTFFixtureView(
                        builder: builder,
                        rootGeometryName: selectedGeometry.isEmpty ? nil : selectedGeometry,
                        panDegrees: panDegrees,
                        tiltDegrees: tiltDegrees
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
        .frame(width: 700, height: 600)
        .task(id: selectedFixture.rid) {
            await loadFixture(rid: selectedFixture.rid)
        }
    }

    private func loadFixture(rid: String) async {
        state = .loading
        selectedGeometry = ""
        panDegrees = 0
        tiltDegrees = 0
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwiftGDTF/Fixtures")
        let fixtureURL = cacheDir.appendingPathComponent("\(rid).gdtf")

        guard
            let gdtfData = try? Data(contentsOf: fixtureURL),
            let gdtf = try? loadGDTF(data: gdtfData)
        else {
            state = .unavailable("Fixture \(rid) not in cache.")
            return
        }

        let hasAnyModel = gdtf.fixtureType.models.contains { model in
            model.primitiveType != .undefined ||
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

        func descendantCount(_ g: Geometry) -> Int {
            1 + g.children.reduce(0) { $0 + descendantCount($1) }
        }
        let best = geometries.max(by: { descendantCount($0) < descendantCount($1) })
        selectedGeometry = best?.name ?? geometryNames.first ?? ""
    }
}

#Preview("Pan/Tilt Slider") {
    PanTiltSliderPreview(fixtures: animatedPreviewFixtures)
}
#endif
