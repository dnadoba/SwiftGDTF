// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SWXMLHash
import ZIPFoundation

public enum GDTFError: Error {
    case invalidGDTF
    case invalidGDTFDescription
}

public class FixtureType {
    public let fixtureTypeTree: XMLIndexer
    public let gdtfData: Data
    
    /// Fixture Attributes
    public let dataVersion: String
    public let name: String
    public let shortName: String
    public let longName: String
    public let manufacturer: String
    public let description: String
    public let fixtureTypeID: String
    public let refFT: String?

    public let thumbnail: String?
    public let thumbnailOffset: ThumbnailOffset
    
    public init(from gdtfData: Data) throws {
        self.gdtfData = gdtfData
        let xmlTree = try FixtureType.loadGDTFTree(data: gdtfData)
        
        self.fixtureTypeTree = xmlTree["GDTF"]["FixtureType"]
                
        /// Fixture Attributes
        self.dataVersion = xmlTree["GDTF"].element!.attribute(by: "DataVersion")!.text

        let fixtureTreeElement = fixtureTypeTree.element!
        self.name = fixtureTreeElement.attribute(by: "Name")!.text
        self.shortName = fixtureTreeElement.attribute(by: "ShortName")!.text
        self.longName = fixtureTreeElement.attribute(by: "LongName")!.text
        self.manufacturer = fixtureTreeElement.attribute(by: "Manufacturer")!.text
        self.description = fixtureTreeElement.attribute(by: "Description")!.text
        self.fixtureTypeID = fixtureTreeElement.attribute(by: "FixtureTypeID")!.text
        self.refFT = fixtureTreeElement.attribute(by: "RefFT")!.text
     
        self.thumbnail = fixtureTreeElement.attribute(by: "Thumbnail")?.text
        self.thumbnailOffset = ThumbnailOffset(
            x: Int(fixtureTreeElement.attribute(by: "ThumbnailOffsetX")?.text ?? "0")!,
            y: Int(fixtureTreeElement.attribute(by: "ThumbnailOffsetY")?.text ?? "0")!)
            
    }
    
    public convenience init(url: URL) throws {
        let gdtfData: Data = try Data(contentsOf: url)
        
        try self.init(from: gdtfData)
    }
    
    private static func loadGDTFTree(data: Data) throws -> XMLIndexer {
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
        
        return xmlTree
    }
}
