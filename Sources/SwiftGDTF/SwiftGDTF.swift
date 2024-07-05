// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SWXMLHash
import ZIPFoundation

public enum GDTFError: Error {
    case invalidGDTF
    case invalidGDTFDescription
}

public func loadGDTF(url: URL) throws -> GDTF{
    let data = try Data(contentsOf: url)
    let zipArchive = try Archive(data: data, accessMode: .read)
    
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
    
    /// Setup XML parser config
    let config = XMLHash.config { config in
        config.shouldProcessLazily = false
        config.detectParsingErrors = true
    }
    
    /// parse XML tree and verify we got a GDTF root node
    let xmlTree = config.parse(xmlString)
    guard (xmlTree["GDTF"].element != nil) else {
        throw GDTFError.invalidGDTFDescription
    }
    
    return GDTF(xml: xmlTree)
}

public func loadGDTFDescription(url: URL) throws -> GDTF {
    let xmlData = try Data(contentsOf: url)
    
    /// Decode as UTF8, if fails throw
    guard let xmlString = String(data: xmlData, encoding: .utf8) else {
        throw GDTFError.invalidGDTFDescription
    }
    
    /// Setup XML parser config
    let config = XMLHash.config { config in
        config.shouldProcessLazily = false
        config.detectParsingErrors = true
    }
    
    /// parse XML tree and verify we got a GDTF root node
    let xmlTree = config.parse(xmlString)
    guard (xmlTree["GDTF"].element != nil) else {
        throw GDTFError.invalidGDTFDescription
    }
    
    return GDTF(xml: xmlTree)
}
