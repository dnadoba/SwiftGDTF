import Testing
import SwiftGDTF

@Suite
struct AttributeTests {
    @Test func checkThatAllAttributesDescriptionsAreKnown() {
        let all = AttributeDescription.attributes

        for (attribute, description) in all {
            #expect(!attribute.isCustom, "attribute \(attribute) should be known but it is custom. Description: \(description)")
        }
    }

    @Test func checkThatAllAttributesSymbolsAreKnown() {
        let all = AttributeIcon.attributes

        for (attribute, symbol) in all {
            #expect(!attribute.isCustom, "attribute \(attribute) should be known but it is custom. Symbol: \(symbol)")
        }
    }
}


extension AttributeType.Canonical {
    var isCustom: Bool {
        if case .custom = self {
            true
        } else {
            false
        }
    }
}
