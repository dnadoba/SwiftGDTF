import Foundation
import Testing

struct TandemRepeat: Equatable, Comparable {
    let range: Range<Int>
    let count: Int
    
    static func < (lhs: TandemRepeat, rhs: TandemRepeat) -> Bool {
        lhs.range.lowerBound < rhs.range.lowerBound
    }
}

struct RollingHash {
    private let h1: [UInt64]
    private let h2: [UInt64]
    private let pow1: [UInt64]
    private let pow2: [UInt64]
    
    private let base1: UInt64 = 131
    private let base2: UInt64 = 137
    
    init<T: Hashable>(_ arr: [T]) {
        let n = arr.count
        var p1 = [UInt64](repeating: 1, count: n + 1)
        var p2 = [UInt64](repeating: 1, count: n + 1)
        
        for i in 1...n {
            p1[i] = p1[i-1] &* base1
            p2[i] = p2[i-1] &* base2
        }
        pow1 = p1
        pow2 = p2
        
        var hh1 = [UInt64](repeating: 0, count: n + 1)
        var hh2 = [UInt64](repeating: 0, count: n + 1)
        
        for i in 0..<n {
            let val = UInt64(bitPattern: Int64(arr[i].hashValue))
            hh1[i+1] = hh1[i] &* base1 &+ val
            hh2[i+1] = hh2[i] &* base2 &+ val
        }
        h1 = hh1
        h2 = hh2
    }
    
    func getHash(_ range: Range<Int>) -> (UInt64, UInt64) {
        let l = range.lowerBound
        let r = range.upperBound
        let len = r - l
        
        let res1 = h1[r] &- (h1[l] &* pow1[len])
        let res2 = h2[r] &- (h2[l] &* pow2[len])
        
        return (res1, res2)
    }
}

private func minimalPeriod<T: Equatable>(_ arr: [T]) -> Int {
    let n = arr.count
    if n <= 1 { return n }
    var pi = [Int](repeating: 0, count: n)
    var j = 0
    for i in 1..<n {
        while j > 0 && arr[i] != arr[j] {
            j = pi[j - 1]
        }
        if arr[i] == arr[j] {
            j += 1
        }
        pi[i] = j
    }
    let per = n - pi[n - 1]
    return n % per == 0 ? per : n
}

func findTandemRepeats<T: Hashable>(_ arr: [T]) -> [TandemRepeat] {
    let n = arr.count
    if n == 0 { return [] }
    
    let rh = RollingHash(arr)
    var results: [TandemRepeat] = []
    var currentPos = 0
    
    while currentPos < n {
        var found = false
        
        let remaining = n - currentPos
        guard remaining >= 2 else {
            currentPos += 1
            continue
        }
        
        let maxPatternLen = remaining / 2
        
        for len in 1...maxPatternLen {
            let midRange  = currentPos ..< currentPos + len
            let nextRange = currentPos + len ..< currentPos + 2 * len
            
            let hashMid  = rh.getHash(midRange)
            let hashNext = rh.getHash(nextRange)
            
            if hashMid == hashNext && arr[midRange] == arr[nextRange] {
                // Binary search for maximum repetitions k ≥ 2
                var low = 2
                var high = remaining / len
                var bestK = 2
                
                while low <= high {
                    let midK = low + (high - low) / 2
                    let checkEnd = currentPos + midK * len
                    
                    if checkEnd > n {
                        high = midK - 1
                        continue
                    }
                    
                    let checkRange = currentPos + (midK - 1) * len ..< checkEnd
                    
                    let checkHash = rh.getHash(checkRange)
                    if checkHash == hashMid && arr[checkRange] == arr[midRange] {
                        bestK = midK
                        low = midK + 1
                    } else {
                        high = midK - 1
                    }
                }
                
                let k = bestK
                let pattern = Array(arr[midRange])
                
                if minimalPeriod(pattern) == len {
                    results.append(TandemRepeat(range: currentPos..<currentPos + len, count: k))
                    currentPos += k * len
                    found = true
                    break
                }
            }
        }
        
        if !found {
            currentPos += 1
        }
    }
    
    return results
}
@Suite
struct TandemRepeatTests {
    @Test("No repeats 1")
    func testNoRepeats1() {
        let arr = [1, 2, 1, 3, 1, 4]
        let res = findTandemRepeats(arr)
        #expect(res == [])
    }
    
    @Test("No repeats 2")
    func testNoRepeats2() {
        let arr = [1, 2, 1, 3, 1, 2]
        let res = findTandemRepeats(arr)
        #expect(res == [])
    }
    
    @Test("Repeat length 2 count 3")
    func testRepeat1() {
        let arr = [1, 2, 1, 2, 1, 2]
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<2, count: 3)])
    }
    
    @Test("Repeat length 2 count 2")
    func testRepeat2() {
        let arr = [1, 2, 1, 2, 5, 1, 2]
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<2, count: 2)])
    }
    
    @Test("Two repeats length 2")
    func testRepeat3() {
        let arr = [1, 2, 1, 2, 5, 1, 2, 1, 2]
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<2, count: 2), TandemRepeat(range: 5..<7, count: 2)])
    }
    
    @Test("Two repeats different")
    func testRepeat4() {
        let arr = [1, 2, 1, 2, 5, 1, 3, 1, 3]
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<2, count: 2), TandemRepeat(range: 5..<7, count: 2)])
    }
    
    @Test("Repeat with length 3")
    func testRepeat5() {
        let arr = [1, 2, 1, 2, 5, 1, 2, 3, 1, 2, 3]
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<2, count: 2), TandemRepeat(range: 5..<8, count: 2)])
    }
    
    @Test("Overlap case")
    func testRepeat6() {
        let arr = [1, 2, 1, 2, 1, 2, 3, 1, 2, 3]
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<2, count: 2), TandemRepeat(range: 4..<7, count: 2)])
    }
    @Test("Simple Repeat")
    func testRepeat7() {
        let arr = Array(repeating: 1, count: 10)
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<1, count: 10)])
    }
    
    @Test("Long Repeat")
    func testRepeat8() {
        let arr = Array(repeating: 1, count: 1000)
        let res = findTandemRepeats(arr)
        #expect(res == [TandemRepeat(range: 0..<1, count: 1000)])
    }
    
}
