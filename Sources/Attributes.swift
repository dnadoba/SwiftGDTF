//
//  Attributes.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 10/4/25.
//

import Foundation

private struct AttributeDescriptions: Decodable, Sendable {
    let attributes: [AttributeDescription]

    private enum CodingKeys: String, CodingKey {
        case attributes = "Attribute"
    }
}

public struct AttributeDescription: Decodable, Identifiable, Sendable, Equatable {
    /// TODO: we should be able to optimize this to just an array and add some kind of integer value to AttributeType
    /// potentially the better solution is to just have this in memory anyway
    static let attributes: [AttributeType: AttributeDescription] = {
        let attributesURL = Bundle.module.url(forResource: "gdtf_attributes_with_description", withExtension: "json")!
        let attributesData = try! Data(contentsOf: attributesURL)
        let decoder = JSONDecoder()
        let attributes = try! decoder.decode(AttributeDescriptions.self, from: attributesData)
        return Dictionary(uniqueKeysWithValues: attributes.attributes.lazy.map { ($0.name, $0) })
    }()

    public var id: AttributeType { name }

    public struct SubPhysicalUnit: Decodable, Sendable, Equatable {
        public var `default`: Bool
        public var type: String
        public var physicalUnit: String
        private var _physicalFrom: LosslessDouble
        public var physicalFrom: Double {
            get { _physicalFrom.value }
            set { _physicalFrom.value = newValue }
        }
        private var _physicalTo: LosslessDouble
        public var physicalTo: Double {
            get { _physicalTo.value }
            set { _physicalTo.value = newValue }
        }

        private enum CodingKeys: String, CodingKey {
            case `default` = "_default"
            case type = "_type"
            case physicalUnit = "_physicalUnit"
            case _physicalFrom
            case _physicalTo
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name = "_name"
        case prettyName = "_prettyName"
        case feature = "_feature"
        case physicalUnit = "_physicalUnit"
        case mainAttribute = "_MainAttribute"
        case activationGroup = "_ActivationGroup"
        case subPhysicalUnits = "_subPhysicalUnits"
        case definition
        case explanation
        case visual
        case label = "_label"
    }

    public var name: AttributeType
    public var prettyName: String
    public var feature: String
    public var physicalUnit: String?
    public var mainAttribute: String?
    public var activationGroup: String?
    public var subPhysicalUnits: [SubPhysicalUnit]?
    public var definition: String?
    public var explanation: String
    public var visual: String
    public var label: String
}

extension AttributeType {
    public var attributeDescription: AttributeDescription? {
        AttributeDescription.attributes[self]
    }
}


// Seems like the json includes a string e.g. "0.025" but we need to treat that as a double
struct LosslessDouble: Decodable, Sendable, Equatable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self),
                  let doubleFromString = Double(stringValue) {
            value = doubleFromString
        } else {
            throw DecodingError.typeMismatch(
                Double.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a Double or String convertible to Double"
                )
            )
        }
    }
}



