import Testing
import SwiftGDTF

@Suite
struct AttributeDescriptionsTests {
    @Test func checkThatAllAttributeAreKnown() {
        let all = AttributeDescription.attributes

        for (attribute, description) in all {
            #expect(!attribute.isCustom, "attribute \(attribute) should be known but it is custom. Description: \(description)")
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
