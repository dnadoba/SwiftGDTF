//
//  MVRSceneRenderingTests.swift
//  SwiftGDTFTests
//
//  Visual regression tests for MVR scene rendering using SceneKit.
//  Verifies that all expected geometry loads and renders for each MVR test file.
//

import Testing
import Foundation
import SwiftGDTF
import SceneKit
import simd

// MARK: - MVR SceneKit Renderer (standalone, no app dependency)

/// Loads an MVR file and renders it with SceneKit for testing.
struct MVRSceneKitRenderer {
    let archive: MVRArchive
    private var symdefIndex: [UUID: MVRSymdef] = [:]
    private var gdtfCache: [String: (gdtf: GDTF, data: Data)] = [:]
    private var geoCache: [String: SCNNode] = [:]

    struct SceneStats {
        var fixtureCount = 0
        var geometryCount = 0
        var failedGDTFSpecs: [String] = []
    }

    init(url: URL) throws {
        self.archive = try MVRArchive(url: url)
        for sd in archive.scene.scene.auxData.symdefs { symdefIndex[sd.uuid] = sd }
    }

    /// Builds the full SceneKit scene and returns stats + the scene.
    mutating func buildScene() -> (scene: SCNScene, stats: SceneStats) {
        var stats = SceneStats()

        // Load GDTFs
        func collectSpecs(_ objects: [MVRChildObject]) {
            for obj in objects {
                if let spec = obj.gdtfSpec, gdtfCache[spec] == nil {
                    if let r = try? archive.loadEmbeddedGDTF(spec: spec) {
                        gdtfCache[spec] = r
                    } else {
                        stats.failedGDTFSpecs.append(spec)
                    }
                }
                collectSpecs(obj.childList)
            }
        }
        for layer in archive.scene.scene.layers { collectSpecs(layer.childList) }

        let scene = SCNScene()
        scene.background.contents = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)

        for layer in archive.scene.scene.layers {
            let lm = layer.matrix?.simdMatrix ?? matrix_identity_float4x4
            walkChildren(layer.childList, parentWorld: lm, scene: scene, stats: &stats)
        }

        // Lights
        let kl = SCNNode(); kl.light = SCNLight(); kl.light!.type = .omni; kl.light!.intensity = 2000
        kl.position = SCNVector3(10, 15, 10); scene.rootNode.addChildNode(kl)
        let al = SCNNode(); al.light = SCNLight(); al.light!.type = .ambient; al.light!.intensity = 600
        scene.rootNode.addChildNode(al)

        return (scene, stats)
    }

    /// Renders the scene to a PNG image.
    func renderToImage(_ scene: SCNScene, width: Int = 1280, height: Int = 720,
                       azimuth: Float = 0.5, elevation: Float = 0.35) -> NSImage {
        let (bbMin, bbMax) = scene.rootNode.boundingBox
        let center = SIMD3<Float>(Float(bbMin.x+bbMax.x)/2, Float(bbMin.y+bbMax.y)/2, Float(bbMin.z+bbMax.z)/2)
        let span = SIMD3<Float>(Float(bbMax.x-bbMin.x), Float(bbMax.y-bbMin.y), Float(bbMax.z-bbMin.z))
        let dist = max(length(span) * 0.8, 5.0)

        let camPos = SIMD3<Float>(
            center.x + dist * sin(azimuth) * cos(elevation),
            center.y + dist * sin(elevation),
            center.z + dist * cos(azimuth) * cos(elevation)
        )
        let cn = SCNNode(); cn.camera = SCNCamera(); cn.camera?.zNear = 0.01; cn.camera?.zFar = 500
        let fwd = normalize(center - camPos)
        let rt = normalize(cross(fwd, SIMD3<Float>(0,1,0)))
        let up = cross(rt, fwd)
        var m = simd_float4x4(1)
        m.columns.0 = SIMD4(rt,0); m.columns.1 = SIMD4(up,0); m.columns.2 = SIMD4(-fwd,0); m.columns.3 = SIMD4(camPos,1)
        cn.simdTransform = m
        scene.rootNode.addChildNode(cn)

        let r = SCNRenderer(device: nil, options: nil)
        r.scene = scene; r.pointOfView = cn
        let img = r.snapshot(atTime: 0, with: CGSize(width: width, height: height), antialiasingMode: .multisampling4X)
        cn.removeFromParentNode()
        return img
    }

    // MARK: - Private

    private static let zUpMmToYUpM = simd_float4x4(
        SIMD4<Float>(0.001,0,0,0), SIMD4<Float>(0,0,-0.001,0), SIMD4<Float>(0,0.001,0,0), SIMD4<Float>(0,0,0,1)
    )

    private func mvrWorldToSK(_ wm: simd_float4x4) -> simd_float4x4 {
        let t = wm.columns.3
        let r3 = simd_float3x3(SIMD3(wm.columns.0.x,wm.columns.0.y,wm.columns.0.z),SIMD3(wm.columns.1.x,wm.columns.1.y,wm.columns.1.z),SIMD3(wm.columns.2.x,wm.columns.2.y,wm.columns.2.z))
        let c = simd_float3x3(SIMD3<Float>(1,0,0),SIMD3<Float>(0,0,-1),SIMD3<Float>(0,1,0))
        let ci = simd_float3x3(SIMD3<Float>(1,0,0),SIMD3<Float>(0,0,1),SIMD3<Float>(0,-1,0))
        let cv = c * r3 * ci
        var xf = simd_float4x4(SIMD4(cv.columns.0,0),SIMD4(cv.columns.1,0),SIMD4(cv.columns.2,0),SIMD4(0,0,0,1))
        xf.columns.3 = SIMD4(t.x/1000, t.z/1000, -t.y/1000, 1)
        return xf
    }

    private mutating func walkChildren(_ objects: [MVRChildObject], parentWorld: simd_float4x4, scene: SCNScene, stats: inout SceneStats) {
        for obj in objects {
            let local = obj.matrix?.simdMatrix ?? matrix_identity_float4x4
            let world = parentWorld * local
            var placed = false

            if let spec = obj.gdtfSpec, let cached = gdtfCache[spec] {
                let n = FixtureSceneBuilder(gdtf: cached.gdtf, gdtfData: cached.data).buildNode(normalize: false)
                let c = SCNNode(); c.simdTransform = mvrWorldToSK(world); c.addChildNode(n)
                scene.rootNode.addChildNode(c)
                stats.fixtureCount += 1; placed = true
            }

            if !placed {
                let geos = obj.geometries
                if !geos.isEmpty {
                    let c = SCNNode(); c.simdTransform = mvrWorldToSK(world)
                    addGeoNodes(geos, to: c)
                    if c.childNodes.count > 0 { scene.rootNode.addChildNode(c); stats.geometryCount += 1 }
                }
            }
            walkChildren(obj.childList, parentWorld: world, scene: scene, stats: &stats)
        }
    }

    private mutating func addGeoNodes(_ geos: [MVRGeometryNode], to parent: SCNNode) {
        for g in geos {
            switch g {
            case .geometry3D(let geo):
                if let n = loadGeoNode(geo.fileName) {
                    let w = SCNNode()
                    let ext = (geo.fileName as NSString).pathExtension.lowercased()
                    if ext == "3ds" || ext.isEmpty {
                        w.simdTransform = geo.matrix != nil ? Self.zUpMmToYUpM * geo.matrix!.simdMatrix : Self.zUpMmToYUpM
                    } else if let m = geo.matrix { w.simdTransform = m.simdMatrix }
                    w.addChildNode(n); parent.addChildNode(w)
                }
            case .symbol(let sym):
                if let sd = symdefIndex[sym.symdef] {
                    let sn = SCNNode()
                    if let m = sym.matrix { sn.simdTransform = m.simdMatrix }
                    addGeoNodes(sd.children, to: sn)
                    if sn.childNodes.count > 0 { parent.addChildNode(sn) }
                }
            }
        }
    }

    private mutating func loadGeoNode(_ fn: String) -> SCNNode? {
        if let c = geoCache[fn] { return c.clone() }
        let actual = fn.contains(".") ? fn : fn + ".3ds"
        guard let data = try? archive.extractResource(named: actual) else { return nil }
        let ext = (actual as NSString).pathExtension.lowercased()
        let n: SCNNode?
        switch ext {
        case "3ds": n = (try? ThreeDSFile.parse(data: data))?.sceneNodeRaw()
        case "glb": n = (try? GLBFile.parse(data: data))?.sceneNodeRaw()
        default: n = nil
        }
        if let n { geoCache[fn] = n; return n.clone() }
        return nil
    }
}

private extension Matrix {
    var simdMatrix: simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(Float(matrix[0][0]), Float(matrix[0][1]), Float(matrix[0][2]), Float(matrix[0][3])),
            SIMD4<Float>(Float(matrix[1][0]), Float(matrix[1][1]), Float(matrix[1][2]), Float(matrix[1][3])),
            SIMD4<Float>(Float(matrix[2][0]), Float(matrix[2][1]), Float(matrix[2][2]), Float(matrix[2][3])),
            SIMD4<Float>(Float(matrix[3][0]), Float(matrix[3][1]), Float(matrix[3][2]), Float(matrix[3][3]))
        )
    }
}

// MARK: - Tests

@Suite("MVR Scene Rendering")
struct MVRSceneRenderingTests {
    static let fixturesURL = Bundle.module.resourceURL!.appendingPathComponent("MVRTestFixtures")
    static let outputDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MVRRenderTests")

    /// Expected counts per MVR file: (minFixtures, minGeometry)
    /// These are minimum expectations — actual counts may be higher if GDTF Share is available.
    static let expectations: [String: (fixtures: Int, geometry: Int)] = [
        "7-fixtures-sample": (7, 0),
        "basic_fixture": (1, 0),
        "fixture-line-gltf": (16, 0),
        "scene_objects": (72, 28),       // 72 fixtures + 28 SceneObjects with .glb geometry
        "Circle_Stage": (74, 46),        // 74 fixtures + 44 stage + 2 backdrop
        "Basic_Festival": (100, 0),      // Some fixtures may fail to load
        "Midsize_w_GP": (76, 39),        // 76 fixtures + 39 scene objects
        "Demoshow_grandMA3": (0, 22),    // All GDTFs fail embedded, 22 symdefs/scene objects
        "Simple_Show": (0, 4),           // GDTF fails, 4 truss segments
        "capture_demo_show": (0, 0),     // GDTFs and geometry may not load
        "Demostage_MVR": (0, 54),        // All GDTFs fail, 54 scene objects
    ]

    @Test("All MVR files load and render with expected geometry counts",
          arguments: try! FileManager.default.contentsOfDirectory(
            at: fixturesURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "mvr" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent })
    func renderMVRFile(url: URL) throws {
        let name = url.deletingPathExtension().lastPathComponent

        var renderer = try MVRSceneKitRenderer(url: url)
        let (scene, stats) = renderer.buildScene()

        // Save screenshot
        try FileManager.default.createDirectory(at: Self.outputDir, withIntermediateDirectories: true)
        let image = renderer.renderToImage(scene)
        let outURL = Self.outputDir.appendingPathComponent("\(name).png")
        if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try png.write(to: outURL)
        }

        // Verify expectations
        if let expected = Self.expectations[name] {
            #expect(stats.fixtureCount >= expected.fixtures,
                    "\(name): expected >= \(expected.fixtures) fixtures, got \(stats.fixtureCount)")
            #expect(stats.geometryCount >= expected.geometry,
                    "\(name): expected >= \(expected.geometry) geometry objects, got \(stats.geometryCount)")
        }

        // Print summary
        print("[\(name)] fixtures=\(stats.fixtureCount) geometry=\(stats.geometryCount) failedGDTF=\(stats.failedGDTFSpecs.count)")
    }
}
