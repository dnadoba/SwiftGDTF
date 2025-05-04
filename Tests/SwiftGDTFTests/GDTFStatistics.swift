import Foundation
import SwiftGDTF

@available(macOS 15.4, iOS 18.4, *)
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
        let fixtureTypeID: UUID  // Store the UUID for reference
        let goboWheels: [WheelInfo]
        let colorWheels: [WheelInfo]
        let dmxBitWidths: Set<Int>
        let attributeBitWidths: [AttributeType: Set<Int>] // [AttributeType: Set of unique bit widths]
        let usedAttributes: Set<AttributeType> // New field to track attributes used in this fixture
        
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
        var goboWheelDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [wheelCount: (count, fixtureIDs)]
        
        // Color wheel stats
        var maxColorWheels: Int = 0
        var fixtureWithMaxColorWheels: String = ""
        var colorWheelDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [wheelCount: (count, fixtureIDs)]
        
        // Gobo count per wheel stats
        var maxGobosPerWheel: Int = 0
        var wheelWithMaxGobos: String = ""
        var fixtureWithMaxGobosPerWheel: String = ""
        var goboPerWheelDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [goboCount: (wheelCount, fixtureIDs)]
        
        // Total gobo count stats
        var maxTotalGobos: Int = 0
        var fixtureWithMaxTotalGobos: String = ""
        var totalGobosDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [goboCount: (fixtureCount, fixtureIDs)]
        
        // Color count per wheel stats
        var maxColorsPerWheel: Int = 0
        var wheelWithMaxColors: String = ""
        var fixtureWithMaxColorsPerWheel: String = ""
        var colorPerWheelDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [colorCount: (wheelCount, fixtureIDs)]
        
        // Total color count stats
        var maxTotalColors: Int = 0
        var fixtureWithMaxTotalColors: String = ""
        var totalColorsDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [colorCount: (fixtureCount, fixtureIDs)]
        
        // DMX bit width stats
        var dmxBitWidthDistribution: [Int: (count: Int, fixtureIDs: [UUID])] = [:] // [bitWidth: (count, fixtureIDs)]
        
        // Attribute bit width stats - now grouped by bit width first
        var bitWidthAttributeDistribution: [Int: [AttributeType: (count: Int, fixtureIDs: [UUID])]] = [:] // [bitWidth: [AttributeType: (count, fixtureIDs)]]
        
        // New: Attribute usage stats
        var attributeUsageCount: [AttributeType: (count: Int, fixtureIDs: [UUID])] = [:] // [AttributeType: (fixtureCount, fixtureIDs)]
        
        var description: String {
            var result = """
            Analyzed \(fixtureCount) fixtures (successfully parsed \(parsedFixtureCount))
            
            === ATTRIBUTE USAGE ===
            Attributes by number of fixtures using them:
            """
            
            // Add the attribute usage statistics, sorted by usage count (descending)
            let sortedAttributeUsage = attributeUsageCount.sorted { $0.value.count > $1.value.count }
            for (attributeType, stats) in sortedAttributeUsage {
                let percentage = Double(stats.count) / Double(parsedFixtureCount) * 100
                result += "\n\(attributeType): \(stats.count) fixture(s) (\(String(format: "%.1f", percentage))%)"
            }
            
            result += """
            
            
            === GOBO WHEELS ===
            Maximum number of gobo wheels: \(maxGoboWheels) (in fixture: \(fixtureWithMaxGoboWheels))
            
            Gobo wheel distribution:
            """
            
            let sortedGoboWheelDistribution = goboWheelDistribution.sorted { $0.key < $1.key }
            for (wheelCount, stats) in sortedGoboWheelDistribution {
                result += "\n\(wheelCount) wheel(s): \(stats.count) fixture(s)"
            }
            
            result += """
            
            
            === GOBOS PER WHEEL ===
            Maximum gobos per wheel: \(maxGobosPerWheel) (in wheel: \(wheelWithMaxGobos) of fixture: \(fixtureWithMaxGobosPerWheel))
            
            Gobo per wheel distribution:
            """
            
            let sortedGoboPerWheelDistribution = goboPerWheelDistribution.sorted { $0.key < $1.key }
            for (goboCount, stats) in sortedGoboPerWheelDistribution {
                result += "\n\(goboCount) gobo(s): \(stats.count) wheel(s)"
            }
            
            result += """
            
            
            === TOTAL GOBOS PER FIXTURE ===
            Maximum total gobos: \(maxTotalGobos) (in fixture: \(fixtureWithMaxTotalGobos))
            
            Total gobos distribution:
            """
            
            let sortedTotalGobosDistribution = totalGobosDistribution.sorted { $0.key < $1.key }
            for (goboCount, stats) in sortedTotalGobosDistribution {
                result += "\n\(goboCount) gobo(s): \(stats.count) fixture(s)"
            }
            
            result += """
            
            
            === COLOR WHEELS ===
            Maximum number of color wheels: \(maxColorWheels) (in fixture: \(fixtureWithMaxColorWheels))
            
            Color wheel distribution:
            """
            
            let sortedColorWheelDistribution = colorWheelDistribution.sorted { $0.key < $1.key }
            for (wheelCount, stats) in sortedColorWheelDistribution {
                result += "\n\(wheelCount) wheel(s): \(stats.count) fixture(s)"
            }
            
            result += """
            
            
            === COLORS PER WHEEL ===
            Maximum colors per wheel: \(maxColorsPerWheel) (in wheel: \(wheelWithMaxColors) of fixture: \(fixtureWithMaxColorsPerWheel))
            
            Color per wheel distribution:
            """
            
            let sortedColorPerWheelDistribution = colorPerWheelDistribution.sorted { $0.key < $1.key }
            for (colorCount, stats) in sortedColorPerWheelDistribution {
                result += "\n\(colorCount) color(s): \(stats.count) wheel(s)"
            }
            
            result += """
            
            
            === TOTAL COLORS PER FIXTURE ===
            Maximum total colors: \(maxTotalColors) (in fixture: \(fixtureWithMaxTotalColors))
            
            Total colors distribution:
            """
            
            let sortedTotalColorsDistribution = totalColorsDistribution.sorted { $0.key < $1.key }
            for (colorCount, stats) in sortedTotalColorsDistribution {
                result += "\n\(colorCount) color(s): \(stats.count) fixture(s)"
            }
            
            result += """
            
            
            === DMX BIT WIDTH ===
            DMX bit width distribution:
            """
            
            let sortedDMXBitWidthDistribution = dmxBitWidthDistribution.sorted { $0.key < $1.key }
            for (bitWidth, stats) in sortedDMXBitWidthDistribution {
                result += "\n\(bitWidth)-bit: \(stats.count) usage(s)"
            }
            
            result += """
            
            
            === ATTRIBUTE BIT WIDTH DETAILS ===
            Bit width distribution by attribute type:
            """
            
            // Get a sorted list of bit widths for consistent output
            let bitWidths = bitWidthAttributeDistribution.keys.sorted()
            
            for bitWidth in bitWidths {
                result += "\n\n\(bitWidth)-bit:"
                
                if let attributes = bitWidthAttributeDistribution[bitWidth] {
                    // Sort attributes by name for consistent output
                    let sortedAttributes = attributes.sorted { $0.value.count > $1.value.count }
                    for (attribute, stats) in sortedAttributes {
                        result += "\n  \(attribute): \(stats.count) fixture(s)"
                    }
                } else {
                    result += "\n  No data"
                }
            }
            
            return result
        }
        
        // Helper method to get fixtures with specific gobo wheel count
        func fixturesWithGoboWheelCount(_ count: Int) -> [UUID] {
            return goboWheelDistribution[count]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures with specific color wheel count
        func fixturesWithColorWheelCount(_ count: Int) -> [UUID] {
            return colorWheelDistribution[count]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures with specific number of gobos per wheel
        func fixturesWithGoboPerWheelCount(_ count: Int) -> [UUID] {
            return goboPerWheelDistribution[count]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures with specific total gobo count
        func fixturesWithTotalGoboCount(_ count: Int) -> [UUID] {
            return totalGobosDistribution[count]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures with specific colors per wheel
        func fixturesWithColorPerWheelCount(_ count: Int) -> [UUID] {
            return colorPerWheelDistribution[count]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures with specific total color count
        func fixturesWithTotalColorCount(_ count: Int) -> [UUID] {
            return totalColorsDistribution[count]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures with specific DMX bit width
        func fixturesWithDMXBitWidth(_ bitWidth: Int) -> [UUID] {
            return dmxBitWidthDistribution[bitWidth]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures using a specific attribute
        func fixturesUsingAttribute(_ attribute: AttributeType) -> [UUID] {
            return attributeUsageCount[attribute]?.fixtureIDs ?? []
        }
        
        // Helper method to get fixtures using a specific attribute at specific bit width
        func fixturesUsingAttribute(_ attribute: AttributeType, withBitWidth bitWidth: Int) -> [UUID] {
            return bitWidthAttributeDistribution[bitWidth]?[attribute]?.fixtureIDs ?? []
        }
    }
    
    func collect() async -> Result {
        var result = Result()
        
        do {
            let startTime = Date()
            let progressFormatter = DateComponentsFormatter()
            progressFormatter.allowedUnits = [.hour, .minute, .second]
            progressFormatter.unitsStyle = .abbreviated
            progressFormatter.maximumUnitCount = 2
            
            let gdtfFiles = try getListOfGDTFs(at: fixturesDirectory)
            let limitedFiles = Array(gdtfFiles.prefix(limit))
            
            result.fixtureCount = limitedFiles.count
            print("Starting to process \(limitedFiles.count) fixture files...")
            
            var processedCount = 0
            
            await withTaskGroup(of: FixtureStats?.self) { group in
                var filesToProcess = limitedFiles.makeIterator()
                let queue = DispatchQueue.global(qos: .userInitiated)
                func addTaskIfNeeded() {
                    guard let fileURL = filesToProcess.next() else { return }
                    group.addTask(executorPreference: queue) {
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
                
                for _ in 0..<ProcessInfo.processInfo.processorCount {
                    addTaskIfNeeded()
                }
                
                
                for await fixtureStats in group {
                    addTaskIfNeeded()
                    processedCount += 1
                    // Show progress every 5% or every file if there are few files
                    let reportInterval = max(1, limitedFiles.count / 20)
                    if processedCount % reportInterval == 0 || processedCount == limitedFiles.count {
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        let filesPerSecond = Double(processedCount) / elapsedTime
                        let remainingFiles = limitedFiles.count - processedCount
                        let remainingTimeSeconds = filesPerSecond > 0 ? Double(remainingFiles) / filesPerSecond : 0
                        
                        let percentage = Double(processedCount) / Double(limitedFiles.count) * 100
                        let remainingTimeFormatted = progressFormatter.string(from: remainingTimeSeconds) ?? "unknown"
                        
                        print("Progress: \(processedCount)/\(limitedFiles.count) (\(String(format: "%.1f", percentage))%) - Est. remaining time: \(remainingTimeFormatted)")
                    }
                    guard let fixtureStats = fixtureStats else {
                        continue
                    }
                    result.fixtureStats.append(fixtureStats)
                    result.parsedFixtureCount += 1
                    
                    // Gobo wheel stats
                    let goboWheelCount = fixtureStats.goboWheels.count
                    if let existing = result.goboWheelDistribution[goboWheelCount] {
                        result.goboWheelDistribution[goboWheelCount] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                    } else {
                        result.goboWheelDistribution[goboWheelCount] = (1, [fixtureStats.fixtureTypeID])
                    }
                    
                    if goboWheelCount > result.maxGoboWheels {
                        result.maxGoboWheels = goboWheelCount
                        result.fixtureWithMaxGoboWheels = fixtureStats.name
                    }
                    
                    // Gobo per wheel stats
                    for wheel in fixtureStats.goboWheels {
                        if let existing = result.goboPerWheelDistribution[wheel.slotCount] {
                            result.goboPerWheelDistribution[wheel.slotCount] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                        } else {
                            result.goboPerWheelDistribution[wheel.slotCount] = (1, [fixtureStats.fixtureTypeID])
                        }
                        
                        if wheel.slotCount > result.maxGobosPerWheel {
                            result.maxGobosPerWheel = wheel.slotCount
                            result.wheelWithMaxGobos = wheel.name
                            result.fixtureWithMaxGobosPerWheel = fixtureStats.name
                        }
                    }
                    
                    // Total gobos stats
                    let totalGobos = fixtureStats.totalGoboCount
                    if let existing = result.totalGobosDistribution[totalGobos] {
                        result.totalGobosDistribution[totalGobos] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                    } else {
                        result.totalGobosDistribution[totalGobos] = (1, [fixtureStats.fixtureTypeID])
                    }
                    
                    if totalGobos > result.maxTotalGobos {
                        result.maxTotalGobos = totalGobos
                        result.fixtureWithMaxTotalGobos = fixtureStats.name
                    }
                    
                    // Color wheel stats
                    let colorWheelCount = fixtureStats.colorWheels.count
                    if let existing = result.colorWheelDistribution[colorWheelCount] {
                        result.colorWheelDistribution[colorWheelCount] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                    } else {
                        result.colorWheelDistribution[colorWheelCount] = (1, [fixtureStats.fixtureTypeID])
                    }
                    
                    if colorWheelCount > result.maxColorWheels {
                        result.maxColorWheels = colorWheelCount
                        result.fixtureWithMaxColorWheels = fixtureStats.name
                    }
                    
                    // Color per wheel stats
                    for wheel in fixtureStats.colorWheels {
                        if let existing = result.colorPerWheelDistribution[wheel.slotCount] {
                            result.colorPerWheelDistribution[wheel.slotCount] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                        } else {
                            result.colorPerWheelDistribution[wheel.slotCount] = (1, [fixtureStats.fixtureTypeID])
                        }
                        
                        if wheel.slotCount > result.maxColorsPerWheel {
                            result.maxColorsPerWheel = wheel.slotCount
                            result.wheelWithMaxColors = wheel.name
                            result.fixtureWithMaxColorsPerWheel = fixtureStats.name
                        }
                    }
                    
                    // Total colors stats
                    let totalColors = fixtureStats.totalColorCount
                    if let existing = result.totalColorsDistribution[totalColors] {
                        result.totalColorsDistribution[totalColors] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                    } else {
                        result.totalColorsDistribution[totalColors] = (1, [fixtureStats.fixtureTypeID])
                    }
                    
                    if totalColors > result.maxTotalColors {
                        result.maxTotalColors = totalColors
                        result.fixtureWithMaxTotalColors = fixtureStats.name
                    }
                    
                    // DMX bit width stats
                    for bitWidth in fixtureStats.dmxBitWidths {
                        if let existing = result.dmxBitWidthDistribution[bitWidth] {
                            result.dmxBitWidthDistribution[bitWidth] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                        } else {
                            result.dmxBitWidthDistribution[bitWidth] = (1, [fixtureStats.fixtureTypeID])
                        }
                    }
                    
                    // Attribute bit width stats - now grouped by bit width first
                    for (attributeType, bitWidths) in fixtureStats.attributeBitWidths {
                        for bitWidth in bitWidths {
                            if let attributeMap = result.bitWidthAttributeDistribution[bitWidth] {
                                if let existing = attributeMap[attributeType] {
                                    result.bitWidthAttributeDistribution[bitWidth]?[attributeType] =
                                        (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                                } else {
                                    result.bitWidthAttributeDistribution[bitWidth]?[attributeType] = (1, [fixtureStats.fixtureTypeID])
                                }
                            } else {
                                result.bitWidthAttributeDistribution[bitWidth] = [attributeType: (1, [fixtureStats.fixtureTypeID])]
                            }
                        }
                    }
                    
                    // Process attribute usage stats
                    for attributeType in fixtureStats.usedAttributes {
                        if let existing = result.attributeUsageCount[attributeType] {
                            result.attributeUsageCount[attributeType] = (existing.count + 1, existing.fixtureIDs + [fixtureStats.fixtureTypeID])
                        } else {
                            result.attributeUsageCount[attributeType] = (1, [fixtureStats.fixtureTypeID])
                        }
                    }
                }
            }
            
            let totalTime = Date().timeIntervalSince(startTime)
            print("Processing completed in \(progressFormatter.string(from: totalTime) ?? "unknown")")
            
        } catch {
            print("Error accessing fixtures directory: \(error)")
        }
        
        return result
    }

    
    private func analyzeFixture(_ gdtf: GDTF, name: String) -> FixtureStats {
        var goboWheels: [WheelInfo] = []
        var colorWheels: [WheelInfo] = []
        var dmxBitWidths = Set<Int>()
        var attributeBitWidths: [AttributeType: Set<Int>] = [:]
        var usedAttributes = Set<AttributeType>()
    
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
                    // Add the attribute type from the logical channel to the set of used attributes
                    usedAttributes.insert(logicalChannel.attribute.type)
                    
                    for channelFunction in logicalChannel.channelFunctions {
                        let bitWidth = channelFunction.dmxFrom.byteCount * 8
                        dmxBitWidths.insert(bitWidth)
                        
                        if let attributeType = channelFunction.attribute?.type {
                            attributeBitWidths[attributeType, default: []].insert(bitWidth)
                            usedAttributes.insert(attributeType)
                        }
                    }
                }
            }
        }
        
        return FixtureStats(
            name: name,
            fixtureTypeID: gdtf.fixtureType.fixtureTypeID,
            goboWheels: goboWheels,
            colorWheels: colorWheels,
            dmxBitWidths: dmxBitWidths,
            attributeBitWidths: attributeBitWidths,
            usedAttributes: usedAttributes
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
    
    func getListOfGDTFs(at directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        let directoryContents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return directoryContents.filter { $0.pathExtension.lowercased() == "gdtf" }
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


@Test
@available(macOS 15.4, iOS 18.4, *)
func calculateStatistics() async throws {
    let statistics = GDTFStatistics(fixturesDirectory: GDTFShare().downloadFolder, limit: .max)
    let results = await statistics.collect()
    print(results)
}
