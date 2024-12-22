import Foundation
import SwiftGDTF

let file = Bundle.main.url(forResource: "storm", withExtension: "gdtf")!

let clock = ContinuousClock()

//let fixture = try! loadGDTF(url: file)

print(clock.measure {
//    print(fixture.fixtureType.dmxModes[0].name)
    let newFixture = try! loadFixtureModePackage(mode: "Single Control: Basic 31ch", url: file)
//    
//    for i in newFixture.mode.channels {
//        print(i.geometry, i.initialFunction.attribute!.type)
//    }

})

//
//
////print(AttributeType.from("Test1File3"))
