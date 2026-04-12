import Testing
import Foundation
@testable import SwiftGDTF

@Suite("Debug Dump")
struct MVRDebugDump {
    @Test("Dump Demostage structure")
    func dumpDemostage() throws {
        let url = Bundle.module.url(forResource: "Demostage_MVR", withExtension: "mvr", subdirectory: "MVRTestFixtures")!
        let archive = try MVRArchive(url: url)
        let scene = archive.scene
        let targetUUID = "D6B48338-16D2-440F-8BA6-A3D5834E7542"

        func walk(_ objects: [MVRChildObject], depth: Int) {
            for obj in objects {
                let indent = String(repeating: "  ", count: depth)
                let geos = obj.geometries.map { geo -> String in
                    switch geo {
                    case .geometry3D(let g): return "3D:\(g.fileName)"
                    case .symbol(let s): return "sym:\(s.symdef.uuidString.prefix(8))"
                    }
                }
                let geoStr = geos.isEmpty ? "" : " geos=\(geos)"
                let target = obj.uuid.uuidString == targetUUID ? " <<<TARGET>>>" : ""
                let isCurtain = obj.name.lowercased().contains("curtain")
                let isTruss = obj.name.lowercased().contains("truss") || obj.kind == .truss
                if isCurtain || isTruss || !target.isEmpty || obj.name.lowercased().contains("stage") {
                    print("\(indent)\(obj.kind.rawValue) \"\(obj.name)\" uuid=\(obj.uuid.uuidString.prefix(8)) gdtfSpec=\(obj.gdtfSpec ?? "nil") children=\(obj.childList.count)\(geoStr)\(target)")
                }
                walk(obj.childList, depth: depth + 1)
            }
        }
        for (li, layer) in scene.scene.layers.enumerated() {
            print("Layer \(li): \"\(layer.name)\"")
            walk(layer.childList, depth: 1)
        }

        // Print symdefs
        print("\nSymdefs: \(scene.scene.auxData.symdefs.count)")
        for sd in scene.scene.auxData.symdefs {
            let geos = sd.children.map { geo -> String in
                switch geo {
                case .geometry3D(let g): return "3D:\(g.fileName)"
                case .symbol(let s): return "sym:\(s.symdef.uuidString.prefix(8))"
                }
            }
            print("  Symdef \(sd.uuid.uuidString.prefix(8)) \"\(sd.name)\" children=\(geos)")
        }

        // Print resource names
        let resources = try archive.resourceNames
        print("\nResources (\(resources.count)):")
        for r in resources.sorted() { print("  \(r)") }
    }
}
