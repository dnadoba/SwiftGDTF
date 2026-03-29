import Testing
import Foundation
@testable import SwiftGDTF

@Suite("MVR Matrix Parsing")
struct MVRMatrixParsingTests {

    @Test func validIdentityMatrix() throws {
        let m = try Matrix(fromMVR: "{1,0,0}{0,1,0}{0,0,1}{0,0,0}")
        // Identity rotation, zero translation
        #expect(m.matrix[0][0] == 1)
        #expect(m.matrix[1][1] == 1)
        #expect(m.matrix[2][2] == 1)
        #expect(m.matrix[3][0] == 0)
        #expect(m.matrix[3][1] == 0)
        #expect(m.matrix[3][2] == 0)
    }

    @Test func translationOnly() throws {
        let m = try Matrix(fromMVR: "{1,0,0}{0,1,0}{0,0,1}{1000,2000,3000}")
        #expect(m.matrix[3][0] == 1000)
        #expect(m.matrix[3][1] == 2000)
        #expect(m.matrix[3][2] == 3000)
    }

    @Test func scientificNotation() throws {
        let m = try Matrix(fromMVR: "{1,0,8.53590478e-08}{0,1,0}{0,0,1}{0,0,0}")
        #expect(m.matrix[0][2] > 0)
        #expect(m.matrix[0][2] < 1e-6)
    }

    @Test func rotationAndTranslation() throws {
        let m = try Matrix(fromMVR: "{0.158127,-0.987419,0.000000}{0.987419,0.158127,0.000000}{0.000000,0.000000,1.000000}{6020.939200,2838.588955,4978.134459}")
        #expect(abs(m.matrix[0][0] - 0.158127) < 1e-6)
        #expect(abs(m.matrix[0][1] - (-0.987419)) < 1e-6)
        #expect(abs(m.matrix[3][0] - 6020.9392) < 1e-3)
    }

    @Test func wrongElementCount() {
        // 9 values instead of 12
        #expect(throws: MVRParsingError.self) {
            _ = try Matrix(fromMVR: "{1,0,0}{0,1,0}{0,0,1}")
        }
    }

    @Test func tooManyElements() {
        // 16 values (GDTF format, not MVR)
        #expect(throws: MVRParsingError.self) {
            _ = try Matrix(fromMVR: "{1,0,0,0}{0,1,0,0}{0,0,1,0}{0,0,0,1}")
        }
    }

    @Test func emptyString() {
        #expect(throws: MVRParsingError.self) {
            _ = try Matrix(fromMVR: "")
        }
    }
}

@Suite("MVR XML Parsing")
struct MVRXMLParsingTests {

    @Test func minimalScene() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="6" provider="TestApp" providerVersion="1.0">
                <Scene>
                    <Layers>
                        <Layer uuid="11111111-1111-1111-1111-111111111111" name="Main">
                            <ChildList>
                                <Fixture uuid="22222222-2222-2222-2222-222222222222" name="Spot 1">
                                    <GDTFSpec>Manufacturer@Fixture.gdtf</GDTFSpec>
                                    <GDTFMode>Standard</GDTFMode>
                                    <FixtureID>1</FixtureID>
                                    <Addresses>
                                        <Address break="0">1</Address>
                                    </Addresses>
                                </Fixture>
                            </ChildList>
                        </Layer>
                    </Layers>
                </Scene>
            </GeneralSceneDescription>
            """)
        #expect(scene.verMajor == 1)
        #expect(scene.verMinor == 6)
        #expect(scene.provider == "TestApp")
        #expect(scene.scene.layers.count == 1)
        #expect(scene.scene.layers[0].name == "Main")
        #expect(scene.scene.layers[0].childList.count == 1)

        guard case .fixture(let f) = scene.scene.layers[0].childList[0] else {
            Issue.record("Expected fixture")
            return
        }
        #expect(f.name == "Spot 1")
        #expect(f.gdtfSpec == "Manufacturer@Fixture.gdtf")
        #expect(f.gdtfMode == "Standard")
        #expect(f.fixtureID == "1")
        #expect(f.addresses.count == 1)
    }

    @Test func emptyGDTFSpec() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="5">
                <Scene>
                    <Layers>
                        <Layer uuid="11111111-1111-1111-1111-111111111111" name="L">
                            <ChildList>
                                <Fixture uuid="22222222-2222-2222-2222-222222222222" name="F">
                                    <GDTFSpec></GDTFSpec>
                                    <FixtureID></FixtureID>
                                </Fixture>
                            </ChildList>
                        </Layer>
                    </Layers>
                </Scene>
            </GeneralSceneDescription>
            """)
        guard case .fixture(let f) = scene.scene.layers[0].childList[0] else {
            Issue.record("Expected fixture")
            return
        }
        #expect(f.gdtfSpec == nil, "Empty GDTFSpec should be nil")
    }

    @Test func auxDataParsing() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="5">
                <Scene>
                    <AUXData>
                        <Symdef uuid="AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA" name="MySymdef">
                            <ChildList>
                                <Geometry3D fileName="geo.3ds"/>
                            </ChildList>
                        </Symdef>
                        <Position uuid="BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB" name="FOH"/>
                        <Class uuid="CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC" name="Spots"/>
                    </AUXData>
                    <Layers/>
                </Scene>
            </GeneralSceneDescription>
            """)
        #expect(scene.scene.auxData.symdefs.count == 1)
        #expect(scene.scene.auxData.symdefs[0].name == "MySymdef")
        #expect(scene.scene.auxData.symdefs[0].children.count == 1)
        #expect(scene.scene.auxData.positions.count == 1)
        #expect(scene.scene.auxData.positions[0].name == "FOH")
        #expect(scene.scene.auxData.classes.count == 1)
        #expect(scene.scene.auxData.classes[0].name == "Spots")
    }

    @Test func nestedChildList() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="5">
                <Scene>
                    <Layers>
                        <Layer uuid="11111111-1111-1111-1111-111111111111" name="L">
                            <ChildList>
                                <GroupObject uuid="22222222-2222-2222-2222-222222222222" name="G">
                                    <ChildList>
                                        <Fixture uuid="33333333-3333-3333-3333-333333333333" name="F">
                                            <GDTFSpec>Test@Fixture</GDTFSpec>
                                            <FixtureID>1</FixtureID>
                                        </Fixture>
                                    </ChildList>
                                </GroupObject>
                            </ChildList>
                        </Layer>
                    </Layers>
                </Scene>
            </GeneralSceneDescription>
            """)
        let layer = scene.scene.layers[0]
        #expect(layer.childList.count == 1)
        guard case .groupObject(let g) = layer.childList[0] else {
            Issue.record("Expected GroupObject")
            return
        }
        #expect(g.childList.count == 1)
        guard case .fixture(let f) = g.childList[0] else {
            Issue.record("Expected nested Fixture")
            return
        }
        #expect(f.name == "F")
    }

    @Test func unknownElementsAreSkipped() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="5">
                <Scene>
                    <Layers>
                        <Layer uuid="11111111-1111-1111-1111-111111111111" name="L">
                            <ChildList>
                                <UnknownThing uuid="22222222-2222-2222-2222-222222222222"/>
                                <Fixture uuid="33333333-3333-3333-3333-333333333333" name="F">
                                    <FixtureID>1</FixtureID>
                                </Fixture>
                            </ChildList>
                        </Layer>
                    </Layers>
                </Scene>
            </GeneralSceneDescription>
            """)
        #expect(scene.scene.layers[0].childList.count == 1, "Unknown elements should be skipped")
    }

    @Test func matrixChildParsing() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="5">
                <Scene>
                    <Layers>
                        <Layer uuid="11111111-1111-1111-1111-111111111111" name="L">
                            <Matrix>{1,0,0}{0,1,0}{0,0,1}{0,0,5000}</Matrix>
                            <ChildList>
                                <Fixture uuid="22222222-2222-2222-2222-222222222222" name="F">
                                    <Matrix>{1,0,0}{0,1,0}{0,0,1}{1000,2000,3000}</Matrix>
                                    <FixtureID>1</FixtureID>
                                </Fixture>
                            </ChildList>
                        </Layer>
                    </Layers>
                </Scene>
            </GeneralSceneDescription>
            """)
        let layer = scene.scene.layers[0]
        #expect(layer.matrix != nil)
        #expect(layer.matrix?.matrix[3][2] == 5000)

        guard case .fixture(let f) = layer.childList[0] else {
            Issue.record("Expected fixture")
            return
        }
        #expect(f.matrix != nil)
        #expect(f.matrix?.matrix[3][0] == 1000)
    }

    @Test func missingRequiredUUID() {
        #expect(throws: (any Error).self) {
            _ = try parseMVRXML("""
                <GeneralSceneDescription verMajor="1" verMinor="5">
                    <Scene>
                        <Layers>
                            <Layer name="L">
                                <ChildList/>
                            </Layer>
                        </Layers>
                    </Scene>
                </GeneralSceneDescription>
                """)
        }
    }

    @Test func missingProviderDefaults() throws {
        let scene = try parseMVRXML("""
            <GeneralSceneDescription verMajor="1" verMinor="4">
                <Scene><Layers/></Scene>
            </GeneralSceneDescription>
            """)
        #expect(scene.provider == "")
        #expect(scene.providerVersion == "")
    }
}

// MARK: - Helper

/// Parses an MVR XML string directly (without ZIP wrapping).
private func parseMVRXML(_ xmlString: String) throws -> MVRScene {
    let config = XMLHash.config { config in
        config.shouldProcessLazily = false
        config.detectParsingErrors = true
    }
    let xml = config.parse(xmlString)
    let root = xml["GeneralSceneDescription"]
    guard root.element != nil else {
        throw MVRError.invalidRootElement("<empty>")
    }
    return try MVRScene(xml: root)
}

import SWXMLHash
