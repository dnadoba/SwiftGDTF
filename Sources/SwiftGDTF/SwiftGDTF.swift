// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SWXMLHash
import ZIPFoundation

public enum GDTFError: Error {
    case invalidGDTF
    case invalidGDTFDescription
    case dmxModeNotFound
}

func loadXMLFromGDTF(url: URL) throws -> XMLIndexer {
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
    
    return try loadXML(xmlData: xmlData)
}

func loadXML(xmlData: Data) throws -> XMLIndexer {
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
    
    return xmlTree
}

public func loadGDTF(url: URL) throws -> GDTF{
    var xmlTree = try loadXMLFromGDTF(url: url)
        
    return GDTF(xml: xmlTree)
}

public func loadGDTFDescription(url: URL) throws -> GDTF {
    let xmlData = try Data(contentsOf: url)
    let xmlTree = try loadXML(xmlData: xmlData)
    
    return GDTF(xml: xmlTree)
}

public func loadGDTFFixtureMode(mode: String, url: URL) throws -> DMXMode {
    var xmlTree = try loadXMLFromGDTF(url: url)
    
    /// Find the requested dmx mode
    guard let mode = xmlTree["GDTF"]["FixtureType"]["DMXModes"].filterChildren({child, _ in child.attribute(by: "Name")!.text == mode}).children.first else {
        throw GDTFError.dmxModeNotFound
    }
    
    return mode.parse(tree: xmlTree["GDTF"]["FixtureType"])
}
