import Foundation
import SwiftGDTF

final class GDTFStatistics {
    let fixturesDirectory: URL
    let limit: Int
    
    init(fixturesDirectory: URL, limit: Int = .max) {
        self.fixturesDirectory = fixturesDirectory
        self.limit = limit
    }
    
    struct Result: CustomStringConvertible {
        var fixtureCount: Int = 0
        var maxGoboWheels: Int = 0
        var fixtureWithMaxGoboWheels: String = ""
        var goboWheelDistribution: [Int: Int] = [:] // [wheelCount: numberOfFixtures]
        
        var description: String {
            var result = """
            Analyzed \(fixtureCount) fixtures
            Maximum number of gobo wheels: \(maxGoboWheels) (in fixture: \(fixtureWithMaxGoboWheels))
            
            Gobo wheel distribution:
            """
            
            let sortedDistribution = goboWheelDistribution.sorted { $0.key < $1.key }
            for (wheelCount, fixtureCount) in sortedDistribution {
                result += "\n\(wheelCount) wheel(s): \(fixtureCount) fixture(s)"
            }
            
            return result
        }
    }
    
    func collect() async -> Result {
        var result = Result()
        
        do {
            let gdtfFiles = try getListOfGDTFs(at: fixturesDirectory)
            let limitedFiles = gdtfFiles.prefix(limit)
            
            result.fixtureCount = limitedFiles.count
            
            await withTaskGroup(of: (String, Int).self) { group in
                for fileURL in limitedFiles {
                    group.addTask {
                        let filename = fileURL.lastPathComponent
                        do {
                            let gdtf = try loadGDTF(url: fileURL)
                            let goboWheelCount = self.countGoboWheels(in: gdtf)
                            return (filename, goboWheelCount)
                        } catch {
                            print("Error processing \(filename): \(error)")
                            return (filename, 0)
                        }
                    }
                }
                
                // Process results from the task group
                for await (filename, goboWheelCount) in group {
                    // Update distribution count
                    result.goboWheelDistribution[goboWheelCount, default: 0] += 1
                    
                    // Update max if needed
                    if goboWheelCount > result.maxGoboWheels {
                        result.maxGoboWheels = goboWheelCount
                        result.fixtureWithMaxGoboWheels = filename
                    }
                }
            }
        } catch {
            print("Error accessing fixtures directory: \(error)")
        }
        
        return result
    }
    
    private func countGoboWheels(in gdtf: GDTF) -> Int {
        // Method 1: Count wheels that are referenced by gobo-related attributes
        var goboWheelNames = Set<String>()
        
        for mode in gdtf.fixtureType.dmxModes {
            for channel in mode.channels {
                for logicalChannel in channel.logicalChannels {
                    for channelFunction in logicalChannel.channelFunctions {
                        // Check if channel function has a gobo-related attribute type
                        if case .gobo = channelFunction.attribute?.type,
                           let wheel = channelFunction.wheel {
                            goboWheelNames.insert(wheel.name)
                        } else if case .goboWheelIndex = channelFunction.attribute?.type,
                                  let wheel = channelFunction.wheel {
                            goboWheelNames.insert(wheel.name)
                        } else if case .goboWheelSpin = channelFunction.attribute?.type,
                                  let wheel = channelFunction.wheel {
                            goboWheelNames.insert(wheel.name)
                        } else if case .goboWheelShake = channelFunction.attribute?.type,
                                  let wheel = channelFunction.wheel {
                            goboWheelNames.insert(wheel.name)
                        }
                    }
                }
            }
        }
        
        return goboWheelNames.count
    }
}
