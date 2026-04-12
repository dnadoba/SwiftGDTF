//
//  MVR+Encoding.swift
//  SwiftGDTF
//
//  Public API for encoding MVR scenes to ZIP archives.
//

#if os(macOS)
import Foundation
import ZIPFoundation

/// Encodes an MVR scene to a ZIP archive in memory.
///
/// - Parameter scene: The MVR scene to encode.
/// - Returns: The raw bytes of the .mvr (ZIP) file.
public func encodeMVR(scene: MVRScene) throws -> Data {
    try encodeMVR(scene: scene, resources: [:])
}

/// Encodes an MVR scene with resources to a ZIP archive in memory.
///
/// - Parameters:
///   - scene: The MVR scene to encode.
///   - resources: Resource files to include (key: file name, value: raw data).
///     Typically GDTF files, 3DS models, GLB files, or textures.
/// - Returns: The raw bytes of the .mvr (ZIP) file.
public func encodeMVR(scene: MVRScene, resources: [String: Data]) throws -> Data {
    let xmlDoc = XMLDocument(rootElement: scene.xmlElement())
    xmlDoc.version = "1.0"
    xmlDoc.characterEncoding = "UTF-8"
    let xmlData = xmlDoc.xmlData(options: [.nodePrettyPrint])

    let archive = try Archive(accessMode: .create)

    try archive.addEntry(
        with: "GeneralSceneDescription.xml",
        type: .file,
        uncompressedSize: Int64(xmlData.count),
        provider: { position, size in
            let start = Int(position)
            return xmlData[start..<(start + size)]
        }
    )

    for (name, data) in resources.sorted(by: { $0.key < $1.key }) {
        try archive.addEntry(
            with: name,
            type: .file,
            uncompressedSize: Int64(data.count),
            provider: { position, size in
                let start = Int(position)
                return data[start..<(start + size)]
            }
        )
    }

    guard let archiveData = archive.data else {
        throw MVRError.invalidArchive
    }
    return archiveData
}

/// Encodes an MVR scene and writes it to a file.
///
/// - Parameters:
///   - scene: The MVR scene to encode.
///   - url: File URL to write the .mvr file to.
public func encodeMVR(scene: MVRScene, to url: URL) throws {
    let data = try encodeMVR(scene: scene)
    try data.write(to: url)
}

/// Encodes an MVR scene with resources and writes it to a file.
///
/// - Parameters:
///   - scene: The MVR scene to encode.
///   - resources: Resource files to include.
///   - url: File URL to write the .mvr file to.
public func encodeMVR(scene: MVRScene, resources: [String: Data], to url: URL) throws {
    let data = try encodeMVR(scene: scene, resources: resources)
    try data.write(to: url)
}
#endif
