//
//  MVRLoader.swift
//  SwiftGDTF
//
//  Public API for loading MVR files: ZIP extraction + XML parsing.
//

import Foundation
import ZIPFoundation
import SWXMLHash

/// Loads and parses an MVR file from raw data.
///
/// MVR files are ZIP archives containing `GeneralSceneDescription.xml` at the root
/// plus referenced resource files (.gdtf, .3ds, .glb, textures).
///
/// - Parameter data: The raw bytes of the .mvr file.
/// - Returns: The parsed MVR scene.
public func loadMVR(data: Data) throws -> MVRScene {
    let archive: Archive
    do {
        archive = try Archive(data: data, accessMode: .read)
    } catch {
        throw MVRError.invalidArchive
    }

    guard let entry = archive["GeneralSceneDescription.xml"] else {
        throw MVRError.missingSceneDescription
    }

    var xmlData = Data()
    _ = try archive.extract(entry) { chunk in
        xmlData.append(chunk)
    }

    // Some exporters (e.g. grandMA3) write a trailing NULL byte — strip it.
    while xmlData.last == 0 { xmlData.removeLast() }

    guard let xmlString = String(data: xmlData, encoding: .utf8) else {
        throw MVRError.invalidXML(MVRParsingError.elementMissing)
    }

    let config = XMLHash.config { config in
        config.shouldProcessLazily = false
        config.detectParsingErrors = true
    }
    let xml = config.parse(xmlString)

    // Navigate to the root element
    let root = xml["GeneralSceneDescription"]
    guard root.element != nil else {
        // Try the first child in case the XML structure is different
        if let firstChild = xml.children.first, firstChild.element?.name == "GeneralSceneDescription" {
            return try MVRScene(xml: firstChild)
        }
        throw MVRError.invalidRootElement(xml.children.first?.element?.name ?? "<empty>")
    }

    return try MVRScene(xml: root)
}

/// Loads and parses an MVR file from a URL.
///
/// - Parameter url: File URL of the .mvr file.
/// - Returns: The parsed MVR scene.
public func loadMVR(url: URL) throws -> MVRScene {
    let data = try Data(contentsOf: url)
    return try loadMVR(data: data)
}
