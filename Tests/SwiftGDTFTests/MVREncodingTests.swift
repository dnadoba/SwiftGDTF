import Testing
import Foundation
@testable import SwiftGDTF

// MARK: - Diffing Helper

/// Walks two MVR scenes and returns a human-readable description of the first difference found.
/// Returns nil if the scenes are equal.
func mvrSceneDiff(_ a: MVRScene, _ b: MVRScene) -> String? {
    if a.verMajor != b.verMajor { return "verMajor: \(a.verMajor) vs \(b.verMajor)" }
    if a.verMinor != b.verMinor { return "verMinor: \(a.verMinor) vs \(b.verMinor)" }
    if a.provider != b.provider { return "provider: '\(a.provider)' vs '\(b.provider)'" }
    if a.providerVersion != b.providerVersion { return "providerVersion: '\(a.providerVersion)' vs '\(b.providerVersion)'" }
    if a.userData.count != b.userData.count { return "userData count: \(a.userData.count) vs \(b.userData.count)" }
    for (i, (ua, ub)) in zip(a.userData, b.userData).enumerated() {
        if ua != ub { return "userData[\(i)]: provider='\(ua.provider)' vs '\(ub.provider)', content='\(ua.content)' vs '\(ub.content)'" }
    }
    return mvrSceneNodeDiff(a.scene, b.scene, path: "scene")
}

private func mvrSceneNodeDiff(_ a: MVRSceneNode, _ b: MVRSceneNode, path: String) -> String? {
    if let d = mvrAuxDataDiff(a.auxData, b.auxData, path: "\(path).auxData") { return d }
    if a.layers.count != b.layers.count { return "\(path).layers count: \(a.layers.count) vs \(b.layers.count)" }
    for (i, (la, lb)) in zip(a.layers, b.layers).enumerated() {
        if let d = mvrLayerDiff(la, lb, path: "\(path).layers[\(i)]") { return d }
    }
    return nil
}

private func mvrAuxDataDiff(_ a: MVRAUXData, _ b: MVRAUXData, path: String) -> String? {
    if a.symdefs.count != b.symdefs.count { return "\(path).symdefs count: \(a.symdefs.count) vs \(b.symdefs.count)" }
    for (i, (sa, sb)) in zip(a.symdefs, b.symdefs).enumerated() {
        if sa != sb { return "\(path).symdefs[\(i)] '\(sa.name)' differs" }
    }
    if a.positions.count != b.positions.count { return "\(path).positions count: \(a.positions.count) vs \(b.positions.count)" }
    for (i, (pa, pb)) in zip(a.positions, b.positions).enumerated() {
        if pa != pb { return "\(path).positions[\(i)] '\(pa.name)' differs" }
    }
    if a.mappingDefinitions.count != b.mappingDefinitions.count { return "\(path).mappingDefinitions count: \(a.mappingDefinitions.count) vs \(b.mappingDefinitions.count)" }
    for (i, (ma, mb)) in zip(a.mappingDefinitions, b.mappingDefinitions).enumerated() {
        if ma != mb { return "\(path).mappingDefinitions[\(i)] '\(ma.name)' differs" }
    }
    if a.classes.count != b.classes.count { return "\(path).classes count: \(a.classes.count) vs \(b.classes.count)" }
    for (i, (ca, cb)) in zip(a.classes, b.classes).enumerated() {
        if ca != cb { return "\(path).classes[\(i)] '\(ca.name)' differs" }
    }
    return nil
}

private func mvrLayerDiff(_ a: MVRLayer, _ b: MVRLayer, path: String) -> String? {
    if a.uuid != b.uuid { return "\(path).uuid: \(a.uuid) vs \(b.uuid)" }
    if a.name != b.name { return "\(path).name: '\(a.name)' vs '\(b.name)'" }
    if a.matrix != b.matrix { return "\(path).matrix differs" }
    return mvrChildListDiff(a.childList, b.childList, path: "\(path).childList")
}

private func mvrChildListDiff(_ a: [MVRChildObject], _ b: [MVRChildObject], path: String) -> String? {
    if a.count != b.count { return "\(path) count: \(a.count) vs \(b.count)" }
    for (i, (ca, cb)) in zip(a, b).enumerated() {
        if ca.kind != cb.kind { return "\(path)[\(i)] kind: \(ca.kind) vs \(cb.kind)" }
        if ca.uuid != cb.uuid { return "\(path)[\(i)] uuid: \(ca.uuid) vs \(cb.uuid)" }
        if ca.name != cb.name { return "\(path)[\(i)] name: '\(ca.name)' vs '\(cb.name)'" }
        if ca != cb {
            // Recurse into children for more detail
            if let d = mvrChildListDiff(ca.childList, cb.childList, path: "\(path)[\(i)].childList") { return d }
            return "\(path)[\(i)] '\(ca.name)' (\(ca.kind)) differs in fields"
        }
    }
    return nil
}

// MARK: - Suite A: Round-Trip Tests

extension MVRTestFixture: CustomTestStringConvertible {
    public var testDescription: String { filename }
}

@Suite("MVR Round-Trip Encoding")
struct MVRRoundTripTests {

    @Test("Scene round-trips through encode/decode", arguments: allMVRTestFixtures)
    func sceneRoundTrip(fixture: MVRTestFixture) throws {
        let originalData = try Data(contentsOf: fixture.url)
        let originalScene = try loadMVR(data: originalData)

        let encodedData = try encodeMVR(scene: originalScene)
        let decodedScene = try loadMVR(data: encodedData)

        let diff = mvrSceneDiff(originalScene, decodedScene)
        #expect(originalScene == decodedScene, "Round-trip mismatch for \(fixture.filename): \(diff ?? "unknown")")
    }

    @Test("Archive round-trips with resources preserved", arguments: allMVRTestFixtures)
    func archiveRoundTrip(fixture: MVRTestFixture) throws {
        let originalArchive = try MVRArchive(url: fixture.url)
        let originalResourceNames = try Set(originalArchive.resourceNames)

        let reEncodedData = try originalArchive.encode()
        let reDecodedArchive = try MVRArchive(data: reEncodedData)

        // Scene must match
        let diff = mvrSceneDiff(originalArchive.scene, reDecodedArchive.scene)
        #expect(originalArchive.scene == reDecodedArchive.scene,
                "Archive round-trip scene mismatch for \(fixture.filename): \(diff ?? "unknown")")

        // Resources must be preserved
        let reDecodedResourceNames = try Set(reDecodedArchive.resourceNames)
        #expect(originalResourceNames == reDecodedResourceNames,
                "Resource names differ for \(fixture.filename): missing=\(originalResourceNames.subtracting(reDecodedResourceNames)), extra=\(reDecodedResourceNames.subtracting(originalResourceNames))")

        // Verify resource data matches
        for name in originalResourceNames {
            let origData = try originalArchive.extractResource(named: name)
            let reData = try reDecodedArchive.extractResource(named: name)
            #expect(origData == reData, "Resource '\(name)' data differs for \(fixture.filename) (original: \(origData.count) bytes, re-encoded: \(reData.count) bytes)")
        }
    }
}

// MARK: - Suite B: Construction Tests

@Suite("MVR Construction Encoding")
struct MVRConstructionTests {

    @Test func minimalScene() throws {
        let layerUUID = UUID()
        let fixtureUUID = UUID()
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: layerUUID, name: "Main", childList: [
                    .fixture(MVRFixture(
                        uuid: fixtureUUID,
                        name: "Spot 1",
                        gdtfSpec: "Generic@Spot.gdtf",
                        gdtfMode: "Standard",
                        fixtureID: "1",
                        addresses: [.address(MVRAddress(break: 0, dmxAddress: DMXAddress(universe: 1, address: 1)))]
                    ))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "Minimal scene round-trip failed: \(diff ?? "unknown")")
    }

    @Test func sceneWithAuxData() throws {
        let symdefUUID = UUID()
        let positionUUID = UUID()
        let classUUID = UUID()
        let mappingUUID = UUID()
        let layerUUID = UUID()

        let scene = MVRScene(
            scene: MVRSceneNode(
                auxData: MVRAUXData(
                    symdefs: [MVRSymdef(uuid: symdefUUID, name: "MySymdef", children: [
                        .geometry3D(MVRGeometry3D(fileName: "model.3ds"))
                    ])],
                    positions: [MVRPosition(uuid: positionUUID, name: "FOH")],
                    mappingDefinitions: [MVRMappingDefinition(uuid: mappingUUID, name: "Video1", sizeX: 1920, sizeY: 1080)],
                    classes: [MVRClass(uuid: classUUID, name: "Spots")]
                ),
                layers: [MVRLayer(uuid: layerUUID, name: "Main")]
            )
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "AuxData round-trip failed: \(diff ?? "unknown")")
    }

    @Test func allChildObjectTypes() throws {
        let layerUUID = UUID()
        let children: [MVRChildObject] = [
            .sceneObject(MVRSceneObject(uuid: UUID(), name: "SO")),
            .groupObject(MVRGroupObject(uuid: UUID(), name: "GO")),
            .focusPoint(MVRFocusPoint(uuid: UUID(), name: "FP")),
            .fixture(MVRFixture(uuid: UUID(), name: "FX", fixtureID: "1")),
            .truss(MVRTruss(uuid: UUID(), name: "TR")),
            .support(MVRSupport(uuid: UUID(), name: "SP")),
            .videoScreen(MVRVideoScreen(uuid: UUID(), name: "VS")),
            .projector(MVRProjector(uuid: UUID(), name: "PJ")),
        ]

        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: layerUUID, name: "All Types", childList: children)
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "All child types round-trip failed: \(diff ?? "unknown")")
        #expect(decoded.scene.layers[0].childList.count == 8)
        let kinds = decoded.scene.layers[0].childList.map(\.kind)
        #expect(kinds == [.sceneObject, .groupObject, .focusPoint, .fixture, .truss, .support, .videoScreen, .projector])
    }

    @Test func nestedGroupObjects() throws {
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", childList: [
                    .groupObject(MVRGroupObject(uuid: UUID(), name: "G1", childList: [
                        .groupObject(MVRGroupObject(uuid: UUID(), name: "G2", childList: [
                            .groupObject(MVRGroupObject(uuid: UUID(), name: "G3", childList: [
                                .fixture(MVRFixture(uuid: UUID(), name: "Deep Fixture", fixtureID: "1"))
                            ]))
                        ]))
                    ]))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "Nested groups round-trip failed: \(diff ?? "unknown")")

        // Verify depth
        guard case .groupObject(let g1) = decoded.scene.layers[0].childList[0],
              case .groupObject(let g2) = g1.childList[0],
              case .groupObject(let g3) = g2.childList[0],
              case .fixture(let f) = g3.childList[0] else {
            Issue.record("Expected 3 levels of nesting with a fixture at the bottom")
            return
        }
        #expect(f.name == "Deep Fixture")
    }

    @Test func fixtureWithAllFields() throws {
        let posUUID = UUID()
        let focusUUID = UUID()
        let classUUID = UUID()
        let connTargetUUID = UUID()
        let mappingDefUUID = UUID()
        let multipatchUUID = UUID()

        let matrix = try Matrix(fromMVR: "{0.707107,0.707107,0}{-0.707107,0.707107,0}{0,0,1}{1000,2000,3000}")

        let fixture = MVRFixture(
            uuid: UUID(),
            name: "Full Fixture",
            multipatch: multipatchUUID,
            matrix: matrix,
            classing: classUUID,
            gdtfSpec: "Manufacturer@Fixture.gdtf",
            gdtfMode: "Extended",
            focus: focusUUID,
            castShadow: true,
            dmxInvertPan: true,
            dmxInvertTilt: false,
            position: posUUID,
            function: "Wash",
            fixtureID: "42",
            fixtureIDNumeric: 42,
            unitNumber: 7,
            childPosition: "Head",
            addresses: [
                .address(MVRAddress(break: 0, dmxAddress: DMXAddress(universe: 1, address: 1))),
                .address(MVRAddress(break: 1, dmxAddress: DMXAddress(universe: 2, address: 100))),
                .network(MVRNetwork(geometry: "ethernet_1", ipv4: "192.168.0.10", subnetMask: "255.255.255.0", dhcp: false)),
            ],
            protocols: [MVRProtocol(geometry: "NetworkInOut_1", name: "sACN", type: "sACN", version: "1.31")],
            alignments: [MVRAlignment(
                geometry: "Beam",
                up: Vector3(vector: .init(0, 0, 1)),
                direction: Vector3(vector: .init(0, 0, -1))
            )],
            customCommands: ["SetColor Red", "EnableStrobe"],
            overwrites: [MVROverwrite(universal: "Gobo1.Slot2", target: "Gobo1")],
            connections: [MVRConnection(own: "Power_1", toObject: connTargetUUID, other: "Power_In")],
            color: ColorCIE(x: 0.3127, y: 0.329, Y: 1.0),
            customIdType: 5,
            customId: 12,
            mappings: [MVRMapping(linkedDef: mappingDefUUID, ux: 0, uy: 0, ox: 1920, oy: 1080, rz: 45.0)],
            gobo: MVRGobo(rotation: 30.0, fileName: "gobo_star.png")
        )

        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "Full", childList: [.fixture(fixture)])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "Full fixture round-trip failed: \(diff ?? "unknown")")
    }

    @Test func geometryNodes() throws {
        let symdefUUID = UUID()
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", childList: [
                    .sceneObject(MVRSceneObject(
                        uuid: UUID(),
                        name: "With Geometry",
                        geometries: [
                            .geometry3D(MVRGeometry3D(fileName: "model.3ds")),
                            .symbol(MVRSymbol(uuid: UUID(), symdef: symdefUUID)),
                        ]
                    ))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "Geometry nodes round-trip failed: \(diff ?? "unknown")")
    }

    @Test func userData() throws {
        let scene = MVRScene(
            userData: [
                MVRUserData(provider: "TestApp", ver: "1.0", content: "some custom data"),
                MVRUserData(provider: "OtherApp", ver: "2.5", content: "<xml>nested</xml>"),
            ],
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L")
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "UserData round-trip failed: \(diff ?? "unknown")")
    }

    @Test func matrixPreservation() throws {
        // Non-identity rotation + translation
        let matrix = try Matrix(fromMVR: "{0.158127,-0.987419,0.000000}{0.987419,0.158127,0.000000}{0.000000,0.000000,1.000000}{6020.939200,2838.588955,4978.134459}")

        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", matrix: matrix, childList: [
                    .fixture(MVRFixture(uuid: UUID(), name: "F", matrix: matrix, fixtureID: "1"))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        // Use approximate comparison for matrix values due to float formatting
        let origMatrix = scene.scene.layers[0].matrix!.matrix
        let decodedMatrix = decoded.scene.layers[0].matrix!.matrix
        for col in 0..<4 {
            for row in 0..<4 {
                let orig = origMatrix[col][row]
                let dec = decodedMatrix[col][row]
                #expect(abs(orig - dec) < 1e-4,
                        "Matrix[\(col)][\(row)] drift: \(orig) vs \(dec)")
            }
        }
    }

    @Test func resourcesPreserved() throws {
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", childList: [
                    .fixture(MVRFixture(uuid: UUID(), name: "F", gdtfSpec: "Test@Fixture.gdtf", fixtureID: "1"))
                ])
            ])
        )

        let fakeGDTF = Data([0x50, 0x4B, 0x03, 0x04]) // PK header
        let resources = ["Test@Fixture.gdtf": fakeGDTF, "texture.png": Data(repeating: 0xFF, count: 100)]

        let encoded = try encodeMVR(scene: scene, resources: resources)
        let archive = try MVRArchive(data: encoded)

        let names = try Set(archive.resourceNames)
        #expect(names == ["Test@Fixture.gdtf", "texture.png"])

        let extractedGDTF = try archive.extractResource(named: "Test@Fixture.gdtf")
        #expect(extractedGDTF == fakeGDTF)
        let extractedTexture = try archive.extractResource(named: "texture.png")
        #expect(extractedTexture == resources["texture.png"])
    }

    @Test func emptyScene() throws {
        let scene = MVRScene(scene: MVRSceneNode())

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        #expect(decoded.verMajor == 1)
        #expect(decoded.verMinor == 6)
        #expect(decoded.scene.layers.isEmpty)
    }

    @Test func mappingDefinitionWithSourceAndScaleHandling() throws {
        let scene = MVRScene(
            scene: MVRSceneNode(
                auxData: MVRAUXData(
                    mappingDefinitions: [
                        MVRMappingDefinition(
                            uuid: UUID(),
                            name: "VideoFeed",
                            sizeX: 3840,
                            sizeY: 2160,
                            source: MVRSource(linkedGeometry: "Display_1", type: .ndi, value: "NDI Stream 1"),
                            scaleHandling: .scaleKeepRatio
                        )
                    ]
                ),
                layers: [MVRLayer(uuid: UUID(), name: "L")]
            )
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "MappingDefinition round-trip failed: \(diff ?? "unknown")")
    }

    @Test func projectorWithProjections() throws {
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", childList: [
                    .projector(MVRProjector(
                        uuid: UUID(),
                        name: "Proj1",
                        projections: [
                            MVRProjection(
                                sources: [MVRSource(linkedGeometry: "Beam_1", type: .file, value: "content.mp4")],
                                scaleHandling: .scaleIgnoreRatio
                            )
                        ]
                    ))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "Projector round-trip failed: \(diff ?? "unknown")")
    }

    @Test func videoScreenWithSources() throws {
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", childList: [
                    .videoScreen(MVRVideoScreen(
                        uuid: UUID(),
                        name: "Screen1",
                        sources: [MVRSource(linkedGeometry: "Display_1", type: .citp, value: "CITP Layer 1")]
                    ))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "VideoScreen round-trip failed: \(diff ?? "unknown")")
    }

    @Test func supportWithChainLength() throws {
        let scene = MVRScene(
            scene: MVRSceneNode(layers: [
                MVRLayer(uuid: UUID(), name: "L", childList: [
                    .support(MVRSupport(uuid: UUID(), name: "Chain Motor", chainLength: 5.5))
                ])
            ])
        )

        let encoded = try encodeMVR(scene: scene)
        let decoded = try loadMVR(data: encoded)

        let diff = mvrSceneDiff(scene, decoded)
        #expect(scene == decoded, "Support round-trip failed: \(diff ?? "unknown")")
    }
}
