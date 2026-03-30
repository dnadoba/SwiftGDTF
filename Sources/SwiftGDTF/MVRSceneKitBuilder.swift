import Foundation
import SceneKit
import simd

/// Builds a SceneKit scene from an MVR archive.
///
/// Handles coordinate conversion (MVR Z-up mm → SceneKit Y-up meters),
/// GDTF fixture instantiation via FixtureSceneBuilder, and inline geometry loading.
public struct MVRSceneKitBuilder {
    private var archive: MVRArchive
    private var gdtfCache: [String: (gdtf: GDTF, data: Data)]
    private var symdefIndex: [UUID: MVRSymdef] = [:]
    private var geoCache: [String: SCNNode] = [:]

    public struct BuildResult: Sendable {
        public var fixtureCount: Int = 0
        public var geometryCount: Int = 0
        public var failedGDTFSpecs: [String] = []
    }

    public init(archive: MVRArchive, gdtfOverrides: [String: (gdtf: GDTF, data: Data)] = [:]) {
        self.archive = archive
        self.gdtfCache = gdtfOverrides
        for sd in archive.scene.scene.auxData.symdefs {
            symdefIndex[sd.uuid] = sd
        }
    }

    /// Builds the SceneKit scene with all fixtures, geometry, lights, and floor grid.
    public mutating func buildScene(
        includeFloor: Bool = true,
        includeLights: Bool = true
    ) -> (scene: SCNScene, stats: BuildResult) {
        loadEmbeddedGDTFs()

        let scene = SCNScene()
        scene.background.contents = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)

        var stats = BuildResult()
        stats.failedGDTFSpecs = gdtfCache.keys.isEmpty ? [] : []

        for layer in archive.scene.scene.layers {
            let lm = layer.matrix?.simdMatrix ?? matrix_identity_float4x4
            walkChildren(layer.childList, parentWorld: lm, parentNode: scene.rootNode, stats: &stats)
        }

        if includeLights {
            Self.addDefaultLights(to: scene)
        }

        if includeFloor {
            scene.rootNode.addChildNode(Self.makeGridFloor())
        }

        return (scene, stats)
    }

    /// Renders the scene to an NSImage from a given camera angle.
    public static func renderToImage(
        _ scene: SCNScene,
        width: Int = 1280,
        height: Int = 720,
        azimuth: Float = 0.5,
        elevation: Float = 0.35
    ) -> NSImage {
        let (bbMin, bbMax) = scene.rootNode.boundingBox
        let center = SIMD3<Float>(
            Float(bbMin.x + bbMax.x) / 2,
            Float(bbMin.y + bbMax.y) / 2,
            Float(bbMin.z + bbMax.z) / 2
        )
        let span = SIMD3<Float>(
            Float(bbMax.x - bbMin.x),
            Float(bbMax.y - bbMin.y),
            Float(bbMax.z - bbMin.z)
        )
        let dist = max(length(span) * 0.8, 5.0)

        let camPos = SIMD3<Float>(
            center.x + dist * sin(azimuth) * cos(elevation),
            center.y + dist * sin(elevation),
            center.z + dist * cos(azimuth) * cos(elevation)
        )

        let cn = SCNNode()
        cn.camera = SCNCamera()
        cn.camera?.zNear = 0.01
        cn.camera?.zFar = 500
        let fwd = normalize(center - camPos)
        let rt = normalize(cross(fwd, SIMD3<Float>(0, 1, 0)))
        let up = cross(rt, fwd)
        var m = simd_float4x4(1)
        m.columns.0 = SIMD4(rt, 0)
        m.columns.1 = SIMD4(up, 0)
        m.columns.2 = SIMD4(-fwd, 0)
        m.columns.3 = SIMD4(camPos, 1)
        cn.simdTransform = m
        scene.rootNode.addChildNode(cn)

        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        renderer.pointOfView = cn
        let img = renderer.snapshot(
            atTime: 0,
            with: CGSize(width: width, height: height),
            antialiasingMode: .multisampling4X
        )
        cn.removeFromParentNode()
        return img
    }

    /// Saves an NSImage as a PNG file.
    public static func savePNG(_ image: NSImage, to url: URL) throws {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            return
        }
        try png.write(to: url)
    }

    // MARK: - Coordinate Conversion

    /// Matrix converting MVR Z-up mm vertices to Y-up meters.
    /// (x,y,z) → (x/1000, z/1000, -y/1000)
    public static let zUpMmToYUpMeters = simd_float4x4(
        SIMD4<Float>(0.001,  0,      0,     0),
        SIMD4<Float>(0,      0,     -0.001, 0),
        SIMD4<Float>(0,      0.001,  0,     0),
        SIMD4<Float>(0,      0,      0,     1)
    )

    /// Converts an MVR Z-up world matrix to a Y-up SceneKit transform (mm → meters + rotation).
    public static func mvrWorldToYUpTransform(_ worldMatrix: simd_float4x4) -> simd_float4x4 {
        let t = worldMatrix.columns.3
        let r3 = simd_float3x3(
            SIMD3(worldMatrix.columns.0.x, worldMatrix.columns.0.y, worldMatrix.columns.0.z),
            SIMD3(worldMatrix.columns.1.x, worldMatrix.columns.1.y, worldMatrix.columns.1.z),
            SIMD3(worldMatrix.columns.2.x, worldMatrix.columns.2.y, worldMatrix.columns.2.z)
        )
        let c = simd_float3x3(
            SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 0, -1), SIMD3<Float>(0, 1, 0)
        )
        let ci = simd_float3x3(
            SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 0, 1), SIMD3<Float>(0, -1, 0)
        )
        let cv = c * r3 * ci
        var xf = simd_float4x4(
            SIMD4(cv.columns.0, 0), SIMD4(cv.columns.1, 0),
            SIMD4(cv.columns.2, 0), SIMD4(0, 0, 0, 1)
        )
        xf.columns.3 = SIMD4(t.x / 1000, t.z / 1000, -t.y / 1000, 1)
        return xf
    }

    // MARK: - Private

    private mutating func loadEmbeddedGDTFs() {
        func collectSpecs(_ objects: [MVRChildObject]) {
            for obj in objects {
                if let spec = obj.gdtfSpec, gdtfCache[spec] == nil {
                    if let r = try? archive.loadEmbeddedGDTF(spec: spec) {
                        gdtfCache[spec] = r
                    }
                }
                collectSpecs(obj.childList)
            }
        }
        for layer in archive.scene.scene.layers { collectSpecs(layer.childList) }
    }

    private mutating func walkChildren(
        _ objects: [MVRChildObject],
        parentWorld: simd_float4x4,
        parentNode: SCNNode,
        stats: inout BuildResult
    ) {
        for obj in objects {
            let local = obj.matrix?.simdMatrix ?? matrix_identity_float4x4
            let world = parentWorld * local
            var placed = false

            if let spec = obj.gdtfSpec, let cached = gdtfCache[spec] {
                let n = FixtureSceneBuilder(gdtf: cached.gdtf, gdtfData: cached.data)
                    .buildNode(normalize: false)
                let c = SCNNode()
                c.simdTransform = Self.mvrWorldToYUpTransform(world)
                c.addChildNode(n)
                parentNode.addChildNode(c)
                stats.fixtureCount += 1
                placed = true
            } else if let spec = obj.gdtfSpec, !stats.failedGDTFSpecs.contains(spec) {
                stats.failedGDTFSpecs.append(spec)
            }

            if !placed {
                let geos = obj.geometries
                if !geos.isEmpty {
                    let c = SCNNode()
                    c.simdTransform = Self.mvrWorldToYUpTransform(world)
                    addGeoNodes(geos, to: c)
                    if c.childNodes.count > 0 {
                        parentNode.addChildNode(c)
                        stats.geometryCount += 1
                    }
                }
            }
            walkChildren(obj.childList, parentWorld: world, parentNode: parentNode, stats: &stats)
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
                        w.simdTransform = geo.matrix != nil
                            ? Self.zUpMmToYUpMeters * geo.matrix!.simdMatrix
                            : Self.zUpMmToYUpMeters
                    } else if let m = geo.matrix {
                        w.simdTransform = m.simdMatrix
                    }
                    w.addChildNode(n)
                    parent.addChildNode(w)
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

    private static func addDefaultLights(to scene: SCNScene) {
        // Key light (warm, from upper-right-front)
        let kl = SCNNode()
        kl.light = SCNLight()
        kl.light!.type = .directional
        kl.light!.intensity = 1000
        kl.light!.color = NSColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1)
        kl.simdEulerAngles = SIMD3<Float>(-0.6, 0.4, 0)
        scene.rootNode.addChildNode(kl)

        // Fill light (cool, from behind)
        let fl = SCNNode()
        fl.light = SCNLight()
        fl.light!.type = .directional
        fl.light!.intensity = 400
        fl.light!.color = NSColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1)
        fl.simdEulerAngles = SIMD3<Float>(0.3, .pi + 0.5, 0)
        scene.rootNode.addChildNode(fl)

        // Ambient
        let al = SCNNode()
        al.light = SCNLight()
        al.light!.type = .ambient
        al.light!.intensity = 400
        al.light!.color = NSColor(white: 0.9, alpha: 1)
        scene.rootNode.addChildNode(al)
    }

    // MARK: - Grid Floor

    /// Creates a large floor plane with a 1-meter grid pattern.
    public static func makeGridFloor() -> SCNNode {
        let size: CGFloat = 200
        let plane = SCNPlane(width: size, height: size)
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.lightingModel = .constant
        plane.firstMaterial?.diffuse.contents = makeGridImage(
            cellSize: 64, lineWidth: 1,
            bgColor: NSColor(white: 0.04, alpha: 1),
            lineColor: NSColor(white: 0.15, alpha: 1)
        )
        plane.firstMaterial?.diffuse.wrapS = .repeat
        plane.firstMaterial?.diffuse.wrapT = .repeat
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(size, size, 1)

        let node = SCNNode(geometry: plane)
        node.simdEulerAngles = SIMD3<Float>(-.pi / 2, 0, 0)
        return node
    }

    private static func makeGridImage(
        cellSize: Int, lineWidth: Int, bgColor: NSColor, lineColor: NSColor
    ) -> NSImage {
        let img = NSImage(size: NSSize(width: cellSize, height: cellSize))
        img.lockFocus()
        bgColor.setFill()
        NSRect(x: 0, y: 0, width: cellSize, height: cellSize).fill()
        lineColor.setFill()
        NSRect(x: 0, y: 0, width: cellSize, height: lineWidth).fill()
        NSRect(x: 0, y: 0, width: lineWidth, height: cellSize).fill()
        img.unlockFocus()
        return img
    }
}
