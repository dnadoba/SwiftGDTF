//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/4/24.
//

import Foundation

public protocol XMLCollectionElement: Codable {
    static var tagName: String { get }
}

@propertyWrapper
public struct XMLCollection<
    Element: XMLCollectionElement
>: Codable {
    public var wrappedValue: [Element]

    struct CodingKeys: CodingKey {
        init() {}

        init?(stringValue: String) {
            guard stringValue == Element.tagName else { return nil }
        }

        var stringValue: String {
            Element.tagName
        }

        init?(intValue: Int) { nil }
        var intValue: Int? { nil }
    }

    public init(wrappedValue: [Element]) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wrappedValue = try container.decode([Element].self, forKey: CodingKeys())
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wrappedValue, forKey: CodingKeys())
    }
}
