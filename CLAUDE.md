# SwiftGDTF — Claude Code Notes

## Project overview

Swift package that parses GDTF (General Device Type Format) fixture files and MVR
(My Virtual Rig) scene files, and renders 3D models using SceneKit.  Targets macOS 26 / iOS 26.

Key files — GDTF:
- `Sources/GDTF.swift` — top-level types, `GDTFModel`, `ModelFileFormat`, LOD enum
- `Sources/Types.swift` — `PrimitiveType`, `Matrix`, `Rotation`, `FileResource`
- `Sources/Geometries.swift` — geometry enum tree (user's preferred model pattern)
- `Sources/Geometries+XML.swift` — geometry XML parsing (user's preferred parsing pattern)
- `Sources/ThreeDS.swift` — binary .3ds parser
- `Sources/GLBParser.swift` — glTF Binary (.glb) parser (node-hierarchy-aware)
- `Sources/ThreeDSView.swift` — SceneKit rendering: `FixtureSceneBuilder`, primitive
  fallbacks, previews
- `Sources/XMLProcessor.swift` — XML deserialization for all GDTF types

Key files — MVR:
- `Sources/MVR.swift` — MVR model types (structs, enums, protocols)
- `Sources/MVR+XML.swift` — XMLDecodable conformances for MVR types
- `Sources/MVRLoader.swift` — `loadMVR(data:)`, `loadMVR(url:)`, ZIP extraction
- `mvr-spec.md` — MVR v1.6 specification (DIN SPEC 15801)

## Xcode MCP — always use `windowtab1` (or list windows first)

```swift
mcp__xcode__XcodeListWindows()   // → windowtab1
mcp__xcode__BuildProject(tabIdentifier: "windowtab1")
mcp__xcode__RunAllTests(tabIdentifier: "windowtab1")
mcp__xcode__RenderPreview(tabIdentifier: "windowtab1", sourceFilePath: "SwiftGDTF/Sources/ThreeDSView.swift", previewDefinitionIndexInFile: 0)
```

Preview indices in `ThreeDSView.swift`:
- 0 = `#Preview("GDTF Fixture Assembler")` — .3ds fixtures (previewFixtures)
- 1 = `#Preview("GLB Fixture Assembler")` — GLB fixtures (glbPreviewFixtures)
- 2 = `#Preview("Primitive Fixture Assembler")` — primitive-type fixtures

To change the default fixture shown, temporarily edit `selectedIndex` in
`GDTFFixturePickerPreview` (reset to 0 before committing).

## Running code / debugging with ExecuteSnippet

`mcp__xcode__ExecuteSnippet` is the primary debugging tool. Run arbitrary Swift
against the live compiled module. Key imports:

```swift
import Foundation
import SwiftGDTF
import SceneKit          // for SCNNode, bounding boxes
import ZIPFoundation     // for Archive (available in SwiftGDTF target context)
import simd
```

Fixture cache is at:
```swift
let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("SwiftGDTF/Fixtures")
// Files named {rid}.gdtf
```

Load and parse a fixture:
```swift
let gdtfData = try Data(contentsOf: cacheDir.appendingPathComponent("71555.gdtf"))
let gdtf = try loadGDTF(data: gdtfData)
```

Build the scene node (from ThreeDSView.swift public API):
```swift
let builder = FixtureSceneBuilder(gdtf: gdtf, gdtfData: gdtfData)
let node = builder.buildNode()                     // auto-selects best root geometry
let node2 = builder.buildNode(rootGeometryName: "Base")
```

Compute world-space AABB (SceneKit's `boundingBox` is unreliable after rotation):
```swift
var wMin = SIMD3<Float>(repeating: Float.infinity)
var wMax = SIMD3<Float>(repeating: -Float.infinity)
func acc(_ n: SCNNode) {
    if n.geometry != nil {
        let (mn, mx) = n.boundingBox
        let wt = n.simdWorldTransform
        for dx in [Float(mn.x), Float(mx.x)] {
            for dy in [Float(mn.y), Float(mx.y)] {
                for dz in [Float(mn.z), Float(mx.z)] {
                    let wp = wt * SIMD4<Float>(dx, dy, dz, 1)
                    wMin = min(wMin, SIMD3(wp.x, wp.y, wp.z))
                    wMax = max(wMax, SIMD3(wp.x, wp.y, wp.z))
                }
            }
        }
    }
    n.childNodes.forEach { acc($0) }
}
acc(node)
let span = wMax - wMin
let aspect = span.max() / max(span.min(), 0.0001)
```

Inspect a GLB archive entry:
```swift
import ZIPFoundation
let archive = Archive(data: gdtfData, accessMode: .read)!
for entry in archive where entry.path.contains("models/gltf/") && entry.path.hasSuffix(".glb") {
    var glbData = Data()
    _ = try archive.extract(entry) { chunk in glbData.append(chunk) }
    let chunk0Len = glbData[12..<16].withUnsafeBytes { $0.load(as: UInt32.self) }
    let json = try JSONSerialization.jsonObject(with: glbData[20..<(20+Int(chunk0Len))]) as! [String: Any]
    print(json.keys.sorted())
}
```

## Coordinate system conventions

| Space | Convention |
|---|---|
| GDTF / .3ds mesh | Z-up right-handed: X=right, Y=into screen, Z=up |
| glTF / .glb mesh | Y-up right-handed: X=right, Y=up, Z=toward camera |
| SceneKit | Y-up right-handed |

`gdtfToSceneKit` (built into walk's root worldTransform): maps GDTF (x,y,z) → SceneKit (x,z,-y).
`sceneKitToGdtf` (applied to Y-up mesh nodes): maps SceneKit (x,y,z) → GDTF (x,-z,y).

GLB coordinate detection (`detectCoordSystem`): rank-order match between declared
model dims and mesh bounding box spans under Z-up vs Y-up interpretations.

## GDTF matrix convention

The `Matrix` XML attribute stores a 4×4 in **row-major order**, but uses the
**row-vector convention** (v' = v·M), meaning each raw data row is the image of a
basis vector.  To convert to SIMD column-vector convention (v' = M·v), each raw row
becomes a SIMD **column** directly — no transposition of the 3×3 rotation block.

In `Types.swift`:
```swift
// raw row 0 → SIMD col 0, raw row 1 → SIMD col 1, etc.
// translation lives in elements [3],[7],[11] → SIMD col 3
```

## Mesh scaling

`meshScaleMatrix()` scales each mesh axis so its bounding-box span matches the
model's declared dimensions (Length→X, Width→Y, Height→Z in GDTF Z-up metres).

- For Y-up meshes, the bounding box is first rotated by `sceneKitToGdtf` before
  comparing spans to declared dims.
- Threshold for "valid span" is `1e-9` (nearly zero) — GLB node transforms can
  produce very small post-transform spans (e.g. a 0.001 mm→m scale factor applied
  to mm-scale vertices gives spans ~0.00006).

## GLB parser (`GLBParser.swift`)

- Walks the glTF node hierarchy accumulating world transforms before extracting
  vertex data — critical for SketchUp exports that use scale+rotation nodes.
- Node `matrix` is column-major (16 floats); TRS components are parsed from JSON
  arrays into `simd_quatf` and `SIMD3<Float>`.
- `GLTFNode.localTransform` computes T * R * S (or uses `matrix` directly).
- SPM's `.process("Resources")` **flattens** subdirectories — `Bundle.module.url`
  should NOT pass `subdirectory:` when loading bundled .3ds primitive meshes.

## Primitive type fallback

When no mesh file is found, `makeMeshNode()` falls back to `gdtfModel.primitiveType`:
- Complex shapes (Base, Yoke, Head, Scanner, Conventional + 1.1 variants): loaded
  from bundled .3ds files in `Sources/Resources/PrimitiveMeshes/`.
- Simple shapes: generated as SceneKit primitives.
  - Cube → `SCNBox(width:1, height:1, length:1, chamferRadius:0)`
  - Cylinder / Pigtail → `SCNCylinder(radius:0.5, height:1)` rotated -90° around X
  - Sphere → `SCNSphere(radius:0.5)`

## Code style for new code

- Follow `Geometries.swift` / `Geometries+XML.swift` patterns (enum with associated
  values, Kind enum with rawValue for XML dispatch)
- Do NOT use `parseChildrenToArray` or helpers that accept `base: XMLIndexer, tree
  fullTree: XMLIndexer` — those are from the old maintainer. Use `.children.map { }`.
- All model types must conform to `Equatable` and `Sendable`
- Never crash on invalid input — always throw descriptive errors
- Don't use tuples in public types (not Equatable)

## Tests

All tests in `Tests/SwiftGDTFTests/`:
- `ThreeDSViewTests.swift` — unit tests for .3ds parser and SceneKit builder
- `GLBParserTests.swift` — unit + cached-fixture tests for GLB parser
- `SwiftGDTFTests.swift` — `parse3DSModels()`, `parseGLBModels()` (iterate cache)
- `GDTFStatistics.swift` — print-only statistics tests (no assertions)
- `MVRTests.swift` — 14 MVR fixtures with statistics validation + embedded GDTF parsing
- `MVRParsingTests.swift` — unit tests for MVR matrix parsing, malformed input, etc.

MVR test fixtures in `Tests/SwiftGDTFTests/MVRTestFixtures/` (14 .mvr files from
various sources: grandMA3, Capture, Vectorworks, python-mvr, MomentFactory).

Run all: `mcp__xcode__RunAllTests`. Expected: 34 passed, 1 skipped (`parseAllFixtures`
requires network credentials).

Quick sanity check after a rendering change — run the world-AABB snippet above on
several fixture rids and check aspect ratios are reasonable (< 20 for most fixtures).

## Common debugging patterns

**"Fixture renders as empty / tiny"**
1. Check `meshSpan` in `meshScaleMatrix` — if all axes < 1e-9, the mesh bounding
   box is degenerate (node transform collapsed it).
2. Parse the GLB manually and print raw vertex ranges BEFORE the node transform to
   see what scale the exporter used.
3. Check the GLB node's `matrix` or `scale` field for extreme values (e.g. 0.001).

**"Parts are disconnected / floating"**
- GLB node hierarchy transforms were not applied. Verify `walkNode` is visiting all
  nodes and the `scene`/`scenes` JSON fields are being read.
- Check the geometry tree's `position` matrices (GDTF XML) — are parent offsets
  correct?

**"Mesh is stretched on one axis"**
- Coordinate system mismatch. Print `detectCoordSystem` result and compare rank
  orders of declared dims vs mesh spans.
- Check if the GLB node rotation already converts Y-up→Z-up (a -90° X rotation is
  the tell). If so the mesh IS in Z-up space and `.zUp` is correct.

**"Renders as thin line / flat"**
- For flat-panel fixtures (matrix blinders etc.) this may be physically correct — the
  fixture really is only 67mm thick viewed edge-on.
- If wrong: the Y/Z scale axes are swapped. The `sceneKitToGdtf` sandwich fix in
  `meshScaleMatrix` / `walk` should handle this — check that the bounding-box
  rotation is being applied correctly.

**Checking fixture format (3DS vs GLB vs primitive)**:
```swift
for model in gdtf.fixtureType.models {
    let has3ds = GDTFModel.LOD.allCases.contains { model.resolveFile(gdtf: gdtfData, format: .threeds, lod: $0) != nil }
    let hasGlb = GDTFModel.LOD.allCases.contains { model.resolveFile(gdtf: gdtfData, format: .glb, lod: $0) != nil }
    print("'\(model.name)': 3ds=\(has3ds) glb=\(hasGlb) prim=\(model.primitiveType) L=\(model.length) W=\(model.width) H=\(model.height)")
}
```

## Finding test fixtures

Use `ExecuteSnippet` with the cache directory — do NOT use file search tools to find
.gdtf files (the cache has 10,752 of them and will overwhelm search tools):

```swift
// Find GLB-only fixtures with 3+ models from a specific manufacturer
let files = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension.lowercased() == "gdtf" }
for file in files { ... }
```

Always use `withTaskGroup` for batch processing across all 10k+ fixtures.

## MVR file format

MVR (My Virtual Rig, DIN SPEC 15801) files are ZIP archives containing
`GeneralSceneDescription.xml` at the root plus referenced resources (.gdtf, .3ds,
.glb, textures). All referenced files must be at the archive root (no subdirectories).

### MVR matrix convention

MVR uses a 4×3 matrix format (12 values) vs GDTF's 4×4 (16 values):
```
{u1,u2,u3}{v1,v2,v3}{w1,w2,w3}{o1,o2,o3}
```
- Rows 0-2: rotation/scale basis vectors
- Row 3: translation (in mm)
- Right-handed, Z-up, 1 unit = 1 mm
- Same row-vector convention as GDTF

### MVR node hierarchy
```
GeneralSceneDescription (root)
  └─ Scene
       ├─ AUXData: Symdef, Position, MappingDefinition, Class
       └─ Layers → Layer → ChildList (recursive)
            ChildList objects: SceneObject, GroupObject, FocusPoint,
            Fixture, Truss, Support, VideoScreen, Projector
```

### MVR UUID references (kept as raw UUIDs, not eagerly resolved)
- Fixture.focus → FocusPoint UUID
- Fixture.position / Truss.position / Support.position → AUXData Position UUID
- Any object's Classing → AUXData Class UUID
- Symbol.symdef → AUXData Symdef UUID
- Mapping.linkedDef → AUXData MappingDefinition UUID
- Connection.toObject → any object UUID

### Loading MVR files
```swift
let mvrData = try Data(contentsOf: url)
let scene = try loadMVR(data: mvrData)
// scene.scene.layers[0].childList — the objects
// scene.scene.auxData.symdefs — shared geometry definitions
```

### Deriving test statistics for new MVR files
See the comment block above `MVRParserTests` in `MVRTests.swift` for step-by-step
shell commands (unzip, grep, count node types).
