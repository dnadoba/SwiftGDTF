import Testing
import Foundation
import SwiftGDTF
import SceneKit
import simd

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
        "scene_objects": (72, 28),
        "Circle_Stage": (74, 46),
        "Basic_Festival": (100, 0),
        "Midsize_w_GP": (76, 39),
        "Demoshow_grandMA3": (0, 22),
        "Simple_Show": (0, 4),
        "capture_demo_show": (0, 0),
        "Demostage_MVR": (0, 54),
    ]

    @Test("All MVR files load and render with expected geometry counts",
          arguments: try! FileManager.default.contentsOfDirectory(
            at: fixturesURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "mvr" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent })
    func renderMVRFile(url: URL) throws {
        let name = url.deletingPathExtension().lastPathComponent

        let archive = try MVRArchive(url: url)
        var builder = MVRSceneKitBuilder(archive: archive)
        let (scene, stats) = builder.buildScene()

        // Save screenshot
        try FileManager.default.createDirectory(at: Self.outputDir, withIntermediateDirectories: true)
        let image = MVRSceneKitBuilder.renderToImage(scene)
        try MVRSceneKitBuilder.savePNG(image, to: Self.outputDir.appendingPathComponent("\(name).png"))

        // Verify expectations
        if let expected = Self.expectations[name] {
            #expect(stats.fixtureCount >= expected.fixtures,
                    "\(name): expected >= \(expected.fixtures) fixtures, got \(stats.fixtureCount)")
            #expect(stats.geometryCount >= expected.geometry,
                    "\(name): expected >= \(expected.geometry) geometry objects, got \(stats.geometryCount)")
        }

        print("[\(name)] fixtures=\(stats.fixtureCount) geometry=\(stats.geometryCount) failedGDTF=\(stats.failedGDTFSpecs.count)")
    }
}
