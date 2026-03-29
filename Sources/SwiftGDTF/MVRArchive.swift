//
//  MVRArchive.swift
//  SwiftGDTF
//
//  Wraps a parsed MVRScene + retains the raw archive data for resource extraction.
//

import Foundation
import ZIPFoundation
import SWXMLHash

/// A loaded MVR archive with access to both the parsed scene and embedded resources.
///
/// Unlike `loadMVR(data:)` which discards the ZIP archive after parsing,
/// `MVRArchive` retains the raw data so embedded GDTF files, 3D models,
/// and textures can be extracted on demand.
public struct MVRArchive: Sendable {
    /// The parsed MVR scene description.
    public let scene: MVRScene

    /// The raw archive data, retained for resource extraction.
    private let data: Data

    /// Loads and parses an MVR archive from raw data.
    ///
    /// - Parameter data: The raw bytes of the .mvr file.
    public init(data: Data) throws {
        self.data = data
        self.scene = try loadMVR(data: data)
    }

    /// Loads and parses an MVR archive from a file URL.
    ///
    /// - Parameter url: File URL of the .mvr file.
    public init(url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    /// Names of all resources in the archive (root-level entries only).
    public var resourceNames: [String] {
        get throws {
            let archive = try Archive(data: data, accessMode: .read)
            return archive.compactMap { entry -> String? in
                let path = entry.path
                // Only root-level files, skip directories and GeneralSceneDescription.xml
                guard entry.type == .file,
                      !path.contains("/"),
                      path != "GeneralSceneDescription.xml" else { return nil }
                return path
            }
        }
    }

    /// Extracts a resource from the archive by name.
    ///
    /// - Parameter name: File name of the resource (e.g. "fixture.gdtf", "model.3ds").
    /// - Returns: The raw data of the resource.
    public func extractResource(named name: String) throws -> Data {
        let archive = try Archive(data: data, accessMode: .read)
        guard let entry = archive[name] else {
            throw MVRError.resourceNotFound(name)
        }
        var result = Data()
        _ = try archive.extract(entry) { chunk in
            result.append(chunk)
        }
        return result
    }

    /// Extracts and parses an embedded GDTF file from the archive.
    ///
    /// - Parameter spec: The `gdtfSpec` value from an MVR fixture (e.g. "Manufacturer@Fixture.gdtf").
    ///   If the spec doesn't end in ".gdtf", the extension is appended.
    /// - Returns: The parsed GDTF and its raw data (needed for mesh extraction).
    public func loadEmbeddedGDTF(spec: String) throws -> (gdtf: GDTF, data: Data) {
        let fileName = spec.hasSuffix(".gdtf") ? spec : spec + ".gdtf"
        let gdtfData = try extractResource(named: fileName)
        let gdtf = try loadGDTF(data: gdtfData)
        return (gdtf, gdtfData)
    }
}

