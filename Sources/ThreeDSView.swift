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
//    geometry's GDTFModel, extracting the matching .3ds file from the
//    GDTF ZIP, and building an SCNNode hierarchy with each geometry's
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

            if let matName = object.materialName, let mat = materialMap[matName] {
                scnMaterial.diffuse.contents = mat.diffuseColor.map {
                    PlatformColor(red: CGFloat($0.x), green: CGFloat($0.y), blue: CGFloat($0.z), alpha: 1)
                } ?? PlatformColor.lightGray
                if let a = mat.ambientColor {
                    scnMaterial.ambient.contents = PlatformColor(
                        red: CGFloat(a.x), green: CGFloat(a.y), blue: CGFloat(a.z), alpha: 1
                    )
                }
                if let s = mat.specularColor {
                    scnMaterial.specular.contents = PlatformColor(
                        red: CGFloat(s.x), green: CGFloat(s.y), blue: CGFloat(s.z), alpha: 1
                    )
                }
            } else {
                scnMaterial.diffuse.contents = PlatformColor.lightGray
            }
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
    /// The GDTF `Matrix` stores a `simd_double4x4` initialised with
    /// `.init(rows:)`, so `matrix[col, row]` gives the element at that
    /// column and row.  Translation is in column 3 (rows 0-2).
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
/// `.3ds` mesh to each node.
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
        let root = SCNNode()
        root.name = rootGeometry.name

        // GDTF uses Z-up; SceneKit uses Y-up.
        // Rotate -90° around X: (x, y, z) → (x, -z, y).
        let gdtfToSceneKit = simd_float4x4(
            SIMD4<Float>(1,  0, 0, 0),
            SIMD4<Float>(0,  0, 1, 0),
            SIMD4<Float>(0, -1, 0, 0),
            SIMD4<Float>(0,  0, 0, 1)
        )
        context.walk(rootGeometry, worldTransform: gdtfToSceneKit,
                     into: root, modelOverride: nil, depth: 0)

        // Compute world-space bounding box by transforming each mesh node's
        // local AABB by its accumulated world transform.
        var worldMin = SIMD3<Float>(repeating:  Float.infinity)
        var worldMax = SIMD3<Float>(repeating: -Float.infinity)

        func accumulate(_ node: SCNNode) {
            if node.geometry != nil {
                let (localMin, localMax) = node.boundingBox
                let wt = node.simdWorldTransform
                for dx in [Float(localMin.x), Float(localMax.x)] {
                    for dy in [Float(localMin.y), Float(localMax.y)] {
                        for dz in [Float(localMin.z), Float(localMax.z)] {
                            let lp = SIMD4<Float>(dx, dy, dz, 1)
                            let wp = wt * lp
                            let wp3 = SIMD3<Float>(wp.x, wp.y, wp.z)
                            worldMin = min(worldMin, wp3)
                            worldMax = max(worldMax, wp3)
                        }
                    }
                }
            }
            for child in node.childNodes { accumulate(child) }
        }
        accumulate(root)

        let span = worldMax - worldMin
        let maxDim = span.max()
        if maxDim > 0 {
            let s = CGFloat(1.0 / maxDim)
            let centre = (worldMin + worldMax) * 0.5
            root.simdPosition = simd_float3(-centre.x, -centre.y, -centre.z)
            root.scale = SCNVector3(s, s, s)
            // Re-apply centring at the new scale
            root.simdPosition = simd_float3(
                -centre.x * Float(s),
                -centre.y * Float(s),
                -centre.z * Float(s)
            )
        }

        return root
    }

    // MARK: - Build context (captures shared state)

    private struct BuildContext {
        let gdtfData: Data
        let modelMap: [String: GDTFModel]
        let topLevelMap: [String: Geometry]

        /// Walks the geometry tree and collects all mesh nodes into `root`,
        /// each positioned by the cumulative world transform at that geometry.
        ///
        /// The `.3ds` vertex coordinates are already in the fixture's local
        /// coordinate space (authored in mm relative to the fixture origin).
        /// The GDTF `position` matrices define the pivot/default pose for
        /// DMX-driven animation — they must *not* be stacked on top of the
        /// mesh vertices for a static render. Instead we apply the accumulated
        /// transform only when the same geometry is instanced via a
        /// `GeometryReference`, which genuinely places a copy at a new location.
        func collectMeshNodes(into root: SCNNode) {
            for geo in topLevelMap.values.sorted(by: { $0.name < $1.name }) {
                // Only process geometries that are top-level roots (not referenced ones
                // used only as templates). We process the full tree from the
                // caller-selected root instead.
                _ = geo
            }
        }

        /// Walks `geometry` and its children, adding mesh nodes to `root`.
        ///
        /// - Parameters:
        ///   - geometry: Current geometry node to process.
        ///   - worldTransform: Accumulated transform from all ancestor geometries.
        ///     Identity for the root geometry of the tree being rendered.
        ///   - root: Destination node; all mesh nodes are added as direct children.
        ///   - modelOverride: Model name override from a `GeometryReference` parent.
        ///   - depth: Guard against infinite recursion in malformed files.
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
                walkReference(ref, parentTransform: worldTransform, into: root, depth: depth)
            default:
                // Accumulate this geometry's local transform (metres).
                let combined = worldTransform * geometry.position.matrix.float4x4

                let modelName = modelOverride ?? geometry.model
                if let modelName, let gdtfModel = modelMap[modelName],
                   let meshNode = makeMeshNode(gdtfModel: gdtfModel) {
                    // Determine the scale that converts mesh vertex units to metres.
                    // Compare the mesh bounding box against the GDTFModel's declared
                    // physical dimensions (Length/Width/Height, stored in metres).
                    let vertexScale = meshToMetresScale(gdtfModel: gdtfModel, meshNode: meshNode)
                    let scaleMat = simd_float4x4(diagonal: SIMD4<Float>(vertexScale, vertexScale, vertexScale, 1))
                    meshNode.simdTransform = combined * scaleMat
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

            let refTransform = ref.position.matrix.float4x4
            let combined = parentTransform * refTransform

            let tempRoot = SCNNode()
            walk(target, worldTransform: combined,
                 into: tempRoot, modelOverride: ref.model, depth: depth + 1)

            for child in tempRoot.childNodes {
                child.removeFromParentNode()
                root.addChildNode(child)
            }
        }

        /// Extracts the `.3ds` file for `gdtfModel` from the ZIP and builds
        /// a flat `SCNNode` containing all mesh objects (no extra hierarchy).
        private func makeMeshNode(gdtfModel: GDTFModel) -> SCNNode? {
            var raw: Data?
            for lod in GDTFModel.LOD.allCases {
                if let data = gdtfModel.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod) {
                    raw = data
                    break
                }
            }
            guard let data = raw,
                  let file = try? ThreeDSFile.parse(data: data) else { return nil }
            return file.sceneNodeRaw()
        }

        /// Computes the uniform scale that converts mesh vertex units to metres.
        ///
        /// The GDTF spec defines model dimensions (Length = X, Width = Y,
        /// Height = Z) in metres. The `.3ds` vertices may be authored in mm,
        /// cm, or any other unit. We compare the largest declared dimension
        /// against the mesh's actual bounding-box span along the same axis to
        /// derive the conversion factor.
        ///
        /// Falls back to 0.001 (mm → m) when the declared dimensions are zero
        /// or the mesh is degenerate.
        private func meshToMetresScale(gdtfModel: GDTFModel, meshNode: SCNNode) -> Float {
            let (mn, mx) = meshNode.boundingBox
            let meshSpanX = Double(mx.x) - Double(mn.x)
            let meshSpanY = Double(mx.y) - Double(mn.y)
            let meshSpanZ = Double(mx.z) - Double(mn.z)

            // GDTFModel: length = X, width = Y, height = Z (all in metres)
            let pairs: [(declared: Double, mesh: Double)] = [
                (gdtfModel.length, meshSpanX),
                (gdtfModel.width,  meshSpanY),
                (gdtfModel.height, meshSpanZ),
            ]

            // Use the axis with the largest declared dimension for the best
            // numerical stability.
            var bestScale: Double?
            var bestDeclared = 0.0
            for (declared, mesh) in pairs {
                if declared > bestDeclared && mesh > 0.0001 {
                    bestDeclared = declared
                    bestScale = declared / mesh
                }
            }

            return Float(bestScale ?? 0.001)
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
    keyLight.light!.intensity = 800
    keyLight.light!.color = PlatformColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1)
    keyLight.position = SCNVector3(1.5, 2, 1.5)
    scene.rootNode.addChildNode(keyLight)

    // Fill light (cool, lower-left-back)
    let fillLight = SCNNode()
    fillLight.light = SCNLight()
    fillLight.light!.type = .omni
    fillLight.light!.intensity = 300
    fillLight.light!.color = PlatformColor(red: 0.8, green: 0.88, blue: 1.0, alpha: 1)
    fillLight.position = SCNVector3(-1.5, -0.5, -1)
    scene.rootNode.addChildNode(fillLight)

    // Ambient fill
    let ambientNode = SCNNode()
    ambientNode.light = SCNLight()
    ambientNode.light!.type = .ambient
    ambientNode.light!.intensity = 200
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
    FixtureEntry(rid: "130017", name: "High End Systems SolaFrame Theatre"),
]

private enum PreviewLoadState {
    case loading
    case loaded(FixtureSceneBuilder, [String])   // builder + top-level geometry names
    case unavailable(String)
}

private struct GDTFFixturePickerPreview: View {
    @State private var selectedIndex: Int = 0
    @State private var state: PreviewLoadState = .loading
    @State private var selectedGeometry: String = ""

    private var selectedFixture: FixtureEntry { previewFixtures[selectedIndex] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Stepper(
                    "\(selectedIndex + 1)/\(previewFixtures.count)",
                    value: $selectedIndex,
                    in: 0...(previewFixtures.count - 1)
                )
                .fixedSize()

                Picker("Fixture", selection: $selectedIndex) {
                    ForEach(Array(previewFixtures.enumerated()), id: \.offset) { i, entry in
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
                        "No .3ds models",
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

        // Check that at least one top-level geometry has a .3ds model somewhere
        // in its subtree (otherwise it will render as empty).
        let hasAny3DS = gdtf.fixtureType.models.contains { model in
            GDTFModel.LOD.allCases.contains { lod in
                model.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod) != nil
            }
        }
        guard hasAny3DS else {
            state = .unavailable("Fixture \(rid) has no .3ds models.\nRun parseAllFixtures() to find a fixture with .3ds support.")
            return
        }

        let builder = FixtureSceneBuilder(gdtf: gdtf, gdtfData: gdtfData)
        let geometryNames = gdtf.fixtureType.geometries.map { $0.name }
        state = .loaded(builder, geometryNames)
        selectedGeometry = geometryNames.first ?? ""
    }
}

#Preview("GDTF Fixture Assembler") {
    GDTFFixturePickerPreview()
}
#endif
