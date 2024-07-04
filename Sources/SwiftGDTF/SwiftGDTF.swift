// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import XMLCoder
import ZIPFoundation

public enum GDTFError: Error {
    case invalidGDTF
    case invalidGDTFDescription
}

public func loadGDTF(from gdtfData: Data) throws -> GDTF {
    let zipArchive = try Archive(data: gdtfData, accessMode: .read)

    /// Verify a description.xml file was found, otherwise invalid GDTF
    guard let entry = zipArchive["description.xml"] else {
        throw GDTFError.invalidGDTF
    }

    /// Make buffer to append extracted ZIP data
    var xmlData = Data()

    /// Extract the data into data buffer
    _ = try zipArchive.extract(entry) { data in
        xmlData.append(data)
    }

    /// Decode as UTF8, if fails throw
    guard let xmlString = String(data: xmlData, encoding: .utf8) else {
        throw GDTFError.invalidGDTFDescription
    }
    
    return try XMLDecoder().decode(GDTF.self, from: Data(xmlString.utf8))
}

public func loadGDTF(url: URL) throws -> GDTF {
    let gdtfData = try Data(contentsOf: url)
    
    return try loadGDTF(from: gdtfData)
}

public func loadGDTFDescription(url: URL) throws -> GDTF {
    let xmlData = try Data(contentsOf: url)
    
    /// Decode as UTF8, if fails throw
    guard let xmlString = String(data: xmlData, encoding: .utf8) else {
        throw GDTFError.invalidGDTFDescription
    }
    
    let decoder = XMLDecoder()
    
    return try decoder.decode(GDTF.self, from: Data(xmlString.utf8))
}
