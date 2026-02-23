import Testing
import Foundation

let env = ProcessInfo.processInfo.environment

// MARK: - Credentials

struct Credentials {
    let username: String
    let password: String
}

// MARK: - Fixture

struct Fixture: Decodable {
    var uuid: String
    var rid: Int
    var fixture: String
    var manufacturer: String
    var creationDate: Int
    
    func filename() -> String {
        return "\(self.rid).gdtf"
    }
}

// MARK: - Session Manager

actor SessionManager {
    private let credentials: Credentials
    private var isLoggedIn = false

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    func login() async throws {
        guard !isLoggedIn else { return }

        let loginURL = URL(string: "https://gdtf-share.com/apis/public/login.php")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "user": credentials.username,
            "password": credentials.password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "LoginError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        isLoggedIn = true
    }

    func invalidateSession() {
        isLoggedIn = false
    }
}

// MARK: - GDTF Downloader

actor GDTFDownloader {
    private let sessionManager: SessionManager
    private let downloadDirectory: URL
    private var fixtures: [Fixture] = []

    init(credentials: Credentials, downloadDirectory: URL) {
        self.sessionManager = SessionManager(credentials: credentials)
        self.downloadDirectory = downloadDirectory
    }

    func start() async throws {
        try await sessionManager.login()
        try await fetchFixtures()
        try await downloadFixtures()
    }

    private func fetchFixtures() async throws {
        let listURL = URL(string: "https://gdtf-share.com/apis/public/getList.php")!
        var request = URLRequest(url: listURL)
        request.httpMethod = "GET"

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = .shared
        configuration.httpMaximumConnectionsPerHost = 200
        
        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FetchFixturesError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        struct ListResponse: Decodable {
            let result: Bool
            let list: [Fixture]
        }

        let decoder = JSONDecoder()
        let responseObj = try decoder.decode(ListResponse.self, from: data)

        // Group by UUID and pick the newest creationDate
        var latestByUUID: [String: Fixture] = [:]

        for fixture in responseObj.list {
            if let existing = latestByUUID[fixture.uuid] {
                if fixture.creationDate > existing.creationDate {
                    latestByUUID[fixture.uuid] = fixture
                }
            } else {
                latestByUUID[fixture.uuid] = fixture
            }
        }

        self.fixtures = Array(latestByUUID.values.sorted(by: { $0.rid < $1.rid }))
    }

    private func downloadFixtures() async throws {
        try FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
        print("downloading to \(downloadDirectory)")

        await withTaskGroup(of: Void.self) { group in
            func addTask(_ fixture: Fixture) {
                group.addTask {
                    do {
                        try await self.downloadFixture(fixture)
                    } catch {
                        print("Failed to download fixture \(fixture.uuid): \(error)")
                    }
                }
            }
            var fixtures = fixtures.makeIterator()
            var i = 0
            while let fixture = fixtures.next(), i < 20 {
                i += 1
                addTask(fixture)
            }
            for await _ in group {
                if let fixture = fixtures.next() {
                    addTask(fixture)
                } else {
                    break
                }
            }
        }
    }

    private func downloadFixture(_ fixture: Fixture) async throws {
        let destinationURL = downloadDirectory.appendingPathComponent(fixture.filename())

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            // already downloaded, skip
            return
        }

        let downloadURL = URL(string: "https://gdtf-share.com/apis/public/downloadFile.php?rid=\(fixture.rid)")!
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "GET"

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = .shared
        let session = URLSession(configuration: configuration)

        let (tempURL, response) = try await session.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: try Data(contentsOf: tempURL), encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DownloadError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        print("Downloaded \(fixture.filename())")
    }
}

import SwiftGDTF

// MARK: - GDTF Validator

class GDTFValidator {
    private let fixturesDirectory: URL
    private var successes: [String] = []
    private var failures: [(String, String)] = []

    init(fixturesDirectory: URL) {
        self.fixturesDirectory = fixturesDirectory
    }

    func validateAll() async throws {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: fixturesDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let gdtfFiles = fileURLs.filter { $0.pathExtension.lowercased() == "gdtf" }

        print("Found \(gdtfFiles.count) GDTF files to validate.\n")

        await withTaskGroup(of: (String, Result<Void, Error>).self) { group in
            for fileURL in gdtfFiles {
                let filename = fileURL.lastPathComponent

                group.addTask {
                    do {
                        _ = try loadGDTF(url: fileURL)
                        return (filename, .success(()))
                    } catch {
                        return (filename, .failure(error))
                    }
                }
            }

            for await (filename, result) in group {
                switch result {
                case .success:
                    successes.append(filename)
                case .failure(let error):
                    failures.append((filename, "\(error)"))
                    print("❌ Failed to parse: \(filename)\n   Error: \(error)")
                }
            }
        }

        // Summary
        print("\nValidation Summary:")
        print("✅ Successes: \(successes.count)")
        print("❌ Failures: \(failures.count)")

        
        if !failures.isEmpty {
            let errorGrouped = Dictionary.init(zip(failures.map(\.1), repeatElement(1, count: .max)), uniquingKeysWith: +).sorted(by: { $0.value > $1.value})
            
            print("Failure Reasons")
            for error in errorGrouped {
                print("\(error.key): \(error.value)")
            }
            
            print("\nFailed Files:")
            for (filename, errorDescription) in failures {
                print(" - \(filename): \(errorDescription)")
            }

            // fail the test
            throw NSError(domain: "GDTFValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "GDTF validation failed for \(failures.count) files."])
        }
    }
}

// MARK: - Main Execution

@Suite
struct GDTFShare {
    let downloadFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SwiftGDTF")
        .appendingPathComponent("Fixtures")

    let credentials = Credentials(username: "SwiftGDTF", password: "hedti4-wadjer-wihtAk")

    @Test(.disabled("Downloads all fixtures from GDTF Share — run manually")) func parseAllFixtures() async throws {
        print("Download Folder: \(downloadFolder)")
        let downloader = GDTFDownloader(credentials: credentials, downloadDirectory: downloadFolder)
        try await downloader.start()

        try await GDTFValidator(fixturesDirectory: downloadFolder).validateAll()
    }

    // Useful for debugging
//    @Test func testIndividual() async throws {
//        _ = try loadGDTF(url: downloadFolder.appending(component: "Reflect Color Studio_Brother Brother and Sons_379FE751-C45E-4734-A6C8-843A2BF28F42.gdtf"))
//    }
}

// MARK: - Cached Fixture Tests (no network, reads from local cache)

/// Tests that run against whatever fixtures are already cached locally.
/// Run parseAllFixtures() first to populate the cache.
@Suite("Cached Fixtures")
struct CachedFixtures {
    let fixturesFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SwiftGDTF")
        .appendingPathComponent("Fixtures")

    /// Iterates every cached GDTF, finds all models that have a .3ds file entry, and
    /// asserts that `ThreeDSFile.parse` succeeds. Additional sanity checks are run on the
    /// returned data when possible.
    @Test func parse3DSModels() async throws {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: fixturesFolder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let gdtfFiles = fileURLs.filter { $0.pathExtension.lowercased() == "gdtf" }

        guard !gdtfFiles.isEmpty else {
            print("No GDTF files found in \(fixturesFolder) — run parseAllFixtures first.")
            return
        }

        struct ModelResult {
            var parsed: Int
            var failures: [(file: String, model: String, error: String)]
            var fixturesWithThreeDS: [(rid: String, name: String)]
        }

        let results = await withTaskGroup(of: ModelResult.self) { group in
            for fileURL in gdtfFiles {
                group.addTask {
                    let gdtfData: Data
                    let gdtf: GDTF
                    do {
                        gdtfData = try Data(contentsOf: fileURL)
                        gdtf = try loadGDTF(data: gdtfData)
                    } catch {
                        return ModelResult(parsed: 0, failures: [], fixturesWithThreeDS: [])
                    }

                    var parsed = 0
                    var failures: [(file: String, model: String, error: String)] = []
                    var hasThreeDS = false

                    for model in gdtf.fixtureType.models {
                        for lod in GDTFModel.LOD.allCases {
                            guard let raw = model.resolveFile(gdtf: gdtfData, format: .threeds, lod: lod) else {
                                continue
                            }
                            do {
                                let threeds = try ThreeDSFile.parse(data: raw)
                                hasThreeDS = true

                                // Basic sanity: if there are objects they should have vertices
                                for object in threeds.objects {
                                    #expect(!object.vertices.isEmpty,
                                            "Object '\(object.name)' in '\(model.name)' has no vertices")
                                    #expect(!object.faces.isEmpty,
                                            "Object '\(object.name)' in '\(model.name)' has no faces")
                                    // UV coordinates are optional, but if present must match vertex count
                                    if !object.textureCoordinates.isEmpty {
                                        #expect(object.textureCoordinates.count == object.vertices.count,
                                                "UV count mismatch in '\(object.name)'")
                                    }
                                    // All face indices must be within bounds
                                    for face in object.faces {
                                        #expect(Int(face.x) < object.vertices.count, "Face index out of bounds in '\(object.name)'")
                                        #expect(Int(face.y) < object.vertices.count, "Face index out of bounds in '\(object.name)'")
                                        #expect(Int(face.z) < object.vertices.count, "Face index out of bounds in '\(object.name)'")
                                    }
                                }

                                parsed += 1
                            } catch {
                                failures.append((
                                    file: fileURL.lastPathComponent,
                                    model: "\(model.name) (\(lod))",
                                    error: "\(error)"
                                ))
                            }
                        }
                    }

                    let rid = fileURL.deletingPathExtension().lastPathComponent
                    let fixtureName = "\(gdtf.fixtureType.manufacturer) \(gdtf.fixtureType.name)"
                    let fixturesWithThreeDS: [(rid: String, name: String)] = hasThreeDS
                        ? [(rid: rid, name: fixtureName)]
                        : []
                    return ModelResult(parsed: parsed, failures: failures, fixturesWithThreeDS: fixturesWithThreeDS)
                }
            }

            var combined = ModelResult(parsed: 0, failures: [], fixturesWithThreeDS: [])
            for await result in group {
                combined.parsed += result.parsed
                combined.failures += result.failures
                combined.fixturesWithThreeDS += result.fixturesWithThreeDS
            }
            return combined
        }

        let total = results.parsed + results.failures.count
        print("\n3DS Model Parsing Summary:")
        print("  Total .3ds entries found : \(total)")
        print("  Successfully parsed      : \(results.parsed)")
        print("  Parse failures           : \(results.failures.count)")
        if !results.failures.isEmpty {
            for failure in results.failures {
                print("  ❌ \(failure.file) / \(failure.model): \(failure.error)")
            }
        }

        let sorted = results.fixturesWithThreeDS.sorted { $0.rid < $1.rid }
        print("\nFixtures with .3ds models (\(sorted.count) total):")
        for fixture in sorted {
            print("  rid: \(fixture.rid)  name: \(fixture.name)")
        }

        #expect(results.failures.isEmpty, "Some .3ds models failed to parse — see output above.")
    }
}
