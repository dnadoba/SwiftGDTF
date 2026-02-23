//
//  ThreeDSView.swift
//  SwiftGDTF
//
//  A SwiftUI view that renders a `ThreeDSFile` using SceneKit.
//  Each `ThreeDSObject` becomes an `SCNNode` with an `SCNGeometry` built
//  from the parsed vertex / face / UV data.  Materials are applied when a
//  matching `ThreeDSMaterial` is found.
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
}

// MARK: - Scene builder (shared)

private func buildScene(for file: ThreeDSFile) -> SCNScene {
    let scene = SCNScene()
    scene.rootNode.addChildNode(file.sceneNode())

    // Camera — looking at origin from -Z (GDTF coordinate system: Z up, Y into screen)
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.camera?.zNear = 0.001
    cameraNode.camera?.zFar = 100
    cameraNode.position = SCNVector3(0, 0, 2.5)
    scene.rootNode.addChildNode(cameraNode)

    // Key light (warm, upper-right-front)
    let keyLight = SCNNode()
    keyLight.light = SCNLight()
    keyLight.light!.type = .omni
    keyLight.light!.intensity = 800
    keyLight.light!.color = PlatformColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1)
    keyLight.position = SCNVector3(1.5, 1.5, 2)
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

// MARK: - Platform view wrapper

#if canImport(AppKit)
private struct SceneKitView: NSViewRepresentable {
    let file: ThreeDSFile

    func makeNSView(context: Context) -> SCNView {
        let v = SCNView()
        configure(v)
        return v
    }

    func updateNSView(_ v: SCNView, context: Context) {
        v.scene = buildScene(for: file)
    }

    private func configure(_ v: SCNView) {
        v.scene = buildScene(for: file)
        v.allowsCameraControl = true
        v.autoenablesDefaultLighting = false
        v.backgroundColor = NSColor.windowBackgroundColor
        v.antialiasingMode = .multisampling4X
    }
}
#elseif canImport(UIKit)
private struct SceneKitView: UIViewRepresentable {
    let file: ThreeDSFile

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        configure(v)
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        v.scene = buildScene(for: file)
    }

    private func configure(_ v: SCNView) {
        v.scene = buildScene(for: file)
        v.allowsCameraControl = true
        v.autoenablesDefaultLighting = false
        v.backgroundColor = UIColor.systemBackground
        v.antialiasingMode = .multisampling4X
    }
}
#endif

// MARK: - Public SwiftUI view

/// A SwiftUI view that displays a `ThreeDSFile` in an interactive SceneKit
/// viewport.  The user can orbit and zoom using standard trackpad / touch
/// gestures.
public struct ThreeDSView: View {
    public let file: ThreeDSFile

    public init(file: ThreeDSFile) {
        self.file = file
    }

    public var body: some View {
        SceneKitView(file: file)
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
    case loaded(ThreeDSFile, String)
    case unavailable(String)
}

private struct ThreeDSPickerPreview: View {
    @State private var selected: FixtureEntry = previewFixtures[0]
    @State private var state: PreviewLoadState = .loading

    var body: some View {
        VStack(spacing: 0) {
            Picker("Fixture", selection: $selected) {
                ForEach(previewFixtures) { entry in
                    Text(entry.name).tag(entry)
                }
            }
            .pickerStyle(.menu)
            .padding(8)

            Divider()

            Group {
                switch state {
                case .loading:
                    ProgressView("Loading…")
                case .loaded(let file, let modelName):
                    ThreeDSView(file: file)
                        .navigationTitle(modelName)
                case .unavailable(let message):
                    ContentUnavailableView(
                        "No .3ds model",
                        systemImage: "cube.transparent",
                        description: Text(message)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 600, height: 540)
        .task(id: selected.rid) { await load(rid: selected.rid, name: selected.name) }
    }

    private func load(rid: String, name: String) async {
        state = .loading
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwiftGDTF/Fixtures")
        let fixtureURL = cacheDir.appendingPathComponent("\(rid).gdtf")

        guard
            let gdtfData = try? Data(contentsOf: fixtureURL),
            let gdtf = try? loadGDTF(data: gdtfData),
            let (modelData, modelName) = gdtf.fixtureType.models.lazy.compactMap({ model -> (Data, String)? in
                for lod in GDTFModel.LOD.allCases {
                    if let data = model.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod) {
                        return (data, "\(model.name) (\(lod))")
                    }
                }
                return nil
            }).first,
            let file = try? ThreeDSFile.parse(data: modelData)
        else {
            state = .unavailable("Fixture \(rid) not in cache or has no .3ds models.\nRun parseAllFixtures() to populate the cache.")
            return
        }

        state = .loaded(file, "\(name) – \(modelName)")
    }
}

#Preview(".3ds Model Picker") {
    ThreeDSPickerPreview()
}
#endif
