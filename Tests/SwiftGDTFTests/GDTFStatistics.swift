import Foundation
import SwiftGDTF

final class GDTFStatistics {
    let fixturesDirectory: URL
    let limit: Int
    
    init(fixturesDirectory: URL, limit: Int = .max) {
        self.fixturesDirectory = fixturesDirectory
        self.limit = limit
    }
    
    struct WheelInfo {
        let name: String
        let slotCount: Int
    }
    
    struct FixtureStats {
        let name: String
        let goboWheels: [WheelInfo]
        let colorWheels: [WheelInfo]
        let dmxBitWidths: Set<Int>
        
        var totalGoboCount: Int {
            return goboWheels.reduce(0) { $0 + $1.slotCount }
        }
        
        var totalColorCount: Int {
            return colorWheels.reduce(0) { $0 + $1.slotCount }
        }
    }
    
    struct Result: CustomStringConvertible {
        var fixtureCount: Int = 0
        var parsedFixtureCount: Int = 0
        var fixtureStats: [FixtureStats] = []
        
        // Gobo wheel stats
        var maxGoboWheels: Int = 0
        var fixtureWithMaxGoboWheels: String = ""
        var goboWheelDistribution: [Int: Int] = [:] // [wheelCount: numberOfFixtures]
        
        // Color wheel stats
        var maxColorWheels: Int = 0
        var fixtureWithMaxColorWheels: String = ""
        var colorWheelDistribution: [Int: Int] = [:] // [wheelCount: numberOfFixtures]
        
        // Gobo count per whele stats
        var maxGobosPerWheel: Int = 0
        var wheelWithMaxGobos: String = ""
        var fixtureWithMaxGobosPerWheel: String = ""
        var goboPerWheelDistribution: [Int: Int] = [:] // [goboCount: numberOfWheels]
        
        // Total gobo count stats
        var maxTotalGobos: Int = 0
        var fixtureWithMaxTotalGobos: String = ""
        var totalGobosDistribution: [Int: Int] = [:] // [goboCount: numberOfFixtures]
        
        // Color count per wheel stats
        var maxColorsPerWheel: Int = 0
        var wheelWithMaxColors: String = ""
        var fixtureWithMaxColorsPerWheel: String = ""
        var colorPerWheelDistribution: [Int: Int] = [:] // [colorCount: numberOfWheels]
        
        // Total color count stats
        var maxTotalColors: Int = 0
        var fixtureWithMaxTotalColors: String = ""
        var totalColorsDistribution: [Int: Int] = [:] // [colorCount: numberOfFixtures]
        
        // DMX bit width stats
        var dmxBitWidthDistribution: [Int: Int] = [:] // [bitWidth: count]
        
        var description: String {
            var result = """
            Analyzed \(fixtureCount) fixtures (successfully parsed \(parsedFixtureCount))
            
            === GOBO WHEELS ===
            Maximum number of gobo wheels: \(maxGoboWheels) (in fixture: \(fixtureWithMaxGoboWheels))
            
            Gobo wheel distribution:
            """
            
            let sortedGoboWheelDistribution = goboWheelDistribution.sorted { $0.key < $1.key }
            for (wheelCount, fixtureCount) in sortedGoboWheelDistribution {
                result += "\n\(wheelCount) wheel(s): \(fixtureCount) fixture(s)"
            }
            
            result += """
            
            
            === GOBOS PER WHEEL ===
            Maximum gobos per wheel: \(maxGobosPerWheel) (in wheel: \(wheelWithMaxGobos) of fixture: \(fixtureWithMaxGobosPerWheel))
            
            Gobo per wheel distribution:
            """
            
            let sortedGoboPerWheelDistribution = goboPerWheelDistribution.sorted { $0.key < $1.key }
            for (goboCount, wheelCount) in sortedGoboPerWheelDistribution {
                result += "\n\(goboCount) gobo(s): \(wheelCount) wheel(s)"
            }
            
            result += """
            
            
            === TOTAL GOBOS PER FIXTURE ===
            Maximum total gobos: \(maxTotalGobos) (in fixture: \(fixtureWithMaxTotalGobos))
            
            Total gobos distribution:
            """
            
            let sortedTotalGobosDistribution = totalGobosDistribution.sorted { $0.key < $1.key }
            for (goboCount, fixtureCount) in sortedTotalGobosDistribution {
                result += "\n\(goboCount) gobo(s): \(fixtureCount) fixture(s)"
            }
            
            result += """
            
            
            === COLOR WHEELS ===
            Maximum number of color wheels: \(maxColorWheels) (in fixture: \(fixtureWithMaxColorWheels))
            
            Color wheel distribution:
            """
            
            let sortedColorWheelDistribution = colorWheelDistribution.sorted { $0.key < $1.key }
            for (wheelCount, fixtureCount) in sortedColorWheelDistribution {
                result += "\n\(wheelCount) wheel(s): \(fixtureCount) fixture(s)"
            }
            
            result += """
            
            
            === COLORS PER WHEEL ===
            Maximum colors per wheel: \(maxColorsPerWheel) (in wheel: \(wheelWithMaxColors) of fixture: \(fixtureWithMaxColorsPerWheel))
            
            Color per wheel distribution:
            """
            
            let sortedColorPerWheelDistribution = colorPerWheelDistribution.sorted { $0.key < $1.key }
            for (colorCount, wheelCount) in sortedColorPerWheelDistribution {
                result += "\n\(colorCount) color(s): \(wheelCount) wheel(s)"
            }
            
            result += """
            
            
            === TOTAL COLORS PER FIXTURE ===
            Maximum total colors: \(maxTotalColors) (in fixture: \(fixtureWithMaxTotalColors))
            
            Total colors distribution:
            """
            
            let sortedTotalColorsDistribution = totalColorsDistribution.sorted { $0.key < $1.key }
            for (colorCount, fixtureCount) in sortedTotalColorsDistribution {
                result += "\n\(colorCount) color(s): \(fixtureCount) fixture(s)"
            }
            
            result += """
            
            
            === DMX BIT WIDTH ===
            DMX bit width distribution:
            """
            
            let sortedDMXBitWidthDistribution = dmxBitWidthDistribution.sorted { $0.key < $1.key }
            for (bitWidth, count) in sortedDMXBitWidthDistribution {
                result += "\n\(bitWidth)-bit: \(count) usage(s)"
            }
            
            return result
        }
    }
    
    func collect() async -> Result {
        var result = Result()
        
        do {
            let gdtfFiles = try getListOfGDTFs(at: fixturesDirectory)
            let limitedFiles = Array(gdtfFiles.prefix(limit))
            
            result.fixtureCount = limitedFiles.count
            
            await withTaskGroup(of: FixtureStats?.self) { group in
                for fileURL in limitedFiles {
                    group.addTask {
                        do {
                            let gdtf = try loadGDTF(url: fileURL)
                            let fixtureName = fileURL.lastPathComponent
                            let stats = self.analyzeFixture(gdtf, name: fixtureName)
                            return stats
                        } catch {
                            print("Error processing \(fileURL.lastPathComponent): \(error)")
                            return nil
                        }
                    }
                }
                
                for await fixtureStats in group {
                    guard let fixtureStats = fixtureStats else {
                        continue
                    }
                    result.fixtureStats.append(fixtureStats)
                    result.parsedFixtureCount += 1
                    
                    // Gobo wheel stats
                    let goboWheelCount = fixtureStats.goboWheels.count
                    result.goboWheelDistribution[goboWheelCount, default: 0] += 1
                    
                    if goboWheelCount > result.maxGoboWheels {
                        result.maxGoboWheels = goboWheelCount
                        result.fixtureWithMaxGoboWheels = fixtureStats.name
                    }
                    
                    // Gobo per wheel stats
                    for wheel in fixtureStats.goboWheels {
                        result.goboPerWheelDistribution[wheel.slotCount, default: 0] += 1
                        
                        if wheel.slotCount > result.maxGobosPerWheel {
                            result.maxGobosPerWheel = wheel.slotCount
                            result.wheelWithMaxGobos = wheel.name
                            result.fixtureWithMaxGobosPerWheel = fixtureStats.name
                        }
                    }
                    
                    // Total gobos stats
                    let totalGobos = fixtureStats.totalGoboCount
                    result.totalGobosDistribution[totalGobos, default: 0] += 1
                    
                    if totalGobos > result.maxTotalGobos {
                        result.maxTotalGobos = totalGobos
                        result.fixtureWithMaxTotalGobos = fixtureStats.name
                    }
                    
                    // Color wheel stats
                    let colorWheelCount = fixtureStats.colorWheels.count
                    result.colorWheelDistribution[colorWheelCount, default: 0] += 1
                    
                    if colorWheelCount > result.maxColorWheels {
                        result.maxColorWheels = colorWheelCount
                        result.fixtureWithMaxColorWheels = fixtureStats.name
                    }
                    
                    // Color per wheel stats
                    for wheel in fixtureStats.colorWheels {
                        result.colorPerWheelDistribution[wheel.slotCount, default: 0] += 1
                        
                        if wheel.slotCount > result.maxColorsPerWheel {
                            result.maxColorsPerWheel = wheel.slotCount
                            result.wheelWithMaxColors = wheel.name
                            result.fixtureWithMaxColorsPerWheel = fixtureStats.name
                        }
                    }
                    
                    // Total colors stats
                    let totalColors = fixtureStats.totalColorCount
                    result.totalColorsDistribution[totalColors, default: 0] += 1
                    
                    if totalColors > result.maxTotalColors {
                        result.maxTotalColors = totalColors
                        result.fixtureWithMaxTotalColors = fixtureStats.name
                    }
                    
                    // DMX bit width stats
                    for bitWidth in fixtureStats.dmxBitWidths {
                        result.dmxBitWidthDistribution[bitWidth, default: 0] += 1
                    }
                }
            }
            
        } catch {
            print("Error accessing fixtures directory: \(error)")
        }
        
        return result
    }

    
    private func analyzeFixture(_ gdtf: GDTF, name: String) -> FixtureStats {
        var goboWheels: [WheelInfo] = []
        var colorWheels: [WheelInfo] = []
        var dmxBitWidths = Set<Int>()
    
        let goboWheelMap = getGoboWheels(in: gdtf)
        let colorWheelMap = getColorWheels(in: gdtf)
        
        for (wheelName, wheel) in goboWheelMap {
            goboWheels.append(WheelInfo(name: wheelName, slotCount: wheel.slots.count))
        }
        
        for (wheelName, wheel) in colorWheelMap {
            colorWheels.append(WheelInfo(name: wheelName, slotCount: wheel.slots.count))
        }
        
        for mode in gdtf.fixtureType.dmxModes {
            for channel in mode.channels {
                for logicalChannel in channel.logicalChannels {
                    for channelFunction in logicalChannel.channelFunctions {
                        dmxBitWidths.insert(channelFunction.dmxFrom.byteCount * 8)
                    }
                }
            }
        }
        
        return FixtureStats(
            name: name,
            goboWheels: goboWheels,
            colorWheels: colorWheels,
            dmxBitWidths: dmxBitWidths
        )
    }
    
    private func getGoboWheels(in gdtf: GDTF) -> [String: Wheel] {
        var goboWheels: [String: Wheel] = [:]
        
        for mode in gdtf.fixtureType.dmxModes {
            for channel in mode.channels {
                for logicalChannel in channel.logicalChannels {
                    for channelFunction in logicalChannel.channelFunctions {
                        if let attributeType = channelFunction.attribute?.type {
                            if attributeType.isGoboWheel,
                               let wheel = channelFunction.wheel {
                                goboWheels[wheel.name] = wheel
                            }
                        }
                    }
                }
            }
        }
        
        return goboWheels
    }
    
    private func getColorWheels(in gdtf: GDTF) -> [String: Wheel] {
        var colorWheels: [String: Wheel] = [:]
        
        for mode in gdtf.fixtureType.dmxModes {
            for channel in mode.channels {
                for logicalChannel in channel.logicalChannels {
                    for channelFunction in logicalChannel.channelFunctions {
                        if let attributeType = channelFunction.attribute?.type {
                            if attributeType.isColorWheel,
                               let wheel = channelFunction.wheel {
                                colorWheels[wheel.name] = wheel
                            }
                        }
                    }
                }
            }
        }
        
        return colorWheels
    }
}

extension AttributeType {
    var isColorWheel: Bool {
        switch self {
        case .color:
            return true
        default:
            return false
        }
    }
    var isGoboWheel: Bool {
        switch self {
        case .gobo:
            return true
        default:
            return false
        }
    }
}

import Testing

@Test func calculateStatistics() async throws {
    let statistics = GDTFStatistics(fixturesDirectory: GDTFShare().downloadFolder, limit: .max)
    let results = await statistics.collect()
    print(results)
}
