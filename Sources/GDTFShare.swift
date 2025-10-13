//
//  GDTFShare.swift
//  SwiftGDTF
//
//  Created by Brandon Wees on 12/21/24.
//

import Foundation

public struct GDTFShare {
    
    public struct LoginResponse: Equatable, Codable, Sendable {
        // Was login successful
        public let result: Bool
        
        // Possible error message
        public let error: String?
        
        // Fun joke from the site
        public let notice: String
        
    }
    
    public struct DMXMode: Equatable, Codable, Sendable {
        let name: String
        let dmxFootprint: Int
        
        private enum CodingKeys : String, CodingKey {
            case name, dmxFootprint = "dmxfootprint"
        }
    }
    
    public struct FixtureEntry: Equatable, Codable, Sendable, Identifiable {
        public enum Uploader: Codable, CustomStringConvertible, Sendable, Equatable, Comparable {
            private static let userString = "User"
            private static let manufacturerString = "Manuf."
            case user
            case manufacturer
            case unknown(String)
            public init(from decoder: any Decoder) throws {
                let string = try decoder.singleValueContainer().decode(String.self)
                switch string {
                case Self.userString:
                    self = .user
                case Self.manufacturerString:
                    self = .manufacturer
                default:
                    self = .unknown(string)
                }
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.singleValueContainer()
                let string = switch self {
                case .user: Self.userString
                case .manufacturer: Self.manufacturerString
                case .unknown(let string): string
                }
                try container.encode(string)
            }

            public var description: String {
                switch self {
                case .user: "User"
                case .manufacturer: "Manufacturer"
                case .unknown(let string): string
                }
            }
        }
        public var id: GDTF.ID  {
            self.revisionID
        }
        public let revisionID: GDTF.ID
        public let name: String
        public let manufacturer: String
        public let revisionName: String
        public let creationDate: Date
        public let lastModified: Date
        public let uploader: Uploader

        private let ratingString: String
        public var rating: Double? { Double(ratingString) }

        public let version: String
        public let creator: String
        
        // Does not change across revisions
        public let uuid: UUID
        
        public let filesize: Int
        public let modes: [DMXMode]

        private enum CodingKeys : String, CodingKey {
            case revisionID = "rid"
            case name = "fixture"
            case manufacturer
            case revisionName = "revision"
            case creationDate
            case lastModified
            case uploader
            case ratingString = "rating"
            case version
            case creator
            case uuid
            case filesize
            case modes
        }
    }
    
    public struct ListResponse: Equatable, Codable, Sendable {
        // was the request for data successful
        public let result: Bool
        
        // Possible error message
        public let error: String?
        
        public let list: [FixtureEntry]?
    }
    
    // Returns the sessionID which is the PHPSESSID cookie
    public static func login(username: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "https://gdtf-share.com/apis/public/login.php")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "user" : username,
            "password" : password
        ])
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)

        // Parse the JSON data
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    public static func getList() async throws -> ListResponse {
        let url = URL(string: "https://gdtf-share.com/apis/public/getList.php")!
                
        let (data, _) = try await URLSession.shared.data(from: url)

        // Parse the JSON data
        return try decoder.decode(ListResponse.self, from: data)
    }

    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }

    public static func downloadURL(revisionID: GDTF.ID) -> URL {
        URL(string: "https://gdtf-share.com/apis/public/downloadFile.php?rid=\(revisionID.rawValue)")!
    }

    public static func download(revisionID: GDTF.ID) async throws -> Data? {
        let url = downloadURL(revisionID: revisionID)

        let (data, response) = try await URLSession.shared.data(from: url)
        
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return data
            } else {
                return nil
            }
        }

        return nil
    }
    
    public static func editorURL(revisionID: GDTF.ID) -> URL {
        URL(string: "https://fixturebuilder.gdtf-share.com/load/?rid=\(revisionID.rawValue)")!
    }
}

