//
//  MVRRendererComparisonTests.swift
//  SwiftGDTFTests
//
//  Renders all MVR test files from multiple angles for visual comparison.
//  Produces front/back/top/side views to verify geometry renders from all directions.
//

import Testing
import Foundation
import SwiftGDTF
import SceneKit
import simd

@Suite("MVR Multi-Angle Rendering")
struct MVRMultiAngleRenderingTests {
    static let fixturesURL = Bundle.module.resourceURL!.appendingPathComponent("MVRTestFixtures")
    static let outputDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MVRComparison")

    static let testFiles = [
        "Circle_Stage", "Demoshow_grandMA3", "Demostage_MVR", "Simple_Show",
        "scene_objects", "Midsize_w_GP", "Basic_Festival", "capture_demo_show",
        "Key_Arena_Remake_MVR", "Template_Stage1",
    ]

    @Test("Multi-angle renders for visual inspection", arguments: testFiles)
    func renderMultiAngle(fileName: String) throws {
        let url = Self.fixturesURL.appendingPathComponent("\(fileName).mvr")
        guard FileManager.default.fileExists(atPath: url.path) else {
            Issue.record("\(fileName).mvr not found"); return
        }
        let outDir = Self.outputDir.appendingPathComponent(fileName)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        var renderer = try MVRSceneKitRenderer(url: url)
        let (scene, stats) = renderer.buildScene()

        let angles: [(name: String, az: Float, el: Float)] = [
            ("front", 0.0, 0.25),
            ("back", .pi, 0.25),
            ("side", .pi/2, 0.2),
            ("top", 0.0, .pi/2 - 0.05),
            ("3qtr", 0.5, 0.35),
            ("closeup", 0.3, 0.15),  // closer view
        ]

        for (name, az, el) in angles {
            let img = renderer.renderToImage(scene, azimuth: az, elevation: el)
            let url = outDir.appendingPathComponent("\(name).png")
            if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try png.write(to: url)
            }
        }

        print("[\(fileName)] \(stats.fixtureCount)F / \(stats.geometryCount)G / \(stats.failedGDTFSpecs.count) failed — \(angles.count) angles saved to \(outDir.path)")

        // Basic sanity: scene should have some content
        #expect(stats.fixtureCount + stats.geometryCount > 0,
                "\(fileName): no content loaded at all")
    }
}
